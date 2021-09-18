//
//  ChaptersDetailVC.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-24.
//

import Cocoa

class ChaptersDetailVC: BFViewController {
	
	var book: Book? {
		didSet {
			updateUI()
		}
	}
	
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
	
	override func updateUI() {
		super.updateUI()
		tableView.reloadData()
	}
	
	@IBAction func openInBBEdit(_ sender: AnyObject) {
		print("openInBBEdit in chapters detail")
		if let item = objectFor(row: tableView.selectedRow) {
			document?.notificationCenter.post(name: .openExternal, object: item)
		}
	}
	
	@IBAction func delete(_ sender: AnyObject) {
		print("delete in chapters detail")
		let item = objectFor(row: tableView.selectedRow)
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
			document?.notificationCenter.post(name: .changeContext, object: item)
		}
	}
	
}

extension ChaptersDetailVC: NSTableViewDelegate {
	func tableViewSelectionDidChange(_ notification: Notification) {
		guard tableView.selectedRow >= 0 else {
			return // no selected row
		}
		let item = objectFor(row: tableView.selectedRow)
		document?.notificationCenter.post(name: .contextDidChange, object: item)
	}
	
	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		return 24.0
	}
	
	func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
		switch edge {
		case .trailing:
			let deleteAction = NSTableViewRowAction(style: .destructive, title: "Delete") { action, row in
				self.delete(self.tableView)
			}
			return [deleteAction]
		default:
			return []
		}
	}
	
	func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
		if let rowObject = objectFor(row: row) as? IDable {
			return TableReorderPasteboardWriter(id: rowObject.id, at: row)
		}
		return nil
	}
	
	func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
		guard dropOperation == .above else {
			return []
		}
		
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
					// Can go anywhere except to row 0 (before first chapter)
					return row > 0 ? .move : []
				}
				else if let _ = objectFor(row: row) as? Chapter {
					// Dragged onto another chapter
					return .move
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
		
		// What got dragged? Chapter or SubChapter?
		let ids:[String] = items.compactMap {
			$0.string(forType: .string)
		}
		if let id = ids.first,
		   let draggedObject = objectFor(id: id) {
			// Preserve the chapters as-is for undo
			let oldChapters = book!.chapters
			
			if let draggedChapter = draggedObject as? Chapter {
				if let targetChapter = objectFor(row: row) as? Chapter {
					// draggedChapter needs to be reordered before targetChapter
					if let oldIndex = book!.indexOf(chapter: draggedChapter),
					   var newIndex = book!.indexOf(chapter: targetChapter) {
						if newIndex > oldIndex { newIndex -= 1 }
						book!.reorderChapter(fromIndex: oldIndex, toIndex: newIndex)
					}
				}
				else {
					// draggedChapter was dragged to the end
					if let oldIndex = book!.indexOf(chapter: draggedChapter) {
						book!.reorderChapter(fromIndex: oldIndex, toIndex: book!.chapters.count - 1)
					}
				}
			}
			else if let draggedSub = draggedObject as? SubChapter,
					var sourceChapter = book!.chapterContaining(subchapter: draggedSub) {
				let targetObject = objectFor(row: row)
				
				if var targetChapter = targetObject as? Chapter {
					// draggedSub has to be moved to the end of the chapter before targetChapter
					if let sourceIndex = sourceChapter.indexOf(subchapter: draggedSub),
					   let targetChIndex = book!.indexOf(chapter: targetChapter) {
					    let chapterBeforeTargetChapterIndex = targetChIndex - 1
						targetChapter = book!.chapters[chapterBeforeTargetChapterIndex]
						sourceChapter.subchapters.remove(at: sourceIndex)
						if sourceChapter.id == targetChapter.id {
							sourceChapter.subchapters.append(draggedSub)
							book!.replace(chapter: sourceChapter)
						}
						else {
							targetChapter.subchapters.append(draggedSub)
							book!.replace(chapter: sourceChapter)
							book!.replace(chapter: targetChapter)
						}
					}
				}
				else if let targetSub = targetObject as? SubChapter {
					// draggedSub has to be moved to before targetSub
					if var targetChapter = book!.chapterContaining(subchapter: targetSub),
					   let sourceIndex = sourceChapter.indexOf(subchapter: draggedSub),
					   var targetIndex = targetChapter.indexOf(subchapter: targetSub) {
						if targetIndex > sourceIndex { targetIndex -= 1 }
						sourceChapter.subchapters.remove(at: sourceIndex)
						if sourceChapter.id == targetChapter.id {
							sourceChapter.subchapters.insert(draggedSub, at: targetIndex)
							book!.replace(chapter: sourceChapter)
						}
						else {
							targetChapter.subchapters.insert(draggedSub, at: targetIndex)
							book!.replace(chapter: sourceChapter)
							book!.replace(chapter: targetChapter)
						}
					}
				}
				else if targetObject == nil {
					// draggedSub has to be moved to the end of the last chapter
					if var targetChapter = book!.chapters.last,
					   let sourceIndex = sourceChapter.indexOf(subchapter: draggedSub) {
						sourceChapter.subchapters.remove(at: sourceIndex)
						if sourceChapter.id == targetChapter.id {
							sourceChapter.subchapters.append(draggedSub)
						}
						else {
							targetChapter.subchapters.append(draggedSub)
							book!.replace(chapter: sourceChapter)
							book!.replace(chapter: targetChapter)
						}
					}
				}
			}
			// Redo the edit so that it's captured by undoManager
			let newChapters = book!.chapters
			book!.chapters = oldChapters
			setChapters(newChapters)
		}
		return true
	}
	
	private func setChapters(_ newValue: [Chapter], reloadTableData: Bool = true) {
		guard book != nil && book!.chapters != newValue else {
			return
		}
		let oldValue = book!.chapters
		undoManager?.registerUndo(withTarget: self) { $0.setChapters(oldValue) }
		book!.chapters = newValue
		if reloadTableData {
			tableView.reloadData()
		}
		document?.notificationCenter.post(name: .bookEdited, object: book!.chapters)
	}
}

