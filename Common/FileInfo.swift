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
	
	static let allValues = [WWDC2015, WWDC2014, WWDC2013]
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
				guard let directory = FileInfo.sdVideoDirectory(year), let filename = self.fileName  else { return nil }
                return directory.URLByAppendingPathComponent(filename.sanitizeFileNameString())
			case .HD:
				guard let directory = FileInfo.hdVideoDirectory(year), let filename = self.fileName  else { return nil }
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
									return true
								}
							}
						}
					}
					catch {
						print("File Size Compare error - \(error)")
					}
				}
				forceCheckIfFileExists()
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
	}

	// MARK:  File Helpers
	func fileExistsLocallyForFile() -> Bool {
        return isFileMarkedAsDownloaded
	}
    
    func forceCheckIfFileExists() {
        
        if let localFileURLString = self.localFileURL?.path {
            isFileMarkedAsDownloaded = NSFileManager.defaultManager().fileExistsAtPath(localFileURLString)
            return
        }
        isFileMarkedAsDownloaded = false
    }
	
	func saveFileLocallyFrom(url: NSURL) {
		
		if isFileAlreadyDownloaded == false {
			// Copy the file over to the correct location
			if let localFileURL = self.localFileURL {
                
                let directory : NSURL?
                
                switch (fileType) {
                case .PDF:
                    directory = FileInfo.pdfDirectory(year)
                case .SD:
                    directory = FileInfo.sdVideoDirectory(year)
                case .HD:
                   directory = FileInfo.hdVideoDirectory(year)
                case .SampleCode:
                    directory = FileInfo.codeDirectory(year)
                }
                
                guard let fileDirectory = directory else { return }
                
                do {
                    try NSFileManager.defaultManager().createDirectoryAtURL(fileDirectory, withIntermediateDirectories: true, attributes: nil)
                    
                    do {
                        try NSFileManager.defaultManager().moveItemAtURL(url, toURL: localFileURL)
                        isFileMarkedAsDownloaded = true
                    }
                    catch let moveError as NSError {
                        print("File move/save error - \(moveError)")
                    }
                }
                catch let createError as NSError {
                    print("Create Directory Error -  \(createError)")
                }
            }
		}
	}

	
	// MARK: - Directory Helpers
	class func wwdcDirectory () -> NSURL? {
        
        if Preferences.sharedPreferences.downloadFolderURL == nil {
            Preferences.sharedPreferences.populateFolderURL()
        }
        
        if let directory = Preferences.sharedPreferences.downloadFolderURL {
		
            let path = "WWDC"
		
            return directory.URLByAppendingPathComponent(path, isDirectory: true)
        }
        return nil
	}

	class func yearDirectory(year : WWDCYear) -> NSURL? {
		
		guard let directory = wwdcDirectory()  else { return nil }
		
		let path = "\(year.description)"
		
        return directory.URLByAppendingPathComponent(path, isDirectory: true)
	}
	
	
	class func sdVideoDirectory (year : WWDCYear) -> NSURL? {
		
		guard let directory = yearDirectory(year)  else { return nil }
		
		let path = "Videos"
		
		let videos = directory.URLByAppendingPathComponent(path, isDirectory: true)
		
        return videos.URLByAppendingPathComponent("SD", isDirectory: true)
	}
	
	class func hdVideoDirectory (year : WWDCYear) -> NSURL? {
		
		guard let directory = yearDirectory(year)  else { return nil }
		
		let path = "Videos"
		
		let videos = directory.URLByAppendingPathComponent(path, isDirectory: true)
		
		return videos.URLByAppendingPathComponent("HD", isDirectory: true)	}
	
	
	class func codeDirectory (year : WWDCYear) -> NSURL? {
		
		guard let directory = yearDirectory(year)  else { return nil }
		
		let path = "Code Samples"
		
        return directory.URLByAppendingPathComponent(path, isDirectory: true)
	}
	
	class func pdfDirectory (year : WWDCYear) -> NSURL? {
		
		guard let directory = yearDirectory(year)  else { return nil }
		
		let path = "PDFs"
		
		return directory.URLByAppendingPathComponent(path, isDirectory: true)
	}
}
