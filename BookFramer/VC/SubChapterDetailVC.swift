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
	@IBOutlet weak var povPopupMenu: NSPopUpButton!
	@IBOutlet weak var charactersField: NSTextField!
	@IBOutlet weak var paragraphsLabel: NSTextField!
	@IBOutlet weak var wordsLabel: NSTextField!
	@IBOutlet weak var startsAtLineLabel: NSTextField!
	
	
	override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
	
	private func updateUI() {
		descriptionField.stringValue = subchapter?.headerInfo.description ?? ""
		locationField.stringValue = subchapter?.headerInfo.location ?? ""
		charactersField.stringValue = personas
		wordsLabel.stringValue = "Words: \(subchapter?.wordCount ?? 0)"
		paragraphsLabel.stringValue = "Chapter: \(subchapter?.paragraphs.count ?? 0)"
		startsAtLineLabel.stringValue = "Starts at Line: \(subchapter?.startLineNumber ?? 0)"
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
}
