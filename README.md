# xcopen

Because sometimes you really just want to cd and open whatever xcode project is in that folder.

Xcopen also builds new files, and creates playgrounds and their hosting workspaces.

```
OVERVIEW: 
xcopen <files>...        Open files in Xcode.
xcopen docs              Open .md and .txt files.
xcopen new               Create new files (if they don't exist), open in Xcode.
xcopen xc|ws|pg(w)       Open xcodeproj, workspace, or playground.
                           * Add ios|mac|tvos to create playground.
                           * Add w (pgw) to create playground in workspace.
xcopen pkg|xpkg          Open Package.swift in TextEdit or Xcode.
xcopen uireset           Reset uistate/recent files. (Quits xcode.)

USAGE: xcopen [<paths> ...] [--background] [--folder] [--open] [--no-open]

ARGUMENTS:
  <paths>                 Files to open. If blank, opens xcworkspace or,if not
                          found, searches for xcodeproj. 

OPTIONS:
  -b, -g, --background    Open Xcode in the background 
  -f, -e, --folder        Enclose new items in folder 
  --open/--no-open        Open newly created playgrounds/workspaces (default:
                          true)
  -h, --help              Show help information.
```

## Installation

* Install [homebrew](https://brew.sh).
* Install [mint](https://github.com/yonaskolb/Mint) with homebrew (`brew install mint`).
* From command line: `mint install erica/xcopen`

## Build notes

* This project includes a build phase that writes to /usr/local/bin
* Make sure your /usr/local/bin is writable: `chmod u+w /usr/local/bin`
