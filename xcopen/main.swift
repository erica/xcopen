//  Created by Erica Sadun on 6/12/20.

import Foundation
import ArgumentParser
import GeneralUtility

struct Xcopen: ParsableCommand {
    static var configuration = CommandConfiguration(helpNames: [.short, .customLong("help", withSingleDash: true)])
    
    @Flag(help: .hidden) // provides undocumented --help
    var help = false
    
    @Argument(help: "Files to open. Leave blank to search for xcodeproj and xcworkspace in the working directory")
    var files: [String] = []
    
    @Flag(name: [.short, .customLong("all", withSingleDash: true)], help: "In addition, open Package.swift")
    var allXcodeTypes = false
    
    @Flag(name: [.short, .customLong("docs", withSingleDash: true)], help: "Open all .md and .txt files")
    var docTypes = false
    
    @Flag(name: [.short, .customLong("new", withSingleDash: true)], help: "Create new files and then open them in Xcode")
    var newFiles = false
    
    @Flag(name: [.short, .customLong("focus", withSingleDash: true)], help: .hidden) // "Set Xcode focus on the first file"
    var focusXcode = false
    
    @Flag(name: [.short, .customLong("pkg", withSingleDash: true), .customLong("package", withSingleDash: true), .customLong("edit", withSingleDash: true)], help: .hidden)
    var openPackageInTextEdit = false
    
    @Flag(name: [.customShort("b"), .customLong("bg", withSingleDash: true), .customLong("background", withSingleDash: true)], help: "Open Xcode in the background")
    var openInBackground = false
    
    func run() throws {
        guard !help
            else { throw CleanExit.helpRequest() }
        
        // Little undocumented feature for my own use. Sort of subcommands
        // without actually being subcommands.
        var isDir: ObjCBool = false
        if files.count == 1 {
            switch files[0] {
            case "ws":
                // Just open a workspace if there's one here
                try searchAndOpen([".xcworkspace"], bg: openInBackground)
                return
            case "docs":
                // Just open docs
                try searchAndXcodeOpen([".txt", ".md"], bg: openInBackground)
                return
            case "pkg":
                // Just open Package.swift in Textedit
                try openPkgInTextEdit()
                return
            case "xpkg":
                // Just open Package.swift in Xcode
                try searchAndXcodeOpen(["Package.swift"], bg: openInBackground)
                return
            case _ where FileManager.default.fileExists(atPath: files[0], isDirectory: &isDir) && isDir.boolValue == true :
                let dirURL = URL(fileURLWithPath: files[0])
                var filesToOpen: [String] = []
                for file in try FileManager.default.contentsOfDirectory(atPath: files[0]) {
                    let path = dirURL.appendingPathComponent(file).path
                    _ = FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
                    if isDir.boolValue == true { continue }
                    filesToOpen.append(path)
                }
                _ = try Utility.execute(commandPath: "/usr/bin/open", arguments: (openInBackground ? ["-g"] : []) + ["-a", xcurl().path] + filesToOpen)
                return
            default:
                break
            }
        }
        
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
