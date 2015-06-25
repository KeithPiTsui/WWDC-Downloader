//
//  CheckBoxTableCell.swift
//  WWDC
//
//  Created by David Roberts on 25/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa

class CheckBoxTableViewCell : NSTableCellView {
	
	weak var file : FileInfo?
	
	var fileArray : [FileInfo]?
	
	@IBOutlet weak var checkBox: NSButton!
	@IBOutlet weak var label: NSTextField!
	@IBOutlet weak var loadingProgressView: NSProgressIndicator!
	@IBOutlet weak var downloadProgressView: NSProgressIndicator!
	@IBOutlet weak var downloadCompleteImage: NSButton!
	
	@IBAction func checked(sender: NSButton) {
		if let file = file {
			file.shouldDownloadFile = Bool(sender.state)
		}
	}
	
	func resetCell() {
		
		self.checkBox.hidden = true
		self.label.hidden = true
		self.downloadProgressView.hidden = true
		self.downloadCompleteImage.hidden = true
	}
	
	func updateCell(isSessionInfoFetchComplete:Bool) {
		
		var isAllFilesSizeFetchComplete = false
		var isAllFilesAlreadyDownloaded = false
		var isAllFilesDownloading = false
		var isAllFilesShouldDownload = false
		var fileDownloadProgress : Float = 0
		var totalDownloadSize : Int64 = 0
		
		if let fileArray = fileArray {
			for file in fileArray {
				
				
			}
		}
		
			// visible
		if isAllFilesSizeFetchComplete {
			self.checkBox.hidden = false
			self.label.hidden = false

			// Progress
			if isAllFilesAlreadyDownloaded {
				self.downloadProgressView.hidden = true
				self.label.hidden = true
				self.checkBox.hidden = true
				self.downloadCompleteImage.hidden = false
			}
			else {
				if isAllFilesDownloading {
					self.downloadProgressView.hidden = false
					self.downloadProgressView.doubleValue = Double(fileDownloadProgress)
					self.label.stringValue = NSByteCountFormatter().stringFromByteCount(Int64(fileDownloadProgress*Float(totalDownloadSize)))
				}
				else {
					self.downloadProgressView.hidden = true
					self.label.stringValue = NSByteCountFormatter().stringFromByteCount(Int64(totalDownloadSize))
				}
			}
			
		}
		else {
			self.checkBox.hidden = true
			self.label.hidden = true
			self.downloadProgressView.hidden = true
		}
		
		// enabled
		if (isSessionInfoFetchComplete) {
			
			self.checkBox.enabled = true
			
			if isAllFilesShouldDownload == true {
				self.checkBox.state = 1
			}
			else {
				self.checkBox.state = 0
			}
		}
		else {
			self.checkBox.enabled = false
		}
	}
}
