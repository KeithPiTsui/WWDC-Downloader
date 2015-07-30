//
//  ViewExtras.swift
//  WWDC
//
//  Created by David Roberts on 30/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa

extension NSView {
    
    func addSubviewWithContentHugging(subview : NSView) {
        
        subview.frame = self.bounds
        subview.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(subview)
        
        let width = NSLayoutConstraint(item: subview, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0)
        let height = NSLayoutConstraint(item: subview, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 0)
        
        let top = NSLayoutConstraint(item: subview, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: 0)
        let leading = NSLayoutConstraint(item: subview, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: 0)

        NSLayoutConstraint.activateConstraints([width, height, top, leading])
        
    }
}
