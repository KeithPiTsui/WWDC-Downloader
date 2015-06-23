//
//  ViewController.swift
//  WWDC
//
//  Created by David Roberts on 13/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var sessionFetch : GetSessionInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        sessionFetch = GetSessionInfo()
        
        if let sessionFetch = sessionFetch {
            
            sessionFetch.fetchSessionInfo(.WWDC2014) { [unowned self] (sessions) -> Void in
                                
                print ("Count of Sessions with Info - \(sessions.count)")
                
                self.downloadPDF(sessions)
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

