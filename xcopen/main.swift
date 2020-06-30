//  Created by Erica Sadun on 6/12/20.

import Foundation
import ArgumentParser
import MacUtility
import GeneralUtility

struct Xcopen: ParsableCommand {

    // The Swift argument parser doesn't _quite_ match the utility needs
    // so this implements pseudo-subcommands, requiring a mocked-up discussion.
    static var configuration = CommandConfiguration(discussion: """
    xcopen <files>...        Open files in Xcode.
    xcopen docs              Open .md and .txt files.
    xcopen new               Create new files (if they don't exist) and
                             open in Xcode.
    xcopen newpg ios|mac|tv  Build a new playground.
    xcopen xc|ws|pg          Open xcodeproj, workspace, or playground.
    xcopen pkg|xpkg          Open Package.swift in TextEdit or Xcode.
    """)


    @Argument(help: "Files to open. If blank, opens xcworkspace or,if not found, searches for xcodeproj.")
    var paths: [String] = []

    @Flag(name: [.customShort("b"), .customLong("bg", withSingleDash: true), .customLong("background")], help: "Open Xcode in the background")
    var openInBackground = false

    /// Open `xcworkspace`, `xcodeproj`, and `playground` files in the working
    /// directory. If workspaces are found, they are opened. Otherwise, all project and playground
    /// files are opened. If no known types are found, do nothing.
    func openKnownTypes() throws {
        let cwd = FileManager.default.currentDirectoryPath
        let hasWorkspace = try !FileManager.default.contentsOfDirectory(atPath: cwd)
            .filter({ $0.hasSuffix(".xcworkspace") }).isEmpty
        switch hasWorkspace {
        case true:
            try Utility.searchAndOpen([".xcworkspace"], bg: openInBackground)
        case false:
            try Utility.searchAndOpen([".xcodeproj", ".playground"], bg: openInBackground)
        }
    }

    func run() throws {
        // Handle the empty paths case first. Everything else references the paths list.
        guard !paths.isEmpty else {
            try openKnownTypes()
            return
        }

        // Subcommands without being subcommands, allowing the utility
        // to be called without any arguments
        if paths.count == 1 {
            switch paths[0] {

            // Open workspaces
            case "ws":
                try Utility.searchAndOpen([".xcworkspace"], bg: openInBackground)
                return

            // Open projects
            case "xc":
                try Utility.searchAndOpen([".xcodeproj"], bg: openInBackground)
                return

            // Open playgrounds
            case "pg":
                try Utility.searchAndOpen([".playground"], bg: openInBackground)
                return

            // Open docs
            case "docs":
                try Utility.searchAndXcodeOpen([".txt", ".md"], bg: openInBackground)
                return

            // Open Package.swift in Textedit
            case "pkg":
                try Utility.openPkgInTextEdit()
                return

            // Open Package.swift in Xcode
            case "xpkg":
                try Utility.searchAndXcodeOpen(["Package.swift"], bg: openInBackground)
                return

            // This degenerate case is handled below
            case "new":
                break

            default:
                break
            }
        }

        // Special case "new" as the first file mentioned
        if paths[0] == "new" {
            guard paths.count > 1
            else { throw RuntimeError("No new files to create.") }
            try Utility.createNewFilesAndOpen(Array<String>(paths.dropFirst()), bg: openInBackground)
            return
        }

        // Playground creation is always `newpg type`
        if paths[0] == "newpg" {
            guard paths.count == 2
            else { throw RuntimeError("Specify playground type (mac, ios).") }

            switch paths[1].lowercased() {
            case "mac", "macos", "osx":
                try Utility.buildNewPlayground(type: .macos, bg: openInBackground)
            case "ios":
                try Utility.buildNewPlayground(type: .ios, bg: openInBackground)
            case "tv", "tvos":
                try Utility.buildNewPlayground(type: .tvos, bg: openInBackground)
            default:
                throw RuntimeError("Unsupported playground type (mac, ios).")
            }
            return
        }

        // Separate standard, dir, and flat paths
        let (standardPaths, remainingPaths) = paths.partition { path in
            for ext in ["xcodeproj", "xcworkspace", "playground"] {
                if path.trimmedDirPath().hasSuffix(ext) { return true }
            }
            return false
        }
        let (dirPaths, flatPaths) = remainingPaths.partition { $0.isDir() }

        // Open the standard paths
        if !standardPaths.isEmpty {
            try Utility.searchAndOpen(standardPaths.map({ $0.trimmedDirPath() }), bg: openInBackground)
        }

        // Open flat paths
        if !flatPaths.isEmpty {
            try Utility.xcopen(flatPaths, bg: openInBackground)
        }

        // Treat each folder as individual open-without-argument scenarios
        for dirPath in dirPaths {
            if FileManager.default.changeCurrentDirectoryPath(dirPath) {
                try openKnownTypes()
            }
        }
    }
}

Xcopen.main()
