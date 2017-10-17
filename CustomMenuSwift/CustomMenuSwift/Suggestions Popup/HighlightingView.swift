//
//  HighlightingView.swift
//  CustomMenuSwift
//
//  Created by Rice on 06/10/2017.
//  Copyright © 2017 Rice. All rights reserved.
//

import Cocoa

class HighlightingView: NSView {

    var isHighlighted: Bool = false {
        didSet (value) {
            for view in self.subviews {
                if let textField = view as? NSTextField {
                    textField.cell?.backgroundStyle = value ? NSView.BackgroundStyle.light : NSView.BackgroundStyle.dark
                }
            }
            
            self.needsDisplay = true
        }
    }
 
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if self.isHighlighted {
            NSColor.alternateSelectedControlColor.set()
            dirtyRect.fill(using: .sourceOver)
        } else {
            NSColor.clear.set()
            dirtyRect.fill(using: .sourceOver)
        }
    }
    
    override func accessibilityIsIgnored() -> Bool {
        return false
    }
    
    override func accessibilityAttributeValue(_ attribute: NSAccessibilityAttributeName) -> Any? {
        if attribute == .role {
            return NSAccessibilityRole.group
        } else {
            return super.accessibilityAttributeValue(attribute)
        }
    }
    
}
