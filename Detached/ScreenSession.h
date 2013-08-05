//
//  ScreenSession.h
//  Detached
//
//  Created by Zack Hobson on 7/23/13.
//  Copyright (c) 2013 Zack Hobson. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ScreenSessionAttachedState = 1 << 0,
    ScreenSessionDetachedState = 1 << 1
} ScreenSessionState;

@interface ScreenSession : NSObject

@property (readonly) NSString* name;
@property (readonly) NSUInteger pid;
@property (readonly) ScreenSessionState state;

+ (NSString*)createSessionCommand:(NSString*)name;
+ (ScreenSession*)attachedSessionWithName:(NSString *)name pid:(NSUInteger)pid;
+ (ScreenSession*)detachedSessionWithName:(NSString *)name pid:(NSUInteger)pid;

- (NSMenuItem*)menuItemWithTarget:(id)target selector:(SEL)selector;
- (BOOL)isAttached;
- (void)setAttached;
- (BOOL)isDetached;
- (void)reattachInTerminal;
- (NSString*)reattachCommand;

@end
