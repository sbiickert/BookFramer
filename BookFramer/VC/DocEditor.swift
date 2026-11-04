//
//  DocEditingDelegate.swift
//  BookFramer
//
//  Created by Simon Biickert on 2022-02-02.
//

import AppKit

/// What DocEditor needs from the document's view controller. Lets DocEditor be tested without a window.
protocol DocEditorHost: AnyObject, BFContextProvider {
	var undoManager: UndoManager? { get }
	var notificationCenter: NotificationCenter? { get }
}

class DocEditor {
	/// Weak, because the host (ManageVC) owns this editor
	private weak var host: DocEditorHost?
	private var _observersAdded = false

	init() {
	}

	func register(host: DocEditorHost) {
		self.host = host
		addObservers()
	}

	private func addObservers() {
		guard _observersAdded == false else {return}

		if let nc = notificationCenter {
			nc.addObserver(self, selector: #selector(modifyBookInfo(notification:)),
						   name: .modifyBookInfo, object: nil)

			nc.addObserver(self, selector: #selector(modifyChapters(notification:)),
						   name: .modifyChapters, object: nil)

			nc.addObserver(self, selector: #selector(addChapter(notification:)),
						   name: .addChapter, object: nil)
			nc.addObserver(self, selector: #selector(modifyChapter(notification:)),
						   name: .modifyChapter, object: nil)
			nc.addObserver(self, selector: #selector(deleteChapter(notification:)),
						   name: .deleteChapter, object: nil)

			nc.addObserver(self, selector: #selector(addSubChapter(notification:)),
						   name: .addSubChapter, object: nil)
			nc.addObserver(self, selector: #selector(modifySubChapter(notification:)),
						   name: .modifySubChapter, object: nil)
			nc.addObserver(self, selector: #selector(deleteSubChapter(notification:)),
						   name: .deleteSubChapter, object: nil)

			nc.addObserver(self, selector: #selector(addPersona(notification:)),
						   name: .addPersona, object: nil)
			nc.addObserver(self, selector: #selector(modifyPersona(notification:)),
						   name: .modifyPersona, object: nil)
			nc.addObserver(self, selector: #selector(deletePersona(notification:)),
						   name: .deletePersona, object: nil)

			_observersAdded = true
		}
	}

	var notificationCenter: NotificationCenter? {
		return host?.notificationCenter
	}

	var undoManager: UndoManager? {
		return host?.undoManager
	}

	private var book: Book? {
		return host?.book
	}

	// MARK: Book Editing

	public struct BookInfo: Equatable {
		let title: String
		let subtitle: String
		let header: BookHeader
	}

	@objc func modifyBookInfo(notification: Notification) {
		if let info = notification.object as? BookInfo {
			setBookInfo(info)
		}
	}

	private func setBookInfo(_ newValue: BookInfo) {
		if let book = book {
			let oldValue = BookInfo(title: book.title,
								   subtitle: book.subtitle,
								   header: book.headerInfo)
			undoManager?.registerUndo(withTarget: self) {
				$0.setBookInfo(oldValue)
			}
			book.title = newValue.title
			book.subtitle = newValue.subtitle
			book.headerInfo = newValue.header
			notificationCenter?.post(name: .bookEdited, object: book)
		}
	}

	// MARK: Chapter and SubChapter Editing
	// Every chapter and subchapter edit computes the complete new list of chapters and applies it
	// with setChapters, so undo always restores exactly what was there before, and redo works.

	@objc func modifyChapters(notification: Notification) {
		if let chapters = notification.object as? [Chapter] {
			setChapters(chapters, selecting: chapters)
		}
	}

	/**
	Replaces all chapters in the book, registering the reverse change for undo (and therefore redo).

	- Parameter newValue: the chapters to apply. They are renumbered.
	- Parameter selecting: posted with `.bookEdited`. VCs select it if it is a Chapter or SubChapter.
	*/
	private func setChapters(_ newValue: [Chapter], selecting: Any?) {
		guard let book = book else { return }
		let oldValue = book.chapters
		undoManager?.registerUndo(withTarget: self) {
			$0.setChapters(oldValue, selecting: selecting)
		}
		var chapters = newValue
		for i in chapters.indices {
			chapters[i].number = i + 1
		}
		book.chapters = chapters
		notificationCenter?.post(name: .bookEdited, object: selecting)
	}

	@objc func addChapter(notification: Notification) {
		guard let book = book else { return }

		// Add the new chapter after the chapter given in the notification or currently selected
		var relativeCh: Chapter?
		if let ch = notification.object as? Chapter {
			relativeCh = ch
		}
		else if let sub = notification.object as? SubChapter {
			relativeCh = book.chapterContaining(subchapter: sub)
		}
		else if let sub = host?.selectedSubChapter {
			relativeCh = book.chapterContaining(subchapter: sub)
		}
		else {
			relativeCh = host?.selectedChapter
		}

		var insertIndex = book.chapters.count // default: at the end
		if let relativeCh = relativeCh,
		   let relativeIndex = book.indexOf(chapter: relativeCh) {
			insertIndex = relativeIndex + 1
		}

		let ch = Chapter(title: "", subtitle: "", number: -1, subchapters: [SubChapter]())
		var chapters = book.chapters
		chapters.insert(ch, at: insertIndex)
		setChapters(chapters, selecting: ch)
	}

