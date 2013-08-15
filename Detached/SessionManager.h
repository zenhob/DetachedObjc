//
//  SessionManager.h
//  Detached
//
//  Created by Zack Hobson on 7/21/13.
//  Copyright (c) 2013 Zack Hobson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScreenSession.h"
#import "TerminalRunner.h"

@interface SessionManager : NSObject {
    NSMutableArray* sessionList; // actual session data
    FSEventStreamRef fsStream; // watches session dir
    NSString* screenDir; // session dir path
    NSRegularExpression *dirInfo;
    NSRegularExpression *sessInfo;
    NSMenuItem *emptyMessage;
    NSMenu *menu;
}

@property SEL callbackSelector;
@property(weak) id callbackObject;
@property(weak) TerminalRunner *terminalRunner;

- (void)setMenu:(NSMenu*)newMenu;
- (BOOL)hasDetachedSessions;
- (void)updateSessions;
- (void)watchForChanges;
- (void)readSessionsFromString:(NSString*)sessions failedWithError:(NSError*)error;
- (void)reattachSession:(ScreenSession*)session;
- (void)reattachAllSessions;
- (IBAction)attachSessionFromMenu:(id)item;
- (void)startSessionWithName:(NSString*)name;

@end
