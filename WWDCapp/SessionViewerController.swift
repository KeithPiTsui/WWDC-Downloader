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
import CoreGraphics
import WebKit

let SessionViewerDidLaunchNotification = "SessionViewerDidLaunchNotification"
let SessionViewerDidCloseNotification = "SessionViewerDidCloseNotification"

// MARK: WindowController
class SessionViewerWindowController : NSWindowController, NSWindowDelegate {
	
	weak var videoController : VideoViewController!
	weak var pdfController : PDFMainViewController!
	weak var transcriptController : TranscriptViewController!

	weak var topSplitViewController : ViewerTopSplitViewController!

	@IBOutlet weak var segmentedPaneControl: NSSegmentedControl!
	@IBOutlet weak var titleLabel: NSTextField!
    
    private var eventMonitor : AnyObject?
	
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
            
            transcriptController.seekToTimeCodeCallBack = { [unowned self] (timeCode:Double) in
                self.videoController.seekToTimeCode(timeCode)
            }
            
            videoController.highlightLineInTranscriptCallBack = { [unowned self] (timeString: String) in
                self.transcriptController.highlightLineat(timeString)
            }
        }
		
		if let window = self.window {
			
			//window.styleMask |= NSFullSizeContentViewWindowMask
			window.titlebarAppearsTransparent = false
			window.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
			
			window.titleVisibility = NSWindowTitleVisibility.Hidden
		}
		
		segmentedPaneControl.setImage(NSImage(named: "bottom_button")?.tintImageToBrightBlurColor(), forSegment: 0)
		segmentedPaneControl.setImage(NSImage(named: "pdf_Button")?.tintImageToBrightBlurColor(), forSegment: 1)
        
        NSNotificationCenter.defaultCenter().postNotificationName(SessionViewerDidLaunchNotification, object: nil)

        
        eventMonitor = NSEvent.addLocalMonitorForEventsMatchingMask([NSEventMask.KeyDownMask, NSEventMask.FlagsChangedMask] ) { [unowned self] (event) -> NSEvent? in
            
            if let thisWindow = self.window {
                if event.window == thisWindow {
                    if event.type == NSEventType.KeyDown {
                        let flags = event.modifierFlags.rawValue & NSEventModifierFlags.DeviceIndependentModifierFlagsMask.rawValue
                        if flags == NSEventModifierFlags.CommandKeyMask.rawValue {
                            switch event.charactersIgnoringModifiers! {
                            case "f":
                                dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                                    if self.transcriptController.searchFieldHasFocus {
                                        self.transcriptController.searchField.stringValue = ""
                                        self.transcriptController.searchEntered(self.transcriptController.searchField)
                                        self.transcriptController.webview?.becomeFirstResponder()
                                        self.transcriptController.searchFieldHasFocus = false
                                    }
                                    else {
                                        self.transcriptController.searchField.becomeFirstResponder()
                                        self.transcriptController.searchFieldHasFocus = true
                                    }
                                }
                                return nil
                            default:
                                break
                            }
                        }
                        
                        switch event.charactersIgnoringModifiers! {
                            case "\r":
                                if self.transcriptController.searchFieldHasFocus && self.transcriptController.numberOfStringsFound > 0 {
                                    dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                                        self.transcriptController.findSegmented.trackingMode = NSSegmentSwitchTracking.SelectOne
                                        self.transcriptController.findSegmented.selectedSegment = 1
                                        self.transcriptController.findSegmented.setSelected(true, forSegment: 1)
                                        self.transcriptController.scrollItem(self.transcriptController.findSegmented)
                                        self.transcriptController.findSegmented.setSelected(false, forSegment: 1)
                                        self.transcriptController.findSegmented.trackingMode = NSSegmentSwitchTracking.Momentary
                                        self.transcriptController.findSegmented.selectedSegment = -1
                                    }
                                    return nil
                                }
                            default:
                                break
                        }
                    }
                }
            }
            return event
        }
        
    }
    


	@IBAction func toggleView(sender:NSSegmentedControl)  {

		guard let primarySplitViewController = self.contentViewController as? ViewerPrimarySplitViewController else { return }

		if sender.selectedSegment == 0 {

			let splitItems = primarySplitViewController.splitViewItems
			
			if splitItems.last!.collapsed == true {
				splitItems.last!.animator().collapsed = false
				
				sender.setImage(NSImage(named: "bottom_button")?.tintImageToBrightBlurColor(), forSegment: 0)
			}
			else {
				splitItems.last!.animator().collapsed = true
				
				sender.setImage(NSImage(named: "bottom_button"), forSegment: 0)
			}
		}
		
		if sender.selectedSegment == 1 {
			
			let splitItems = topSplitViewController.splitViewItems
			
			if splitItems.last!.collapsed == true {
				splitItems.last!.animator().collapsed = false
				
				sender.setImage(NSImage(named: "pdf_Button")?.tintImageToBrightBlurColor(), forSegment: 1)
			}
			else {
				splitItems.last!.animator().collapsed = true
				
				sender.setImage(NSImage(named: "pdf_Button"), forSegment: 1)
			}
		}
	}
	
