//
//  SidebarVC.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-23.
//

import Cocoa

class SidebarVC: BFViewController  {
    
    @IBOutlet weak var outlineView: NSOutlineView!
    
    var book: Book? {
        didSet {
            updateUI()
            let name: NSNotification.Name = .selectedItemDidChange
			document?.notificationCenter.post(name: name, object: book)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        outlineView.delegate = self
        outlineView.dataSource = self
    }
	
	override func viewWillAppear() {
		document?.notificationCenter.addObserver(self, selector: #selector(selectedItemDidChange(notification:)), name: .selectedItemDidChange, object: nil)
		document?.notificationCenter.addObserver(self, selector: #selector(bookEdited(notification:)), name: .bookEdited, object: nil)
	}
    
    private func updateUI() {
        outlineView.reloadData()
    }
	
	@objc func selectedItemDidChange(notification: NSNotification) {
		var row = outlineView.row(forItem: notification.object)
		if row >= 0 {
			outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
		}
		else {
			// The notification object is something not disclosed in the outlineView
			if notification.object is Chapter {
				// Expand book > chapters
				outlineView.expandItem(book)
				if let item = outlineView.child(0, ofItem: book) {
					outlineView.expandItem(item)
				}
			}
			else if let sub = notification.object as? SubChapter {
				// Expand book > chapters > chapter containing book
				outlineView.expandItem(book)
				if let item = outlineView.child(0, ofItem: book) {
					outlineView.expandItem(item)
				}
				if let containingChapter = book?.chapterContaining(subchapter: sub) {
					outlineView.expandItem(containingChapter)
				}
			}
			// Try again
			row = outlineView.row(forItem: notification.object)
			if row >= 0 {
				outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
			}
		}
	}
	
	@objc func bookEdited(notification: NSNotification) {
		outlineView.reloadData()
		selectedItemDidChange(notification: notification)
	}
	
    enum NodeIcon: String {
        case book = "book"
        case chapter = "doc"
        case chapters = "doc.on.doc"
        case subchapter = "note.text" // Not used! Status is provided in the item header info
        case personas = "person.3.fill"
    }
}

extension SidebarVC: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return 1 // Nil means root item, pass 1 for book
        }
        if item is Book {
            return 2 // Chapters, Personas
        }
        if let chapters = item as? [Chapter] {
            return chapters.count
        }
        if let chapter = item as? Chapter {
            return chapter.subchapters.count
        }
        if item is SubChapter {
            return 0
        }
        if item is [Persona] {
            return 0
        }

        // Should never get here
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if item is SubChapter || item is [Persona] {
            return false
        }
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let b = item as? Book {
            return index == 0 ? b.chapters : b.allPersonas
        }
        if let chapters = item as? [Chapter] {
            return chapters[index]
        }
        if let chapter = item as? Chapter {
            return chapter.subchapters[index]
        }
        
        // Item is nil
        return book as Any
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let result = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self)
        let imageView = result?.viewWithTag(0) as? NSImageView
        let textView = result?.viewWithTag(1) as? NSTextField

        var icon = NSImage(systemSymbolName: NodeIcon.book.rawValue, accessibilityDescription: "book")
        let font = textView?.font
        
        if let b = item as? Book {
            imageView?.image = icon
            textView?.stringValue = b.title
			textView?.font = font?.resized(to: 13)
        }
        else if item is [Chapter] {
            icon = NSImage(systemSymbolName: NodeIcon.chapters.rawValue, accessibilityDescription: "chapters")
            imageView?.image = icon
            textView?.stringValue = "Chapters"
			textView?.font = font?.resized(to: 13)
        }
        else if let c = item as? Chapter {
            icon = NSImage(systemSymbolName: NodeIcon.chapter.rawValue, accessibilityDescription: "chapter")
            imageView?.image = icon
            textView?.stringValue = c.titleSubtitle
			textView?.font = font?.resized(to: 13)
        }
        else if let sc = item as? SubChapter {
            icon = NSImage(systemSymbolName: sc.headerInfo.status.imageName, accessibilityDescription: "subchapter")
            imageView?.contentTintColor = sc.headerInfo.status.tint
            imageView?.image = icon
            textView?.stringValue = sc.headerInfo.description
			textView?.font = font?.resized(to: 11)
        }
        else if item is [Persona] {
            icon = NSImage(systemSymbolName: NodeIcon.personas.rawValue, accessibilityDescription: "personas")
            imageView?.image = icon
            textView?.stringValue = "Personas"
			textView?.font = font?.resized(to: 13)
        }
        
        return result
    }
    
}

extension SidebarVC: NSOutlineViewDelegate{
    func outlineViewSelectionDidChange(_ notification: Notification) {
        let item = outlineView.item(atRow: outlineView.selectedRow)
        let name: NSNotification.Name = .selectedItemDidChange
		document?.notificationCenter.post(name: name, object: item)
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        return 24.0
    }
}
