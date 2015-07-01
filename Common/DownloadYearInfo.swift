//
//  DownloadYearInfo.swift
//  WWDC
//
//  Created by David Roberts on 15/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

let developerBaseURL = "https://developer.apple.com"

let videos2015baseURL = "/videos/wwdc/2015/"
let videos2014baseURL = "/videos/wwdc/2014/"
let videos2013baseURL = "/videos/wwdc/2013/"

enum DownloadYearState {
    case Idle
    case FetchingYear
    case FetchingFileSizes
    case FetchingASCIIExtendedinfo
}

import Foundation

class DownloadYearInfo: NSObject, NSURLSessionTaskDelegate {
    
	var wwdcSessions : [WWDCSession] = []
	
    private let year : WWDCYear
	
	private var parsingCompletionHandler : (sessions: [WWDCSession]) -> Void
	private var individualCompletionHandler : (session : WWDCSession) -> Void
    private var sessionInfoCompletionHandler : (success : Bool) -> Void
	
    private var sessionManager : NSURLSession?

    private var state : DownloadYearState
    
    private var isCancelled = false
    
	// MARK: Initialization
    init(year: WWDCYear, parsingCompleteHandler:((sessions: [WWDCSession]) -> Void), individualSessionUpdateHandler: ((session: WWDCSession) -> Void), completionHandler: (success : Bool) -> Void) {
        
        self.year = year
		self.parsingCompletionHandler = parsingCompleteHandler
		self.individualCompletionHandler = individualSessionUpdateHandler
        self.sessionInfoCompletionHandler = completionHandler
	
        self.state = .Idle
        
        super.init()
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.HTTPMaximumConnectionsPerHost = 3
        sessionManager = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
        
        print("Downloading Main Page for \(year)...")
        
        var videoURLString : NSURL?
        
        switch year {
            case .WWDC2015:
               videoURLString = NSURL(string:developerBaseURL+videos2015baseURL)
            case .WWDC2014:
                videoURLString = NSURL(string:developerBaseURL+videos2014baseURL)
            case .WWDC2013:
                videoURLString = NSURL(string:developerBaseURL+videos2013baseURL)
        }
        
        if let videoURLString = videoURLString {

            state = .FetchingYear
            
            let task = sessionManager?.dataTaskWithURL(videoURLString) { [unowned self]  (data, response, error) in
                self.downloadMainPageFinished(data, response: response as? NSHTTPURLResponse, error: error)
            }
            task?.resume()
        }
    }
    
    private func downloadMainPageFinished(data: NSData?, response: NSHTTPURLResponse?, error: NSError?) {
        
        if !isCancelled {
            if let wwdcMainHTMLdata = data  {
            
                print("Completed Downloading Main Page for \(year)")
                // Convert Data to TFHpple Elements
                let doc = TFHpple(HTMLData: wwdcMainHTMLdata)
                
                switch year {
                    case .WWDC2015:
                        parse2015Doc(doc)
                    case .WWDC2014:
                        parse2014Doc(doc)
                    case .WWDC2013:
                        parse2014Doc(doc)
                }
                return
            }
            else if let error = error {
                print("Main Page Error - \(error)")
            }
            else {
                // Do nothing, and the operation will automatically finish.
            }
        }
        else {
            self.sessionInfoCompletionHandler(success: false)
        }
        
        self.state = .Idle
    }
	
	
	// MARK: - Parsers 
	// MARK: 2015
	// - Has Main Page with links to a Separate page to each Session
    private func parse2015Doc(doc : TFHpple) {
    
        // find sections
        let sections : [TFHppleElement] = doc.searchWithXPathQuery("//*[@class='inner_v_section']") as! [TFHppleElement]
		
		print("Started Parsing Main Page\(year)...")

        // find and amalgamate links to sessions
        for section in sections {
            
            let sectionItems = section.searchWithXPathQuery("//a") as! [TFHppleElement]
			
            for link in sectionItems {
				
				autoreleasepool {
					if let sessionIDLink = link.attributes["href"] as? String, let sessionTitle = link.content {
						
						let sessionID = sessionIDLink.stringByReplacingOccurrencesOfString("?id=", withString: "")
						
						wwdcSessions.append(WWDCSession(sessionID: sessionID, title: sessionTitle, year: .WWDC2015))
					}
				}
            }
        }
		
		wwdcSessions.sortInPlace { ($1.sessionID > $0.sessionID) }
        
        print("Finished Parsing Main Page\(year)")
		
        if isCancelled {
            sessionInfoCompletionHandler(success: false)
            return
        }
        
		parsingCompletionHandler(sessions: wwdcSessions)
		
		print("Fetching Session Info in \(year)...")
		
        state = .FetchingFileSizes

		let sessionGroup = dispatch_group_create()
		
		for wwdcSession in wwdcSessions {
			
			dispatch_group_enter(sessionGroup)
			
			parseAndFetchSession2015(wwdcSession) { (success) -> Void in
				
				dispatch_group_leave(sessionGroup)
			}
		}
        
		dispatch_group_notify(sessionGroup,dispatch_get_main_queue(),{ [unowned self] in
			
            if !self.isCancelled {
                
                print("Fetching ASCIIwwdc Extra Info...")
                
                self.state = .FetchingASCIIExtendedinfo
                
                let transcriptGroup = dispatch_group_create()
                
                for wwdcSession in self.wwdcSessions {
                    
                    dispatch_group_enter(transcriptGroup)
                    
                    DownloadTranscriptManager.sharedManager.fetchTranscript(wwdcSession, completion: {  (success, errorCode) -> Void in
                        
                        wwdcSession.isInfoFetchComplete = true
                        
                        self.individualCompletionHandler(session: wwdcSession)
                        
                        if success {
                            print("Completed fetch of Session Info -   \(wwdcSession.sessionID) - \(wwdcSession.title)")
                        }
                        else {
                            print("Failed fetch of Extended Info - \(wwdcSession.sessionID) - \(wwdcSession.title)")
                        }
                        
                        dispatch_group_leave(transcriptGroup)
                    })
                }
                
                dispatch_group_notify(transcriptGroup,dispatch_get_main_queue(),{ [unowned self] in
                    
                        self.state = .Idle
                        
                        print("Finished All Session Info in \(self.year)")
                        self.sessionInfoCompletionHandler(success: true)
                    })
            }
            else {
                self.sessionInfoCompletionHandler(success: false)
            }
            
        })
	}
	
