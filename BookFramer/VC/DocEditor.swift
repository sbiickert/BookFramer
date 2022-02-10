//
//  DocEditingDelegate.swift
//  BookFramer
//
//  Created by Simon Biickert on 2022-02-02.
//

import Foundation

class DocEditor {
	private var docVC: DocVC!
	private var _observersAdded = false
	
	init() {
	}
	
	func registerDocumentVC(vc: DocVC) {
		self.docVC = vc
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
		return docVC.document?.notificationCenter
	}
	
	var undoManager: UndoManager? {
		return docVC.undoManager
	}

	// MARK: Book Editing
	
	public struct BookInfo {
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
		if docVC.book != nil {
			let oldValue = BookInfo(title: docVC.book!.title,
								   subtitle: docVC.book!.subtitle,
								   header: docVC.book!.headerInfo)
			undoManager?.registerUndo(withTarget: self) {
				$0.setBookInfo(oldValue)
			}
			docVC.book!.title = newValue.title
			docVC.book!.subtitle = newValue.subtitle
			docVC.book!.headerInfo = newValue.header
			notificationCenter?.post(name: .bookEdited, object: docVC.book!)
		}
	}
	
	// MARK: Bulk Chapter Edits

	@objc func modifyChapters(notification: Notification) {
		if let chapters = notification.object as? [Chapter] {
			setChapters(chapters)
		}
	}
	
	private func setChapters(_ newValue: [Chapter]) {
		if docVC.book != nil {
			let oldValue = docVC.book!.chapters
			undoManager?.registerUndo(withTarget: self) {
				$0.setChapters(oldValue)
				self.notificationCenter?.post(name: .bookEdited, object: newValue)
			}
			docVC.book!.chapters = newValue
			notificationCenter?.post(name: .bookEdited, object: newValue)
		}
	}
	
	// MARK: Chapter Editing
	
	@objc func addChapter(notification: Notification) {
		guard docVC.book != nil else { return }
		
		var insertIndex = docVC.book!.chapters.count // default
		
		if let relativeCh = notification.object as? Chapter {
			// Add new chapter after relativeCh
			if let relativeIndex = docVC.book!.chapters.firstIndex(where: { $0.id == relativeCh.id} ) {
				insertIndex = relativeIndex + 1
			}
		}
		else if let relativeSub = notification.object as? SubChapter,
				let relativeCh = docVC.book!.chapterContaining(subchapter: relativeSub) {
			// Add new chapter after relativeCh
			if let relativeIndex = docVC.book!.chapters.firstIndex(where: { $0.id == relativeCh.id} ) {
				insertIndex = relativeIndex + 1
			}
		}
		else if let relativeSub = docVC.selectedSubChapter ,
				let relativeCh = docVC.book!.chapterContaining(subchapter: relativeSub) {
			// Add new chapter after relativeCh
			if let relativeIndex = docVC.book!.chapters.firstIndex(where: { $0.id == relativeCh.id} ) {
				insertIndex = relativeIndex + 1
			}
		}
		else if let relativeCh = docVC.selectedChapter {
			// Add new chapter after relativeCh
			if let relativeIndex = docVC.book!.chapters.firstIndex(where: { $0.id == relativeCh.id} ) {
				insertIndex = relativeIndex + 1
			}
		}
		
		let ch = Chapter(title: "", subtitle: "", number: -1, subchapters: [SubChapter]())
		// For undo
		let oldChapters = docVC.book!.chapters
		docVC.book!.add(chapter: ch, at: insertIndex)
		let newChapters = docVC.book!.chapters
		docVC.book!.chapters = oldChapters
		undoManager?.registerUndo(withTarget: docVC.book!) {
			$0.chapters = oldChapters
			self.notificationCenter?.post(name: .bookEdited, object: [oldChapters])
		}
		docVC.book!.chapters = newChapters
		notificationCenter?.post(name: .bookEdited, object: ch)
	}
	
	@objc func modifyChapter(notification: Notification) {
		if let newValue = notification.object as? Chapter,
		   let oldValue = docVC.selectedChapter {
			undoManager?.registerUndo(withTarget: docVC.book!) {
				$0.replace(chapter: oldValue)
				self.notificationCenter?.post(name: .bookEdited, object: oldValue)
			}
			docVC.book!.replace(chapter: newValue)
			notificationCenter?.post(name: .bookEdited, object: newValue)
		}
	}
	
