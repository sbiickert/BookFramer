//
//  BFViewController.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-09-01.
//

import Cocoa

class BFViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
	
	private var _bookEditedObserverAdded = false
	override func viewDidAppear() {
		if let d = document,
		   _bookEditedObserverAdded == false {
			d.notificationCenter.addObserver(self, selector: #selector(bookEdited(notification:)), name: .bookEdited, object: nil)
			_bookEditedObserverAdded = true
		}
	}
	
	public var document: Document? {
		return self.view.window?.windowController?.document as? Document
	}
	
	public var context: BFContextProvider? {
		return self.view.window?.contentViewController as? BFContextProvider
	}

	@objc func bookEdited(notification: Notification) {
		updateUI()
	}
	
	func updateUI() {}
}
