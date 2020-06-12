//  Created by Erica Sadun on 6/12/20.

import Foundation

let mgr = FileManager.default
let files = try! mgr.contentsOfDirectory(atPath: ".")

for file in files {
    if file.hasSuffix(".xcodeproj") {
        let process = Process()
        process.launchPath = "/usr/bin/open"
        process.arguments = [file]
        if #available(macOS 10.13, *) {
            _ = try? process.run()
        } else {
            process.launch()
        }
        process.waitUntilExit()
    }
}
