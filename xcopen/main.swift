//  Created by Erica Sadun on 6/12/20.

import Foundation
import ArgumentParser
import GeneralUtility

struct Xcopen: ParsableCommand {
    static var configuration = CommandConfiguration(discussion: """
    xcopen <files>...        Open files in Xcode.
    xcopen                   Open workspace or xcodeproj.
    xcopen ws                Only search for workspace.
    xcopen xc                Only search for xcodeproj.
    xcopen docs              Open .md and .txt files.
    xcopen pkg               Open Package.swift in TextEdit.
    xcopen xpkg              Open Package.swift in Xcode.
    xcopen new               Create new files (if they don't exist) and
                             open in Xcode.
    """)


    @Argument(help: "Files to open. If blank, opens xcworkspace or, if not found, searches for xcodeproj.")
    var paths: [String] = []

    @Flag(name: [.customShort("b"), .customLong("bg", withSingleDash: true), .customLong("background")], help: "Open Xcode in the background")
    var openInBackground = false

    func run() throws {
        var isDir: ObjCBool = false

        // Handle the empty paths case first. Everything else references the paths list.
        guard !paths.isEmpty else {
            let hasWorkspace = try !FileManager.default.contentsOfDirectory(atPath: ".")
                .filter({ $0.hasSuffix(".xcworkspace") }).isEmpty
            switch hasWorkspace {
            case true:
                try Utility.searchAndOpen([".xcworkspace"], bg: openInBackground)
            case false:
                try Utility.searchAndOpen([".xcodeproj"], bg: openInBackground)
            }
            return
        }

        // Subcommands without being subcommands, allowing the utility
        // to be called without any arguments
        if paths.count == 1 {
            switch paths[0] {

            // Open a workspace if there's one here
            case "ws":
                try Utility.searchAndOpen([".xcworkspace"], bg: openInBackground)
                return

            // Opens all xcodeproj
            case "xc":
                try Utility.searchAndOpen([".xcodeproj"], bg: openInBackground)
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

            // This is handled below
            case "new":
                break

            // Check whether there is a single path and it is a directory
            case _
                    where
                    paths.count == 1
                    && FileManager.default.fileExists(atPath: paths[0], isDirectory: &isDir)
                    && isDir.boolValue == true :
                let dirURL = URL(fileURLWithPath: paths[0])
                let filesToOpen = try FileManager.default
                    .contentsOfDirectory(atPath: paths[0])
                    .compactMap({ path -> String? in
                        let filePath = dirURL.appendingPathComponent(path).path
                        _ = FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
                        return isDir.boolValue == true ? nil : filePath
                    })
                _ = try Utility.execute(commandPath: "/usr/bin/open", arguments: (openInBackground ? ["-g"] : []) + ["-a", Utility.xcurl().path] + filesToOpen)
                return
            default:
                break
            }
        }

        // Special case "new" as the first file mentioned
        if paths[0] == "new" {
            try Utility.createNewFilesAndOpen(Array<String>(paths.dropFirst()), bg: openInBackground)
            return
        }

        try Utility.searchAndXcodeOpen(paths, bg: openInBackground)
    }
}

Xcopen.main()
