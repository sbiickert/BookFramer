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
        case chapters = 3
        case personas = 4
    }
	
	var book: Book?
	
	public var document: Document? {
		return self.view.window?.windowController?.document as? Document
	}

    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear() {
		document?.notificationCenter.addObserver(self, selector: #selector(selectedItemDidChange(notification:)), name: .selectedItemDidChange, object: nil)
	}
    
    @objc func selectedItemDidChange(notification: NSNotification) {
		
        if notification.object is Book {
            let tvi = self.tabViewItems[TabIndex.book.rawValue]
            if let bdvc = tvi.viewController as? BookDetailVC {
				bdvc.book = self.book
            }
            self.tabView.selectTabViewItem(tvi)
        }
        else if notification.object is Chapter {
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
        else if notification.object is [Chapter] {
			let tvi = self.tabViewItems[TabIndex.chapters.rawValue]
			if let chaptersVC = tvi.viewController as? ChaptersDetailVC {
				chaptersVC.book = self.book
			}
            self.tabView.selectTabViewItem(at: TabIndex.chapters.rawValue)
        }
        else if notification.object is [Persona] {
            self.tabView.selectTabViewItem(at: TabIndex.personas.rawValue)
        }


    }
}

