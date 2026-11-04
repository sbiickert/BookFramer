//
//  ChaptersDetailVC.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-24.
//

import Cocoa

class ChaptersDetailVC: BFViewController {
	@IBOutlet weak var tableView: NSTableView!
	
	@IBOutlet weak var colStatus: NSTableColumn!
	@IBOutlet weak var colInfo: NSTableColumn!
	@IBOutlet weak var colPOV: NSTableColumn!
	@IBOutlet weak var colLocation: NSTableColumn!
	@IBOutlet weak var colWords: NSTableColumn!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do view setup here.
		tableView.delegate = self
		tableView.dataSource = self
		tableView.doubleAction = #selector(tableViewWasDoubleClicked)
		tableView.registerForDraggedTypes([.tableViewIndex])
	}

	private var _observersAdded = false
	override func viewDidAppear() {
		super.viewDidAppear()
		
		if document != nil && _observersAdded == false {
			document!.notificationCenter.addObserver(self, selector: #selector(search(notification:)), name: .search, object: nil)
			_observersAdded = true
		}
		
		updateUI()
	}
	
	private var searchedObjects: [Any]?
	override func updateUI() {
		super.updateUI()
		searchedObjects = nil
		if let searchText = searchText {
			searchedObjects = allObjects.filter({
				if let ch = $0 as? Chapter {
					return ch.search(for: searchText)
				}
				if let sub = $0 as? SubChapter {
					return sub.search(for: searchText)
				}
				return false
			})
		}
		tableView.reloadData()
	}
	
	private var searchText: String? {
		didSet {
			if searchText != nil && searchText!.isEmpty {
				searchText = nil
			}
		}
	}
	@objc func search(notification: Notification) {
		searchText = notification.object as? String
		updateUI()
	}
	
	@IBAction func delete(_ sender: AnyObject) {
		deleteItem(at: tableView.selectedRow)
	}

	private func deleteItem(at row: Int) {
		let item = objectFor(row: row)
		if item is Chapter {
			document?.notificationCenter.post(name: .deleteChapter, object: item)
		}
		else if item is SubChapter {
			document?.notificationCenter.post(name: .deleteSubChapter, object: item)
		}
	}

	@objc func tableViewWasDoubleClicked() {
		//print("Double click on row \(tableView.clickedRow) and column \(tableView.clickedColumn)")
		guard tableView.clickedRow >= 0 else {
			return // click on header
		}
		if let item = objectFor(row: tableView.clickedRow) {
			document?.notificationCenter.post(name: .openExternal, object: item)
		}
	}
	
	override func bookEdited(notification: Notification) {
		super.bookEdited(notification: notification)
		// Select the correct chapter/subchapter here
		if let obj = notification.object as? IDable {
			selectTableViewRow(obj)
		}
	}
	
	private func selectTableViewRow(_ id: IDable) {
		if let row = indexOf(obj: id) {
			let indexSet = IndexSet(integer: row)
			tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
			tableView.scrollRowToVisible(row)
		}
	}
}

