//
//  AppDelegate.m
//  Detached
//
//  Created by Zack Hobson on 7/21/13.
//  Copyright (c) 2013 Zack Hobson. All rights reserved.
//

#import "AppDelegate.h"

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
    
    sessions = [SessionManager getManager];
    [sessions watchForChanges:^ {
        if ([sessions hasDetachedSessions]) {
            [statusItem setImage:iconDetached];
        } else {
            [statusItem setImage:iconEmpty];
        }
    }];


}

- (IBAction)showSessionWindow:(id)selector
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [[self sessionPanel] center];
    [[self sessionPanel] orderFront:selector];
    [[self sessionPanel] makeKeyWindow];
}

- (IBAction)startSession:(id)selector
{
    [[self sessionPanel] orderOut:selector];
    NSString *name = [[self sessionName] stringValue];
    [self startTerminal:name];
}

- (IBAction)doUpdate:(id)selector
{
    [sessions updateSessions];

}

- (void)startTerminal:(NSString *)name
{
    // TODO start a session with the given name
}



@end