//	@IBAction func toggleFloatNnTop(menu : NSMenu) {
//		
//		if let window = self.window {
//			
//			window.level = Int32(CGWindowLevelForKey(FloatingWindowLevelKey))
//
//		}
//		
//	}
	
    func windowShouldClose(sender: AnyObject) -> Bool {
		
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        
		videoController.unloadPlayer()
		
        NSNotificationCenter.defaultCenter().postNotificationName(SessionViewerDidCloseNotification, object: nil)

        return true
    }
}

class ViewerPrimarySplitViewController : NSSplitViewController {

}

class ViewerTopSplitViewController : NSSplitViewController {

}

class ViewerPDFSplitViewController : NSSplitViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		NSNotificationCenter.defaultCenter().addObserverForName(NSWindowDidEnterFullScreenNotification, object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
			
			if  let window = self.view.window, let item = self.splitViewItems.last where window == notification.object as? NSWindow {
				item.collapsed = true
			}
		}
		
		NSNotificationCenter.defaultCenter().addObserverForName(NSWindowDidExitFullScreenNotification, object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
			if  let window = self.view.window, let item = self.splitViewItems.last where window == notification.object as? NSWindow {
				item.collapsed = false
			}
		}
	}
}

// MARK: - Transcript
class TranscriptViewController : NSViewController, NSTextFinderClient, WKScriptMessageHandler, NSSearchFieldDelegate {
    
    weak var wwdcSession : WWDCSession?

    @IBOutlet weak var webViewContainerForIBContraintSetting : NSView!
    var webview : WKWebView?
    
	@IBOutlet weak var autoScrollingCheckbox: NSButton!
	@IBOutlet weak var searchField : NSSearchField!
    @IBOutlet weak var findSegmented : NSSegmentedControl!
    @IBOutlet weak var matchesLabel : NSTextField!
	
    var searchFieldHasFocus = false
    
    var numberOfStringsFound :Int = 0
    
	var seekToTimeCodeCallBack : ((timeCode: Double) -> Void)?
	
