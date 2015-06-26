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
    
    init(sessionID: String, title: String, year: WWDCYear) {
        
        self.title = title
        self.sessionID = sessionID
        self.sessionYear = year

        sampleCodeArray = []
	}
}
