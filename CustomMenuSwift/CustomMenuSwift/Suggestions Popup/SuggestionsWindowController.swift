//
//  SuggestionsWindowController.swift
//  CustomMenuSwift
//
//  Created by Rice on 03/10/2017.
//  Copyright © 2017 Rice. All rights reserved.
//

import Cocoa

let kTrackerKey = "TrackerKey"

class SuggestionsWindowController: NSWindowController {

    var parentTextField: NSTextField?
    var target: Any?
    var action: Selector?
    
    var suggestions: [[String:Any]]? {
        didSet {
            self.layoutSuggestions()
        }
    }
    
    var viewControllers: [NSViewController]?
    var trackingAreas: [NSTrackingArea]?
    var needsLayoutUpdate = false
    var localMouseDownEventMonitor: Any?
    var lostFocusObserver: Any?
    var selectedView: HighlightingView? {
        didSet (view) {
            self.selectedView?.isHighlighted = true
        }
    }
    
    // MARK: - View Life Cycle
    convenience init(contentRect: NSRect) {
        let window = SuggestionsWindow(with: contentRect, defer: true)
        self.init(window: window)
        let contentView = RoundedCornersView(frame: contentRect)
        window.contentView = contentView
        contentView.autoresizesSubviews = false
        self.needsLayoutUpdate = true
        self.window = window
    }
    
    // MARK: - Public Functions
    func selectedSuggestion() -> Any? {
        var suggestion: Any? = nil
        
        for vc in viewControllers! {
            if self.selectedView == vc.view {
                suggestion = vc.representedObject
                break
            }
        }
        
        return suggestion
    }
    
