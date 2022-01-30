//
//  ChapterTest.swift
//  BookFramerTests
//
//  Created by Simon Biickert on 2021-08-10.
//

import XCTest
@testable import BookFramer

class ChapterTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
	
	func testWordCount() throws {
		let fileURL = URL(fileURLWithPath: BookTest.PRIDE_AND_PREJUDICE)
		let book = try Book(fromFile: fileURL)

		let chapter = book.chapters[16]
		XCTAssert(chapter.wordCount == 1279, "Expected Chapter Seventeen's word count to be 1279, was \(chapter.wordCount)")
	}

    func testReorderSubs() throws {
		let fileURL = URL(fileURLWithPath: BookTest.PRIDE_AND_PREJUDICE)
		let book = try Book(fromFile: fileURL)

		var chapter = book.chapters[5]
		XCTAssert(chapter.title == "Chapter Six")
		XCTAssert(chapter.subchapters.count == 2, "Expected sc count to be 2, was \(chapter.subchapters.count)")
		XCTAssert(chapter.subchapters[0].paragraphs[0].starts(with: "The ladies of Longbourn"))
		XCTAssert(chapter.subchapters[1].paragraphs[0].starts(with: "Mr. Darcy stood near them"))
		
		chapter.reorderSubChapter(fromIndex: 1, toIndex: 0)
		XCTAssert(chapter.subchapters[1].paragraphs[0].starts(with: "The ladies of Longbourn"))
		XCTAssert(chapter.subchapters[0].paragraphs[0].starts(with: "Mr. Darcy stood near them"))
		
		chapter.reorderSubChapter(fromIndex: 0, toIndex: 1)
		XCTAssert(chapter.subchapters[0].paragraphs[0].starts(with: "The ladies of Longbourn"))
		XCTAssert(chapter.subchapters[1].paragraphs[0].starts(with: "Mr. Darcy stood near them"))
		
		book.chapters[5] = chapter
		XCTAssert(book.chapters[5].title == "Chapter Six")
    }

	func testSearch() throws {
		let simpleBook = try Book.init(fromMarkdown: BookTest.SIMPLE_BOOK)
		
		XCTAssert(simpleBook.chapters[0].search(for: "feelings"))
		XCTAssert(simpleBook.chapters[0].search(for: "Feelings"))
		XCTAssert(simpleBook.chapters[0].search(for: "pookie") == false)
		XCTAssert(simpleBook.chapters[0].search(for: "such[\\w\\s]+man"))
		XCTAssert(simpleBook.chapters[0].search(for: "crazy[\\w\\s]+man") == false)
	}
	
	func testIdentity() throws {
		let ch0 = Chapter()
		var ch1 = ch0
		ch1.title = "Some other value"
		XCTAssert(ch0.id == ch1.id)
		XCTAssert(ch0 != ch1)
	}
	
	func testFuzzyEquality() throws {
		let simpleBook = try Book.init(fromMarkdown: BookTest.SIMPLE_BOOK)

		var ch0 = simpleBook.chapters[0]
		ch0.subchapters.append(SubChapter(text: "Extra sub"))
		var ch1 = ch0
		XCTAssert(ch0.roughlyEqual(to: ch1))
		
		// Change title
		ch1.title = "Test string"
		XCTAssert(ch0.roughlyEqual(to: ch1))

		// Change subtitle
		ch1.subtitle = "Test string"
		XCTAssert(ch0.roughlyEqual(to: ch1))

		// Change one sub
		ch1.subchapters[0].headerInfo.description = "Test string"
		XCTAssert(ch0.roughlyEqual(to: ch1))

		// Change the second sub
		ch1.subchapters[1].headerInfo.description = "Test string"
		XCTAssert(ch0.roughlyEqual(to: ch1) == false)

	}
}
