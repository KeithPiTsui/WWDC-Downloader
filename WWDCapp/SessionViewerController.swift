//
//  ViewerController.swift
//  WWDC
//
//  Created by David Roberts on 20/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa
import AVKit
import Quartz

class ViewerPrimarySplitViewController : NSSplitViewController {
	
	var wwdcSession : WWDCSession? {
		didSet {
			print(wwdcSession?.sessionID)
			
			let splitItems = self.splitViewItems
			
			let transcriptController = splitItems.last!.viewController as! TranscriptViewController
			
			transcriptController.wwdcSession = wwdcSession
			
			let viewerTopSplitController = splitItems.first!.viewController as! ViewerTopSplitViewController
			
			let topSplitItems = viewerTopSplitController.splitViewItems
			
			
			let videoController = topSplitItems.first!.viewController as! VideoViewController
			
			videoController.avPlayerView

		}
	}

}

class ViewerTopSplitViewController : NSSplitViewController {
	
}

class ViewerPDFSplitViewController : NSSplitViewController {
	
}

class TranscriptViewController : NSViewController {
	
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

class VideoViewController : NSViewController {

	@IBOutlet weak var avPlayerView: AVPlayerView!
	
	override func viewDidLoad() {

		avPlayerView.videoGravity = "AVLayerVideoGravityResizeAspect"
		avPlayerView.controlsStyle = AVPlayerViewControlsStyle.Floating
		avPlayerView.showsFullScreenToggleButton = true
		
	}
	
	
}

class PDFMainViewController : NSViewController {
	
	@IBOutlet weak var pdfView: PDFView!
	
	override func viewDidLoad() {

	}
}

class PDFThumbnailViewController : NSViewController {
	
	@IBOutlet weak var thumbnailView: PDFThumbnailView!
	
	
	override func viewDidLoad() {
		
	}
}


