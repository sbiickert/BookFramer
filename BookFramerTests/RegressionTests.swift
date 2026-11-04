//
//  RegressionTests.swift
//  BookFramerTests
//
//  Created by Simon Biickert on 2026-11-04.
//

import Testing
import Foundation
@testable import BookFramer

/**
 Tests reproducing bugs found during the November 2026 code review.
 These are expected to fail until the corresponding bug is fixed.
 */
@Suite("Code review regressions")
struct RegressionTests {

	// MARK: Markdown import drops inline content

	@Suite("Markdown import preserves paragraph text")
	struct MarkdownImport {
		@Test("Soft line breaks do not merge adjacent words")
		func softBreakKeepsWordsSeparate() throws {
			let md = "# Title\n\n## Chapter\n\nThe first line\nthe second line."
			let book = try Book(fromMarkdown: md)
			let paragraph = try #require(book.chapters.first?.subchapters.first?.paragraphs.first)

			#expect(!paragraph.contains("linethe"), "Words were merged across the line break: \(paragraph)")
			#expect(book.wordCount == 6)
		}

		@Test("Link text is not discarded")
		func linkTextIsKept() throws {
			let md = "# Title\n\n## Chapter\n\nRead the [whole story](http://example.com) here."
			let book = try Book(fromMarkdown: md)
			let paragraph = try #require(book.chapters.first?.subchapters.first?.paragraphs.first)

			#expect(paragraph.contains("whole story"), "Link text was lost: \(paragraph)")
		}

		@Test("Links survive a save and reload")
		func linkRoundTrips() throws {
			let book = Book(text: "Read the [whole story](http://example.com) here.")
			let reloaded = try Book(fromBFD: try book.toMarkdown())

			#expect(reloaded.chapters.first?.subchapters.first?.paragraphs == book.chapters.first?.subchapters.first?.paragraphs)
		}
	}

	// MARK: Empty book title crashes

	@Test("An empty book title does not crash the parser")
	func emptyBookTitleDoesNotCrash() async {
		// Run in a separate process: the current bug is an index-out-of-range trap,
		// which would otherwise take down the whole test run.
		await #expect(processExitsWith: .success) {
			_ = try? Book(fromMarkdown: "# \n\nSome text.")
		}
	}

	// MARK: Title/subtitle colon handling

	@Suite("Chapter titles survive a save and reload")
	struct TitleRoundTrip {
		private func roundTrip(title: String, subtitle: String) throws -> Chapter {
			let book = Book(text: "Some text.")
			book.chapters[0].title = title
			book.chapters[0].subtitle = subtitle
			let reloaded = try Book(fromBFD: try book.toMarkdown())
			return try #require(reloaded.chapters.first)
		}

		@Test("Empty title with a subtitle stays empty")
		func emptyTitle() throws {
			let chapter = try roundTrip(title: "", subtitle: "Only Subtitle")
			#expect(chapter.title == "")
			#expect(chapter.subtitle == "Only Subtitle")
		}

		@Test("Subtitle containing a colon is kept whole")
		func subtitleWithColon() throws {
			let chapter = try roundTrip(title: "Part One", subtitle: "Arrival: Day 1")
			#expect(chapter.title == "Part One")
			#expect(chapter.subtitle == "Arrival: Day 1")
		}

		@Test("Book subtitle containing a colon is kept whole")
		func bookSubtitleWithColon() throws {
			let book = Book(text: "Some text.")
			book.title = "Saga"
			book.subtitle = "Volume One: Beginnings"
			let reloaded = try Book(fromBFD: try book.toMarkdown())
			#expect(reloaded.title == "Saga")
			#expect(reloaded.subtitle == "Volume One: Beginnings")
		}
	}

	// MARK: Hashable must agree with ==

	@Suite("Equal values have equal hashes")
	struct HashConsistency {
		@Test func subChapter() {
			let a = SubChapter(text: "Same text")
			let b = SubChapter(text: "Same text")
			#expect(a == b)
			#expect(a.hashValue == b.hashValue)
			#expect(Set([a]).contains(b))
		}

		@Test func chapter() {
			let a = Chapter(title: "One", subtitle: "", number: 1, subchapters: [SubChapter(text: "Text")])
			let b = Chapter(title: "One", subtitle: "", number: 1, subchapters: [SubChapter(text: "Text")])
			#expect(a == b)
			#expect(a.hashValue == b.hashValue)
		}

		@Test func persona() {
			let a = Persona(name: "Snoopy", description: "A beagle", aliases: ["Joe Cool"])
			let b = Persona(name: "Snoopy", description: "A beagle", aliases: ["Joe Cool"])
			#expect(a == b)
			#expect(a.hashValue == b.hashValue)
		}

		@Test("A renamed chapter is still matched after reload")
		func roughlyEqualAfterReload() throws {
			// Simulates an external edit (e.g. in BBEdit) that renames a chapter
			// but leaves its scenes untouched. Selection continuity depends on this.
			// Repeated because, while hashes include the random id, a match only happens
			// when two hashes collide by chance in the Set, so a single try can pass by luck.
			let original = "# Book\n\n## Old Name\n\nFirst scene.\n\n***\n\nSecond scene."
			let edited = "# Book\n\n## New Name\n\nFirst scene.\n\n***\n\nSecond scene."
			var matches = 0
			let attempts = 50
			for _ in 0..<attempts {
				let before = try #require(try Book(fromMarkdown: original).chapters.first)
				let after = try #require(try Book(fromMarkdown: edited).chapters.first)
				if after.roughlyEqual(to: before) { matches += 1 }
			}

			#expect(matches == attempts)
		}
	}
}
