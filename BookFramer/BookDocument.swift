//
//  Document.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-23.
//

import Cocoa

class BookDocument: NSDocument {
	weak var contentViewController: ManageVC?
	let notificationCenter = NotificationCenter()
	
	var book: Book {
		didSet {

			if let contentVC = contentViewController {
				contentVC.representedObject = book
			}
			
			// TODO: set window title. This is wrong.
			Swift.print("Set document book to \(book)")
		}
	}
	
	override init() {
		book = Book(text: "Hello, world!")
		super.init()
	}
	
	override class var autosavesInPlace: Bool {
		return false
	}
	
	override func makeWindowControllers() {
		// Returns the Storyboard that contains your Document window.
		let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
		let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
		self.addWindowController(windowController)
		
		// Set the view controller's represented object as your document.
		if let contentVC = windowController.contentViewController as? ManageVC {
			contentVC.representedObject = book
			contentViewController = contentVC
		}
	}
	
	override var isEntireFileLoaded: Bool {
		return true
	}
	
	override func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {
		guard let data = fileWrapper.regularFileContents,
			  let string = String(data: data, encoding: .utf8) else {
			throw CocoaError(.fileReadCorruptFile)
		}
		book = try Book(fromBFD: string)
	}
	
	override func fileWrapper(ofType typeName: String) throws -> FileWrapper {
		let text = try book.toMarkdown()
		let data = text.data(using: .utf8)!
		return .init(regularFileWithContents: data)
	}
	
	// MARK: Monitoring for external changes
	
	override func presentedItemDidChange() {
		guard fileContentsDidChange else {
			return
		}
		if isDocumentEdited {
			// Let the user know it happened. Would like to
			DispatchQueue.main.async {
				let alert = NSAlert()
				alert.messageText = "File Changed"
				alert.informativeText = "Book \(self.book.title) was edited outside BookFramer."
				alert.addButton(withTitle: "Reload")
				alert.addButton(withTitle: "Ignore")
				alert.beginSheetModal(for: self.windowForSheet!) { response in
					if response == .alertFirstButtonReturn {
						self.reloadFromFile()
					}
				}
			}
		}
		else {
			DispatchQueue.main.async {
				self.reloadFromFile()
			}
			return
		}

	}

	private func reloadFromFile() {
		guard fileURL != nil else { return }
		do {
			book = try Book(fromFile: fileURL!)
		}
		catch {return}
	}

	private var fileContentsDidChange: Bool {
		if let fmd = fileModificationDateOnDisk() {
			return fmd > book.readAtTime
		}
		return false
	}

	private func fileModificationDateOnDisk() -> Date? {
		guard let fileURL = self.fileURL else { return nil }

		let fm = FileManager.default
		do {
			let attributes = try fm.attributesOfItem(atPath: fileURL.path)
			let modificationDate = attributes[FileAttributeKey.modificationDate] as? Date
			return modificationDate
		}
		catch {
			return nil
		}
	}
}

