//
//  CheckboxTableCellView.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-26.
//

import Cocoa

class CheckboxTableCellView: NSTableCellView {

    @IBOutlet var checkbox: NSButton?
    @IBAction func stateDidChange(_ sender: NSButton) {
        NotificationCenter.default.post(Notification(name: .genreDidChange))
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
