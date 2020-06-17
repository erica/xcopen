# xcopen

Because sometimes you really just want to cd and open whatever xcode project is in that folder.

```
USAGE: xcopen [<files> ...] [-a] [-d] [-n] [-b]

ARGUMENTS:
<files>                 Files to open. Leave blank to search for xcodeproj
                        and xcworkspace in the working directory 

OPTIONS:
-all, -a                In addition, open Package.swift 
-docs, -d               Open all .md and .txt files 
-new, -n                Create new files and then open them in Xcode 
-background, -bg, -b    Open Xcode in the background 
-h, --help              Show help information.
```


## Installation

* Install [homebrew](https://brew.sh).
* Install [mint](https://github.com/yonaskolb/Mint) with homebrew (`brew install mint`).
* From command line: `mint install erica/xcopen`

## Build notes

* This project includes a build phase that writes to /usr/local/bin
* Make sure your /usr/local/bin is writable: `chmod u+w /usr/local/bin`
