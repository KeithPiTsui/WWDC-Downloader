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
	
	@IBOutlet var transcriptSearchCountLabel : NSTextField!

    private var nameTextStorage : HighlightableTextStorage!
    private var descriptionTextStorage : HighlightableTextStorage!
	
	override var backgroundStyle : NSBackgroundStyle {
		didSet {
			sessionName.textColor = (backgroundStyle == NSBackgroundStyle.Light ? NSColor.labelColor() : NSColor.whiteColor())
			sessionDescriptionTextView.textColor = (backgroundStyle == NSBackgroundStyle.Light ? NSColor.labelColor() : NSColor.whiteColor())
			sessionName.needsDisplay = true
			sessionDescriptionTextView.needsDisplay = true
		}
	}
    
    var nameAttributes : [String : NSObject] {
        get {
            let pstyle = NSMutableParagraphStyle()
            pstyle.alignment = NSTextAlignment.Left
            pstyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
            let attributes = [ NSParagraphStyleAttributeName : pstyle , NSFontAttributeName : NSFont.boldSystemFontOfSize(12.0)]
            return attributes
		}
    }
    
    var descriptionAttributesFull : [String : NSObject] {
        get {
            let pstyle = NSMutableParagraphStyle()
            pstyle.alignment = NSTextAlignment.Left
            pstyle.lineBreakMode = NSLineBreakMode.ByTruncatingTail
            let attributes = [ NSParagraphStyleAttributeName : pstyle , NSFontAttributeName : NSFont.systemFontOfSize(12.0)]
            return attributes
        }
    }
	
	override func awakeFromNib() {
        
        sessionName.verticallyResizable = false
        sessionDescriptionTextView.verticallyResizable = false
		
        sessionName.string = ""
        sessionName.typingAttributes = nameAttributes
		sessionName.didChangeText()
		
        sessionDescriptionTextView.string = ""
        sessionDescriptionTextView.typingAttributes = descriptionAttributesFull
		sessionDescriptionTextView.didChangeText()
		
		transcriptSearchCountLabel.stringValue = ""

        nameTextStorage = HighlightableTextStorage()
        descriptionTextStorage = HighlightableTextStorage()

        if let layoutManager = sessionName.layoutManager {
            nameTextStorage.addLayoutManager(layoutManager)
        }
        if let layoutManager = sessionDescriptionTextView.layoutManager {
            descriptionTextStorage.addLayoutManager(layoutManager)
        }
	}
	
	func updateCell(name:String, description:String?, descriptionVisible:Bool, searchActive:Bool, searchCount:Int) {
		
		sessionName.textColor = NSColor.labelColor()
		sessionDescriptionTextView.textColor = NSColor.labelColor()
		
        sessionName.string = name
		sessionName.didChangeText()
		
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
            sessionDescriptionTextView.didChangeText()
        }
        else {
            sessionDescriptionTextView.hidden = true
            sessionDescriptionTextView.string = ""
            sessionDescriptionTextView.didChangeText()
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
		
		if searchActive {
			transcriptSearchCountLabel.stringValue = "Nº found in transcript: \(searchCount)"
		}
		else {
			transcriptSearchCountLabel.stringValue = ""
		}
	}
    
    func highlightText (searchString: String) {
        nameTextStorage.textToHighlight = searchString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        descriptionTextStorage.textToHighlight = searchString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
}
