//
//  SessionManager.m
//  Detached
//
//  Created by Zack Hobson on 7/21/13.
//  Copyright (c) 2013 Zack Hobson. All rights reserved.
//

#import "SessionManager.h"

static SessionManager* sessionManager_g;

static NSString* getScreenDirFromScanner(NSScanner* scanner)
{
    NSString *path;
    [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet]
                            intoString:&path];
    // drop the ending period
    return [path stringByReplacingCharactersInRange:(NSRange){[path length]-1,1}
                                         withString:@""];
}

void updateSession_cb(
                      ConstFSEventStreamRef streamRef,
                      void *clientCallBackInfo,
                      size_t numEvents,
                      void *eventPaths,
                      const FSEventStreamEventFlags eventFlags[],
                      const FSEventStreamEventId eventIds[])
{
    [sessionManager_g updateSessions];
}

@implementation SessionManager

+(SessionManager*)getManager
{
    @synchronized(self) {
        if (sessionManager_g == NULL)
            sessionManager_g = [[self alloc] init];
    }
    return sessionManager_g;
}

-(id)init
{
    screenDir = nil;
    sessionList = [[NSMutableArray alloc] init];
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

- (void)watchForChanges:(void(^)(void))callback
{
    if (fsStream != NULL) {
        FSEventStreamStop(fsStream);
        FSEventStreamUnscheduleFromRunLoop(fsStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        FSEventStreamInvalidate(fsStream);
        FSEventStreamRelease(fsStream);
        fsStream = NULL;
    }

    CFStringRef screenDir_cf = (__bridge CFStringRef)screenDir;
    CFArrayRef screenPath = CFArrayCreate(NULL, (const void **)&screenDir_cf, 1, NULL);

    fsStream = FSEventStreamCreate(NULL, &updateSession_cb, NULL, screenPath, kFSEventStreamEventIdSinceNow, 0.3, kFSEventStreamCreateFlagFileEvents);
    FSEventStreamScheduleWithRunLoop(fsStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(fsStream);

    [self updateSessions];
}

- (BOOL)hasDetachedSessions
{
    return YES;
}

-(void)readSessionsFromString:(NSString*)sessions failedWithError:(NSError*)error
{
    [sessionList removeAllObjects];
    NSScanner* scanner = [NSScanner scannerWithString:sessions];

    if ([scanner scanString:@"No Sockets found in" intoString:nil]) {
        screenDir = getScreenDirFromScanner(scanner);
        return;
    }

    NSRange startRange = [sessions rangeOfString:@" on:\r\n"];
    if (startRange.location != NSNotFound) {
        [scanner setScanLocation:startRange.location + startRange.length];
        NSString* sessionLine;
        while (true) {
            if ([scanner scanString:@"Socket in" intoString:nil] ||
                [scanner scanString:@"Sockets in" intoString:nil])
            {
                screenDir = getScreenDirFromScanner(scanner);
                break;
            }

            [scanner scanUpToString:@"\n" intoString:&sessionLine];
            if ([scanner isAtEnd]) {
                break;
            } else {
                [sessionList addObject:sessionLine];
            }
        }
    } else {
        NSLog(@"Unable to scan: %@", sessions);
    }
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
}

@end
