//
//  FileInfo.swift
//  WWDC
//
//  Created by David Roberts on 23/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation

enum WWDCYear: CustomStringConvertible {
	case WWDC2015
    case WWDC2014
    case WWDC2013
    
    var description : String {
        switch self {
        case .WWDC2015:
            return "2015"
        case .WWDC2014:
            return "2014"
        case .WWDC2013:
            return "2013"
        }
    }
}

enum FileType: CustomStringConvertible {
	case PDF
    case SD
    case HD
    case SampleCode
    
    var description : String {
        switch self {
        case .PDF:
            return "PDF"
        case .SD:
            return "SD"
        case .HD:
            return "HD"
        case .SampleCode:
            return "Sample Code"
        }
    }
}

@objc class FileInfo : NSObject, NSCoding {
	
	let fileType : FileType
	weak var session : WWDCSession?
	
	var remoteFileURL : NSURL?
	var fileSize : Int?
	var shouldDownloadFile : Bool = true
    
    var isFileMarkedAsDownloaded = false
    
	var downloadProgress : Float = 0
	var attemptsToDownloadFile = 0
	var fileErrorCode : NSError?
    var resumeData : NSData?
	
    // MARK: Convenience
	var sessionID : String {
		get {
			if let session = session {
				return session.sessionID
			}
			else {
				return ""
			}
		}
	}
	
	var title : String {
		get {
			if let session = session {
				return session.title
			}
			else {
				return ""
			}
		}
	}
	
	var year : WWDCYear {
		get {
			if let session = session {
				return session.sessionYear
			}
			else {
				return .WWDC2015 // should never happen but needed to satisfy weak optional to break ref cycle
			}
		}
	}

	var fileName : String? {
		get {
			
			switch (fileType) {
			case .PDF:
				return (sessionID+"-"+title).sanitizeFileNameString()+".pdf"
			case .SD:
				return (sessionID+"-"+title).sanitizeFileNameString()+"-SD.mp4"
			case .HD:
				return (sessionID+"-"+title).sanitizeFileNameString()+"-HD.mp4"
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
				guard let directory = FileInfo.pdfDirectory(year), let filename = self.fileName  else { return nil }
				return directory.URLByAppendingPathComponent(filename.sanitizeFileNameString())
			case .SD:
				guard let directory = FileInfo.videoDirectory(year), let filename = self.fileName  else { return nil }
                return directory.URLByAppendingPathComponent(filename.sanitizeFileNameString())
			case .HD:
				guard let directory = FileInfo.videoDirectory(year), let filename = self.fileName  else { return nil }
                return directory.URLByAppendingPathComponent(filename.sanitizeFileNameString())
			case .SampleCode:
				guard let directory = FileInfo.codeDirectory(year), let filename = self.fileName  else { return nil }
                return directory.URLByAppendingPathComponent(filename.sanitizeFileNameString())
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
								downloadProgress = 0
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
	
	// MARK: - Encoding
	required init(coder aDecoder: NSCoder) {
		self.session  = aDecoder.decodeObjectForKey("session") as? WWDCSession
		let fileTypeString  = aDecoder.decodeObjectForKey("fileType") as! String
		switch fileTypeString {
		case "PDF":
			self.fileType = .PDF
		case "SD":
			self.fileType = .SD
		case "HD":
			self.fileType = .HD
		case "Sample Code":
			self.fileType = .SampleCode
		default:
			self.fileType = .PDF
		}
		
		super.init()
		
		self.remoteFileURL = aDecoder.decodeObjectForKey("remoteFileURL") as? NSURL
		let fileSize = Int(aDecoder.decodeInt64ForKey("fileSize"))
		if fileSize > 0 {
			self.fileSize = fileSize
		}
		self.shouldDownloadFile = aDecoder.decodeBoolForKey("shouldDownloadFile")
	}
	
	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(session, forKey: "session")
		aCoder.encodeObject(fileType.description, forKey: "fileType")
		if let remoteFileURL = self.remoteFileURL {
			aCoder.encodeObject(remoteFileURL, forKey: "remoteFileURL")
		}
		if let fileSize = self.fileSize {
			aCoder.encodeInt64(Int64(fileSize), forKey: "fileSize")
		}
		aCoder.encodeBool(shouldDownloadFile, forKey: "shouldDownloadFile")
	}

	// MARK:  File Helpers
	func fileExistsLocallyForFile() -> Bool {
        return isFileMarkedAsDownloaded
	}
    
    func forceCheckIfFileExists() {
        
        if let localFileURL = self.localFileURL {
            do {
                try localFileURL.checkResourceIsReachable()
                isFileMarkedAsDownloaded = true
                return
            }
            catch {
                //print(error)
            }
        }
        isFileMarkedAsDownloaded = false
    }
	
	func saveFileLocallyFrom(url: NSURL) {
		
		if isFileAlreadyDownloaded == false {
			// Copy the file over to the correct location
			if let localFileURL = self.localFileURL {
				do {
					try NSFileManager.defaultManager().moveItemAtURL(url, toURL: localFileURL)
                    isFileMarkedAsDownloaded = true
				}
				catch {
					print("File move/save error - \(error)")
				}
			}
		}
	}

	
	// MARK: - Directory Helpers
	class func wwdcDirectory () -> NSURL? {
        
        if Preferences.sharedPreferences.downloadFolderURL == nil {
            Preferences.sharedPreferences.populateFolderURL()
        }
        
        if let folderURL = Preferences.sharedPreferences.downloadFolderURL {
		
            let path = "WWDC"
		
            return createDirectoryIfNeeded(path, inDirectory: folderURL)
        }
        return nil
	}

	class func yearDirectory(year : WWDCYear) -> NSURL? {
		
		guard let wwdcDirectory = wwdcDirectory()  else { return nil }
		
		let yearpath = "\(year.description)"
		
		return createDirectoryIfNeeded(yearpath, inDirectory: wwdcDirectory)
	}
	
	
	class func videoDirectory (year : WWDCYear) -> NSURL? {
		
		guard let wwdcDirectory = yearDirectory(year)  else { return nil }
		
		let path = "Videos"
		
		return createDirectoryIfNeeded(path, inDirectory: wwdcDirectory)
	}
	
	class func codeDirectory (year : WWDCYear) -> NSURL? {
		
		guard let wwdcDirectory = yearDirectory(year)  else { return nil }
		
		let path = "Code Samples"
		
		return createDirectoryIfNeeded(path, inDirectory: wwdcDirectory)
	}
	
	class func pdfDirectory (year : WWDCYear) -> NSURL? {
		
		guard let wwdcDirectory = yearDirectory(year)  else { return nil }
		
		let path = "PDFs"
		
		return createDirectoryIfNeeded(path, inDirectory: wwdcDirectory)
	}
	
	
	// MARK: Helpers

	private class func createDirectoryIfNeeded(directory : String, inDirectory: NSURL) -> NSURL? {
		
		let url = inDirectory.URLByAppendingPathComponent(directory, isDirectory: true)
				
        do {
           try NSFileManager.defaultManager().createDirectoryAtURL(url, withIntermediateDirectories: true, attributes: nil)
            return url
        }
        catch {
            print(error)
        }
        return nil
	}

}