	@objc func deleteChapter(notification: Notification) {
		guard docVC.book != nil && notification.object != nil else {return}
		if let ch = notification.object as? Chapter {
			if let index = docVC.book!.indexOf(chapter: ch) {
				undoManager?.registerUndo(withTarget: docVC.book!) {
					$0.add(chapter: ch, at: index)
					self.notificationCenter?.post(name: .bookEdited, object: self.docVC.book!)
				}
				docVC.book!.removeChapter(at: index)
				notificationCenter?.post(name: .bookEdited, object: docVC.book!.chapters)
			}
		}
	}
	
	// MARK: SubChapter Editing

	@objc func addSubChapter(notification: Notification) {
		guard docVC.book != nil else { return }
		
		var targetChapter = docVC.book!.chapters.last
		if let sub = notification.object as? SubChapter {
			targetChapter = docVC.book!.chapterContaining(subchapter: sub)
		}
		else if let ch = notification.object as? Chapter {
			targetChapter = ch
		}
		else if let ch = docVC.selectedChapter {
			targetChapter = ch
		}
		guard targetChapter != nil else {return}
		
		let sub = SubChapter(text: "")
		targetChapter!.subchapters.append(sub)
		// For undo
		let oldChapters = docVC.book!.chapters
		docVC.book!.replace(chapter: targetChapter!)
		let newChapters = docVC.book!.chapters
		docVC.book!.chapters = oldChapters
		undoManager?.registerUndo(withTarget: docVC.book!) {
			$0.chapters = oldChapters
			self.notificationCenter?.post(name: .bookEdited, object: targetChapter!)
		}
		docVC.book!.chapters = newChapters
		notificationCenter?.post(name: .bookEdited, object: sub)
	}
	
	@objc func modifySubChapter(notification: Notification) {
		if let newValue = notification.object as? SubChapter,
		   let oldValue = docVC.selectedSubChapter {
			undoManager?.registerUndo(withTarget: docVC.book!) {
				$0.replace(subChapter: oldValue)
				self.notificationCenter?.post(name: .bookEdited, object: oldValue)
			}
			docVC.book!.replace(subChapter: newValue)
			notificationCenter?.post(name: .bookEdited, object: newValue)
		}
	}
	
	@objc func deleteSubChapter(notification: Notification) {
		guard docVC.book != nil && notification.object != nil else {return}
		if let sub = notification.object as? SubChapter,
		   let origCh = docVC.book!.chapterContaining(subchapter: sub),
		   var modCh = docVC.book!.chapterContaining(subchapter: sub),
		   let index = modCh.subchapters.firstIndex(where: {$0.id == sub.id}) {
			modCh.subchapters.remove(at: index)
			undoManager?.registerUndo(withTarget: docVC.book!) {
				$0.replace(chapter: origCh)
				self.notificationCenter?.post(name: .bookEdited, object: origCh)
			}
			docVC.book!.replace(chapter: modCh)
			notificationCenter?.post(name: .bookEdited, object: modCh)
		}
	}
	
	// MARK: Persona Editing
	
	static let newPersonaName = "New Character"
	@objc func addPersona(notification: Notification) {
		guard docVC.book != nil else { return }
		let p = Persona(name: DocEditor.newPersonaName, description: "", aliases: [])
		var major = docVC.book!.majorPersonas
		let minor = docVC.book!.minorPersonas
		major.append(p)
		setPersonas(major: major, minor: minor)
	}
	
	public struct PersonaInfo {
		let persona: Persona
		let isMajor: Bool
	}
	@objc func modifyPersona(notification: Notification) {
		guard docVC.book != nil else { return }
		if let pInfo = notification.object as? PersonaInfo {
			var major = docVC.book!.majorPersonas
			var minor = docVC.book!.minorPersonas
			
			let wasMajor = docVC.book!.isMajor(persona: pInfo.persona)
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
		guard docVC.book != nil else { return }
		if let p = notification.object as? Persona {
			// Using filter to remove the persona. Simple!
			let major = docVC.book!.majorPersonas.filter({$0.id != p.id})
			let minor = docVC.book!.minorPersonas.filter({$0.id != p.id})
			setPersonas(major: major, minor: minor)
		}
	}
	
	private func setPersonas(major: [Persona], minor: [Persona]) {
		let oldMajor = docVC.book!.majorPersonas
		let oldMinor = docVC.book!.minorPersonas
		undoManager?.beginUndoGrouping()
		undoManager?.registerUndo(withTarget: self) {
			$0.setPersonas(major: oldMajor, minor: oldMinor)
			self.docVC.document?.notificationCenter.post(name: .bookEdited, object: [oldMajor])
		}
		docVC.book!.majorPersonas = major
		docVC.book!.minorPersonas = minor
		undoManager?.endUndoGrouping()
		self.docVC.document?.notificationCenter.post(name: .bookEdited, object: [major])
	}
}
