//
//  DockProgressBar.swift
//  WWDC
//
//  Created by David Roberts on 24/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa

class DockProgressBar : NSProgressIndicator {
    
    static let appProgressBar = DockProgressBar(frame: NSMakeRect(0, 0, NSApp.dockTile.size.width, 12
        ))
    
    override init(frame frameRect: NSRect) {
        
        super.init(frame: frameRect)

        self.style = NSProgressIndicatorStyle.BarStyle
        self.indeterminate = false
        self.bezeled = false
        self.minValue = 0
        self.maxValue = 1
        self.hidden = false
        self.doubleValue = 0
        
        addProgress()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func drawRect(dirtyRect: NSRect) {
        
        // Outline
        let rect = NSInsetRect(self.bounds, 1.0, 1.0)
        let radius = rect.size.height / 2
        let bezierPath = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        bezierPath.lineWidth = 2.0
        NSColor.grayColor().set()
        bezierPath.stroke()

        // inside
        let insideRect = NSInsetRect(rect, 2.0, 2.0)
        let insideRadius = insideRect.size.height / 2
        let insideBezierpath = NSBezierPath(roundedRect: insideRect, xRadius: insideRadius, yRadius: insideRadius)
        insideBezierpath.lineWidth = 1.0
        insideBezierpath.addClip()
        let widthOfProgress = floor(CGFloat(insideRect.size.width) * (CGFloat(self.doubleValue) / CGFloat(self.maxValue)))
        var rectToDraw = insideRect
        rectToDraw.size.width = widthOfProgress
        NSColor(colorLiteralRed: 0.2, green: 0.6, blue: 1, alpha: 1).set()
        NSRectFill(rectToDraw)
    }
    
    private func addProgress() {
        
        if NSApp.dockTile.contentView == nil {
            let imageView = NSImageView()
            imageView.image = NSApplication.sharedApplication().applicationIconImage
            NSApp.dockTile.contentView = imageView
            imageView.addSubview(self)
        }
    }
    
    func updateProgress(progress: Double) {
        addProgress()
        self.hidden = false
        self.doubleValue = progress
        NSApp.dockTile.display()
    }
    
    func hideProgressBar() {
        self.hidden = true
        NSApp.dockTile.display()
    }
    
    func removeProgress() {
        self.doubleValue = 0
        NSApp.dockTile.contentView = nil
        NSApp.dockTile.display()
    }
    
}