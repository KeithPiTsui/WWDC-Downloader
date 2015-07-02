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

	@IBOutlet var sessionName: NSTextView!
    @IBOutlet var sessionDescriptionTextView: NSTextView!

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

	func resetCell() {
		
		if #available(OSX 10.11, *) {
            sessionName.string = ""
            sessionDescriptionTextView.string = ""
        }
        else {
			textField!.stringValue = ""
            descriptionField.stringValue = ""
		}
	}
	
	func updateCell(name:String, description:String?, descriptionVisible:Bool) {
		
		if #available(OSX 10.11, *) {
            sessionName.string = name
            if let description = description {
                sessionDescriptionTextView.string = description
            }
            else {
                sessionDescriptionTextView.string = ""
            }
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
	
}
