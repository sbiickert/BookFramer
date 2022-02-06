//
//  Scene.swift
//  SwiftBookBuilder
//
//  Created by Simon Biickert on 2021-08-02.
//

import AppKit

struct SubChapter: Equatable, Hashable, IDable {
	static func == (lhs: SubChapter, rhs: SubChapter) -> Bool {
		return lhs.headerInfo == rhs.headerInfo &&
			lhs.paragraphs == rhs.paragraphs
	}
//	static func == (lhs: SubChapter, rhs: SubChapter) -> Bool {
//		return lhs.id == rhs.id
//	}
	/**
	 Roughly equal to. If there's similarities between the SubChapters, even if they're not fully equal.
	 - Parameter other: the SubChapter to compare to
	 - Returns: true if other is equal, the headers are equal or more than half the paragraphs are equal
	 */
	func roughlyEqual(to other: SubChapter) -> Bool {
		if self == other { return true }
		if self.headerInfo == other.headerInfo { return true }
		var paraSet = Set<String>()
		for para in self.paragraphs {
			paraSet.insert(para)
		}
		var eqCount = 0
		for para in other.paragraphs {
			if paraSet.contains(para) { eqCount += 1 }
		}
		return eqCount > 0 && eqCount >= (self.paragraphs.count / 2)
	}
	
	let id = UUID().uuidString
	var headerInfo = SubChapterHeader()
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
	
	var lineCount: Int {
		// 2 for the header, paragraphs are double-spaced
		return 2 + (paragraphs.count * 2)
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
