//
//  ResizeAwareTableView.swift
//  WWDC
//
//  Created by David Roberts on 15/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa

class ResizeAwareTableView : NSTableView {
	
	override func viewDidEndLiveResize() {
		super.viewDidEndLiveResize()
		
		if self.inLiveResize == false {
			self.reloadData()
		}
	}
	
	override func mouseDown(theEvent: NSEvent) {
		
		let indexes = self.selectedRowIndexes
		
		let windowLocation = theEvent.locationInWindow
		
		let localLocation = self.convertPoint(windowLocation, fromView: nil)
		
		var deselect = false
		
		if indexes.count == 1 {
			if self.isRowSelected(self.rowAtPoint(localLocation)) == true {
				deselect = true
			}
		}
		
		super.mouseDown(theEvent)

		if deselect {
			self.deselectAll(nil)
		}
	}
	
	override func menuForEvent(event: NSEvent) -> NSMenu? {
		
		let windowLocation = event.locationInWindow
		
		let localLocation = self.convertPoint(windowLocation, fromView: nil)
		
		let rowClicked = self.rowAtPoint(localLocation)
		
		if self.isRowSelected(rowClicked) == false {
			self.selectRowIndexes(NSIndexSet(index: rowClicked), byExtendingSelection: false)
		}
				
		return super.menuForEvent(event)
	}
	
}