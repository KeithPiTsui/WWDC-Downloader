//
//  ViewController.swift
//  WWDCapp
//
//  Created by David Roberts on 19/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSURLSessionDelegate, NSURLSessionDataDelegate, NSTableViewDataSource, NSTableViewDelegate {

	var allWWDCSessionsArray : [WWDCSession] = []

	@IBOutlet weak var yearSeletor: NSPopUpButton!

	@IBOutlet weak var definition: NSSegmentedControl!
	
	@IBOutlet weak var allCodeCheckbox: NSButton!
	@IBOutlet weak var allVideoCheckBox: NSButton!
	@IBOutlet weak var allPDFCheckBox: NSButton!
	
	@IBOutlet weak var startDownload: NSButton!
	
	@IBOutlet weak var yearFetchIndicator: NSProgressIndicator!
	
	@IBOutlet weak var myTableView: NSTableView!
	
	
	@IBAction func yearSelected(sender: NSPopUpButton) {
		
		allWWDCSessionsArray.removeAll()
		myTableView.reloadData()

		if sender.selectedItem?.title == "2015" {
			fetchSessionInfoForYear(.WWDC2015)
		}
		else if sender.selectedItem?.title == "2014" {
			fetchSessionInfoForYear(.WWDC2014)
		}
	}
	
	@IBAction func selectDefinition(sender: AnyObject) {
		
	}
	
	@IBAction func allCodeChecked(sender: AnyObject) {
		
	}
	
	@IBAction func allVideoChecked(sender: AnyObject) {
		
	}
	
	@IBAction func allPDFChecked(sender: AnyObject) {
		
	}
	
	@IBAction func startDownloadButton(sender: AnyObject) {
		
		self.downloadPDF(self.allWWDCSessionsArray)
	}
	
	
	
	
	private var downloadSessionInfo : DownloadSessionInfo?

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
	
	func fetchSessionInfoForYear(year : WWDCYear) {
		
		yearFetchIndicator.startAnimation(nil)
		
		allCodeCheckbox.enabled = false
		allVideoCheckBox.enabled = false
		allPDFCheckBox.enabled = false
		definition.enabled = false

		downloadSessionInfo = DownloadSessionInfo(year: year, completionHandler: { [unowned self] (sessions) -> Void in
			
				print("ALL \(year) INFO DOWNLOADED")
				
				var tempArray = Array(sessions)
				tempArray.sortInPlace({ $1.sessionID > $0.sessionID })
				self.allWWDCSessionsArray = tempArray
				
				self.yearFetchIndicator.stopAnimation(nil)
				
				self.startDownload.enabled = true
				
				self.myTableView.reloadData()
			})
	}
	
	
	func numberOfRowsInTableView(tableView: NSTableView) -> Int {
		return self.allWWDCSessionsArray.count
	}
	
//	- (NSView *)tableView:(NSTableView *)tableView
//	viewForTableColumn:(NSTableColumn *)tableColumn
//	row:(NSInteger)row {
// 
//	// Retrieve to get the @"MyView" from the pool or,
//	// if no version is available in the pool, load the Interface Builder version
//	NSTableCellView *result = [tableView makeViewWithIdentifier:@"MyView" owner:self];
// 
//	// Set the stringValue of the cell's text field to the nameArray value at row
//	result.textField.stringValue = [self.nameArray objectAtIndex:row];
// 
//	// Return the result
//	return result;
	
	
	func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
		
		let cell : NSTableCellView?
		
		if tableColumn?.identifier == "sessionID" {
			cell = (tableView.makeViewWithIdentifier("sessionID", owner: self) as? NSTableCellView)!
			
			if let aCell = cell {
				aCell.textField?.stringValue = allWWDCSessionsArray[row].sessionID
			}
		}
		else if tableColumn?.identifier == "sessionName" {
			cell = (tableView.makeViewWithIdentifier("sessionName", owner: self) as? NSTableCellView)!
			
			if let aCell = cell {
				aCell.textField?.stringValue = allWWDCSessionsArray[row].title
			}
		}
		else {
			cell = nil
		}
		
		
		return cell
	}
	
	
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

