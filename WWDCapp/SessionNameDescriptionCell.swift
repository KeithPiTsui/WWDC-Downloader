//
//  SessionNameDescriptionCell.swift
//  WWDC
//
//  Created by David Roberts on 30/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa

class SessionNameDescriptionCell : NSTableCellView, NSTextViewDelegate {

    @IBOutlet var sessionName: IntrinsicContentNSTextView!
    @IBOutlet var sessionNameScrollView: NSScrollView!
    
    @IBOutlet var sessionDescriptionTextView: IntrinsicContentNSTextView!
    @IBOutlet var sessionDescriptionTextViewScrollView: NSScrollView!
    var nameTextStorage : AnyObject!
    var descriptionTextStorage : AnyObject!

	@IBOutlet var descriptionField: NSTextField! // pre 10.11
    
    var nameAttributes : [String : NSObject] {
        get {
            let pstyle = NSMutableParagraphStyle()
            pstyle.alignment = NSTextAlignment.Left
            pstyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
            let attributes = [ NSForegroundColorAttributeName : NSColor.labelColor(), NSParagraphStyleAttributeName : pstyle , NSFontAttributeName : NSFont.boldSystemFontOfSize(12.0)]
            return attributes
        }
    }
    
    var descriptionAttributesFull : [String : NSObject] {
        get {
            let pstyle = NSMutableParagraphStyle()
            pstyle.alignment = NSTextAlignment.Left
            pstyle.lineBreakMode = NSLineBreakMode.ByTruncatingTail
            let attributes = [ NSForegroundColorAttributeName : NSColor.labelColor(), NSParagraphStyleAttributeName : pstyle , NSFontAttributeName : NSFont.systemFontOfSize(12.0)]
            return attributes
        }
    }
	
	override func awakeFromNib() {

		// if #available(OSX 10.11, *) {
				
            textField!.stringValue = ""
            
            sessionName.verticallyResizable = false
            sessionDescriptionTextView.verticallyResizable = false
            
            sessionName.string = ""
            sessionName.typingAttributes = nameAttributes
            
            sessionDescriptionTextView.string = ""
            sessionDescriptionTextView.typingAttributes = descriptionAttributesFull
            
		    nameTextStorage = HighlightableTextStorage()
            descriptionTextStorage = HighlightableTextStorage()

			if let layoutManager = sessionName.layoutManager {
				(nameTextStorage as! HighlightableTextStorage).addLayoutManager(layoutManager)
			}
            if let layoutManager = sessionDescriptionTextView.layoutManager {
                (descriptionTextStorage as! HighlightableTextStorage).addLayoutManager(layoutManager)
            }
		//}
	}
	
	func updateCell(name:String, description:String?, descriptionVisible:Bool) {
		
		//    if #available(OSX 10.11, *) {
            sessionName.string = name
            
            if descriptionVisible {
                var attributes = sessionDescriptionTextView.typingAttributes
                if let pstyle = attributes[NSParagraphStyleAttributeName] as? NSMutableParagraphStyle {
                    pstyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
                    attributes[NSParagraphStyleAttributeName] = pstyle
                    sessionDescriptionTextView.typingAttributes = attributes
                }
            }
            else {
                var attributes = sessionDescriptionTextView.typingAttributes
                if let pstyle = attributes[NSParagraphStyleAttributeName] as? NSMutableParagraphStyle {
                    pstyle.lineBreakMode = NSLineBreakMode.ByTruncatingTail
                    attributes[NSParagraphStyleAttributeName] = pstyle
                    sessionDescriptionTextView.typingAttributes = attributes
                }
            }
            
            if let description = description {
                sessionDescriptionTextView.hidden = false
                sessionDescriptionTextView.string = description
              //  sessionDescriptionTextView.didChangeText()
            }
            else {
                sessionDescriptionTextView.hidden = true
                sessionDescriptionTextView.string = ""
              //  sessionDescriptionTextView.didChangeText()
            }
            
            if descriptionVisible {
                
                var scrollFrame = sessionDescriptionTextViewScrollView.frame
                var textviewFrame = sessionDescriptionTextView.frame
                scrollFrame.size.height = sessionDescriptionTextView.intrinsicContentSize.height
                textviewFrame.size.height = sessionDescriptionTextView.intrinsicContentSize.height
                sessionDescriptionTextViewScrollView.frame = scrollFrame
                sessionDescriptionTextView.frame = textviewFrame
            }
            else {
                
                var scrollFrame = sessionDescriptionTextViewScrollView.frame
                var textviewFrame = sessionDescriptionTextView.frame
                scrollFrame.size.height = 15
                textviewFrame.size.height = 15
                sessionDescriptionTextViewScrollView.frame = scrollFrame
                sessionDescriptionTextView.frame = textviewFrame
            }
		//}
//		else {
//			textField!.stringValue = name
//            
//            if let description = description {
//                descriptionField.stringValue = description
//            }
//            else {
//                descriptionField.stringValue = ""
//            }
//		}
	}
    
//  @available(OSX 10.11, *)
    func highlightText (searchString: String) {
        
        let nameTextStorage = self.nameTextStorage as! HighlightableTextStorage
        let descriptionTextStorage = self.descriptionTextStorage as! HighlightableTextStorage
        nameTextStorage.textToHighlight = searchString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        descriptionTextStorage.textToHighlight = searchString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }

	
}
