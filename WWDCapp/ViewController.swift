//
//  ViewController.swift
//  WWDCapp
//
//  Created by David Roberts on 19/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSURLSessionDelegate, NSURLSessionDataDelegate {

	var allWWDCSessionsSet : Set<WWDCSession> = []

	private var downloadSessionInfo : DownloadSessionInfo?

    override func viewDidLoad() {
        super.viewDidLoad()
		
		downloadSessionInfo = DownloadSessionInfo(year: .WWDC2014, completionHandler: { (sessions) -> Void in
			
			print("ALL INFO DOWNLOADED")
			self.allWWDCSessionsSet = sessions
		})
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

