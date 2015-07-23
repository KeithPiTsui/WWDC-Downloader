//
//  SearchSuggestions.swift
//  WWDC
//
//  Created by David Roberts on 23/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa

protocol SearchSuggestionsDelegate {
	func didSelectSuggestion(suggestion : String)
}

class SearchSuggestions : NSView {
	
	var delegate : SearchSuggestionsDelegate?
	var contentSize : CGSize = CGSizeZero
	
	override var intrinsicContentSize : CGSize {
		get {
			return contentSize
		}
	}
	
	var suggestionsStringArray : [String]? {
		didSet {
			if let suggestionsStringArray = suggestionsStringArray {
								
				var xPosition : CGFloat = 10
				var height : CGFloat = 0
				
				for suggestion in suggestionsStringArray {
					
					let button = NSButton()
					button.title = suggestion
					button.setButtonType(NSButtonType.MomentaryLightButton)
					button.bordered = true
					button.target = self
					button.action = "suggestionSelected:"
					button.ignoresMultiClick = true
					button.bezelStyle = NSBezelStyle.InlineBezelStyle
					button.font = NSFont.systemFontOfSize(NSFont.systemFontSizeForControlSize(NSControlSize.MiniControlSize))
					
					button.sizeToFit()
					self.addSubview(button)
					
					var thisframe = button.frame
					thisframe.origin.x = xPosition
					thisframe.size.width += 10
					button.frame = thisframe
					
					xPosition = CGRectGetMaxX(button.frame)+10
					height = button.frame.height
				}
				
				contentSize = CGSizeMake(xPosition, height)
				
				self.invalidateIntrinsicContentSize()
			}
		}
	}
	
	
	func suggestionSelected(sender : NSButton) {
		if let delegate = delegate {
			delegate.didSelectSuggestion(sender.title)
		}
	}
	
}