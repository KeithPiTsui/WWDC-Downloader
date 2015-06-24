//
//  ViewController.swift
//  WWDCapp
//
//  Created by David Roberts on 19/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Cocoa

class CheckBoxTableViewCell : NSTableCellView {
	
	var file : FileInfo?
	
	@IBOutlet weak var checkBox: NSButton!
	@IBOutlet weak var label: NSTextField!
	
	@IBOutlet weak var progressView: NSProgressIndicator!
	
	@IBOutlet weak var downloadComplete: NSButton!
	
	@IBAction func checked(sender: NSButton) {
		if let file = file {
			file.shouldDownloadFile = Bool(sender.state)
		}
	}
	
	func updateCell(isSessionInfoFetchComplete:Bool) {
		
		self.downloadComplete.hidden = true

		if let file = file {
			
			// visible
			if let fileSize = file.fileSize {
				self.checkBox.hidden = false
				self.label.hidden = false
				
				// Progress
				if file.isFileAlreadyDownloaded {
					self.progressView.hidden = true
					self.label.hidden = true
					self.checkBox.hidden = true
					self.downloadComplete.hidden = false
				}
				else {
					if file.downloadProgress > 0 {
						self.progressView.hidden = false
						self.progressView.doubleValue = Double(file.downloadProgress)
						self.label.stringValue = NSByteCountFormatter().stringFromByteCount(Int64(file.downloadProgress*Float(fileSize)))
					}
					else {
						self.progressView.hidden = true
						self.label.stringValue = NSByteCountFormatter().stringFromByteCount(Int64(fileSize))
					}
				}				
			}
			else {
				self.checkBox.hidden = true
				self.label.hidden = true
				self.progressView.hidden = true
			}
			
			// enabled
			if (isSessionInfoFetchComplete) {
				
				self.checkBox.enabled = true
				
				if file.shouldDownloadFile == true {
					self.checkBox.state = 1
				}
				else {
					self.checkBox.state = 0
				}
			}
			else {
				self.checkBox.enabled = false
			}
		}

	}
}

class ViewController: NSViewController, NSURLSessionDelegate, NSURLSessionDataDelegate, NSTableViewDataSource, NSTableViewDelegate {

	@IBOutlet weak var yearSeletor: NSPopUpButton!
	@IBOutlet weak var yearFetchIndicator: NSProgressIndicator!

	@IBOutlet weak var allCodeCheckbox: NSButton!
	@IBOutlet weak var allSDCheckBox: NSButton!
	@IBOutlet weak var allHDCheckBox: NSButton!
	@IBOutlet weak var allPDFCheckBox: NSButton!
	
	@IBOutlet weak var startDownload: NSButton!
	
	@IBOutlet weak var myTableView: NSTableView!
	
	
	var allWWDCSessionsArray : [WWDCSession] = []

	private var downloadSessionInfo : DownloadSessionInfo?
	
	private var isSessionInfoFetchComplete = false
	
	private var isDownloading = false
	
	// MARK: - Init
	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
	
	// MARK: - ACTIONS
	@IBAction func yearSelected(sender: NSPopUpButton) {
		
		isSessionInfoFetchComplete = false
		allWWDCSessionsArray.removeAll()
		myTableView.reloadData()

        guard let title = sender.selectedItem?.title else { return }
        
        switch title {
            case "2015":
                fetchSessionInfoForYear(.WWDC2015)
            case "2014":
                fetchSessionInfoForYear(.WWDC2014)
            case "2013":
                fetchSessionInfoForYear(.WWDC2013)
            default:
                fetchSessionInfoForYear(.WWDC2015)
        }
	}
	
	@IBAction func allCodeChecked(sender: NSButton) {
		
		for wwdcSession in allWWDCSessionsArray {
			for code in wwdcSession.sampleCodeArray {
				code.shouldDownloadFile = Bool(sender.state)
			}
		}
		
		myTableView.reloadData()
	}
	
	@IBAction func allSDChecked(sender: NSButton) {
		
		for wwdcSession in allWWDCSessionsArray {
			wwdcSession.sdFile?.shouldDownloadFile = Bool(sender.state)
		}
		
		myTableView.reloadData()
	}
	
	@IBAction func allHDChecked(sender: NSButton) {
		
		for wwdcSession in allWWDCSessionsArray {
			wwdcSession.hdFile?.shouldDownloadFile = Bool(sender.state)
		}
		
		myTableView.reloadData()
	}
	
	
	@IBAction func allPDFChecked(sender: NSButton) {
		
		for wwdcSession in allWWDCSessionsArray {
			wwdcSession.pdfFile?.shouldDownloadFile = Bool(sender.state)
		}
		
		myTableView.reloadData()
	}
	
