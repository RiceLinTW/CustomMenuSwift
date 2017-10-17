//
//  RoundedCornersView.swift
//  CustomMenuSwift
//
//  Created by Rice on 06/10/2017.
//  Copyright © 2017 Rice. All rights reserved.
//

import Cocoa

class RoundedCornersView: NSView {

    var rcvCornerRadius: CGFloat = 10
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let borderPath = NSBezierPath(roundedRect: self.bounds, xRadius: rcvCornerRadius, yRadius: rcvCornerRadius)
        NSColor.windowBackgroundColor.setFill()
        borderPath.fill()
    }
    
    override func accessibilityIsIgnored() -> Bool {
        return false
    }
    
    override func accessibilityAttributeNames() -> [NSAccessibilityAttributeName] {
        var attributedNames: [NSAccessibilityAttributeName] = NSMutableArray(array: super.accessibilityAttributeNames()) as! [NSAccessibilityAttributeName]
        attributedNames.append(.orientation)
        attributedNames.append(.enabled)
        attributedNames.append(.visibleChildren)
        attributedNames.append(.selectedChildren)
        return attributedNames
    }
    
    override func accessibilityAttributeValue(_ attribute: NSAccessibilityAttributeName) -> Any? {
        switch attribute {
        case .role:
            return NSAccessibilityRole.list
        case .orientation:
            return NSAccessibilityOrientation.vertical
        case .enabled:
            return NSNumber(booleanLiteral: true)
        case .visibleChildren:
            return self.accessibilityAttributeValue(.children)
        case .selectedChildren:
            guard let elements = self.accessibilityAttributeValue(.children) as? [AnyObject] else {
                return nil
            }
            var selectedChildren: [AnyObject] = []
            for element in elements {
                if element.responds(to: #selector(getter: AnyObject.isHighlighted)) && element.isHighlighted {
                    selectedChildren.append(element)
                }
            }
            return selectedChildren
        default:
            return super.accessibilityAttributeValue(attribute)
        }
    }
    
    override func accessibilityIsAttributeSettable(_ attribute: NSAccessibilityAttributeName) -> Bool {
        switch attribute {
        case .orientation, .enabled, .visibleChildren, .selectedChildren:
            return false
        case .selectedChildren:
            return true
        default:
            return super.accessibilityIsAttributeSettable(attribute)
        }
    }
    
    override func accessibilitySetValue(_ value: Any?, forAttribute attribute: NSAccessibilityAttributeName) {
        if attribute == .selectedChildren {
            if let wc = self.window?.windowController {
                wc.setValue(value, forKey: "selectedView")
            }
        }else {
            super.accessibilitySetValue(value, forAttribute: attribute)
        }
    }
}
