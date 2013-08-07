--
--  TerminalSuite.applescript
--  Detached
--
--  Created by Zack Hobson on 8/4/13.
--  Copyright (c) 2013 Zack Hobson. All rights reserved.
--

on terminalWindow(shellCommand, customName)
	tell application "Terminal"
		activate
		do script shellCommand & " && exit"
		tell last window to set custom title to customName
	end tell
end terminalWindow

on terminalTab(shellCommand, customName)
	tell application "Terminal"
		activate
		tell application "System Events"
			tell process "Terminal"
				keystroke "t" using command down
			end tell
		end tell
		do script shellCommand & " && exit" in last tab of last window
		tell window 1 to set custom title to customName
	end tell
end terminalTab

on itermWindow(shellCommand, customName)
	tell application "iTerm"
		activate
		set term to (make new terminal)
		tell term
			set mysession to (make new session at the end of sessions)
			tell mysession
				set name to customName
				exec command shellCommand
			end tell
		end tell
	end tell
end itermWindow

on itermTab(shellCommand, customName)
	tell application "iTerm"
		set term to (current terminal)
		try
			get term
		on error
			set term to (make new terminal)
		end try
		tell term
			set mysession to (make new session at the end of sessions)
			tell mysession
				exec command shellCommand
				set name to customName
			end tell
		end tell
	end tell
end itermTab
