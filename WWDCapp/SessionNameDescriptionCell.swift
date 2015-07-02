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

	@IBOutlet var nameScrollView : NSScrollView!
	@IBOutlet var sessionName: NSTextView!

	@IBOutlet var descriptionField: NSTextField!
	
	var textStorage : AnyObject?
	
	override func awakeFromNib() {

		if #available(OSX 10.11, *) {
						
		    textStorage = HighlightableTextStorage()
			
			if let layoutManager = sessionName.layoutManager {
				(textStorage as! HighlightableTextStorage).addLayoutManager(layoutManager)
			}
		}
	}

	func resetCell() {
		
		
		if #available(OSX 10.11, *) {
			if let textStorage = textStorage as? HighlightableTextStorage {
				textStorage.replaceCharactersInRange(NSMakeRange(0, (sessionName.string?.characters.count)!), withString:"")
			}
		}
		else {
			textField!.stringValue = ""
		}
		
		descriptionField.stringValue = ""
		
	}
	
	func updateCell(name:String, description:String?, descriptionVisible:Bool) {
		
		if #available(OSX 10.11, *) {
			if let textStorage = textStorage as? HighlightableTextStorage {
				textStorage.replaceCharactersInRange(NSMakeRange(0, 0), withString:name)
			}
		}
		else {
			textField!.stringValue = name
		}
		
		if let description = description {
			descriptionField.stringValue = description
		}
		else {
			descriptionField.stringValue = ""
		}
		
		if descriptionVisible {
			
		}
		else {
			
			
		}
	}
	
}
