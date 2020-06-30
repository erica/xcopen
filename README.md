# xcopen

Because sometimes you really just want to cd and open whatever xcode project is in that folder.

```
OVERVIEW: 
xcopen <files>...        Open files in Xcode.
xcopen docs              Open .md and .txt files.
xcopen new               Create new files (if they don't exist) and
                         open in Xcode.
xcopen newpg ios|mac|tv  Build a new playground.
xcopen xc|ws|pg          Open xcodeproj, workspace, or playground.
xcopen pkg|xpkg          Open Package.swift in TextEdit or Xcode.

USAGE: xcopen [<paths> ...] [-bg]

ARGUMENTS:
  <paths>                 Files to open. If blank, opens xcworkspace or,
                          if not found, searches for xcodeproj. 

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
