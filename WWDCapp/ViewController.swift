//
//  ViewController.swift
//  WWDCapp
//
//  Created by David Roberts on 19/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Cocoa

class OneCheckBoxTableViewCell : NSTableCellView {
	
	@IBOutlet weak var checkBox: NSButton!
	@IBOutlet weak var progressView: NSProgressIndicator!

}

class TwoCheckBoxTableViewCell : NSTableCellView {
	
	@IBOutlet weak var checkBoxHD: NSButton!
	@IBOutlet weak var checkBoxSD: NSButton!

	@IBOutlet weak var progressView: NSProgressIndicator!
}

class ViewController: NSViewController, NSURLSessionDelegate, NSURLSessionDataDelegate, NSTableViewDataSource, NSTableViewDelegate {

	@IBOutlet weak var yearSeletor: NSPopUpButton!
	@IBOutlet weak var definition: NSSegmentedControl!
	@IBOutlet weak var allCodeCheckbox: NSButton!
	@IBOutlet weak var allVideoCheckBox: NSButton!
	@IBOutlet weak var allPDFCheckBox: NSButton!
	@IBOutlet weak var startDownload: NSButton!
	@IBOutlet weak var yearFetchIndicator: NSProgressIndicator!
	@IBOutlet weak var myTableView: NSTableView!
	
	
	var allWWDCSessionsArray : [WWDCSession] = []

	private var downloadSessionInfo : DownloadSessionInfo?
	
