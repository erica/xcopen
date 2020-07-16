//  Copyright © 2020 Erica Sadun. All rights reserved.

import Foundation
import GeneralUtility
import MacUtility

extension Utility {
    /// Remove "Contents/Developer" and return path to the actively selected Xcode.
    /// - Throws: `RuntimeError` describing reason selected Xcode path could not be retrieved
    /// - Returns: URL to Xcode app
    static func xcurl() throws -> URL {
        let xclocation = try Utility.execute(commandPath: "/usr/bin/xcrun", arguments: ["xcode-select", "-p"])
        return URL(fileURLWithPath: xclocation).deletingLastPathComponent().deletingLastPathComponent()
    }

    /// Find all files in the working directory whose suffixes match the supplied strings
    /// - Parameter suffixes: The endings of the files to open. This can match a suffix, extension, or entire file.
    /// - Throws: FileManager errors on retrieving directory contents
    /// - Returns: An array of files that match the provided suffixes
    static func filesWithSuffixes(_ suffixes: [String]) throws -> [String] {
        let files = try FileManager.default.contentsOfDirectory(atPath: ".")

        return files.filter({ file in
            for suffix in suffixes {
                if file.hasSuffix(suffix) { return true }
            }
            return false
        })
    }

    /// Activates Xcode unless backgrounding.
    /// - Throws: a `RuntimeError` indicating why `osascript` failed.
    static func activateXcode() throws {
        let script = #"tell application "Xcode" to activate"#
        _ = try Utility.execute(commandPath: "/usr/bin/osascript", arguments: ["-e", script])
    }
    
    /// Quits Xcode
    /// - Throws: a `RuntimeError` indicating why `osascript` failed.
    static func quitXcode() throws {
        let script = #"tell application "Xcode" to quit"#
        _ = try Utility.execute(commandPath: "/usr/bin/osascript", arguments: ["-e", script])
    }

    /// Resets UIState
    static func uireset() throws {
        try quitXcode()
        let whoami = try execute("/usr/bin/whoami")
        let projects = try filesWithSuffixes(["xcodeproj", "xcworkspace"])
        for project in projects {
            let url = URL(fileURLWithPath: project)
                .appendingPathComponent("project.xcworkspace")
                .appendingPathComponent("xcuserdata")
                .appendingPathComponent("\(whoami).xcuserdatad")
                .appendingPathComponent("UserInterfaceState.xcuserstate")
            if url.exists {
                var outurl: NSURL?
                try FileManager.default.trashItem(at: url, resultingItemURL: &outurl)
                if let outpath = outurl?.path {
                    print("User state moved to \(outpath)")
                }
            }
        }
    }

    /// Search working folder for files matching the supplied patterns and open them with `open`
    /// - Parameters:
    ///   - patterns: Ending patterns by which to match files. This can match a suffix, extension, or entire file.
    ///   - bg: Launch Xcode in the background.
    /// - Throws: A `RuntimeError` describing the failure in opening the files.
    static func searchAndOpen(_ patterns: [String], bg: Bool = false) throws {
        let filesToOpen = try filesWithSuffixes(patterns)
        guard !filesToOpen.isEmpty else { return }
        _ = try Utility.execute(commandPath: "/usr/bin/open", arguments: (bg ? ["-g"] : []) + filesToOpen)
        if !bg { try activateXcode() }
    }

    /// Search working folder for files matching the supplied patterns and open them with Xcode
    /// - Parameters:
    ///   - patterns: Ending patterns by which to match files. This can match a suffix, extension, or entire file.
    ///   - bg: Launch Xcode in the background.
    /// - Throws: A `RuntimeError` describing the failure in opening the files.
    static func searchAndXcodeOpen(_ patterns: [String], bg: Bool = false) throws {
        let filesToOpen = try filesWithSuffixes(patterns)
        guard !filesToOpen.isEmpty else { return }
        _ = try Utility.execute(commandPath: "/usr/bin/open", arguments: (bg ? ["-g"] : []) + ["-a", xcurl().path] + filesToOpen)
        if !bg { try activateXcode() }
    }

    /// Open files with Xcode
    /// - Parameters:
    ///   - filesToOpen: Ending patterns by which to match files. This can match a suffix, extension, or entire file.
    ///   - bg: Launch Xcode in the background.
    /// - Throws: A `RuntimeError` describing the failure in opening the files.
    static func xcopen(_ filesToOpen: [String], bg: Bool = false) throws {
        guard !filesToOpen.isEmpty else { return }
        _ = try Utility.execute(commandPath: "/usr/bin/open", arguments: (bg ? ["-g"] : []) + ["-a", xcurl().path] + filesToOpen)
        if !bg { try activateXcode() }
    }

    /// Create each file and then open it in Xcode. Open but do not create if file exists
    /// - Parameters:
    ///   - patterns: Ending patterns by which to match files. This can match a suffix, extension, or entire file.
    ///   - bg: Launch Xcode in the background.
    /// - Throws: A `RuntimeError` describing the failure in opening the files.
    static func createNewFilesAndOpen(_ files: [String], bg: Bool = false) throws {
        for file in files {
            let url = URL(fileURLWithPath: file)
            if !url.exists {
                FileManager.default.createFile(atPath: url.path, contents: "".data(using: .utf8), attributes: nil)
            }
        }

        _ = try Utility.execute(commandPath: "/usr/bin/open", arguments: (bg ? ["-g"] : []) + ["-a", xcurl().path] + files)
    }
}
