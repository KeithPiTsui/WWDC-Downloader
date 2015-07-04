//
//  SessionNameDescriptionCell.swift
//  WWDC
//
//  Created by David Roberts on 30/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa

class SessionNameDescriptionCell : NSTableCellView {

    @IBOutlet var sessionName: IntrinsicContentNSTextView!
    @IBOutlet var sessionNameScrollView: NSScrollView!
    
    @IBOutlet var sessionDescriptionTextView: IntrinsicContentNSTextView!
    @IBOutlet var sessionDescriptionTextViewScrollView: NSScrollView!
    var nameTextStorage : AnyObject!
    var descriptionTextStorage : AnyObject!

	@IBOutlet var descriptionField: NSTextField! // pre 10.11
	
	override func awakeFromNib() {

        if #available(OSX 10.11, *) {
				
            textField!.stringValue = ""

            let pstyle = NSMutableParagraphStyle()
            pstyle.alignment = NSTextAlignment.Left
            let attributes = [ NSForegroundColorAttributeName : NSColor.labelColor(), NSParagraphStyleAttributeName : pstyle , NSFontAttributeName : NSFont.boldSystemFontOfSize(12.0)]
            
            sessionName.string = ""
            sessionName.typingAttributes = attributes
            
            
            let descriptionAttributes = [ NSForegroundColorAttributeName : NSColor.labelColor(), NSParagraphStyleAttributeName : pstyle , NSFontAttributeName : NSFont.systemFontOfSize(12.0)]
            
            sessionDescriptionTextView.string = ""
            sessionDescriptionTextView.typingAttributes = descriptionAttributes
            
            sessionName.didChangeText()
            sessionDescriptionTextView.didChangeText()


		    nameTextStorage = HighlightableTextStorage()
            descriptionTextStorage = HighlightableTextStorage()

			if let layoutManager = sessionName.layoutManager {
				(nameTextStorage as! HighlightableTextStorage).addLayoutManager(layoutManager)
			}
            if let layoutManager = sessionDescriptionTextView.layoutManager {
                (descriptionTextStorage as! HighlightableTextStorage).addLayoutManager(layoutManager)
            }
		}
	}
	
	func updateCell(name:String, description:String?, descriptionVisible:Bool) {
		
        if #available(OSX 10.11, *) {
            sessionName.string = name
            sessionName.didChangeText()
            
            if let description = description {
                sessionDescriptionTextView.hidden = false
                sessionDescriptionTextView.string = description
            }
            else {
                sessionDescriptionTextView.hidden = true
                sessionDescriptionTextView.string = ""
            }
            
            sessionDescriptionTextView.didChangeText()
            
            var frame = sessionDescriptionTextViewScrollView.frame
            frame.size.height = sessionDescriptionTextViewScrollView.intrinsicContentSize.height
            sessionDescriptionTextViewScrollView.frame = frame
        }
		else {
			textField!.stringValue = name
            
            if let description = description {
                descriptionField.stringValue = description
            }
            else {
                descriptionField.stringValue = ""
            }
		}
				
		if descriptionVisible {
			
		}
		else {
			
			
		}
	}
    
    @available(OSX 10.11, *)
    func highlightText (searchString: String) {
        
        let nameTextStorage = self.nameTextStorage as! HighlightableTextStorage
        let descriptionTextStorage = self.descriptionTextStorage as! HighlightableTextStorage
        nameTextStorage.textToHighlight = searchString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        descriptionTextStorage.textToHighlight = searchString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }

	
}
