//
//  BookTest.swift
//  SwiftBookBuilderTests
//
//  Created by Simon Biickert on 2021-08-02.
//

import XCTest
@testable import BookFramer

class BookTest: XCTestCase {
    
	public static let PRIDE_AND_PREJUDICE = "/Users/sbiickert/Code/BookFramer/Pride_And_Prejudice/book.bfd"
	//"/Users/sjb/Projects/Mac/BookFramer/Pride_And_Prejudice/book.bfd"
	public static let SIMPLE_BOOK = """
		# Pride and Prejudice:

		<!-- {
		  "author": "Jane Austen",
		  "year": "1813",
		  "keywords": [ "classic", "feminist" ],
		  "genres": [ "Romance" ],
		  "characters": {
			"major": [
			  {
				"description": "of Longbourn-house, Hertfordshire. Entailed estate with ￡2,000 a year. Married to Mrs. Bennet.",
				"name": "Mr. Bennet",
				"aliases": ["Bob", "Sir"]
			  }],
			"minor": [
			{
			  "description": "Companion to Miss Darcy",
			  "name": "Mrs. Annesley",
			  "aliases": []
			}] }} -->
		
		## Chapter One:

		<!-- {
		"description": "News of Mr. Bingley Coming to Netherfield",
		"location": "Longbourn",
		"pov": "Mr. Bennet",
		"status": "Finished",
		"analytic_info": {}
		} -->

		It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.
			
		*However* little known the feelings or views of such a man may be on his first entering a neighbourhood, this truth is so well fixed in the minds of the surrounding families, that he is considered the rightful property of some one or other of their daughters.
		"""
		
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
	
	func testCreateEmptyBook() throws {
		let book = Book(text: "Tested")
		XCTAssert(book.chapters.count == 1)
		XCTAssert(book.chapters[0].subchapters.count == 1)
		XCTAssert(book.chapters[0].subchapters[0].paragraphs.count == 1)
		XCTAssert(book.chapters[0].subchapters[0].paragraphs[0] == "Tested")
	}

    func testParseBlocks() throws {
		let blocks = BookBlock.parse(fromMarkdown: BookTest.SIMPLE_BOOK)
		XCTAssert(blocks.count == 6)
		if (blocks.count == 6) {
			XCTAssert(blocks[0].type == .title)
			XCTAssert(blocks[1].type == .header)
			XCTAssert(blocks[2].type == .chapterTitle)
			XCTAssert(blocks[3].type == .header)
			XCTAssert(blocks[4].type == .paragraph)
			XCTAssert(blocks[5].type == .paragraph)
		}
    }
	
	func testOutput() throws {
		let blocks = BookBlock.parse(fromMarkdown: BookTest.SIMPLE_BOOK)
		XCTAssert(blocks.count == 6)
		let book = try Book(fromBlocks: blocks)
		let outputBlocks = try book.toBlocks()
		XCTAssert(outputBlocks.count == 6)
		
		let markdown = try book.toMarkdown()
		
		let secondBlocks = BookBlock.parse(fromMarkdown: markdown)
		XCTAssert(secondBlocks.count == 6)
		let secondBook = try Book(fromBlocks: secondBlocks)

		XCTAssert(book == secondBook, "They weren't equal.")
	}

	func testInitSimpleBook() throws {
		let blocks = BookBlock.parse(fromMarkdown: BookTest.SIMPLE_BOOK)
		let book = try Book(fromBlocks: blocks)
		
		XCTAssert(book.title == "Pride and Prejudice", "Expected title to be 'Pride and Prejudice', was '\(book.title)'")
		XCTAssert(book.subtitle == "", "Expected subtitle to be '', was '\(book.subtitle)'")
		XCTAssert(book.headerInfo.author == "Jane Austen", "Expected author to be 'Jane Austen', was '\(book.headerInfo.author)'")
		XCTAssert(book.minorPersonas.count == 1, "Expected minor character count to be 1, was \(book.minorPersonas.count)")
		XCTAssert(book.majorPersonas[0].aliases.count == 2, "Expected major character [0] alias count to be 2, was \(book.majorPersonas[0].aliases.count)")
		XCTAssert(book.chapters.count == 1, "Expected chapter count to be 1, was \(book.chapters.count)")
		XCTAssert(book.chapters[0].title == "Chapter One", "Expected chapter 1 title to be 'Chapter One', was \(book.chapters[0].title)")
		XCTAssert(book.chapters[0].subchapters[0].headerInfo.status == .finished, "Expected chapter 1, scene[0] to be finished. Was \(book.chapters[0].subchapters[0].headerInfo.status)")
	}

