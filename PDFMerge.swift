//
//  PDFMerge.swift
//  WWDC
//
//  Created by David Roberts on 01/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import CoreGraphics

class PDFMerge : NSObject {
	
    class func merge(pdfs : [NSURL], year : WWDCYear, progressHandler:((numberProcessed: Int) -> Void), completionHandler :(url: NSURL?) -> ()) {
		
        if pdfs.count == 0 { completionHandler(url: nil); return}
	
        guard let directory = FileInfo.yearDirectory(year) else { completionHandler(url: nil); return }
		
		let outputPath = directory.stringByAppendingPathComponent("/\(year.description)-Combined-PDF.pdf")
		
		let outputURL = NSURL.fileURLWithPath(outputPath)
		
        guard let writeContext = CGPDFContextCreateWithURL(outputURL, nil, nil) else { completionHandler(url: nil); return }

		print("Creating Enormous Combined PDF document...")
		
		var numberOfPDFsProcessed = 0
		
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {

                for url in pdfs {
                    
                    autoreleasepool {
                        if let doc = CGPDFDocumentCreateWithURL(url as CFURL) {
                            
                            let numberOfPages = CGPDFDocumentGetNumberOfPages(doc)
                            
                            for var index = 0; index < numberOfPages; ++index {
                                
                                if let page = CGPDFDocumentGetPage(doc, index) {
                                    var rect = CGPDFPageGetBoxRect(page, CGPDFBox.CropBox)
                                    CGContextBeginPage(writeContext, &rect)
                                    CGContextDrawPDFPage(writeContext, page)
                                    CGContextEndPage(writeContext)
                                }
                            }
							
							numberOfPDFsProcessed++
							
							dispatch_async(dispatch_get_main_queue()) {
								progressHandler(numberProcessed: numberOfPDFsProcessed)
							}
                        }
                    }
                }
            
                CGPDFContextClose(writeContext)
                
                print("Finishing \(year.description) Combined PDF Document")
            
                dispatch_async(dispatch_get_main_queue()) {
                    completionHandler(url: outputURL)
                }
            })
	}
	
}