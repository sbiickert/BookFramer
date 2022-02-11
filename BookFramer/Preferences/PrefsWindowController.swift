//
//  PrefsWindowController.swift
//  BookFramer
//
//  Created by Simon Biickert on 2022-02-11.
//

import Cocoa

class PrefsWindowController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

	func windowShouldClose(_ sender: NSWindow) -> Bool {
		// Hide instead of closing
		self.window?.orderOut(sender)
		return false
	}
}
