//
//  WWDCSession.swift
//  WWDC
//
//  Created by David Roberts on 15/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation

enum WWDCYear {
    case WWDC2015, WWDC2014, WWDC2013
}

func ==(lhs: WWDCSession, rhs: WWDCSession)-> Bool {
    return lhs.title == rhs.title && lhs.sessionID == rhs.sessionID
}

class WWDCSession : NSObject {
    
    let title : String
    let sessionID : String
    let sessionYear : WWDCYear

    var isInfoFetchComplete = false
	
    var hdFile : FileInfo?
    var sdFile : FileInfo?
    var pdfFile : FileInfo?

    var sampleCodeArray : [FileInfo]
    
    init(sessionID : String, title:String , year : WWDCYear) {
        
        self.title = title
        self.sessionID = sessionID
        self.sessionYear = year

        sampleCodeArray = []
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
		
		guard let wwdcDirectory = yearDirectory(sessionYear)  else { return nil }
		
		let path = "/Videos"
		
		return createDirectoryIfNeeded(path, inDirectory: wwdcDirectory)
	}
	
	func codeDirectory () -> String? {
		
		guard let wwdcDirectory = yearDirectory(sessionYear)  else { return nil }
		
		let path = "/Code Samples"
		
		return createDirectoryIfNeeded(path, inDirectory: wwdcDirectory)
	}
	
	func pdfDirectory () -> String? {
		
		guard let wwdcDirectory = yearDirectory(sessionYear)  else { return nil }
		
		let path = "/PDFs"
		
		return createDirectoryIfNeeded(path, inDirectory: wwdcDirectory)
	}
	
	class func sanitizeFileNameString(filename : String) -> String {
		let characters = NSCharacterSet(charactersInString: "/\\?%*|\"<>:")
		let components = filename.componentsSeparatedByCharactersInSet(characters) as NSArray
		return components.componentsJoinedByString("")
		
	}
	
	// MARK: Helper
	private func createDirectoryIfNeeded(directory : String, inDirectory: String) -> String? {
		
		let path = inDirectory.stringByAppendingPathComponent(directory)
		
		//var isDir = ObjCBool(true)
		
		if !NSFileManager.defaultManager().fileExistsAtPath(path) {
			do {
				try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: false, attributes: nil)
			}
			catch {
				print(error)
			}
		}
		return path
	}


	
}
