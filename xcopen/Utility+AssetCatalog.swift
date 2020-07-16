//  Copyright © 2020 Erica Sadun. All rights reserved.

import Foundation
import GeneralUtility
import MacUtility

extension Utility {
    /// Building  a conforming Contents.json for xcassets
    enum AssetCatalog {
        struct Info: Codable {
            var author = "xcopen"
            var version = 1
        }
        
        struct Contents: Codable {
            var info: Info = Info()
        }
    }
    
    /// Building  a conforming Contents.json for imageset
    enum ImageSet {
        struct Info: Codable {
            var author = "xcopen"
            var version = 1
        }
        
        struct Image: Codable {
            let filename: String
            var idiom = "universal"
        }
                
        /// The contents of an app icon set
        struct Contents: Codable {
            var info = Info()
            let images: [Image]
            var properties = [ "preserves-vector-representation": true ]
            init(name imageName: String) {
                images = [Image(filename: imageName)]
            }
        }
    }
    
    private static var cwdurl = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

    /// Build an asset catalog of the specified name at the destination URL.
    /// - Parameters:
    ///   - name: The catalog name, nominally "Media"
    ///   - url: Where the catalog will be built
    /// - Throws: An error describing why the catalog could not be built
    /// - Returns: A URL pointing to the new catalog
    private static func buildAssetCatalog(_ name: String = "Media", url: URL = cwdurl) throws -> URL {
        
        // Establish where this is built
        let destinationURL = url
            .appendingPathComponent(name)
            .appendingPathExtension("xcassets")
        
        // Create the folder if needed, re-use otherwise
        if !destinationURL.exists {
            try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        } else if !destinationURL.path.isDir() {
            // A quick check just in case the user has passed an existing non-folder
            throw RuntimeError("Destination must be a directory: \(destinationURL.path)")
        }

        // Place a Contents.json into the folder. Boilerplate.
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let contents = try encoder.encode(AssetCatalog.Contents())
        try contents.write(to: destinationURL.appendingPathComponent("Contents.json"))
        return destinationURL
    }
    
    /// Build an image set for a given image
    /// - Parameters:
    ///   - source: A URL pointing to an image
    ///   - destination: A URL pointing to an asset catalog
    /// - Throws: An error describing why the image could not be copied to the catalog and an imageset created
    private static func buildImageSet(source: URL, destination: URL) throws {
        
        // In case the user has passed a non-existent image
        guard source.exists
        else {
            print("Skipping: source image does not exist \(source.path)")
            return
        }
        
        // Test for supported image types
        let pathExtension = source.pathExtension
        guard ["avci", "heic", "heif", "jpeg", "jpg", "pdf", "png", "svg"].contains(pathExtension.lowercased())
        else {
            print("Skipping: Unsupported file type \(source.lastPathComponent)")
            return
        }
        
        // Create the imageset folder if it does not already exist
        let name = source.deletingPathExtension().lastPathComponent
        let imagesetURL = destination.appendingPathComponent("\(name).imageset")
        if !imagesetURL.exists {
            try FileManager.default.createDirectory(at: imagesetURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        // Remove any existing image asset and replace with the one at the source url
        let assetName = source.lastPathComponent
        let fileURL = imagesetURL.appendingPathComponent(assetName)
        if fileURL.exists {
            try FileManager.default.removeItem(at: fileURL)
        }
        try FileManager.default.copyItem(atPath: source.path, toPath: fileURL.path)

        // Build the Content.json boilerplate for the asset. This will always be a
        // single universal resolution with hints that support any vector image.
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let contents = try encoder.encode(ImageSet.Contents(name: assetName))
        try contents.write(to: imagesetURL.appendingPathComponent("Contents.json"))
    }
    
    /// Creates asset catalogs
    /// - Parameters:
    ///   - paths: the destination path followed by image paths
    /// - Throws: Errors describing why the asset catalog could not be built
    static func buildAssets(_ paths: [String]) throws {
        
        // If no further arguments, build Media.xcassets and leave.
        guard paths.count > 1 else {
            _ = try buildAssetCatalog()
            return
        }
        
        var baseURL = URL(fileURLWithPath: paths[1]) // skip "asset(s)"
        var name = "Media"
        if !baseURL.path.isDir() {
            name = baseURL.deletingPathExtension().lastPathComponent
            baseURL = baseURL.deletingLastPathComponent()
        }
        
        // Usage: assets destination (image-path...)
        // If there are no paths, only the catalog shell is built
        let catalogURL = try buildAssetCatalog(name, url: baseURL)
        guard paths.count > 2 else {
            return
        }
        
        // Skip past asset and destination to get to the image paths
        for path in paths.dropFirst(2) {
            let url = URL(fileURLWithPath: path)
            if !url.exists {
                print("Skipping: \(url.lastPathComponent) does not exist")
                continue
            }
            try buildImageSet(source: url, destination: catalogURL)
        }
    }
}
