//
//  DownloadFileManager.swift
//  WWDC
//
//  Created by David Roberts on 17/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation

let logFileManager = false

typealias ProgressHandler = ((progress: Float) -> Void)
typealias SimpleCompletionHandler = ((success: Bool) -> Void)

typealias HeaderCompletionHandler = ((fileSize:Int?, errorCode:Int?) -> Void)

@objc class DownloadFileManager : NSObject, NSURLSessionDownloadDelegate {
	
	// MARK: - Instance Variables
	
	// File Download
	private var sessionManager : NSURLSession?
	private var backgroundHandlersForFiles: [FileInfo : CallbackWrapper] = [:]
	private var backgroundRequestsForFiles: [Int : FileInfo] = [:]				// Int is taskIdentifier of NSURLSessionTask
	
	// Header Fetch
	private var headerSessionManager : NSURLSession?
	private var headerRequests: [Int : HeaderCompletionHandler] = [:]			// Int is taskIdentifier of NSURLSessionTask
	
	
  	// MARK: - Singleton Status
	class var sharedManager: DownloadFileManager {
		struct Singleton {
			static let instance = DownloadFileManager()
		}
		return Singleton.instance
	}
	
	// MARK: - Object Lifecycle Methods
	// Singleton so prevent init outside of class by marking private
	private override init() {
        
        super.init()
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.HTTPMaximumConnectionsPerHost = 3
        sessionManager = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
		
		let headerconfig = NSURLSessionConfiguration.defaultSessionConfiguration()
		headerconfig.HTTPMaximumConnectionsPerHost = 3
		headerSessionManager = NSURLSession(configuration: headerconfig, delegate: self, delegateQueue: nil)
	}
	
    // MARK: - Download File Transfer
    func downloadFile(file: FileInfo, progressWrapper: ProgressWrapper?, completionWrapper:SimpleCompletionWrapper?) {

        // Check if it exists locally
		if file.isFileAlreadyDownloaded {
			if let completionWrapper = completionWrapper {
				completionWrapper.execute(true)
			}
			return
		}
		
        //  Handle Callbacks
        if let backgroundDownloadHandler = backgroundHandlersForFiles[file] {
            backgroundDownloadHandler.addProgressWrapper(progressWrapper)
            backgroundDownloadHandler.addCompletionWrapper(completionWrapper)
        }
        else {
            let callbackWrapper = CallbackWrapper(file: file)
            callbackWrapper.addProgressWrapper(progressWrapper)
            callbackWrapper.addCompletionWrapper(completionWrapper)
            backgroundHandlersForFiles[file] = callbackWrapper
            
            startDownload(file, callbacks: callbackWrapper)
        }
    }
	
	func stopDownloads() {
		
		if let sessionManager = sessionManager {
			
			sessionManager.getAllTasksWithCompletionHandler({ [unowned self] (tasks) -> Void in
			
				for task in tasks {
					
					if let file = self.backgroundRequestsForFiles[task.taskIdentifier] {
						
						task.cancel()
						file.downloadProgress = 0
					}
				}
			})
		}
	}
	
	func fetchHeader(url : NSURL, completionHandler:HeaderCompletionHandler) {
		
		let downloadTask = headerSessionManager?.downloadTaskWithRequest(NSURLRequest(URL: url))
		
		if let task = downloadTask {
			headerRequests[task.taskIdentifier] = completionHandler
			task.resume()
		}
	}

	
	// MARK: -
    private func startDownload(file: FileInfo, callbacks:CallbackWrapper?) {
        
        if logFileManager { print("Queue Download of \(file.displayName!)") }
        
        if let url = file.remoteFileURL {
            let downloadTask = sessionManager?.downloadTaskWithRequest(NSURLRequest(URL: url))
            
            if let task = downloadTask {
                backgroundRequestsForFiles[task.taskIdentifier] = file
                task.resume()
            }
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)  {
		
		if session == sessionManager {
			var progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
			if progress > 1 {
				progress = 1;
			}
			
			if let fileInfo = backgroundRequestsForFiles[downloadTask.taskIdentifier] {
				
				fileInfo.downloadProgress = progress
				
				if let callback = backgroundHandlersForFiles[fileInfo] {
					callback.notifyProgress(progress, file: fileInfo)
				}
			}
		}
		if session == headerSessionManager {
			
			if let completionHandler = headerRequests[downloadTask.taskIdentifier] {
				
				headerRequests[downloadTask.taskIdentifier] = nil
				
				if let response = downloadTask.response {
					
					downloadTask.cancel()

					if let hresponse = response as? NSHTTPURLResponse {
						if let dictionary = hresponse.allHeaderFields as? Dictionary<String,String> {
							if hresponse.statusCode == 200 {
								if let size = dictionary["Content-Length"] {
									completionHandler(fileSize: Int(size), errorCode:nil)
									return
								}
							}
							else {
								print("Code - \(hresponse.statusCode) - Bad Header Response - \(dictionary)")
								completionHandler(fileSize: nil, errorCode:Int(hresponse.statusCode))
							}
						}
					}
				}
			}
		}
    }
	
	func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
		
		if session == headerSessionManager {
			print("Redirected to \(request)")
		}
		
	}
	
	
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
		
