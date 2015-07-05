//
//  HighlightableTextStorage.swift
//  WWDC
//
//  Created by David Roberts on 02/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa

@available(OSX 10.11, *)
class HighlightableTextStorage : NSTextStorage {
	
	var textToHighlight : String = ""
	
    private var tmpString = NSMutableAttributedString()
	
	override var string : String {
		get {
			return self.tmpString.string
		}
	}
	
	override func attributesAtIndex(location: Int, effectiveRange range: NSRangePointer) -> [String : AnyObject] {
		
		return tmpString.attributesAtIndex(location, effectiveRange: range)
	}
	
	override init() {
		
		super.init()
        
        tmpString = NSMutableAttributedString()
	}
	
	override func replaceCharactersInRange(range: NSRange, withString str: String) {
		
		tmpString.replaceCharactersInRange(range, withString: str)
		
		self.edited(NSTextStorageEditActions.EditedCharacters, range: range, changeInLength: str.characters.count-range.length)
	}
	
	override func setAttributes(attrs: [String : AnyObject]?, range: NSRange) {
		
		tmpString.setAttributes(attrs, range: range)
		
		self.edited(NSTextStorageEditActions.EditedAttributes, range: range, changeInLength: 0)
		
	}
	
	override func processEditing() {
			
		let paragraphRange = (self.string as NSString).paragraphRangeForRange(self.editedRange)
		self.removeAttribute(NSForegroundColorAttributeName, range: paragraphRange)		
		
		do {
			let expression =  try NSRegularExpression(pattern: textToHighlight, options: NSRegularExpressionOptions.CaseInsensitive)
			
			expression.enumerateMatchesInString(self.string, options: NSMatchingOptions.ReportProgress, range: paragraphRange, usingBlock: { (result, _, _) -> Void in
				
				if let result = result {
					self.addAttribute(NSBackgroundColorAttributeName, value: NSColor.yellowColor(), range: result.range)
				}
			})
			
		}
		catch {
			
		}
		
		super.processEditing()
	}
	

	required init?(pasteboardPropertyList propertyList: AnyObject, ofType type: String) {
		//fatalError("init(pasteboardPropertyList:ofType:) has not been implemented")
		super.init(pasteboardPropertyList: propertyList, ofType: type)
	}

	required init?(coder aDecoder: NSCoder) {
		// fatalError("init(coder:) has not been implemented")
		super.init(coder: aDecoder)
	}
	
}