	func testInitFullBook() throws {
		let fileURL = URL(fileURLWithPath: BookTest.PRIDE_AND_PREJUDICE)

		let book = try Book(fromFile: fileURL)
		XCTAssert(book.title == "Pride and Prejudice", "Expected title to be 'Pride and Prejudice', was '\(book.title)'")
		XCTAssert(book.subtitle == "", "Expected subtitle to be '', was '\(book.subtitle)'")
		XCTAssert(book.headerInfo.author == "Jane Austen", "Expected author to be 'Jane Austen', was '\(book.headerInfo.author)'")
		XCTAssert(book.minorPersonas.count == 29, "Expected minor character count to be 29, was \(book.minorPersonas.count)")
		XCTAssert(book.majorPersonas[3].aliases.count == 3, "Expected major character [3] alias count to be 3, was \(book.majorPersonas[3].aliases.count)")
		XCTAssert(book.chapters.count == 61, "Expected chapter count to be 61, was \(book.chapters.count)")
		XCTAssert(book.chapters[5].title == "Chapter Six", "Expected chapter[5] title to be 'Chapter Six', was \(book.chapters[5].title)")
		XCTAssert(book.chapters[0].subchapters[0].headerInfo.status == .finished, "Expected chapter 1, scene[0] to be finished. Was \(book.chapters[0].subchapters[0].headerInfo.status)")
		XCTAssert(book.chapters[0].subchapters[0].paragraphs[0].starts(with: "It is a truth universally acknowledged"),
				  "Expected chapter one to start with 'It is a truth universally acknowledged', started with \(book.chapters[0].subchapters[0].paragraphs[0].prefix(30))...")
		XCTAssert(book.chapters[1].subchapters[0].paragraphs[0].starts(with: "Mr. Bennet was among the earliest"),
				  "Expected chapter two to start with 'Mr. Bennet was among the earliest', started with \(book.chapters[1].subchapters[0].paragraphs[0].prefix(30))...")
		XCTAssert(book.chapters[2].subchapters[0].paragraphs[0].starts(with: "Not all that Mrs. Bennet"),
				  "Expected chapter one to start with 'Not all that Mrs. Bennet', started with \(book.chapters[2].subchapters[0].paragraphs[0].prefix(30))...")
		XCTAssert(book.chapters[3].subchapters[0].paragraphs[0].starts(with: "When Jane and Elizabeth were alone"),
				  "Expected chapter one to start with 'When Jane and Elizabeth were alone', started with \(book.chapters[3].subchapters[0].paragraphs[0].prefix(30))...")
		XCTAssert(book.chapters[4].subchapters[0].paragraphs[0].starts(with: "Within a short walk of Longbourn"),
				  "Expected chapter one to start with 'Within a short walk of Longbourn', started with \(book.chapters[4].subchapters[0].paragraphs[0].prefix(30))...")
		XCTAssert(book.chapters[5].subchapters[0].paragraphs[0].starts(with: "The ladies of Longbourn soon"),
				  "Expected chapter one to start with 'The ladies of Longbourn soon', started with \(book.chapters[5].subchapters[0].paragraphs[0].prefix(30))...")
	}
	
	func testAddChapter() throws {
		let book = try Book(fromMarkdown: BookTest.SIMPLE_BOOK)
		XCTAssert(book.chapters.count == 1)
		var c = Chapter()
		c.title = "Test"
		book.add(chapter: c)
		XCTAssert(book.chapters.count == 2)
		XCTAssert(book.chapters[1].title == "Test")
		XCTAssert(book.chapters[0].number == 1)
		XCTAssert(book.chapters[1].number == 2)
		c.title = "Second Test"
		book.add(chapter: c, at: 0)
		XCTAssert(book.chapters[0].title == "Second Test")
		XCTAssert(book.chapters[2].title == "Test")

	}
	
