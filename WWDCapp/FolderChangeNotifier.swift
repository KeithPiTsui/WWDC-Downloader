//
//  FolderChangeNotifier.swift
//  WWDC
//
//  Created by David Roberts on 29/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import CoreServices

typealias FolderMonitorBlock = () -> Void

struct FolderChangeInfo  {
	
	var fileDescriptor : Int32?
	var block : FolderMonitorBlock?
	var queue : dispatch_queue_t?
	var source : dispatch_source_t?
	var url : NSURL?

}

class FolderChangeNotifier : NSObject {
	
	var notifiers = [FolderChangeInfo]()
	
	convenience init(url : NSURL, callback : FolderMonitorBlock) {
		self.init()
		
		let info = createNotification(url, callback: callback)
		notifiers.append(info)
	}
	
	convenience init(urls : [NSURL], callback : FolderMonitorBlock) {
		self.init()
		
		for url in urls {
			let info = createNotification(url, callback: callback)
			notifiers.append(info)
		}
	}
	
	func createNotification(url : NSURL, callback : FolderMonitorBlock) -> FolderChangeInfo {
		
		var info = FolderChangeInfo()

		info.block = callback
		info.fileDescriptor = open(url.fileSystemRepresentation, O_EVTONLY)
		info.url = url
		
		if let descriptor = info.fileDescriptor {
			
			if descriptor > -1 {
				info.queue = dispatch_queue_create("\(url.fileSystemRepresentation) Queue", nil)
				
				if let queue = info.queue {
					info.source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, UInt(descriptor), DISPATCH_VNODE_WRITE, queue)
					
					if let source = info.source, let block = info.block {
						
						dispatch_source_set_event_handler(source, block)
						
						dispatch_source_set_cancel_handler(source, { () -> Void in
							close(descriptor)
							info.fileDescriptor = -1
							info.source = nil
						})
						
						dispatch_resume(source);
					}
				}
			}
			else {
				print("No File Descriptor! for url - \(url)")
			}
		}
		
		return info
	}
	
	func stopNotifying() {
		for info in notifiers {
			if let source  = info.source {
				dispatch_source_cancel(source)
			}
		}
	}
}