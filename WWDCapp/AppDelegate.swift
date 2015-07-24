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
    @IBOutlet var dockProgress : NSProgressIndicator!
	
    var mainViewController : ViewController!

    var preferencesWindowController : NSWindowController?
    
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
            
            NSNotificationCenter.defaultCenter().addObserverForName(SessionViewerDidLaunchNotification, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock: { (notification) -> Void in

                window.standardWindowButton(NSWindowButton.CloseButton)?.enabled = false
            })
            
            NSNotificationCenter.defaultCenter().addObserverForName(SessionViewerDidCloseNotification, object: nil, queue: NSOperationQueue.mainQueue(), usingBlock: { (notification) -> Void in
                
                window.standardWindowButton(NSWindowButton.CloseButton)?.enabled = true
            })
		}
        

		setupDockTile()
		
	}
	
	func setupDockTile() {
		
		dockTile = NSApplication.sharedApplication().dockTile
		
		if let dockTile = dockTile, let dockProgress = dockProgress {
			
			let imageView = NSImageView()
			imageView.image = NSApplication.sharedApplication().applicationIconImage
			imageView.wantsLayer = true
			
			dockTile.contentView = imageView
			dockProgress.frame = CGRectMake(0, 0, dockTile.size.width, 20)
			
//				dockProgress.wantsLayer = true
//				dockProgress.style = NSProgressIndicatorStyle.BarStyle
			dockProgress.startAnimation(self)
//				dockProgress.indeterminate = false
//				dockProgress.minValue = 0
//				dockProgress.maxValue = 1
			dockProgress.hidden = false
			dockProgress.needsDisplay = true
			dockProgress.layerUsesCoreImageFilters = true

			// Not working to color progress indicator
//				if let filter = CIFilter(name: "CIHueAdjust") {
//					filter.setDefaults()
//					filter.setValue(0.8, forKey: "inputAngle")
//					dockProgress.contentFilters = [filter]
//				}
			
			imageView.addSubview(dockProgress)
			
			dockTile.display()
			
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
        
        UserInfo.sharedManager.save()
		
        Searching.sharedManager.save()
	}

}

