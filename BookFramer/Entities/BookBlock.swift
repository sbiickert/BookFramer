//
//  BookBlock.swift
//  SwiftBookBuilder
//
//  Created by Simon Biickert on 2021-08-02.
//

import Foundation
import Markdown

struct BookBlock {
	/**
	 Using Apple's swift-markdown framework instead of hand-rolled.
	 - Parameter md: the markdown novel
	 - Returns: array of BookBlocks
	 */
	public static func parse(fromMarkdown md: String, isBFD: Bool) -> [BookBlock] {
		let doc = Markdown.Document(parsing: md)
		var walker = BookWalker()
		if isBFD == false {
			walker.insertHeaders = true
		}
		walker.visit(doc)
		
		return walker.parsed
	}
	
	struct BookWalker: MarkupWalker {
		var insertHeaders = false
		var parsed = [BookBlock]()
		
		private var encoder: JSONEncoder {
			let enc = JSONEncoder()
			enc.keyEncodingStrategy = .convertToSnakeCase
			return enc
		}
		
		private func emptyHeader(type: BookBlockType) -> BookBlock? {
			do {
				var json:Data
				if type == .title {
					let emptyHeader = BookHeader()
					json = try encoder.encode(emptyHeader)
				}
				else {
					let emptyHeader = SubChapterHeader()
					json = try encoder.encode(emptyHeader)
				}
				let str = String(data: json, encoding: .utf8)!
				let block = BookBlock(type: .header, content: str)
				return block
			}
			catch {
				print(error)
			}
			return nil
		}

		mutating func visitHeading(_ heading: Heading) -> () {
			if heading.level == 1 {
				parsed.append(BookBlock(type: .title, content: heading.plainText))
				if insertHeaders {
					parsed.append(emptyHeader(type: .title)!)
				}
			}
			else {
				parsed.append(BookBlock(type: .chapterTitle, content: heading.plainText))
				if insertHeaders {
					parsed.append(emptyHeader(type: .header)!)
				}
			}
		}
		mutating func visitParagraph(_ paragraph: Paragraph) -> () {
			// parsed.append(BookBlock(type: .paragraph, content: paragraph.plainText)) // Strips inline markup
			
			var content = ""
			for child in paragraph.inlineChildren {
				if let text = child as? Text {
					content.append(text.string)
				}
				else if let em = child as? Emphasis {
					content.append("*\(em.plainText)*")
				}
				else if let strong = child as? Strong {
					content.append("**\(strong.plainText)**")
				}
			}
			if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
				parsed.append(BookBlock(type: .paragraph, content: content))
			}
		}
		
		mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> () {
			// Section Break e.g. ****
			parsed.append(emptyHeader(type: .header)!)
		}
		
		mutating func visitHTMLBlock(_ html: HTMLBlock) -> () {
			// Header JSON in HTML comment
			var block = BookBlock(type: .header, content: html.rawHTML)
			block.trimMarkers()
			parsed.append(block)
		}
	}
	
	var type: BookBlockType = .unknown
	var content: String = ""
	
	var markdown: String {
		switch type {
		case .title:
			return "# \(content)"
		case .chapterTitle:
			return "## \(content)"
		case .header:
			return "<!-- \(content) -->"
		default:
			return content
		}
	}
	
	private mutating func trimMarkers() {
		var c = content.trimmingCharacters(in: .whitespacesAndNewlines)
		if c.hasPrefix("<!--") {
			c = String(c.dropFirst(4))
		}
		if c.hasSuffix("-->") {
			c = String(c.dropLast(3))
		}
		if c.hasPrefix("# ") {
			c = String(c.dropFirst(2))
		}
		if c.hasPrefix("## ") {
			c = String(c.dropFirst(3))
		}
		content = c
	}
}

enum BookBlockType {
	case title
	case chapterTitle
	case header
	case paragraph
	case unknown
}
