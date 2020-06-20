# CHANGELOG

## 0.0.7
Some undocumented "subcommand"-like personal tweaks for my own use:

* `xcopen ws`: opens workspace in cwd
* `xcopen docs`: same as `xcopen -docs`
* `xcopen pkg`: same as undocumented `xcopen -pkg`
* `xcopen xpkg`: opens package in cwd in Xcode
* `xcopen <path-to-directory>`: opens non-dir files within that directory in Xcode, e.g. `xcopen Sources` or `xcopen .`

## 0.0.6
* Minor code cleanup

## 0.0.5
* All of -h, -help, and --help will work but the double-dash version does not appear in usage.
* Decided to hide `-focus`. It's still there but it's really not for everyone. If there were long help in the argument parser, I'd include it with a caution in long help. No change in functionality, it just won't appear in usage.

## 0.0.4
* Bugfix: dependencies should no longer fail
* Added `-focus` for Paul Hudson. It may or may not work for you and relies on the localization of the menus to match my localization.
* Secret feature: -pkg opens Package.swift in TextEdit

## 0.0.3

* Add swift-argument-parser support with help
* Open xcworkspace as well as xcodeproj
* Optionally (-all) also open Package.swift
* Open docs
* Create new files and open them in Xcode
* Open with Xcode in background

## 0.0.2

Roll back Swift tools to 5.1 to support Mojave

## 0.0.1

Initial Commit

