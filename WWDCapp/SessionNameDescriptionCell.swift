//
//  SessionNameDescriptionCell.swift
//  WWDC
//
//  Created by David Roberts on 30/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa

class SessionNameDescriptionCell : NSTableCellView {

	@IBOutlet var descriptionField: NSTextField!
	
	override func awakeFromNib() {

	}
	
	func resetCell() {
		
		textField!.stringValue = ""
		descriptionField.stringValue = ""
	}
	
	func updateCell(name:String, description:String?, descriptionVisible:Bool) {
	
		textField!.stringValue = name
		
		if let description = description {
			descriptionField.stringValue = description
		}
		else {
			descriptionField.stringValue = ""
		}
		
		if descriptionVisible {
			
		}
		else {
			
			
		}
	}
	
}
