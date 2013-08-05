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
    	[[self tabOption] setState:NSOnState];
    } else {
    	[[self tabOption] setState:NSOffState];
    }
    if ([defaults boolForKey:@"WarnOnQuit"]) {
    	[[self warnOption] setState:NSOnState];
    } else {
    	[[self warnOption] setState:NSOffState];
    }
}

- (IBAction)toggleWarnOnQuit:(id)selector
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"WarnOnQuit"]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"WarnOnQuit"];
    	[[self warnOption] setState:NSOffState];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"WarnOnQuit"];
    	[[self warnOption] setState:NSOnState];
    }
}

- (IBAction)toggleTerminalTabs:(id)selector
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"OpenTerminalTabs"]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"OpenTerminalTabs"];
    	[[self tabOption] setState:NSOffState];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"OpenTerminalTabs"];
    	[[self tabOption] setState:NSOnState];
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
    [[self emptyMessage] setHidden:NO];
    while ([[self menu] itemAtIndex:0] != [self emptyMessage]){
        [[self menu] removeItemAtIndex:0];
    }
    [[manager sessionList] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop)
    {
         [[self emptyMessage] setHidden:YES];
         ScreenSession *s = obj;
         [[self menu] insertItem:[s menuItemWithTarget:self
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
        [self.quitWindow center];
        [self.quitWindow orderFront:sender];
        [self.quitWindow makeKeyWindow];
        return NSTerminateLater;
    } else {
        return NSTerminateNow;
    }
}

// display the "new session" window
- (IBAction)showNewSessionWindow:(id)selector
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [self.sessionPanel center];
    [self.sessionPanel orderFront:selector];
    [self.sessionPanel makeKeyWindow];
}

// start a new session
- (IBAction)startSession:(id)selector
{
    [self.sessionPanel orderOut:selector];
    NSString *name = [self.sessionName stringValue];
    runTerminalWithCommand([ScreenSession createSessionCommand:name],
        [[NSUserDefaults standardUserDefaults] boolForKey:@"OpenTerminalTabs"]);
    [self.emptyMessage setHidden:YES];
    [[self menu] insertItem:[[NSMenuItem alloc] initWithTitle:name action:nil keyEquivalent:@""]
                    atIndex:[[sessions sessionList] count]];
}

// attach a detached session
- (IBAction)attachSession:(id)item
{ // this is manually attached at runtime
    ScreenSession* session = [(NSMenuItem*)item representedObject];
    runTerminalWithCommand([session reattachCommand], 
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
         if ([s isDetached]) [s reattachInTerminal];
     }];
    [[NSApplication sharedApplication] replyToApplicationShouldTerminate:YES];
}

@end