	private var isSessionInfoFetchComplete = false
	
	
	// MARK: - ACTIONS
	@IBAction func yearSelected(sender: NSPopUpButton) {
		
		isSessionInfoFetchComplete = false
		definition.selectedSegment = 1
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
	
	@IBAction func selectDefinition(sender: NSSegmentedControl) {
		
		for wwdcSession in allWWDCSessionsArray {
			if sender.selectedSegment == 0 {
				wwdcSession.sdFile?.shouldDownloadFile = true
				wwdcSession.hdFile?.shouldDownloadFile = false
			}
			else if sender.selectedSegment == 1 {
				wwdcSession.hdFile?.shouldDownloadFile = true
				wwdcSession.sdFile?.shouldDownloadFile = false
			}
			else if sender.selectedSegment == 2 {
				
				wwdcSession.hdFile?.shouldDownloadFile = true
				wwdcSession.sdFile?.shouldDownloadFile = true
			}
		}
		
		myTableView.reloadData()
	}
	
	@IBAction func allCodeChecked(sender: NSButton) {
		
		for wwdcSession in allWWDCSessionsArray {
			for code in wwdcSession.sampleCodeArray {
				code.shouldDownloadFile = Bool(sender.state)
			}
		}
		
		myTableView.reloadData()
	}
	
	@IBAction func allVideoChecked(sender: NSButton) {
		
		for wwdcSession in allWWDCSessionsArray {
			wwdcSession.hdFile?.shouldDownloadFile = Bool(sender.state)
			wwdcSession.sdFile?.shouldDownloadFile = Bool(sender.state)
		}
		
		myTableView.reloadData()
	}
	
	@IBAction func allPDFChecked(sender: NSButton) {
		
		for wwdcSession in allWWDCSessionsArray {
			wwdcSession.pdfFile?.shouldDownloadFile = Bool(sender.state)
		}
		
		myTableView.reloadData()
	}
	
	@IBAction func startDownloadButton(sender: AnyObject) {
		
		self.downloadPDF(self.allWWDCSessionsArray)
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
		
		fetchSessionInfoForYear(.WWDC2013)
	}
	
	func fetchSessionInfoForYear(year : WWDCYear) {
		
		yearFetchIndicator.startAnimation(nil)
		
		allCodeCheckbox.enabled = false
		allVideoCheckBox.enabled = false
		allPDFCheckBox.enabled = false
		definition.enabled = false

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
					
					self.allPDFCheckBox.enabled = true
					self.allVideoCheckBox.enabled = true
					self.allCodeCheckbox.enabled = true
					self.definition.enabled = true
				}
			})
	}
	
	
	// MARK: - TableView
	func numberOfRowsInTableView(tableView: NSTableView) -> Int {
		return self.allWWDCSessionsArray.count
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
			
			let cell = (tableView.makeViewWithIdentifier("PDF", owner: self) as? OneCheckBoxTableViewCell)!
			
			let fileInfo = allWWDCSessionsArray[row]
		
			cell.checkBox.hidden = true
			cell.checkBox.enabled = false
			cell.progressView.hidden = true

			if let _ = fileInfo.pdfFile?.fileSize {
				cell.checkBox.hidden = false
			}
			else {
				cell.checkBox.hidden = true
			}
			
			if (isSessionInfoFetchComplete && fileInfo.pdfFile?.shouldDownloadFile == true) {
				cell.checkBox.enabled = true
			}
			else {
				cell.checkBox.enabled = false
			}
			
			return cell
		}
		else if tableColumn?.identifier == "Videos" {
			
			let cell = (tableView.makeViewWithIdentifier("Videos", owner: self) as? TwoCheckBoxTableViewCell)!
			
			let fileInfo = allWWDCSessionsArray[row]

			cell.checkBoxHD.hidden = true
			cell.checkBoxHD.enabled = false
			cell.checkBoxSD.hidden = true
			cell.checkBoxSD.enabled = false
			cell.progressView.hidden = true

			if let _ = fileInfo.sdFile?.fileSize {
				cell.checkBoxSD.hidden = false
			}
			else {
				cell.checkBoxSD.hidden = true
			}
			
			if let _ = fileInfo.hdFile?.fileSize {
				cell.checkBoxHD.hidden = false
			}
			else {
				cell.checkBoxHD.hidden = true
			}
			
			if (isSessionInfoFetchComplete && fileInfo.hdFile?.shouldDownloadFile == true) {
				cell.checkBoxHD.enabled = true
			}
			else {
				cell.checkBoxHD.enabled = false
			}
			
			if (isSessionInfoFetchComplete && fileInfo.sdFile?.shouldDownloadFile == true) {
				cell.checkBoxSD.enabled = true
			}
			else {
				cell.checkBoxSD.enabled = false
			}
			
			return cell
		}
		else if tableColumn?.identifier == "Code" {
			
			let cell = (tableView.makeViewWithIdentifier("Code", owner: self) as? OneCheckBoxTableViewCell)!
			
			let fileInfo = allWWDCSessionsArray[row]
			
			cell.checkBox.hidden = true
			cell.checkBox.enabled = false
			cell.progressView.hidden = true

			if fileInfo.sampleCodeArray.count > 0 {
				cell.checkBox.hidden = false
			}
			else {
				cell.checkBox.hidden = true
			}
			
			if (isSessionInfoFetchComplete) {
				cell.checkBox.enabled = true
			}
			else {
				cell.checkBox.enabled = false
			}
			
			return cell
		}
		else {
			return nil
		}
		
	}
	
	
	// MARK: - Download Convenience
    func  downloadPDF(forSessions : [WWDCSession] ) {
		
		let pdfDownloadGroup = dispatch_group_create();

        for wwdcSession in forSessions {
            
            if let file = wwdcSession.pdfFile {
				
				dispatch_group_enter(pdfDownloadGroup);

                let progressWrapper = ProgressWrapper(handler: { (progress) -> Void in
                    
                })
                
                let completionWrapper = SimpleCompletionWrapper(handler: { (success) -> Void in
                    
                    if success {
                        print("PDF Download SUCCESS - \(file.displayName!)")
                    }
                    else {
                        print("PDF Download Fail - \(file.displayName!)")
                    }
					
					dispatch_group_leave(pdfDownloadGroup)
                })
                
                DownloadFileManager.sharedManager.downloadFile(file, progressWrapper: progressWrapper, completionWrapper: completionWrapper)
            }
        }
		
		dispatch_group_notify(pdfDownloadGroup,dispatch_get_main_queue(),{
				print("Finished All PDF Downloads")
			})
    }
    
    func  downloadCodeSamples(forSessions : [WWDCSession] ) {
        
        for wwdcSession in forSessions {
            
           for file in wwdcSession.sampleCodeArray {
                
                let progressWrapper = ProgressWrapper(handler: { (progress) -> Void in
                    
                })
                
                let completionWrapper = SimpleCompletionWrapper(handler: { (success) -> Void in
                    
                    if success {
                        print("Completion Wrapper SUCCESS - \(file.displayName!)")
                    }
                    else {
                        print("Completion Wrapper Fail - \(file.displayName!)")
                    }
                })
                
                DownloadFileManager.sharedManager.downloadFile(file, progressWrapper: progressWrapper, completionWrapper: completionWrapper)
            }
        }
    }

    
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

