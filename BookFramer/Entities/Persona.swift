//
//  Character.swift
//  SwiftBookBuilder
//
//  Created by Simon Biickert on 2021-08-02.
//

import AppKit

struct Persona: Codable, Equatable, Hashable, IDable {
	static func == (lhs: Persona, rhs: Persona) -> Bool {
		return lhs.name == rhs.name &&
			lhs.description == rhs.description &&
			lhs.aliases == rhs.aliases
	}
	static let MAJOR = "major"
	static let MINOR = "minor"
	
	static let MAJOR_IMAGE = NSImage(systemSymbolName: "person.crop.circle.badge.exclamationmark", accessibilityDescription: "Major character")
	static let MINOR_IMAGE = NSImage(systemSymbolName: "person.crop.circle", accessibilityDescription: "Minor character")
	
	private(set) var id = UUID().uuidString
	var name: String
	var description: String
	var aliases: [String]
	
	var joinedAliases: String {
		get {
			return aliases.joined(separator: ", ")
		}
		set {
			aliases = _aliasesToArray(csv: newValue)
		}
	}
	
	private func _aliasesToArray(csv: String) -> [String] {
		let s = csv.replacingOccurrences(of: ", *", with: ",", options: .regularExpression, range: nil)
		let kw: [String] = s.split(separator: ",").map {String($0)}
		return kw
	}

	
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
