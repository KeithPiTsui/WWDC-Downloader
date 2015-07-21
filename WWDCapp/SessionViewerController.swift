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

class SessionViewerWindowController : NSWindowController, NSWindowDelegate {
	
	weak var videoController : VideoViewController!
	weak var pdfController : PDFMainViewController!
	weak var transcriptController : TranscriptViewController!

	weak var topSplitViewController : ViewerTopSplitViewController!

	@IBOutlet weak var segmentedPaneControl: NSSegmentedControl!
	@IBOutlet weak var titleLabel: NSTextField!
	
	override func windowDidLoad() {
		
		if let contentViewController = self.contentViewController as? ViewerPrimarySplitViewController {
			
			let splitItems = contentViewController.splitViewItems
			
			transcriptController = splitItems.last!.viewController as? TranscriptViewController
			
			topSplitViewController = splitItems.first!.viewController as! ViewerTopSplitViewController
			let topSplitItems = topSplitViewController.splitViewItems
			
			videoController = topSplitItems.first!.viewController as? VideoViewController
			
			let viewerPDFSplitController = topSplitItems.last!.viewController as! ViewerPDFSplitViewController
			let pdfSplitItems = viewerPDFSplitController.splitViewItems
			
			pdfController = pdfSplitItems.first!.viewController as? PDFMainViewController
			
			let thumbnailMainViewController = pdfSplitItems.last!.viewController as! PDFThumbnailViewController
			 thumbnailMainViewController.thumbnailView.setPDFView(pdfController.pdfView)
		}
		
		if let window = self.window {
			
			window.styleMask |= NSFullSizeContentViewWindowMask
			window.titlebarAppearsTransparent = false
			window.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
			
			window.titleVisibility = NSWindowTitleVisibility.Hidden
			
		}
		
		segmentedPaneControl.setImage(NSImage(imageLiteral: "bottom_button")?.tintImageToBrightBlurColor(), forSegment: 0)
		segmentedPaneControl.setImage(NSImage(imageLiteral: "pdf_Button")?.tintImageToBrightBlurColor(), forSegment: 1)

	}


	@IBAction func toggleView(sender:NSSegmentedControl)  {

		guard let primarySplitViewController = self.contentViewController as? ViewerPrimarySplitViewController else { return }

		if sender.selectedSegment == 0 {

			let splitItems = primarySplitViewController.splitViewItems
			
			if splitItems.last!.collapsed == true {
				splitItems.last!.animator().collapsed = false
				
				sender.setImage(NSImage(imageLiteral: "bottom_button")?.tintImageToBrightBlurColor(), forSegment: 0)
			}
			else {
				splitItems.last!.animator().collapsed = true
				
				sender.setImage(NSImage(imageLiteral: "bottom_button"), forSegment: 0)
			}
		}
		
		if sender.selectedSegment == 1 {
			
			let splitItems = topSplitViewController.splitViewItems
			
			if splitItems.last!.collapsed == true {
				splitItems.last!.animator().collapsed = false
				
				sender.setImage(NSImage(imageLiteral: "pdf_Button")?.tintImageToBrightBlurColor(), forSegment: 1)
			}
			else {
				splitItems.last!.animator().collapsed = true
				
				sender.setImage(NSImage(imageLiteral: "pdf_Button"), forSegment: 1)
			}
		}
	}
    
    func windowShouldClose(sender: AnyObject) -> Bool {
        videoController.avPlayerView.player?.pause()
        videoController.avPlayerView.player = nil
        return true
    }
}

class ViewerPrimarySplitViewController : NSSplitViewController {

}

class ViewerTopSplitViewController : NSSplitViewController {

}

class ViewerPDFSplitViewController : NSSplitViewController {
	
}

class TranscriptViewController : NSViewController, NSTextFinderClient {
	
	@IBOutlet var textView: NSTextView!
	
	@IBOutlet weak var scrollView: NSScrollView!
	
	@IBOutlet var textFinder: NSTextFinder!
	
	private var transcriptTextStorage : AnyObject!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		textView.usesFindBar = true
		textView.incrementalSearchingEnabled = true
		scrollView.findBarPosition = NSScrollViewFindBarPosition.AboveContent
		textFinder.performAction(NSTextFinderAction.ShowFindInterface)

		

	}
	
	
	weak var wwdcSession : WWDCSession? {
		didSet {
			if let wwdcSession = wwdcSession {
				if let fullTranscriptPrettyPrint = wwdcSession.fullTranscriptPrettyPrint {
					self.textView.string = fullTranscriptPrettyPrint
				}
				else {
					self.textView.string = ""
				}
			}
		}
	}

}

class VideoViewController : NSViewController {

	@IBOutlet weak var avPlayerView: AVPlayerView!
    
	@IBOutlet weak var noVideoLabel: NSTextField!
	
	weak var wwdcSession : WWDCSession? {
		didSet {
			loadVideo()
		}
	}
	
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
        
        if let localFileURL = wwdcSession.hdFile?.localFileURL where wwdcSession.hdFile?.isFileAlreadyDownloaded == true  {
            videoURL = localFileURL
        }
        else {
            if let localFileURL = wwdcSession.sdFile?.localFileURL where wwdcSession.sdFile?.isFileAlreadyDownloaded == true {
                videoURL = localFileURL
            }
        }
        
        guard let url = videoURL else {
		
			if let _ = avPlayerView.player?.currentItem {
				avPlayerView.player?.pause()
				avPlayerView.player = nil
			}
			
            avPlayerView.controlsStyle = AVPlayerViewControlsStyle.None
			noVideoLabel.animator().alphaValue = 1
			
			return
		}
		
		noVideoLabel.animator().alphaValue = 0
		
		avPlayerView.controlsStyle = AVPlayerViewControlsStyle.Floating

		let asset = AVAsset(URL: url)
		let newItem = AVPlayerItem(asset: asset)
		
		if let _ = avPlayerView.player?.currentItem {
			avPlayerView.player?.replaceCurrentItemWithPlayerItem(newItem)
		}
		else {
			avPlayerView.player = AVPlayer(playerItem:newItem)
			avPlayerView.player?.play()
		}
		

    }
	
}

class PDFMainViewController : NSViewController {
	
	@IBOutlet weak var pdfView: PDFView!
	@IBOutlet weak var noPDFLabel: NSTextField!
	
    weak var wwdcSession : WWDCSession? {
        didSet {
            if let localFileURL = wwdcSession?.pdfFile?.localFileURL {
                let document = PDFDocument(URL: localFileURL)
                pdfView.setDocument(document)
				
				noPDFLabel.animator().alphaValue = 0
            }
			else {
				noPDFLabel.animator().alphaValue = 1
				pdfView.setDocument(nil)

			}
        }
    }
    
	override func viewDidLoad() {
        super.viewDidLoad()
		
		pdfView.setBackgroundColor(NSColor.blackColor())
	}
}

class PDFThumbnailViewController : NSViewController {
	
	@IBOutlet weak var thumbnailView: PDFThumbnailView!
	
	override func viewDidLoad() {
        super.viewDidLoad()

	}
}


