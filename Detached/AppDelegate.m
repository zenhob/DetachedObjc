//
//  AppDelegate.m
//  Detached
//
//  Created by Zack Hobson on 7/21/13.
//  Copyright (c) 2013 Zack Hobson. All rights reserved.
//

#import "AppDelegate.h"
#import "ScreenSession.h"

static NSString
    *OptUseTabs = @"OpenTerminalTabs",
    *OptWarnOnQuit = @"WarnOnQuit",
    *OptITerm = @"UseITerm2";

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    statusItem = [[NSStatusBar systemStatusBar]
                  statusItemWithLength:NSVariableStatusItemLength];
    iconDetached = [NSImage imageNamed:@"app.tif"];
    iconActive = [NSImage imageNamed:@"app_a.tif"];
    iconEmpty = [NSImage imageNamed:@"app_x.tif"];

    // set up the menu bar item
    [statusItem setMenu:self.menu];
    [statusItem setHighlightMode:YES];
    [statusItem setAlternateImage:iconActive];
    [statusItem setImage:iconEmpty];

    // set up user defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        OptUseTabs: @YES,
        OptWarnOnQuit: @YES,
        OptITerm: @NO
    }];
    hasITerm = (nil != [[NSWorkspace sharedWorkspace] fullPathForApplication:@"iTerm"]);

    // prepare the terminal runner
    terminal = [[TerminalRunner alloc]
        initUsingTabs:[[NSUserDefaults standardUserDefaults] boolForKey:OptUseTabs]
        andITerm:(hasITerm && [[NSUserDefaults standardUserDefaults] boolForKey:OptITerm])];

    // prepare the prefs window
    [self.iTermOption setEnabled:hasITerm];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notifyTerminalSettingChange:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];

    // prepare the session manager
    localSessions = [[SessionManager alloc] initWithRunner:terminal];
    [localSessions setMenu:self.menu];
    __unsafe_unretained typeof(self) mySelf = self;
    [localSessions setCallback:^(SessionManager *manager) {
       [mySelf setDetached:[manager hasDetachedSessions]];
    }];
    [localSessions watchForChanges];

    // XXX prepare a remote session manager
    remoteSessions = [[SessionManager alloc] initWithRunner:terminal];
    NSMenuItem *remoteMenuItem = [[NSMenuItem alloc]
        initWithTitle:@"subscreen!" action:nil keyEquivalent:@""];
    NSMenu *remoteMenu = [[NSMenu alloc] init];
    [self.menu insertItem:remoteMenuItem atIndex:[localSessions count]+1];
    [remoteMenuItem setSubmenu:remoteMenu];
    [remoteSessions setMenu:remoteMenu];
}

- (void)setDetached:(BOOL)isDetached
{
    if (isDetached) {
        [statusItem setImage:iconDetached];
        [statusItem setToolTip:@"There are detached sessions"];
    } else {
        [statusItem setImage:iconEmpty];
        [statusItem setToolTip:@"No detached sessions"];
    }
}

// avoid terminating with detached sessions
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:OptWarnOnQuit]) {
        return NSTerminateNow;
    } else if ([localSessions hasDetachedSessions]) {
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        [self.quitWindow makeKeyAndOrderFront:sender];
        return NSTerminateLater;
    } else {
        return NSTerminateNow;
    }
}

- (IBAction)showAbout:(id)selector
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [[NSApplication sharedApplication]
        orderFrontStandardAboutPanelWithOptions:[[NSBundle mainBundle] infoDictionary]];
}

// display the "new session" window
- (IBAction)showNewSessionWindow:(id)selector
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [_sessionPanel makeKeyAndOrderFront:selector];
}

// display the preferences window
- (IBAction)showPreferences:(id)selector
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [_prefWindow makeKeyAndOrderFront:selector];
}

// start a new session
- (IBAction)startSession:(id)selector
{
    [_sessionPanel orderOut:selector];
    NSString *name = [_sessionName stringValue];
    [localSessions startSessionWithName:name];
}

// manually update the session list
- (IBAction)doUpdate:(id)selector
{
    [localSessions updateSessions];
}

// allow quit, ignoring detached sessions
- (IBAction)ignoreDetachedSessions:(id)selector
{
    [[NSApplication sharedApplication] replyToApplicationShouldTerminate:YES];
}

// reattach all sessions and allow quit
- (IBAction)reopenDetachedSessions:(id)selector
{
    [localSessions reattachAllSessions];
    [[NSApplication sharedApplication] replyToApplicationShouldTerminate:YES];
}

- (void)notifyTerminalSettingChange:(NSNotification*)notification
{
    NSUserDefaults* defaults = [notification object];
    [terminal setUseTabs:[defaults boolForKey:OptUseTabs]];
    [terminal setITerm:(hasITerm && [defaults boolForKey:OptITerm])];
}

@end