extension ChaptersDetailVC: NSTableViewDataSource {
	func numberOfRows(in tableView: NSTableView) -> Int {
		// One row for each chapter, one row for each subchapter
		var n = 0
		if let b = book {
			n = b.chapters.count
			for c in b.chapters {
				n += c.subchapters.count
			}
		}
		return n
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		var cellView: NSTableCellView?
		
		if let rowObject = objectFor(row: row) {
			if tableColumn == colStatus {
				cellView = tableView.makeView(withIdentifier: .chaptersDetailStatus, owner: self) as? NSTableCellView
				var status = EditStatus.multiple
				if let ch = rowObject as? Chapter {
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
				if let sub = rowObject as? SubChapter {
					cellView?.textField?.stringValue = sub.headerInfo.description
					cellView?.textField?.font = f?.unbolded()?.resized(to: 11)
				}
				else if let ch = rowObject as? Chapter {
					cellView?.textField?.stringValue = ch.titleSubtitle
					cellView?.textField?.font = f?.bolded()?.resized(to: 13)
					tableView.rowView(atRow: row, makeIfNecessary: false)?.backgroundColor = NSColor.unemphasizedSelectedTextBackgroundColor
				}
			}
			
			if tableColumn == colPOV {
				cellView = tableView.makeView(withIdentifier: .chaptersDetailPOV, owner: self) as? NSTableCellView
				if let sub = rowObject as? SubChapter {
					cellView?.textField?.stringValue = sub.headerInfo.pov
				}
				else {
					cellView?.textField?.stringValue = ""
				}
			}
			
			if tableColumn == colLocation {
				cellView = tableView.makeView(withIdentifier: .chaptersDetailLocation, owner: self) as? NSTableCellView
				if let sub = rowObject as? SubChapter {
					cellView?.textField?.stringValue = sub.headerInfo.location
				}
				else {
					cellView?.textField?.stringValue = ""
				}
			}
			
			if tableColumn == colWords {
				cellView = tableView.makeView(withIdentifier: .chaptersDetailWords, owner: self) as? NSTableCellView
				if let sub = rowObject as? SubChapter {
					cellView?.textField?.stringValue = "\(sub.wordCount)"
				}
				else if let ch = rowObject as? Chapter {
					cellView?.textField?.stringValue = "\(ch.wordCount)"
				}
			}
		}
		
		return cellView
	}
	
	private func objectFor(row: Int) -> Any? {
		if let b = book {
			var index = -1
			for c in b.chapters {
				index += 1
				if index == row {
					return c as Any
				}
				for sub in c.subchapters {
					index += 1
					if index == row {
						return sub as Any
					}
				}
			}
		}
		return nil
	}
	
	private func objectFor(id: String) -> Any? {
		if let b = book {
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
