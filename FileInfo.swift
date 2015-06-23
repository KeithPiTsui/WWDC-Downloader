//
//  FileInfo.swift
//  WWDC
//
//  Created by David Roberts on 23/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation

@objc class FileInfo : NSObject {
	
	var remoteFileURL : NSURL?
	var localFileURL : NSURL?
	
	var displayName : String?
	var fileSize : Int?
	var fileName : String?
	
	var shouldDownloadFile : Bool = true
	
	var isFileAlreadyDownloaded : Bool  {
		get {
			if let url = localFileURL {
				do {
					if let path = url.path {
						let fileAttributes = try NSFileManager.defaultManager().attributesOfItemAtPath(path)
						if let size = fileAttributes["NSFileSize"] as? Int, let fileSize = fileSize {
							if size == fileSize {
								return true
							}
						}
					}
				}
				catch {
					print("File Size Compare error - \(error)")
				}
			}
			return false
		}
	}
}
