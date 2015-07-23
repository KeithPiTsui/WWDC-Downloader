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
		
	var suggestionsStringArray : [String]? {
		didSet {
			if let suggestionsStringArray = suggestionsStringArray {
				for suggestion in suggestionsStringArray {
					
					let button = NSButton()
					button.title = suggestion
					button.sizeToFit()
					button.setButtonType(NSButtonType.MomentaryLightButton)
					button.bordered = true
					button.target = self
					button.action = "suggestionSelected:"
					button.ignoresMultiClick = true
					self.addSubview(button)
				}
			}
		}
	}
	
	private func suggestionSelected(sender : NSButton) {
		if let delegate = delegate {
			delegate.didSelectSuggestion(sender.title)
		}
	}
	
}