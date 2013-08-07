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

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSStatusItem* statusItem;
    SessionManager* sessions;
    TerminalRunner* terminal;
    
    // status icons
    NSImage* iconDetached;
    NSImage* iconActive;
    NSImage* iconEmpty;
 }

@property (assign) IBOutlet NSMenu *menu;
@property (assign) IBOutlet NSPanel *sessionPanel;
@property (assign) IBOutlet NSTextField *sessionName;
@property (assign) IBOutlet NSMenuItem *emptyMessage;
@property (assign) IBOutlet NSWindow *quitWindow;
@property (assign) IBOutlet NSWindow *prefWindow;
@property (assign) IBOutlet NSTextField *versionLabel;

- (IBAction)startSession:(id)selector;
- (IBAction)showNewSessionWindow:(id)selector;
- (IBAction)showPreferences:(id)selector;
- (IBAction)doUpdate:(id)selector;
- (IBAction)ignoreDetachedSessions:(id)selector;
- (IBAction)reopenDetachedSessions:(id)selector;

@end
