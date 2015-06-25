//
//  StringExtras.swift
//  WWDC
//
//  Created by David Roberts on 15/06/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation

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
}