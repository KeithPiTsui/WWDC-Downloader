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
}
