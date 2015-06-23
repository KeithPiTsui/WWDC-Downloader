//
//  DownloadSessionInfo.swift
//  WWDC
//
//  Created by David Roberts on 15/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

let developerBaseURL = "https://developer.apple.com"

let videos2015baseURL = "/videos/wwdc/2015/"
let videos2014baseURL = "/videos/wwdc/2014/"

import Foundation

class DownloadSessionInfo: NSObject {
    
    // MARK: Initialization
    
    private let year : WWDCYear
    
    private var sessionInfoCompletionHandler : (sessions: Set<WWDCSession>) -> Void
    
    init(year: WWDCYear, completionHandler: (sessions: Set<WWDCSession>) -> Void) {
        
        self.year = year
        self.sessionInfoCompletionHandler = completionHandler
        
        super.init()
        
        print("Downloading Main Page for \(year)...")
        
        var videoURLString : NSURL?
        
        switch year {
            case .WWDC2015:
               videoURLString = NSURL(string:developerBaseURL+videos2015baseURL)
            
            case .WWDC2014:
                videoURLString = NSURL(string:developerBaseURL+videos2014baseURL)
        }
        
        if let videoURLString = videoURLString {

            let task = NSURLSession.sharedSession().dataTaskWithURL(videoURLString) { [unowned self]  (url, response, error) in
                self.downloadMainPageFinished(url, response: response as? NSHTTPURLResponse, error: error)
            }
            
            if let task = task {
                task.resume()
            }
        }
        
    }
    
    private func downloadMainPageFinished(data: NSData?, response: NSHTTPURLResponse?, error: NSError?) {
        
        if let wwdcMainHTMLdata = data  {
			
			print("Completed Downloading Main Page for \(year)")
            // Convert Data to TFHpple Elements
            let doc = TFHpple(HTMLData: wwdcMainHTMLdata)
            
            switch year {
                case .WWDC2015:
                    parse2015Doc(doc)
                case .WWDC2014:
                    parse2014Doc(doc)
            }
            
        }
        else if let error = error {
            print("Main Page Error - \(error)")
        }
        else {
            // Do nothing, and the operation will automatically finish.
        }
    }
	
	
	// MARK: - Parsers 
	// MARK: 2015
	// - Has Main Page with links to a Separate page to each Session
    private func parse2015Doc(doc : TFHpple) {
    
        // find sections
        let sections : [TFHppleElement] = doc.searchWithXPathQuery("//*[@class='inner_v_section']") as! [TFHppleElement]
        
        // Create Set of WWDCSession items
        var wwdcSessionsSet = Set<WWDCSession>()
		
		print("Started Parsing Main Page\(year)...")

        // find and amalgamate links to sessions
        for section in sections {
            
            let sectionItems = section.searchWithXPathQuery("//a") as! [TFHppleElement]
            
            for link in sectionItems {
                
                if let sessionIDLink = link.attributes["href"] as? String, let sessionTitle = link.content {
                    
                    let sessionID = sessionIDLink.stringByReplacingOccurrencesOfString("?id=", withString: "")
                    
                    wwdcSessionsSet.insert(WWDCSession(sessionID: sessionID, title: sessionTitle, year: .WWDC2015))
                }
            }
        }
        
        print("Finished Parsing Main Page\(year)")
		
		print("Fetching Session Info in \(year)...")
		
		let sessionGroup = dispatch_group_create();
		
		for wwdcSession in wwdcSessionsSet {
			
			dispatch_group_enter(sessionGroup);
			
			self.parseAndFetchSession2015(wwdcSession) { (success) -> Void in
				dispatch_group_leave(sessionGroup)
			}
		}
		
		dispatch_group_notify(sessionGroup,dispatch_get_main_queue(),{ [unowned self] in
			
				print("Finished All Session Info in \(self.year)")
				self.sessionInfoCompletionHandler(sessions: wwdcSessionsSet)
			})
	}
	
