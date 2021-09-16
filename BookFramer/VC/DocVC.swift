//
//  ViewController.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-23.
//

import Cocoa

class DocVC: NSSplitViewController {
    var book: Book? {
        return representedObject as? Book
    }

    var sidebar: SidebarVC? {
        for svi in self.splitViewItems {
            if let sbvc = svi.viewController as? SidebarVC {
                return sbvc
            }
        }
        return nil
    }
	
	var detail: DetailTabVC? {
		for svi in self.splitViewItems {
			if let dtvc = svi.viewController as? DetailTabVC {
				return dtvc
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

    override var representedObject: Any? {
        didSet {
            sidebar?.book = book
			detail?.book = book
			document?.notificationCenter.addObserver(self, selector: #selector(openExternal(notification:)), name: .openExternal, object: nil)
        }
    }
	
	// These are the default handlers for these menu selections
	// The detail VCs for Chapters, Chapter and SubChapter have more specific handlers
	@IBAction func addChapter(_ sender: AnyObject) {
		// Add a new chapter to the end of the book
		guard book != nil else { return }
		let ch = Chapter(title: "", subtitle: "", number: -1, subchapters: [SubChapter]())
		book?.add(chapter: ch)
		document?.notificationCenter.post(name: .changeContext, object: ch)
	}
	
	@IBAction func addScene(_ sender: AnyObject) {
		// Add a new subchapter to the end of the last chapter
		guard book != nil else { return }
		if var lastCh = book!.chapters.last {
			let sub = SubChapter(text: "")
			lastCh.subchapters.append(sub)
			book!.replace(chapter: lastCh)
			document?.notificationCenter.post(name: .changeContext, object: sub)
		}
	}
	
	@IBAction func addPersona(_ sender: AnyObject) {
		// Add a new persona
		guard book != nil else { return }
		let p = Persona(name: "", description: "", aliases: [])
		var major = book!.majorPersonas
		major.append(p)
		book!.majorPersonas = major
		document?.notificationCenter.post(name: .changeContext, object: major)
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

}

