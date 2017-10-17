//
//  SuggestionsWindow.swift
//  CustomMenuSwift
//
//  Created by Rice on 06/10/2017.
//  Copyright © 2017 Rice. All rights reserved.
//

import Cocoa

class SuggestionsWindow: NSWindow {
    
    var parentElement: Any?
    
    convenience init(with contentRect: NSRect, defer flag: Bool) {
        self.init(contentRect: contentRect, styleMask: .borderless, backing: .buffered, defer: true)
    }
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: .borderless, backing: backingStoreType, defer: flag)
        self.hasShadow = true
        self.backgroundColor = .clear
        self.isOpaque = false
    }

    override func accessibilityIsIgnored() -> Bool {
        return true
    }
    
    override func accessibilityAttributeValue(_ attribute: NSAccessibilityAttributeName) -> Any? {
        if attribute == .parent {
            return NSAccessibilityUnignoredAncestor(parentElement!)
        } else {
            return super.accessibilityAttributeValue(attribute)
        }
    }
}