    private var transcriptConfiguration : WKWebViewConfiguration {
        get {
            
            let configuration = WKWebViewConfiguration()
            let contentController = WKUserContentController();
                        
            if let resourcePath = NSBundle.mainBundle().pathForResource("transcript", ofType: "js") {
                do {
                    let script = try String(contentsOfFile: resourcePath, encoding: NSUTF8StringEncoding)
                    let userScript =  WKUserScript(source: script, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
                    contentController.addUserScript(userScript)
                }
                catch {
                    print(error)
                }
            }

            contentController.addScriptMessageHandler(self, name: "callbackHandler")

            configuration.userContentController = contentController
            
            return configuration
        }
    }
    
    private var transcriptURL : NSURL? {
        get {
            let resource = NSBundle.mainBundle().URLForResource("transcript", withExtension: "html")
            if let resource = resource {
                return resource
            }
            return nil
        }
    }
    
    private var baseURL : NSURL? {
        get {
            if let path = transcriptURL?.path {
                return NSURL.fileURLWithPath((path as NSString).stringByDeletingLastPathComponent)
            }
            return nil
        }
    }
    
    // MARK: Actions
    @IBAction func enableAutoScroll(sender : NSButton) {
        
        if sender.state == 1 {
            webview?.evaluateJavaScript("setAutoScrollEnabled(true)" as String) { (object, error) -> Void in
                
            }
        }
        else {
            webview?.evaluateJavaScript("setAutoScrollEnabled(false)" as String) { (object, error) -> Void in
                
            }
        }
    }
    
    @IBAction func searchEntered(sender: NSSearchField) {
        
        numberOfStringsFound = 0
        
        if sender.stringValue.isEmpty == true {
            findSegmented.enabled = false
        }
        else {
            autoScrollingCheckbox.state = 0
            enableAutoScroll(autoScrollingCheckbox)
            findSegmented.enabled = true
        }
        
        searchFor(sender.stringValue)
    }
    
    @IBAction func scrollItem(sender : NSSegmentedControl) {
        
        if sender.selectedSegment == 0 {
            webview?.evaluateJavaScript("previousItem()") { (object, error) -> Void in
                //print(error)
            }
        }
        if sender.selectedSegment == 1 {
            webview?.evaluateJavaScript("nextItem()") { (object, error) -> Void in
                //print(error)
            }
        }
    }
    
    
	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
    
    // MARK: View
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.layer?.backgroundColor = NSColor.whiteColor().CGColor
        
        autoScrollingCheckbox.state = 0
        
        findSegmented.enabled = false
        
        matchesLabel.stringValue = ""
        
        webview = WKWebView(frame: CGRectZero, configuration: transcriptConfiguration)
        
        if let webview = webview {
            webViewContainerForIBContraintSetting.addSubviewWithContentHugging(webview)
            
            loadSessionTranscript()
        }
    }
    
    func loadSessionTranscript() {
        
        if let wwdcSession = wwdcSession {
            if let html = wwdcSession.transcriptHTMLFormatted, let base = baseURL, let transcript = transcriptURL  {
                do {
                    let baseString = try NSString(contentsOfURL: transcript, encoding: NSUTF8StringEncoding)
                    let fullPage = NSString(format: baseString, html)
                    webview?.loadHTMLString(fullPage as String, baseURL: base)
                }
                catch {
                    print(error)
                }
            }
        }
    }
	
	func highlightLineat(roundedTimeCode: String) {
		
		let script = NSString(format: "highlightLineWithTimecode('%@')", roundedTimeCode)
		webview?.evaluateJavaScript(script as String) { (object, error) -> Void in
           // print(error)
        }
	}
	
	private func searchFor(term : String) {
		
		let script = NSString(format: "findText('%@')", term)
        webview?.evaluateJavaScript(script as String) { [unowned self] (object, error) -> Void in
            
            if let numberOfMatches = object as? Int {
                self.numberOfStringsFound = numberOfMatches
                if numberOfMatches > 0 {
                    self.matchesLabel.stringValue = "\(self.numberOfStringsFound) matches"
                }
                else {
                    self.matchesLabel.stringValue = ""
                }
            }
        }
    }
    
    func seekToTimeCode(timecode:String) {
        
        if let callback = seekToTimeCodeCallBack {
            callback(timeCode: Double(timecode)!)
        }
    }
    
    func searchFieldDidStartSearching(sender: NSSearchField) {
        searchFieldHasFocus = true
    }
    
    func searchFieldDidEndSearching(sender: NSSearchField) {
        matchesLabel.stringValue = ""
        findSegmented.enabled = false
        searchFieldHasFocus = false
    }
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        
        if let dictionary = message.body as? NSDictionary where message.name == "callbackHandler" {

            if let type = dictionary["type"] as? String {
                switch type {
                case "log":
                    if let message = dictionary["message"] as? String {
                        print(" \(message)")
                    }
                case "selector":
                    if let selector = dictionary["selector"] as? String {
                        if selector == "seekToTimeCode" {
                            if let timecode = dictionary["data"] as? NSNumber {
                                seekToTimeCode(timecode.stringValue)
                            }
                        }
                    }
                default:
                    break
                }
            }
        }
    }
}

