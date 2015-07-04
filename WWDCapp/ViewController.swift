//
//  ViewController.swift
//  WWDCapp
//
//  Created by David Roberts on 19/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSURLSessionDelegate, NSURLSessionDataDelegate, NSTableViewDataSource, NSTableViewDelegate {

	// MARK: Hooks for Proxying to ToolbarItems in WindowControllerSubclass
	var yearSeletor: NSPopUpButton! {
		get {
			if let windowController = NSApplication.sharedApplication().windows.first?.windowController  as? ToolbarHookableWindowSubclass {
				return windowController.yearSeletor
			}
			assertionFailure("IBOutlet Fail!")
			return NSPopUpButton()
		}
	}
	
	var yearFetchIndicator: NSProgressIndicator! {
		get {
			if let windowController = NSApplication.sharedApplication().windows.first?.windowController  as? ToolbarHookableWindowSubclass {
				return windowController.yearFetchIndicator
			}
			assertionFailure("IBOutlet Fail!")
			return NSProgressIndicator()
		}
	}
	
	var stopFetchButton: NSButton! {
		get {
			if let windowController = NSApplication.sharedApplication().windows.first?.windowController  as? ToolbarHookableWindowSubclass {
				return windowController.stopFetchButton
			}
			assertionFailure("IBOutlet Fail!")
			return NSButton()
		}
	}
		
	var searchField: NSSearchField! {
		get {
			if let windowController = NSApplication.sharedApplication().windows.first?.windowController  as? ToolbarHookableWindowSubclass {
				return windowController.searchField
			}
			assertionFailure("IBOutlet Fail!")
			return NSSearchField()
		}
	}
	
	var combineProgressLabel: NSTextField! {
		get {
			if let windowController = NSApplication.sharedApplication().windows.first?.windowController  as? ToolbarHookableWindowSubclass {
				return windowController.combineProgressLabel
			}
			assertionFailure("IBOutlet Fail!")
			return NSTextField()
		}
	}
	
    var combinePDFIndicator: NSProgressIndicator! {
        get {
            if let windowController = NSApplication.sharedApplication().windows.first?.windowController  as? ToolbarHookableWindowSubclass {
                return windowController.combinePDFIndicator
            }
            assertionFailure("IBOutlet Fail!")
            return NSProgressIndicator()
        }
    }
    
    var combinePDFButton: NSButton! {
        get {
            if let windowController = NSApplication.sharedApplication().windows.first?.windowController  as? ToolbarHookableWindowSubclass {
                return windowController.combinePDFButton
            }
            assertionFailure("IBOutlet Fail!")
            return NSButton()
        }
    }

	
	// MARK: IBOutlets
    @IBOutlet weak var toolbarVisualEffectView: NSVisualEffectView!
	@IBOutlet weak var visualEffectView: NSVisualEffectView!

	@IBOutlet weak var loggingLabel: NSTextField!
	
	@IBOutlet weak var allCodeCheckbox: NSButton!
	@IBOutlet weak var allSDCheckBox: NSButton!
	@IBOutlet weak var allHDCheckBox: NSButton!
	@IBOutlet weak var allPDFCheckBox: NSButton!
	
	@IBOutlet weak var myTableView: NSTableView!
	@IBOutlet weak var hideDescriptionsCheckBox: NSButton!
	
	@IBOutlet weak var totalDescriptionlabel: NSTextField!
    @IBOutlet weak var currentlabel: NSTextField!
    @IBOutlet weak var oflabel: NSTextField!
    @IBOutlet weak var totallabel: NSTextField!

    @IBOutlet weak var downloadProgressView: NSProgressIndicator!

	@IBOutlet weak var startDownload: NSButton!
	

	// MARK: Variables
	var allWWDCSessionsArray : [WWDCSession] = []
	var visibleWWDCSessionsArray : [WWDCSession] = []

	private var downloadYearInfo : DownloadYearInfo?
	
	private var isYearInfoFetchComplete = false
	
	private var isDownloading = false
    private var filesToDownload : [FileInfo] = []
    private var totalBytesToDownload : Int64 = 0
	
	private let byteFormatter : NSByteCountFormatter
	
	private var isFiltered  = false
	
	private var dockIconUpdateTimer : NSTimer?
    
    private let attributesForCheckboxLabelLeft : [String : NSObject]
    
    private var referenceCell : SessionNameDescriptionCell?
	
	// MARK: - Init
	required init?(coder: NSCoder) {
	
		byteFormatter = NSByteCountFormatter()
		byteFormatter.zeroPadsFractionDigits = true
		
		let pstyle = NSMutableParagraphStyle()
		pstyle.alignment = NSTextAlignment.Left
		attributesForCheckboxLabelLeft = [ NSForegroundColorAttributeName : NSColor.labelColor(), NSParagraphStyleAttributeName : pstyle ]
		
		super.init(coder: coder)
	}
	
	// MARK: - ACTIONS
    // MARK: TitleBar
	@IBAction func yearSelected(sender: NSPopUpButton) {

        guard let title = sender.selectedItem?.title else { return }
        
        switch title {
            case "2015":
                fetchSessionInfoForYear(.WWDC2015)
            case "2014":
                fetchSessionInfoForYear(.WWDC2014)
            case "2013":
                fetchSessionInfoForYear(.WWDC2013)
            default:
				break
        }
	}
	
    @IBAction func stopFetchingYearInfo(sender: NSButton) {
        
        if let downloadYearInfo = downloadYearInfo {
            downloadYearInfo.stopDownloading()
        }
    }
    
	@IBAction func searchEntered(sender: NSSearchField) {
	
		if sender.stringValue.isEmpty {
			isFiltered = false
		}
		else {
			isFiltered = true
			
			var newArray = [WWDCSession]()
			
			for wwdcSession in allWWDCSessionsArray {
				
				if let description = wwdcSession.sessionDescription {
					if #available(OSX 10.11, *) {
					    if wwdcSession.title.localizedStandardContainsString(sender.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())) || description.localizedStandardContainsString(sender.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())) {
    						newArray.append(wwdcSession)
    					}
					} else {
					    // Fallback on earlier versions
						let searchTerm = sender.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
						let rangeTitle = wwdcSession.title.rangeOfString(searchTerm, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: NSLocale.systemLocale())
						let rangeDescription = description.rangeOfString(searchTerm, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: NSLocale.systemLocale())

						if rangeTitle != nil || rangeDescription != nil {
							newArray.append(wwdcSession)
						}
					}
				}
				else {
					if #available(OSX 10.11, *) {
					    if wwdcSession.title.localizedStandardContainsString(sender.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())) {
    						newArray.append(wwdcSession)
    					}
					
					} else {
					    // Fallback on earlier versions
						let searchTerm = sender.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
						let rangeTitle = wwdcSession.title.rangeOfString(searchTerm, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: NSLocale.systemLocale())
						if rangeTitle != nil {
							newArray.append(wwdcSession)
						}
					}
				}
			}

			visibleWWDCSessionsArray = newArray
		}
		
		myTableView.reloadData()
	}
    
    @IBAction func combinePDF(sender: NSButton) {

        combinePDFIndicator.startAnimation(nil)
        combinePDFButton.enabled = false
        disableUIForDownloading()
        startDownload.enabled = false
        
        var pdfURLArray = [NSURL]()
        
        for wwdcSession in allWWDCSessionsArray {
            if let pdf = wwdcSession.pdfFile {
                if pdf.isFileAlreadyDownloaded {
                    if let url = pdf.localFileURL {
                        pdfURLArray.append(url)
                    }
                }
            }
        }
        
        guard let title = yearSeletor.selectedItem?.title else { return }
        
        switch title {
        case "2015":
			PDFMerge.merge(pdfURLArray, year: .WWDC2015, progressHandler: { (numberProcessed) in
					self.updateUIAfterEachPDFProcessed(numberProcessed)
				},
				completionHandler: { [unowned self] (url) in
					self.updateUIAfterCombiningPDFAndDisplay(url)
				})
        case "2014":
			PDFMerge.merge(pdfURLArray, year: .WWDC2014, progressHandler: { (numberProcessed) in
					self.updateUIAfterEachPDFProcessed(numberProcessed)
				},
				completionHandler: { [unowned self] (url) in
					self.updateUIAfterCombiningPDFAndDisplay(url)
				})
        case "2013":
			PDFMerge.merge(pdfURLArray, year: .WWDC2013, progressHandler: { (numberProcessed) in
					self.updateUIAfterEachPDFProcessed(numberProcessed)
				},
				completionHandler: { [unowned self] (url) in
					self.updateUIAfterCombiningPDFAndDisplay(url)
				})
        default:
            break
        }
    }
    
    // MARK: Main View
	@IBAction func allPDFChecked(sender: NSButton) {
		
		resetDownloadUI()
        
        allWWDCSessionsArray.map { wwdcSession in
            wwdcSession.pdfFile?.shouldDownloadFile = Bool(sender.state)
        }
		
		myTableView.reloadDataForRowIndexes(NSIndexSet(indexesInRange: NSMakeRange(0,allWWDCSessionsArray.count)) , columnIndexes:NSIndexSet(index: 2))
		
		checkDownloadButtonState()
		
		updateTotalToDownloadLabel()
    }
	
	@IBAction func allSDChecked(sender: NSButton) {
		
		resetDownloadUI()

        allWWDCSessionsArray.map { wwdcSession in
            wwdcSession.sdFile?.shouldDownloadFile = Bool(sender.state)
        }

		
		myTableView.reloadDataForRowIndexes(NSIndexSet(indexesInRange: NSMakeRange(0,allWWDCSessionsArray.count)) , columnIndexes:NSIndexSet(index: 3))
		
		checkDownloadButtonState()
		
		updateTotalToDownloadLabel()
    }
	
	@IBAction func allHDChecked(sender: NSButton) {
		
		resetDownloadUI()

        allWWDCSessionsArray.map { wwdcSession in
            wwdcSession.hdFile?.shouldDownloadFile = Bool(sender.state)
        }

		
		myTableView.reloadDataForRowIndexes(NSIndexSet(indexesInRange: NSMakeRange(0,allWWDCSessionsArray.count)) , columnIndexes:NSIndexSet(index: 4))
		
		checkDownloadButtonState()
		
		updateTotalToDownloadLabel()
    }
	
	@IBAction func allCodeChecked(sender: NSButton) {
		
		resetDownloadUI()
        
		for wwdcSession in allWWDCSessionsArray {
			for code in wwdcSession.sampleCodeArray {
				code.shouldDownloadFile = Bool(sender.state)
			}
		}
		
		myTableView.reloadDataForRowIndexes(NSIndexSet(indexesInRange: NSMakeRange(0,allWWDCSessionsArray.count)) , columnIndexes:NSIndexSet(index: 5))
		
		checkDownloadButtonState()
		
		updateTotalToDownloadLabel()
    }
	
	
	@IBAction func singleChecked(sender: NSButton) {
		
		resetDownloadUI()

		let cell = sender.superview?.superview as! CheckBoxTableViewCell
		
		if let fileArray = cell.fileArray {
			for file in fileArray {
				file.shouldDownloadFile = Bool(sender.state)
			}
		}

		let index = myTableView.columnForView(cell)
		
		if (index >= 0) {
			myTableView.reloadDataForRowIndexes(NSIndexSet(indexesInRange: NSMakeRange(0,allWWDCSessionsArray.count)) , columnIndexes:NSIndexSet(index: index))
		}
		
		checkDownloadButtonState()
		
		updateTotalToDownloadLabel()
		
		coordinateAllCheckBoxUI()
	}
	
	@IBAction func fileClicked(sender: NSButton) {
		
		let cell = sender.superview?.superview as! CheckBoxTableViewCell
		
		if let fileArray = cell.fileArray {
			if let fileInfo = fileArray.first {
				
				guard let localFileURL = fileInfo.localFileURL else { return }
				
				switch fileInfo.fileType {
				case .PDF:
					NSWorkspace.sharedWorkspace().openURL(localFileURL)
				case .SD:
					NSWorkspace.sharedWorkspace().openURL(localFileURL)
				case .HD:
					NSWorkspace.sharedWorkspace().openURL(localFileURL)
				case .SampleCode:
					NSWorkspace.sharedWorkspace().selectFile(localFileURL.filePathURL?.path, inFileViewerRootedAtPath: localFileURL.filePathURL?.absoluteString.stringByDeletingLastPathComponent)
				}
			}
		}
	}
    
	@IBAction func hideSessionsChecked(sender: NSButton) {
		
		myTableView.beginUpdates()
		
		if !isFiltered {
			myTableView.noteHeightOfRowsWithIndexesChanged(NSIndexSet(indexesInRange: NSMakeRange(0,allWWDCSessionsArray.count)))
		}
		else {
			myTableView.noteHeightOfRowsWithIndexesChanged(NSIndexSet(indexesInRange: NSMakeRange(0,visibleWWDCSessionsArray.count)))
		}
		
		myTableView.endUpdates()
	}
	
	@IBAction func startDownloadButton(sender: NSButton) {
		
		if isDownloading {
			DownloadFileManager.sharedManager.stopFileDownloads()   // Causes dispatch_group_notify to fire in downloadFiles eventually when tasks finished/cancelled
		}
		else {
			
			let (totalSize, _) = selectedDownloadInformation()
			
			let (hasSpace, freeSpace) = hasReasonableFreeDiskSpace(totalSize)
			
			if hasSpace {
				startDownloading()
			}
			else {
				
				let neededSpace = totalSize - freeSpace
				
				let readableFreeSpace = byteFormatter.stringFromByteCount(freeSpace)
				let readableNeededSpace = byteFormatter.stringFromByteCount(neededSpace)
				
				let alert = NSAlert()
				alert.messageText = "Friendly Warning"
				alert.informativeText = "It looks like you don't have enough free disk space for the selected downloads, you currently have \(readableFreeSpace) available, so would need to free up at least \(readableNeededSpace)."
				alert.addButtonWithTitle("I understand, GO!")
				alert.addButtonWithTitle("Let me think about it")

				if let window = NSApplication.sharedApplication().windows.first {

					alert.beginSheetModalForWindow(window, completionHandler: { [unowned self] (returnCode) -> Void in
							if returnCode == NSAlertFirstButtonReturn {
								self.startDownloading()
							}
							if returnCode == NSAlertSecondButtonReturn {
								
							}
						})
				}
			}
		}
	}
	
	

	// MARK: - View / UI
    override func viewDidLoad() {
        super.viewDidLoad()
		
        referenceCell = (myTableView.makeViewWithIdentifier("sessionName", owner: self) as? SessionNameDescriptionCell)!

        toolbarVisualEffectView.material = NSVisualEffectMaterial.Titlebar
        toolbarVisualEffectView.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
        toolbarVisualEffectView.state = NSVisualEffectState.FollowsWindowActiveState
        toolbarVisualEffectView.blendingMode = NSVisualEffectBlendingMode.BehindWindow

		visualEffectView.material = NSVisualEffectMaterial.AppearanceBased
		visualEffectView.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
		visualEffectView.blendingMode = NSVisualEffectBlendingMode.BehindWindow
		visualEffectView.state = NSVisualEffectState.FollowsWindowActiveState
		
		hideDescriptionsCheckBox.attributedTitle = NSAttributedString(string: "Hide Session Descriptions", attributes: attributesForCheckboxLabelLeft)
		allPDFCheckBox.attributedTitle = NSAttributedString(string: "All PDFs", attributes: attributesForCheckboxLabelLeft)
		allHDCheckBox.attributedTitle = NSAttributedString(string: "All HD", attributes: attributesForCheckboxLabelLeft)
		allSDCheckBox.attributedTitle = NSAttributedString(string: "All SD", attributes: attributesForCheckboxLabelLeft)
		allCodeCheckbox.attributedTitle = NSAttributedString(string: "All Code", attributes: attributesForCheckboxLabelLeft)

		
		myTableView.allowsMultipleSelection = false
		myTableView.allowsMultipleSelection = false
		myTableView.allowsEmptySelection = false
		
		if #available(OSX 10.11, *) {
		    totallabel.font = NSFont.monospacedDigitSystemFontOfSize(NSFont.systemFontSizeForControlSize(NSControlSize.SmallControlSize), weight: NSFontWeightRegular)
			oflabel.font = NSFont.monospacedDigitSystemFontOfSize(NSFont.systemFontSizeForControlSize(NSControlSize.SmallControlSize), weight: NSFontWeightRegular)
			currentlabel.font = NSFont.monospacedDigitSystemFontOfSize(NSFont.systemFontSizeForControlSize(NSControlSize.SmallControlSize), weight: NSFontWeightRegular)
		}
		
		resetUIForYearFetch()
	}
	
	func resetUIForYearFetch () {
		
		loggingLabel.stringValue = ""
        
        combinePDFButton.enabled = false
        
        stopFetchButton.hidden = true
		
        isYearInfoFetchComplete = false
        
		isFiltered = false
		
		combineProgressLabel.stringValue = ""
		
		searchField.stringValue = ""
		
        allWWDCSessionsArray.removeAll()
        
		visibleWWDCSessionsArray.removeAll()
		
		searchField.enabled = false
		
		resetAllCheckboxesAndDisable()
		
		updateTotalToDownloadLabel()
		
		resetDownloadUI()
		
		startDownload.enabled = false
		
		hideDescriptionsCheckBox.enabled = false
		
		hideDescriptionsCheckBox.state = 0
		
		updateCombinePDFButtonState()

        myTableView.reloadData()
    }

	
	// MARK: Fetch Year Info
	func fetchSessionInfoForYear(year : WWDCYear) {
		
		resetUIForYearFetch()
		
		yearSeletor.enabled = false
		
        stopFetchButton.hidden = false
        
		yearFetchIndicator.startAnimation(nil)
		
		downloadYearInfo = DownloadYearInfo(year: year, parsingCompleteHandler: { [unowned self] (sessions) -> Void in
			
				self.allWWDCSessionsArray = sessions
			
				dispatch_async(dispatch_get_main_queue()) { [unowned self] in
					self.myTableView.reloadData()
				}
			},
			messageForUIupdateHandler: { [unowned self] (updateMessage) -> Void in
				
				dispatch_async(dispatch_get_main_queue()) { [unowned self] in
					self.loggingLabel.stringValue = updateMessage
				}
			},
			individualSessionUpdateHandler: { [unowned self] (session) -> Void in
				
				if let index = self.allWWDCSessionsArray.indexOf(session) {
					dispatch_async(dispatch_get_main_queue()) { [unowned self] in
						self.myTableView.beginUpdates()
                        self.myTableView.noteHeightOfRowsWithIndexesChanged(NSIndexSet(index: index))
						self.myTableView.reloadDataForRowIndexes(NSIndexSet(index: index), columnIndexes:NSIndexSet(indexesInRange: NSMakeRange(0,self.myTableView.numberOfColumns)))
						self.myTableView.endUpdates()
					}
				}
			},
			completionHandler: { [unowned self] (success) in
								
				dispatch_async(dispatch_get_main_queue()) { [unowned self] in

                    if (success) {
                        
                        self.isYearInfoFetchComplete = true
                        
                        self.stopFetchButton.hidden = true

                        self.searchField.enabled = true
                        
                        self.startDownload.enabled = true
                        
                        let sessionIDSortDescriptor = NSSortDescriptor(key: "sessionID", ascending: true, selector: "localizedStandardCompare:")
                        
                        self.myTableView.sortDescriptors = [sessionIDSortDescriptor]
                        
                        self.reEnableCheckboxes()
                        
                        self.coordinateAllCheckBoxUI()
                        
                        self.hideDescriptionsCheckBox.enabled = true
                        self.hideDescriptionsCheckBox.state = 0
                        
                        self.myTableView.reloadData()
                        
                        self.updateCombinePDFButtonState()
						
						self.updateTotalToDownloadLabel()
						
						self.checkDownloadButtonState()
						
						let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC)))
						dispatch_after(delayTime, dispatch_get_main_queue()) {
							self.loggingLabel.stringValue = ""
						}
						
                    }
                    else {
                        self.resetUIForYearFetch()
                    }
                    
                    self.yearSeletor.enabled = true

                    self.yearFetchIndicator.stopAnimation(nil)
                    
                    self.downloadYearInfo = nil
				}
			})
	}
	
	
	// MARK: - TableView
	func numberOfRowsInTableView(tableView: NSTableView) -> Int {
		
		if !isFiltered {
			return self.allWWDCSessionsArray.count
		}
		else {
			return self.visibleWWDCSessionsArray.count
		}
	}
	
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        
        if hideDescriptionsCheckBox.state == 1 {
            return 50
        }
        else {
            
            let wwdcSession = (!isFiltered ? allWWDCSessionsArray[row] : visibleWWDCSessionsArray[row])
            
            if let referenceCell = referenceCell {
                
                referenceCell.updateCell(wwdcSession.title, description: wwdcSession.sessionDescription, descriptionVisible: true)
                
                let rowHeight = 10 + referenceCell.sessionName.intrinsicContentSize.height + referenceCell.sessionDescriptionTextView.intrinsicContentSize.height + 10
                
                if rowHeight < 50 {
                    return 50
                }
                else {
                    return rowHeight
                }
            }
            else {
                return 50
            }
        }
    }
	
	func selectionShouldChangeInTableView(tableView: NSTableView) -> Bool {
		return false
	}
	
	func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
		
        let wwdcSession = (!isFiltered ? allWWDCSessionsArray[row] : visibleWWDCSessionsArray[row])
		
		if tableColumn?.identifier == "sessionID" {

			let cell = (tableView.makeViewWithIdentifier("sessionID", owner: self) as? NSTableCellView)!
			
			cell.textField?.stringValue = wwdcSession.sessionID
			
			return cell
		}
		else if tableColumn?.identifier == "sessionName" {
			
			let cell = (tableView.makeViewWithIdentifier("sessionName", owner: self) as? SessionNameDescriptionCell)!
				
            if #available(OSX 10.11, *) {
                cell.highlightText(searchField.stringValue)
            }
            
            cell.updateCell(wwdcSession.title, description: wwdcSession.sessionDescription, descriptionVisible: false)
            
            return cell
		}
		else if tableColumn?.identifier == "PDF" {
			
			let cell = (tableView.makeViewWithIdentifier("PDF", owner: self) as? CheckBoxTableViewCell)!
			
			cell.resetCell()

			if let file = wwdcSession.pdfFile {
				cell.fileArray = [file]
				cell.updateCell(isYearInfoFetchComplete, isDownloadSessionActive: isDownloading)
			}
			
			if wwdcSession.isInfoFetchComplete {
				cell.loadingProgressView.stopAnimation(nil)
				cell.loadingProgressView.hidden = true
			}
			else {
				cell.loadingProgressView.startAnimation(nil)
				cell.loadingProgressView.hidden = false
			}
			
			return cell
		}
		else if tableColumn?.identifier == "SD" {
			
			let cell = (tableView.makeViewWithIdentifier("SD", owner: self) as? CheckBoxTableViewCell)!
			
			cell.resetCell()

			if let file = wwdcSession.sdFile {
				cell.fileArray = [file]
				cell.updateCell(isYearInfoFetchComplete, isDownloadSessionActive: isDownloading)
			}
			
			if wwdcSession.isInfoFetchComplete {
				cell.loadingProgressView.stopAnimation(nil)
				cell.loadingProgressView.hidden = true
			}
			else {
				cell.loadingProgressView.startAnimation(nil)
				cell.loadingProgressView.hidden = false
			}
			
			return cell
		}
		else if tableColumn?.identifier == "HD" {
			
			let cell = (tableView.makeViewWithIdentifier("HD", owner: self) as? CheckBoxTableViewCell)!
			
			cell.resetCell()

			if let file = wwdcSession.hdFile {
				cell.fileArray = [file]
				cell.updateCell(isYearInfoFetchComplete, isDownloadSessionActive: isDownloading)
			}
			
			if wwdcSession.isInfoFetchComplete {
				cell.loadingProgressView.stopAnimation(nil)
				cell.loadingProgressView.hidden = true
			}
			else {
				cell.loadingProgressView.startAnimation(nil)
				cell.loadingProgressView.hidden = false
			}
			
			return cell
		}
		else if tableColumn?.identifier == "Code" {
			
			let cell = (tableView.makeViewWithIdentifier("Code", owner: self) as? CheckBoxTableViewCell)!
			
			cell.resetCell()

			if wwdcSession.sampleCodeArray.count > 0 {
				cell.fileArray = wwdcSession.sampleCodeArray
				cell.updateCell(isYearInfoFetchComplete, isDownloadSessionActive: isDownloading)
			}
			
			if wwdcSession.isInfoFetchComplete {
				cell.loadingProgressView.stopAnimation(nil)
				cell.loadingProgressView.hidden = true
			}
			else {
				cell.loadingProgressView.startAnimation(nil)
				cell.loadingProgressView.hidden = false
			}
			
			return cell
		}
		else {
			return nil
		}
		
	}
	
	
	func tableView(tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {

		if !isFiltered {
			let sortedBy = (allWWDCSessionsArray as NSArray).sortedArrayUsingDescriptors(tableView.sortDescriptors)
			
			allWWDCSessionsArray = sortedBy as! [WWDCSession]
		}
		else {
			let sortedBy = (visibleWWDCSessionsArray as NSArray).sortedArrayUsingDescriptors(tableView.sortDescriptors)
			
			visibleWWDCSessionsArray = sortedBy as! [WWDCSession]
		}
		
		tableView.reloadData()
	}
	
	
	// MARK: - Download
	func  downloadFiles(files : [FileInfo] ) {
		
		print("Total Files to download - \(files.count)")
		
		let downloadGroup = dispatch_group_create()
		
        var failError : NSError?
        
		for file in files {
			
			dispatch_group_enter(downloadGroup)
			
			let progressWrapper = ProgressWrapper(handler: { [unowned self] (progress) -> Void in
				
				guard let session = file.session else { return }
				
				var actualIndex : Int?
				
				if self.isFiltered {
					if let index = self.visibleWWDCSessionsArray.indexOf(session) {
						actualIndex = index
					}
				}
				else {
					if let index = self.allWWDCSessionsArray.indexOf(session) {
						actualIndex = index
					}
				}

				if let index = actualIndex {
					dispatch_async(dispatch_get_main_queue()) { [unowned self] in
						switch file.fileType {
						case .PDF:
							self.myTableView.reloadDataForRowIndexes(NSIndexSet(index: index), columnIndexes:NSIndexSet(indexesInRange: NSMakeRange(2,1)))
						case .SD:
							self.myTableView.reloadDataForRowIndexes(NSIndexSet(index: index), columnIndexes:NSIndexSet(indexesInRange: NSMakeRange(3,1)))
						case .HD:
							self.myTableView.reloadDataForRowIndexes(NSIndexSet(index: index), columnIndexes:NSIndexSet(indexesInRange: NSMakeRange(4,1)))
						case .SampleCode:
							self.myTableView.reloadDataForRowIndexes(NSIndexSet(index: index), columnIndexes:NSIndexSet(indexesInRange: NSMakeRange(5,1)))
						}
						
						self.updateTotalProgress()
					}
				}

			})
			
			let completionWrapper = SimpleCompletionWrapper(handler: { [unowned self] (success) -> Void in
				
				if success {
					
					file.downloadProgress = 1
					
					print("Download SUCCESS - \(file.displayName!)")
				}
                else {
                    if let error = file.fileErrorCode {
                        failError = error
                    }
                }
				
				guard let session = file.session else { return }

				if self.isFiltered {
					if let index = self.visibleWWDCSessionsArray.indexOf(session) {
						dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                            self.myTableView.beginUpdates()
							self.myTableView.reloadDataForRowIndexes(NSIndexSet(index: index), columnIndexes:NSIndexSet(indexesInRange: NSMakeRange(0,self.myTableView.numberOfColumns)))
//                            self.myTableView.scrollRowToVisible(index)
                            self.myTableView.endUpdates()

							self.updateTotalProgress()
						}
					}
				}
				else {
					if let index = self.allWWDCSessionsArray.indexOf(session) {
						dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                            self.myTableView.beginUpdates()
							self.myTableView.reloadDataForRowIndexes(NSIndexSet(index: index), columnIndexes:NSIndexSet(indexesInRange: NSMakeRange(0,self.myTableView.numberOfColumns)))
//                            self.myTableView.scrollRowToVisible(index)
                            self.myTableView.endUpdates()

							self.updateTotalProgress()
						}
					}
				}

				dispatch_group_leave(downloadGroup)
			})
			
			DownloadFileManager.sharedManager.downloadFile(file, progressWrapper: progressWrapper, completionWrapper: completionWrapper)
		}
		
		dispatch_group_notify(downloadGroup,dispatch_get_main_queue(),{ [unowned self] in
            
            if let error = failError {
                let alert = NSAlert(error: error)
                alert.runModal()
				NSSound(named: "Basso")?.play()
            }
			else {
				if NSRunningApplication.currentApplication() != NSWorkspace.sharedWorkspace().frontmostApplication {
					NSSound(named: "Glass")?.play()
					NSApp.requestUserAttention(NSRequestUserAttentionType.CriticalRequest)
				}

			}
			
            self.stopDownloading()
		})
	}
	
	func startDownloading () {
		
		isDownloading = true

		searchField.enabled = false
		searchField.stringValue = ""
		isFiltered = false
		visibleWWDCSessionsArray.removeAll()
		myTableView.reloadData()

		startDownload.title = "Stop Downloading"
		
		disableUIForDownloading()
				
		filesToDownload.removeAll()
		
		for wwdcSession in self.allWWDCSessionsArray {
			
			if let file = wwdcSession.pdfFile  where (wwdcSession.pdfFile?.shouldDownloadFile == true && wwdcSession.pdfFile?.fileSize > 0  && wwdcSession.pdfFile?.isFileAlreadyDownloaded == false) {
				filesToDownload.append(file)
			}
			if let file = wwdcSession.sdFile where (wwdcSession.sdFile?.shouldDownloadFile == true && wwdcSession.sdFile?.fileSize > 0  && wwdcSession.sdFile?.isFileAlreadyDownloaded == false) {
				filesToDownload.append(file)
			}
			if let file = wwdcSession.hdFile  where (wwdcSession.hdFile?.shouldDownloadFile == true && wwdcSession.hdFile?.fileSize > 0  && wwdcSession.hdFile?.isFileAlreadyDownloaded == false) {
				filesToDownload.append(file)
			}
			for file in wwdcSession.sampleCodeArray where (file.shouldDownloadFile == true && file.fileSize > 0  && file.isFileAlreadyDownloaded == false)  {
				filesToDownload.append(file)
			}
		}
		
		updateTotalProgress()
		oflabel.hidden = false
		updateTotalToDownloadLabel()
		
		startUpdatingDockIcon()
		
		downloadFiles(filesToDownload)
	}
	
	func stopDownloading () {
		
		isDownloading = false

		startDownload.title = "Start Downloading"
		
		searchField.enabled = true

		yearSeletor.enabled = true
		
		coordinateAllCheckBoxUI()
				
		filesToDownload.removeAll()
		
		myTableView.reloadData()
		
		checkDownloadButtonState()
		
		stopUpdatingDockIcon()
		
        updateCombinePDFButtonState()
        
        print("Completed File Downloads")
	}
	
	func hasReasonableFreeDiskSpace(projectedSpaceNeeded : Int64) -> (Bool, Int64) {
		
		let fileManager = NSFileManager.defaultManager()
		
		do {
			let attributes = try fileManager.attributesOfFileSystemForPath("/")
			let freeSpace = Int64((attributes[NSFileSystemFreeSize] as! NSNumber) as Double)
			
//			let readableNeeded = byteFormatter.stringFromByteCount(projectedSpaceNeeded)
//			let readableFreeSpace = byteFormatter.stringFromByteCount(freeSpace)
//			print("Needed Space - \(readableNeeded)")
//			print("Free Space - \(readableFreeSpace)")
			
			if freeSpace > projectedSpaceNeeded {
				return (true, freeSpace)
			}
			else {
				return (false, freeSpace)
			}
		}
		catch {
			print(error)
			return (false, 0)
		}
	}
	
    // MARK: - UI State changes / checks
    func updateTotalProgress() {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { [unowned self] in
            
            var currentDownloadBytes : Int64 = 0
            
            for file in self.filesToDownload {
                if let fileSize = file.fileSize {
                    currentDownloadBytes += Int64(file.downloadProgress*Float(fileSize))
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { [unowned self] in
                
                self.currentlabel.stringValue = self.byteFormatter.stringFromByteCount(currentDownloadBytes)
                
                let progress = Float(currentDownloadBytes)/Float(self.totalBytesToDownload)
                
                self.downloadProgressView.doubleValue = Double(progress)
                })
            })
    }
    
	func selectedDownloadInformation() -> (totalSize: Int64, numberOfFiles: Int) {
        
        totalBytesToDownload = 0
		
		var totalBytes : Int64 = 0
		var numberOfFiles = 0

        for wwdcSession in self.allWWDCSessionsArray {
            
            if let file = wwdcSession.pdfFile  where (wwdcSession.pdfFile?.shouldDownloadFile == true && wwdcSession.pdfFile?.fileSize > 0 && wwdcSession.pdfFile?.isFileAlreadyDownloaded == false) {
                if let fileSize = file.fileSize {
                    totalBytes += Int64(fileSize)
					numberOfFiles++
                }
            }
            if let file = wwdcSession.sdFile where (wwdcSession.sdFile?.shouldDownloadFile == true && wwdcSession.sdFile?.fileSize > 0 && wwdcSession.sdFile?.isFileAlreadyDownloaded == false) {
                if let fileSize = file.fileSize {
                    totalBytes += Int64(fileSize)
					numberOfFiles++
                }
            }
            if let file = wwdcSession.hdFile  where (wwdcSession.hdFile?.shouldDownloadFile == true && wwdcSession.hdFile?.fileSize > 0 && wwdcSession.hdFile?.isFileAlreadyDownloaded == false) {
                if let fileSize = file.fileSize {
                    totalBytes += Int64(fileSize)
					numberOfFiles++
                }
            }
            for sample in wwdcSession.sampleCodeArray where (sample.shouldDownloadFile == true && sample.fileSize > 0 && sample.isFileAlreadyDownloaded == false) {
                if let fileSize = sample.fileSize {
                    totalBytes += Int64(fileSize)
					numberOfFiles++
                }
            }
        }
		
		totalBytesToDownload = totalBytes
		
        return (totalBytes, numberOfFiles)
    }
	
	func updateTotalToDownloadLabel() {
		
		let (totalSize, _) = selectedDownloadInformation()
		
		let (hasSpace, _) = hasReasonableFreeDiskSpace(totalSize)

		if hasSpace {
			totallabel.textColor = NSColor.labelColor()
		}
		else {
			totallabel.textColor = NSColor.redColor()
		}
		
		totallabel.stringValue = byteFormatter.stringFromByteCount(totalSize)
	}
	
	func checkDownloadButtonState () {
		
		let (_, totalToFetch) = selectedDownloadInformation()
		
		if totalToFetch == 0 {
			startDownload.enabled = false
			totalDescriptionlabel.stringValue = "total:"
		}
		else {
			startDownload.enabled = true
			totalDescriptionlabel.stringValue = "\(totalToFetch) files, total:"
		}
	}
	
   	func resetDownloadUI() {
		
		currentlabel.stringValue = ""
		oflabel.hidden = true
        
        totallabel.stringValue = byteFormatter.stringFromByteCount(0)

		downloadProgressView.doubleValue = 0
	}

    // MARK: Checkboxes
    func disableUIForDownloading () {
        
        yearSeletor.enabled = false
        
        allPDFCheckBox.enabled = false
        allSDCheckBox.enabled = false
        allHDCheckBox.enabled = false
        allCodeCheckbox.enabled = false
    }
	
	func resetAllCheckboxesAndDisable() {
		
		allPDFCheckBox.state = 1
		allSDCheckBox.state = 1
		allHDCheckBox.state = 1
		allCodeCheckbox.state = 1
		
		allPDFCheckBox.enabled = false
		allSDCheckBox.enabled = false
		allHDCheckBox.enabled = false
		allCodeCheckbox.enabled = false
	}
	
	func reEnableCheckboxes () {
		
		allPDFCheckBox.enabled = true
		allSDCheckBox.enabled = true
		allHDCheckBox.enabled = true
		allCodeCheckbox.enabled = true
	}
    
    private func coordinateAllCheckBoxUI() {
        
        var shouldCheckAllPDF = true
        var shouldCheckAllSD = true
        var shouldCheckAllHD = true
        var shouldCheckAllCode = true
        
        var countPDF = 0
        var countSD = 0
        var countHD = 0
        var countCode = 0
        
        for wwdcSession in self.allWWDCSessionsArray {
            
            if let file = wwdcSession.pdfFile  where (wwdcSession.pdfFile?.fileSize > 0 && wwdcSession.pdfFile?.isFileAlreadyDownloaded == false) {
                if file.shouldDownloadFile == false {
                    shouldCheckAllPDF = false
                }
                countPDF++
            }
            if let file = wwdcSession.sdFile where (wwdcSession.sdFile?.fileSize > 0 && wwdcSession.sdFile?.isFileAlreadyDownloaded == false) {
                if file.shouldDownloadFile == false {
                    shouldCheckAllSD = false
                }
                countSD++
            }
            if let file = wwdcSession.hdFile  where (wwdcSession.hdFile?.fileSize > 0 && wwdcSession.hdFile?.isFileAlreadyDownloaded == false) {
                if file.shouldDownloadFile == false {
                    shouldCheckAllHD = false
                }
                countHD++
            }
            for sample in wwdcSession.sampleCodeArray where (sample.fileSize > 0 && sample.isFileAlreadyDownloaded == false)  {
                if sample.shouldDownloadFile == false {
                    shouldCheckAllCode = false
                }
                countCode++
            }
        }
        
        if countPDF > 0 {
            allPDFCheckBox.state = Int(shouldCheckAllPDF)
            allPDFCheckBox.enabled = true
        }
        else {
            allPDFCheckBox.state = 0
            allPDFCheckBox.enabled = false
        }
        
        if countSD > 0 {
            allSDCheckBox.state = Int(shouldCheckAllSD)
            allSDCheckBox.enabled = true
        }
        else {
            allSDCheckBox.state = 0
            allSDCheckBox.enabled = false
        }
        
        if countHD > 0 {
            allHDCheckBox.state = Int(shouldCheckAllHD)
            allHDCheckBox.enabled = true
        }
        else {
            allHDCheckBox.state = 0
            allHDCheckBox.enabled = false
        }
        
        if countCode > 0 {
            allCodeCheckbox.state = Int(shouldCheckAllCode)
            allCodeCheckbox.enabled = true
        }
        else {
            allCodeCheckbox.state = 0
            allCodeCheckbox.enabled = false
        }
    }

    // MARK: CombineButton
    func updateCombinePDFButtonState() {
        
        if isDownloading {
            combinePDFButton.enabled = false
        }
        else {
            
            var numberOfPDFsPresent = 0
            
            for wwdcSession in allWWDCSessionsArray {
                if let pdfFile = wwdcSession.pdfFile {
                    if pdfFile.isFileAlreadyDownloaded {
                        numberOfPDFsPresent++
                    }
                }
            }
			
            if numberOfPDFsPresent > 1 {
                combinePDFButton.enabled = true
				combinePDFButton.title = "Combine \(numberOfPDFsPresent) PDFs"
            }
            else{
                combinePDFButton.enabled = false
				combinePDFButton.title = "Combine PDFs"
            }
        }
    }
	
	func updateUIAfterEachPDFProcessed(numberProcessed:Int) {
		
		combineProgressLabel.stringValue = "Progress: \(numberProcessed)"
	}
    
    func updateUIAfterCombiningPDFAndDisplay(url:NSURL?) {
        
        if let url = url {
            NSWorkspace.sharedWorkspace().selectFile(url.path, inFileViewerRootedAtPath: url.absoluteString.stringByDeletingLastPathComponent)
        }
		
		combineProgressLabel.stringValue = ""
        combinePDFIndicator.stopAnimation(nil)
        combinePDFButton.enabled = true
        startDownload.enabled = true
        yearSeletor.enabled = true
        reEnableCheckboxes()
    }

	
    // MARK: Dock Icon
    func startUpdatingDockIcon () {
		dockIconUpdateTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "updateDockIcon", userInfo: nil, repeats: true)
	}
	
	func updateDockIcon () {
		
		dispatch_async(dispatch_get_main_queue()) { [unowned self] in
			let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
			appDelegate.updateDockProgress(self.downloadProgressView.doubleValue)
		}
	}
	
	func stopUpdatingDockIcon () {
		if let timer = dockIconUpdateTimer {
			if timer.valid {
				timer.invalidate()
			}
		}
		dockIconUpdateTimer = nil
	}

}

