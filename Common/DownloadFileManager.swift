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

@objc class DownloadFileManager : NSObject, NSURLSessionDownloadDelegate {
	
	// MARK: - Instance Variables
	
	// File Download
	private var sessionManager : NSURLSession?
	private var backgroundHandlersForFiles: [FileInfo : CallbackWrapper] = [:]
	private var backgroundRequestsForFiles: [Int : FileInfo] = [:]				// Int is taskIdentifier of NSURLSessionTask
	
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
        config.HTTPMaximumConnectionsPerHost = NSUserDefaults.standardUserDefaults().integerForKey(simultaneousDownloadsKey)
		config.timeoutIntervalForResource = NSTimeInterval(300)
        sessionManager = NSURLSession(configuration: config, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
    }
    
    func preferenceChanged() {
				
        stopAllFileDownloads()
        
        if let config = sessionManager?.configuration {
            config.HTTPMaximumConnectionsPerHost = NSUserDefaults.standardUserDefaults().integerForKey(simultaneousDownloadsKey)
            config.timeoutIntervalForResource = NSTimeInterval(300)

            sessionManager?.invalidateAndCancel()
            
            sessionManager = NSURLSession(configuration: config, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        }
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
            let callbackWrapper = CallbackWrapper()
            callbackWrapper.addProgressWrapper(progressWrapper)
            callbackWrapper.addCompletionWrapper(completionWrapper)
            backgroundHandlersForFiles[file] = callbackWrapper
            
            if file.shouldDownloadFile == true && file.fileSize > 0 {
                startDownload(file)
            }
        }
    }
	
	
	func stopAllFileDownloads() {
					
        sessionManager?.getTasksWithCompletionHandler{ [unowned self] (dataTasks, uploadTasks, downloadTasks) -> Void in
            
            for task in downloadTasks {
                if let file = self.backgroundRequestsForFiles[task.taskIdentifier] {
                    task.cancelByProducingResumeData({ (data) -> Void in   // ResumeData saved out in didCompleteMethod
                        if  data == nil{
                            file.resumeData = nil
                            file.downloadProgress = 0
                        }
                    })
                }
            }
        }
    }
	
	// MARK: -
    private func startDownload(file: FileInfo) {
        
        if logFileManager { print("Queue Download of \(file.displayName!)") }
        
        guard let url = file.remoteFileURL else
        {
            if let callback = backgroundHandlersForFiles[file] {
                print("Download Fail No RemoteURL! - \(file.displayName!)")
                callback.notifyCompletion(false)
                backgroundHandlersForFiles[file] = nil
            }
            return
        }

        // Resume download if possible
        if let resumeData = file.resumeData {
            if let task = sessionManager?.downloadTaskWithResumeData(resumeData) {
                backgroundRequestsForFiles[task.taskIdentifier] = file
                task.resume()
                return
            }
        }

        // New Download
        if let task = sessionManager?.downloadTaskWithRequest(NSURLRequest(URL: url)) {
            backgroundRequestsForFiles[task.taskIdentifier] = file
            task.resume()
        }
    }
	
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)  {
		
        var progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
        if progress > 1 {
            progress = 1
        }
        
        if let fileInfo = backgroundRequestsForFiles[downloadTask.taskIdentifier] {
            
            fileInfo.downloadProgress = progress
            
            if let callback = backgroundHandlersForFiles[fileInfo] {
                callback.notifyProgress(progress)
            }
        }
    }
	
	
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
		
        if let fileInfo = backgroundRequestsForFiles[downloadTask.taskIdentifier] {
            fileInfo.saveFileLocallyFrom(location)
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
		
        if  let downloadTask = task as? NSURLSessionDownloadTask {
				if let fileInfo = backgroundRequestsForFiles[downloadTask.taskIdentifier] {
					if let callback = backgroundHandlersForFiles[fileInfo] {
						
						if let error = error {
							
                            if let resumeData = error.userInfo["NSURLSessionDownloadTaskResumeData"] as? NSData {
                                fileInfo.resumeData = resumeData
                            }
                            
							switch error.code {
								case NSURLErrorTimedOut:
									print("Retrying - \(fileInfo.displayName!)")
                                    fileInfo.fileErrorCode = nil
									fileInfo.attemptsToDownloadFile++
                                    startDownload(fileInfo)
                                case NSURLErrorCancelled:
                                    print("User Cancelled - \(fileInfo.displayName!)")
                                    fileInfo.fileErrorCode = nil
                                    callback.notifyCompletion(false)
                                    self.backgroundHandlersForFiles[fileInfo] = nil
                                    self.backgroundRequestsForFiles[downloadTask.taskIdentifier] = nil
								default:
									print("Download Fail Code-\(error.code) - \(fileInfo.displayName!)")
									fileInfo.fileErrorCode = error
									callback.notifyCompletion(false)
									self.backgroundHandlersForFiles[fileInfo] = nil
									self.backgroundRequestsForFiles[downloadTask.taskIdentifier] = nil
                            }
						}
						else {
							callback.notifyCompletion(true)
							self.backgroundHandlersForFiles[fileInfo] = nil
							self.backgroundRequestsForFiles[downloadTask.taskIdentifier] = nil
						}
					}
				}
			}
    }


	// MARK: - CallbackWrapper
    private class CallbackWrapper : NSObject {
		
		// MARK: Instance Variables
		var progressWrappers: [ProgressWrapper] = []
		var completionWrappers: [SimpleCompletionWrapper] = []
		
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
		
        func notifyProgress(progress: Float) {
			
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
		
        func notifyCompletion(success: Bool) {
			
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
	
