//
//  WWDCSession.swift
//  WWDC
//
//  Created by David Roberts on 15/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation

class TranscriptInfo : NSObject, NSCoding {
	
	let timeStamp : Double
	let caption : String

	init(tuple : (Double, String)) {
		self.timeStamp = tuple.0
		self.caption = tuple.1
	}
	
	required init(coder aDecoder: NSCoder) {
		self.timeStamp  = aDecoder.decodeDoubleForKey("timeStamp")
		self.caption = aDecoder.decodeObjectForKey("caption") as! String
	}
	
	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeDouble(self.timeStamp, forKey:"timeStamp")
		aCoder.encodeObject(self.caption, forKey: "caption")
	}
}


func ==(lhs: WWDCSession, rhs: WWDCSession)-> Bool {
    return lhs.title == rhs.title && lhs.sessionID == rhs.sessionID
}

@objc class WWDCSession : NSObject, NSCoding {
	
    let title : String
    let sessionID : String
    let sessionYear : WWDCYear

    var isInfoFetchComplete = false
	
    var hdFile : FileInfo?
    var sdFile : FileInfo?
    var pdfFile : FileInfo?

    var sampleCodeArray : [FileInfo]
	
	// ASCIIwwdc fetchedInfo
	var sessionDescription : String?
	var fullTranscriptPrettyPrint : String? {	// Full Print Out
		get {
			if let transcript = self.transcript {
				
				var fullTranscript : String = ""
				
				for transcriptInfo in transcript {
					fullTranscript = fullTranscript+((String(transcriptInfo.timeStamp))+"  "+transcriptInfo.caption+"\n\n")
				}
				
				if fullTranscript.isEmpty {
					return nil
				}
				else {
					return fullTranscript
				}
			}
			else {
				return nil
			}
		}
	}
	
	var transcript : [TranscriptInfo]?
	
	init(sessionID: String, title: String, year: WWDCYear) {
        
        self.title = title
        self.sessionID = sessionID
        self.sessionYear = year

        sampleCodeArray = []
	}
	
	required init(coder aDecoder: NSCoder) {
		self.title  = aDecoder.decodeObjectForKey("title") as! String
		self.sessionID  = aDecoder.decodeObjectForKey("sessionID") as! String
		let yearString = aDecoder.decodeObjectForKey("sessionYear") as! String
		switch yearString {
		case "2015":
			self.sessionYear = .WWDC2015
		case "2014":
			self.sessionYear = .WWDC2014
		case "2013":
			self.sessionYear = .WWDC2013
		default:
			self.sessionYear = .WWDC2015
		}
		self.sampleCodeArray = aDecoder.decodeObjectForKey("sampleCodeArray") as! [FileInfo]
		
		super.init()

		self.isInfoFetchComplete = aDecoder.decodeBoolForKey("isInfoFetchComplete")
		self.hdFile = aDecoder.decodeObjectForKey("hdFile") as? FileInfo
		self.sdFile = aDecoder.decodeObjectForKey("sdFile") as? FileInfo
		self.pdfFile = aDecoder.decodeObjectForKey("pdfFile") as? FileInfo
		self.sessionDescription  = aDecoder.decodeObjectForKey("sessionDescription") as? String
		if let boxed = aDecoder.decodeObjectForKey("transcript") as? [TranscriptInfo] {
			self.transcript = boxed
		}
		
	}
	
	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(title, forKey: "title")
		aCoder.encodeObject(sessionID, forKey: "sessionID")
		aCoder.encodeObject(sessionYear.description, forKey: "sessionYear")
		aCoder.encodeObject(sampleCodeArray, forKey: "sampleCodeArray")
		aCoder.encodeBool(isInfoFetchComplete, forKey: "isInfoFetchComplete")
		if let hdFile = self.hdFile {
			aCoder.encodeObject(hdFile, forKey: "hdFile")
		}
		if let sdFile = self.sdFile {
			aCoder.encodeObject(sdFile, forKey: "sdFile")
		}
		if let pdfFile = self.pdfFile {
			aCoder.encodeObject(pdfFile, forKey: "pdfFile")
		}
		if let sessionDescription = self.sessionDescription {
			aCoder.encodeObject(sessionDescription, forKey: "sessionDescription")
		}
		if let transcript = self.transcript {
			aCoder.encodeObject(transcript, forKey: "transcript")
		}
	}
}
