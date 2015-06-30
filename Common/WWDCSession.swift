//
//  WWDCSession.swift
//  WWDC
//
//  Created by David Roberts on 15/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation

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
	
	// ASCIIwwdc fetchedInfo
	var sesssionDescription : String?
	var fullTranscriptPrettyPrint : String? {	// Full Print Out
		get {
			if let transcript = self.transcript {
				
				var fullTranscript : String = ""
				
				for (_, textToDisplay) in transcript {
					fullTranscript = fullTranscript+(textToDisplay+"\n\n")
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
	
	var transcript : [(Double , String)]?	// (TimeStamp, Annotation)
    
    init(sessionID: String, title: String, year: WWDCYear) {
        
        self.title = title
        self.sessionID = sessionID
        self.sessionYear = year

        sampleCodeArray = []
	}
}
