//
//  ViewController.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-23.
//

import Cocoa

class DocVC: NSTabViewController, BFContextProvider {
	var editor: DocEditor
	
	enum TabIndex: Int {
		case manage = 0
		case preview = 1
	}

	
	required init?(coder: NSCoder) {
		editor = DocEditor()
		super.init(coder: coder)
	}
	
	var book: Book? {
		return representedObject as? Book
	}
	
	var selectedPart: Any? {
		if selectedSubChapter != nil {
			return selectedSubChapter
		}
		if selectedChapter != nil {
			return selectedChapter
		}
		return book
	}
	
	private var _selectedChapterID: String?
	var selectedChapter: Chapter? {
		if let id = _selectedChapterID,
		   let book = book {
			return book.chapters.first(where: {$0.id == id})
		}
		return nil
	}
	
	private var _selectedSubChapterID: String?
	var selectedSubChapter: SubChapter? {
		if let id = _selectedSubChapterID,
		   let book = book {
			return book.findSubChapter(id: id)
		}
		return nil
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
	
	public var document: BookDocument? {
		return self.view.window?.windowController?.document as? BookDocument
	}

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
	
	override func viewDidAppear() {
		super.viewDidAppear()
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
			editor.registerDocumentVC(vc: self)
			if selectedChapter == nil && selectedSubChapter == nil {
				self.changeContext(notification: Notification(name: .changeContext, object: book, userInfo: nil))
			}
			else if selectedSubChapter != nil {
				self.changeContext(notification: Notification(name: .changeContext, object: selectedSubChapter, userInfo: nil))
			}
			else {
				self.changeContext(notification: Notification(name: .changeContext, object: selectedChapter, userInfo: nil))
			}

			if _observersAdded == false {
				_observersAdded = true
				document?.notificationCenter.addObserver(self, selector: #selector(changeContext(notification:)), name: .changeContext, object: nil)
				document?.notificationCenter.addObserver(self, selector: #selector(bookEdited(notification:)), name: .bookEdited, object: nil)
				document?.notificationCenter.addObserver(self, selector: #selector(openExternal(notification:)), name: .openExternal, object: nil)
				document?.notificationCenter.addObserver(self, selector: #selector(exportToPDF(notification:)), name: .exportPDF, object: nil)
			}
			document?.notificationCenter.post(name: .bookEdited, object: nil)
        }
    }
	
	@objc func changeContext(notification: Notification) {
		if let ch = notification.object as? Chapter {
			_selectedChapterID = ch.id
			_selectedSubChapterID = nil
		}
		else if let sub = notification.object as? SubChapter {
			_selectedSubChapterID = sub.id
			if let book = book,
			   let ch = book.chapterContaining(subchapter: sub) {
				_selectedChapterID = ch.id
			}
		}
		else if let _ = notification.object as? Book {
			_selectedChapterID = nil
			_selectedSubChapterID = nil
		}
		document?.notificationCenter.post(name: .contextDidChange, object: notification.object)
	}
	
	@objc func bookEdited(notification: Notification) {
		// Send a context changed event if the selected chapter or subchapter was deleted
		if (_selectedChapterID != nil && selectedChapter == nil) ||
			(_selectedSubChapterID != nil && selectedSubChapter == nil) {
			document?.notificationCenter.post(name: .contextDidChange, object: nil)
		}
	}

	private func handleDocReload(old: Book, new: Book) {
		if let currentSelectedChapter = selectedChapter {
			_selectedChapterID = nil // if we don't find it
			// Find the old Chapter in the new Book
			for ch in new.chapters {
				if ch.roughlyEqual(to: currentSelectedChapter) {
					_selectedChapterID = ch.id
					break
				}
			}
		}
		
		if let currentSelectedSubChapter = selectedSubChapter {
			_selectedSubChapterID = nil // if we don't find it
			// Find the old SubChapter in the new Book
			for ch in new.chapters {
				for sub in ch.subchapters {
					if sub.roughlyEqual(to: currentSelectedSubChapter) {
						_selectedSubChapterID = sub.id
						break
					}
				}
			}
		}
	}

	// MARK: Menu Handlers
	// Default handler for these menu selections pass nil
	// The detail VCs for Chapters, Chapter and SubChapter will pass a Chapter or SubChapter to indicate context
	@IBAction func newChapterMenuHandler(_ sender: AnyObject) {
		// Add a new chapter to the end of the book
		document?.notificationCenter.post(name: .addChapter, object: nil)
	}
	
	@IBAction func newSceneMenuHandler(_ sender: AnyObject) {
		// Add a new subchapter to the end of the last chapter
		document?.notificationCenter.post(name: .addSubChapter, object: nil)
	}

	@IBAction func newPersonaMenuHandler(_ sender: AnyObject) {
		// Add a new persona
		document?.notificationCenter.post(name: .addPersona, object: nil)
	}
	
	@IBAction func openInBBEditMenuHandler(_ sender: Any) {
		document?.notificationCenter.post(name: .openExternal, object: nil)
	}
	
	@IBAction func showManageViewMenuHandler(_ sender: Any) {
		tabView.selectTabViewItem(at: DocVC.TabIndex.manage.rawValue)
	}
	
	@IBAction func showPreviewMenuHandler(_ sender: Any) {
		tabView.selectTabViewItem(at: DocVC.TabIndex.preview.rawValue)
	}

	// MARK: Search field
	@objc func searchFieldAction(sender: AnyObject) {
		guard let searchField = sender as? NSSearchField else { return }
		
		document?.notificationCenter.post(name: .search, object: searchField.stringValue)
	}

	// MARK: Opening the file in BBEdit
	
	@objc func openExternal(notification: NSNotification) {
		guard document != nil && undoManager != nil else {
			return
		}
		
		var lineNumber = 1
		
		if let sub = selectedSubChapter {
			lineNumber = book?.lineNumberFor(subchapter: sub) ?? 1
		}
		else if let ch = selectedChapter {
			lineNumber = book?.lineNumberFor(chapter: ch) ?? 1
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
		let bbEdit = UserDefaults.standard.string(forKey: PrefsVC.DefaultNames.bbedit) ?? ""
		if FileManager.default.fileExists(atPath: bbEdit) == false {
			let alert = NSAlert()
			alert.messageText = "Path to BBEdit not set"
			alert.informativeText = "Open the Preferences dialog and input the path to the BBEdit command line tool."
			alert.runModal()
			return
		}
		let bbEditURL = URL(fileURLWithPath: bbEdit)
		
		if let fileURL = document!.fileURL {
			var task: NSUserUnixTask
			do {
				task = try NSUserUnixTask(url: bbEditURL)
			} catch {
				print("Could not create task from URL for \(bbEdit)")
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
	
	@objc func exportToPDF(notification: Notification) {
		// pandoc {source} --pdf-engine=xelatex -o {target}
		// or pipe in like cat {source} | pandoc --pdf-engine=xelatex -o {target}
		guard document != nil else { return }
		guard book != nil else { return }

		let pandoc = UserDefaults.standard.string(forKey: PrefsVC.DefaultNames.pandoc) ?? ""
		if FileManager.default.fileExists(atPath: pandoc) == false {
			let alert = NSAlert()
			alert.messageText = "Path to pandoc not set"
			alert.informativeText = "Open the Preferences dialog and input the path to the pandoc command line tool."
			alert.runModal()
			return
		}

		let pdflatex = UserDefaults.standard.string(forKey: PrefsVC.DefaultNames.pdflatex) ?? ""
		if FileManager.default.fileExists(atPath: pdflatex) == false {
			let alert = NSAlert()
			alert.messageText = "Path to pdflatex not set"
			alert.informativeText = "Open the Preferences dialog and input the path to the pdflatex command line tool."
			alert.runModal()
			return
		}
		
		let pandocURL = URL(fileURLWithPath: pandoc)
		
		// Compile the file to markdown in a temp dir
		let compiledMD = book!.compile()
		var tempFile: URL?
		do {
			let tempFolder = URL(fileURLWithPath: NSTemporaryDirectory(),
								 isDirectory: true)
			tempFile = tempFolder.appendingPathComponent("temp.md")
			try compiledMD.write(to: tempFile!, atomically: true, encoding: .utf8)
		}
		catch {
			tempFile = nil
			print(error)
		}
		
		if let fileURL = tempFile {
			var task: NSUserUnixTask
			do {
				task = try NSUserUnixTask(url: pandocURL)
			} catch {
				print("Could not create task from URL for \(pandoc)")
				return
			}
			
			let panel = NSSavePanel()
			panel.allowedFileTypes = ["pdf"]
			
			let clicked = panel.runModal()
			if clicked != NSApplication.ModalResponse.OK { return }
			
			if let outputURL = panel.url {
				let outputFile = outputURL.path
				var args = [String]()
				args.append("-o\(outputFile)")
				args.append("--pdf-engine=\(pdflatex)")
				args.append(fileURL.path)
				let stdout = FileHandle.standardOutput
				task.standardOutput = stdout
				print(args)
				
				task.execute(withArguments: args) {error in
					if let error = error {
						print("Pandoc export to PDF failed: ", error)
					}
				}
			}
		}
	}

}

