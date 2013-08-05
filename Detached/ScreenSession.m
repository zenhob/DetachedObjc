//
//  ScreenSession.m
//  Detached
//
//  Created by Zack Hobson on 7/23/13.
//  Copyright (c) 2013 Zack Hobson. All rights reserved.
//

#import "ScreenSession.h"
#import "TerminalRunner.h"

@interface ScreenSession ()
@property NSString* name;
@property NSUInteger pid;
@property ScreenSessionState state;
@end

@implementation ScreenSession

+ (NSString*)createSessionCommand:(NSString*)name
{
    return [NSString stringWithFormat:@"screen -t '%@' -S '%@' && exit", name, name];
}

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
    NSMenuItem* item = [[NSMenuItem alloc]
	    initWithTitle:[self name] action:selector keyEquivalent:@""];
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

-(void)setAttached
{
    self.state = ScreenSessionAttachedState;
}

-(BOOL)isDetached
{
    return self.state == ScreenSessionDetachedState;
}

- (NSString*)reattachCommand
{
    return [NSString stringWithFormat:@"screen -r '%@' && exit", self.name];
}

- (void)reattachInTerminal
{
    runTerminalWithCommand([self reattachCommand], YES);
    self.state = ScreenSessionAttachedState;
}
@end

