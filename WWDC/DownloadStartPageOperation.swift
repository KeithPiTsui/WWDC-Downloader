//
//  DownloadStartPageOperation.swift
//  WWDC
//
//  Created by David Roberts on 15/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

let developerBaseURL = "https://developer.apple.com"

let videos2015baseURL = "/videos/wwdc/2015/"
let videos2014baseURL = "/videos/wwdc/2014/"

import Foundation

class DownloadStartPageOperation: NSObject {
    
    // MARK: Initialization
    
    private let year : WWDCYear
    
    private var wwdcStartPageCompletionHandler : (sessions: Set<WWDCSession>) -> Void
    
    init(year: WWDCYear, completionHandler: (sessions: Set<WWDCSession>) -> Void) {
        
        self.year = year
        self.wwdcStartPageCompletionHandler = completionHandler
        
        super.init()
        
        print("Download Start Page for \(year)")
        
        var videoURLString : NSURL?
        
        switch year {
            case .WWDC2015:
               videoURLString = NSURL(string:developerBaseURL+videos2015baseURL)
            
            case .WWDC2014:
                videoURLString = NSURL(string:developerBaseURL+videos2014baseURL)
        }
        
        if let videoURLString = videoURLString {

            let task = NSURLSession.sharedSession().dataTaskWithURL(videoURLString) { url, response, error in
                self.downloadFinished(url, response: response as? NSHTTPURLResponse, error: error)
            }
            
            if let task = task {
                task.resume()
            }
        }
        
    }
    
    private func downloadFinished(data: NSData?, response: NSHTTPURLResponse?, error: NSError?) {
        
        if let wwdcMainHTMLdata = data  {
            
            // Convert Data to TFHpple Elements
            let doc = TFHpple(HTMLData: wwdcMainHTMLdata)
            
            switch year {
                case .WWDC2015:
                    parse2015Doc(doc)
                case .WWDC2014:
                    parse2014Doc(doc)
            }
            
        }
        else if let error = error {
            print("Start Page Error - \(error)")
        }
        else {
            // Do nothing, and the operation will automatically finish.
        }
    }
    
    private func parse2015Doc(doc : TFHpple) {
    
        // find sections
        let sections : [TFHppleElement] = doc.searchWithXPathQuery("//*[@class='inner_v_section']") as! [TFHppleElement]
        
        // Create Set of WWDCSession items
        var allSessionInfo = Set<WWDCSession>()
        
        // find and amalgamate links to sessions
        for section in sections {
            
            let sectionItems = section.searchWithXPathQuery("//a") as! [TFHppleElement]
            
            for link in sectionItems {
                
                if let sessionIDLink = link.attributes["href"] as? String, let sessionTitle = link.content {
                    
                    let sessionID = sessionIDLink.stringByReplacingOccurrencesOfString("?id=", withString: "")
                    
                    allSessionInfo.insert(WWDCSession(sessionID: sessionID, title: sessionTitle, year: .WWDC2015))
                }
            }
        }
        
        print("Finished Parsing \(year)")
        
        self.wwdcStartPageCompletionHandler(sessions: allSessionInfo)
    }
    
    private func parse2014Doc(doc : TFHpple) {
        
        // find sections
        let sessionSections : [TFHppleElement] = doc.searchWithXPathQuery("//*[@class='session']") as! [TFHppleElement]
        
        // Create Set of WWDCSession items
        var allSessionInfo = Set<WWDCSession>()
        
        for section in sessionSections {
            
            if let sessionID = section.attributes["id"] as? String {

                let sectionItems = section.searchWithXPathQuery("//*[@class='title']") as! [TFHppleElement]
                let title = sectionItems[0].content

                let wwdcSession = WWDCSession(sessionID: sessionID, title: title, year: .WWDC2014)
            
                let aItems = section.searchWithXPathQuery("//*[@class='description active']") as! [TFHppleElement]
                
                for anItem in aItems {
                    
                    let links = anItem.searchWithXPathQuery("//a") as! [TFHppleElement]
                    
                    for link in links {
                        if link.content == "HD" {
                            if let hdDownloadLink = link.attributes["href"] as? String {
                                let file = FileInfo()
                                file.remoteFileURL = NSURL(string: hdDownloadLink)
                                file.fileName = sessionID+"-"+title+"-HD.mp4"
                                file.displayName = sessionID+"-"+title+" HD Video"
                                guard let directory = wwdcSession.videoDirectory(), let filename = file.fileName  else { return }
                                file.localFileURL = NSURL(fileURLWithPath: directory.stringByAppendingPathComponent(WWDCSession.sanitizeFileNameString( filename)))
                                wwdcSession.hdFile = file
                            }
                        }
                        
                        if link.content == "SD" {
                            if let sdDownloadLink = link.attributes["href"] as? String {
                                let file = FileInfo()
                                file.remoteFileURL = NSURL(string: sdDownloadLink)
                                file.fileName = sessionID+"-"+title+"-SD.mp4"
                                file.displayName = sessionID+"-"+title+" SD Video"
                                guard let directory = wwdcSession.videoDirectory(), let filename = file.fileName  else { return }
                                file.localFileURL = NSURL(fileURLWithPath: directory.stringByAppendingPathComponent(WWDCSession.sanitizeFileNameString( filename)))
                                wwdcSession.sdFile = file
                            }
                        }
                        
                        if link.content == "PDF" {
                            if let pdfDownloadLink = link.attributes["href"] as? String {
                                let file = FileInfo()
                                file.remoteFileURL = NSURL(string: pdfDownloadLink)
                                file.fileName = sessionID+"-"+title+".pdf"
                                file.displayName = sessionID+"-"+title+" PDF"
                                guard let directory = wwdcSession.pdfDirectory(), let filename = file.fileName  else { return }
                                file.localFileURL = NSURL(fileURLWithPath: directory.stringByAppendingPathComponent(WWDCSession.sanitizeFileNameString( filename)))
                                wwdcSession.pdfFile = file
                            }
                        }
                    }
                }
                
                allSessionInfo.insert(wwdcSession)
            }
        }
        
        print("Finished Parsing \(year)")

        self.wwdcStartPageCompletionHandler(sessions: allSessionInfo)
    }
}
