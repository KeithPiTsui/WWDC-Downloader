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
    var transcriptController: TranscriptPanelController?

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
        
        setupTranscriptDrawer()
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
	
	// MARK: - Transcript Drawer
    func setupTranscriptDrawer() {
		
        if let mainWindowController = mainApplicationController {

            if let mainViewController = mainWindowController.contentViewController as? ViewController {
				
				self.mainViewController = mainViewController
                
                transcriptDrawer = NSDrawer(contentSize: NSSizeFromCGSize(CGSizeMake(400, mainViewController.view.frame.size.height)), preferredEdge: NSRectEdge.MaxX)
				
                if let transcriptDrawer = transcriptDrawer {
					
					transcriptDrawer.leadingOffset = 10
					
                    transcriptDrawer.parentWindow = mainWindowController.window
					
					transcriptDrawer.minContentSize = NSSizeFromCGSize(CGSizeMake(160, mainViewController.view.frame.size.height))
					
                    let storyboard = NSStoryboard(name: "Main", bundle: nil)
                    transcriptController = storyboard.instantiateControllerWithIdentifier("Transcript") as? TranscriptPanelController
					
					if let transcriptController = transcriptController {
						
						transcriptDrawer.contentView = transcriptController.view
												
						transcriptDrawer.contentView?.autoresizingMask = [NSAutoresizingMaskOptions.ViewHeightSizable, NSAutoresizingMaskOptions.ViewWidthSizable]
					}
				}
            }
        }
    }
	
	func highlightTranscript() {
		transcriptController?.highlightText(mainViewController.searchField.stringValue)
	}
	
	func toggleTranscript() {
		
		if transcriptDrawer?.state == Int(NSDrawerState.ClosedState.rawValue) {
			transcriptDrawer?.openOnEdge(NSRectEdge.MaxX)
		}
		else {
			transcriptDrawer?.close()
		}
	}
	
    func updateTranscript(wwdcSession : WWDCSession) {
        transcriptController?.wwdcSession = wwdcSession
		highlightTranscript()
    }
    
    func hideTranscript() {
        transcriptDrawer?.close()
    }
    

	// MARK: - Preferences
    @IBAction func showPreferencesPanel(sender: NSMenuItem) {
        
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        preferencesWindowController = storyboard.instantiateControllerWithIdentifier("Preferences") as? NSWindowController
        
        if let window = preferencesWindowController?.window {
            
            let min = window.standardWindowButton(NSWindowButton.MiniaturizeButton)
            let full = window.standardWindowButton(NSWindowButton.FullScreenButton)
            let zoomButton = window.standardWindowButton(NSWindowButton.ZoomButton)
            
            min?.hidden = true
            full?.hidden = true
            zoomButton?.hidden = true
        }
        
        preferencesWindowController?.showWindow(self)
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
        // Insert code here to tear zown your application
		
    }
}

