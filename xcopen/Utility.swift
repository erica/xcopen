//  Copyright © 2020 Erica Sadun. All rights reserved.

import Foundation
import GeneralUtility

enum PGType {
    case mac, ios, watchos, other
}

extension Utility {
    /// Remove "Contents/Developer" and return path to active Xcode
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

    // Activate Xcode unless backgrounding
    static func activateXcode() throws {
        let script = #"tell application "Xcode" to activate"#
        _ = try Utility.execute(commandPath: "/usr/bin/osascript", arguments: ["-e", script])
    }

    /// Search working folder for files matching the supplied patterns and open them with `open`
    /// - Parameters:
    ///   - patterns: Ending patterns by which to match files. This can match a suffix, extension, or entire file.
    ///   - bg: Launch xcode in the background.
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
    ///   - bg: Launch xcode in the background.
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
    ///   - bg: Launch xcode in the background.
    /// - Throws: A `RuntimeError` describing the failure in opening the files.
    static func xcopen(_ filesToOpen: [String], bg: Bool = false) throws {
        guard !filesToOpen.isEmpty else { return }
        _ = try Utility.execute(commandPath: "/usr/bin/open", arguments: (bg ? ["-g"] : []) + ["-a", xcurl().path] + filesToOpen)
        if !bg { try activateXcode() }
    }

    /// Create each file and then open it in Xcode. Open but do not create if file exists
    /// - Parameters:
    ///   - patterns: Ending patterns by which to match files. This can match a suffix, extension, or entire file.
    ///   - bg: Launch xcode in the background.
    /// - Throws: A `RuntimeError` describing the failure in opening the files.
    static func createNewFilesAndOpen(_ files: [String], bg: Bool = false) throws {
        for file in files {
            if !FileManager.default.fileExists(atPath: file) {
                FileManager.default.createFile(atPath: file, contents: "".data(using: .utf8), attributes: nil)
            }
        }

        _ = try Utility.execute(commandPath: "/usr/bin/open", arguments: (bg ? ["-g"] : []) + ["-a", xcurl().path] + files)
    }

    /// Opens and focuses the file.
    ///
    /// This should probably never be used. Leaving it here for my own personal reference.
    /// - Parameter filePath: The file to focus
    /// - Throws: A `RuntimeError`
    static func focus(_ filePath: String) throws {
        guard FileManager.default.fileExists(atPath: filePath)
        else { return }

        let file = URL(fileURLWithPath: filePath).lastPathComponent

        let script = """
        tell application "System Events"
        tell process "Xcode"
        activate
        set frontmost to true
        click menu item "Open Quickly…" of menu "File" of menu bar 1
        key up option
        key up command
        keystroke "\(file)"
        delay 0.5
        keystroke return
        delay 0.2
        click menu item "Move Focus to Editor…" of menu "Navigate" of menu bar 1
        delay 0.1
        keystroke return
        delay 0.1
        click menu item "Reveal in Project Navigator" of menu "Navigate" of menu bar 1
        end tell
        end tell
        """
        _ = try Utility.execute(commandPath: "/usr/bin/osascript", arguments: ["-e", script])
    }

    /// Opens Package.swift in Text Edit
    /// - Throws: A `RuntimeError` describing why a file could not be opened in TextEdit.
    static func openPkgInTextEdit() throws {
        _ = try Utility.execute(commandPath: "/usr/bin/open", arguments: ["-e", "Package.swift"])
    }

    static func buildNewPlayground(type: PGType, bg: Bool) throws {
        var location = ""
        var name = ""
        switch type {
        case .mac:
            location = "Contents/Developer/Library/Xcode/Templates/File Templates/macOS/Playground/Blank.xctemplate/___FILEBASENAME___.playground"
            name = "Mac"
        case .ios:
            location = "Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/Xcode/Templates/File Templates/iOS/Playground/Blank.xctemplate/___FILEBASENAME___.playground"
            name = "iOS"
        default:
            throw RuntimeError("Unsupported playground type")
        }

        let url = try xcurl()
            .appendingPathComponent(location)
        let destinationURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("New \(name).playground")

        // Create the playground if the file does not yet exist
        if !FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.copyItem(at: url, to: destinationURL)
            try xcopen([destinationURL.path], bg: bg)
            return
        }

        // Find an offset name that does not yet exist
        var offset = 2
        while FileManager.default.fileExists(atPath: destinationURL.deletingPathExtension().path + " \(offset).playground") { offset += 1 }
        let numberedDestinationURL = URL(fileURLWithPath: destinationURL.deletingPathExtension().path + " \(offset).playground")
        try FileManager.default.copyItem(at: url, to: numberedDestinationURL)
        try xcopen([numberedDestinationURL.path], bg: bg)
    }
}
