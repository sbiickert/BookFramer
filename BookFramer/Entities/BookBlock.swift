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
			parsed.append(BookBlock(type: .paragraph, content: paragraph.plainText))
//			for child in paragraph.inlineChildren {
//			}
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
	
//	public static func parse(fromMarkdown md: String) -> [BookBlock] {
//		var parsed = [BookBlock]()
//		var partialBlock: BookBlock?
//		var lastCharWasNewline = false
//		var partialHeaderTerminator = "" // -->
//
//		func parse(_ ch: Character) {
//			if var block = partialBlock {
//				// We are adding to a block in progress
//				var terminateBlock = false
//				if ch == "\t" { // Ignore all tabs
//					return
//				}
//				block.content.append(ch)
//
//				if block.type == .header {
//					if ch == "-" {
//						partialHeaderTerminator.append(ch)
//					}
//					else if ch == ">" && partialHeaderTerminator == "--" {
//						// Found end of header block
//						block.trimMarkers()
//						parsed.append(block)
//						terminateBlock = true
//						partialHeaderTerminator = ""
//					}
//					else {
//						partialHeaderTerminator = ""
//					}
//				}
//
//				else if block.type == .unknown {
//					// We haven't determined the block type
//					let t = block.determineType()
//					if t != .unknown {
//						block.type = t
//					}
//				}
//
//				else {
//					// headers can have arbitrary \n. Other blocks are terminated by them.
//					if ch == "\n" {
//						if lastCharWasNewline { // The previous letter was also \n
//							// end of block
//							block.trimMarkers()
//							parsed.append(block)
//							terminateBlock = true
//							lastCharWasNewline = false
//						}
//						else {
//							lastCharWasNewline = true
//						}
//					}
//					else {
//						lastCharWasNewline = false
//					}
//				}
//
//				partialBlock = terminateBlock ? nil : block
//			}
//			else {
//				// New block starting
//				if ch != "\n" {
//					// Ignore additional \n
//					var block = BookBlock()
//					block.content.append(ch)
//					partialBlock = block
//				}
//			}
//		}
//
//		md.forEach(parse)
//
//		if let block = partialBlock {
//			parsed.append(block)
//		}
//
//		return parsed
//	}
	
	var type: BookBlockType = .unknown
	var content: String = ""
	
//	func determineType() -> BookBlockType {
//		let trimmed = content.trimmingCharacters(in: .whitespaces)
//
//		if trimmed.starts(with: "<!--") {
//			return .header
//		}
//		if trimmed.starts(with: "## ") {
//			return .chapterTitle
//		}
//		if trimmed.starts(with: "# ") {
//			return .title
//		}
//		if trimmed.count > 4 {
//			// Haven't found any of the markdown tags in the first 4 chars
//			return .paragraph
//		}
//		return .unknown
//	}
	
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
