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
			if book != nil && chapter != nil {
				assert(book!.chapters.contains(where: {$0.id == chapter!.id}))
			}
            updateUI()
        }
    }
    
    @IBOutlet weak var titleField: NSTextField!
    
    @IBOutlet weak var subtitleField: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func updateUI() {
		super.updateUI()
        titleField.stringValue = chapter?.title ?? ""
        subtitleField.stringValue = chapter?.subtitle ?? ""
    }
	
	@IBAction func delete(_ sender: AnyObject) {
		if sender is NSButton,
			let ch = chapter {
			document?.notificationCenter.post(name: .deleteChapter, object: ch)
		}
	}
	
	@IBAction func addScene(_ sender: AnyObject) {
		guard chapter != nil else { return }
		document?.notificationCenter.post(name: .addSubChapter, object: chapter)
//		let sub = SubChapter(text: "")
//		chapter!.subchapters.append(sub)
//		setChapter(newValue: chapter!)
//		updateUI()
	}
	private func setChapter(newValue: Chapter) {
		guard book != nil else { return }
		if let oldChapter = book!.chapters.first(where: { $0.id == newValue.id }) {
			undoManager?.registerUndo(withTarget: self) { $0.setChapter(newValue: oldChapter) }
			book!.replace(chapter: newValue)
		}
	}

	@IBAction func openInBBEdit(_ sender: AnyObject) {
		print("openInBBEdit in chapter detail")
		if let ch = chapter {
			document?.notificationCenter.post(name: .openExternal, object: ch)
		}
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
}

