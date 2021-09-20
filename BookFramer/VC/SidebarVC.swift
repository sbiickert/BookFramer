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
			document?.notificationCenter.post(name: .changeContext, object: book)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        outlineView.delegate = self
        outlineView.dataSource = self
    }
	
	override func viewWillAppear() {
		super.viewWillAppear()
		document?.notificationCenter.addObserver(self, selector: #selector(contextDidChange(notification:)), name: .contextDidChange, object: nil)
	}
    
    override func updateUI() {
		super.updateUI()
        outlineView.reloadData()
    }
	
	private var _shouldChangeContext = true
	@objc func contextDidChange(notification: Notification) {
		var row = outlineView.row(forItem: notification.object)
		if row >= 0 {
			_shouldChangeContext = false
			outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
			_shouldChangeContext = true
			outlineView.scrollRowToVisible(row)
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
			else if notification.object is [Persona] {
				// Expand book > personas
				outlineView.expandItem(book)
				if let item = outlineView.child(1, ofItem: book) {
					let personasRow = outlineView.row(forItem: item)
					outlineView.selectRowIndexes(IndexSet(integer: personasRow), byExtendingSelection: false)
				}
			}
			// Try again
			row = outlineView.row(forItem: notification.object)
			if row >= 0 {
				_shouldChangeContext = false
				outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
				_shouldChangeContext = true
				outlineView.scrollRowToVisible(row)
			}
		}
	}
	
	@objc override func bookEdited(notification: Notification) {
		super.bookEdited(notification: notification)
		contextDidChange(notification: notification)
	}
	
	@IBAction func openInBBEdit(_ sender: AnyObject) {
		print("openInBBEdit in sidebar")
		guard book != nil else {
			return
		}
		if let item = outlineView.item(atRow: outlineView.selectedRow) {
			if item is Book {
				print("Open book in BBEdit, line \(book!.startLineNumber)")
			}
			else if let ch = item as? Chapter {
				print("Open chapter in BBEdit, line \(book!.lineNumberFor(chapter: ch))")
			}
			else if let sub = item as? SubChapter {
				print("Open subchapter in BBEdit, line \(book!.lineNumberFor(subchapter: sub))")
			}
			else {
				print("Was something else")
			}
			document?.notificationCenter.post(name: .openExternal, object: item)
		}
	}
	
	@IBAction func addChapter(_ sender: AnyObject) {
		print("addChapter in sidebar")
		let item = outlineView.item(atRow: outlineView.selectedRow)
		if item is Chapter || item is SubChapter {
			// Will want to add the Chapter after selected Chapter
			document?.notificationCenter.post(name: .addChapter, object: item)
		}
		else {
			// Will want to add to end
			document?.notificationCenter.post(name: .addChapter, object: nil)
		}
	}
	
	@IBAction func addScene(_ sender: AnyObject) {
		print("addScene in sidebar")
		let item = outlineView.item(atRow: outlineView.selectedRow)
		if item is Chapter || item is SubChapter {
			// Will want to add the SubChapter in selected Chapter
			document?.notificationCenter.post(name: .addSubChapter, object: item)
		}
		else {
			// Will want to add to end of book
			document?.notificationCenter.post(name: .addSubChapter, object: nil)
		}
	}
	
	@IBAction func delete(_ sender: AnyObject) {
		print("delete in sidebar")
		let item = outlineView.item(atRow: outlineView.selectedRow)
		if item is Chapter {
			document?.notificationCenter.post(name: .deleteChapter, object: item)
		}
		else if item is SubChapter {
			// Will want to add the SubChapter in selected Chapter
			document?.notificationCenter.post(name: .deleteSubChapter, object: item)
		}
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
        
        imageView?.contentTintColor = nil

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
		if _shouldChangeContext {
			let item = outlineView.item(atRow: outlineView.selectedRow)
			document?.notificationCenter.post(name: .changeContext, object: item)
		}
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        return 24.0
    }
}
