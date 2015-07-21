//
//  SessionViewerController.swift
//  WWDC
//
//  Created by David Roberts on 20/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa
import AVKit
import Quartz
import AVFoundation

class ViewerPrimarySplitViewController : NSSplitViewController {
	
    weak var videoController : VideoViewController?
    weak var pdfController : PDFMainViewController?
    weak var transcriptController : TranscriptViewController?
    
	var wwdcSession : WWDCSession? {
		didSet {
			print(wwdcSession?.sessionID)
            
            if let wwdcSession = wwdcSession {
                
                self.view.window?.title = wwdcSession.title
                
                let splitItems = self.splitViewItems
                
                transcriptController = splitItems.last!.viewController as? TranscriptViewController
                
                if let transcriptController = transcriptController {
                    transcriptController.wwdcSession = wwdcSession
                }
                
                let viewerTopSplitController = splitItems.first!.viewController as! ViewerTopSplitViewController
                let topSplitItems = viewerTopSplitController.splitViewItems
                
                videoController = topSplitItems.first!.viewController as? VideoViewController
               // videoController.wwdcSession = wwdcSession
               
                let viewerPDFSplitController = topSplitItems.last!.viewController as! ViewerPDFSplitViewController
                let pdfSplitItems = viewerPDFSplitController.splitViewItems
                    
                pdfController = pdfSplitItems.first!.viewController as? PDFMainViewController
               // pdfController.wwdcSession = wwdcSession
                    
                let thumbnailMainViewController = pdfSplitItems.last!.viewController as! PDFThumbnailViewController
               // thumbnailMainViewController.thumbnailView.setPDFView(pdfController.pdfView)
            }
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
    
    weak var wwdcSession : WWDCSession?
    
	override func viewDidLoad() {
        super.viewDidLoad()

		avPlayerView.videoGravity = "AVLayerVideoGravityResizeAspect"
		avPlayerView.controlsStyle = AVPlayerViewControlsStyle.Floating
		avPlayerView.showsFullScreenToggleButton = true
       	
    }
    
    func loadVideo () {
        
        guard let wwdcSession = wwdcSession else { return }
        
        self.view.window?.title = wwdcSession.title
        
        var videoURL : NSURL?
        
        if let localFileURL = wwdcSession.hdFile?.localFileURL {
            videoURL = localFileURL
        }
        else {
            if let localFileURL = wwdcSession.sdFile?.localFileURL {
                videoURL = localFileURL
            }
        }
        
        guard let url = videoURL else { return }

        let asset = AVAsset(URL: url)
        let item = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: item)
        avPlayerView.player = player
    }
	
}

class PDFMainViewController : NSViewController {
	
	@IBOutlet weak var pdfView: PDFView!
	
    weak var wwdcSession : WWDCSession? {
        didSet {
            if let localFileURL = wwdcSession?.pdfFile?.localFileURL {
                let document = PDFDocument(URL: localFileURL)
                pdfView.setDocument(document)
            }
        }
    }
    
	override func viewDidLoad() {
        super.viewDidLoad()
	}
}

class PDFThumbnailViewController : NSViewController {
	
	@IBOutlet weak var thumbnailView: PDFThumbnailView!
	
	override func viewDidLoad() {
        super.viewDidLoad()

	}
}


