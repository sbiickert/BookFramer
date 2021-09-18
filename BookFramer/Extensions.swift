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
    static let contextDidChange = Notification.Name("CONTEXT CHANGED")
	static let changeContext = Notification.Name("CHANGE CONTEXT")
	static let bookEdited = Notification.Name("BOOK EDITED")
	static let openExternal = Notification.Name("IT DOESN'T SUCK")
	static let addChapter = Notification.Name("ADD CHAPTER")
	static let addSubChapter = Notification.Name("ADD SUBCHAPTER")
	static let deleteChapter = Notification.Name("DELETE CHAPTER")
	static let deleteSubChapter = Notification.Name("DELETE SUBCHAPTER")
}


extension CaseIterable where Self: Equatable {
    var index: Self.AllCases.Index? {
        return Self.allCases.firstIndex { self == $0 }
    }
}

extension NSPasteboard.PasteboardType {
    static let tableViewIndex = NSPasteboard.PasteboardType("ca.biickert.tableViewIndex")
}
