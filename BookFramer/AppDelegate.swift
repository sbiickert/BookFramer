//
//  AppDelegate.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-23.
//

import Cocoa
import UniformTypeIdentifiers

@main
class AppDelegate: NSObject, NSApplicationDelegate {

	var preferencesController: NSWindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
		NotificationCenter.default.addObserver(self,
											   selector: #selector(openMarkdownFileAsNewDocument(notification:)),
											   name: .importMarkdown,
											   object: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
	
	@IBAction func showPreferences(_ sender: Any) {
		if preferencesController == nil {
			let storyboard = NSStoryboard(name: NSStoryboard.Name("Preferences"), bundle: nil)
			preferencesController = storyboard.instantiateInitialController() as? NSWindowController
		}
		if preferencesController != nil {
			preferencesController!.showWindow(sender)
		}
	}
	
	@IBAction func importMarkdown(_ sender: Any) {
		NotificationCenter.default.post(name: .importMarkdown, object: nil)
	}

	@objc func openMarkdownFileAsNewDocument(notification: Notification) {
		// Present open dialog
		let panel = NSOpenPanel()
		panel.canChooseFiles = true
		panel.canChooseDirectories = false
		panel.allowsMultipleSelection = false
		panel.allowedContentTypes = [.markdown]
		
		let clicked = panel.runModal()
		if clicked != NSApplication.ModalResponse.OK { return }
		
		if let fileURL = panel.url {
			// Parse markdown
			var book: Book?
			do {
				book = try Book.init(fromFile: fileURL)
			}
			catch {
				print(error)
				return
			}
		
			// Create new document
			do {
				if let book = book,
				   let newDoc = try NSDocumentController.shared.openUntitledDocumentAndDisplay(true) as? BookDocument {
					newDoc.book = book
				}
			}
			catch {
				print(error)
			}
			
		}
	}
}

extension UTType {
	static var markdown: UTType {
		return UTType(importedAs: "public.markdown")
	}
}