	private func parseAndFetchSession2015 (wwdcSession : WWDCSession, completion: (success: Bool) -> Void) {
		
		let wwdcSessionPage = developerBaseURL+videos2015baseURL+"/?id="+wwdcSession.sessionID
		
		guard let wwdcSessionPageURL = NSURL(string: wwdcSessionPage) else { return }
		
		let urlSession = NSURLSession().dataTaskWithURL(wwdcSessionPageURL) { [unowned self] (pageData, response, error) -> Void in
			
			if let pageData = pageData  {
				
				// Debug HMTL For Session Page
				//  guard let html = NSString(data: pageData, encoding: NSUTF8StringEncoding) else { return }
				//  print(html)
				//  return
				
				let sessionDoc = TFHpple(HTMLData: pageData)
				
				let hd : [TFHppleElement] = sessionDoc.searchWithXPathQuery("//*[text()='HD']") as! [TFHppleElement]
				
				if let hdDownloadLink = hd.first?.attributes["href"] as? String {
					let file = FileInfo()
					file.remoteFileURL = NSURL(string: hdDownloadLink)
					file.fileName = WWDCSession.sanitizeFileNameString(wwdcSession.sessionID+"-"+wwdcSession.title)+"-HD.mp4"
					file.displayName = wwdcSession.sessionID+"-"+wwdcSession.title+" HD Video"
					guard let directory = wwdcSession.videoDirectory(), let filename = file.fileName  else { return }
					file.localFileURL = NSURL(fileURLWithPath: directory.stringByAppendingPathComponent(WWDCSession.sanitizeFileNameString( filename)))
					wwdcSession.hdFile = file
				}
				
				let sd : [TFHppleElement] = sessionDoc.searchWithXPathQuery("//*[text()='SD']") as! [TFHppleElement]
				
				if let sdDownloadLink = sd.first?.attributes["href"] as? String {
					let file = FileInfo()
					file.remoteFileURL = NSURL(string: sdDownloadLink)
					file.fileName = WWDCSession.sanitizeFileNameString(wwdcSession.sessionID+"-"+wwdcSession.title)+"-SD.mp4"
					file.displayName = wwdcSession.sessionID+"-"+wwdcSession.title+" SD Video"
					guard let directory = wwdcSession.videoDirectory(), let filename = file.fileName  else { return }
					file.localFileURL = NSURL(fileURLWithPath: directory.stringByAppendingPathComponent(WWDCSession.sanitizeFileNameString( filename)))
					wwdcSession.sdFile = file
				}
				
				let pdf : [TFHppleElement] = sessionDoc.searchWithXPathQuery("//*[text()='PDF']") as![TFHppleElement]
				
				if let pdfDownloadLink = pdf.first?.attributes["href"] as? String {
					let file = FileInfo()
					file.remoteFileURL = NSURL(string: pdfDownloadLink)
					file.fileName = WWDCSession.sanitizeFileNameString(wwdcSession.sessionID+"-"+wwdcSession.title)+".pdf"
					file.displayName = wwdcSession.sessionID+"-"+wwdcSession.title+" PDF"
					guard let directory = wwdcSession.pdfDirectory(), let filename = file.fileName  else { return }
					file.localFileURL = NSURL(fileURLWithPath: directory.stringByAppendingPathComponent(WWDCSession.sanitizeFileNameString( filename)))
					wwdcSession.pdfFile = file
				}
				
				let sampleCodes : [TFHppleElement] = sessionDoc.searchWithXPathQuery("//*[@class='sample-code']") as! [TFHppleElement]
				
				if sampleCodes.count > 0 {
					
					let downloadGroup = dispatch_group_create();
					
					for sampleCode in sampleCodes {
						
						let sampleCodeName = sampleCode.content
						
						let child = sampleCode.children as NSArray
						
						if let item = child.firstObject as? TFHppleElement {
							
							let link = item.attributes["href"] as! String
							
							dispatch_group_enter(downloadGroup);
							
							let codeURLSession = NSURLSession().dataTaskWithURL(NSURL(string: developerBaseURL+link+"/book.json")!) { (jsonData, response, error) -> Void in
								
								if let jsonData = jsonData {
									guard let json = NSString(data: jsonData, encoding: NSUTF8StringEncoding) as? String else { return }
									
									let substring = json.stringBetweenString("\"sampleCode\":\"", andString: ".zip\"")
									
									if let substring = substring {
										
										let codelink = developerBaseURL+link+"/"+substring+".zip"
										
										let file = FileInfo()
										file.remoteFileURL = NSURL(string: codelink)
										file.displayName = sampleCodeName
										file.fileName = WWDCSession.sanitizeFileNameString(sampleCodeName)+".zip"
										guard let directory = wwdcSession.codeDirectory(), let filename = file.fileName  else { return }
										file.localFileURL = NSURL(fileURLWithPath: directory.stringByAppendingPathComponent(WWDCSession.sanitizeFileNameString( filename)))
										wwdcSession.sampleCodeArray.append(file)
									}
								}
								dispatch_group_leave(downloadGroup);
							}
							codeURLSession?.resume()
							
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
		
		urlSession?.resume()
	}
	
	
	// MARK: 2014
	// - Has Main Page with all sessions
    private func parse2014Doc(doc : TFHpple) {
        
        // find sections
        let sessionSections : [TFHppleElement] = doc.searchWithXPathQuery("//*[@class='session']") as! [TFHppleElement]
        
        // Create Set of WWDCSession items
        var wwdcSessionsSet = Set<WWDCSession>()
		
		
		print("Started Parsing \(year)...")

        for section in sessionSections {
            
            if let sessionID = section.attributes["id"] as? String {

				let cleanSessionID = sessionID.stringByReplacingOccurrencesOfString("-video", withString: "")
				
                let sectionItems = section.searchWithXPathQuery("//*[@class='title']") as! [TFHppleElement]
                let title = sectionItems[0].content

                let wwdcSession = WWDCSession(sessionID: cleanSessionID, title: title, year: .WWDC2014)
            
                let aItems = section.searchWithXPathQuery("//*[@class='description active']") as! [TFHppleElement]
                
                for anItem in aItems {
                    
                    let links = anItem.searchWithXPathQuery("//a") as! [TFHppleElement]
                    
                    for link in links {
                        if link.content == "HD" {
                            if let hdDownloadLink = link.attributes["href"] as? String {
                                let file = FileInfo()
                                file.remoteFileURL = NSURL(string: hdDownloadLink)
                                file.fileName = sessionID+"-"+title+"-HD.mp4"
                                file.displayName = sessionID+"-"+title+" HD Video"
                                guard let directory = wwdcSession.videoDirectory(), let filename = file.fileName  else { return }
                                file.localFileURL = NSURL(fileURLWithPath: directory.stringByAppendingPathComponent(WWDCSession.sanitizeFileNameString( filename)))
                                wwdcSession.hdFile = file
                            }
                        }
                        
                        if link.content == "SD" {
                            if let sdDownloadLink = link.attributes["href"] as? String {
                                let file = FileInfo()
                                file.remoteFileURL = NSURL(string: sdDownloadLink)
                                file.fileName = sessionID+"-"+title+"-SD.mp4"
                                file.displayName = sessionID+"-"+title+" SD Video"
                                guard let directory = wwdcSession.videoDirectory(), let filename = file.fileName  else { return }
                                file.localFileURL = NSURL(fileURLWithPath: directory.stringByAppendingPathComponent(WWDCSession.sanitizeFileNameString( filename)))
                                wwdcSession.sdFile = file
                            }
                        }
                        
                        if link.content == "PDF" {
                            if let pdfDownloadLink = link.attributes["href"] as? String {
                                let file = FileInfo()
                                file.remoteFileURL = NSURL(string: pdfDownloadLink)
                                file.fileName = sessionID+"-"+title+".pdf"
                                file.displayName = sessionID+"-"+title+" PDF"
                                guard let directory = wwdcSession.pdfDirectory(), let filename = file.fileName  else { return }
                                file.localFileURL = NSURL(fileURLWithPath: directory.stringByAppendingPathComponent(WWDCSession.sanitizeFileNameString( filename)))
                                wwdcSession.pdfFile = file
                            }
                        }
                    }
                }
                
                wwdcSessionsSet.insert(wwdcSession)
            }
        }
        
        print("Finished Parsing \(year)")
		
		print("Fetching File Sizes for Sessions in \(year)...")
		
		let fileSizeGroup = dispatch_group_create();

		for wwdcSession in wwdcSessionsSet {
			
			dispatch_group_enter(fileSizeGroup);

			self.fetchFileSizes(wwdcSession) { (success) -> Void in
				dispatch_group_leave(fileSizeGroup)
			}
		}

		dispatch_group_notify(fileSizeGroup,dispatch_get_main_queue(),{ [unowned self] in
			
			print("Finished File Sizes in \(self.year)")
			self.sessionInfoCompletionHandler(sessions: wwdcSessionsSet)
		})
    }
	
	
	// MARK: - FileSize
	private func fetchFileSizes (wwdcSession : WWDCSession, completion: (success: Bool) -> Void) {
		
		let fileSizeSessionGroup = dispatch_group_create();
		
		if let hdURL = wwdcSession.hdFile?.remoteFileURL {
			dispatch_group_enter(fileSizeSessionGroup);
			
			fetchFileSize(hdURL, completion: { (result) -> Void in
				
					if let filesize = result {
						wwdcSession.hdFile?.fileSize = filesize
					}
					dispatch_group_leave(fileSizeSessionGroup)
				})
		}
		
		if let sdURL = wwdcSession.sdFile?.remoteFileURL {
			dispatch_group_enter(fileSizeSessionGroup);
			
			fetchFileSize(sdURL, completion: { (result) -> Void in
				
					if let filesize = result {
						wwdcSession.sdFile?.fileSize = filesize
					}
					dispatch_group_leave(fileSizeSessionGroup)
				})
		}
		
		if let pdfURL = wwdcSession.pdfFile?.remoteFileURL {
			dispatch_group_enter(fileSizeSessionGroup);
			
			fetchFileSize(pdfURL, completion: { (result) -> Void in
				
					if let filesize = result {
						wwdcSession.pdfFile?.fileSize = filesize
					}
					dispatch_group_leave(fileSizeSessionGroup)
				})
		}
		
		if wwdcSession.sampleCodeArray.count > 0 {
			for sample in wwdcSession.sampleCodeArray {
				if let fileURL = sample.remoteFileURL {
					
// TODO: 401 returned for HEAD request on Zip Files? Commented out for now....
//					dispatch_group_enter(fileSizeSessionGroup);
//					
//					fetchFileSize(fileURL, completion: { (result) -> Void in
//						
//						if let filesize = result {
//							sample.fileSize = filesize
//							print("Sample Code FileSize - \(filesize)")
//						}
//						else {
//							print("NO RESULT")
//						}
//						dispatch_group_leave(fileSizeSessionGroup);
//					})
				}
			}
		}
		
		dispatch_group_notify(fileSizeSessionGroup,dispatch_get_main_queue(),{
			
				print("Completed fetch of Session Info -   \(wwdcSession.sessionID) - \(wwdcSession.title)")

				wwdcSession.isInfoFetchComplete = true
				completion(success: true)
			})
	}
	
	private func fetchFileSize(url : NSURL, completion: (result: Int?) -> Void) {
		
		let request = NSMutableURLRequest(URL: url)
		request.HTTPMethod = "HEAD"
		
		let fileSizeTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
			if let hresponse = response as? NSHTTPURLResponse {
				if let dictionary = hresponse.allHeaderFields as? Dictionary<String,String> {
					if hresponse.statusCode == 200 {
						if let size = dictionary["Content-Length"] {
							completion(result: Int(size))
							return
						}
					}
					else {
						print("Bad Header Response - \(dictionary)")
					}
				}
			}
			completion(result: nil)
		}
		fileSizeTask?.resume()
	}
	
}
