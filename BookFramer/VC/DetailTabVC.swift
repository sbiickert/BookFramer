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
	
	var book: Book? {
		didSet {
			let note = NSNotification(name: .changeContext, object: book)
			self.contextChanged(notification: note)
		}
	}
	
	public var document: Document? {
		return self.view.window?.windowController?.document as? Document
	}

    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	private var _observerAdded = false
	override func viewWillAppear() {
		if _observerAdded == false {
			_observerAdded = true
			document?.notificationCenter.addObserver(self, selector: #selector(contextChanged(notification:)), name: .contextDidChange, object: nil)
		}
	}
    
    @objc func contextChanged(notification: NSNotification) {
        if notification.object is Chapter {
			let tvi = self.tabViewItems[TabIndex.chapter.rawValue]
			if let cdvc = tvi.viewController as? ChapterDetailVC {
				cdvc.book = self.book
				cdvc.chapter = notification.object as? Chapter
			}
            self.tabView.selectTabViewItem(at: TabIndex.chapter.rawValue)
        }
        else if notification.object is SubChapter {
			let tvi = self.tabViewItems[TabIndex.subchapter.rawValue]
			if let scdvc = tvi.viewController as? SubChapterDetailVC {
				scdvc.book = book
				scdvc.subchapter = notification.object as? SubChapter
			}
            self.tabView.selectTabViewItem(at: TabIndex.subchapter.rawValue)
        }
		else {
			let tvi = self.tabViewItems[TabIndex.book.rawValue]
			if let bdvc = tvi.viewController as? BookDetailVC {
				bdvc.book = book
			}
			self.tabView.selectTabViewItem(at: TabIndex.book.rawValue)
		}
    }
}

