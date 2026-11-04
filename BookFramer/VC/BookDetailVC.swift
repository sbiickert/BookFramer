//
//  BookDetailVC.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-24.
//

import Cocoa

class BookDetailVC: BFViewController {
	@IBOutlet weak var titleField: NSTextField!
	@IBOutlet weak var subtitleField: NSTextField!
	@IBOutlet weak var authorField: NSTextField!
	@IBOutlet weak var yearField: NSTextField!
	@IBOutlet weak var keywordField: NSTextField!
	
	@IBOutlet weak var tableView: NSTableView!
	@IBOutlet weak var tableColCheckbox: NSTableColumn!
	@IBOutlet weak var tableColDescription: NSTableColumn!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.delegate = self
		tableView.dataSource = self
	}
	
	private var _observerAdded = false
	override func viewDidAppear() {
		super.viewDidAppear()
		updateUI()
		if _observerAdded == false {
			document?.notificationCenter.addObserver(self, selector: #selector(contextChanged(notification:)), name: .contextDidChange, object: nil)
			_observerAdded = true
		}
	}
	
	@objc func contextChanged(notification: NSNotification) {
		updateUI()
	}
	
	/**
	Updates all views
	*/
	override func updateUI() {
		super.updateUI()
		let book = context?.book
		titleField.stringValue = book?.title ?? ""
		subtitleField.stringValue = book?.subtitle ?? ""
		authorField.stringValue = book?.headerInfo.author ?? ""
		yearField.stringValue = book?.headerInfo.year ?? ""
		keywordField.stringValue = book?.headerInfo.joinedKeywords ?? ""
		tableView.reloadData()
	}

	/**
	Posts the book info from the form fields as an edit, if anything changed.
	- Parameter genres: the new genres. If nil, the book's current genres are kept. Genres are not read
	  from the table's checkboxes, because rows scrolled out of view have no checkbox to read.
	*/
	private func modifyBook(genres: [Genre]? = nil) {
		guard let book = context?.book else { return }

		var header = book.headerInfo
		header.author = authorField.stringValue
		header.year = yearField.stringValue
		header.joinedKeywords = keywordField.stringValue
		if let genres = genres {
			header.genres = genres
		}

		let currentInfo = DocEditor.BookInfo(title: book.title,
											 subtitle: book.subtitle,
											 header: book.headerInfo)
		
		let info = DocEditor.BookInfo(title: titleField.stringValue,
									  subtitle: subtitleField.stringValue,
									  header: header)
		
		if currentInfo != info {
			document?.notificationCenter.post(name: .modifyBookInfo, object: info)
		}
	}
	
	/**
	Target of action when `titleField` changes. Calls `modifyBook`
	- Parameter sender: the NSTextField
	*/
	@IBAction func titleChanged(_ sender: NSTextField) {
		modifyBook()
	}
	
	/**
	Target of action when `subtitleField` changes. Calls `modifyBook`
	- Parameter sender: the NSTextField
	*/
	@IBAction func subtitleChanged(_ sender: NSTextField) {
		modifyBook()
	}
	
	/**
	Target of action when `authorField` changes. Calls `modifyBook`
	- Parameter sender: the NSTextField
	*/
	@IBAction func authorChanged(_ sender: NSTextField) {
		modifyBook()
	}
	
	/**
	Target of action when `yearField` changes. Calls `modifyBook`
	- Parameter sender: the NSTextField
	*/
	@IBAction func yearChanged(_ sender: NSTextField) {
		modifyBook()
	}
	
	/**
	Target of action when `keywordsField` changes. Calls `modifyBook`
	- Parameter sender: the NSTextField
	*/
	@IBAction func keywordsChanged(_ sender: NSTextField) {
		modifyBook()
	}
	
	/**
	Listens for tableView checkbox state changes. Calls `modifyBook`
	- Parameter sender: Checkbox that changed state
	*/
	@IBAction func genreChanged(_ sender: NSButton) {
		let row = tableView.row(for: sender)
		guard let book = context?.book,
			  Genre.allCases.indices.contains(row) else { return }
		var selected = Set(book.headerInfo.genres)
		if sender.state == .on {
			selected.insert(Genre.allCases[row])
		}
		else {
			selected.remove(Genre.allCases[row])
		}
		// Keep genres in the same order as the table
		modifyBook(genres: Genre.allCases.filter { selected.contains($0) })
	}
}

extension BookDetailVC: NSTableViewDelegate {
	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		return 24.0
	}
}

extension BookDetailVC: NSTableViewDataSource {
	func numberOfRows(in tableView: NSTableView) -> Int {
		return Genre.allCases.count
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		var cellView: NSTableCellView?
		
		if tableColumn == tableColCheckbox {
			if let cbv = tableView.makeView(withIdentifier: .check, owner: self) as? CheckboxTableCellView {
				let g = Genre.allCases[row]
				let isChecked = context?.book?.headerInfo.genres.contains(g) ?? false
				//print("Genre \(g) is checked? \(isChecked)")
				cbv.checkbox?.state = isChecked ? NSControl.StateValue.on : NSControl.StateValue.off
				cellView = cbv
			}
		}
		else { // tableColumn == tableColDescription
			if let cv = tableView.makeView(withIdentifier: .description, owner: self) as? NSTableCellView {
				cv.textField?.stringValue = Genre.allCases[row].rawValue
				cellView = cv
			}
		}
		return cellView
	}
}

extension NSUserInterfaceItemIdentifier {
	static let check = NSUserInterfaceItemIdentifier(rawValue: "Check")
	static let description = NSUserInterfaceItemIdentifier(rawValue: "Description")
}
