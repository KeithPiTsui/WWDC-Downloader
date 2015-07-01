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
	
	class func merge(pdfs : [NSURL], year : WWDCYear) -> NSURL? {
		
		if pdfs.count == 0 { return nil }
	
		guard let directory = FileInfo.pdfDirectory(year) else { return nil }
		
		let outputPath = directory.stringByAppendingPathComponent("/\(year.description)-Combined-PDF.pdf")
		
		let outputURL = NSURL.fileURLWithPath(outputPath)
		
		guard let writeContext = CGPDFContextCreateWithURL(outputURL, nil, nil) else { return nil }

		print("Creating Enormous Combined PDF document...")
		
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
				}
			}
		}
		
		CGPDFContextClose(writeContext)
		
		print("Finishing \(year.description) Combined PDF Document")

		return outputURL
	}
	
}