	@IBAction func startDownloadButton(sender: NSButton) {
		
		if isDownloading {
			
			sender.title = "Start Downloading"

			isDownloading = false
			
			stopDownloading()
			
			enableUI()
			
			yearFetchIndicator.stopAnimation(nil)
		}
		else {
			
			sender.title = "Stop Downloading"
			
			isDownloading = true
			
			disableUI()
			
			yearFetchIndicator.startAnimation(nil)
			
			var filesToDownload : [FileInfo] = []
			
			for wwdcSession in self.allWWDCSessionsArray {
				
				if let file = wwdcSession.sdFile where (wwdcSession.sdFile?.shouldDownloadFile == true && wwdcSession.sdFile?.fileSize > 0) {
					filesToDownload.append(file)
				}
				
				if let file = wwdcSession.hdFile  where (wwdcSession.hdFile?.shouldDownloadFile == true && wwdcSession.hdFile?.fileSize > 0) {
					filesToDownload.append(file)
				}
				
				if let file = wwdcSession.pdfFile  where (wwdcSession.pdfFile?.shouldDownloadFile == true && wwdcSession.pdfFile?.fileSize > 0) {
					filesToDownload.append(file)
				}
			}
			
			downloadFiles(filesToDownload)
		}
	}
	
	

	// MARK: - View
    override func viewDidLoad() {
        super.viewDidLoad()
		
		myTableView.setDelegate(self)
		myTableView.setDataSource(self)
		
		myTableView.allowsColumnSelection = false
		myTableView.allowsMultipleSelection = false
		myTableView.allowsEmptySelection = false
		
		
		myTableView.reloadData()
		
		fetchSessionInfoForYear(.WWDC2015)
	}
	
	func disableUI() {
		
		yearSeletor.enabled = false
		
		allPDFCheckBox.enabled = false
		allSDCheckBox.enabled = false
		allHDCheckBox.enabled = false
		allCodeCheckbox.enabled = false
	}
	
	func enableUI() {
		
		yearSeletor.enabled = true
		
		allPDFCheckBox.enabled = true
		allSDCheckBox.enabled = true
		allHDCheckBox.enabled = true
		allCodeCheckbox.enabled = true
	}
	
	func fetchSessionInfoForYear(year : WWDCYear) {
		
		yearFetchIndicator.startAnimation(nil)
		
		disableUI()
		
		downloadSessionInfo = DownloadSessionInfo(year: year, parsingCompleteHandler: { [unowned self] (sessions) -> Void in
			
				self.allWWDCSessionsArray = sessions
			
				dispatch_async(dispatch_get_main_queue()) {
					self.myTableView.reloadData()
				}
			},
			individualSessionUpdateHandler: { [unowned self] (session) -> Void in
				
				dispatch_async(dispatch_get_main_queue()) {
					if let index = self.allWWDCSessionsArray.indexOf(session) {
						self.myTableView.reloadDataForRowIndexes(NSIndexSet(index: index), columnIndexes:NSIndexSet(indexesInRange: NSMakeRange(0,self.myTableView.numberOfColumns)))
					}
				}
			},
			completionHandler: {
				
				print("ALL \(year) INFO DOWNLOADED")
				
				dispatch_async(dispatch_get_main_queue()) {

					self.isSessionInfoFetchComplete = true

					self.yearFetchIndicator.stopAnimation(nil)

					self.startDownload.enabled = true

					self.myTableView.reloadData()
					
					self.enableUI()
				}
			})
	}
	
	
	// MARK: - TableView
	func numberOfRowsInTableView(tableView: NSTableView) -> Int {
		return self.allWWDCSessionsArray.count
	}
	
	func selectionShouldChangeInTableView(tableView: NSTableView) -> Bool {
		return false
	}
	
	func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
		
