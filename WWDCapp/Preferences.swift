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

let defaultSimultaneousDownloads = 3

class PreferencesController : NSViewController {
    
    @IBOutlet weak var stepper: NSStepper!
    @IBOutlet weak var connectionsLabel: NSTextField!
	
	@IBOutlet weak var downloadFolderLabel: NSTextField!

	@IBOutlet weak var changeFolder : NSButton!
	
	@IBOutlet weak var applyChangesButton: NSButton!

    override func awakeFromNib() {
		
		let numberOfDownloads = Preferences.sharedPreferences.simultaneousDownloads
		
        stepper.integerValue = numberOfDownloads
        connectionsLabel.stringValue = String(numberOfDownloads)
        
		//downloadFolderLabel.stringValue = Preferences.sharedPreferences.downloadFolder
    }
    
    @IBAction func stepperChanged(sender: NSStepper) {
        
		connectionsLabel.stringValue = String(sender.integerValue)
		DownloadFileManager.sharedManager.preferenceChanged()
    }
	
	/*
    @IBAction func folderSelected(sender: NSButton) {
		
		let filePanel = NSOpenPanel()
		filePanel.directoryURL = NSURL(fileURLWithPath: Preferences.sharedPreferences.downloadFolder)
		filePanel.canCreateDirectories = true
		filePanel.canChooseDirectories = true
		filePanel.canChooseFiles = false
		filePanel.allowsMultipleSelection = false
		filePanel.showsHiddenFiles = false
		
		filePanel.prompt = "Choose Folder for Downloads"
		filePanel.beginSheetModalForWindow(self.view.window!) { result in
			if result == NSFileHandlingPanelOKButton {
				
				if let url = filePanel.URL {
					Preferences.sharedPreferences.saveBookMarkDataFor(url)
				}
				
//				if let path = filePanel.URL?.path {
//					Preferences.sharedPreferences.downloadFolder = path
//					self.downloadFolderLabel.stringValue = path
//				}
			}
		}
	}
	
//	@IBAction func revealInFinder(sender: NSButton) {
//		let path = Preferences.SharedPreferences().localVideoStoragePath
//		let root = path.stringByDeletingLastPathComponent
//		
//		let fileManager = NSFileManager.defaultManager()
//		if !fileManager.fileExistsAtPath(path) {
//			fileManager.createDirectoryAtPath(path, withIntermediateDirectories: false, attributes: nil, error: nil)
//		}
//		
//		NSWorkspace.sharedWorkspace().selectFile(path, inFileViewerRootedAtPath: root)
//	}

*/

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
	
	/*
	var bookmarkURLForDownloadFolder : NSURL? {
		get {
			var staleData : ObjCBool = false
			do {
				if let data = bookMarkData(downloadFolder) {
					let url = try NSURL(byResolvingBookmarkData: data, options: [NSURLBookmarkResolutionOptions.WithSecurityScope , NSURLBookmarkResolutionOptions.WithoutUI], relativeToURL: nil, bookmarkDataIsStale: &staleData)
					if (staleData) {
						print("### BOOK MARK STALE ###")
					}
					return url
				}
			}
			catch {
				print(error)
			}
			return nil
		}
	}
	
	func bookMarkData(path : String) -> NSData? {
		if let data = NSUserDefaults.standardUserDefaults().objectForKey(path) as? NSData {
			return data
		}
		return nil
	}
	
	func saveBookMarkDataFor(url: NSURL) {
		
		do {
			let bookmarkData = try url.bookmarkDataWithOptions(NSURLBookmarkCreationOptions.WithSecurityScope, includingResourceValuesForKeys: nil, relativeToURL: nil)
			
			if let path = url.path {
				NSUserDefaults.standardUserDefaults().setObject(bookmarkData, forKey: path)
				self.downloadFolder = path
			}
		}
		catch {
			print(error)
		}
	}
*/
	
}
