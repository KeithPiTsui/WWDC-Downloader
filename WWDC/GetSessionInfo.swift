//
//  GetSessionInfo.swift
//  WWDC
//
//  Created by David Roberts on 17/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation

class GetSessionInfo :NSObject {
    
    var allSessionsSet : Set<WWDCSession> = []
    
    var wwdcSessionWithoutInfoSet : Set <WWDCSession> = []
    
    private var downloads : [NSURLSessionDownloadTask: FileInfo] = [:]
    
    private var startPageDownloader : DownloadStartPageOperation?

    func fetchSessionInfo (year :WWDCYear, completionHandler: (sessions: Set<WWDCSession>) -> Void) {
        
        startPageDownloader = DownloadStartPageOperation(year: year, completionHandler: { [unowned self] (sessions) -> Void in
            
                let downloadSessionInfoGroup = dispatch_group_create();

                for wwdcSession in sessions {
                    
                    dispatch_group_enter(downloadSessionInfoGroup);

                    wwdcSession.fetchThisSessionInfo { [unowned self] success in
                        if success {
                            print("Completed Info for \(wwdcSession.title)")
                        }
                        else {
                            print("Failed Info for \(wwdcSession.title)")
                            self.wwdcSessionWithoutInfoSet.insert(wwdcSession)
                        }
                        
                        dispatch_group_leave(downloadSessionInfoGroup)
                    }
                }
            
                dispatch_group_notify(downloadSessionInfoGroup,dispatch_get_main_queue(),{ [unowned self] in
                    
                    self.allSessionsSet = sessions
                    print("ALL INFO DOWNLOADED")
                    completionHandler(sessions: self.allSessionsSet)
                })
            })
    }
}
