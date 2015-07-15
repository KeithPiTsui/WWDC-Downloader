//
//  TranscriptPanelController.swift
//  WWDC
//
//  Created by David Roberts on 15/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa

class TranscriptPanelController : NSViewController {
    
    @IBOutlet var textView: NSTextView!
    
    weak var wwdcSession : WWDCSession? {
        didSet {
            if let wwdcSession = wwdcSession {
                self.textView.string = wwdcSession.fullTranscriptPrettyPrint
            }
        }
    }    
}