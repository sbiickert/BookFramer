//
//  SubChapterDetailVC.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-24.
//

import Cocoa

class SubChapterDetailVC: BFViewController, NSTextFieldDelegate {
	@IBOutlet weak var descriptionField: NSTextField!
	@IBOutlet weak var locationField: NSTextField!
	@IBOutlet weak var statusPopupMenu: NSPopUpButton!
	@IBOutlet weak var statusImage: NSImageView!
	@IBOutlet weak var povPopupMenu: NSPopUpButton!
	@IBOutlet var charactersTextView: NSTextView!
	
	
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

	override func updateUI() {
		super.updateUI()
		let subchapter = context?.selectedSubChapter
		descriptionField.stringValue = subchapter?.headerInfo.description ?? ""
		locationField.stringValue = subchapter?.headerInfo.location ?? ""
		charactersTextView.string = personas		
		
		updateStatusMenu()
		
		povPopupMenu.removeAllItems()
		if let b = context?.book {
			for p in b.allPersonas {
				povPopupMenu.addItem(withTitle: p.name)
			}
		}
		updatePovMenu()
	}
	
	private func updateStatusMenu() {
		let subchapter = context?.selectedSubChapter
		if let status = subchapter?.headerInfo.status,
		   let menuItem = statusPopupMenu.item(withTitle: status.rawValue) {
			let menuImage = NSImage(systemSymbolName: status.imageName, accessibilityDescription: status.rawValue)
			statusPopupMenu.select(menuItem)
			statusImage.image = menuImage
			statusImage.contentTintColor = status.tint
		}
	}
	
	private func updatePovMenu() {
		if let book = context?.book,
		   let subchapter = context?.selectedSubChapter,
		   let p = book.findPersona(named: subchapter.headerInfo.pov),
		   let menuItem = povPopupMenu.item(withTitle: p.name) {
			povPopupMenu.select(menuItem)
		}
	}
	
	private var personas: String {
		if let book = context?.book,
		   let subchapter = context?.selectedSubChapter {
			var resultList = [String]()
			for p in book.allPersonas {
				if p.isIn(subChapter: subchapter) {
					resultList.append(p.name)
				}
			}
			return resultList.joined(separator: "\n")
		}
		return ""
	}
	
	@IBAction func openInBBEdit(_ sender: AnyObject) {
		print("openInBBEdit in subchapter detail")
		if let sub = context?.selectedSubChapter {
			document?.notificationCenter.post(name: .openExternal, object: sub)
		}
	}

    private func modifySubChapter() {
		if var sub = context?.selectedSubChapter {
			sub.headerInfo.description = descriptionField.stringValue
			sub.headerInfo.location = locationField.stringValue
			if let menuItem = statusPopupMenu.selectedItem {
				sub.headerInfo.status = EditStatus.init(rawValue: menuItem.title)!
			}
			sub.headerInfo.pov = povPopupMenu.selectedItem?.title ?? ""
			
			document?.notificationCenter.post(name: .modifySubChapter, object: sub)
		}
    }
	
	@IBAction func delete(_ sender: Any) {
		if sender is NSButton,
		   let sub = context?.selectedSubChapter {
			document?.notificationCenter.post(name: .openExternal, object: sub)
		}
	}

	/**
	Target of action when `descriptionField` changes. Calls `modifySubChapter`
	- Parameter sender: the NSTextField
	*/
	@IBAction func descriptionChanged(_ sender: NSTextField) {
		modifySubChapter()
	}
	
	/**
	 `NSTextFieldDelegate` event raised on each typed change to the location field. Using to implement auto-suggest.
	 - Parameter obj: Notification of the change.
	 */
	private var _prevLocLen: Int? = nil
	func controlTextDidChange(_ obj: Notification) {
		if let field = obj.object as? NSTextField,
		   field.stringValue.isEmpty == false,
		   let book = context?.book {
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
	Target of action when `locationField` changes. Calls `modifySubChapter`
	- Parameter sender: the NSTextField
	*/
	@IBAction func locationChanged(_ sender: NSTextField) {
		modifySubChapter()
	}
	
	/**
	Target of action when `statusPopupMenu` changes. Calls `modifySubChapter`
	- Parameter sender: the NSPopUpButton
	*/
	@IBAction func statusChanged(_ sender: NSPopUpButton) {
		modifySubChapter()
	}
	
	/**
	Target of action when `povPopupMenu` changes. Calls `modifySubChapter`
	- Parameter sender: the NSPopUpButton
	*/
	@IBAction func povChanged(_ sender: NSPopUpButton) {
		modifySubChapter()
	}
}
