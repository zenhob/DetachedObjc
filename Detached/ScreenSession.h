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

+(ScreenSession*)attachedSessionWithName:(NSString *)name pid:(NSUInteger)pid;
+(ScreenSession*)detachedSessionWithName:(NSString *)name pid:(NSUInteger)pid;

@property (readonly) NSString* name;
@property (readonly) NSUInteger pid;
@property (readonly) ScreenSessionState state;

-(BOOL)isAttached;
-(BOOL)isDetached;


@end
