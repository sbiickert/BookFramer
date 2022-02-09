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
	
	public var document: BookDocument? {
		return self.view.window?.windowController?.document as? BookDocument
	}
	
	public var context: BFContextProvider? {
		return self.view.window?.contentViewController as? BFContextProvider
	}
	
	func updateUI() {}

	
	// MARK: Notifications

	@objc func bookEdited(notification: Notification) {
		updateUI()
	}
	
	// MARK: menu actions
	// These are all menu items whose target can be inferred from context.
	
	@IBAction func newChapterMenuHandler(_ sender: AnyObject) {
		// Add a new chapter to the end of the book
		document?.notificationCenter.post(name: .addChapter, object: nil)
	}

	@IBAction func newSceneMenuHandler(_ sender: AnyObject) {
		document?.notificationCenter.post(name: .addSubChapter, object: nil)
	}

	@IBAction func newPersonaMenuHandler(_ sender: Any) {
		document?.notificationCenter.post(name: .addPersona, object: nil)
	}
	
	@IBAction func openInBBEditMenuHandler(_ sender: Any) {
		document?.notificationCenter.post(name: .openExternal, object: nil)
	}
	
	@IBAction func exportToPDFMenuHandler(_ sender: Any) {
		document?.notificationCenter.post(name: .exportPDF, object: nil)
	}
}