// MARK: - Video
class VideoViewController : NSViewController {

	@IBOutlet weak var avPlayerView: AVPlayerView!
	@IBOutlet weak var noVideoLabel: NSTextField!
    
	private var isStreamingURL : Bool = false
    private var timeObserver : AnyObject?
    
    var highlightLineInTranscriptCallBack : ((timeCodeString: String) -> Void)?
    var timeCodesCMTimes : [NSValue]?
	
	weak var wwdcSession : WWDCSession? {
		didSet {
			loadVideo()
		}
	}
	
    // MARK: View
	override func viewDidLoad() {
        super.viewDidLoad()

		avPlayerView.videoGravity = "AVLayerVideoGravityResizeAspect"
		avPlayerView.controlsStyle = AVPlayerViewControlsStyle.Floating
		avPlayerView.showsFullScreenToggleButton = true
		
		noVideoLabel.layer?.zPosition = 10
		
	}
    
    private func loadVideo () {
        
        guard let wwdcSession = wwdcSession else { return }
		
		isStreamingURL = false
		
        self.view.window?.title = wwdcSession.title
        
        var videoURL : NSURL?
        
        if let localFileURL = wwdcSession.hdFile?.localFileURL where wwdcSession.hdFile?.isFileAlreadyDownloaded == true  {
            videoURL = localFileURL
        }
        else {
            if let localFileURL = wwdcSession.sdFile?.localFileURL where wwdcSession.sdFile?.isFileAlreadyDownloaded == true {
                videoURL = localFileURL
            }
            else {
                if let streamingURL = wwdcSession.streamingURL {
                    videoURL = streamingURL
					isStreamingURL = true
					noVideoLabel.stringValue = "No Downloaded Videos for this Session.\nTap Play to try the streaming version 😊"
                }
				else {
					noVideoLabel.stringValue = "No Video Available for this Session!"
				}
            }
        }
        
        guard let urlToPlay = videoURL else {
		
			// loaded session has no videos so save current and blank
			unloadPlayer()
			
            avPlayerView.controlsStyle = AVPlayerViewControlsStyle.None
			noVideoLabel.animator().alphaValue = 1
			
			return
		}
		
		avPlayerView.controlsStyle = AVPlayerViewControlsStyle.Floating

		let asset = AVAsset(URL: urlToPlay)
		let newItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: ["tracks", "duration", "commonMetadata"])

		if let _ = avPlayerView.player?.currentItem {
			avPlayerView.player?.pause()
			saveVideoProgress()
			avPlayerView.player?.replaceCurrentItemWithPlayerItem(newItem)
		}
		else {
			let player = AVPlayer(playerItem:newItem)
			avPlayerView.player = player
			startObservingPlayer(player)
		}
		
