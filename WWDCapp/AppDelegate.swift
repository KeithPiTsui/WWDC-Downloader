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
			
			// populate download url and check
			if Preferences.sharedPreferences.downloadFolderURL == nil {
				Preferences.sharedPreferences.populateFolderURL()
				
				guard let _ = Preferences.sharedPreferences.downloadFolderURL else { assertionFailure("No Directory Available to Download to! - You may need to choose a Team in xcode to sign the app as it needs entitlements for directory access!"); return }
			}
		}
    }

	
	func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
		return true
	}
	
	
    func applicationWillTerminate(aNotification: NSNotification) {
				
        Preferences.sharedPreferences.stopAccessingURLResource()
        
        UserInfo.sharedManager.save()
		
        Searching.sharedManager.save()
	}

}