		if session == sessionManager {
			if let fileInfo = backgroundRequestsForFiles[downloadTask.taskIdentifier] {
				fileInfo.saveFileLocallyFrom(location)
			}
		}
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
		
		if session == sessionManager {
			if  let downloadTask = task as? NSURLSessionDownloadTask {
				if let fileInfo = backgroundRequestsForFiles[downloadTask.taskIdentifier] {
					if let callback = backgroundHandlersForFiles[fileInfo] {
						
						if let error = error {
							callback.notifyCompletion(false, file: fileInfo, error: error)
						}
						else {
							callback.notifyCompletion(true, file: fileInfo, error: nil)
						}
						
						self.backgroundHandlersForFiles[fileInfo] = nil
						self.backgroundRequestsForFiles[downloadTask.taskIdentifier] = nil
					}
				}
			}
		}
//		if session == headerSessionManager {
//			
//			session.getAllTasksWithCompletionHandler({ [unowned self] (tasks) -> Void in
//				
//				for task in tasks {
//					
//					if let completionHandler = self.headerRequests[task.taskIdentifier] {
//						
//						self.headerRequests[task.taskIdentifier] = nil
//						
//						if let error = error {
//							print("Bad Header Completion - \(error)")
//						}
//						
//						completionHandler(fileSize: nil, errorCode:nil)
//					}
//				}
//			})
//		}
    }


	// MARK: - CallbackWrapper
	private class CallbackWrapper {
		
		// MARK: Instance Variables
		
		let file: FileInfo
		var progressWrappers: [ProgressWrapper] = []
		var completionWrappers: [SimpleCompletionWrapper] = []
		var currentProgress: Float = 0
		
		// MARK: - Object Lifecycle Methods
		
		init(file: FileInfo) {
			self.file = file
		}
		
		// MARK: - Helper Methods
		
		func addProgressWrapper(wrapper: ProgressWrapper?) {
			if let wrapper = wrapper {
				progressWrappers.append(wrapper)
			}
		}

		func addCompletionWrapper(wrapper: SimpleCompletionWrapper?) {
			if let wrapper = wrapper {
				completionWrappers.append(wrapper)
			}
		}
		
        func notifyProgress(progress: Float, file : FileInfo?) {
            if let file = file {
                if logFileManager { print(" file DOWNLOAD progress: \(file.displayName!) - \(progress)") }
            }
           
			var wrappersToRemove: [ProgressWrapper] = []
			for wrapper in progressWrappers {
				if wrapper.execute(progress) == false {
					wrappersToRemove.append(wrapper)
				}
			}
			// Remove any now invalid wrappers
			for invalidWrapper in wrappersToRemove {
				if let index = progressWrappers.indexOf(invalidWrapper) {
					progressWrappers.removeAtIndex(index)
				}
			}
		}
		
        func notifyCompletion(success: Bool, file: FileInfo?, error: NSError?) {
            
            if (success) {
                 if let file = file {
                    if logFileManager { print(" file transfer complete! \(file.displayName!)") }
                }
            }
            else {
                if let file = file {
                    if logFileManager { print(" file transfer error! - \(file.displayName!) - \(error)") }
                }
            }
            
			var wrappersToRemove: [SimpleCompletionWrapper] = []
			for wrapper in completionWrappers {
				if wrapper.execute(success) == false {
					wrappersToRemove.append(wrapper)
				}
			}
			// Remove any now invalid wrappers
			for invalidWrapper in wrappersToRemove {
				if let index = completionWrappers.indexOf(invalidWrapper) {
					completionWrappers.removeAtIndex(index)
				}
			}
		}
	}
}
	
