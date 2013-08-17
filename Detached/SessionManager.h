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

@interface SessionManager : NSObject <NSMenuDelegate> {
    NSMutableArray* sessionList; // actual session data
    FSEventStreamRef fsStream; // watches session dir
    NSString* screenDir; // session dir path
    NSRegularExpression *dirInfo;
    NSRegularExpression *sessInfo;
    NSMenuItem *emptyMessage;
    NSMenu *menu;
    NSString *serverName;
}

typedef void (^SessionManagerCallback)(SessionManager*);
@property(strong) SessionManagerCallback callback;
@property(weak) TerminalRunner *terminalRunner;
@property BOOL updating;

- (id)initWithRunner:(TerminalRunner*)runner;
- (void)setMenu:(NSMenu*)newMenu;
- (BOOL)hasDetachedSessions;
- (void)updateSessions;
- (void)watchForChanges;
- (void)readSessionsFromString:(NSString*)sessions failedWithError:(NSError*)error;
- (void)reattachSession:(ScreenSession*)session;
- (void)reattachAllSessions;
- (IBAction)attachSessionFromMenu:(id)item;
- (void)startSessionWithName:(NSString*)name;
- (NSUInteger)count;
- (NSMenuItem*)remoteSubmenuTo:(NSString*)newServer;

@end
