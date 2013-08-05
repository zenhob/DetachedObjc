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
    do script \"%@ && exit\" in the last tab of window 1\n\
    tell window 1 to set custom title to \"%@\"\n\
end tell\n";

static NSString* terminalWindowScript =
@"tell application \"Terminal\"\n\
    activate\n\
    do script \"%@ && exit\"\n\
    tell window 1 to set custom title to \"%@\"\n\
end tell";

static NSString* iTermWindowScript =
@"tell application \"System Events\"\n\
    tell process \"iTerm\"\n\
        keystroke \"t\" using command down\n\
    end tell\n\
end tell\n\
tell application \"iTerm\"\n\
	activate\n\
	set term to (make new terminal)\n\
	tell term\n\
		set mysession to (make new session at the end of sessions)\n\
		tell mysession\n\
			exec command \"%@\"\n\
			set name to \"%@\"\n\
		end tell\n\
	end tell\n\
end tell";

void runTerminalWithCommand(NSString* command, NSString* title, BOOL newTab, BOOL iTerm2)
{
    NSString* code = newTab ? terminalTabScript : terminalWindowScript;
    code = iTerm2 ? iTermWindowScript : code;
    NSAppleScript* script = [[NSAppleScript alloc]
	    initWithSource:[NSString stringWithFormat:code,
	    [command stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"], title]];
    NSDictionary* error;
    [script executeAndReturnError:&error];
}

void runITerm2WithCommand(NSString* command, NSString* title, BOOL newTab)
{
    //NSString* code = newTab ? terminalTabScript : terminalWindowScript;
    NSAppleScript* script = [[NSAppleScript alloc]
	    initWithSource:[NSString stringWithFormat:iTermWindowScript,
	    [command stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"], title]];
    NSDictionary* error;
    [script executeAndReturnError:&error];
}
