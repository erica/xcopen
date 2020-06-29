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

            default:
                break
            }
        }

        // Special case "new" as the first file mentioned
        if paths[0] == "new" {
            try Utility.createNewFilesAndOpen(Array<String>(paths.dropFirst()), bg: openInBackground)
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

extension Array where Element: Comparable {
    /// Partitions an array in two by applying a predicate to each member.
    /// - Parameters:
    ///   - predicate: a Boolean test to determine membership.
    ///   - element: A `Comparable` array element.
    /// - Returns: A tuple of two arrays. The first array contains elements matched by the predicate.
    ///     The second includes all non-matching elements.
    public func partition(by predicate: (_ element: Element) -> Bool) -> (matching: [Element], notMatching: [Element]) {
        var (matching, notMatching): ([Element], [Element]) = ([], [])
        for element in self {
            switch predicate(element) {
            case true:
                matching.append(element)
            case false:
                notMatching.append(element)
            }
        }        
        return (matching: matching, notMatching: notMatching)
    }
}

extension String {
    func trimmedDirPath() -> String {
        if self.hasSuffix("/") { return String(self.dropLast()) }
        return self
    }
    
    /// Returns boolean indicating whether a string-based path is a directory
    func isDir() -> Bool {
        var pathIsDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: self, isDirectory: &pathIsDir)
        else { return false }
        return pathIsDir.boolValue
    }
}

Xcopen.main()
