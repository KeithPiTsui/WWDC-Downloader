//
//  FileButton.swift
//  WWDC
//
//  Created by David Roberts on 22/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa

class FileButton : NSButton {
	
	override func menuForEvent(event: NSEvent) -> NSMenu? {
		let menu = super.menuForEvent(event) as! ReferencedMenu
		menu.menuCalledFromView = self
		return menu
	}

}
