//
//  Chapter.swift
//  SwiftBookBuilder
//
//  Created by Simon Biickert on 2021-08-02.
//

import Foundation

struct Chapter: Equatable, Hashable, IDable {
	static func == (lhs: Chapter, rhs: Chapter) -> Bool {
		return lhs.title == rhs.title &&
			lhs.subtitle == rhs.subtitle &&
			lhs.subchapters == rhs.subchapters
	}
//	static func == (lhs: Chapter, rhs: Chapter) -> Bool {
//		return lhs.id == rhs.id
//	}
	
	let id = UUID().uuidString
	var title = "Title"
	var subtitle = "Subtitle"
	var number = 0
	var startLineNumber = 0
	var subchapters = [SubChapter]()
	
	/**
	Convenience property joining the title and the (optional) subtitle
	
	- Returns: "title" or "title: subtitle"
	*/
	var titleSubtitle: String {
		if subtitle.trimmingCharacters(in: .whitespaces) == "" {
			return title
		}
		return "\(title): \(subtitle)"
	}
	
	/**
	Sums the word counts in all subchapters
	
	- Returns: word count for the chapter
	*/
	var wordCount: Int {
		var wc = 0
		for sub in subchapters {
			wc += sub.wordCount
		}
		return wc
	}
	
	var status: EditStatus {
		var statuses = Set<EditStatus>()
		for sub in subchapters {
			statuses.insert(sub.headerInfo.status)
		}
		return statuses.count == 1 ? statuses.first! : EditStatus.multiple
	}
	
	/**
	Moves the subchapter from the chapter from `fromIndex` to `toIndex`
	Takes no action if `fromIndex` or `toIndex` is invalid.
	
	- Parameter fromIndex: the index of the subchapter to move
	- Parameter toIndex: the index to move the subchapter to
	*/
	public mutating func reorderSubChapter(fromIndex: Int, toIndex: Int) {
		guard (0..<subchapters.count).contains(fromIndex) && (0..<subchapters.count).contains(toIndex) else {
			print("fromIndex or toIndex was out of range.")
			return
		}
		var arr = subchapters
		let sc = arr.remove(at: fromIndex)
		arr.insert(sc, at: toIndex)
		subchapters = arr
	}
	
	/**
	Replaces the subchapter from the chapter identified by the same id
	Takes no action if no subchapter in the book has the same id.
	
	- Parameter subchapter: the revised SubChapter
	*/
	public mutating func replace(subchapter: SubChapter) {
		for (index, sub) in subchapters.enumerated() {
			if sub.id == subchapter.id {
				subchapters[index] = subchapter
				break
			}
		}
	}

	/**
	Searches for a case-insensitive regex pattern in all subchapters
	
	- Parameter pattern: the regex to search for
	
	- Returns: true if the pattern exists in the chapter
	*/
	func search(for pattern: String) -> Bool {
		for sub in subchapters {
			if sub.search(for: pattern) {
				return true
			}
		}
		return false
	}
	
	/**
	Combines all SubChapters into a list of Markdown strings for printing.
	
	- Returns: array of markdown strings for printing
	*/
	func compile() -> [String] {
		var markdownStrings = [String]()
		markdownStrings.append("\\newpage")
		markdownStrings.append("## Chapter \(number): \(title)")
		if subtitle.trimmingCharacters(in: .whitespaces).count > 0 {
			markdownStrings.append("### \(subtitle)")
		}
		for sub in subchapters {
			markdownStrings.append(contentsOf: sub.compile())
			markdownStrings.append("***")
		}
		// Remove the last scene break, b/c we've added one too many
		markdownStrings.removeLast()
		return markdownStrings
	}
}
