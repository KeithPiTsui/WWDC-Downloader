//
//  DisabledScrollingScrollView.swift
//  WWDC
//
//  Created by David Roberts on 02/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa

class DisabledScrollingScrollView : NSScrollView {

    @IBOutlet var textView: IntrinsicContentNSTextView!

	required init?(coder: NSCoder) {
	    super.init(coder: coder)
		self.hideScrollers()
	}
	
	override func awakeFromNib() {
		 self.hideScrollers()
	}
	
	func hideScrollers() {
		
		self.hasHorizontalScroller = false
		self.hasVerticalScroller = false
	}
	
	override func scrollWheel(theEvent: NSEvent) {
		
		self.nextResponder?.scrollWheel(theEvent)
	}
	
	override func swipeWithEvent(event: NSEvent) {
		
		self.nextResponder?.swipeWithEvent(event)
	}
    
    override func mouseDown(theEvent: NSEvent) {
        
        self.nextResponder?.mouseDown(theEvent)
    }
    
    override var intrinsicContentSize : CGSize {
        get {
            return textView.intrinsicContentSize
        }
    }
}