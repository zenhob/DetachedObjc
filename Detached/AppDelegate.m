//
//  AppDelegate.m
//  Detached
//
//  Created by Zack Hobson on 7/21/13.
//  Copyright (c) 2013 Zack Hobson. All rights reserved.
//

#import "AppDelegate.h"
#import "ScreenSession.h"

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

    __unsafe_unretained typeof(self) mySelf = self; // for referencing self in a block
    sessions = [[SessionManager alloc] init];
    [sessions setUpdateCallback:^(SessionManager* manager) {
        if ([manager hasDetachedSessions]) {
            [mySelf->statusItem setImage:mySelf->iconDetached];
        } else {
            [mySelf->statusItem setImage:mySelf->iconEmpty];
        }
        [[mySelf emptyMessage] setHidden:NO];
        while ([[mySelf menu] itemAtIndex:0] != [mySelf emptyMessage]){
            [[mySelf menu] removeItemAtIndex:0];
        }
        [[manager sessionList] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop)
        {
            [[mySelf emptyMessage] setHidden:YES];
            ScreenSession *s = obj;
            [[mySelf menu] insertItem:[s menuItemWithTarget:mySelf
                                                   selector:@selector(attachSession:)] atIndex:0];
        }];
    }];
    [sessions watchForChanges];
}

// avoid terminating with detached sessions
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if ([sessions hasDetachedSessions]) {
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
    [sessions startSessionWithName:name];
    [self.emptyMessage setHidden:YES];
    [[self menu] insertItem:[[NSMenuItem alloc] initWithTitle:name action:nil keyEquivalent:@""]
                    atIndex:[[sessions sessionList] count]];
}

// attach a detached session
- (IBAction)attachSession:(id)item
{ // this is manually attached at runtime
    [(ScreenSession*)[(NSMenuItem*)item representedObject] reattachInTerminal];
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
