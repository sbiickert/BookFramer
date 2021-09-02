//
//  SubChapterDetailVC.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-24.
//

import Cocoa

class SubChapterDetailVC: BFViewController {

	var book: Book? {
		didSet {
			updateUI()
		}
	}

	var subchapter: SubChapter? {
		didSet {
			updateUI()
		}
	}

	@IBOutlet weak var descriptionField: NSTextField!
	@IBOutlet weak var locationField: NSTextField!
	@IBOutlet weak var statusPopupMenu: NSPopUpButton!
	@IBOutlet weak var statusImage: NSImageView!
	@IBOutlet weak var povPopupMenu: NSPopUpButton!
	@IBOutlet weak var charactersField: NSTextField!
	@IBOutlet weak var paragraphsLabel: NSTextField!
	@IBOutlet weak var wordsLabel: NSTextField!
	@IBOutlet weak var startsAtLineLabel: NSTextField!
	
	
	override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
		statusPopupMenu.removeAllItems()
		statusPopupMenu.addItem(withTitle: EditStatus.rough.rawValue)
		statusPopupMenu.addItem(withTitle: EditStatus.inProgress.rawValue)
		statusPopupMenu.addItem(withTitle: EditStatus.good.rawValue)
		statusPopupMenu.addItem(withTitle: EditStatus.finished.rawValue)
    }
    
	
	private func updateUI() {
		descriptionField.stringValue = subchapter?.headerInfo.description ?? ""
		locationField.stringValue = subchapter?.headerInfo.location ?? ""
		charactersField.stringValue = personas
		wordsLabel.stringValue = "Words: \(subchapter?.wordCount ?? 0)"
		paragraphsLabel.stringValue = "Chapter: \(subchapter?.paragraphs.count ?? 0)"
		startsAtLineLabel.stringValue = "Starts at Line: \(subchapter?.startLineNumber ?? 0)"
		
		
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
		   let menuItem = statusPopupMenu.item(withTitle: p.name) {
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
	
	@IBAction func descriptionChanged(_ sender: NSTextField) {
		setDescription(sender.stringValue)
	}
	private func setDescription(_ value: String) {
		
	}
	
	@IBAction func locationChanged(_ sender: NSTextField) {
		setLocation(sender.stringValue)
	}
	private func setLocation(_ value: String) {
		
	}
	
	@IBAction func statusChanged(_ sender: NSPopUpButton) {
		if let menuItem = sender.selectedItem {
			setStatus(EditStatus.init(rawValue: menuItem.title)!)
		}
		updateStatusMenu()
	}
	private func setStatus(_ value: EditStatus) {
		//subchapter?.headerInfo.status =
	}
	
	@IBAction func povChanged(_ sender: NSPopUpButton) {
		setPOV(sender.selectedItem?.title ?? "")
	}
	private func setPOV(_ value: String) {
		
	}
	
}
