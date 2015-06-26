//
//  ViewController.swift
//  WWDCapp
//
//  Created by David Roberts on 19/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSURLSessionDelegate, NSURLSessionDataDelegate, NSTableViewDataSource, NSTableViewDelegate {

	@IBOutlet weak var yearSeletor: NSPopUpButton!
	@IBOutlet weak var yearFetchIndicator: NSProgressIndicator!
	@IBOutlet weak var searchField: NSSearchField!

	@IBOutlet weak var allCodeCheckbox: NSButton!
	@IBOutlet weak var allSDCheckBox: NSButton!
	@IBOutlet weak var allHDCheckBox: NSButton!
	@IBOutlet weak var allPDFCheckBox: NSButton!
	
	@IBOutlet weak var startDownload: NSButton!
	
	@IBOutlet weak var myTableView: NSTableView!
	
    @IBOutlet weak var currentlabel: NSTextField!
    @IBOutlet weak var oflabel: NSTextField!
    @IBOutlet weak var totallabel: NSTextField!

    @IBOutlet weak var downloadProgressView: NSProgressIndicator!

	
	var allWWDCSessionsArray : [WWDCSession] = []
	var visibleWWDCSessionsArray : [WWDCSession] = []

	private var downloadSessionInfo : DownloadSessionInfo?
	
	private var isYearInfoFetchComplete = false
	
	private var isDownloading = false
    private var filesToDownload : [FileInfo] = []
    private var totalBytesToDownload : Int64 = 0
	
	private let byteFormatter : NSByteCountFormatter
	
	private var isFiltered  = false
	
	// MARK: - Init
	required init?(coder: NSCoder) {
	
		byteFormatter = NSByteCountFormatter()
		byteFormatter.zeroPadsFractionDigits = true
		
		super.init(coder: coder)
	}
	
	// MARK: - ACTIONS
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
	
	@IBAction func searchEntered(sender: NSSearchField) {
	
		if sender.stringValue.isEmpty {
			isFiltered = false
		}
		else {
			isFiltered = true
			
			var newArray = [WWDCSession]()
			
			for wwdcSession in allWWDCSessionsArray {
				if wwdcSession.title.localizedStandardContainsString(sender.stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())) {
					newArray.append(wwdcSession)
				}
			}

			visibleWWDCSessionsArray = newArray
		}
		
		dispatch_async(dispatch_get_main_queue()) { [unowned self] in
			self.myTableView.reloadData()
		}
		
	}
	

	@IBAction func allPDFChecked(sender: NSButton) {
		
		resetDownloadUI()

		for wwdcSession in allWWDCSessionsArray {
			wwdcSession.pdfFile?.shouldDownloadFile = Bool(sender.state)
		}
		
		myTableView.reloadDataForRowIndexes(NSIndexSet(indexesInRange: NSMakeRange(0,allWWDCSessionsArray.count)) , columnIndexes:NSIndexSet(index: 2))
		
		updateTotalFileSize()
	}
	
	@IBAction func allSDChecked(sender: NSButton) {
		
		resetDownloadUI()

		for wwdcSession in allWWDCSessionsArray {
			wwdcSession.sdFile?.shouldDownloadFile = Bool(sender.state)
		}
		
		myTableView.reloadDataForRowIndexes(NSIndexSet(indexesInRange: NSMakeRange(0,allWWDCSessionsArray.count)) , columnIndexes:NSIndexSet(index: 3))
		
        updateTotalFileSize()
	}
	
	@IBAction func allHDChecked(sender: NSButton) {
		
		resetDownloadUI()

		for wwdcSession in allWWDCSessionsArray {
			wwdcSession.hdFile?.shouldDownloadFile = Bool(sender.state)
		}
		
		myTableView.reloadDataForRowIndexes(NSIndexSet(indexesInRange: NSMakeRange(0,allWWDCSessionsArray.count)) , columnIndexes:NSIndexSet(index: 4))
		
        updateTotalFileSize()
		
	}
	
	@IBAction func allCodeChecked(sender: NSButton) {
		
		resetDownloadUI()

		for wwdcSession in allWWDCSessionsArray {
			for code in wwdcSession.sampleCodeArray {
				code.shouldDownloadFile = Bool(sender.state)
			}
		}
		
		myTableView.reloadDataForRowIndexes(NSIndexSet(indexesInRange: NSMakeRange(0,allWWDCSessionsArray.count)) , columnIndexes:NSIndexSet(index: 5))
		
		updateTotalFileSize()
	}
	
	
	@IBAction func singleChecked(sender: NSButton) {
		
		resetDownloadUI()

		let cell = sender.superview as! CheckBoxTableViewCell
		
		if let fileArray = cell.fileArray {
			for file in fileArray {
				file.shouldDownloadFile = Bool(sender.state)
			}
		}

		let index = myTableView.columnForView(cell)
		
		if (index >= 0) {
			myTableView.reloadDataForRowIndexes(NSIndexSet(indexesInRange: NSMakeRange(0,allWWDCSessionsArray.count)) , columnIndexes:NSIndexSet(index: index))
		}
		
		updateTotalFileSize()
		
		coordinateAllCheckBoxUI()
		
	}
	
	@IBAction func fileClicked(sender: NSButton) {
		
		let cell = sender.superview as! CheckBoxTableViewCell
		
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

		// print("PDFs-\(countPDF), SD-\(countSD), HD-\(countHD), Code-\(countCode)")
		
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
	
	@IBAction func startDownloadButton(sender: NSButton) {
		
		if isDownloading {
			DownloadFileManager.sharedManager.stopDownloads()   // Causes dispatch_group_notify to fire in downloadFiles eventually when tasks finished/cancelled
		}
		else {
			startDownloading()
		}
	}
	
	

	// MARK: - View / UI
    override func viewDidLoad() {
        super.viewDidLoad()
		
		myTableView.allowsColumnSelection = false
		myTableView.allowsMultipleSelection = false
		myTableView.allowsEmptySelection = false
		
		myTableView.reloadData()
		
		resetUIForYearFetch()
	}
	
	func resetUIForYearFetch () {
		
		searchField.enabled = false
		
		resetAllCheckboxesAndDisable()
		
		updateTotalFileSize()
		
		resetDownloadUI()
		
		startDownload.enabled = false
	}
	
	func disableUIForDownloading () {
		
		yearSeletor.enabled = false
		
		allPDFCheckBox.enabled = false
		allSDCheckBox.enabled = false
		allHDCheckBox.enabled = false
		allCodeCheckbox.enabled = false
	}
	
	func reEnableUIWhenStoppedDownloading() {
		
		yearSeletor.enabled = true
		
		coordinateAllCheckBoxUI()
	}
	
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
	
	func updateTotalFileSize() {
		
		totalBytesToDownload = 0
		
		for wwdcSession in self.allWWDCSessionsArray {
			
			if let file = wwdcSession.pdfFile  where (wwdcSession.pdfFile?.shouldDownloadFile == true && wwdcSession.pdfFile?.fileSize > 0 && wwdcSession.pdfFile?.isFileAlreadyDownloaded == false) {
				if let fileSize = file.fileSize {
					totalBytesToDownload += Int64(fileSize)
				}
			}
			if let file = wwdcSession.sdFile where (wwdcSession.sdFile?.shouldDownloadFile == true && wwdcSession.sdFile?.fileSize > 0 && wwdcSession.sdFile?.isFileAlreadyDownloaded == false) {
				if let fileSize = file.fileSize {
					totalBytesToDownload += Int64(fileSize)
				}
			}
			if let file = wwdcSession.hdFile  where (wwdcSession.hdFile?.shouldDownloadFile == true && wwdcSession.hdFile?.fileSize > 0 && wwdcSession.hdFile?.isFileAlreadyDownloaded == false) {
				if let fileSize = file.fileSize {
					totalBytesToDownload += Int64(fileSize)
				}
			}
			for sample in wwdcSession.sampleCodeArray where (sample.shouldDownloadFile == true && sample.fileSize > 0 && sample.isFileAlreadyDownloaded == false) {
				if let fileSize = sample.fileSize {
					totalBytesToDownload += Int64(fileSize)
				}
			}
		}
		
		totallabel.stringValue = byteFormatter.stringFromByteCount(totalBytesToDownload)
	}


	
	// MARK: Fetch Year Info
	func fetchSessionInfoForYear(year : WWDCYear) {
		
		resetUIForYearFetch()
		
		yearSeletor.enabled = false
		
		isYearInfoFetchComplete = false
		allWWDCSessionsArray.removeAll()
		myTableView.reloadData()
		
		yearFetchIndicator.startAnimation(nil)
		
		downloadSessionInfo = DownloadSessionInfo(year: year, parsingCompleteHandler: { [unowned self] (sessions) -> Void in
			
				self.allWWDCSessionsArray = sessions
			
				dispatch_async(dispatch_get_main_queue()) { [unowned self] in
					self.myTableView.reloadData()
				}
			},
			individualSessionUpdateHandler: { [unowned self] (session) -> Void in
				
				if let index = self.allWWDCSessionsArray.indexOf(session) {
					dispatch_async(dispatch_get_main_queue()) { [unowned self] in
						self.myTableView.reloadDataForRowIndexes(NSIndexSet(index: index), columnIndexes:NSIndexSet(indexesInRange: NSMakeRange(0,self.myTableView.numberOfColumns)))
					}
				}
			},
			completionHandler: { [unowned self] in
				
				print("ALL \(year) INFO DOWNLOADED")
				
				dispatch_async(dispatch_get_main_queue()) { [unowned self] in

					self.searchField.enabled = true
					
					self.yearSeletor.enabled = true

					self.isYearInfoFetchComplete = true

					self.yearFetchIndicator.stopAnimation(nil)

					self.startDownload.enabled = true
					
					let sessionIDSortDescriptor = NSSortDescriptor(key: "sessionID", ascending: true, selector: "localizedStandardCompare:")
					
					self.myTableView.sortDescriptors = [sessionIDSortDescriptor]  // This fires reload of table
					
					self.reEnableCheckboxes()
					
					self.coordinateAllCheckBoxUI()
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
	
	func selectionShouldChangeInTableView(tableView: NSTableView) -> Bool {
		return false
	}
	
	func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
		
		let wwdcSession : WWDCSession
		
		if !isFiltered {
			wwdcSession =  allWWDCSessionsArray[row]
		}
		else {
			wwdcSession = visibleWWDCSessionsArray[row]
		}
		
		if tableColumn?.identifier == "sessionID" {

			let cell = (tableView.makeViewWithIdentifier("sessionID", owner: self) as? NSTableCellView)!
			
			cell.textField?.stringValue = wwdcSession.sessionID
			
			return cell
		}
		else if tableColumn?.identifier == "sessionName" {
			
			let cell = (tableView.makeViewWithIdentifier("sessionName", owner: self) as? NSTableCellView)!
			
			cell.textField?.stringValue = wwdcSession.title
			
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
	
	
	// MARK: SearchFieldDelegates
	func searchFieldDidStartSearching(sender: NSSearchField) {
		
	}
	
	func searchFieldDidEndSearching(sender: NSSearchField) {
		
	}
	
	// MARK: - Download
	func  downloadFiles(files : [FileInfo] ) {
		
		print("Total Files to download - \(files.count)")
		
		let downloadGroup = dispatch_group_create();
		
		for file in files {
			
			dispatch_group_enter(downloadGroup);
			
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
				
				guard let session = file.session else { return }

				if self.isFiltered {
					if let index = self.visibleWWDCSessionsArray.indexOf(session) {
						dispatch_async(dispatch_get_main_queue()) { [unowned self] in
							self.myTableView.reloadDataForRowIndexes(NSIndexSet(index: index), columnIndexes:NSIndexSet(indexesInRange: NSMakeRange(0,self.myTableView.numberOfColumns)))
							self.updateTotalProgress()
						}
					}
				}
				else {
					if let index = self.allWWDCSessionsArray.indexOf(session) {
						dispatch_async(dispatch_get_main_queue()) { [unowned self] in
							self.myTableView.reloadDataForRowIndexes(NSIndexSet(index: index), columnIndexes:NSIndexSet(indexesInRange: NSMakeRange(0,self.myTableView.numberOfColumns)))
							self.updateTotalProgress()
						}
					}
				}

				dispatch_group_leave(downloadGroup)
			})
			
			DownloadFileManager.sharedManager.downloadFile(file, progressWrapper: progressWrapper, completionWrapper: completionWrapper)
		}
		
		dispatch_group_notify(downloadGroup,dispatch_get_main_queue(),{ [unowned self] in
            self.stopDownloading()
		})
	}
	
	func startDownloading () {
		
		isDownloading = true

		startDownload.title = "Stop Downloading"
		
		searchField.enabled = false;
		
		disableUIForDownloading()
		
		yearFetchIndicator.startAnimation(nil)
		
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
		updateTotalFileSize()
		
		myTableView.reloadData()
		
		downloadFiles(filesToDownload)
	}
	
	func stopDownloading () {
		
		isDownloading = false

		startDownload.title = "Start Downloading"
		
		searchField.enabled = true

		reEnableUIWhenStoppedDownloading()
		
		yearFetchIndicator.stopAnimation(nil)
		
		filesToDownload.removeAll()
		
		myTableView.reloadData()
		
		print("Completed File Downloads")
	}
	
	func resetDownloadUI() {
		
		currentlabel.stringValue = ""
		oflabel.hidden = true
		totallabel.stringValue = byteFormatter.stringFromByteCount(0)
		downloadProgressView.doubleValue = 0
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
	
	
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