	@objc func modifyChapter(notification: Notification) {
		guard let book = book,
			  let newValue = notification.object as? Chapter,
			  let index = book.indexOf(chapter: newValue) else { return }
		var chapters = book.chapters
		chapters[index] = newValue
		setChapters(chapters, selecting: newValue)
	}

	@objc func deleteChapter(notification: Notification) {
		guard let book = book,
			  let ch = notification.object as? Chapter,
			  let index = book.indexOf(chapter: ch) else { return }
		var chapters = book.chapters
		chapters.remove(at: index)
		setChapters(chapters, selecting: chapters)
	}

	@objc func addSubChapter(notification: Notification) {
		guard let book = book else { return }

		// Add to the chapter given in the notification or currently selected, else the last chapter
		var targetChapter = book.chapters.last
		if let sub = notification.object as? SubChapter {
			targetChapter = book.chapterContaining(subchapter: sub)
		}
		else if let ch = notification.object as? Chapter {
			targetChapter = ch
		}
		else if let ch = host?.selectedChapter {
			targetChapter = ch
		}
		guard let target = targetChapter,
			  let chIndex = book.indexOf(chapter: target) else { return }

		let sub = SubChapter(text: "")
		var chapters = book.chapters
		chapters[chIndex].subchapters.append(sub)
		setChapters(chapters, selecting: sub)
	}

	@objc func modifySubChapter(notification: Notification) {
		guard let book = book,
			  let newValue = notification.object as? SubChapter,
			  let chIndex = book.chapters.firstIndex(where: { $0.indexOf(subchapter: newValue) != nil }),
			  let subIndex = book.chapters[chIndex].indexOf(subchapter: newValue) else { return }
		var chapters = book.chapters
		chapters[chIndex].subchapters[subIndex] = newValue
		setChapters(chapters, selecting: newValue)
	}

	@objc func deleteSubChapter(notification: Notification) {
		guard let book = book,
			  let sub = notification.object as? SubChapter,
			  let chIndex = book.chapters.firstIndex(where: { $0.indexOf(subchapter: sub) != nil }),
			  let subIndex = book.chapters[chIndex].indexOf(subchapter: sub) else { return }
		var chapters = book.chapters
		chapters[chIndex].subchapters.remove(at: subIndex)
		setChapters(chapters, selecting: chapters[chIndex])
	}

	// MARK: Persona Editing

	static let newPersonaName = "New Character"
	@objc func addPersona(notification: Notification) {
		guard let book = book else { return }
		let p = Persona(name: DocEditor.newPersonaName, description: "", aliases: [])
		var major = book.majorPersonas
		let minor = book.minorPersonas
		major.append(p)
		setPersonas(major: major, minor: minor)
	}

	public struct PersonaInfo {
		let persona: Persona
		let isMajor: Bool
	}
	@objc func modifyPersona(notification: Notification) {
		guard let book = book else { return }
		if let pInfo = notification.object as? PersonaInfo {
			var major = book.majorPersonas
			var minor = book.minorPersonas

			let wasMajor = book.isMajor(persona: pInfo.persona)
			if wasMajor {
				if let idx = major.firstIndex(where: {$0.id == pInfo.persona.id}) {
					major.remove(at: idx)
					if pInfo.isMajor {
						major.insert(pInfo.persona, at: idx)
					}
					else {
						minor.append(pInfo.persona)
					}
				}
			}
			else {
				if let idx = minor.firstIndex(where: {$0.id == pInfo.persona.id}) {
					minor.remove(at: idx)
					if pInfo.isMajor {
						major.append(pInfo.persona)
					}
					else {
						minor.insert(pInfo.persona, at: idx)
					}
				}
			}
			setPersonas(major: major, minor: minor)
		}
	}

	@objc func deletePersona(notification: Notification) {
		guard let book = book else { return }
		if let p = notification.object as? Persona {
			let alert = NSAlert()
			alert.addButton(withTitle: "OK")
			alert.addButton(withTitle: "Cancel")
			alert.alertStyle = .warning
			alert.messageText = "Delete character '\(p.name)'?"
			let result = alert.runModal()
			if result != .alertFirstButtonReturn { return }

			// Using filter to remove the persona. Simple!
			let major = book.majorPersonas.filter({$0.id != p.id})
			let minor = book.minorPersonas.filter({$0.id != p.id})
			setPersonas(major: major, minor: minor)
		}
	}

	private func setPersonas(major: [Persona], minor: [Persona]) {
		guard let book = book else { return }
		let oldMajor = book.majorPersonas
		let oldMinor = book.minorPersonas
		undoManager?.registerUndo(withTarget: self) {
			$0.setPersonas(major: oldMajor, minor: oldMinor)
		}
		book.majorPersonas = major
		book.minorPersonas = minor
		notificationCenter?.post(name: .bookEdited, object: [major])
	}
}
