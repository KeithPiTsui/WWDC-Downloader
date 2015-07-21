//
//  UserInfo.swift
//  WWDC
//
//  Created by David Roberts on 21/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation

class UserSessionInfo : NSObject, NSCoding {
	
	let sessionID : String
	var markAsFavorite: Bool = false
    var currentProgress: Float = 0
	
	init(sessionID: String) {
		self.sessionID = sessionID
		super.init()
	}
	
	// MARK: - Encoding
	required init(coder aDecoder: NSCoder) {
		
		self.sessionID  = aDecoder.decodeObjectForKey("sessionID") as! String
		self.markAsFavorite = aDecoder.decodeBoolForKey("markAsFavorite")
		self.currentProgress = aDecoder.decodeFloatForKey("currentProgress") as Float

		super.init()
	}
	
	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(sessionID, forKey: "sessionID")
		aCoder.encodeBool(markAsFavorite, forKey: "markAsFavorite")
		aCoder.encodeFloat(currentProgress, forKey: "currentProgress")
	}
}


class UserInfo {
	
	static let sharedManager = UserInfo()
	
	var userInfoDictionary : [String: UserSessionInfo] = [:]
    
    func userInfo(wwdcSession: WWDCSession) -> UserSessionInfo? {
        
        if let userInfo = userInfoDictionary["\(wwdcSession.sessionYear)-\(wwdcSession.sessionID)"] {
            return userInfo
        }
        else {
            let userInfo = UserSessionInfo(sessionID: "\(wwdcSession.sessionYear)-\(wwdcSession.sessionID)")
            userInfoDictionary["\(wwdcSession.sessionYear)-\(wwdcSession.sessionID)"] = userInfo
            return userInfo
        }
    }
    
	private init() {
		
		unArchiveUserInfo { (success) -> Void in
			if !success {
				print("Failed to Unarchive User Info")
			}
		}
	}
	
	func archiveUserInfo(completionSuccess:(success: Bool) -> Void) {
		
		let data = NSKeyedArchiver.archivedDataWithRootObject(userInfoDictionary as NSDictionary)
		
		completionSuccess(success: data.writeToFile(pathForUserInfo(), atomically: true))
	}
	
	private func unArchiveUserInfo(completionSuccess:(success: Bool) -> Void) {
		
		do {
			let data = try NSData(contentsOfFile: pathForUserInfo(), options: NSDataReadingOptions.DataReadingMappedIfSafe)
			
			if let userInfo = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String:UserSessionInfo] {
				userInfoDictionary = userInfo
				completionSuccess(success: true)
				return
			}
		}
		catch {
			print(error)
		}
		
		completionSuccess(success: false)
	}
	
	func delete() -> Void {
		
		let path = pathForUserInfo()
		
		if NSFileManager.defaultManager().fileExistsAtPath(path) {
			
			do {
				try NSFileManager.defaultManager().removeItemAtPath(path)
			}
			catch {
				print(error)
			}
		}
	}
	
	private func pathForUserInfo() -> String {
		
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
		return expanded.stringByAppendingPathComponent("UserInfo")
	}
}
