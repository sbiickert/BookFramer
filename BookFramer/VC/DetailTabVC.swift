//
//  DetailVC.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-23.
//

import Cocoa

class DetailTabVC: NSTabViewController {
    enum TabIndex: Int {
		case book = 0
		case chapter = 1
        case subchapter = 2
    }
	
	public var document: BookDocument? {
		return self.view.window?.windowController?.document as? BookDocument
	}

    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	private var _observerAdded = false
	override func viewDidAppear() {
		super.viewDidAppear()
		if _observerAdded == false {
			_observerAdded = true
			document?.notificationCenter.addObserver(self, selector: #selector(contextChanged(notification:)), name: .contextDidChange, object: nil)
		}
	}
    
    @objc func contextChanged(notification: NSNotification) {
        if notification.object is Chapter {
            self.tabView.selectTabViewItem(at: TabIndex.chapter.rawValue)
        }
        else if notification.object is SubChapter {
            self.tabView.selectTabViewItem(at: TabIndex.subchapter.rawValue)
        }
		else {
			self.tabView.selectTabViewItem(at: TabIndex.book.rawValue)
		}
    }
}

