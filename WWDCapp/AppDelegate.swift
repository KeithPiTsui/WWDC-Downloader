//
//  AppDelegate.swift
//  WWDCapp
//
//  Created by David Roberts on 19/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var dockTile : NSDockTile?
    var dockProgress : NSProgressIndicator?
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        dockTile = NSApplication.sharedApplication().dockTile

        if let dockTile = dockTile {
            dockProgress = NSProgressIndicator(frame: NSRect(x: 0, y: 0, width: dockTile.size.width, height: 50))
            if let dockProgress = dockProgress {
                let imageView = NSImageView()
                imageView.image = NSApplication.sharedApplication().applicationIconImage
                dockTile.contentView = imageView
                
                dockProgress.style = NSProgressIndicatorStyle.BarStyle
                //dockProgress.usesThreadedAnimation = true
                dockProgress.startAnimation(self)
                dockProgress.indeterminate = false
                dockProgress.minValue = 0
                dockProgress.maxValue = 1
                dockProgress.needsDisplay = true
                dockProgress.hidden = false
                imageView.addSubview(dockProgress)
            }
        }
       
    }
    
    func updateDockProgress(progress: Double) {
        
        if let dockProgress = dockProgress, let dockTile = dockTile {
            dockProgress.doubleValue = progress
            dockTile.display()
        }
    }

    @IBAction func showPreferencesPanel(sender: NSMenuItem) {
        print("Show Preferences")
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

