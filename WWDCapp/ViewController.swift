//
//  ViewController.swift
//  WWDCapp
//
//  Created by David Roberts on 19/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSURLSessionDelegate, NSURLSessionDataDelegate {

    var sessionFetch : GetSessionInfo?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sessionFetch = GetSessionInfo()

        if let sessionFetch = sessionFetch {
            
            sessionFetch.fetchSessionInfo(.WWDC2015) { [unowned self] (sessions) -> Void in
                
                print ("Count of Sessions with Info - \(sessions.count)")
                
                self.downloadCodeSamples(sessions)
            }
        }
    }
    
    func  downloadPDF(forSessions : Set<WWDCSession> ) {
        
        for wwdcSession in forSessions {
            
            if let file = wwdcSession.pdfFile {
                
                let progressWrapper = ProgressWrapper(handler: { (progress) -> Void in
                    
                })
                
                let completionWrapper = SimpleCompletionWrapper(handler: { (success) -> Void in
                    
                    if success {
                        print("Completion Wrapper SUCCESS - \(file.displayName!)")
                    }
                    else {
                        print("Completion Wrapper Fail - \(file.displayName!)")
                    }
                })
                
                DownloadFileManager.sharedManager.downloadFile(file, progressWrapper: progressWrapper, completionWrapper: completionWrapper)
            }
        }
    }
    
    func  downloadCodeSamples(forSessions : Set<WWDCSession> ) {
        
        for wwdcSession in forSessions {
            
           for file in wwdcSession.sampleCodeArray {
                
                let progressWrapper = ProgressWrapper(handler: { (progress) -> Void in
                    
                })
                
                let completionWrapper = SimpleCompletionWrapper(handler: { (success) -> Void in
                    
                    if success {
                        print("Completion Wrapper SUCCESS - \(file.displayName!)")
                    }
                    else {
                        print("Completion Wrapper Fail - \(file.displayName!)")
                    }
                })
                
                DownloadFileManager.sharedManager.downloadFile(file, progressWrapper: progressWrapper, completionWrapper: completionWrapper)
            }
        }
    }

    
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

