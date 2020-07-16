//  Copyright © 2020 Erica Sadun. All rights reserved.

import Foundation
import GeneralUtility
import MacUtility

/// Known playground types that can be created.
enum PGType: String {
    case macos = "macOS", ios = "iOS", tvos = "tvOS", other
    
    static func from(string: String) -> Self {
        switch string {
        case "mac", "macos", "osx":
            return .macos
        case "ios":
            return .ios
        case "tv", "tvos":
            return .tvos
        default:
            return .other
        }
    }
}

extension Utility {
    /// Opens Package.swift in Text Edit
    /// - Throws: A `RuntimeError` describing why a file could not be opened in TextEdit.
    static func openPkgInTextEdit() throws {
        _ = try Utility.execute(commandPath: "/usr/bin/open", arguments: ["-e", "Package.swift"])
    }
    
    /// Creates a new playground at the destination URL
    /// - Parameters:
    ///   - type: The style of playground to create, a `PGType`
    static func createPlayground(type: PGType, at destinationURL: URL) throws {
        var location = ""
        switch type {
        case .macos:
            location = "Contents/Developer/Library/Xcode/Templates/File Templates/macOS/Playground/Blank.xctemplate/___FILEBASENAME___.playground"
        case .ios:
            location = "Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/Xcode/Templates/File Templates/iOS/Playground/Blank.xctemplate/___FILEBASENAME___.playground"
        case .tvos:
            location = "Contents/Developer/Platforms/AppleTVOS.platform/Developer/Library/Xcode/Templates/File Templates/tvOS/Playground/Blank.xctemplate/___FILEBASENAME___.playground"
        default:
            throw RuntimeError("Unsupported playground type")
        }
        
        let sourceURL = try xcurl().appendingPathComponent(location)
        
        // Create the playground if the file does not yet exist
        if !destinationURL.exists {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        }
    }
    
    /// Creates a new playground workspace at the destination URL
    /// - Parameters:
    ///   - type: The style of playground to create, a `PGType`
    static func createPlaygroundWorkspace(coreName: String, at destinationURL: URL) throws {
        
        // Create workspace directory
        let xcwsurl = destinationURL.appendingPathComponent("\(coreName).xcworkspace")
        try FileManager.default.createDirectory(at: xcwsurl, withIntermediateDirectories: true, attributes: nil)
        
        //        // Create user data directory
        //        let xcudurl = xcwsurl.appendingPathComponent("xcuserdata")
        //        try FileManager.default.createDirectory(at: xcudurl, withIntermediateDirectories: true, attributes: nil)
        
        // Establish contents
        let contents = """
        <?xml version="1.0" encoding="UTF-8"?>
        <Workspace version = "1.0">
        <FileRef location = "container:\(coreName).playground">
        </FileRef>
        </Workspace>
        """
        let contentsurl = xcwsurl.appendingPathComponent("contents.xcworkspacedata")
        FileManager.default.createFile(atPath: contentsurl.path, contents: contents.data(using: .utf8), attributes: nil)
    }
}

