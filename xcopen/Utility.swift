//  Copyright © 2020 Erica Sadun. All rights reserved.

import Foundation
import GeneralUtility
import MacUtility

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

    /// Trims trailing slashes from a folder path.
    /// - Returns: a canonical path to a folder
    func trimmedDirPath() -> String {
        if self.hasSuffix("/") { return String(self.dropLast()) }
        return self
    }

    /// Tests a string representing a path.
    /// - Returns: Boolean indicating whether a string-based path is a directory.
    func isDir() -> Bool {
        var pathIsDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: self, isDirectory: &pathIsDir)
        else { return false }
        return pathIsDir.boolValue
    }
}

/// Known playground types that can be created.
enum PGType {
    case macos, ios, tvos, other
}

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
            if !FileManager.default.fileExists(atPath: file) {
                FileManager.default.createFile(atPath: file, contents: "".data(using: .utf8), attributes: nil)
            }
        }

        _ = try Utility.execute(commandPath: "/usr/bin/open", arguments: (bg ? ["-g"] : []) + ["-a", xcurl().path] + files)
    }

    /// Opens Package.swift in Text Edit
    /// - Throws: A `RuntimeError` describing why a file could not be opened in TextEdit.
    static func openPkgInTextEdit() throws {
        _ = try Utility.execute(commandPath: "/usr/bin/open", arguments: ["-e", "Package.swift"])
    }

    /// Creates a new playground in the working directory.
    /// - Parameters:
    ///   - type: The style of playground to create, a `PGType`
    ///   - bg: Launch Xcode in the background
    static func buildNewPlayground(type: PGType, bg: Bool) throws {
        var location = ""
        var name = ""
        switch type {
        case .macos:
            location = "Contents/Developer/Library/Xcode/Templates/File Templates/macOS/Playground/Blank.xctemplate/___FILEBASENAME___.playground"
            name = "macOS"
        case .ios:
            location = "Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/Xcode/Templates/File Templates/iOS/Playground/Blank.xctemplate/___FILEBASENAME___.playground"
            name = "iOS"
        case .tvos:
            location = "Contents/Developer/Platforms/AppleTVOS.platform/Developer/Library/Xcode/Templates/File Templates/tvOS/Playground/Blank.xctemplate/___FILEBASENAME___.playground"
            name = "tvOS"
        default:
            throw RuntimeError("Unsupported playground type")
        }

        let url = try xcurl()
            .appendingPathComponent(location)
        let destinationURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("\(name).playground")

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

    /// Opens and focuses the file.
    ///
    /// This should not be used. Leaving it here for my own personal reference.
    /// - Parameter filePath: The file to focus
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
}
