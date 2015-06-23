//
//  WWDCSession.swift
//  WWDC
//
//  Created by David Roberts on 15/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation

enum WWDCYear {
    case WWDC2015, WWDC2014
}

class FileInfo : NSObject {
    
    var remoteFileURL : NSURL?
    var localFileURL : NSURL?
    
    var displayName : String?
    var fileSize : Int?
    var fileName : String?
}

func ==(lhs: WWDCSession, rhs: WWDCSession)-> Bool {
    return lhs.title == rhs.title && lhs.sessionID == rhs.sessionID
}

class WWDCSession : NSObject {
    
    let title : String
    let sessionID : String
    let sessionYear : WWDCYear

    var isInfoComplete = false
    
    var completionHandler : ((success: Bool) -> Void)?
    
    var hdFile : FileInfo?
    var sdFile : FileInfo?
    var pdfFile : FileInfo?

    var sampleCodeArray : [FileInfo]
    
    init(sessionID : String, title:String , year : WWDCYear) {
        
        self.title = title
        self.sessionID = sessionID
        self.sessionYear = year

        sampleCodeArray = []
    }
    
    func fetchThisSessionInfo(completion: (success: Bool) -> Void) {
        
        completionHandler = completion
        
        switch sessionYear {
        case .WWDC2015:
           parseAndFetchSession2015()
        case .WWDC2014:
            parseAndFetchSession2014()
        }
        
    }
    
    // MARK: Years
    
    private func parseAndFetchSession2015 () {
        
        let wwdcSessionPage = developerBaseURL+videos2015baseURL+"/?id="+sessionID
        
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
                    file.fileName = WWDCSession.sanitizeFileNameString(self.sessionID+"-"+self.title)+"-HD.mp4"
                    file.displayName = self.sessionID+"-"+self.title+" HD Video"
                    guard let directory = self.videoDirectory(), let filename = file.fileName  else { return }
                    file.localFileURL = NSURL(fileURLWithPath: directory.stringByAppendingPathComponent(WWDCSession.sanitizeFileNameString( filename)))
                    self.hdFile = file
                }
                
                let sd : [TFHppleElement] = sessionDoc.searchWithXPathQuery("//*[text()='SD']") as! [TFHppleElement]
                
                if let sdDownloadLink = sd.first?.attributes["href"] as? String {
                    let file = FileInfo()
                    file.remoteFileURL = NSURL(string: sdDownloadLink)
                    file.fileName = WWDCSession.sanitizeFileNameString(self.sessionID+"-"+self.title)+"-SD.mp4"
                    file.displayName = self.sessionID+"-"+self.title+" SD Video"
                    guard let directory = self.videoDirectory(), let filename = file.fileName  else { return }
                    file.localFileURL = NSURL(fileURLWithPath: directory.stringByAppendingPathComponent(WWDCSession.sanitizeFileNameString( filename)))
                    self.sdFile = file
                }
                
                let pdf : [TFHppleElement] = sessionDoc.searchWithXPathQuery("//*[text()='PDF']") as![TFHppleElement]
                
