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

- (IBAction)showSessionWindow:(id)selector
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [self.sessionPanel center];
    [self.sessionPanel orderFront:selector];
    [self.sessionPanel makeKeyWindow];
}

- (IBAction)startSession:(id)selector
{
    [self.sessionPanel orderOut:selector];
    [sessions startSessionWithName:[self.sessionName stringValue]];
}

static NSString* terminalScript = @"activate application \"Terminal\"\n\
    tell application \"System Events\"\n\
        tell process \"Terminal\"\n\
            keystroke \"t\" using command down\n\
        end tell\n\
    end tell\n\
    tell application \"Terminal\"\n\
        do script \"%@\" in the last tab of window 1\n\
    end tell\n";

- (IBAction)attachSession:(id)item
{ // this is manually attached at runtime
    NSString* command = [(ScreenSession*)[(NSMenuItem*)item representedObject] reattachCommandLine];
    NSAppleScript* script = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:terminalScript, command]];
    NSDictionary *error;
    [script executeAndReturnError:&error];
}

- (IBAction)doUpdate:(id)selector
{
    [sessions updateSessions];

}

@end
