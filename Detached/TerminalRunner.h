//
//  TerminalRunner.h
//  Detached
//
//  Created by Zack Hobson on 8/4/13.
//  Copyright (c) 2013 Zack Hobson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TerminalRunner : NSObject {
    NSAppleScript* suite;
}

@property BOOL iTerm;
@property BOOL useTabs;

- (id)initUsingTabs:(BOOL)tabs andITerm:(BOOL)iterm;
- (void)terminalWithCommand:(NSString*)command andTitle:(NSString*)title;

@end

