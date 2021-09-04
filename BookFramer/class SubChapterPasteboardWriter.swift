//
//  class SubChapterPasteboardWriter.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-09-03.
//

import Cocoa

class SubChapterPasteboardWriter: NSObject, NSPasteboardWriting {
    var id: String
    var index: Int
    
    init(id: String, at index: Int) {
        self.id = id
        self.index = index
    }
    
    func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        return [.string, .tableViewIndex]
    }
    
    func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        switch type {
        case .string:
            return id
        case .tableViewIndex:
            return NSNumber(integerLiteral: index)
        default:
            return nil
        }
    }
}
