//
//  ChapterDetailVC.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-24.
//

import Cocoa

class ChapterDetailVC: BFViewController {

	var book: Book? {
		didSet {
			updateUI()
		}
	}

	var chapter: Chapter? {
		didSet {
			updateUI()
		}
	}

	@IBOutlet weak var titleField: NSTextField!
	
	@IBOutlet weak var subtitleField: NSTextField!
	@IBOutlet weak var wordsLabel: NSTextField!
	@IBOutlet weak var chapterNumberLabel: NSTextField!
	@IBOutlet weak var lineNumberLabel: NSTextField!
	
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
		titleField.stringValue = chapter?.title ?? ""
		subtitleField.stringValue = chapter?.subtitle ?? ""
		wordsLabel.stringValue = "Words: \(chapter?.wordCount ?? 0)"
		chapterNumberLabel.stringValue = "Chapter: \(chapter?.number ?? 0)"
		lineNumberLabel.stringValue = "Starts at Line: \(chapter?.startLineNumber ?? 0)"
		
		tableView.reloadData()
	}
	
	/**
	Target of action when `titleField` changes. Calls `setTitle`
	- Parameter sender: the NSTextField
	*/
	@IBAction func titleChanged(_ sender: NSTextField) {
		setTitle(sender.stringValue)
	}
	/**
	Undoable way to set the title of the chapter.
	- Parameter newValue: the value to change the title to
	*/
	private func setTitle(_ newValue: String) {
		guard book != nil && chapter != nil && chapter!.title != newValue else {
			return
		}
		let oldValue = chapter!.title
		undoManager?.registerUndo(withTarget: self) { $0.setTitle(oldValue) }
		chapter!.title = newValue
		titleField.stringValue = newValue
		// Chapter is a value type. Need to replace it in the book
		book!.replace(chapter: chapter!)
		document?.notificationCenter.post(name: .bookEdited, object: chapter!)
	}

	/**
	Target of action when `subtitleField` changes. Calls `setSubtitle`
	- Parameter sender: the NSTextField
	*/
	@IBAction func subtitleChanged(_ sender: NSTextField) {
		setSubtitle(sender.stringValue)
	}
	private func setSubtitle(_ newValue: String) {
		guard book != nil && chapter != nil && chapter!.subtitle != newValue else {
			return
		}
		let oldValue = chapter!.subtitle
		undoManager?.registerUndo(withTarget: self) { $0.setSubtitle(oldValue) }
		chapter!.subtitle = newValue
		subtitleField.stringValue = newValue
		// Chapter is a value type. Need to replace it in the book
		book!.replace(chapter: chapter!)
		document?.notificationCenter.post(name: .bookEdited, object: chapter!)
	}

	
	@objc func tableViewWasDoubleClicked() {
		//print("Double click on row \(tableView.clickedRow) and column \(tableView.clickedColumn)")
		guard tableView.clickedRow >= 0 else {
			return // click on header
		}
		if let rowObject = tableView(tableView, objectValueFor: nil, row: tableView.clickedRow) {
			document?.notificationCenter.post(name: .selectedItemDidChange, object: rowObject)
		}
	}

}

extension ChapterDetailVC: NSTableViewDelegate {
	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		return 24.0
	}
}

extension ChapterDetailVC: NSTableViewDataSource {
	func numberOfRows(in tableView: NSTableView) -> Int {
		return chapter?.subchapters.count ?? 0
	}
	
	func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		guard row >= 0 && row < (chapter?.subchapters.count ?? 0) else {
			return nil
		}
		return chapter?.subchapters[row]
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		var cellView: NSTableCellView?

		if let sub = self.tableView(tableView, objectValueFor: nil, row: row) as? SubChapter {
			if tableColumn == colStatus {
				cellView = tableView.makeView(withIdentifier: .chaptersDetailStatus, owner: self) as? NSTableCellView
				let status = sub.headerInfo.status
				let image = NSImage(systemSymbolName: status.imageName, accessibilityDescription: status.rawValue)
				cellView?.imageView?.contentTintColor = status.tint
				cellView?.imageView?.image = image
			}
			
			if tableColumn == colInfo {
				cellView = tableView.makeView(withIdentifier: .chaptersDetailInfo, owner: self) as? NSTableCellView
				cellView?.textField?.stringValue = sub.headerInfo.description
			}
			
			if tableColumn == colPOV {
				cellView = tableView.makeView(withIdentifier: .chaptersDetailPOV, owner: self) as? NSTableCellView
				cellView?.textField?.stringValue = sub.headerInfo.pov
			}
			
			if tableColumn == colLocation {
				cellView = tableView.makeView(withIdentifier: .chaptersDetailLocation, owner: self) as? NSTableCellView
				cellView?.textField?.stringValue = sub.headerInfo.location
			}
			
			if tableColumn == colWords {
				cellView = tableView.makeView(withIdentifier: .chaptersDetailWords, owner: self) as? NSTableCellView
				cellView?.textField?.stringValue = "\(sub.wordCount)"
			}

		}
		
		return cellView
	}
}
