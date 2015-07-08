//
//  Preferences.swift
//  WWDC
//
//  Created by David Roberts on 08/07/2015.
//  Copyright © 2015 Dave Roberts. All rights reserved.
//

import Foundation
import Cocoa

let simultaneousDownloadsKey = "simultaneousDownloads"
let downloadFolderPreferencesKey = "downloadFolderPreferencesKey"


class PreferencesController : NSViewController {
    
    @IBOutlet weak var stepper: NSStepper!
    @IBOutlet weak var connectionsLabel: NSTextField!
    
    @IBOutlet weak var downloadLocationMenu: NSPopUpButton!
    
    override func awakeFromNib() {
        
        let defaults = NSUserDefaults.standardUserDefaults()

        let simultaneous = defaults.integerForKey(simultaneousDownloadsKey)
        
        stepper.integerValue = simultaneous

        connectionsLabel.stringValue = String(simultaneous)
        
        let folderIndex = defaults.integerForKey(downloadFolderPreferencesKey)
        
        downloadLocationMenu.selectItem(downloadLocationMenu.itemAtIndex(folderIndex))
    }
    
    @IBAction func stepperChanged(sender: NSStepper) {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(sender.integerValue
, forKey: simultaneousDownloadsKey)
        defaults.synchronize()
        
        connectionsLabel.stringValue = String(sender.integerValue)
    }
    
    @IBAction func folderSelected(sender: NSPopUpButton) {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(sender.indexOfSelectedItem, forKey: downloadFolderPreferencesKey)
        defaults.synchronize()
    }
    
}
