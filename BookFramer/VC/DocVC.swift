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
	
	@objc func openExternal(notification: NSNotification) {
		guard undoManager != nil else {
			return
		}
		
		// If there are unsaved changes, save them
		if undoManager!.canUndo {
			// TODO: prompt for user to confirm save
			document!.save(self)
		}
		
		var lineNumber = 1
		
		if let ch = notification.object as? Chapter {
			lineNumber = book?.lineNumberFor(chapter: ch) ?? 1
		}
		else if let sub = notification.object as? SubChapter {
			lineNumber = book?.lineNumberFor(subchapter: sub) ?? 1
		}
		
		openInBBEdit(to: lineNumber)
		
	}

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
					print("Open with BBEdit failed: ", error)
				}
			}
		}
	}

}

