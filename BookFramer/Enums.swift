//
//  Enums.swift
//  SwiftBookBuilder
//
//  Created by Simon Biickert on 2021-08-08.
//

import Foundation

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
