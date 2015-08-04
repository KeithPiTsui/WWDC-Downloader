//
//  DownloadTranscriptManager.swift
//  WWDC
//
//  Created by David Roberts on 29/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation

typealias TranscriptCompletionHandler = ((success:Bool, errorCode:Int?) -> Void)

class DownloadTranscriptManager : NSObject, NSURLSessionDataDelegate {
	
	static let sharedManager = DownloadTranscriptManager()

    private var sessionManager : NSURLSession?
	private var downloadHandlers: [Int : (WWDCSession,HeaderCompletionHandler)] = [:]			// Int is taskIdentifier of NSURLSessionTask

	static let timeFormatter : NSDateComponentsFormatter = {
		let aFormatter = NSDateComponentsFormatter()
		aFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehavior.Pad
		aFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyle.Positional
		aFormatter.allowedUnits = [NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second]
		return aFormatter
		}()
    
    static let numberFormatter : NSNumberFormatter = {
        let aFormatter = NSNumberFormatter()
        aFormatter.positiveFormat = "0"
        return aFormatter
    }()
    
    private override init() {
        
        super.init()
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
		config.timeoutIntervalForRequest = NSTimeInterval(120)
        sessionManager = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func fetchTranscript(session : WWDCSession, completion: TranscriptCompletionHandler) {
        
        let remoteFileURLString = "http://asciiwwdc.com/"+String(session.sessionYear.description)+"/sessions/"+session.sessionID
        
        if let url = NSURL(string: remoteFileURLString) {
			startDownload(session, transcriptURL:url, completion: completion)
        }
    }
	
	private func startDownload(session:WWDCSession, transcriptURL : NSURL , completion: TranscriptCompletionHandler) {
		
		let request = NSMutableURLRequest(URL: transcriptURL)
		request.HTTPMethod = "GET"
		request.setValue("application/json", forHTTPHeaderField: "Accept")
		
		if let task = sessionManager?.downloadTaskWithRequest(request) {
			self.downloadHandlers[task.taskIdentifier] = (session,completion)
			task.resume()
		}
	}

	func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
		
		if let (wwdcSession,completion) = downloadHandlers[downloadTask.taskIdentifier], let response = downloadTask.response as? NSHTTPURLResponse {
			
			if let path = location.path where response.statusCode == 200 {
				if let data = NSData(contentsOfFile:path)  {
					do {
						if let jsonObject : NSDictionary = try NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.AllowFragments) as? NSDictionary {
							
							if let sessionDescription = jsonObject["description"] as? String {
								wwdcSession.sessionDescription = sessionDescription
							}
							
							if let sessionTrack = jsonObject["track"] as? String {
								wwdcSession.sessionTrack = sessionTrack
							}
							
							if let timeCodes = jsonObject["timecodes"] as? NSArray, let annotations = jsonObject["annotations"] as? NSArray {
								
								if timeCodes.count == annotations.count {
									
									autoreleasepool {
										var transcript : [TranscriptInfo] = []
										
										var fullTranscript : String = ""
										let markup : NSMutableString = ""
										
										for var i = 0;  i < timeCodes.count; ++i {
											let timeCode = timeCodes[i] as? NSNumber
											let annotation = annotations[i] as? NSString
											
											if let timeCode = timeCode, let annotation = annotation {
												let transcriptPoint = TranscriptInfo(tuple:(Double(timeCode), annotation as String))
												transcript.append(transcriptPoint)
												
												if let timeString = DownloadTranscriptManager.timeFormatter.stringFromTimeInterval(Double(timeCode)) {
													fullTranscript = fullTranscript+(timeString+"  "+(annotation as String)+"\n\n")
													
													let stringTimeCode = DownloadTranscriptManager.numberFormatter.stringFromNumber(timeCode)
													
													// Build HTML
													let htmlFormat = "<p><a href=\"javascript:seekToTimeCode(%@)\" data-timecode=\"%@\">%@</a>  %@</p>"
													
													if let stringTimeCode = stringTimeCode {
														markup.appendFormat(htmlFormat, timeCode, stringTimeCode, timeString, (annotation as String))
													}
												}
											}
										}
										
										wwdcSession.transcript = transcript
										wwdcSession.fullTranscriptPrettyPrint = fullTranscript
										wwdcSession.transcriptHTMLFormatted = markup as String
										
										completion(success: true, errorCode: nil)
									}
								}
							}
						}
					}
					catch {
						print("JSON Error - \(wwdcSession.displayName) - \(error)")
						completion(success: false, errorCode: 404)
					}
				}
			}
			else {
				print("Transcript Response Error - \(wwdcSession.displayName) - \(response.statusCode)")
				completion(success: false, errorCode: response.statusCode)
			}
			downloadHandlers[downloadTask.taskIdentifier] = nil
		}
	}
	
	func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
		
		if session == sessionManager {
			if let (wwdcSession,completion) = downloadHandlers[task.taskIdentifier] {
				if let error = error {
					switch error.code {
					case NSURLErrorTimedOut:
						print("Retrying - \(wwdcSession.displayName)")
						if let url = task.originalRequest?.URL {
							downloadHandlers[task.taskIdentifier] = nil
							startDownload(wwdcSession, transcriptURL:url, completion: completion)
							return
						}
						else {
							print("Download Fail Code - NO URL -\(error.code) - \(wwdcSession.displayName)")
							completion(success: false, errorCode:error.code)
						}
					case NSURLErrorCancelled:
						print("User Cancelled -\(error.code) - \(wwdcSession.displayName)")
						completion(success: false, errorCode:error.code)
					default:
						print("Download Fail Code-\(error.code) - \(wwdcSession.displayName)")
						completion(success: false, errorCode:error.code)
					}
					
					downloadHandlers[task.taskIdentifier] = nil
				}
			}
		}
	}
	
    func stopAllTranscriptFetchs() {
		
		sessionManager?.getAllTasksWithCompletionHandler{ (tasks) -> Void in
			for task in tasks {
				task.cancel()
			}
		}
	}


}