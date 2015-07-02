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

	static let byteFormatter : NSByteCountFormatter = {
		let aFormatter = NSByteCountFormatter()
		aFormatter.zeroPadsFractionDigits = true
		return aFormatter
	}()
	
	func resetCell() {
		
		if #available(OSX 10.11, *) {
		    label.font = NSFont.monospacedDigitSystemFontOfSize(NSFont.systemFontSizeForControlSize(NSControlSize.SmallControlSize), weight: NSFontWeightRegular)
		}
		
		checkBox.hidden = true
		label.hidden = true
		downloadProgressView.hidden = true
		downloadCompleteImage.hidden = true
		checkBox.enabled = false
		checkBox.state = 1
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
			checkBox.hidden = false
			label.hidden = false

			// Progress
			if isAllFilesAlreadyDownloaded {
				downloadProgressView.hidden = true
				label.hidden = true
				checkBox.hidden = true
				downloadCompleteImage.hidden = false
			}
			else {
				if isAllFilesDownloading {
					downloadProgressView.hidden = false
					let progress = Double(Float(currentDownloadBytes)/Float(totalDownloadSizeBytes))
					downloadProgressView.doubleValue = progress
					
					if isDownloadSessionActive {
						label.stringValue = CheckBoxTableViewCell.byteFormatter.stringFromByteCount(Int64(progress*Double(totalDownloadSizeBytes)))
                    }
                    else {
						label.stringValue = CheckBoxTableViewCell.byteFormatter.stringFromByteCount(totalDownloadSizeBytes)
                    }
				}
				else {
					downloadProgressView.hidden = true
					label.stringValue = CheckBoxTableViewCell.byteFormatter.stringFromByteCount(totalDownloadSizeBytes)
				}
			}
		}
		else {
			checkBox.hidden = true
			label.hidden = true
			downloadProgressView.hidden = true
		}
		
		if (isYearInfoFetchComplete) {
			
			if isAllFilesShouldDownload == true {
				checkBox.state = 1
			}
			else {
				checkBox.state = 0
			}
			
			if isDownloadSessionActive {
				checkBox.enabled = false
			}
			else {
				checkBox.enabled = true
			}
		}
		else {
			checkBox.enabled = false
		}
	}
}
