//
//  DetailVC.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-23.
//

import Cocoa

class DetailTabVC: NSTabViewController {
    enum TabIndex: Int {
        case chapter = 0
        case subchapter = 1
    }
	
	var book: Book? {
		didSet {
			let note = NSNotification(name: .changeContext, object: book)
			self.changeContext(notification: note)
		}
	}
	
	public var document: Document? {
		return self.view.window?.windowController?.document as? Document
	}

    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear() {
		document?.notificationCenter.addObserver(self, selector: #selector(changeContext(notification:)), name: .changeContext, object: nil)
	}
    
    @objc func changeContext(notification: NSNotification) {
		
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
		
		document?.notificationCenter.post(name: .contextDidChange, object: notification.object)
    }
}

