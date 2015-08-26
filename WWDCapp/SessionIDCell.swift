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
	
	override var backgroundStyle : NSBackgroundStyle {
		didSet {
			imageView?.image = (backgroundStyle == NSBackgroundStyle.Light ? imageView?.image?.tintImageToBrightBlurColor() : imageView?.image?.tintImageToWhiteColor())
		}
	}
	
    func updateUserInfo(userInfo:UserSessionInfo) {
                
        switch userInfo.currentProgress {
        case 1.0:
            imageView?.image = (userInfo.markAsFavorite ? NSImage(named: "Star-Outline")?.tintImageToBrightBlurColor() : nil)
        case 0:
            imageView?.image = (userInfo.markAsFavorite ? NSImage(named: "Star-Solid")?.tintImageToBrightBlurColor() : NSImage(named: "Circle-Solid")?.tintImageToBrightBlurColor())
        default:
            imageView?.image = (userInfo.markAsFavorite ? NSImage(named: "Star-Half")?.tintImageToBrightBlurColor() : NSImage(named: "Circle-Half")?.tintImageToBrightBlurColor())
        }

    }
}
