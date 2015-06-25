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
	
	var fileArray : [FileInfo]?
	
	@IBOutlet weak var checkBox: NSButton!
	@IBOutlet weak var label: NSTextField!
	@IBOutlet weak var loadingProgressView: NSProgressIndicator!
	@IBOutlet weak var downloadProgressView: NSProgressIndicator!
	@IBOutlet weak var downloadCompleteImage: NSButton!
	
	func resetCell() {
		
		self.checkBox.hidden = true
		self.label.hidden = true
		self.downloadProgressView.hidden = true
		self.downloadCompleteImage.hidden = true
	}
	
	func updateCell(isYearInfoFetchComplete:Bool, isDownloadSessionActive:Bool) {
		
		var isAllFilesSizeFetchComplete = true
		var isAllFilesAlreadyDownloaded = true
		var isAllFilesDownloading = false
		var isAllFilesShouldDownload = true
		var currentDownloadBytes : Int64 = 0
		var totalDownloadSizeBytes : Int64 = 0
		
		if let fileArray = fileArray {
			for file in fileArray {
				
				if let fileSize = file.fileSize {
					
					currentDownloadBytes += Int64(Double(file.downloadProgress)*Double(fileSize))
					totalDownloadSizeBytes += Int64(fileSize)
					
					// Progress
					if file.isFileAlreadyDownloaded == false {
	
						if isAllFilesAlreadyDownloaded == true {
							isAllFilesAlreadyDownloaded = false
						}
						
						if file.downloadProgress > 0 {
							if isAllFilesDownloading == false {
								isAllFilesDownloading = true
							}
						}
					}
					else {
						if isAllFilesDownloading == true {
							isAllFilesDownloading = false
						}
					}
				}
				else {
					
					if isAllFilesSizeFetchComplete == true {
						isAllFilesSizeFetchComplete = false
					}
				}
				
				if file.shouldDownloadFile == false {
					isAllFilesShouldDownload = false
				}
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
					let progress = Double(Float(currentDownloadBytes)/Float(totalDownloadSizeBytes))
					self.downloadProgressView.doubleValue = progress
					self.label.stringValue = NSByteCountFormatter().stringFromByteCount(Int64(progress*Double(totalDownloadSizeBytes)))
				}
				else {
					self.downloadProgressView.hidden = true
					self.label.stringValue = NSByteCountFormatter().stringFromByteCount(totalDownloadSizeBytes)
				}
			}
			
		}
		else {
			self.checkBox.hidden = true
			self.label.hidden = true
			self.downloadProgressView.hidden = true
		}
		
		if (isYearInfoFetchComplete) {
			
			if isAllFilesShouldDownload == true {
				self.checkBox.state = 1
			}
			else {
				self.checkBox.state = 0
			}
			
			if (isDownloadSessionActive) {
				self.checkBox.enabled = false

			}
			else {
				self.checkBox.enabled = true
			}
		}
		else {
			self.checkBox.enabled = false
		}
	}
}
