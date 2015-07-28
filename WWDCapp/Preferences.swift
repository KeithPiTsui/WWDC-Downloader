//
//  Preferences.swift
//  WWDC
//
//  Created by David Roberts on 08/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa

let simultaneousDownloadsKey = "simultaneousDownloads"
let downloadFolderPreferencesKey = "downloadFolderPreferencesKey"

let downloadFolderURLBookmarkDataKey = "downloadFolderURLBookmarkDataKey"


let defaultSimultaneousDownloads = 3

class PreferencesController : NSViewController, NSPathControlDelegate {
    
    @IBOutlet weak var stepper: NSStepper!
    @IBOutlet weak var connectionsLabel: NSTextField!
	
	@IBOutlet weak var downloadFolderLabel: NSTextField!	
    @IBOutlet weak var pathControl: NSPathControl!

    override func awakeFromNib() {
		
		let numberOfDownloads = Preferences.sharedPreferences.simultaneousDownloads
		
        stepper.integerValue = numberOfDownloads
        connectionsLabel.stringValue = String(numberOfDownloads)
        
        if let url = Preferences.sharedPreferences.downloadFolderURL {
            pathControl.URL = url
        }
        else {
            pathControl.URL = nil
        }
    }
    
    @IBAction func stepperChanged(sender: NSStepper) {
        
		connectionsLabel.stringValue = String(sender.integerValue)
		DownloadFileManager.sharedManager.preferenceChanged()
    }
    
    func pathControl(pathControl: NSPathControl, willDisplayOpenPanel openPanel: NSOpenPanel) {
        
        let folders = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DownloadsDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        guard let folder = folders.first else { assertionFailure("No Downloads Directory!"); return }
        openPanel.directoryURL = NSURL(fileURLWithPath: folder)
        
        
        openPanel.allowsMultipleSelection = false
        openPanel.message = "Choose a download location for Videos, PDFs and Sample Code:"
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = true
        openPanel.prompt = "Choose"
        openPanel.resolvesAliases = true
    }
    
    func pathControl(pathControl: NSPathControl, willPopUpMenu menu: NSMenu) {
        
        let menuItem = NSMenuItem(title: "Reveal in Finder", action: Selector("menuItemAction"), keyEquivalent: "")
        menuItem.target = self
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItem(menuItem)
    }
    
    func menuItemAction(sender : NSMenuItem) {
        
        if let url = pathControl.clickedPathComponentCell()?.URL {
            let urlArray = [url]
            NSWorkspace.sharedWorkspace().openURLs(urlArray, withAppBundleIdentifier: "com.apple.Finder", options: NSWorkspaceLaunchOptions.WithoutActivation, additionalEventParamDescriptor: nil, launchIdentifiers: nil)
        }
    }
    
    @IBAction func folderSelected(sender: NSPathControl) {
		
        if let url = sender.clickedPathItem?.URL {
            Preferences.sharedPreferences.downloadFolderURL = url
            pathControl.URL = Preferences.sharedPreferences.downloadFolderURL
        }
	}

}

class Preferences {
	
	static let sharedPreferences = Preferences()
	
	var simultaneousDownloads : Int {
		get {
			let simultaneousDownloads = NSUserDefaults.standardUserDefaults().integerForKey(simultaneousDownloadsKey)
			
			if simultaneousDownloads < 1 || simultaneousDownloads > 10 {
				NSUserDefaults.standardUserDefaults().setInteger(defaultSimultaneousDownloads, forKey: simultaneousDownloadsKey)
				NSUserDefaults.standardUserDefaults().synchronize()
				return defaultSimultaneousDownloads
			}
			else {
				return simultaneousDownloads
			}
		}
		set {
			NSUserDefaults.standardUserDefaults().setInteger(newValue, forKey: simultaneousDownloadsKey)
			NSUserDefaults.standardUserDefaults().synchronize()
		}
	}
	
	var downloadFolder : String {
		get {
			if let folder = NSUserDefaults.standardUserDefaults().objectForKey(downloadFolderPreferencesKey) as? String {
				if folder.characters.count > 0 {
					return folder
				}
			}
			
			let folders = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DownloadsDirectory, NSSearchPathDomainMask.UserDomainMask, true)
			guard let folder = folders.first else { assertionFailure("No Downloads Directory!"); return "" }
			NSUserDefaults.standardUserDefaults().setObject(folder, forKey: downloadFolderPreferencesKey)
			NSUserDefaults.standardUserDefaults().synchronize()
			return folder
		}
		set {
			NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: downloadFolderPreferencesKey)
			NSUserDefaults.standardUserDefaults().synchronize()
		}
	}
    
    var downloadFolderURL : NSURL? {
        get {
            if let folderURLData = NSUserDefaults.standardUserDefaults().objectForKey(downloadFolderURLBookmarkDataKey) as? NSData {
                
                var staleData : ObjCBool = false
                do {
                    let url = try NSURL(byResolvingBookmarkData: folderURLData, options: [NSURLBookmarkResolutionOptions.WithSecurityScope , NSURLBookmarkResolutionOptions.WithoutUI], relativeToURL: nil, bookmarkDataIsStale: &staleData)
                    return url
                }
                catch {
                    print("BookmarkURL error - \(error)")
                }
                if staleData {
                    print("### BOOK MARK STALE ###")
                }
                return nil
            }
            else {
                
                if let url = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DownloadsDirectory, inDomains:  NSSearchPathDomainMask.UserDomainMask).last {
                    
                    if let path = url.path {
                        do {
                            let resolvedPath = try NSFileManager.defaultManager().destinationOfSymbolicLinkAtPath(path)
                            let bookmarkURL = NSURL(fileURLWithPath: resolvedPath, isDirectory: true)
                            
                            do {
                                let bookmarkData = try bookmarkURL.bookmarkDataWithOptions(NSURLBookmarkCreationOptions.WithSecurityScope, includingResourceValuesForKeys: nil, relativeToURL: nil)
                                NSUserDefaults.standardUserDefaults().setObject(bookmarkData, forKey: downloadFolderURLBookmarkDataKey)
                                
                                return bookmarkURL
                            }
                            catch {
                                print(error)
                            }
                        }
                        catch {
                            print(error)
                        }
                    }
                }
                return nil
            }
        }
        set {
            if let url = newValue {
                do {
                    let bookmarkData = try url.bookmarkDataWithOptions(NSURLBookmarkCreationOptions.WithSecurityScope, includingResourceValuesForKeys: nil, relativeToURL: nil)
                    NSUserDefaults.standardUserDefaults().setObject(bookmarkData, forKey: downloadFolderURLBookmarkDataKey)
                }
                catch {
                    print("Bookmark data attempted for \(url) - \(error)")
                }
            }
        }
    }
	
}