	func testRemoveChapter() throws {
		let book = try Book(fromMarkdown: BookTest.SIMPLE_BOOK)
		XCTAssert(book.chapters.count == 1)
		book.removeChapter(at: 0)
		XCTAssert(book.chapters.count == 0)
	}
	
	func testReorderChapter() throws {
		let fileURL = URL(fileURLWithPath: BookTest.PRIDE_AND_PREJUDICE)
		let book = try Book(fromFile: fileURL)
		
		XCTAssert(book.chapters.count == 61)
		book.reorderChapter(fromIndex: 1, toIndex: 0)
		XCTAssert(book.chapters[0].title == "Chapter Two")
		XCTAssert(book.chapters[1].title == "Chapter One")
		book.reorderChapter(fromIndex: 0, toIndex: 1)
		XCTAssert(book.chapters[0].title == "Chapter One")
		XCTAssert(book.chapters[1].title == "Chapter Two")
		book.reorderChapter(fromIndex: 0, toIndex: 100)
		XCTAssert(book.chapters[0].title == "Chapter One")
		XCTAssert(book.chapters.count == 61)
	}
	
	func testCheckingModifiedSinceRead() throws {
		let fileURL = URL(fileURLWithPath: BookTest.PRIDE_AND_PREJUDICE)
		let book = try Book(fromFile: fileURL)
		
		XCTAssert(try book.isFileUpdatedSinceRead() == false)
		
		//let newAttrs = [FileAttributeKey.modificationDate: Date()]
		//try FileManager.default.setAttributes(newAttrs, ofItemAtPath: book.sourceFile!.path)
		
		var resourceValues = URLResourceValues()
		resourceValues.contentModificationDate = Date()
		try book.sourceFile!.setResourceValues(resourceValues)
		
		XCTAssert(try book.isFileUpdatedSinceRead() == true)
	}
	
	func testCompile() throws {
		let simpleBook = try Book(fromMarkdown: BookTest.SIMPLE_BOOK)
		
		let fileURL = URL(fileURLWithPath: BookTest.PRIDE_AND_PREJUDICE)
		let fullBook = try Book(fromFile: fileURL)
		
		var md: String
		md = simpleBook.compile()
		XCTAssert(md.count > 0)
		md = fullBook.compile()
		XCTAssert(md.count > 0)
	}
	
	func testWordCount() throws {
		let simpleBook = try Book(fromMarkdown: BookTest.SIMPLE_BOOK)
		
		let fileURL = URL(fileURLWithPath: BookTest.PRIDE_AND_PREJUDICE)
		let fullBook = try Book(fromFile: fileURL)
		
		var wc: Int
		wc = simpleBook.wordCount
		XCTAssert(wc == 70)
		wc = fullBook.wordCount
		XCTAssert(wc == 122074)
	}
	
	func testPersonasIn() throws {
		let fileURL = URL(fileURLWithPath: BookTest.PRIDE_AND_PREJUDICE)
		let fullBook = try Book(fromFile: fileURL)

		let mrDarcy = fullBook.findPersona(named: "Mr. Darcy")
		let mrBingley = fullBook.findPersona(named: "Mr. Bingley")
		let elizabeth = fullBook.findPersona(named: "Lizzy")
		XCTAssert(mrDarcy != nil)
		XCTAssert(mrBingley != nil)
		XCTAssert(elizabeth != nil)
		XCTAssert(mrDarcy!.isIn(chapter: fullBook.chapters[0]) == false)
		XCTAssert(mrBingley!.isIn(chapter: fullBook.chapters[1]))
		XCTAssert(mrDarcy!.isIn(chapter: fullBook.chapters[2]))
		for c in fullBook.chapters {
			XCTAssert(elizabeth!.isIn(chapter: c))
		}
	}
}
