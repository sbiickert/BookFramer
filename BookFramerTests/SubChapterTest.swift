//
//  SubChapterTest.swift
//  BookFramerTests
//
//  Created by Simon Biickert on 2022-01-30.
//

import XCTest
@testable import BookFramer

class SubChapterTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

	func testSearch() throws {
		let simpleBook = try Book.init(fromMarkdown: BookTest.SIMPLE_BOOK)
		
		XCTAssert(simpleBook.chapters[0].subchapters[0].search(for: "feelings"))
		XCTAssert(simpleBook.chapters[0].subchapters[0].search(for: "Feelings"))
		XCTAssert(simpleBook.chapters[0].subchapters[0].search(for: "pookie") == false)
		XCTAssert(simpleBook.chapters[0].subchapters[0].search(for: "such[\\w\\s]+man"))
		XCTAssert(simpleBook.chapters[0].subchapters[0].search(for: "crazy[\\w\\s]+man") == false)
	}
	
	func testIdentity() throws {
		let sub0 = SubChapter(text: "Hello World!")
		var sub1 = sub0
		sub1.headerInfo.description = "Some other value"
		XCTAssert(sub0.id == sub1.id)
		XCTAssert(sub0 != sub1)
	}
	
	func testFuzzyEquality() throws {
		let simpleBook = try Book.init(fromMarkdown: BookTest.SIMPLE_BOOK)

		let sub0 = simpleBook.chapters[0].subchapters[0]
		var sub1 = sub0
		XCTAssert(sub0.roughlyEqual(to: sub1))
		
		// Change content, leaving headers the same
		sub1.paragraphs.removeAll()
		XCTAssert(sub0.roughlyEqual(to: sub1))

		sub1 = sub0 // Reset
		
		// Change header
		sub1.headerInfo.description = "Test string."
		XCTAssert(sub0.roughlyEqual(to: sub1))

		// Modify one paragraph
		sub1.paragraphs[0] += " Test string."
		XCTAssert(sub0.roughlyEqual(to: sub1))

		// Modify another paragraph, meaning both paras are different
		sub1.paragraphs[1] += " Test string."
		XCTAssert(sub0.roughlyEqual(to: sub1) == false)
	}

}
