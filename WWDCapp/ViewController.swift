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

	private var downloadSessionInfo : DownloadSessionInfo?
	
	private var isSessionInfoFetchComplete = false
	
	private var isDownloading = false
    private var filesToDownload : [FileInfo] = []
    private var totalBytesToDownload : Int64 = 0
	
	// MARK: - Init
	required init?(coder: NSCoder) {
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
	
	@IBAction func allCodeChecked(sender: NSButton) {
		
		for wwdcSession in allWWDCSessionsArray {
			for code in wwdcSession.sampleCodeArray {
				code.shouldDownloadFile = Bool(sender.state)
			}
		}
		
		myTableView.reloadData()
        
        updateTotalFileSize()
	}
	
	@IBAction func allSDChecked(sender: NSButton) {
		
		for wwdcSession in allWWDCSessionsArray {
			wwdcSession.sdFile?.shouldDownloadFile = Bool(sender.state)
		}
		
		myTableView.reloadData()
        
        updateTotalFileSize()
	}
	
	@IBAction func allHDChecked(sender: NSButton) {
		
		for wwdcSession in allWWDCSessionsArray {
			wwdcSession.hdFile?.shouldDownloadFile = Bool(sender.state)
		}
		
		myTableView.reloadData()
        
        updateTotalFileSize()
	}
	
	
	@IBAction func allPDFChecked(sender: NSButton) {
		
		for wwdcSession in allWWDCSessionsArray {
			wwdcSession.pdfFile?.shouldDownloadFile = Bool(sender.state)
		}
		
		myTableView.reloadData()
        
        updateTotalFileSize()
	}
	
	@IBAction func startDownloadButton(sender: NSButton) {
		
		if isDownloading {
			
			sender.title = "Start Downloading"
            
			isDownloading = false
			
			stopDownloading()
			
			enableUI()
			
			yearFetchIndicator.stopAnimation(nil)
            
            filesToDownload.removeAll()
		}
		else {
			
			sender.title = "Stop Downloading"
            
            oflabel.hidden = false
            currentlabel.hidden = false
            totallabel.hidden = false
            downloadProgressView.hidden = false
            
            currentlabel.stringValue = NSByteCountFormatter().stringFromByteCount(0)
			
			isDownloading = true
			
			disableUI()
			
			yearFetchIndicator.startAnimation(nil)
			
            filesToDownload.removeAll()
            
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

			updateTotalProgress()
            
			downloadFiles(filesToDownload)
		}
	}
    
	

	// MARK: - View / UI
    override func viewDidLoad() {
        super.viewDidLoad()
		
		myTableView.setDelegate(self)
		myTableView.setDataSource(self)
		
		myTableView.allowsColumnSelection = false
		myTableView.allowsMultipleSelection = false
		myTableView.allowsEmptySelection = false
        
        oflabel.hidden = true
        currentlabel.hidden = true
		
		allPDFCheckBox.enabled = false
		allSDCheckBox.enabled = false
		allHDCheckBox.enabled = false
		allCodeCheckbox.enabled = false
		
		myTableView.reloadData()
        
        updateTotalFileSize()
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
	
	func updateTotalProgress() {
		
		var currentDownloadBytes : Int64 = 0
		
		for file in filesToDownload {
			if let fileSize = file.fileSize {
				currentDownloadBytes += Int64(file.downloadProgress*Float(fileSize))
			}
		}
		
		currentlabel.stringValue = NSByteCountFormatter().stringFromByteCount(currentDownloadBytes)
		
		let progress = Double(currentDownloadBytes)/Double(totalBytesToDownload)
		
		downloadProgressView.doubleValue = progress
	}
	
	func updateTotalFileSize() {
		
		totalBytesToDownload = 0
		
		for wwdcSession in self.allWWDCSessionsArray {
			
			if let file = wwdcSession.sdFile where (wwdcSession.sdFile?.shouldDownloadFile == true && wwdcSession.sdFile?.fileSize > 0) {
				if let fileSize = file.fileSize {
					totalBytesToDownload += Int64(fileSize)
				}
			}
			if let file = wwdcSession.hdFile  where (wwdcSession.hdFile?.shouldDownloadFile == true && wwdcSession.hdFile?.fileSize > 0) {
				if let fileSize = file.fileSize {
					totalBytesToDownload += Int64(fileSize)
				}
			}
			if let file = wwdcSession.pdfFile  where (wwdcSession.pdfFile?.shouldDownloadFile == true && wwdcSession.pdfFile?.fileSize > 0) {
				if let fileSize = file.fileSize {
					totalBytesToDownload += Int64(fileSize)
				}
			}
			
			for sample in wwdcSession.sampleCodeArray {
				if let fileSize = sample.fileSize {
					if sample.shouldDownloadFile == true && fileSize > 0 {
						totalBytesToDownload += Int64(fileSize)
					}
				}
			}
		}
		
		totallabel.stringValue = NSByteCountFormatter().stringFromByteCount(totalBytesToDownload)
	}


	
	// MARK: Fetch Year Info
	func fetchSessionInfoForYear(year : WWDCYear) {
		
		isSessionInfoFetchComplete = false
		allWWDCSessionsArray.removeAll()
		myTableView.reloadData()
		
		yearFetchIndicator.startAnimation(nil)
		
		disableUI()
		
		downloadSessionInfo = DownloadSessionInfo(year: year, parsingCompleteHandler: { [unowned self] (sessions) -> Void in
			
				self.allWWDCSessionsArray = sessions
			
				dispatch_async(dispatch_get_main_queue()) {
					self.myTableView.reloadData()
				}
			},
			individualSessionUpdateHandler: { [unowned self] (session) -> Void in
				
				if let index = self.allWWDCSessionsArray.indexOf(session) {
					dispatch_async(dispatch_get_main_queue()) {
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
		
			cell.resetCell()

			if let file = wwdcSession.pdfFile {
				cell.fileArray = [file]
				cell.updateCell(isSessionInfoFetchComplete)
			}
			
			if wwdcSession.isInfoFetchComplete {
				cell.loadingProgressView.stopAnimation(nil)
			}
			else {
				cell.loadingProgressView.startAnimation(nil)
			}
			
			return cell
		}
		else if tableColumn?.identifier == "SD" {
			
			let cell = (tableView.makeViewWithIdentifier("SD", owner: self) as? CheckBoxTableViewCell)!
			
			let wwdcSession = allWWDCSessionsArray[row]
			
			cell.resetCell()

			if let file = wwdcSession.sdFile {
				cell.fileArray = [file]
				cell.updateCell(isSessionInfoFetchComplete)
			}
			
			if wwdcSession.isInfoFetchComplete {
				cell.loadingProgressView.stopAnimation(nil)
			}
			else {
				cell.loadingProgressView.startAnimation(nil)
			}
			
			return cell
		}
		else if tableColumn?.identifier == "HD" {
			
			let cell = (tableView.makeViewWithIdentifier("HD", owner: self) as? CheckBoxTableViewCell)!
			
			let wwdcSession = allWWDCSessionsArray[row]
			
			cell.resetCell()

			if let file = wwdcSession.hdFile {
				cell.fileArray = [file]
				cell.updateCell(isSessionInfoFetchComplete)
			}
			
			if wwdcSession.isInfoFetchComplete {
				cell.loadingProgressView.stopAnimation(nil)
			}
			else {
				cell.loadingProgressView.startAnimation(nil)
			}
			
			return cell
		}
		else if tableColumn?.identifier == "Code" {
			
			let cell = (tableView.makeViewWithIdentifier("Code", owner: self) as? CheckBoxTableViewCell)!
			
			let wwdcSession = allWWDCSessionsArray[row]
			
			cell.resetCell()

			if wwdcSession.sampleCodeArray.count > 0 {
				cell.fileArray = wwdcSession.sampleCodeArray
				cell.updateCell(isSessionInfoFetchComplete)
			}
			
			if wwdcSession.isInfoFetchComplete {
				cell.loadingProgressView.stopAnimation(nil)
			}
			else {
				cell.loadingProgressView.startAnimation(nil)
			}
			
			return cell
		}
		else {
			return nil
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
                    
                    self.updateTotalProgress()
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
                    
                    self.updateTotalProgress()
				}
				
				dispatch_group_leave(downloadGroup)
			})
			
			DownloadFileManager.sharedManager.downloadFile(file, progressWrapper: progressWrapper, completionWrapper: completionWrapper)
		}
		
		dispatch_group_notify(downloadGroup,dispatch_get_main_queue(),{ [unowned self] in
			
			self.yearFetchIndicator.stopAnimation(nil)
            
            self.startDownload.title = "Start Downloading"
            
            self.isDownloading = false
            
            self.stopDownloading()
            
            self.enableUI()
            
            self.filesToDownload.removeAll()
			
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

