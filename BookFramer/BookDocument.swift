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
	
	nonisolated override class var autosavesInPlace: Bool {
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
	
	nonisolated override var isEntireFileLoaded: Bool {
		return true
	}
	
	nonisolated override func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {
		guard let data = fileWrapper.regularFileContents,
			  let string = String(data: data, encoding: .utf8) else {
			throw CocoaError(.fileReadCorruptFile)
		}
		let parsed = try Book(fromBFD: string)
		// NSDocument reads on the main thread unless canConcurrentlyReadDocuments(ofType:)
		// returns true, which this class doesn't override. Swift traps here if that ever changes.
		MainActor.assumeIsolated {
			book = parsed
		}
	}
	
	override func fileWrapper(ofType typeName: String) throws -> FileWrapper {
		let text = try book.toMarkdown()
		let data = text.data(using: .utf8)!
		return .init(regularFileWithContents: data)
	}
	
	// MARK: Monitoring for external changes
	
	/// Called on NSDocument's file presenter queue, not the main thread, so it only hands off to the main actor
	nonisolated override func presentedItemDidChange() {
		Task { @MainActor in
			self.handleExternalChange()
		}
	}

	private func handleExternalChange() {
		guard fileContentsDidChange else {
			return
		}
		if isDocumentEdited {
			// Let the user know it happened
			let alert = NSAlert()
			alert.messageText = "File Changed"
			alert.informativeText = "Book \(book.title) was edited outside BookFramer."
			alert.addButton(withTitle: "Reload")
			alert.addButton(withTitle: "Ignore")
			guard let window = windowForSheet else { return }
			alert.beginSheetModal(for: window) { response in
				if response == .alertFirstButtonReturn {
					self.reloadFromFile()
				}
			}
		}
		else {
			reloadFromFile()
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

