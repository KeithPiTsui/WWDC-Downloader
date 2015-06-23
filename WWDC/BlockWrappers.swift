//
//  BlockWrappers.swift
//  WWDC
//
//  Created by David Roberts on 17/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation

// MARK: - Base Class
@objc class BlockWrapper : NSObject {
	
}

// MARK: - Progress Wrapper
@objc class ProgressWrapper : BlockWrapper {
	
	// MARK: - Instance Variables
	
	private let block: ProgressHandler
	private var valid: Bool = true
	
	// MARK: - Instance Methods
	
	init(handler: ProgressHandler) {
		self.block = handler
		super.init()
	}
	
	// MARK: - Helper Methods
	
	func invalidate() {
		valid = false;
	}
	
	func execute(progress: Float) -> Bool {
		if valid == true {
			block(progress: progress)
			return true
		}
		return false
	}
}

// MARK: - Simple Completion Wrapper (Only Success bool)
@objc class SimpleCompletionWrapper : BlockWrapper {
	
	// MARK: - Instance Variables
	
	private let block: SimpleCompletionHandler
	private var valid: Bool = true
	
	// MARK: - Instance Methods
	
	init(handler: SimpleCompletionHandler) {
		self.block = handler
		super.init()
	}
	
	// MARK: - Helper Methods
	func invalidate() {
		valid = false;
	}
	
	func execute(success: Bool) -> Bool {
		if valid == true {
			block(success: success)
			return true
		}
		return false
	}
}
