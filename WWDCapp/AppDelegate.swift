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
		
		if let window = NSApplication.sharedApplication().windows.first {
			
			let zoomButton = window.standardWindowButton(NSWindowButton.ZoomButton)

			zoomButton?.enabled = false
			zoomButton?.hidden = true
			
			window.styleMask |= NSFullSizeContentViewWindowMask
			window.titlebarAppearsTransparent = false
			window.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
			
			window.titleVisibility = NSWindowTitleVisibility.Hidden
		}
        
        dockTile = NSApplication.sharedApplication().dockTile

        if let dockTile = dockTile {
            dockProgress = NSProgressIndicator(frame: NSRect(x: 0, y: 0, width: dockTile.size.width, height: 20))
            if let dockProgress = dockProgress {
                let imageView = NSImageView()
                imageView.image = NSApplication.sharedApplication().applicationIconImage
                dockTile.contentView = imageView

				dockProgress.style = NSProgressIndicatorStyle.BarStyle
                dockProgress.startAnimation(self)
                dockProgress.indeterminate = false
                dockProgress.minValue = 0
                dockProgress.maxValue = 1
                dockProgress.hidden = false
				dockProgress.needsDisplay = true

				// Not working to color progress indicator
//				if let filter = CIFilter(name: "CIHueAdjust") {
//					filter.setDefaults()
//					filter.setValue(0.8, forKey: "inputAngle")
//					dockProgress.backgroundFilters = [filter]
//				}
				
                imageView.addSubview(dockProgress)
				
				dockTile.display()
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
	
	
	func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
		return true
	}
	
	
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear zown your application
		
    }
}