    func begin(for textField: NSTextField?) {
        guard
            let suggestionWindow = self.window as? SuggestionsWindow,
            let parentWindow = textField?.window else {
                return
        }
        let parentFrame = textField?.frame
        var frame = suggestionWindow.frame
        frame.size.width = (parentFrame?.width)!
        
        let location = textField?.superview?.convert((parentFrame?.origin)!, to: nil)
        var rect = parentWindow.convertToScreen(NSRect(origin: location!, size: NSSize.zero))
        rect.origin.y -= 2
        suggestionWindow.setFrame(frame, display: false)
        suggestionWindow.setFrameTopLeftPoint(rect.origin)
        layoutSuggestions()
        
        parentWindow.addChildWindow(suggestionWindow, ordered: .above)
        
        parentTextField = textField
        
        let unignoreedAccessibilityDescendant = NSAccessibilityUnignoredDescendant(parentTextField!)
        suggestionWindow.parentElement = unignoreedAccessibilityDescendant
        if let cell = unignoreedAccessibilityDescendant as? SuggestibleTextFieldCell {
            cell.suggestionsWindow = suggestionWindow
        }
        NSAccessibilityPostNotification(NSAccessibilityUnignoredDescendant(suggestionWindow)!, NSAccessibilityNotificationName.created)
        
        localMouseDownEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown], handler: { (event) -> NSEvent? in
            if event.window != suggestionWindow {
                if event.window == parentWindow {
                    guard let contentView = parentWindow.contentView else { return nil }
                    let locationTest = contentView.convert(event.locationInWindow, from: nil)
                    let hitView = contentView.hitTest(locationTest)
                    let fieldEditor = self.parentTextField?.currentEditor()
                    
                    if hitView != parentWindow && fieldEditor != nil && hitView != fieldEditor {
                        self.cancelSuggestions()
                        return nil
                    }
                } else {
                    self.cancelSuggestions()
                }
            }
            
            return event
        })
        
        lostFocusObserver = NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: parentWindow, queue: nil, using: { (_) in
            self.cancelSuggestions()
        })
    }
    
    func cancelSuggestions() {
        guard let suggestionWindow = self.window as? SuggestionsWindow else { return }
        if suggestionWindow.isVisible {
            suggestionWindow.parent?.removeChildWindow(suggestionWindow)
            suggestionWindow.orderOut(nil)
            
            (suggestionWindow.parentElement as? SuggestibleTextFieldCell)?.suggestionsWindow = nil
            suggestionWindow.parentElement = nil
        }
        
        if lostFocusObserver != nil {
            NotificationCenter.default.removeObserver(lostFocusObserver!)
            lostFocusObserver = nil
        }
        
        if localMouseDownEventMonitor != nil {
            NSEvent.removeMonitor(localMouseDownEventMonitor!)
            localMouseDownEventMonitor = nil
        }
    }
    
    // MARK: - Private Functions
    private func layoutSuggestions() {
        guard let contentView = self.window?.contentView as? RoundedCornersView else {
            return
        }
        self.selectedView = nil
        if viewControllers != nil {
            for vc in viewControllers! {
                vc.view.removeFromSuperview()
            }
            viewControllers?.removeAll()
            
            for area in trackingAreas! {
                contentView.removeTrackingArea(area)
            }
            trackingAreas?.removeAll()
        } else {
            viewControllers = []
            trackingAreas = []
        }
        
        var frame = NSRect()
        frame.size.height = 0
        frame.size.width = contentView.frame.width
        frame.origin = NSPoint(x: 0, y: contentView.rcvCornerRadius)
        
        if suggestions == nil {
            suggestions = []
        }
        
        for var entry in suggestions! {
            frame.origin.y += frame.size.height
            let vc = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: Bundle.main).instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "HighlightingViewController")) as! NSViewController
            let view = vc.view as! HighlightingView
            
            if viewControllers?.count == 0 {
                self.selectedView?.isHighlighted = false
                self.selectedView = view
            }
            
            frame.size.height = view.frame.height
            view.frame = frame
            contentView.addSubview(view)
            
            let trackingArea = self.trackingAreaForView(view: view)
            contentView.addTrackingArea(trackingArea!)
            
            viewControllers?.append(vc)
            trackingAreas?.append(trackingArea!)
            
            vc.representedObject = entry

            if entry[kSuggestionImage] == nil {
                ITESharedOperationQueue?.addOperation({
                    if let fileURL = entry[kSuggestionImageURL] as? URL {
                        if let thumbnailImage = NSImage.iteThumbnailImageWith(contentsOf: fileURL, width: 24) {
                            OperationQueue.main.addOperation({
                                entry[kSuggestionImage] = thumbnailImage
                                vc.representedObject = entry
                            })
                        }
                    }
                })
            }
        }
        
        var winFrame = NSRect(origin: (window?.frame.origin)!, size: (window?.frame.size)!)//window?.frame
        winFrame.origin.y = winFrame.maxY - contentView.frame.height
        winFrame.size.height = frame.maxY + contentView.rcvCornerRadius
        window?.setFrame(winFrame, display: true)
    }
    
    private func userSetSelectedView(view: HighlightingView?) {
        self.selectedView?.isHighlighted = false
        self.selectedView = view
        guard let ac = self.action else { return }
        NSApp.sendAction(ac, to: self.target, from: self)
    }
    
    //MARK: - Mouse Tracking
    func trackingAreaForView(view: NSView) -> NSTrackingArea? {
        let trackerData = [kTrackerKey: view]
        guard let trackingRect = self.window?.contentView?.convert(view.bounds, from: view) else { return nil }
        return NSTrackingArea(rect: trackingRect, options: [.enabledDuringMouseDrag, .mouseEnteredAndExited, .activeInActiveApp], owner: self, userInfo: trackerData)
    }
    
    override func mouseEntered(with event: NSEvent) {
        let view = event.trackingArea?.userInfo![kTrackerKey] as! HighlightingView
        self.userSetSelectedView(view: view)
    }
    
    override func mouseExited(with event: NSEvent) {
        self.userSetSelectedView(view: nil)
    }
    
    override func mouseUp(with event: NSEvent) {
        parentTextField?.validateEditing()
        parentTextField?.abortEditing()
        parentTextField?.sendAction(parentTextField?.action, to: parentTextField?.target)
        self.cancelSuggestions()
    }
    
    //MARK: - Keyboard Tracking
    override func moveUp(_ sender: Any?) {
        let selectedView = self.selectedView
        var previouseView: HighlightingView?
        for vc in viewControllers! {
            if vc.view == selectedView {
                break
            }
            previouseView = vc.view as? HighlightingView
        }
        
        if previouseView != nil {
            self.userSetSelectedView(view: previouseView)
        }
    }
    
    override func moveDown(_ sender: Any?) {
        let selectedView = self.selectedView
        var previouseView: HighlightingView?
        for vc in viewControllers!.reversed() {
            if vc.view == selectedView {
                break
            }
            previouseView = vc.view as? HighlightingView
        }
        
        if previouseView != nil {
            self.userSetSelectedView(view: previouseView)
        }
    }
}
