//
// Created by Krzysztof Zabłocki on 05/12/15.
// Copyright (c) 2015 pixle. All rights reserved.
//

import Foundation
import AppKit

extension NSTextStorage {

    private struct AssociatedKeys {
        static var isConsoleKey = "isConsoleKey"
    }

    var kz_isUsedInXcodeConsole: Bool {
        get {
            guard let value = objc_getAssociatedObject(self, &AssociatedKeys.isConsoleKey) as? NSNumber else {
                return false
            }

            return value.boolValue
        }

        set {
            objc_setAssociatedObject(self, &AssociatedKeys.isConsoleKey, NSNumber(bool: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func kz_fixAttributesInRange(range: NSRange) {
        kz_fixAttributesInRange(range) //! call original implementation first

        if !self.kz_isUsedInXcodeConsole {
            return
        }

        injectLinksIntoLogs()
    }

    private func injectLinksIntoLogs() {
        let text = string as NSString
        guard let path = KZPluginHelper.workspacePath() else {
            return
        }

        let matches = pattern.matchesInString(string, options: .ReportProgress, range: editedRange)
        for result in matches where result.numberOfRanges == 4 {
            let fullRange = result.rangeAtIndex(0)
            let fileNameRange = result.rangeAtIndex(1)
            let extensionRange = result.rangeAtIndex(2)
            let lineRange = result.rangeAtIndex(3)

            guard let result = KZPluginHelper.runShellCommand("find \"\(path)\" -name \"\(text.substringWithRange(fileNameRange)).\(text.substringWithRange(extensionRange))\" | head -n 1") else {
                continue
            }

            addAttribute(NSLinkAttributeName, value: "", range: fullRange)
            addAttribute(KZLinkedConsole.Strings.linkedPath, value: result, range: fullRange)
            addAttribute(KZLinkedConsole.Strings.linkedLine, value: text.substringWithRange(lineRange), range: fullRange)
            addAttribute(NSBackgroundColorAttributeName, value: NSColor.lightGrayColor(), range: fullRange)
        }
    }

    private var pattern: NSRegularExpression {
        return try! NSRegularExpression(pattern: "(\\w+)\\.(\\w+)\\:(\\d+)", options: .CaseInsensitive)
    }
}