//
//  Enums.swift
//  SwiftBookBuilder
//
//  Created by Simon Biickert on 2021-08-08.
//

import AppKit

public enum SBSError: Error {
	case invalidBookHeader
	case invalidSubChapterHeader
	case fileNotFound
	case cannotEncodeHeader
}

public enum Genre: String, Codable, CaseIterable {
    case biography = "Biography"
    case detective = "Detective"
    case dystopia = "Dystopia"
    case fantasy = "Fantasy"
    case horror = "Horror"
    case memoir = "Memoir"
    case mystery = "Mystery"
    case romance = "Romance"
    case satire = "Satire"
    case sf = "Science Fiction"
    case thriller = "Thriller"
    case western = "Western"
    case ya = "Young Adult"

}


enum EditStatus: String, Codable {
	case rough = "Rough"
	case inProgress = "In Progress"
	case good = "Good"
	case finished = "Finished"
	case multiple = "Multiple"
	
	var imageName: String {
		switch self {
			case .rough:
				return "clock"
			case .inProgress:
				return "arrow.right.circle.fill"
			case .good:
				return "face.smiling"
			case .finished:
				return "checkmark.seal.fill"
			case .multiple:
				return "paperclip"
		}
	}
	
	var tint: NSColor {
		switch self {
			case .rough:
			return NSColor.init(named: "StatusRough") ?? NSColor.magenta
			case .inProgress:
				return NSColor.init(named: "StatusInProgress") ?? NSColor.magenta
			case .good:
				return NSColor.init(named: "StatusGood") ?? NSColor.magenta
			case .finished:
				return NSColor.init(named: "StatusFinished") ?? NSColor.magenta
			case .multiple:
				return NSColor.init(named: "StatusMultiple") ?? NSColor.magenta
		}
	}
}
