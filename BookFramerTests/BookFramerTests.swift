//
//  BookFramerTests.swift
//  BookFramerTests
//
//  Created by Simon Biickert on 2021-08-23.
//

import XCTest
@testable import BookFramer

class BookFramerTests: XCTestCase {
	let sampleText = ["NLP articles are fun. But they are awfully difficult to write. NLP is not difficult, but the articles, wow would awfully make you think of writing NLP Books!",
					  "The red dog jumped over the red fox."]

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

	func testBookAnalyticTTR() throws {
		var ttr = BookAnalytics.calculateTokenTypeRatio(text: sampleText[0])
		XCTAssert(ttr > 0)
		
		ttr = BookAnalytics.calculateTokenTypeRatio(text: sampleText[1])
		XCTAssert(ttr == 75.0)
	}
	
	func testBookAnalyticFRES() throws {
		var fres = BookAnalytics.calculateFleschReadingEaseScore(text: sampleText[0])
		XCTAssert(fres < 80.0)
		
		fres = BookAnalytics.calculateFleschReadingEaseScore(text: sampleText[1])
		XCTAssert(fres > 90.0)
	}

	func testTokenizing() throws {
		var sentences = BookAnalytics.tokens(in: sampleText[0], unit: .sentence)
		XCTAssert(sentences.count == 3)
		
		sentences = BookAnalytics.tokens(in: sampleText[1], unit: .sentence)
		XCTAssert(sentences.count == 1)
		
		let words = BookAnalytics.tokens(in: sentences[0], unit: .word)
		XCTAssert(words.count == 8)
	}
	
	func testSyllables() throws {
		let words = ["bee", "apple", "bicycle", "quadrupedal"]
		let counts = BookAnalytics.countSyllables(in: words)
		XCTAssert(counts == [1,2,3,4])
	}
	
	func testPartsOfSpeech() throws {
		var parts = BookAnalytics.tagPartsOfSpeech(in: sampleText[0])
		XCTAssert(parts["Adverb"]!.count == 3)
		parts = BookAnalytics.tagPartsOfSpeech(in: sampleText[1])
		XCTAssert(parts["Noun"]!.count == 2)
		
		let adverbRanges = BookAnalytics.tagAdverbs(in: sampleText[0])
		XCTAssert(adverbRanges.count == 3)
	}
	
	func testPassiveVoice() throws {
		var pvRange = BookAnalytics.tagPassiveVoice(in: sampleText[0])
		XCTAssert(pvRange == nil)
		let pv1 = "My sandwich was eaten by bears."
		pvRange = BookAnalytics.tagPassiveVoice(in: pv1)
		XCTAssert(pvRange != nil)
		XCTAssert(pv1[pvRange!] == "was eaten")
		let pv2 = "It is true that my sandwich was eaten by bears."
		pvRange = BookAnalytics.tagPassiveVoice(in: pv2)
		XCTAssert(pvRange != nil)
		XCTAssert(pv2[pvRange!] == "was eaten")
	}
}
