//
//  SuggestibleTextFieldCell.swift
//  CustomMenuSwift
//
//  Created by Rice on 11/10/2017.
//  Copyright © 2017 Rice. All rights reserved.
//

import Cocoa

class SuggestibleTextFieldCell: NSTextFieldCell {
    
    var suggestionsWindow: NSWindow?
    
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        let textColor = self.textColor
        if self.backgroundStyle == .dark {
            self.textColor = .white
        }
        super.draw(withFrame: cellFrame, in: controlView)
        
        self.textColor = textColor
    }
    
    override func accessibilityAttributeValue(_ attribute: NSAccessibilityAttributeName) -> Any? {
        if attribute == .children && suggestionsWindow != nil {
            return (super.accessibilityAttributeValue(attribute) as? NSArray)?.adding(NSAccessibilityUnignoredDescendant(self.suggestionsWindow!)!)
        } else {
            return super.accessibilityAttributeValue(attribute)
        }
    }
}