		if isStreamingURL == false {		// Auto Play downloaded videos
			avPlayerView.player?.play()
			noVideoLabel.animator().alphaValue = 0
		}
		else {
			noVideoLabel.animator().alphaValue = 1
		}
    }
	
	private func restoreProgressOfVideo() {
		
		if let item = avPlayerView.player?.currentItem, let wwdcSession = wwdcSession {
			
			let userInfo = UserInfo.sharedManager.userInfo(wwdcSession)

			if userInfo.currentProgress > 0 && userInfo.currentProgress < 1 {
				let secondsIntoVideo = Double(Float(item.asset.duration.seconds)*userInfo.currentProgress)
				seekToTimeCode(secondsIntoVideo)
			}
		}
	}
    
    func seekToTimeCode(timeCode:Double) {
        
        let time = CMTimeMakeWithSeconds(Float64(timeCode), 60)
        if CMTIME_IS_VALID(time) {
            avPlayerView.player?.seekToTime(time)
        }
    }
	
    // MARK: Observers
	private var myContext = 0
    
	private func startObservingPlayer(player: AVPlayer) {
		let options = NSKeyValueObservingOptions([.New, .Old])
		player.addObserver(self, forKeyPath: "status", options: options, context: &myContext)
		player.addObserver(self, forKeyPath: "rate", options: options, context: &myContext)
        
        if let _ = timeObserver {
            player.removeTimeObserver(timeObserver!)
        }
        
        if let timeCodes = timeCodesCMTimes {
            
            timeObserver = player.addBoundaryTimeObserverForTimes(timeCodes, queue: dispatch_get_main_queue(), usingBlock: { [unowned self] () -> Void in
                
                if let currentTime = self.avPlayerView.player?.currentTime().seconds, let callback = self.highlightLineInTranscriptCallBack {
                    if let stringTimeCode = DownloadTranscriptManager.numberFormatter.stringFromNumber(NSNumber(double: currentTime)) {
                        callback(timeCodeString: stringTimeCode)
                    }
                }
                
                if self.noVideoLabel.alphaValue == 1 {
                    self.noVideoLabel.animator().alphaValue = 0
                }
            })
        }

	}
	
	private func stopObservingPlayer(player: AVPlayer) {
		player.removeObserver(self, forKeyPath: "status", context: &myContext)
		player.removeObserver(self, forKeyPath: "rate", context: &myContext)
        
        if let _ = timeObserver {
            player.removeTimeObserver(timeObserver!)
        }
	}
	
	override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
		
		guard let aKeyPath = keyPath else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
			return
		}
		
		if let _ = object as? AVPlayer where context == &myContext {
			
			switch (aKeyPath) {
			case("status"):
				playerStatusChanged()
				
			case("rate"):
				playerRateChanged()
				
			default:
				assert(false, "unknown key path")
			}
		}
		else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
		}
	}
	
    // MARK: Player
	private func playerStatusChanged() {
		
		if let playerStatus = avPlayerView.player?.status {
			
			if playerStatus == AVPlayerStatus.ReadyToPlay {
				print("Player Status READY")
				restoreProgressOfVideo()
			}
			if playerStatus == AVPlayerStatus.Failed {
				print("Player Status FAILED)")
			}
		}
	}
	
	private func playerRateChanged() {
		
		if let playerRate = avPlayerView.player?.rate {
			
			if playerRate == 0 {
				print("stopped")
			}
			else {
				print("playing")
				noVideoLabel.animator().alphaValue = 0
			}
		}
	}
	
	private let percentageConsideredWatched : Float = 0.95
	private let secondsConsideredStartedWatching : Float64 = 10
	
	private func saveVideoProgress() {
		
		if let item = avPlayerView.player?.currentItem, let player = avPlayerView.player, let wwdcSession = wwdcSession  {
			let userInfo = UserInfo.sharedManager.userInfo(wwdcSession)
			if userInfo.currentProgress < 1 {
				let currentProgress = Float(player.currentTime().seconds/item.asset.duration.seconds)
				if currentProgress < 1 && currentProgress > percentageConsideredWatched {
					userInfo.currentProgress = 1
				}
				else {
					
					if player.currentTime().seconds > CMTimeMakeWithSeconds(secondsConsideredStartedWatching, 60).seconds {
						userInfo.currentProgress = currentProgress
					}
					else {
						userInfo.currentProgress = 0
					}
				}
			}
		}
	}
	
    func unloadPlayer() {
		if let player = avPlayerView.player {
			player.pause()
			saveVideoProgress()
			stopObservingPlayer(player)
			avPlayerView.player = nil
		}
	}
}

// MARK: - PDF
class PDFMainViewController : NSViewController {
	
	@IBOutlet weak var pdfView: PDFView!
	@IBOutlet weak var noPDFLabel: NSTextField!
	
    weak var wwdcSession : WWDCSession? {
        didSet {
            if let localFileURL = wwdcSession?.pdfFile?.localFileURL where wwdcSession?.pdfFile?.isFileAlreadyDownloaded == true {
				
                let document = PDFDocument(URL: localFileURL)
                pdfView.setDocument(document)
				
				noPDFLabel.animator().alphaValue = 0
            }
			else {
				
				if wwdcSession?.pdfFile?.remoteFileURL == nil {
					noPDFLabel.stringValue = "No PDF Available"
				}
				else {
					noPDFLabel.stringValue = "PDF not yet Downloaded"
				}
				
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

}


