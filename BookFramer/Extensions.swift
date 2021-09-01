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
    static let selectedItemDidChange = Notification.Name("SELECTION CHANGED")
    static let genreDidChange = Notification.Name("GENRE CHANGED")
	static let bookEdited = Notification.Name("BOOK EDITED")
}


extension CaseIterable where Self: Equatable {
    var index: Self.AllCases.Index? {
        return Self.allCases.firstIndex { self == $0 }
    }
}
