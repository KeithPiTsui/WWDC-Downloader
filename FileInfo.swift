//
//  FileInfo.swift
//  WWDC
//
//  Created by David Roberts on 23/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation

enum WWDCYear {
	case WWDC2015, WWDC2014, WWDC2013
}

enum FileType {
	case PDF, SD, HD, SampleCode
}

@objc class FileInfo : NSObject {
	
	let fileType : FileType
	unowned let session : WWDCSession
	
	var remoteFileURL : NSURL?
	var fileSize : Int?
	
	var shouldDownloadFile : Bool = true
	
	var downloadProgress : Float = 0
	
	
	var sessionID : String {
		get {
			return session.sessionID
		}
	}
	
	var title : String {
		get {
			return session.title
		}
	}
	
	var year : WWDCYear {
		get {
			return session.sessionYear
		}
	}

	var fileName : String? {
		get {
			
			switch (fileType) {
			case .PDF:
				return self.sanitizeFileNameString(sessionID+"-"+title)+".pdf"
			case .SD:
				return self.sanitizeFileNameString(sessionID+"-"+title)+"-SD.mp4"
			case .HD:
				return self.sanitizeFileNameString(sessionID+"-"+title)+"-HD.mp4"
			case .SampleCode:
				guard let fileName = remoteFileURL?.lastPathComponent else { return nil }
				return fileName
			}
		}
	}
	
	
	var localFileURL : NSURL? {
		get {
			switch (fileType) {
			case .PDF:
				guard let directory = self.pdfDirectory(), let filename = self.fileName  else { return nil }
				return NSURL(fileURLWithPath: directory.stringByAppendingPathComponent(self.sanitizeFileNameString( filename)))
			case .SD:
				guard let directory = self.videoDirectory(), let filename = self.fileName  else { return nil }
				return NSURL(fileURLWithPath: directory.stringByAppendingPathComponent(self.sanitizeFileNameString( filename)))
			case .HD:
				guard let directory = self.videoDirectory(), let filename = self.fileName  else { return nil }
				return NSURL(fileURLWithPath: directory.stringByAppendingPathComponent(self.sanitizeFileNameString( filename)))
			case .SampleCode:
				guard let directory = self.codeDirectory(), let filename = self.fileName  else { return nil }
				return NSURL(fileURLWithPath: directory.stringByAppendingPathComponent(self.sanitizeFileNameString( filename)))
			}
		}
	}
	
	var displayName : String? {
		get {
			switch (fileType) {
				case .PDF:
					return sessionID+" - "+title+" PDF"
				case .SD:
					return sessionID+" - "+title+" SD Video"
				case .HD:
					return sessionID+" - "+title+" HD Video"
				case .SampleCode:
					guard let fileName = remoteFileURL?.lastPathComponent else { return nil }
					return sessionID+" - "+title+" - "+fileName+" Sample Code"
			}
		}
	}

	var isFileAlreadyDownloaded : Bool  {
		get {
	
			if fileExistsLocallyForFile() {
				if let url = localFileURL {
					do {
						if let path = url.path {
							
							let fileAttributes = try NSFileManager.defaultManager().attributesOfItemAtPath(path)
							if let size = fileAttributes["NSFileSize"] as? Int, let fileSize = fileSize {
								if size == fileSize {
									downloadProgress = 1
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
			else {
				return false
			}
		}
	}
	
	// MARK: - Init
	init(session: WWDCSession, fileType: FileType) {
		
		self.session = session
		self.fileType = fileType
		
		super.init()
		
		if isFileAlreadyDownloaded == true {
			print("\(displayName) - Already Downloaded")
		}
	}
	
	
	func fileExistsLocallyForFile() -> Bool {
		if let localFileURL = self.localFileURL {
			if let localFileURLString = localFileURL.path {
				return NSFileManager.defaultManager().fileExistsAtPath(localFileURLString)
			}
		}
		return false
	}
	
	func saveFileLocallyFrom(url: NSURL) {
		
		if isFileAlreadyDownloaded == false {
			// Copy the file over to the correct location
			if let localFileURL = self.localFileURL {
				do {
					try NSFileManager.defaultManager().moveItemAtURL(url, toURL: localFileURL)
				}
				catch {
					print("File move/save error - \(error)")
				}
			}
		}
	}

	
	// MARK: - Directory Helpers
	func wwdcDirectory () -> String? {
		
		let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
		
		guard let documentsDirectory = paths.first else { return nil }
		
		let path = "/WWDC"
		
		return createDirectoryIfNeeded(path, inDirectory: documentsDirectory)
	}
	
	func yearDirectory(year : WWDCYear) -> String? {
		
		guard let wwdcDirectory = wwdcDirectory()  else { return nil }
		
		var yearpath : String?
		
		switch year {
		case .WWDC2015:
			yearpath = "/2015"
		case .WWDC2014:
			yearpath = "/2014"
		case .WWDC2013:
			yearpath = "/2013"
		}
		
		guard let path = yearpath else { return nil }
		
		return createDirectoryIfNeeded(path, inDirectory: wwdcDirectory)
	}
	
	
	func videoDirectory () -> String? {
		
		guard let wwdcDirectory = yearDirectory(year)  else { return nil }
		
		let path = "/Videos"
		
		return createDirectoryIfNeeded(path, inDirectory: wwdcDirectory)
	}
	
	func codeDirectory () -> String? {
		
		guard let wwdcDirectory = yearDirectory(year)  else { return nil }
		
		let path = "/Code Samples"
		
		return createDirectoryIfNeeded(path, inDirectory: wwdcDirectory)
	}
	
	func pdfDirectory () -> String? {
		
		guard let wwdcDirectory = yearDirectory(year)  else { return nil }
		
		let path = "/PDFs"
		
		return createDirectoryIfNeeded(path, inDirectory: wwdcDirectory)
	}
	
	
	// MARK: Helpers

	private func sanitizeFileNameString(filename : String) -> String {
		let characters = NSCharacterSet(charactersInString: "/\\?%*|\"<>:")
		let components = filename.componentsSeparatedByCharactersInSet(characters) as NSArray
		return components.componentsJoinedByString("")
		
	}
	
	private func createDirectoryIfNeeded(directory : String, inDirectory: String) -> String? {
		
		let path = inDirectory.stringByAppendingPathComponent(directory)
				
		if !NSFileManager.defaultManager().fileExistsAtPath(path) {
			do {
				try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
			}
			catch {
				print(error)
			}
		}
		return path
	}

}
