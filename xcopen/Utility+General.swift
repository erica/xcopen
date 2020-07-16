//  Copyright © 2020 Erica Sadun. All rights reserved.

import Foundation

extension String {
    /// Trims trailing slashes from a folder path.
    /// - Returns: a canonical path to a folder
    func trimmedDirPath() -> String {
        if self.hasSuffix("/") { return String(self.dropLast()) }
        return self
    }
}

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