	private func parseAndFetchSession2015 (wwdcSession : WWDCSession, completion: (success: Bool) -> Void) {
		
		let wwdcSessionPage = developerBaseURL+videos2015baseURL+"?id="+wwdcSession.sessionID
		
		guard let wwdcSessionPageURL = NSURL(string: wwdcSessionPage) else { return }
        
        let urlSessionTask : NSURLSessionDataTask? = sessionManager?.dataTaskWithRequest(NSURLRequest(URL: wwdcSessionPageURL)) { [unowned self] (pageData, response, error) -> Void in
			

			if let pageData = pageData  {
				
				// Debug HMTL For Session Page
				//  guard let html = NSString(data: pageData, encoding: NSUTF8StringEncoding) else { return }
				//  print(html)
				//  return
				
				let sessionDoc = TFHpple(HTMLData: pageData)
				
				let hd : [TFHppleElement] = sessionDoc.searchWithXPathQuery("//*[text()='HD']") as! [TFHppleElement]
				
				if let hdDownloadLink = hd.first?.attributes["href"] as? String {
					let file = FileInfo(session: wwdcSession, fileType: .HD)
					file.remoteFileURL = NSURL(string: hdDownloadLink)
					wwdcSession.hdFile = file
				}
				
				let sd : [TFHppleElement] = sessionDoc.searchWithXPathQuery("//*[text()='SD']") as! [TFHppleElement]
				
				if let sdDownloadLink = sd.first?.attributes["href"] as? String {
					let file = FileInfo(session: wwdcSession, fileType: .SD)
					file.remoteFileURL = NSURL(string: sdDownloadLink)
					wwdcSession.sdFile = file
				}
				
				let pdf : [TFHppleElement] = sessionDoc.searchWithXPathQuery("//*[text()='PDF']") as![TFHppleElement]
				
				if let pdfDownloadLink = pdf.first?.attributes["href"] as? String {
					let file = FileInfo(session: wwdcSession, fileType: .PDF)
					file.remoteFileURL = NSURL(string: pdfDownloadLink)
					wwdcSession.pdfFile = file
				}
				
				let sampleCodes : [TFHppleElement] = sessionDoc.searchWithXPathQuery("//*[@class='sample-code']") as! [TFHppleElement]
				
				if sampleCodes.count > 0 {
					
					let downloadGroup = dispatch_group_create()
					
					for sampleCode in sampleCodes {
						
						let child = sampleCode.children as NSArray
						
						if let item = child.firstObject as? TFHppleElement {
							
							let link = item.attributes["href"] as! String
							
							// Links not consistant - can either be on samplecode page in or prelease directory
							if let _ = link.rangeOfString("/sample-code/wwdc/2015/downloads/") {   // link appears to be direct link

								let codelink = developerBaseURL+link

								let file = FileInfo(session: wwdcSession, fileType: .SampleCode)
								file.remoteFileURL = NSURL(string: codelink)
								wwdcSession.sampleCodeArray.append(file)
							}
							else {
								
								dispatch_group_enter(downloadGroup)
								
								let codeURLSession = self.sessionManager?.dataTaskWithURL(NSURL(string: developerBaseURL+link+"/book.json")!) { (jsonData, response, error) -> Void in
									
									if let jsonData = jsonData {
										guard let json = NSString(data: jsonData, encoding: NSUTF8StringEncoding) as? String else { return }
										
										let substring = json.stringBetweenString("\"sampleCode\":\"", andString: ".zip\"")
										
										if let substring = substring {
											
											let codelink = developerBaseURL+link+"/"+substring+".zip"
											
											let file = FileInfo(session: wwdcSession, fileType: .SampleCode)
											file.remoteFileURL = NSURL(string: codelink)
											wwdcSession.sampleCodeArray.append(file)
										}
									}
									dispatch_group_leave(downloadGroup)
								}
								codeURLSession?.resume()
							}
						}
					}
					
					dispatch_group_notify(downloadGroup,dispatch_get_main_queue(),{ [unowned self] in
							self.fetchFileSizes(wwdcSession) { (success) -> Void in
								completion(success: true)
							}
						})
				}
				else {
					self.fetchFileSizes(wwdcSession) { (success) -> Void in
						completion(success: true)
					}
				}
			}
			else if let _ = error {
				print("Failed fetch of Session Info \(wwdcSession.sessionID) - \(wwdcSession.title) - \n \(error)")
				completion(success: false)
			}

		}
		
		urlSessionTask?.resume()
	}
	
	
	// MARK: 2014
	// - Has Main Page with all sessions
    private func parse2014Doc(doc : TFHpple) {
        
        // find sections
        let sessionSections : [TFHppleElement] = doc.searchWithXPathQuery("//*[@class='session']") as! [TFHppleElement]
		
		print("Started Parsing \(year)...")

        for section in sessionSections {
			
			autoreleasepool {
				if let sessionID = section.attributes["id"] as? String {
					
					let cleanSessionID = sessionID.stringByReplacingOccurrencesOfString("-video", withString: "")
					
					let sectionItems = section.searchWithXPathQuery("//*[@class='title']") as! [TFHppleElement]
					let title = sectionItems[0].content
					
					let wwdcSession = WWDCSession(sessionID: cleanSessionID, title: title, year: year)
					
					let aItems = section.searchWithXPathQuery("//*[@class='description active']") as! [TFHppleElement]
					
					for anItem in aItems {
						
						let links = anItem.searchWithXPathQuery("//a") as! [TFHppleElement]
						
						for link in links {
							if link.content == "HD" {
								if let hdDownloadLink = link.attributes["href"] as? String {
									let file = FileInfo(session: wwdcSession, fileType: .HD)
									file.remoteFileURL = NSURL(string: hdDownloadLink)
									wwdcSession.hdFile = file
								}
							}
							
							if link.content == "SD" {
								if let sdDownloadLink = link.attributes["href"] as? String {
									let file = FileInfo(session: wwdcSession, fileType: .SD)
									file.remoteFileURL = NSURL(string: sdDownloadLink)
									wwdcSession.sdFile = file
								}
							}
							
							if link.content == "PDF" {
								if let pdfDownloadLink = link.attributes["href"] as? String {
									let file = FileInfo(session: wwdcSession, fileType: .PDF)
									file.remoteFileURL = NSURL(string: pdfDownloadLink)
									wwdcSession.pdfFile = file
								}
							}
						}
					}
					
					wwdcSessions.append(wwdcSession)
				}
			}
		}
		
		wwdcSessions.sortInPlace { ($1.sessionID > $0.sessionID) }

        print("Finished Parsing \(year)")
		
        if isCancelled {
            self.sessionInfoCompletionHandler(success: false)
            return
        }
        
		self.parsingCompletionHandler(sessions: wwdcSessions)

		print("Fetching File Sizes for Sessions in \(year)...")
        
        state = .FetchingFileSizes
		
		let fileSizeGroup = dispatch_group_create()

		for wwdcSession in wwdcSessions {
			
			dispatch_group_enter(fileSizeGroup)

			self.fetchFileSizes(wwdcSession) { (success) -> Void in
				
				dispatch_group_leave(fileSizeGroup)
			}
		}

		dispatch_group_notify(fileSizeGroup,dispatch_get_main_queue(),{ [unowned self] in
			
            if !self.isCancelled {
                
                print("Fetching ASCIIwwdc Extra Info...")
                
                self.state = .FetchingASCIIExtendedinfo
                
                let transcriptGroup = dispatch_group_create()
                
                for wwdcSession in self.wwdcSessions {
                    
                    dispatch_group_enter(transcriptGroup)
                    
                    DownloadTranscriptManager.sharedManager.fetchTranscript(wwdcSession, completion: {  (success, errorCode) -> Void in
                        
                        wwdcSession.isInfoFetchComplete = true

                        self.individualCompletionHandler(session: wwdcSession)
                        
                        if success {
                            print("Completed fetch of Session Info -   \(wwdcSession.sessionID) - \(wwdcSession.title)")
                        }
                        else {
                            print("Failed fetch of Extended Info - \(wwdcSession.sessionID) - \(wwdcSession.title)")
                        }
                        
                        dispatch_group_leave(transcriptGroup)
                    })
                }
                
                dispatch_group_notify(transcriptGroup,dispatch_get_main_queue(),{ [unowned self] in
                    
                        self.state = .Idle

                        print("Finished All Session Info in \(self.year)")
                        self.sessionInfoCompletionHandler(success: true)
                    })
            }
            else {
                self.sessionInfoCompletionHandler(success: false)
            }
		})
    }
	
	
	// MARK: - FileSize
	private func fetchFileSizes (wwdcSession : WWDCSession, completion: (success: Bool) -> Void) {
		
		let fileSizeSessionGroup = dispatch_group_create()
		
		if let file = wwdcSession.hdFile {
			dispatch_group_enter(fileSizeSessionGroup)
			
            FetchFileSizeManager.sharedManager.fetchFileSize(file, completion: { (success, errorCode) -> Void in
                
                if (!success) {
                    print("\(file.displayName!) - File Size - NO RESULT #######")
                }
                dispatch_group_leave(fileSizeSessionGroup)
            })
        }
		
		if let file = wwdcSession.sdFile {
			dispatch_group_enter(fileSizeSessionGroup)
			
            FetchFileSizeManager.sharedManager.fetchFileSize(file, completion: { (success, errorCode) -> Void in
                
				if (!success) {
					print("\(file.displayName!) - File Size - NO RESULT #######")
				}
                dispatch_group_leave(fileSizeSessionGroup)
            })

		}
		
		if let file = wwdcSession.pdfFile {
			dispatch_group_enter(fileSizeSessionGroup)
			
            FetchFileSizeManager.sharedManager.fetchFileSize(file, completion: { (success, errorCode) -> Void in
                
				if (!success) {
					print("\(file.displayName!) - File Size - NO RESULT #######")
				}
                dispatch_group_leave(fileSizeSessionGroup)
            })

		}
		
		if wwdcSession.sampleCodeArray.count > 0 {
			for sample in wwdcSession.sampleCodeArray {
					
                dispatch_group_enter(fileSizeSessionGroup)
                    
                FetchFileSizeManager.sharedManager.fetchFileSize(sample, completion: { (success, errorCode) -> Void in
                    
					if (!success) {
						print("\(sample.displayName!) - File Size - NO RESULT #######")
					}
                    dispatch_group_leave(fileSizeSessionGroup)
                })
			}
		}
		
		dispatch_group_notify(fileSizeSessionGroup,dispatch_get_main_queue(),{
                completion(success: true)
			})
	}
    
    func stopDownloading () {
        
        isCancelled = true
        
        switch state {
        case .Idle:
            break
        case .FetchingYear:
            if #available(OSX 10.11, *) {
                sessionManager?.getAllTasksWithCompletionHandler({ (tasks) -> Void in
                    for task in tasks {
                        task.cancel()
                    }
                })
            } else {
                // Fallback on earlier versions
				sessionManager?.getTasksWithCompletionHandler({ (data, upload, download) -> Void in
					for task in data {
						task.cancel()
					}
					for task in upload {
						task.cancel()
					}
					for task in download {
						task.cancel()
					}
				})
            }
        case .FetchingFileSizes:
            FetchFileSizeManager.sharedManager.stopAllFileSizeFetchs()
        case .FetchingASCIIExtendedinfo:
            DownloadTranscriptManager.sharedManager.stopAllTranscriptFetchs()
        }
    }
	
}
