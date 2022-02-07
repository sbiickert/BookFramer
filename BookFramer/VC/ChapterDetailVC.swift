//
//  ChapterDetailVC.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-24.
//

import Cocoa

class ChapterDetailVC: BFViewController {
    @IBOutlet weak var titleField: NSTextField!
    @IBOutlet weak var subtitleField: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
	
	private var _observerAdded = false
	override func viewDidAppear() {
		super.viewDidAppear()
		updateUI()
		if _observerAdded == false {
			document?.notificationCenter.addObserver(self, selector: #selector(contextChanged(notification:)), name: .contextDidChange, object: nil)
			_observerAdded = true
		}
	}
	
	@objc func contextChanged(notification: NSNotification) {
		updateUI()
	}

    override func updateUI() {
		super.updateUI()
		titleField.stringValue = context?.selectedChapter?.title ?? ""
        subtitleField.stringValue = context?.selectedChapter?.subtitle ?? ""
    }
	
	@IBAction func delete(_ sender: AnyObject) {
		if sender is NSButton,
			let ch = context?.selectedChapter {
			document?.notificationCenter.post(name: .deleteChapter, object: ch)
		}
	}
	
	private func modifyChapter() {
		if var ch = context?.selectedChapter {
			ch.title = titleField.stringValue
			ch.subtitle = subtitleField.stringValue
			document?.notificationCenter.post(name: .modifyChapter, object: ch)
		}
	}

    /**
     Target of action when `titleField` changes. Calls `modifyChapter`
     - Parameter sender: the NSTextField
     */
    @IBAction func titleChanged(_ sender: NSTextField) {
        modifyChapter()
    }
    
    /**
     Target of action when `subtitleField` changes. Calls `modifyChapter`
     - Parameter sender: the NSTextField
     */
    @IBAction func subtitleChanged(_ sender: NSTextField) {
        modifyChapter()
    }
}

