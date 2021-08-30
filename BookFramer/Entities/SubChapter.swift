//
//  Scene.swift
//  SwiftBookBuilder
//
//  Created by Simon Biickert on 2021-08-02.
//

import AppKit

struct SubChapter: Equatable, Hashable {
	static func == (lhs: SubChapter, rhs: SubChapter) -> Bool {
		return lhs.headerInfo == rhs.headerInfo &&
			lhs.paragraphs == rhs.paragraphs
	}
	
	var headerInfo = SubChapterHeader()
	var startLineNumber = 0
	var paragraphs = [String]()
	
	/**
	Creates an empty subchapter with one paragraph
	
	- Parameter text: inserted into an initial paragraph
	*/
	init(text: String) {
		paragraphs.append(text)
	}
	
	/**
	Parses the JSON header for a sub-chapter
	
	Throws `SBSError.invalidSubChapterHeader`
	if the JSON format cannot be decoded
	
	*/
	init(withBlock header: BookBlock) throws {
		assert(header.type == .header)
		let jsonData = header.content.data(using: .utf8)!
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		do {
			let header = try decoder.decode(SubChapterHeader.self, from: jsonData)
			self.headerInfo = header
		}
		catch {
			throw SBSError.invalidSubChapterHeader
		}
	}
	
	/**
	Sums the word counts in all paragraphs
	
	- Returns: word count for the subchapter
	*/
	var wordCount: Int {
		var wc = 0
		for para in paragraphs {
			para.enumerateSubstrings(in: para.startIndex...,
									 options: .byWords) { _, range, _, _  in
				wc += 1
			}
		}
		return wc
	}
	
	/**
	Searches for a case-insensitive regex pattern in all paragraphs
	
	- Parameter pattern: the regex to search for
	
	- Returns: true if the pattern exists in the subchapter
	*/
	func search(for pattern: String) -> Bool {
		for para in paragraphs {
			if para.range(of: pattern, options: [.regularExpression, .caseInsensitive], range: nil, locale: nil) != nil {
				return true
			}
		}
		return false
	}
	
	/**
	Combines all SubChapters into a list of Markdown strings for printing.
	
	- Returns: array of paragraph markdown strings for printing
	*/
	func compile() -> [String] {
		var markdownStrings = [String]()
		
		markdownStrings.append(contentsOf: paragraphs)
		
		return markdownStrings
	}
}

struct SubChapterHeader: Codable, Equatable, Hashable {
	var description = ""
	var location = ""
	var pov = ""
	var status = EditStatus.rough
	var analyticInfo = Dictionary<String, Double>()
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
				return "clock.fill"
			case .inProgress:
				return "arrow.right.circle.fill"
			case .good:
				return "face.smiling.fill"
			case .finished:
				return "checkmark.circle.fill"
			case .multiple:
				return "paperclip"
		}
	}
	
	var tint: NSColor {
		switch self {
			case .rough:
				return NSColor.black
			case .inProgress:
				return NSColor.orange
			case .good:
				return NSColor.blue
			case .finished:
				return NSColor.green
			case .multiple:
				return NSColor.gray
		}
	}
}
