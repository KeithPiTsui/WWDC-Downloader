//
//  IntrinsicContentNSTextView.swift
//  WWDC
//
//  Created by David Roberts on 04/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa

class IntrinsicContentNSTextView : NSTextView {
    
    override var intrinsicContentSize : CGSize {
        get {
            if let textContainer = self.textContainer, let layoutManager = self.layoutManager {
                layoutManager.ensureLayoutForTextContainer(textContainer)
                if let string = self.string {
                    if string.characters.count == 0 {
                        return CGSizeZero
                    }
                    else {
                        let size = layoutManager.usedRectForTextContainer(textContainer).size
                        return size
                    }
                }
                else {
                    return CGSizeZero
                }
            }
            else {
                return CGSizeZero
            }
        }
    }
    
//    override func didChangeText() {
//        super.didChangeText()
//
//        self.invalidateIntrinsicContentSize()
//    }
}