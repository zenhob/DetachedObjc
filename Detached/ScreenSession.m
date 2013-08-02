//
//  ScreenSession.m
//  Detached
//
//  Created by Zack Hobson on 7/23/13.
//  Copyright (c) 2013 Zack Hobson. All rights reserved.
//

#import "ScreenSession.h"

@interface ScreenSession ()
@property NSString* name;
@property NSUInteger pid;
@property ScreenSessionState state;
@end

@implementation ScreenSession

+(ScreenSession*)attachedSessionWithName:(NSString *)name pid:(NSUInteger)pid
{
    ScreenSession* session = [[self alloc] init];
    session.name = name;
    session.pid = pid;
    session.state = ScreenSessionAttachedState;
    return session;
}

+(ScreenSession*)detachedSessionWithName:(NSString *)name pid:(NSUInteger)pid
{
    ScreenSession* session = [ScreenSession attachedSessionWithName:name pid:pid];
    session.state = ScreenSessionDetachedState;
    return session;
}

-(NSMenuItem*)menuItemWithTarget:(id)target selector:(SEL)selector
{
    NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:[self name] action:selector keyEquivalent:@""];
    [item setEnabled:[self isDetached]];
    [item setRepresentedObject:self];
    [item setTarget:target];
    if (![item isEnabled]) {
        [item setAction:nil];
    }
    return item;
}

-(BOOL)isAttached
{
    return self.state == ScreenSessionAttachedState;
}

-(BOOL)isDetached
{
    return self.state == ScreenSessionDetachedState;
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

- (void)reattachInTerminal
{
    NSString* command = [NSString stringWithFormat:@"screen -r '%@' && exit", self.name];
    NSAppleScript* script = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:terminalScript, command]];
    NSDictionary* error;
    [script executeAndReturnError:&error];
    self.state = ScreenSessionAttachedState;
}
@end

