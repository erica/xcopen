//  Copyright © 2020 Erica Sadun. All rights reserved.

import Foundation
import GeneralUtility
import MacUtility

extension Utility {
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
