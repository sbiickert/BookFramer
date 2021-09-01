//
//  Document.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-23.
//

import Cocoa

class Document: NSDocument {
    weak var contentViewController: DocVC?
	let notificationCenter = NotificationCenter()
	
    var book: Book {
        didSet {
            // TODO: set window title. This is wrong.
        }
    }

    override init() {
        book = Book(text: "Hello, world!")
        super.init()
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
        self.addWindowController(windowController)
        
        // Set the view controller's represented object as your document.
        if let contentVC = windowController.contentViewController as? DocVC {
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
        book = try Book(fromMarkdown: string)
    }
    
    override func fileWrapper(ofType typeName: String) throws -> FileWrapper {
        let text = try book.toMarkdown()
        let data = text.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
}

