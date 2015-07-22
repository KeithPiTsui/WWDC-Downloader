//
//  Searching.swift
//  WWDC
//
//  Created by David Roberts on 17/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation

class Searching {
    
	static let sharedManager = Searching()
	
    func countOfStringsFor(wwdcSession : WWDCSession, searchString: String) -> Int {
        
        if let rangeArray = rangeArrayFor(wwdcSession, searchString: searchString) {
            return rangeArray.count
        }
        else {
            return 0
        }
    }
    
    func rangeArrayFor(wwdcSession : WWDCSession, searchString: String) -> NSArray? {
        
        if let transcript = wwdcSession.fullTranscriptPrettyPrint {
            if searchTranscriptReference.indexForKey("\(wwdcSession.sessionYear)-\(wwdcSession.sessionID)-\(searchString)") == nil {
                
                let length = transcript.characters.count
                var range = NSMakeRange(0, length)
                
                let rangeArray = NSMutableArray()
                
                while(range.location != NSNotFound)
                {
                    range = (transcript as NSString).rangeOfString(searchString, options: NSStringCompareOptions.CaseInsensitiveSearch, range: range)
                    
                    if(range.location != NSNotFound)
                    {
                        rangeArray.addObject(NSValue(range: range))
                        
                        range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
                    }
                }
                
                searchTranscriptReference["\(wwdcSession.sessionYear)-\(wwdcSession.sessionID)-\(searchString)"] = rangeArray
                
                return rangeArray
            }
            else {
                if let rangeArray = searchTranscriptReference["\(wwdcSession.sessionYear)-\(wwdcSession.sessionID)-\(searchString)"] {
                    return rangeArray
                }
            }
        }
        return nil
    }
	
	func save() {
		
		archiveSearchData{ (success) -> Void in
			if !success {
				print("Failed to Archive Search Data")
			}
			else {
				print("Successfully Archived Search Data")
			}
		}

	}
	
	func deleteSearchHistory() -> Void {
		
		let path = pathForSearchFile()
		
		if NSFileManager.defaultManager().fileExistsAtPath(path) {
			
			do {
				try NSFileManager.defaultManager().removeItemAtPath(path)
			}
			catch {
				print(error)
			}
		}
	}
	
	// MARK: Private
	private var searchTranscriptReference : [NSString:NSArray] = [:]

	private init() {
		unArchiveSearchData { (success) -> Void in
			if !success {
				print("Failed to Unarchive Search Data")
			}
		}
	}

    private func archiveSearchData(completionSuccess:(success: Bool) -> Void) {
		
        let data = NSKeyedArchiver.archivedDataWithRootObject(searchTranscriptReference as NSDictionary)

        completionSuccess(success: data.writeToFile(pathForSearchFile(), atomically: true))
    }
    
    private func unArchiveSearchData(completionSuccess:(success: Bool) -> Void) {
        
        do {
            let data = try NSData(contentsOfFile: pathForSearchFile(), options: NSDataReadingOptions.DataReadingMappedIfSafe)
            
            if let unarchived = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [NSString:NSArray] {
                searchTranscriptReference = unarchived
                completionSuccess(success: true)
                return
            }
        }
        catch {
            print(error)
        }
        completionSuccess(success: false)
    }
	
    private func pathForSearchFile() -> String {
        
        let fileManager = NSFileManager.defaultManager()
        
        let folder = "~/Library/Application Support/WWDC Downloader/"
        let expanded = folder.stringByExpandingTildeInPath
        
        if fileManager.fileExistsAtPath(expanded) == false {
            do {
                try fileManager.createDirectoryAtPath(expanded, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                print(error)
            }
        }
        
        return expanded.stringByAppendingPathComponent("SearchArchive")
    }
}