extension ChaptersDetailVC: NSTableViewDelegate {
	func tableViewSelectionDidChange(_ notification: Notification) {
		guard tableView.selectedRow >= 0 else {
			if let book = context?.book {
				document?.notificationCenter.post(name: .changeContext, object: book)
			}
			return
		}
		let item = objectFor(row: tableView.selectedRow)
		document?.notificationCenter.post(name: .changeContext, object: item)
	}
	
	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		return 24.0
	}
	
	func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
		guard row > 0 else { return [] }
		guard edge == .trailing else { return [] }
		let deleteAction = NSTableViewRowAction(style: .destructive, title: "Delete") { action, row in
			// Delete the swiped row, which may not be the selected row
			self.deleteItem(at: row)
		}
		return [deleteAction]
	}
	
	func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
		guard row > 0 else {return nil}
		
		if let rowObject = objectFor(row: row) as? IDable,
		   searchText == nil {
			// Can only drag and drop when no search filter
			return TableReorderPasteboardWriter(id: rowObject.id, at: row)
		}
		return nil
	}
	
	func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
		guard dropOperation == .above else {
			return []
		}
		assert(searchText == nil)
		
		// Only drops from same table, chapters can only drop
		// above/below other chapters
		if let source = info.draggingSource as? NSTableView,
		   source === tableView,
		   let items = info.draggingPasteboard.pasteboardItems {
			tableView.draggingDestinationFeedbackStyle = .regular
			// What got dragged? Chapter or SubChapter?
			let ids:[String] = items.compactMap {
				$0.string(forType: .string)
			}
			if let id = ids.first,
			   let draggedObject = objectFor(id: id) {
				if draggedObject is SubChapter {
					// Can go anywhere except to row 0 or 1 (before book / first chapter)
					return row > 1 ? .move : []
				}
				else if let _ = objectFor(row: row) as? Chapter {
					// Dragged onto another chapter
					return row > 0 ? .move : []
				}
				else if row >= numberOfRows(in: tableView) {
					// Dragging chapter to end. objectFor(row: row) is nil
					return .move
				}
			}
		}
		
		return []
	}
	
	func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
		guard let items = info.draggingPasteboard.pasteboardItems else { return false }
		assert(searchText == nil)

		// What got dragged? Chapter or SubChapter?
		let ids:[String] = items.compactMap {
			$0.string(forType: .string)
		}
		if let id = ids.first,
		   let book = context?.book,
		   let draggedObject = objectFor(id: id) {
			let position: Book.DropPosition
			switch objectFor(row: row) {
			case let ch as Chapter:
				position = .beforeChapter(id: ch.id)
			case let sub as SubChapter:
				position = .beforeSubChapter(id: sub.id)
			default:
				position = .end
			}

			// Compute the result without touching the book, so DocEditor can record the
			// unmodified chapters for undo
			guard let newChapters = book.chapters(moving: id, to: position) else { return false }
			document?.notificationCenter.post(name: .modifyChapters, object: newChapters)

			// Re-select the row in the tableview
			if let draggedIDable = draggedObject as? IDable {
				selectTableViewRow(draggedIDable)
			}
		}
		return true
	}
}

extension ChaptersDetailVC: NSTableViewDataSource {
	func numberOfRows(in tableView: NSTableView) -> Int {
		// One row for the book, one row for each chapter, one row for each subchapter
		var n = 0
		if let searched = searchedObjects {
			n = searched.count + 1 // the book
		}
		else if let book = context?.book {
			n = book.count + 1 // the book
		}
		return n
	}
	
	private func objectFor(row: Int) -> Any? {
		if row == 0 && context?.book != nil {
			return context!.book!
		}
		guard row > 0 else { return nil } // e.g. selectedRow is -1 when nothing is selected
		if let searched = searchedObjects {
			// indexes are off by one b/c the book is the first row
			return searched.indices.contains(row-1) ? searched[row-1] : nil
		}
		else if let book = context?.book {
			return book[row-1] // indexes are off by one b/c the book is the first row
		}
		return nil
	}

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		var cellView: NSTableCellView?
		
