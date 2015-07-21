//
//  SessionIDCell.swift
//  WWDC
//
//  Created by David Roberts on 21/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa

class SessionIDCell: NSTableCellView {
    
    func updateUserInfo(userInfo:UserSessionInfo) {
                
        switch userInfo.currentProgress {
        case 1.0:
            imageView?.image = (userInfo.markAsFavorite ? NSImage(imageLiteral: "Star-Outline") : nil)
        case 0:
            imageView?.image = (userInfo.markAsFavorite ? NSImage(imageLiteral: "Star-Solid") : NSImage(imageLiteral: "Circle-Solid"))
        default:
            imageView?.image = (userInfo.markAsFavorite ? NSImage(imageLiteral: "Star-Half") : NSImage(imageLiteral: "Circle-Half"))
        }

    }
}
