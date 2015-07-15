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
}