		if let rowObject = objectFor(row: row) {
			if tableColumn == colStatus {
				cellView = tableView.makeView(withIdentifier: .chaptersDetailStatus, owner: self) as? NSTableCellView
				var status = EditStatus.multiple
				if let b = rowObject as? Book {
					status = b.status
				}
				else if let ch = rowObject as? Chapter {
					status = ch.status
				}
				else if let sub = rowObject as? SubChapter {
					status = sub.headerInfo.status
				}
				let image = NSImage(systemSymbolName: status.imageName, accessibilityDescription: status.rawValue)
				cellView?.imageView?.contentTintColor = status.tint
				cellView?.imageView?.image = image
			}
			
			if tableColumn == colInfo {
				cellView = tableView.makeView(withIdentifier: .chaptersDetailInfo, owner: self) as? NSTableCellView
				let f = cellView?.textField?.font
				if let b = rowObject as? Book {
					cellView?.textField?.stringValue = b.titleSubtitle
					cellView?.textField?.font = f?.bolded()?.resized(to: 14)
				}
				else if let sub = rowObject as? SubChapter {
					cellView?.textField?.stringValue = sub.headerInfo.description
					cellView?.textField?.font = f?.unbolded()?.resized(to: 11)
				}
				else if let ch = rowObject as? Chapter {
					cellView?.textField?.stringValue = ch.titleSubtitle
					cellView?.textField?.font = f?.bolded()?.resized(to: 13)
					//tableView.rowView(atRow: row, makeIfNecessary: false)?.backgroundColor = NSColor.controlAccentColor
				}
			}
			
			if tableColumn == colPOV {
				cellView = tableView.makeView(withIdentifier: .chaptersDetailPOV, owner: self) as? NSTableCellView
				let f = cellView?.textField?.font
				if let sub = rowObject as? SubChapter {
					cellView?.textField?.stringValue = sub.headerInfo.pov
					cellView?.textField?.font = f?.resized(to: 11)
				}
				else {
					cellView?.textField?.stringValue = ""
					cellView?.textField?.font = f?.resized(to: 13)
				}
			}
			
			if tableColumn == colLocation {
				cellView = tableView.makeView(withIdentifier: .chaptersDetailLocation, owner: self) as? NSTableCellView
				let f = cellView?.textField?.font
				if let sub = rowObject as? SubChapter {
					cellView?.textField?.stringValue = sub.headerInfo.location
					cellView?.textField?.font = f?.resized(to: 11)
				}
				else {
					cellView?.textField?.stringValue = ""
					cellView?.textField?.font = f?.resized(to: 13)
				}
			}
			
			if tableColumn == colWords {
				cellView = tableView.makeView(withIdentifier: .chaptersDetailWords, owner: self) as? NSTableCellView
				let f = cellView?.textField?.font
				if let b = rowObject as? Book {
					cellView?.textField?.stringValue = "\(b.wordCount)"
					cellView?.textField?.font = f?.resized(to: 14)
				}
				else if let sub = rowObject as? SubChapter {
					cellView?.textField?.stringValue = "\(sub.wordCount)"
					cellView?.textField?.font = f?.resized(to: 11)
				}
				else if let ch = rowObject as? Chapter {
					cellView?.textField?.stringValue = "\(ch.wordCount)"
					cellView?.textField?.font = f?.resized(to: 13)
				}
			}
		}
		
		return cellView
	}
	
	private func indexOf(obj: IDable) -> Int? {
		if searchedObjects != nil {
			for (idx, searched) in searchedObjects!.enumerated() {
				if let searchedIDable = searched as? IDable,
				   obj.id == searchedIDable.id {
					return idx + 1 // Book is index 0
				}
			}
		}
		else if let b = context?.book {
			for idx in 0..<b.count {
				if let chSub = b[idx] as? IDable,
				   obj.id == chSub.id {
					return idx + 1 // Book is index 0
				}
			}
		}
		return nil
	}
	
	private var allObjects: [Any] {
		var result = [Any]()
		if let book = context?.book {
			for c in book.chapters {
				result.append(c)
				result.append(contentsOf: c.subchapters)
			}
		}
		return result
	}
	
	private func objectFor(id: String) -> Any? {
		if let b = context?.book {
			for c in b.chapters {
				if c.id == id {
					return c as Any
				}
				for sub in c.subchapters {
					if sub.id == id {
						return sub as Any
					}
				}
			}
		}
		return nil
	}
}

extension NSUserInterfaceItemIdentifier {
	static let chaptersDetailStatus = NSUserInterfaceItemIdentifier(rawValue: "ChapterOrSubChapterStatus")
	static let chaptersDetailInfo = NSUserInterfaceItemIdentifier(rawValue: "ChapterOrSubChapterInfo")
	static let chaptersDetailPOV = NSUserInterfaceItemIdentifier(rawValue: "ChapterOrSubChapterPOV")
	static let chaptersDetailLocation = NSUserInterfaceItemIdentifier(rawValue: "ChapterOrSubChapterLocation")
	static let chaptersDetailWords = NSUserInterfaceItemIdentifier(rawValue: "ChapterOrSubChapterWords")
}
