//  Created by Erica Sadun on 6/12/20.

import Foundation
import ArgumentParser
import GeneralUtility

struct Xcopen: ParsableCommand {
    static var configuration = CommandConfiguration(helpNames: [.short, .customLong("help", withSingleDash: true)])
    @Flag(help: .hidden) // provides undocumented --help
    var help: Bool
    
    @Argument(help: "Files to open. Leave blank to search for xcodeproj and xcworkspace in the working directory")
    var files: [String]
    
    @Flag(name: [.short, .customLong("all", withSingleDash: true)], help: "In addition, open Package.swift")
    var allXcodeTypes: Bool
    
    @Flag(name: [.short, .customLong("docs", withSingleDash: true)], help: "Open all .md and .txt files")
    var docTypes: Bool
    
    @Flag(name: [.short, .customLong("new", withSingleDash: true)], help: "Create new files and then open them in Xcode")
    var newFiles: Bool
    
    @Flag(name: [.short, .customLong("focus", withSingleDash: true)], help: .hidden) // "Set Xcode focus on the first file"
    var focusXcode: Bool
    
    @Flag(name: [.short, .customLong("pkg", withSingleDash: true), .customLong("package", withSingleDash: true), .customLong("edit", withSingleDash: true)], help: .hidden)
    var openPackageInTextEdit: Bool

    @Flag(name: [.customShort("b"), .customLong("bg", withSingleDash: true), .customLong("background", withSingleDash: true)], help: "Open Xcode in the background")
    var openInBackground: Bool
    
    /// Remove "Contents/Developer" and return path to active Xcode
    func xcurl() throws -> URL {
        let xclocation = try Utility.execute(commandPath: "/usr/bin/xcrun", arguments: ["xcode-select", "-p"])
        return URL(fileURLWithPath: xclocation).deletingLastPathComponent().deletingLastPathComponent()
    }
        
    /// Find all files in the working directory whose suffixes match the supplied strings
    func filesWithSuffixes(_ suffixes: [String]) throws -> [String] {
        let files = try! FileManager.default.contentsOfDirectory(atPath: ".")
        
        return files.filter({ file in
            for suffix in suffixes {
                if file.hasSuffix(suffix) { return true }
            }
            return false
        })
    }

    /// Search working folder for files matching the supplied patterns and open them with `open`
    func searchAndOpen(_ patterns: [String], bg: Bool = false) throws {
        let filesToOpen = try filesWithSuffixes(patterns)
        try filesToOpen.forEach { file in
            _ = try Utility.execute(commandPath: "/usr/bin/open", arguments: (bg ? ["-g"] : []) + [file])
        }
    }
    
    /// Search working folder for files matching the supplied patterns and open them with Xcode
    func searchAndXcodeOpen(_ patterns: [String], bg: Bool = false) throws {
        let filesToOpen = try filesWithSuffixes(patterns)
        _ = try Utility.execute(commandPath: "/usr/bin/open", arguments: (bg ? ["-g"] : []) + ["-a", xcurl().path] + filesToOpen)
    }
    
    /// Create each file and then open it in Xcode. Open but do not create if file exists
    func createNewFilesAndOpen(_ files: [String], bg: Bool = false) throws {
        for file in files {
            if !FileManager.default.fileExists(atPath: file) {
                FileManager.default.createFile(atPath: file, contents: "".data(using: .utf8), attributes: nil)
            }
        }
        for file in files {
            _ = try Utility.execute(commandPath: "/usr/bin/open", arguments: (bg ? ["-g"] : []) + ["-a", xcurl().path] + [file])
        }
    }
    
    func focus(_ filePath: String) throws {
        guard FileManager.default.fileExists(atPath: filePath) else { return }
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
    
    func openPkgInTextEdit() throws {
        _ = try Utility.execute(commandPath: "/usr/bin/open", arguments: ["-e", "Package.swift"])
    }

    func run() throws {
        guard !help
            else { throw CleanExit.helpRequest() }
        
        if openPackageInTextEdit {
            try openPkgInTextEdit()
            return
        }
        
        if newFiles {
            try createNewFilesAndOpen(files, bg: openInBackground)
            return
        }
        
        if docTypes {
            try searchAndXcodeOpen([".txt", ".md"], bg: openInBackground)
            return
        }
        
        if focusXcode {
            guard !files.isEmpty
                else { throw RuntimeError("Focus requires a file name") }
            try searchAndOpen([".xcodeproj", ".xcworkspace"] + (allXcodeTypes ? ["Project.swift"] : []), bg: openInBackground)
            try focus(files[0])
            return
        }
        
        if files.isEmpty {
            try searchAndOpen([".xcodeproj", ".xcworkspace"] + (allXcodeTypes ? ["Project.swift"] : []), bg: openInBackground)
        } else {
            try searchAndXcodeOpen(files, bg: openInBackground)
        }
    }
}

Xcopen.main()
