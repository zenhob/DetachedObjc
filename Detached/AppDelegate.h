//
//  AppDelegate.h
//  Detached
//
//  Created by Zack Hobson on 7/21/13.
//  Copyright (c) 2013 Zack Hobson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SessionManager.h"
#import "TerminalRunner.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate> {
    NSStatusItem *statusItem;
    SessionManager *localSessions;
    SessionManager *remoteSessions;
    NSMenuItem *remoteSessionsItem;
    TerminalRunner *terminal;
    BOOL hasITerm;
    
    // status icons
    NSImage *iconDetached;
    NSImage *iconActive;
    NSImage *iconEmpty;
 }

@property (assign) IBOutlet NSMenu *menu;
@property (assign) IBOutlet NSPanel *sessionPanel;
@property (assign) IBOutlet NSTextField *sessionName;
@property (assign) IBOutlet NSMenuItem *emptyMessage;
@property (assign) IBOutlet NSWindow *quitWindow;
@property (assign) IBOutlet NSWindow *prefWindow;
@property (assign) IBOutlet NSButton *iTermOption;

- (IBAction)startSession:(id)selector;
- (IBAction)showNewSessionWindow:(id)selector;
- (IBAction)showPreferences:(id)selector;
- (IBAction)showAbout:(id)selector;
- (IBAction)doUpdate:(id)selector;
- (IBAction)ignoreDetachedSessions:(id)selector;
- (IBAction)reopenDetachedSessions:(id)selector;

@end
