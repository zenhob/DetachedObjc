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
    NSRegularExpression *dirInfo;
    NSRegularExpression *sessInfo;
    BOOL hasDetached;
}

typedef void(^SessionManagerCB)(SessionManager*);
@property (strong) SessionManagerCB updateCallback;

- (void)startSessionWithName:(NSString*)name;
- (BOOL)hasDetachedSessions;
- (void)updateSessions;
- (void)watchForChanges;
- (void)readSessionsFromString:(NSString*)sessions failedWithError:(NSError*)error;
- (NSArray*)sessionList;
- (NSString*)screenDir;

@end
