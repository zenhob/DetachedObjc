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
    ScreenSession *session = [[self alloc] init];
    session.name = name;
    session.pid = pid;
    session.state = ScreenSessionAttachedState;
    return session;
}

+(ScreenSession*)detachedSessionWithName:(NSString *)name pid:(NSUInteger)pid
{
    ScreenSession *session = [ScreenSession attachedSessionWithName:name pid:pid];
    session.state = ScreenSessionDetachedState;
    return session;
}

-(NSMenuItem*)menuItemWithTarget:(id)target selector:(SEL)selector
{
    NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:[self name] action:selector keyEquivalent:@""];
    [item setEnabled:[self isDetached]];
    [item setRepresentedObject:self];
    [item setTarget:target];
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

- (NSString*)reattachCommandLine
{
    return @"foobaz";
}
@end

