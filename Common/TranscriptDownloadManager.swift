//
//  TranscriptDownloadManager.swift
//  WWDC
//
//  Created by David Roberts on 29/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation

class TranscriptDownloadManager : NSObject, NSURLSessionDataDelegate {
    
    private var sessionManager : NSURLSession?
    private var downloadHandlers: [Int : (WWDCSession, SimpleCompletionHandler)] = [:]			// Int is taskIdentifier of NSURLSessionTask
    
    class var sharedManager: TranscriptDownloadManager {
        struct Singleton {
            static let instance = TranscriptDownloadManager()
        }
        return Singleton.instance
    }
    
    private override init() {
        
        super.init()
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.HTTPMaximumConnectionsPerHost = 3
        sessionManager = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func fetchTranscript(session : WWDCSession, completion: (success: Bool, errorCode:Int?) -> Void) {
        
        let remoteFileURLString = "http://asciiwwdc.com/"+String(session.sessionYear.description)+"/sessions/"+session.sessionID
        
        if let url = NSURL(string: remoteFileURLString) {
            
            let request = NSMutableURLRequest(URL: url)
            
            let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { [unowned self] (data, response, error) -> Void in
                if let hresponse = response as? NSHTTPURLResponse {
                    if hresponse.statusCode == 200 {
                        if let data = data {
                            do {
                                let jsonObject = try NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.AllowFragments)
                                print(jsonObject)
                            }
                            catch {
                               print("JSON Error - \(error)")
                            }
                        }
                        else {
                            completion(success: false, errorCode: 404)
                        }
                    }
                    else {
                        completion(success: false, errorCode: error?.code)
                    }
                }
            }
            task?.resume()
        }
    }

}