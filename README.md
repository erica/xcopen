# xcopen

Because sometimes you really just want to cd and open whatever xcode project is in that folder.

```
OVERVIEW: 
xcopen <files>...        Open files in Xcode.
xcopen                   Open workspace or xcodeproj.
xcopen ws                Only search for workspace.
xcopen xc                Only search for xcodeproj.
xcopen docs              Open .md and .txt files.
xcopen pkg               Open Package.swift in TextEdit.
xcopen xpkg              Open Package.swift in Xcode.
xcopen new               Create new files (if they don't exist) and
open in Xcode.

USAGE: xcopen [<paths> ...] [-bg]

ARGUMENTS:
<paths>                 Files to open. If blank, opens xcworkspace or, if not
                        found, searches for xcodeproj. 

OPTIONS:
-b, -bg, --background   Open Xcode in the background 
-h, --help              Show help information.
```


## Installation

* Install [homebrew](https://brew.sh).
* Install [mint](https://github.com/yonaskolb/Mint) with homebrew (`brew install mint`).
* From command line: `mint install erica/xcopen`

## Build notes

* This project includes a build phase that writes to /usr/local/bin
* Make sure your /usr/local/bin is writable: `chmod u+w /usr/local/bin`
