//
//  SessionManager.h
//  Detached
//
//  Created by Zack Hobson on 7/21/13.
//  Copyright (c) 2013 Zack Hobson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SessionManager : NSObject {
    NSMutableArray* sessionList; // actual session data
    FSEventStreamRef fsStream; // watches session dir
    NSString* screenDir; // session dir path
}

+ (SessionManager*)getManager;

- (BOOL)hasDetachedSessions;
- (void)updateSessions;
- (void)watchForChanges:(void(^)(void))callback;
- (void)readSessionsFromString:(NSString*)sessions failedWithError:(NSError*)error;
- (NSArray*)sessionList;
- (NSString*)screenDir;

@end
