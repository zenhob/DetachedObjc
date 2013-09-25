//
//  SessionManager.m
//  Detached
//
//  Created by Zack Hobson on 7/21/13.
//  Copyright (c) 2013 Zack Hobson. All rights reserved.
//

#import "SessionManager.h"
#import "ScreenSession.h"

static void updateSession_cb(
        ConstFSEventStreamRef streamRef,
        void *manager,
        size_t numEvents,
        void *eventPaths,
        const FSEventStreamEventFlags eventFlags[],
        const FSEventStreamEventId eventIds[])
{
    [(__bridge SessionManager*)manager updateSessions];
}

@implementation SessionManager

- (id)initWithRunner:(TerminalRunner*)runner;
{
    self = [super init];
    if (self) {
        _terminalRunner = runner;
        screenDir = nil;
        sessionList = [[NSMutableArray alloc] init];
        emptyMessage = [[NSMenuItem alloc] initWithTitle:@"No sessions" action:nil keyEquivalent:@""];
        dirInfo =
            [NSRegularExpression regularExpressionWithPattern:@"^(?:\\d+|No) Sockets?(?: found)? in (/.+)\\.$"
                                                  options:NSRegularExpressionAnchorsMatchLines
                                                    error:nil];
        sessInfo =
            [NSRegularExpression regularExpressionWithPattern:@"^\\s+(\\d+)\\.(.+?)(?:\\t\\(.+?\\))?\\t\\((Detached|Attached)\\)$"
                                                  options:NSRegularExpressionAnchorsMatchLines
                                                    error:nil];
    }
    return self;
}

- (NSUInteger)count
{
    return [sessionList count];
}

- (void)setMenu:(NSMenu*)newMenu
{
    if (nil != menu) [menu removeItem:emptyMessage];
    menu = newMenu;
    [menu insertItem:emptyMessage atIndex:0];
}

- (NSMenuItem*)remoteSubmenuTo:(NSString*)newServer
{
    serverName = newServer;
    [self setMenu:[[NSMenu alloc] init]];
    NSMenuItem *remoteMenuItem = [[NSMenuItem alloc]
        initWithTitle:newServer action:nil keyEquivalent:@""];
    [remoteMenuItem setSubmenu:menu];
    [self updateSessionsWithoutDelay];
    return remoteMenuItem;
}

- (NSTask*)updateSessionsWithoutDelay
{
    // only run a single update at a time
    if (self.updating) return nil;
    self.updating = YES;

    NSPipe* outPipe = [NSPipe pipe];
    NSTask* screenLs = [[NSTask alloc] init];
    if (serverName) {
        NSLog(@"updating remote session for %@", serverName);
        [screenLs setLaunchPath:@"/usr/bin/ssh"];
        [screenLs setArguments:@[serverName, @"screen", @"-ls"]];
    } else {
        [screenLs setLaunchPath:@"/usr/bin/screen"];
        [screenLs setArguments:@[@"-ls"]];
    }
    [screenLs setStandardOutput:outPipe];
    [screenLs setTerminationHandler:^(NSTask *task) {
        NSFileHandle* outHandle = [[task standardOutput] fileHandleForReading];
        NSString *result = [[NSString alloc] initWithData:[outHandle readDataToEndOfFile]
                                      encoding:NSUTF8StringEncoding];
        [self readSessionsFromString:result failedWithError:nil];
        [self updateMenu];
        if (self.callback) { self.callback(self); }
        self.updating = NO;
    }];
    [screenLs launch];
    return screenLs;
}
- (void)updateSessions
{
    [[self updateSessionsWithoutDelay] waitUntilExit]; // XXX sets screenDir before watchForChanges is called
}

- (void)reattachSession:(ScreenSession*)session
{
    NSString *command;
    if (serverName) {
        command = [NSString stringWithFormat:@"ssh -tA %@ %@", serverName, [session reattachCommand]];
    } else {
        command = [session reattachCommand];
    }
    [self.terminalRunner terminalWithCommand:command andTitle:[session name]];
    [session setAttached];
}

- (void)reattachAllSessions
{
    [sessionList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop)
     {
         ScreenSession *s = obj;
         if ([s isDetached]) {
            [self.terminalRunner terminalWithCommand:[s reattachCommand] andTitle:[s name]];
         }
     }];
}

- (void)startSessionWithName:(NSString*)name
{
    [self.terminalRunner terminalWithCommand:[ScreenSession createSessionCommand:name] andTitle:name];
    [emptyMessage setHidden:YES];
    [menu insertItem:[[NSMenuItem alloc] initWithTitle:name action:nil keyEquivalent:@""]
              atIndex:0];
}

- (void)updateMenu
{
    if (!menu) return;
    [emptyMessage setHidden:NO];
    while ([menu itemAtIndex:0] != emptyMessage){
        [menu removeItemAtIndex:0];
    }
    [sessionList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop)
    {
        [emptyMessage setHidden:YES];
        ScreenSession *s = obj;
        [menu insertItem:[s menuItemWithTarget:self
                     selector:@selector(attachSessionFromMenu:)] atIndex:0];
    }];
}

// attach a detached session from a menu item
- (IBAction)attachSessionFromMenu:(id)item
{
    [self reattachSession:[(NSMenuItem*)item representedObject]];
    [(NSMenuItem*)item setAction:nil];
}


- (void)watchForChanges
{
    [self updateSessions];
    
    if (fsStream != NULL) {
        FSEventStreamStop(fsStream);
        FSEventStreamUnscheduleFromRunLoop(fsStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        FSEventStreamInvalidate(fsStream);
        FSEventStreamRelease(fsStream);
        fsStream = NULL;
    }

    void *appPointer = (__bridge void *)self;
    NSArray *pathsToWatch = [NSArray arrayWithObject:screenDir];
    FSEventStreamContext context = {0, appPointer, NULL, NULL, NULL};
    fsStream = FSEventStreamCreate(NULL, &updateSession_cb, &context, (__bridge CFArrayRef)pathsToWatch, kFSEventStreamEventIdSinceNow, 0.4, kFSEventStreamCreateFlagFileEvents);
    FSEventStreamScheduleWithRunLoop(fsStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(fsStream);
}

-(void)readSessionsFromString:(NSString*)sessions failedWithError:(NSError*)error
{
    NSRange range = NSMakeRange(0,sessions.length);
    NSTextCheckingResult* result = [dirInfo firstMatchInString:sessions options:0 range:range];
    if (result.range.location != NSNotFound)
        screenDir = [sessions substringWithRange:[result rangeAtIndex:1]];

    [sessionList removeAllObjects];
    [sessInfo enumerateMatchesInString:sessions options:0 range:range
                            usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flag, BOOL *stop)
    {
        NSUInteger pid = [[sessions substringWithRange:[result rangeAtIndex:1]] integerValue];
        NSString *name = [sessions substringWithRange:[result rangeAtIndex:2]];
        NSString *state = [sessions substringWithRange:[result rangeAtIndex:3]];

        if ([state compare:@"Detached"] == NSOrderedSame) {
            [sessionList addObject:[ScreenSession detachedSessionWithName:name pid:pid]];
        } else {
            [sessionList addObject:[ScreenSession attachedSessionWithName:name pid:pid]];
        }
    }];
}

- (BOOL)hasDetachedSessions
{
    BOOL __block hasDetached = NO;
    [sessionList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        if ([(ScreenSession*)obj isDetached]) {
            hasDetached = YES;
            *stop = YES;
        }
    }];
    return hasDetached;
}

@end
