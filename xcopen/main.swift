//  Created by Erica Sadun on 6/12/20.

import Foundation
import ArgumentParser
import GeneralUtility

struct Xcopen: ParsableCommand {
    @Argument(help: "Files to open. Leave blank to search for xcodeproj and xcworkspace in the working directory")
    var files: [String]
    
    @Flag(name: [.short, .customLong("all", withSingleDash: true)], help: "In addition, open Package.swift")
    var allXcodeTypes: Bool
    
    @Flag(name: [.short, .customLong("docs", withSingleDash: true)], help: "Open all .md and .txt files")
    var docTypes: Bool
    
    @Flag(name: [.short, .customLong("new", withSingleDash: true)], help: "Create new files and then open them in Xcode")
    var newFiles: Bool
    
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

    func run() throws {
        if newFiles {
            try createNewFilesAndOpen(files, bg: openInBackground)
            return
        }
        
        if docTypes {
            try searchAndXcodeOpen([".txt", ".md"], bg: openInBackground)
            return
        }
        
        if files.isEmpty {
            try searchAndOpen([".xcodeproj", ".xcworkspace"] + (allXcodeTypes ? ["Project.swift"] : []), bg: openInBackground)
            return
        }
        
        try searchAndXcodeOpen(files, bg: openInBackground)
    }
}

Xcopen.main()
