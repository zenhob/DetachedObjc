//
//  SessionManager.m
//  Detached
//
//  Created by Zack Hobson on 7/21/13.
//  Copyright (c) 2013 Zack Hobson. All rights reserved.
//

#import "SessionManager.h"

void updateSession_cb(
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

-(id)init
{
    screenDir = nil;
    sessionList = [[NSMutableArray alloc] init];
    dirInfo =
        [NSRegularExpression regularExpressionWithPattern:@"^(?:\\d+|No) Sockets?(?: found)? in (/.+)\\.$"
                                              options:NSRegularExpressionAnchorsMatchLines
                                                error:nil];
    sessInfo =
        [NSRegularExpression regularExpressionWithPattern:@"^\\s+\\d+\\.(.+?)\\s*\\((Detached|Attached)\\)$"
                                              options:NSRegularExpressionAnchorsMatchLines
                                                error:nil];
    return self;
}

- (NSArray*)sessionList
{
    return (NSArray*)sessionList;
}

- (NSString*)screenDir
{
    return screenDir;
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
    fsStream = FSEventStreamCreate(NULL, &updateSession_cb, &context, (__bridge CFArrayRef)pathsToWatch, kFSEventStreamEventIdSinceNow, 1.0, kFSEventStreamCreateFlagFileEvents);
    FSEventStreamScheduleWithRunLoop(fsStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(fsStream);
}

- (BOOL)hasDetachedSessions
{
    return YES;
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
        [sessionList addObject:[sessions substringWithRange:[result rangeAtIndex:1]]];
    }];
}

- (void)updateSessions
{
    NSPipe* outPipe = [NSPipe pipe];
    NSFileHandle* outHandle = [outPipe fileHandleForReading];
    NSTask* screenLs = [[NSTask alloc] init];
    [screenLs setLaunchPath:@"/usr/bin/screen"];
    [screenLs setArguments:@[@"-ls"]];
    [screenLs setStandardOutput:outPipe];
    [screenLs launch];
    [screenLs waitUntilExit];
    NSString *result = [[NSString alloc] initWithData:[outHandle readDataToEndOfFile]
                                         encoding:NSUTF8StringEncoding];
    [self readSessionsFromString:result failedWithError:nil];
    [self updateCallback](self);
}

@end
