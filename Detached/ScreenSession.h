//
//  ScreenSession.h
//  Detached
//
//  Created by Zack Hobson on 7/23/13.
//  Copyright (c) 2013 Zack Hobson. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ScreenSessionAttachedState,
    ScreenSessionDetachedState
} ScreenSessionState;

@interface ScreenSession : NSObject

@property (readonly) NSString* name;
@property (readonly) NSUInteger pid;
@property (readonly) ScreenSessionState state;

+ (ScreenSession*)attachedSessionWithName:(NSString *)name pid:(NSUInteger)pid;
+ (ScreenSession*)detachedSessionWithName:(NSString *)name pid:(NSUInteger)pid;

- (NSMenuItem*)menuItemWithTarget:(id)target selector:(SEL)selector;
- (BOOL)isAttached;
- (BOOL)isDetached;
- (void)reattachInTerminal;

@end
