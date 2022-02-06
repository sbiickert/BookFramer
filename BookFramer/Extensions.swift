//
//  Extensions.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-23.
//

import AppKit

extension NSFont {
    func resized(to pointSize: CGFloat) -> NSFont? {
		if self.pointSize == pointSize {
			return self
		}
        return NSFont(descriptor: self.fontDescriptor, size: pointSize)
    }
	
	func bolded() -> NSFont? {
		let fDesc = self.fontDescriptor.withSymbolicTraits(.bold)
		return NSFont(descriptor: fDesc, size: self.pointSize)
	}
	
	func unbolded() -> NSFont? {
		var fDesc = self.fontDescriptor
		var st = fDesc.symbolicTraits
		st.remove(.bold)
		fDesc = fDesc.withSymbolicTraits(st)
		return NSFont(descriptor: fDesc, size: self.pointSize)
	}
}

extension NSNotification.Name {
	static let changeContext = Notification.Name("CHANGE CONTEXT")
    static let contextDidChange = Notification.Name("CONTEXT CHANGED")
	static let openExternal = Notification.Name("IT DOESN'T SUCK")
	static let search = Notification.Name("SEARCH")

	// Sent when any book content has been edited
	// Raised by DocEditor
	static let bookEdited = Notification.Name("BOOK EDITED")

	// Sent when user actions trigger edits
	// Raised by VCs
	static let modifyBookInfo = Notification.Name("MODIFY BOOK INFO")
	static let modifyChapters = Notification.Name("MODIFY CHAPTERS")
	
	static let addChapter = Notification.Name("ADD CHAPTER")
	static let modifyChapter = Notification.Name("MODIFY CHAPTER")
	static let deleteChapter = Notification.Name("DELETE CHAPTER")
	
	static let addSubChapter = Notification.Name("ADD SUBCHAPTER")
	static let modifySubChapter = Notification.Name("MODIFY SUBCHAPTER")
	static let deleteSubChapter = Notification.Name("DELETE SUBCHAPTER")
	
	static let addPersona = Notification.Name("ADD PERSONA")
	static let modifyPersona = Notification.Name("MODIFY PERSONA")
	static let deletePersona = Notification.Name("DELETE PERSONA")
}


extension CaseIterable where Self: Equatable {
    var index: Self.AllCases.Index? {
        return Self.allCases.firstIndex { self == $0 }
    }
}

extension NSPasteboard.PasteboardType {
    static let tableViewIndex = NSPasteboard.PasteboardType("ca.biickert.tableViewIndex")
}
