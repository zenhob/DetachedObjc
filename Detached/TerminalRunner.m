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
- (NSAppleEventDescriptor*) callHandler:(NSString *)handlerName 
                            withCommand:(NSString*)command andTitle:(NSString*)title
{
	ProcessSerialNumber PSN = {0, kCurrentProcess};
	NSAppleEventDescriptor *theAddress, *theEvent, *theHandlerName, *paramList;
    NSDictionary *errorInfo;
    NSAppleEventDescriptor *theResult;
	
    // build an event descriptor for this handler
    theAddress = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber
                                                                bytes:&PSN length:sizeof(PSN)];
	if (!theAddress) {
        NSLog(@"Failed to create target address descriptor.");
        return nil;
    }
    theEvent = [NSAppleEventDescriptor
        appleEventWithEventClass:typeAppleScript 
                         eventID:kASSubroutineEvent targetDescriptor:theAddress 
                        returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
    if (!theEvent) {
        NSLog(@"Failed to create subroutine descriptor.");
        return nil;
    }
    theHandlerName = [NSAppleEventDescriptor descriptorWithString:[handlerName lowercaseString]];
    if (!theHandlerName) {
        NSLog(@"Failed to create handler name descriptor.");
        return nil;
    }
    [theEvent setDescriptor:theHandlerName forKeyword:keyASSubroutineName];
				
    paramList = [NSAppleEventDescriptor listDescriptor];
    [paramList insertDescriptor:[NSAppleEventDescriptor descriptorWithString:command] atIndex:0];
    [paramList insertDescriptor:[NSAppleEventDescriptor descriptorWithString:title] atIndex:0];
    [theEvent setDescriptor:paramList forKeyword:keyDirectObject];

    // make it so
    theResult = [suite executeAppleEvent:theEvent error:&errorInfo];
    if (nil == theResult) {
        NSString *err = [NSString stringWithFormat:@"Error %@ on %@(%@): %@",
                            [errorInfo objectForKey:NSAppleScriptErrorNumber],
                            handlerName, [NSString stringWithFormat:@"%@, %@", command, title],
                            [errorInfo objectForKey:NSAppleScriptErrorBriefMessage]];
        NSLog(@"%@", err);
        return nil;
    }

    return theResult;
}

@end
