//
//  Archiving.swift
//  WWDC
//
//  Created by David Roberts on 09/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation

class Archiving {
	
	class func archiveDataForYear(year: WWDCYear, sessions:[WWDCSession], completionSuccess:(success: Bool) -> Void) {
		
		let data = NSKeyedArchiver.archivedDataWithRootObject(sessions as NSArray)
		
		completionSuccess(success: data.writeToFile(pathForArchiving(year), atomically: true))
	}
	
	class func unArchiveDataForYear(year: WWDCYear) -> [WWDCSession]? {
		
		do {
			let data = try NSData(contentsOfFile: pathForArchiving(year), options: NSDataReadingOptions.DataReadingMappedIfSafe)
			
			if let sessions = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [WWDCSession] {
				return sessions
			}
		}
		catch {
			print(error)
		}

		return nil
	}
	
	class func deleteDataForYear(year:WWDCYear) -> Void {
		
		let path = pathForArchiving(year)
		
		if NSFileManager.defaultManager().fileExistsAtPath(path) {
			
			do {
				try NSFileManager.defaultManager().removeItemAtPath(path)
			}
			catch {
				print(error)
			}
		}
	}
	
	class private func pathForArchiving(year: WWDCYear) -> String {
		
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
		
		let fileName = year.description
		return expanded.stringByAppendingPathComponent(fileName)
	}
}
