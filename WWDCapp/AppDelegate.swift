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
	
    var mainViewController : ViewController!

    var preferencesWindowController : NSWindowController?

    var transcriptDrawer : NSDrawer?
    
    var mainApplicationController: ToolbarHookableWindowSubclass?

    func applicationDidFinishLaunching(aNotification: NSNotification) {
		
        let simultaneousDownloads = NSUserDefaults.standardUserDefaults().integerForKey(simultaneousDownloadsKey)

        if simultaneousDownloads < 1 || simultaneousDownloads > 10 {
            NSUserDefaults.standardUserDefaults().setInteger(3, forKey: simultaneousDownloadsKey)
        }
        
		if let window = NSApplication.sharedApplication().windows.first {
			
			window.styleMask |= NSFullSizeContentViewWindowMask
			window.titlebarAppearsTransparent = true
			window.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
			
			window.titleVisibility = NSWindowTitleVisibility.Hidden
            
            mainApplicationController = window.windowController as? ToolbarHookableWindowSubclass
		}
        

		setupDockTile()
		
	}
	
	func setupDockTile() {
		
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
	
	// MARK: - DockTile
	func updateDockProgress(progress: Double) {
		
		if let dockProgress = dockProgress, let dockTile = dockTile {
			dockProgress.doubleValue = progress
			dockTile.display()
		}
	}
	
	
	func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
		return true
	}
	
	
    func applicationWillTerminate(aNotification: NSNotification) {
        
        UserInfo.sharedManager.archiveUserInfo({ (success) -> Void in
            if !success {
                print("Failed to save UserInfo")
            }
            else {
                print("Successfully Saved UserInfo")
            }
        })
        
        Searching.sharedManager.archiveSearchData{ (success) -> Void in
            if !success {
                print("Failed to Archive Search Data")
            }
            else {
                print("Successfully Archived Search Data")
            }
        }
    }

}

