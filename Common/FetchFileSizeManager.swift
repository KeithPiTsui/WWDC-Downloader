//
//  FetchFileSize.swift
//  WWDC
//
//  Created by David Roberts on 29/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation

typealias HeaderCompletionHandler = ((success:Bool, errorCode:Int?) -> Void)

class FetchFileSizeManager : NSObject, NSURLSessionDownloadDelegate {
    
    private var headerSessionManager : NSURLSession?
    private var downloadHandlers: [Int : (FileInfo,HeaderCompletionHandler)] = [:]			// Int is taskIdentifier of NSURLSessionTask

    class var sharedManager: FetchFileSizeManager {
        struct Singleton {
            static let instance = FetchFileSizeManager()
        }
        return Singleton.instance
    }
    
    private override init() {
        
        super.init()
        
        let headerconfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        headerconfig.HTTPMaximumConnectionsPerHost = 3
        headerSessionManager = NSURLSession(configuration: headerconfig, delegate: self, delegateQueue: nil)
    }

    func fetchFileSize(file : FileInfo, completion: (success: Bool, errorCode:Int?) -> Void) {
        
        guard let remotefileURL = file.remoteFileURL else { completion(success: false, errorCode: 400); return }
        
        let request = NSMutableURLRequest(URL: remotefileURL)
        request.HTTPMethod = "HEAD"
        
        let fileSizeTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { [unowned self] (data, response, error) -> Void in
            if let hresponse = response as? NSHTTPURLResponse {
                if let dictionary = hresponse.allHeaderFields as? Dictionary<String,String> {
                    if hresponse.statusCode == 200 {
                        if let size = dictionary["Content-Length"] {
                            file.fileSize = Int(size)
                            completion(success: true, errorCode:nil)
                            return
                        }
                    }
                    else {
                        if let task = self.headerSessionManager?.downloadTaskWithRequest(NSURLRequest(URL: remotefileURL)) {       // Couldnt get with HEAD so download part of file and use that response header!
                            self.downloadHandlers[task.taskIdentifier] = (file,completion)
                            task.resume()
                        }
                    }
                }
            }
        }
        fileSizeTask?.resume()
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)  {

        if session == headerSessionManager {
            
            if let (file,completionHandler) = downloadHandlers[downloadTask.taskIdentifier] {
                
                downloadHandlers[downloadTask.taskIdentifier] = nil
                
                if let response = downloadTask.response {
                    
                    downloadTask.cancel()
                    
                    if let hresponse = response as? NSHTTPURLResponse {
                        if let dictionary = hresponse.allHeaderFields as? Dictionary<String,String> {
                            if hresponse.statusCode == 200 {
                                if let size = dictionary["Content-Length"] {
                                    file.fileSize = Int(size)
                                    completionHandler(success: true, errorCode: nil)
                                    return
                                }
                            }
                            else {
                                print("Code - \(hresponse.statusCode) - Bad Header Response - \(dictionary)")
                                completionHandler(success: false, errorCode:Int(hresponse.statusCode))
                            }
                        }
                    }
                }
            }
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        
        if session == headerSessionManager {
            downloadHandlers[task.taskIdentifier] = nil
        }
    }

}