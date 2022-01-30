//
//  ViewController.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-23.
//

import Cocoa

class DocVC: NSTabViewController {
	
	
	var book: Book? {
        return representedObject as? Book
    }
	
	var manage: ManageVC? {
		for childVC in children {
			if let mvc = childVC as? ManageVC {
				return mvc
			}
		}
		return nil
	}
	
	var preview: PreviewVC? {
		for childVC in children {
			if let pvc = childVC as? PreviewVC {
				return pvc
			}
		}
		return nil
	}
	
	public var document: Document? {
		return self.view.window?.windowController?.document as? Document
	}

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
	
	override func viewDidAppear() {
		guard let toolbar = self.view.window?.toolbar else { return }
		for item in toolbar.items {
			if let searchItem = item as? NSSearchToolbarItem {
				searchItem.searchField.target = self
				searchItem.searchField.action = #selector (searchFieldAction(sender:))
				return
			}
		}
	}

	private var _observersAdded = false
    override var representedObject: Any? {
		willSet {
			// If the current value is not null, this represents a re-load b/c BBEdit changed the file
			// Need to compare the two and set the selected chapter/subchapter
			// So that we have continuity when the doc reloads.
			if let book = book,
			   let newBook = newValue as? Book {
				handleDocReload(old: book, new: newBook)
			}
		}
        didSet {
            manage?.book = book
			preview?.book = book
			if _selectedChapterID == nil && _selectedSubChapterID == nil { preview?.selectedPart = book }
			else if _selectedSubChapterID != nil { preview?.selectedPart = selectedSubChapter }
			else { preview?.selectedPart = selectedChapter }

			if _observersAdded == false {
				_observersAdded = true
				document?.notificationCenter.addObserver(self, selector: #selector(changeContext(notification:)), name: .changeContext, object: nil)
				document?.notificationCenter.addObserver(self, selector: #selector(openExternal(notification:)), name: .openExternal, object: nil)
				document?.notificationCenter.addObserver(self, selector: #selector(addChapter(notification:)), name: .addChapter, object: nil)
				document?.notificationCenter.addObserver(self, selector: #selector(addSubChapter(notification:)), name: .addSubChapter, object: nil)
				document?.notificationCenter.addObserver(self, selector: #selector(deleteChapter(notification:)), name: .deleteChapter, object: nil)
				document?.notificationCenter.addObserver(self, selector: #selector(deleteSubChapter(notification:)), name: .deleteSubChapter, object: nil)
			}
        }
    }
	
	@objc func changeContext(notification: Notification) {
		if let ch = notification.object as? Chapter {
			_selectedChapterID = ch.id
			_selectedSubChapterID = nil
			preview?.selectedPart = ch
		}
		else if let sub = notification.object as? SubChapter {
			_selectedSubChapterID = sub.id
			if let book = book,
			   let ch = book.chapterContaining(subchapter: sub) {
				_selectedChapterID = ch.id
			}
			preview?.selectedPart = sub
		}
		else if let b = notification.object as? Book {
			_selectedChapterID = nil
			_selectedSubChapterID = nil
			preview?.selectedPart = b
		}
		document?.notificationCenter.post(name: .contextDidChange, object: notification.object)
	}
	
	private var _selectedChapterID: String?
	private var selectedChapter: Chapter? {
		if let id = _selectedChapterID,
		   let book = book {
			return book.chapters.first(where: {$0.id == id})
		}
		return nil
	}
	
	private var _selectedSubChapterID: String?
	private var selectedSubChapter: SubChapter? {
		if let id = _selectedSubChapterID,
		   let book = book {
			return book.findSubChapter(id: id)
		}
		return nil
	}
	
	private func handleDocReload(old: Book, new: Book) {
		let temp = selectedChapter
		
		if let currentSelectedChapter = temp {
			_selectedChapterID = nil // if we don't find it
			// Find the old Chapter in the new Book
			for ch in new.chapters {
				if ch.roughlyEqual(to: currentSelectedChapter) {
					_selectedChapterID = ch.id
					break
				}
			}
		}
		
		if let currentSelectedSubChapter = selectedSubChapter,
		   let currentSelectedChapter = temp {
			_selectedSubChapterID = nil // if we don't find it
			// Find the old SubChapter in the new Book
			for sub in currentSelectedChapter.subchapters {
				if sub.roughlyEqual(to: currentSelectedSubChapter) {
					_selectedSubChapterID = sub.id
					break
				}
			}
		}
	}

	// Default handler for these menu selections pass nil
	// The detail VCs for Chapters, Chapter and SubChapter will pass a Chapter or SubChapter to indicate context
	@IBAction func addChapter(_ sender: AnyObject) {
		// Add a new chapter to the end of the book
		document?.notificationCenter.post(name: .addChapter, object: nil)
	}
	
	@objc func addChapter(notification: Notification) {
		guard book != nil else { return }
		
		var insertIndex = book!.chapters.count // default
		
		if let relativeCh = notification.object as? Chapter {
			// Add new chapter after relativeCh
			if let relativeIndex = book!.chapters.firstIndex(where: { $0.id == relativeCh.id} ) {
				insertIndex = relativeIndex + 1
			}
		}
		else if let relativeSub = notification.object as? SubChapter,
				let relativeCh = book!.chapterContaining(subchapter: relativeSub) {
			// Add new chapter after relativeCh
			if let relativeIndex = book!.chapters.firstIndex(where: { $0.id == relativeCh.id} ) {
				insertIndex = relativeIndex + 1
			}
		}
		else if let relativeSub = selectedSubChapter ,
				let relativeCh = book!.chapterContaining(subchapter: relativeSub) {
			// Add new chapter after relativeCh
			if let relativeIndex = book!.chapters.firstIndex(where: { $0.id == relativeCh.id} ) {
				insertIndex = relativeIndex + 1
			}
		}
		else if let relativeCh = selectedChapter {
			// Add new chapter after relativeCh
			if let relativeIndex = book!.chapters.firstIndex(where: { $0.id == relativeCh.id} ) {
				insertIndex = relativeIndex + 1
			}
		}
		
		let ch = Chapter(title: "", subtitle: "", number: -1, subchapters: [SubChapter]())
		// For undo
		let oldChapters = book!.chapters
		book!.add(chapter: ch, at: insertIndex)
		let newChapters = book!.chapters
		book!.chapters = oldChapters
		undoManager?.registerUndo(withTarget: book!) {
			$0.chapters = oldChapters
			self.document?.notificationCenter.post(name: .bookEdited, object: [oldChapters])
		}
		book!.chapters = newChapters
		document?.notificationCenter.post(name: .bookEdited, object: ch)
	}
	
	@IBAction func addScene(_ sender: AnyObject) {
		// Add a new subchapter to the end of the last chapter
		document?.notificationCenter.post(name: .addSubChapter, object: nil)
	}
	
	@objc func addSubChapter(notification: Notification) {
		guard book != nil else { return }
		
		var targetChapter = book!.chapters.last
		if let sub = notification.object as? SubChapter {
			targetChapter = book!.chapterContaining(subchapter: sub)
		}
		else if let ch = notification.object as? Chapter {
			targetChapter = ch
		}
		else if let ch = selectedChapter {
			targetChapter = ch
		}
		guard targetChapter != nil else {return}
		
		let sub = SubChapter(text: "")
		targetChapter!.subchapters.append(sub)
		// For undo
		let oldChapters = book!.chapters
		book!.replace(chapter: targetChapter!)
		let newChapters = book!.chapters
		book!.chapters = oldChapters
		undoManager?.registerUndo(withTarget: book!) {
			$0.chapters = oldChapters
			self.document?.notificationCenter.post(name: .bookEdited, object: targetChapter!)
		}
		book!.chapters = newChapters
		document?.notificationCenter.post(name: .bookEdited, object: sub)
	}
	
	@objc func deleteChapter(notification: Notification) {
		guard book != nil && notification.object != nil else {return}
		if let ch = notification.object as? Chapter {
			if let index = book!.indexOf(chapter: ch) {
				undoManager?.registerUndo(withTarget: book!) {
					$0.add(chapter: ch, at: index)
					self.document?.notificationCenter.post(name: .bookEdited, object: self.book!)
				}
				book!.removeChapter(at: index)
				document?.notificationCenter.post(name: .bookEdited, object: book!.chapters)
			}
		}
	}
	
	@objc func deleteSubChapter(notification: Notification) {
		guard book != nil && notification.object != nil else {return}
		if let sub = notification.object as? SubChapter,
		   let origCh = book!.chapterContaining(subchapter: sub),
		   var modCh = book!.chapterContaining(subchapter: sub),
		   let index = modCh.subchapters.firstIndex(where: {$0.id == sub.id}) {
			modCh.subchapters.remove(at: index)
			undoManager?.registerUndo(withTarget: book!) {
				$0.replace(chapter: origCh)
				self.document?.notificationCenter.post(name: .bookEdited, object: origCh)
			}
			book!.replace(chapter: modCh)
			document?.notificationCenter.post(name: .bookEdited, object: modCh)
		}
	}

	@IBAction func addPersona(_ sender: AnyObject) {
		// Add a new persona
		document?.notificationCenter.post(name: .addPersona, object: nil)
	}
	private func setPersonas(major: [Persona], minor: [Persona]) {
		guard book != nil else {
			return
		}
		let oldMajor = book!.majorPersonas
		let oldMinor = book!.minorPersonas
		undoManager?.beginUndoGrouping()
		undoManager?.registerUndo(withTarget: self) {
			$0.setPersonas(major: oldMajor, minor: oldMinor)
			self.document?.notificationCenter.post(name: .bookEdited, object: major)
		}
		book!.majorPersonas = major
		book!.minorPersonas = minor
		undoManager?.endUndoGrouping()
		self.document?.notificationCenter.post(name: .bookEdited, object: major)
	}
	
	@objc func searchFieldAction(sender: AnyObject) {
		guard let searchField = sender as? NSSearchField else { return }
		
		document?.notificationCenter.post(name: .search, object: searchField.stringValue)
	}

	@objc func openExternal(notification: NSNotification) {
		guard document != nil && undoManager != nil else {
			return
		}
		
		var lineNumber = 1
		
		if let ch = notification.object as? Chapter {
			lineNumber = book?.lineNumberFor(chapter: ch) ?? 1
		}
		else if let sub = notification.object as? SubChapter {
			lineNumber = book?.lineNumberFor(subchapter: sub) ?? 1
		}

		// If there are unsaved changes, save them
		if document!.fileURL == nil {
			// This document has not been saved
			document!.save(self)
			if document!.fileURL == nil { return }
			openInBBEdit(to: lineNumber)
		}
		else if document!.isDocumentEdited {
			// Prompt for user to confirm save
			let alert = NSAlert()
			alert.messageText = "Unsaved Changes"
			alert.informativeText = "Book \(book!.title) has unsaved changes."
			alert.addButton(withTitle: "Save")
			alert.addButton(withTitle: "Cancel")
			alert.beginSheetModal(for: self.view.window!) { response in
				if response == .alertFirstButtonReturn {
					DispatchQueue.main.async {
						self.document!.save(self)
						self.openInBBEdit(to: lineNumber)
					}
				}
			}
		}
		else {
			openInBBEdit(to: lineNumber)
		}
	}
	
	// https://www.objc.io/issues/14-mac/sandbox-scripting/
//	private var bbEditAppleEventDesc: NSAppleEventDescriptor {
//		let param1 = NSAppleEventDescriptor(string: <#T##String#>)
//	}
//	
//	private func openInBBEditAS(to lineNumber: Int) {
//		guard document != nil else {
//			return
//		}
//	}

	private func openInBBEdit(to lineNumber: Int) {
		guard document != nil else {
			return
		}
		// Using NSTask for now, would like to change to directly automating BBEdit
		let bbEdit = "/usr/local/bin/bbedit"
		assert(FileManager.default.fileExists(atPath: bbEdit))
		let bbEditURL = URL(fileURLWithPath: bbEdit)
		
		if let fileURL = document!.fileURL {
			var task: NSUserUnixTask
			do {
				task = try NSUserUnixTask(url: bbEditURL)
			} catch {
				print("Could not create URL for \(bbEdit)")
				return
			}
			
			var args = [String]()
			args.append(fileURL.path)
			args.append("+\(lineNumber)")
			let stdout = FileHandle.standardOutput
			task.standardOutput = stdout
			
			task.execute(withArguments: args) {error in
				if let error = error {
					DispatchQueue.main.async {
						print("Open with BBEdit failed: ", error)
					}
				}
			}
		}
	}
	
	private func exportToPDF() {
		// pandoc {source} --pdf-engine=xelatex -o {target}
		// or pipe in like cat {source} | pandoc --pdf-engine=xelatex -o {target}
	}

}