		if tableColumn?.identifier == "sessionID" {

			let cell = (tableView.makeViewWithIdentifier("sessionID", owner: self) as? NSTableCellView)!
			
			cell.textField?.stringValue = allWWDCSessionsArray[row].sessionID
			
			return cell
		}
		else if tableColumn?.identifier == "sessionName" {
			
			let cell = (tableView.makeViewWithIdentifier("sessionName", owner: self) as? NSTableCellView)!
			
			cell.textField?.stringValue = allWWDCSessionsArray[row].title
			
			return cell
		}
		else if tableColumn?.identifier == "PDF" {
			
			let cell = (tableView.makeViewWithIdentifier("PDF", owner: self) as? CheckBoxTableViewCell)!
			
			let wwdcSession = allWWDCSessionsArray[row]
		
			cell.checkBox.hidden = true
			cell.label.hidden = true
			cell.progressView.hidden = true
			cell.downloadComplete.hidden = true

			if let file = wwdcSession.pdfFile {
				cell.file = file
				cell.updateCell(isSessionInfoFetchComplete)
			}
			
			return cell
		}
		else if tableColumn?.identifier == "SD" {
			
			let cell = (tableView.makeViewWithIdentifier("SD", owner: self) as? CheckBoxTableViewCell)!
			
			let wwdcSession = allWWDCSessionsArray[row]
			
			cell.checkBox.hidden = true
			cell.label.hidden = true
			cell.progressView.hidden = true
			cell.downloadComplete.hidden = true

			if let file = wwdcSession.sdFile {
				cell.file = file
				cell.updateCell(isSessionInfoFetchComplete)
			}
			
			return cell
		}
		else if tableColumn?.identifier == "HD" {
			
			let cell = (tableView.makeViewWithIdentifier("HD", owner: self) as? CheckBoxTableViewCell)!
			
			let wwdcSession = allWWDCSessionsArray[row]
			
			cell.checkBox.hidden = true
			cell.label.hidden = true
			cell.progressView.hidden = true
			cell.downloadComplete.hidden = true

			if let file = wwdcSession.hdFile {
				cell.file = file
				cell.updateCell(isSessionInfoFetchComplete)
			}
			
			return cell
		}
		else if tableColumn?.identifier == "Code" {
			
			let cell = (tableView.makeViewWithIdentifier("Code", owner: self) as? CheckBoxTableViewCell)!
			
			let wwdcSession = allWWDCSessionsArray[row]
			
			cell.checkBox.hidden = true
			cell.label.hidden = true
			cell.progressView.hidden = true
			cell.downloadComplete.hidden = true

			configureCodeCell(cell, session: wwdcSession)
			
			return cell
		}
		else {
			return nil
		}
		
	}
	
	func configureCodeCell(cell : CheckBoxTableViewCell, session: WWDCSession) {
		
		// visible
		if session.sampleCodeArray.count > 0 {
			cell.checkBox.hidden = false
			cell.label.hidden = false

			var fileSizeTotal : Int = 0
			
			for file in session.sampleCodeArray {
				if let size = file.fileSize {
					fileSizeTotal += size
				}
			}
			
			cell.label.stringValue = NSByteCountFormatter().stringFromByteCount(Int64(fileSizeTotal))
		}
		else {
			cell.checkBox.hidden = true
			cell.label.hidden = true
			cell.progressView.hidden = true
		}
		
		// enabled
		if (isSessionInfoFetchComplete) {
			
			if session.sampleCodeArray.count > 0 {

				cell.checkBox.enabled = true
				
				if session.sampleCodeArray.first?.shouldDownloadFile == true {
					cell.checkBox.state = 1
				}
				else {
					cell.checkBox.state = 0
				}
			}
			else {
				cell.checkBox.enabled = false
			}
		}
		else {
			cell.checkBox.enabled = false
		}
	}
	
	
	// MARK: - Download Convenience
	func  downloadFiles(files : [FileInfo] ) {
		
		print("Total Files to download - \(files.count)")
		
		let downloadGroup = dispatch_group_create();
		
		for file in files {
			
			dispatch_group_enter(downloadGroup);
			
			let progressWrapper = ProgressWrapper(handler: { [unowned self] (progress) -> Void in
				//print("\(file.displayName!) - \(progress)")
				
				dispatch_async(dispatch_get_main_queue()) {
					if let index = self.allWWDCSessionsArray.indexOf(file.session) {
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
					}
				}

			})
			
			let completionWrapper = SimpleCompletionWrapper(handler: { (success) -> Void in
				
				if success {
					
					file.downloadProgress = 1
					
					print("Download SUCCESS - \(file.displayName!)")
				}
				else {
					print("Download Fail - \(file.displayName!)")
				}
				
				dispatch_async(dispatch_get_main_queue()) {
					if let index = self.allWWDCSessionsArray.indexOf(file.session) {
						self.myTableView.reloadDataForRowIndexes(NSIndexSet(index: index), columnIndexes:NSIndexSet(indexesInRange: NSMakeRange(0,self.myTableView.numberOfColumns)))
					}
				}
				
				dispatch_group_leave(downloadGroup)
			})
			
			DownloadFileManager.sharedManager.downloadFile(file, progressWrapper: progressWrapper, completionWrapper: completionWrapper)
		}
		
		dispatch_group_notify(downloadGroup,dispatch_get_main_queue(),{ [unowned self] in
			
			self.isDownloading = false
			
			self.enableUI()
			
			self.yearFetchIndicator.stopAnimation(nil)
			
			print("Finished All File Downloads")
		})
	}
	
	func stopDownloading () {
		
		DownloadFileManager.sharedManager.stopDownloads()
	}
	
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

