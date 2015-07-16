//
//  TranscriptPanelController.swift
//  WWDC
//
//  Created by David Roberts on 15/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa

class TranscriptPanelController : NSViewController {
    
	@IBOutlet weak var visualEffectView: NSVisualEffectView!
    @IBOutlet var textView: NSTextView!
	
	private var transcriptTextStorage : AnyObject!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		transcriptTextStorage = HighlightableTextStorage()

		if let layoutManager = textView.layoutManager {
			(transcriptTextStorage as! HighlightableTextStorage).addLayoutManager(layoutManager)
		}
	}

	func highlightText (searchString: String) {
		let transcriptTextStorage = self.transcriptTextStorage as! HighlightableTextStorage
		transcriptTextStorage.textToHighlight = searchString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
	}
	
    weak var wwdcSession : WWDCSession? {
        didSet {
            if let wwdcSession = wwdcSession {
				if let fullTranscriptPrettyPrint = wwdcSession.fullTranscriptPrettyPrint {
					self.textView.string = fullTranscriptPrettyPrint
				}
            }
        }
    }    
}