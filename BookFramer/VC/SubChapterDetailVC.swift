//
//  SubChapterDetailVC.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-24.
//

import Cocoa

class SubChapterDetailVC: BFViewController, NSTextFieldDelegate {

	var book: Book? {
		didSet {
			guard descriptionField != nil else { return }
			updateUI()
		}
	}

	var subchapter: SubChapter? {
		didSet {
			guard descriptionField != nil else { return }
			updateUI()
		}
	}

	@IBOutlet weak var descriptionField: NSTextField!
	@IBOutlet weak var locationField: NSTextField!
	@IBOutlet weak var statusPopupMenu: NSPopUpButton!
	@IBOutlet weak var statusImage: NSImageView!
	@IBOutlet weak var povPopupMenu: NSPopUpButton!
	@IBOutlet weak var charactersField: NSTextField!
	
	
	override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
		statusPopupMenu.removeAllItems()
		statusPopupMenu.addItem(withTitle: EditStatus.rough.rawValue)
		statusPopupMenu.addItem(withTitle: EditStatus.inProgress.rawValue)
		statusPopupMenu.addItem(withTitle: EditStatus.good.rawValue)
		statusPopupMenu.addItem(withTitle: EditStatus.finished.rawValue)
		updateUI()
    }
	
	override func updateUI() {
		super.updateUI()
		descriptionField.stringValue = subchapter?.headerInfo.description ?? ""
		locationField.stringValue = subchapter?.headerInfo.location ?? ""
		charactersField.stringValue = personas		
		
		updateStatusMenu()
		
		povPopupMenu.removeAllItems()
		if let b = book {
			for p in b.allPersonas {
				povPopupMenu.addItem(withTitle: p.name)
			}
		}
		updatePovMenu()
	}
	
	private func updateStatusMenu() {
		if let status = subchapter?.headerInfo.status,
		   let menuItem = statusPopupMenu.item(withTitle: status.rawValue) {
			let menuImage = NSImage(systemSymbolName: status.imageName, accessibilityDescription: status.rawValue)
			statusPopupMenu.select(menuItem)
			statusImage.image = menuImage
			statusImage.contentTintColor = status.tint
		}
	}
	
	private func updatePovMenu() {
		if let p = book?.findPersona(named: subchapter?.headerInfo.pov ?? ""),
		   let menuItem = povPopupMenu.item(withTitle: p.name) {
			povPopupMenu.select(menuItem)
		}
	}
	
	private var personas: String {
		guard book != nil && subchapter != nil else {
			return ""
		}
		var resultList = [String]()
		for p in book!.allPersonas {
			if p.isIn(subChapter: subchapter!) {
				resultList.append(p.name)
			}
		}
		return resultList.joined(separator: "\n")
	}
    
    private func writeChangedSubChapterToBook() {
        guard book != nil && subchapter != nil else {
            return
        }
        // Chapter / SubChapter are value types. Need to replace it in Book
        if var ch = book!.chapterContaining(subchapter: subchapter!) {
            ch.replace(subchapter: subchapter!)
            book!.replace(chapter: ch)
        }
    }
	
	@IBAction func delete(_ sender: Any) {
		if sender is NSButton,
		   let sub = subchapter {
			document?.notificationCenter.post(name: .openExternal, object: sub)
		}
	}
	
	@IBAction func openInBBEdit(_ sender: AnyObject) {
		print("openInBBEdit in subchapter detail")
		if let sub = subchapter {
			document?.notificationCenter.post(name: .openExternal, object: sub)
		}
	}

	/**
	Target of action when `descriptionField` changes. Calls `setDescription`
	- Parameter sender: the NSTextField
	*/
	@IBAction func descriptionChanged(_ sender: NSTextField) {
		setDescription(sender.stringValue)
	}
	/**
	Undoable way to set the description of the subchapter.
	- Parameter newValue: the value to change the description to
	*/
	private func setDescription(_ newValue: String) {
		guard book != nil && subchapter != nil && subchapter!.headerInfo.description != newValue else {
			return
		}
		let oldValue = subchapter!.headerInfo.description
		undoManager?.registerUndo(withTarget: self) { $0.setDescription(oldValue) }
		subchapter!.headerInfo.description = newValue
		descriptionField.stringValue = newValue
        writeChangedSubChapterToBook()
		document?.notificationCenter.post(name: .bookEdited, object: subchapter!)
	}
	
	/**
	 `NSTextFieldDelegate` event raised on each typed change to the location field. Using to implement auto-suggest.
	 - Parameter obj: Notification of the change.
	 */
	private var _prevLocLen: Int? = nil
	func controlTextDidChange(_ obj: Notification) {
		if let field = obj.object as? NSTextField,
		   field.stringValue.isEmpty == false,
		   let book = book {
			// This is the "location" text field. Want to implement auto-suggestion
			// Only suggest if the string is growing (i.e. user typing more chars)
			if _prevLocLen ?? 0 < field.stringValue.count {
				_prevLocLen = field.stringValue.count
				let locs = book.allLocations.filter({$0.starts(with: field.stringValue)})
				if let match = locs.first,
				   let ed = field.currentEditor() {
					// It looks like the user is starting to type something that matches a location
					// Set the text to the match, but select the letters that are only suggested
					let nsMatch = NSString(string: match)
					let nsText = NSString(string: field.stringValue)
					field.stringValue = match
					let range = NSMakeRange(nsText.length, nsMatch.length - nsText.length)
					ed.selectedRange = range
				}
			}
			else {
				_prevLocLen = field.stringValue.count
			}
		}
	}

	/**
	Target of action when `locationField` changes. Calls `setLocation`
	- Parameter sender: the NSTextField
	*/
	@IBAction func locationChanged(_ sender: NSTextField) {
		setLocation(sender.stringValue)
	}
	/**
	Undoable way to set the location of the subchapter.
	- Parameter newValue: the value to change the location to
	*/
	private func setLocation(_ newValue: String) {
		guard book != nil && subchapter != nil && subchapter!.headerInfo.location != newValue else {
			return
		}
		let oldValue = subchapter!.headerInfo.location
		undoManager?.registerUndo(withTarget: self) { $0.setLocation(oldValue) }
		subchapter!.headerInfo.location = newValue
		locationField.stringValue = newValue
		writeChangedSubChapterToBook()
		document?.notificationCenter.post(name: .bookEdited, object: subchapter!)
	}
	
	@IBAction func statusChanged(_ sender: NSPopUpButton) {
		if let menuItem = sender.selectedItem {
			setStatus(EditStatus.init(rawValue: menuItem.title)!)
		}
	}
	private func setStatus(_ newValue: EditStatus) {
        guard book != nil && subchapter != nil && subchapter!.headerInfo.status != newValue else {
            return
        }
        let oldValue = subchapter!.headerInfo.status
        undoManager?.registerUndo(withTarget: self) { $0.setStatus(oldValue) }
        subchapter!.headerInfo.status = newValue
        writeChangedSubChapterToBook()
		updateStatusMenu()
        // Update icon in outline view
        document?.notificationCenter.post(name: .bookEdited, object: subchapter!)
	}
	
	@IBAction func povChanged(_ sender: NSPopUpButton) {
		setPOV(sender.selectedItem?.title ?? "")
	}
	private func setPOV(_ newValue: String) {
        guard book != nil && subchapter != nil && subchapter!.headerInfo.pov != newValue else {
            return
        }
        let oldValue = subchapter!.headerInfo.pov
        undoManager?.registerUndo(withTarget: self) { $0.setPOV(oldValue) }
        subchapter!.headerInfo.pov = newValue
        writeChangedSubChapterToBook()
        updatePovMenu()
		document?.notificationCenter.post(name: .bookEdited, object: subchapter!)
	}
}
