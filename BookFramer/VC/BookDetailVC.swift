//
//  BookDetailVC.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-24.
//

import Cocoa

class BookDetailVC: NSViewController {
	
	var book: Book? {
		didSet {
			updateUI()
		}
	}
	
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
		
		titleField.delegate = self
		subtitleField.delegate = self
		authorField.delegate = self
		yearField.delegate = self
		keywordField.delegate = self
		
		NotificationCenter.default.addObserver(self, selector: #selector(genreChanged(notification:)), name: .genreDidChange, object: nil)
	}
	
	/**
	Updates all views
	*/
	private func updateUI() {
		titleField.stringValue = book?.title ?? ""
		subtitleField.stringValue = book?.subtitle ?? ""
		authorField.stringValue = book?.headerInfo.author ?? ""
		yearField.stringValue = book?.headerInfo.year ?? ""
		keywordField.stringValue = book?.headerInfo.joinedKeywords ?? ""
		tableView.reloadData()
	}
	
	/**
	Target of action when `titleField` changes. Calls `setTitle`
	- Parameter sender: the NSTextField
	*/
	@IBAction func titleChanged(_ sender: NSTextField) {
		self.setTitle(sender.stringValue)
	}
	/**
	Undoable way to set the title of the book.
	- Parameter newValue: the value to change the title to
	*/
	private func setTitle(_ newValue: String) {
		guard book != nil && book!.title != newValue else {
			return
		}
		let oldValue = book!.title
		undoManager?.registerUndo(withTarget: self) { $0.setTitle(oldValue) }
		book!.title = newValue
		titleField.stringValue = newValue
	}
	
	/**
	Target of action when `subtitleField` changes. Calls `setSubtitle`
	- Parameter sender: the NSTextField
	*/
	@IBAction func subtitleChanged(_ sender: NSTextField) {
		self.setSubtitle(sender.stringValue)
	}
	/**
	Undoable way to set the subtitle of the book.
	- Parameter newValue: the value to change the subtitle to
	*/
	private func setSubtitle(_ newValue: String) {
		guard book != nil && book!.subtitle != newValue else {
			return
		}
		let oldValue = book!.subtitle
		undoManager?.registerUndo(withTarget: self) { $0.setSubtitle(oldValue) }
		book!.subtitle = newValue
		subtitleField.stringValue = newValue
	}
	
	/**
	Target of action when `authorField` changes. Calls `setAuthor`
	- Parameter sender: the NSTextField
	*/
	@IBAction func authorChanged(_ sender: NSTextField) {
		self.setAuthor(sender.stringValue)
	}
	/**
	Undoable way to set the author of the book.
	- Parameter newValue: the value to change the author to
	*/
	private func setAuthor(_ newValue: String) {
		guard book != nil && book!.headerInfo.author != newValue else {
			return
		}
		let oldValue = book!.headerInfo.author
		undoManager?.registerUndo(withTarget: self) { $0.setAuthor(oldValue) }
		book!.headerInfo.author = newValue
		authorField.stringValue = newValue
	}
	
	/**
	Target of action when `yearField` changes. Calls `setYear`
	- Parameter sender: the NSTextField
	*/
	@IBAction func yearChanged(_ sender: NSTextField) {
		self.setYear(sender.stringValue)
	}
	/**
	Undoable way to set the year of the book.
	- Parameter newValue: the value to change the year to
	*/
	private func setYear(_ newValue: String) {
		guard book != nil && book!.headerInfo.year != newValue else {
			return
		}
		let oldValue = book!.headerInfo.year
		undoManager?.registerUndo(withTarget: self) { $0.setYear(oldValue) }
		book!.headerInfo.year = newValue
		yearField.stringValue = newValue
	}
	
	/**
	Target of action when `keywordsField` changes. Calls `setKeywords`
	- Parameter sender: the NSTextField
	*/
	@IBAction func keywordsChanged(_ sender: NSTextField) {
		self.setKeywords(sender.stringValue)
	}
	/**
	Undoable way to set the keywords of the book. Keywords are comma-separated by the `Book`
	- Parameter newValue: the value to change the keywords to
	*/
	private func setKeywords(_ newValue: String) {
		guard book != nil && book!.headerInfo.joinedKeywords != newValue else {
			return
		}
		let oldValue = book!.headerInfo.joinedKeywords
		undoManager?.registerUndo(withTarget: self) { $0.setKeywords(oldValue) }
		book!.headerInfo.joinedKeywords = newValue
		keywordField.stringValue = newValue
	}
	
	/**
	Listens for .genreDidChange Notification. Calls `setGenres`
	- Parameter notification: Notification that a genre checkbox changed
	*/
	@objc func genreChanged(notification:Notification) {
		var newValues = [Genre]()
		for index in 0..<Genre.allCases.count {
			if let cbv = tableView.view(atColumn: 0, row: index, makeIfNecessary: false) as? CheckboxTableCellView {
				if cbv.checkbox?.state == NSControl.StateValue.on {
					newValues.append(Genre.allCases[index])
				}
			}
		}
		self.setGenres(newValues)
	}
	/**
	Undoable way to set the genres of the book.
	- Parameter newValue: the value to change the genres to
	*/
	private func setGenres(_ newValue: [Genre]) {
		guard book != nil && book!.headerInfo.genres != newValue else {
			return
		}
		let oldValue = book!.headerInfo.genres
		undoManager?.registerUndo(withTarget: self) { $0.setGenres(oldValue) }
		book!.headerInfo.genres = newValue
		tableView.reloadData()
	}
}

extension BookDetailVC: NSTextFieldDelegate {
	// This code is for logging continuous edits to text. Disabled to make undo/redo simpler.
	//    func controlTextDidChange(_ obj: Notification) {
	//        if let textField = obj.object as? NSTextField {
	//            if textField == titleField {
	//                setTitle(textField.stringValue)
	//            }
	//            else if textField == subtitleField {
	//                setSubtitle(textField.stringValue)
	//            }
	//			else if textField == authorField {
	//				setAuthor(textField.stringValue)
	//			}
	//			else if textField == yearField {
	//				setYear(textField.stringValue)
	//			}
	//            else if textField == keywordField {
	//               setKeywords(textField.stringValue)
	//            }
	//            NotificationCenter.default.post(name: .bookDidChange, object: nil)
	//        }
	//    }
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
				let isChecked = book?.headerInfo.genres.contains(g) ?? false
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
