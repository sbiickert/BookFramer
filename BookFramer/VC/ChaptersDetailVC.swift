//
//  ChaptersDetailVC.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-24.
//

import Cocoa

class ChaptersDetailVC: NSViewController {
	
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
    }
    
	private func updateUI() {
		tableView.reloadData()
	}
	
	@objc func tableViewWasDoubleClicked() {
		//print("Double click on row \(tableView.clickedRow) and column \(tableView.clickedColumn)")
		guard tableView.clickedRow >= 0 else {
			return // click on header
		}
		if let rowObject = objectFor(row: tableView.clickedRow) {
			if rowObject.1 != nil {
				// Double click on scene
				NotificationCenter.default.post(name: .selectedItemDidChange, object: rowObject.1)
			}
			else {
				// Double click on chapter
				NotificationCenter.default.post(name: .selectedItemDidChange, object: rowObject.0)
			}
		}
	}
	
}

extension ChaptersDetailVC: NSTableViewDelegate {
	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		return 24.0
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
				var status = rowObject.0.status
				if rowObject.1 != nil {
					status = rowObject.1!.headerInfo.status
				}
				let image = NSImage(systemSymbolName: status.imageName, accessibilityDescription: status.rawValue)
				cellView?.imageView?.contentTintColor = status.tint
				cellView?.imageView?.image = image
			}
			
			if tableColumn == colInfo {
				cellView = tableView.makeView(withIdentifier: .chaptersDetailInfo, owner: self) as? NSTableCellView
				let f = cellView?.textField?.font
				if rowObject.1 != nil {
					cellView?.textField?.stringValue = rowObject.1!.headerInfo.description
					cellView?.textField?.font = f?.unbolded()?.resized(to: 11)
				}
				else {
					cellView?.textField?.stringValue = rowObject.0.titleSubtitle
					cellView?.textField?.font = f?.bolded()?.resized(to: 13)
					tableView.rowView(atRow: row, makeIfNecessary: false)?.backgroundColor = NSColor.unemphasizedSelectedTextBackgroundColor
				}
			}
			
			if tableColumn == colPOV {
				cellView = tableView.makeView(withIdentifier: .chaptersDetailPOV, owner: self) as? NSTableCellView
				if rowObject.1 != nil {
					cellView?.textField?.stringValue = rowObject.1!.headerInfo.pov
				}
				else {
					cellView?.textField?.stringValue = ""
				}
			}
			
			if tableColumn == colLocation {
				cellView = tableView.makeView(withIdentifier: .chaptersDetailLocation, owner: self) as? NSTableCellView
				if rowObject.1 != nil {
					cellView?.textField?.stringValue = rowObject.1!.headerInfo.location
				}
				else {
					cellView?.textField?.stringValue = ""
				}
			}
			
			if tableColumn == colWords {
				cellView = tableView.makeView(withIdentifier: .chaptersDetailWords, owner: self) as? NSTableCellView
				if rowObject.1 != nil {
					cellView?.textField?.stringValue = "\(rowObject.1!.wordCount)"
				}
				else {
					cellView?.textField?.stringValue = "\(rowObject.0.wordCount)"
				}
			}
		}

		return cellView
	}
	
	private func objectFor(row: Int) -> (Chapter, SubChapter?)? {
		if let b = book {
			var index = -1
			for c in b.chapters {
				index += 1
				if index == row {
					return (c, nil)
				}
				for sub in c.subchapters {
					index += 1
					if index == row {
						return (c, sub)
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
