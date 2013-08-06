//
//  AppDelegate.m
//  Detached
//
//  Created by Zack Hobson on 7/21/13.
//  Copyright (c) 2013 Zack Hobson. All rights reserved.
//

#import "AppDelegate.h"
#import "ScreenSession.h"
#import "TerminalRunner.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    statusItem = [[NSStatusBar systemStatusBar]
                  statusItemWithLength:NSVariableStatusItemLength];
    iconDetached = [NSImage imageNamed:@"app.tif"];
    iconActive = [NSImage imageNamed:@"app_a.tif"];
    iconEmpty = [NSImage imageNamed:@"app_x.tif"];

    [statusItem setMenu:[self menu]];
    [statusItem setHighlightMode:YES];
    [statusItem setAlternateImage:iconActive];
    [statusItem setImage:iconEmpty];

    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        @"OpenTerminalTabs": @YES,
        @"WarnOnQuit": @YES,
        @"UseITerm2": @NO
    }];

    __unsafe_unretained typeof(self) mySelf = self; // for referencing self in a block
    sessions = [[SessionManager alloc] init];
    [sessions setUpdateCallback:^(SessionManager* manager) {
        [mySelf handleSessionUpdate:manager];
    }];
    [sessions watchForChanges];
}

- (void)handleSessionUpdate:(SessionManager*) manager
{
    if ([manager hasDetachedSessions]) {
        [statusItem setImage:iconDetached];
        [statusItem setToolTip:@"There are detached screen sessions"];
    } else {
        [statusItem setImage:iconEmpty];
        [statusItem setToolTip:@"No detached screen sessions"];
    }
    [_emptyMessage setHidden:NO];
    while ([_menu itemAtIndex:0] != _emptyMessage){
        [_menu removeItemAtIndex:0];
    }
    [[manager sessionList] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop)
    {
         [_emptyMessage setHidden:YES];
         ScreenSession *s = obj;
         [_menu insertItem:[s menuItemWithTarget:self
                                        selector:@selector(attachSession:)] atIndex:0];
    }];
}

// avoid terminating with detached sessions
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"WarnOnQuit"]) {
        return NSTerminateNow;
    } else if ([sessions hasDetachedSessions]) {
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
        [_quitWindow makeKeyAndOrderFront:sender];
        return NSTerminateLater;
    } else {
        return NSTerminateNow;
    }
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
    runTerminalWithCommand([ScreenSession createSessionCommand:name], name,
        [[NSUserDefaults standardUserDefaults] boolForKey:@"OpenTerminalTabs"],
        [[NSUserDefaults standardUserDefaults] boolForKey:@"UseITerm2"]);
    [_emptyMessage setHidden:YES];
    [_menu insertItem:[[NSMenuItem alloc] initWithTitle:name action:nil keyEquivalent:@""]
              atIndex:0];
}

// attach a detached session
- (IBAction)attachSession:(id)item
{ // this is manually attached at runtime
    ScreenSession* session = [(NSMenuItem*)item representedObject];
    runTerminalWithCommand([session reattachCommand], [session name],
           [[NSUserDefaults standardUserDefaults] boolForKey:@"OpenTerminalTabs"],
           [[NSUserDefaults standardUserDefaults] boolForKey:@"UseITerm2"]);
    [(NSMenuItem*)item setAction:nil];
    [session setAttached];
}

// manually update the session list
- (IBAction)doUpdate:(id)selector
{
    [sessions updateSessions];
}

// allow quit, ignoring detached sessions
- (IBAction)ignoreDetachedSessions:(id)selector
{
    [[NSApplication sharedApplication] replyToApplicationShouldTerminate:YES];
}

// reattach all sessions and allow quit
- (IBAction)reopenDetachedSessions:(id)selector
{
    [[sessions sessionList] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop)
     {
         ScreenSession *s = obj;
         if ([s isDetached]) {
            runTerminalWithCommand([s reattachCommand], [s name],
                [[NSUserDefaults standardUserDefaults] boolForKey:@"OpenTerminalTabs"],
                [[NSUserDefaults standardUserDefaults] boolForKey:@"UseITerm2"]);
         }
     }];
    [[NSApplication sharedApplication] replyToApplicationShouldTerminate:YES];
}

@end
