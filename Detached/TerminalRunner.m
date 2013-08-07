//
//  TerminalRunner.m
//  Detached
//
//  Created by Zack Hobson on 8/4/13.
//  Copyright (c) 2013 Zack Hobson. All rights reserved.
//

#import "TerminalRunner.h"
#import <Carbon/Carbon.h>

@implementation TerminalRunner

- (id)initUsingTabs:(BOOL)tabs andITerm:(BOOL)iterm
{
    self = [super init];
    self.useTabs = tabs;
    self.iTerm = iterm;

    NSDictionary* error;
	NSURL *scriptURL = [[NSURL alloc] initFileURLWithPath:[[NSBundle mainBundle]
                                          pathForResource:@"TerminalSuite" ofType:@"scpt"]];
    suite = [[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:&error];

    return self;
}

- (void)terminalWithCommand:(NSString*)command andTitle:(NSString*)title
{
    NSString* handler = self.useTabs
        ? (self.iTerm ? @"itermTab"
                  : @"terminalTab")
        : (self.iTerm ? @"itermWindow"
                  : @"terminalWindow");
    [self callHandler:handler withCommand:command andTitle:title];
}

// this is adapted from the "AttachAScript" sample project in xcode
- (void)callHandler:(NSString *)handlerName 
        withCommand:(NSString*)command andTitle:(NSString*)title
{
	ProcessSerialNumber PSN = {0, kCurrentProcess};
	NSAppleEventDescriptor *theAddress, *theEvent, *paramList;
    NSDictionary *errorInfo;
	
    theAddress = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber
                                                                bytes:&PSN length:sizeof(PSN)];
	if (!theAddress) {
        NSLog(@"Failed to create target address descriptor.");
        return;
    }
    theEvent = [NSAppleEventDescriptor
        appleEventWithEventClass:typeAppleScript 
                         eventID:kASSubroutineEvent targetDescriptor:theAddress 
                        returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
    if (!theEvent) {
        NSLog(@"Failed to create subroutine descriptor.");
        return;
    }
    [theEvent setDescriptor:[NSAppleEventDescriptor
       descriptorWithString:[handlerName lowercaseString]]
                 forKeyword:keyASSubroutineName];
				
    paramList = [NSAppleEventDescriptor listDescriptor];
    [paramList insertDescriptor:[NSAppleEventDescriptor descriptorWithString:command] atIndex:0];
    [paramList insertDescriptor:[NSAppleEventDescriptor descriptorWithString:title] atIndex:0];
    [theEvent setDescriptor:paramList forKeyword:keyDirectObject];

    [suite executeAppleEvent:theEvent error:&errorInfo];
}

@end
