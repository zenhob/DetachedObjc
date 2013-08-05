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

    [self setupDefaults:[NSUserDefaults standardUserDefaults]];

    __unsafe_unretained typeof(self) mySelf = self; // for referencing self in a block
    sessions = [[SessionManager alloc] init];
    [sessions setUpdateCallback:^(SessionManager* manager) {
        [mySelf handleSessionUpdate:manager];
    }];
    [sessions watchForChanges];
}

- (void)setupDefaults:(NSUserDefaults*)defaults
{
    [defaults registerDefaults:@{
        @"OpenTerminalTabs": @YES,
        @"WarnOnQuit": @YES,
    }];
    if ([defaults boolForKey:@"OpenTerminalTabs"]) {
    	[_tabOption setState:NSOnState];
    } else {
    	[_tabOption setState:NSOffState];
    }
    if ([defaults boolForKey:@"WarnOnQuit"]) {
    	[_warnOption setState:NSOnState];
    } else {
    	[_warnOption setState:NSOffState];
    }
}

- (IBAction)toggleWarnOnQuit:(id)selector
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"WarnOnQuit"]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"WarnOnQuit"];
    	[_warnOption setState:NSOffState];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"WarnOnQuit"];
    	[_warnOption setState:NSOnState];
    }
}

- (IBAction)toggleTerminalTabs:(id)selector
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"OpenTerminalTabs"]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"OpenTerminalTabs"];
    	[_tabOption setState:NSOffState];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"OpenTerminalTabs"];
    	[_tabOption setState:NSOnState];
    }
}

- (void)handleSessionUpdate:(SessionManager*) manager
{
    if ([manager hasDetachedSessions]) {
        [statusItem setImage:iconDetached];
        [statusItem setToolTip:@"There are detached screen sessions."];
    } else {
        [statusItem setImage:iconEmpty];
        [statusItem setToolTip:@"No detached screen sessions."];
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
        [_quitWindow center];
        [_quitWindow orderFront:sender];
        [_quitWindow makeKeyWindow];
        return NSTerminateLater;
    } else {
        return NSTerminateNow;
    }
}

// display the "new session" window
- (IBAction)showNewSessionWindow:(id)selector
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [_sessionPanel center];
    [_sessionPanel orderFront:selector];
    [_sessionPanel makeKeyWindow];
}

// start a new session
- (IBAction)startSession:(id)selector
{
    [_sessionPanel orderOut:selector];
    NSString *name = [_sessionName stringValue];
    runTerminalWithCommand([ScreenSession createSessionCommand:name], name,
        [[NSUserDefaults standardUserDefaults] boolForKey:@"OpenTerminalTabs"]);
    [_emptyMessage setHidden:YES];
    [_menu insertItem:[[NSMenuItem alloc] initWithTitle:name action:nil keyEquivalent:@""]
              atIndex:[[sessions sessionList] count]];
}

// attach a detached session
- (IBAction)attachSession:(id)item
{ // this is manually attached at runtime
    ScreenSession* session = [(NSMenuItem*)item representedObject];
    runTerminalWithCommand([session reattachCommand], [session name],
           [[NSUserDefaults standardUserDefaults] boolForKey:@"OpenTerminalTabs"]);
    [session setAttached];
}

// manually update the session list
- (IBAction)doUpdate:(id)selector
{
    [sessions updateSessions];
}

// quit ignoring detached sessions
- (IBAction)ignoreDetachedSessions:(id)selector
{
    [[NSApplication sharedApplication] replyToApplicationShouldTerminate:YES];
}

// reattach all sessions and quit
- (IBAction)reopenDetachedSessions:(id)selector
{
    [[sessions sessionList] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop)
     {
         ScreenSession *s = obj;
         if ([s isDetached]) {
            runTerminalWithCommand([s reattachCommand], [s name],
                [[NSUserDefaults standardUserDefaults] boolForKey:@"OpenTerminalTabs"]);
         }
     }];
    [[NSApplication sharedApplication] replyToApplicationShouldTerminate:YES];
}

@end
