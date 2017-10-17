//
//  NSImageExt.swift
//  CustomMenuSwift
//
//  Created by Rice on 03/10/2017.
//  Copyright © 2017 Rice. All rights reserved.
//

import Cocoa
import AppKit

extension NSImage {
    class func iteThumbnailImageWith(contentsOf url: URL, width: CGFloat) -> NSImage? {
        var thumbnailImage: NSImage?
        
        if let image = NSImage(contentsOf: url) {
            let imageSize = image.size
            let imageAspectRatio = imageSize.height / imageSize.width
            
            let thumbnailSize = NSSize(width: width, height: width * imageAspectRatio)
            thumbnailImage = NSImage(size: thumbnailSize)
            
            thumbnailImage?.lockFocus()
            image.draw(in: NSRect(origin: .zero, size: thumbnailSize), from: .zero, operation: .sourceOver, fraction: 1)
            thumbnailImage?.unlockFocus()
            
            let imageName = url.deletingPathExtension().lastPathComponent
            thumbnailImage?.accessibilityDescription = imageName
        }
        
//        if NSEvent.modifierFlags.contains(.control) {
//            usleep(2000000)
//        }
        return thumbnailImage
    }
}

var ITESharedOperationQueue: OperationQueue? {
    let queue = OperationQueue()
    queue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
    return queue
}