                if let pdfDownloadLink = pdf.first?.attributes["href"] as? String {
                    let file = FileInfo()
                    file.remoteFileURL = NSURL(string: pdfDownloadLink)
                    file.fileName = WWDCSession.sanitizeFileNameString(self.sessionID+"-"+self.title)+".pdf"
                    file.displayName = self.sessionID+"-"+self.title+" PDF"
                    guard let directory = self.pdfDirectory(), let filename = file.fileName  else { return }
                    file.localFileURL = NSURL(fileURLWithPath: directory.stringByAppendingPathComponent(WWDCSession.sanitizeFileNameString( filename)))
                    self.pdfFile = file
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
                            
                            let codeURLSession = NSURLSession().dataTaskWithURL(NSURL(string: developerBaseURL+link+"/book.json")!) { [unowned self] (jsonData, response, error) -> Void in
                                
                                if let jsonData = jsonData {
                                    guard let json = NSString(data: jsonData, encoding: NSUTF8StringEncoding) as? String else { return }
                                    
                                    let substring = json.stringBetweenString("\"sampleCode\":\"", andString: ".zip\"")
                                    
                                    if let substring = substring {
                                        
                                        let codelink = developerBaseURL+link+"/"+substring+".zip"
                                        
                                        let file = FileInfo()
                                        file.remoteFileURL = NSURL(string: codelink)
                                        file.displayName = sampleCodeName
                                        file.fileName = WWDCSession.sanitizeFileNameString(sampleCodeName)+".zip"
                                        guard let directory = self.codeDirectory(), let filename = file.fileName  else { return }
                                        file.localFileURL = NSURL(fileURLWithPath: directory.stringByAppendingPathComponent(WWDCSession.sanitizeFileNameString( filename)))
                                        self.sampleCodeArray.append(file)
                                    }
                                }
                                dispatch_group_leave(downloadGroup);
                            }
                            codeURLSession?.resume()
                            
                        }
                    }
                    
                    dispatch_group_notify(downloadGroup,dispatch_get_main_queue(),{ [unowned self] in
                        self.fetchFileSizes()
                        })
                }
                else {
                    self.fetchFileSizes()
                }
            }
            else if let _ = error {
                print("Failed fetch of Session Info \(self.sessionID) - \(self.title) - \n \(error)")
                if let completionHandler = self.completionHandler {
                    completionHandler(success: false)
                }
            }
        }
        
        urlSession?.resume()
    }
    
    private func parseAndFetchSession2014 () {
        self.fetchFileSizes()
    }
    
    
    
    // MARK: - FileSize Helpers
    func fetchFileSizes () {
        
        let filesizeGroup = dispatch_group_create();

        if let hdURL = hdFile?.remoteFileURL {
            dispatch_group_enter(filesizeGroup);
            
            fetchFileSize(hdURL, completion: { [unowned self] (result) -> Void in
                
                    if let filesize = result {
                        self.hdFile?.fileSize = filesize

                    }
                    dispatch_group_leave(filesizeGroup);
                })
        }
        
        if let sdURL = sdFile?.remoteFileURL {
            dispatch_group_enter(filesizeGroup);
            
            fetchFileSize(sdURL, completion: { [unowned self] (result) -> Void in
                
                    if let filesize = result {
                        self.sdFile?.fileSize = filesize
                        
                    }
                    dispatch_group_leave(filesizeGroup);
                })
        }
        
        if let pdfURL = pdfFile?.remoteFileURL {
            dispatch_group_enter(filesizeGroup);
            
            fetchFileSize(pdfURL, completion: { [unowned self] (result) -> Void in

                if let filesize = result {
                        self.pdfFile?.fileSize = filesize
                        
                    }
                    dispatch_group_leave(filesizeGroup);
                })
        }
        
        if sampleCodeArray.count > 0 {
            for sample in sampleCodeArray {
                if let fileURL = sample.remoteFileURL {
                    
                    dispatch_group_enter(filesizeGroup);
                    
                    fetchFileSize(fileURL, completion: { (result) -> Void in
                        
                            if let filesize = result {
                                sample.fileSize = filesize
                                print("Sample Code FileSize - \(filesize)")
                            }
                            else {
                                print("NO RESULT")
                            }
                        
                            dispatch_group_leave(filesizeGroup);
                        })
                }
            }
        }
        
       
        dispatch_group_notify(filesizeGroup,dispatch_get_main_queue(),{ [unowned self] in
            
            self.isInfoComplete = true
            
            if let completionHandler = self.completionHandler {
                completionHandler(success: true)
            }
        });
        
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
    
    // MARK: - Directories
    func wwdcDirectory () -> String? {
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        
        guard let documentsDirectory = paths.first else { return nil }
        
        let path = "/WWDC"
        
        return createDirectoryIfNeeded(path, inDirectory: documentsDirectory)
    }
    
    func yearDirectory(year : WWDCYear) -> String? {
        
        guard let wwdcDirectory = wwdcDirectory()  else { return nil }
        
        var yearpath : String?
        
        switch year {
        case .WWDC2015:
            yearpath = "/2015"
        case .WWDC2014:
            yearpath = "/2014"
        }
        
        guard let path = yearpath else { return nil }
        
        return createDirectoryIfNeeded(path, inDirectory: wwdcDirectory)
    }

    
    func videoDirectory () -> String? {
        
        guard let wwdcDirectory = yearDirectory(sessionYear)  else { return nil }
        
        let path = "/Videos"
        
        return createDirectoryIfNeeded(path, inDirectory: wwdcDirectory)
    }
    
    func codeDirectory () -> String? {
        
        guard let wwdcDirectory = yearDirectory(sessionYear)  else { return nil }
        
        let path = "/Code Samples"
        
        return createDirectoryIfNeeded(path, inDirectory: wwdcDirectory)
    }
    
    func pdfDirectory () -> String? {
        
        guard let wwdcDirectory = yearDirectory(sessionYear)  else { return nil }
        
        let path = "/PDFs"
        
        return createDirectoryIfNeeded(path, inDirectory: wwdcDirectory)
    }
    
    class func sanitizeFileNameString(filename : String) -> String {
        let characters = NSCharacterSet(charactersInString: "/\\?%*|\"<>:")
        let components = filename.componentsSeparatedByCharactersInSet(characters) as NSArray
        return components.componentsJoinedByString("")
        
    }
    
    // MARK: Helper
    private func createDirectoryIfNeeded(directory : String, inDirectory: String) -> String? {
        
        let path = inDirectory.stringByAppendingPathComponent(directory)
        
        //var isDir = ObjCBool(true)
        
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: false, attributes: nil)
            }
            catch {
                print(error)
            }
        }
        return path
    }

    
}
