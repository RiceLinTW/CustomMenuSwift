//
//  SuggestionsViewController.swift
//  CustomMenuSwift
//
//  Created by Rice on 13/10/2017.
//  Copyright © 2017 Rice. All rights reserved.
//

import Cocoa

let DESKTOP_PICTURE_PATH = "/Library/Desktop Pictures"
let kSuggestionImage = "image";
let kSuggestionImageURL = "imageUrl";
let kSuggestionLabel = "label";
let kSuggestionDetailedLabel = "detailedLabel";

class SuggestionsViewController: NSViewController {

    @IBOutlet var window: NSWindow!
    @IBOutlet var imagePicker: NSPopUpButton!
    @IBOutlet var imageView: NSImageView!
    @IBOutlet var searchField: NSTextField!
    
    private var suggestionsController: SuggestionsWindowController?
    private var baseURL: URL?
    private var imageUrls: [URL]?
    private var suggestedURL: URL?
    private var skipNextSuggestion: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.baseURL = URL(fileURLWithPath: DESKTOP_PICTURE_PATH)
    }
    
    // MARK: - IBActions
    @IBAction func takeImageFromSuggestedURL(_ sender: Any?) {
        if let url = suggestedURL, let image = NSImage(contentsOf: url) {
            imageView.image = image
        } else {
            imageView.image = nil
        }
    }
    
    @IBAction func takeImageFrom(_ sender: Any?) {
        let s = sender as AnyObject
        guard
            let vc = s.representedObject as? NSViewController,
            let menuItemData = vc.representedObject as? NSDictionary else {
                return
        }
        if let imageURL = menuItemData["selectedUrl"] as? URL {
            let image = NSImage(contentsOf: imageURL)
            imageView.image = image
        } else {
            imageView.image = nil
        }
    }
    
    @IBAction func selectImageFolder(_ sender: Any?) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.directoryURL = URL(fileURLWithPath: DESKTOP_PICTURE_PATH)
        
        openPanel.beginSheetModal(for: self.window) { (result) in
            if result == NSApplication.ModalResponse.OK {
                self.baseURL = openPanel.url
                self.setupImagesMenu()
            }
        }
    }
    
    @IBAction func updateWithSelectedSuggestion(_ sender: Any?) {
        if
            let wc = sender as? SuggestionsWindowController,
            let entry = wc.selectedSuggestion() as? NSDictionary,
            let fieldEditor = self.searchField.currentEditor(),
            let suggestion = entry.object(forKey: kSuggestionLabel) as? String {
            
            self.update(fieldEditor: fieldEditor, with: suggestion)
            suggestedURL = entry.object(forKey: kSuggestionImageURL) as? URL
        }
    }
    
    // MARK: - Private Functions
    private func setupImagesMenu() {
        
    }
    
    private func update(fieldEditor: NSText, with suggestion: String) {
        let selection = NSMakeRange(fieldEditor.selectedRange.location, suggestion.lengthOfBytes(using: .utf8))
        fieldEditor.string = suggestion
        fieldEditor.selectedRange = selection
    }
    
    private func suggestionsForText(text: String) -> [[String : Any]]? {
        guard text != "" else { return nil }
        if imageUrls == nil {
            imageUrls = []
            let keyProperties: [URLResourceKey] = [.isDirectoryKey, .typeIdentifierKey, .localizedNameKey]
            let dirItr = FileManager.default.enumerator(at: baseURL!, includingPropertiesForKeys: keyProperties, options: [FileManager.DirectoryEnumerationOptions.skipsPackageDescendants, FileManager.DirectoryEnumerationOptions.skipsHiddenFiles], errorHandler: nil)
            
            while let file = dirItr?.nextObject() as? URL {
                if let isDirectory = try? file.resourceValues(forKeys: [URLResourceKey.isDirectoryKey]).isDirectory {
                    if !isDirectory! {
                        if let fileType = try? file.resourceValues(forKeys: [URLResourceKey.typeIdentifierKey]).typeIdentifier {
                            if UTTypeConformsTo(fileType! as CFString, kUTTypeImage) {
                                imageUrls?.append(file)
                            }
                        }
                    }
                }
            }
        }
        
        var suggestions: [[String : Any]]? = []
        
        for file in imageUrls! {
            if let localizedName = try? file.resourceValues(forKeys: [URLResourceKey.localizedNameKey]).localizedName {
                if (localizedName?.hasPrefix(text))! || (localizedName?.uppercased().hasPrefix(text.uppercased()))! {
                    let entry = [
                        kSuggestionLabel: localizedName!,
                        kSuggestionDetailedLabel: file.path,
                        kSuggestionImageURL: file
                        ] as [String : Any]
                    suggestions?.append(entry)
                }
            }
        }
        
        return suggestions
    }
    
    private func updateSuggestions(from control: NSControl) {
        if let fieldEditor = self.view.window?.fieldEditor(false, for: control) {
            let text = fieldEditor.string
            if let suggestions = self.suggestionsForText(text: String(text)), suggestions.count > 0 {
                let suggestion = suggestions.first
                self.suggestedURL = suggestion?[kSuggestionImageURL] as? URL
                self.update(fieldEditor: fieldEditor, with: suggestion![kSuggestionLabel] as! String)
                
                suggestionsController?.suggestions = suggestions
                suggestionsController?.begin(for: control as? NSTextField)
            } else {
                suggestedURL = nil
                suggestionsController?.cancelSuggestions()
            }
        }
    }
    
    override func controlTextDidBeginEditing(_ obj: Notification) {
        if suggestionsController == nil {
            suggestionsController = SuggestionsWindowController(contentRect: NSRect(origin: .zero, size: CGSize(width: 20, height: 20)))
            suggestionsController?.target = self
            suggestionsController?.action = #selector(updateWithSelectedSuggestion(_:))
        }
        self.updateSuggestions(from: obj.object as! NSControl)
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        if !self.skipNextSuggestion {
            self.updateSuggestions(from: obj.object as! NSControl)
        } else {
            suggestedURL = nil
            suggestionsController?.cancelSuggestions()
            self.skipNextSuggestion = false
        }
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        suggestionsController?.cancelSuggestions()
    }
}

extension SuggestionsViewController: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        switch commandSelector {
        case #selector(NSControl.moveUp(_:)):
            suggestionsController?.moveUp(textView)
            return true
        case #selector(NSControl.moveDown(_:)):
            suggestionsController?.moveDown(textView)
            return true
        case #selector(NSControl.deleteForward(_:)), #selector(NSControl.deleteBackward(_:)):
            self.skipNextSuggestion = true
            return false
        case #selector(NSControl.complete(_:)):
            if (suggestionsController?.window?.isVisible)! {
                suggestionsController?.cancelSuggestions()
            } else {
                self.updateSuggestions(from: control)
            }
            return true
        default:
            return false
        }
    }
}
