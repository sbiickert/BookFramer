//
//  Character.swift
//  SwiftBookBuilder
//
//  Created by Simon Biickert on 2021-08-02.
//

import Foundation

struct Persona: Codable, Equatable, Hashable {
	static func == (lhs: Persona, rhs: Persona) -> Bool {
		return lhs.name == rhs.name &&
			lhs.description == rhs.description &&
			lhs.aliases == rhs.aliases
	}
	static let MAJOR = "major"
	static let MINOR = "minor"
	
	let id = UUID().uuidString
	var name: String
	var description: String
	var aliases: [String]
	
	func isIn(chapter: Chapter) -> Bool {
		for sub in chapter.subchapters {
			if isIn(subChapter: sub) {
				return true
			}
		}
		return false
	}
	
	func isIn(subChapter: SubChapter) -> Bool {
		for para in subChapter.paragraphs {
			if isIn(text: para) {
				return true
			}
		}
		return false
	}
	
	func isIn(text: String) -> Bool {
		var allNames = [String]()
		allNames.append(name)
		allNames.append(contentsOf: aliases)
		for n in allNames {
			if text.contains(n) {
				return true
			}
		}
		return false
	}
}
