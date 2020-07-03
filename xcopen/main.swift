//  Copyright © 2020 Erica Sadun. All rights reserved.

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
    xcopen new               Create new files (if they don't exist), open in Xcode.
    xcopen xc|ws|pg(w)       Open xcodeproj, workspace, or playground.
                               * Add ios|mac|tvos to create playground.
                               * Add w (pgw) to create playground in workspace.
    xcopen pkg|xpkg          Open Package.swift in TextEdit or Xcode.
    """)


    @Argument(help: "Files to open. If blank, opens xcworkspace or,if not found, searches for xcodeproj.")
    var paths: [String] = []

    @Flag(name: [.customShort("b"), .customShort("g"), .customLong("background")], help: "Open Xcode in the background")
    var openInBackground = false
    
    @Flag(name: [.customShort("f"), .customShort("e"), .customLong("folder")], help: "Enclose new items in folder")
    var encloseInFolder = false
    
    @Flag(name: [.customLong("open")], inversion: .prefixedNo, help: "Open newly created playgrounds/workspaces")
    var openAfterCreating = true


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
            switch paths[0].lowercased() {

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

            // Request new playground workspace
            case "pgw":
                throw RuntimeError("Must specify playground type (mac, ios, tvos).")

            // This degenerate case is handled below
            case "new":
                break

            default:
                break
            }
        }

        // Special case "new" as the first file mentioned
        if paths[0].lowercased() == "new" {
            guard paths.count > 1
            else { throw RuntimeError("No new files to create.") }
            try Utility.createNewFilesAndOpen(Array<String>(paths.dropFirst()), bg: openInBackground)
            return
        }

        // Playground creation is always `newpg type`
        if (paths[0].lowercased() == "pg" || paths[0].lowercased() == "pgw") && paths.count == 2 {
            
            // What is the playground type?
            let style = PGType.from(string: paths[1].lowercased())
            if style == .other {
                throw RuntimeError("Unsupported playground type (mac, ios, tvos).")
            }
            let styleString = style.rawValue
            
            // Where does this happen?
            var destinationURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            var playgroundURL = destinationURL.appendingPathComponent("\(styleString).playground")
            if encloseInFolder {
                // Enclosing folders are versioned
                destinationURL = destinationURL.appendingPathComponent("\(styleString) Playground").versioned()
                playgroundURL = destinationURL.appendingPathComponent("\(styleString).playground")
                try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            } else {
                // Playgrounds in cwd are versioned
                playgroundURL = playgroundURL.versioned()
            }
            
            // Create playground
            try Utility.createPlayground(type: style, at: playgroundURL)
            
            // Create workspace
            if paths[0].lowercased() == "pgw" {
                let coreName = playgroundURL.deletingPathExtension().lastPathComponent
                FileManager.default.changeCurrentDirectoryPath(destinationURL.path)
                try Utility.createPlaygroundWorkspace(coreName: coreName, at: destinationURL)
                if openAfterCreating {
                    _ = try Utility.execute(commandPath: "/usr/bin/open", arguments: (openInBackground ? ["-g"] : []) + [destinationURL.appendingPathComponent("\(coreName).xcworkspace").path])
                }
            } else {
                if openAfterCreating {
                    try Utility.xcopen([playgroundURL.lastPathComponent], bg: openInBackground)
                }
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
