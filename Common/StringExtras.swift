//
//  StringExtras.swift
//  WWDC
//
//  Created by David Roberts on 15/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa

extension String {
    
    func stringBetweenString(start:String, andString end:String) -> String? {
        
        let startRange = self.rangeOfString(start)
        
        let endRange = self.rangeOfString(end)
        
        if let startRange = startRange, let endRange = endRange  {
            
            startRange.endIndex
            
            let targetRange = Range(start: startRange.endIndex, end: endRange.startIndex)

            return self.substringWithRange(targetRange)
        }
        else {
            return nil
        }
    }
    
    func sanitizeFileNameString() -> String {
        let characters = NSCharacterSet(charactersInString: "/\\?%*|\"<>:")
        let components = self.componentsSeparatedByCharactersInSet(characters) as NSArray
        return components.componentsJoinedByString("")
        
    }
    
    // NOT USED But may be better than using temp Cell??
    func heightForStringDrawing(font: NSFont, width: Double) -> CGFloat {
        
        let textStorage = NSTextStorage(string: self)
        let textContainer = NSTextContainer(containerSize: NSSize(width: width, height: DBL_MAX))
        let layoutManager = NSLayoutManager()
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textStorage.addAttribute(NSFontAttributeName, value: font, range: NSRange(location: 0,length: textStorage.length))
        textContainer.lineFragmentPadding = 0.0
        
        layoutManager.glyphRangeForTextContainer(textContainer)
        
        let rect = layoutManager.usedRectForTextContainer(textContainer)
        
        return rect.size.height
    }

}