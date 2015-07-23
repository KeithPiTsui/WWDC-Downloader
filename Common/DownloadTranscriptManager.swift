//
//  DownloadTranscriptManager.swift
//  WWDC
//
//  Created by David Roberts on 29/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation

class DownloadTranscriptManager : NSObject, NSURLSessionDataDelegate {
	
	static let sharedManager = DownloadTranscriptManager()

    private var sessionManager : NSURLSession?
	
	static let timeFormatter : NSDateComponentsFormatter = {
		let aFormatter = NSDateComponentsFormatter()
		aFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehavior.Pad
		aFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyle.Positional
		aFormatter.allowedUnits = [NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second]
		return aFormatter
		}()
    
    private override init() {
        
        super.init()
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionManager = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func fetchTranscript(session : WWDCSession, completion: (success: Bool, errorCode:Int?) -> Void) {
        
        let remoteFileURLString = "http://asciiwwdc.com/"+String(session.sessionYear.description)+"/sessions/"+session.sessionID
        
        if let url = NSURL(string: remoteFileURLString) {
            
            let request = NSMutableURLRequest(URL: url)
			request.HTTPMethod = "GET"
			request.setValue("application/json", forHTTPHeaderField: "Accept")
			
            let task = sessionManager?.dataTaskWithRequest(request) { (data, response, error) -> Void in
                if let hresponse = response as? NSHTTPURLResponse {
                    if hresponse.statusCode == 200 {
                        if let data = data {
                            do {
								if let jsonObject : NSDictionary = try NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.AllowFragments) as? NSDictionary {
									
									if let sessionDescription = jsonObject["description"] as? String {
										session.sessionDescription = sessionDescription
									}
									
									if let sessionTrack = jsonObject["track"] as? String {
										session.sessionTrack = sessionTrack
									}
									
									if let html = jsonObject["markup"] as? String {
										session.transcriptHTMLFormatted = html
									}
									
									if let timeCodes = jsonObject["timecodes"] as? NSArray, let annotations = jsonObject["annotations"] as? NSArray {
										
										if timeCodes.count == annotations.count {
											
											autoreleasepool {
												var transcript : [TranscriptInfo] = []
												
												var fullTranscript : String = ""

												for var i = 0;  i < timeCodes.count; ++i {
													let timeCode = timeCodes[i] as? NSNumber
													let annotation = annotations[i] as? NSString
													
													if let timeCode = timeCode, let annotation = annotation {
														let transcriptPoint = TranscriptInfo(tuple:(Double(timeCode), annotation as String))
														transcript.append(transcriptPoint)
														
														if let timeString = DownloadTranscriptManager.timeFormatter.stringFromTimeInterval(Double(timeCode)) {
															fullTranscript = fullTranscript+(timeString+"  "+(annotation as String)+"\n\n")
														}
													}
												}
												
												session.transcript = transcript
												session.fullTranscriptPrettyPrint = fullTranscript
											}
										}
									}
									
									completion(success: true, errorCode: nil)
								}
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
                else if let error = error {
                    completion(success: false, errorCode: error.code)
                }
            }
            task?.resume()
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