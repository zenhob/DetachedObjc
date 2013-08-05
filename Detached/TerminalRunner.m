//
//  TerminalRunner.m
//  Detached
//
//  Created by Zack Hobson on 8/4/13.
//  Copyright (c) 2013 Zack Hobson. All rights reserved.
//

#import "TerminalRunner.h"

static NSString* terminalTabScript =
@"activate application \"Terminal\"\n\
tell application \"System Events\"\n\
    tell process \"Terminal\"\n\
        keystroke \"t\" using command down\n\
    end tell\n\
end tell\n\
tell application \"Terminal\"\n\
    do script \"%@\" in the last tab of window 1\n\
end tell\n";

static NSString* terminalWindowScript =
@"tell application \"Terminal\"\n\
    activate\n\
    do script \"%@\"\n\
end tell";

void runTerminalWithCommand(NSString* command, BOOL newTab)
{
    NSString* code = newTab ? terminalTabScript : terminalWindowScript;
    NSAppleScript* script = [[NSAppleScript alloc]
	    initWithSource:[NSString stringWithFormat:code, command]];
    NSDictionary* error;
    [script executeAndReturnError:&error];
}
