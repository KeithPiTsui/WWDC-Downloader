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
import AVFoundation

class ViewerPrimarySplitViewController : NSSplitViewController {
	
	var wwdcSession : WWDCSession? {
		didSet {
			print(wwdcSession?.sessionID)
            
            if let wwdcSession = wwdcSession {
                
                self.view.window?.title = wwdcSession.title
                
                let splitItems = self.splitViewItems
                
                let transcriptController = splitItems.last!.viewController as! TranscriptViewController
                
                transcriptController.wwdcSession = wwdcSession
                
                let viewerTopSplitController = splitItems.first!.viewController as! ViewerTopSplitViewController
                
                let topSplitItems = viewerTopSplitController.splitViewItems
                
                let videoController = topSplitItems.first!.viewController as! VideoViewController
                
                if let localFileURL = wwdcSession.hdFile?.localFileURL {
                    videoController.videoURL = localFileURL
                }
                else {
                    if let localFileURL = wwdcSession.sdFile?.localFileURL {
                        videoController.videoURL = localFileURL
                    }
                }
                
                if let localFileURL = wwdcSession.pdfFile?.localFileURL {
                    
                    let viewerPDFSplitController = topSplitItems.last!.viewController as! ViewerPDFSplitViewController
                    let pdfSplitItems = viewerPDFSplitController.splitViewItems
                    
                    
                    let pdfMainViewController = pdfSplitItems.first!.viewController as! PDFMainViewController
                    pdfMainViewController.pdfURL = localFileURL
                    
                    let thumbnailMainViewController = pdfSplitItems.last!.viewController as! PDFThumbnailViewController
                    thumbnailMainViewController.thumbnailView.setPDFView(pdfMainViewController.pdfView)
                }
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
    
    var videoURL : NSURL?{
        didSet {
            if let videoURL = videoURL{
                let asset = AVAsset(URL: videoURL)
                let item = AVPlayerItem(asset: asset)
                let player = AVPlayer(playerItem: item)
                
                avPlayerView.player = player
            }
        }
    }
	
	override func viewDidLoad() {

		avPlayerView.videoGravity = "AVLayerVideoGravityResizeAspect"
		avPlayerView.controlsStyle = AVPlayerViewControlsStyle.Floating
		avPlayerView.showsFullScreenToggleButton = true
       	
    }
	
}

class PDFMainViewController : NSViewController {
	
	@IBOutlet weak var pdfView: PDFView!
	
    var pdfURL : NSURL?{
        didSet {
            if let pdfURL = pdfURL {
                let document = PDFDocument(URL: pdfURL)
                pdfView.setDocument(document)
            }
        }
    }
    
	override func viewDidLoad() {

	}
}

class PDFThumbnailViewController : NSViewController {
	
	@IBOutlet weak var thumbnailView: PDFThumbnailView!
	
	override func viewDidLoad() {
		
	}
}


