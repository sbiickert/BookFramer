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

	// MARK: Drag and drop reordering

	@Suite("Moving chapters and subchapters")
	struct DragAndDrop {
		/// Three chapters: A (a1, a2, a3), B (b1, b2, b3), C (c1)
		private func makeBook() throws -> Book {
			let md = """
				# Book

				## A

				a1

				***

				a2

				***

				a3

				## B

				b1

				***

				b2

				***

				b3

				## C

				c1
				"""
			return try Book(fromMarkdown: md)
		}

		private func layout(_ chapters: [Chapter]) -> [String] {
			chapters.map { ch in "\(ch.title):" + ch.subchapters.map { $0.paragraphs.joined() }.joined(separator: ",") }
		}

		private func sub(_ text: String, in book: Book) throws -> SubChapter {
			try #require(book.chapters.flatMap(\.subchapters).first(where: { $0.paragraphs.first == text }))
		}

		@Test("Computing a move does not modify the book, so undo can restore it")
		func moveIsNonMutating() throws {
			let book = try makeBook()
			let before = layout(book.chapters)
			let a1 = try sub("a1", in: book)
			_ = book.chapters(moving: a1.id, to: .end)
			#expect(layout(book.chapters) == before)
		}

		@Test("A subchapter moved before a subchapter in a later chapter lands directly before it")
		func moveSubToLaterChapter() throws {
			let book = try makeBook()
			let a1 = try sub("a1", in: book)
			let b3 = try sub("b3", in: book)
			let result = try #require(book.chapters(moving: a1.id, to: .beforeSubChapter(id: b3.id)))
			#expect(layout(result) == ["A:a2,a3", "B:b1,b2,a1,b3", "C:c1"])
		}

		@Test("A subchapter moved later within its own chapter lands directly before the target")
		func moveSubWithinChapter() throws {
			let book = try makeBook()
			let a1 = try sub("a1", in: book)
			let a3 = try sub("a3", in: book)
			let result = try #require(book.chapters(moving: a1.id, to: .beforeSubChapter(id: a3.id)))
			#expect(layout(result) == ["A:a2,a1,a3", "B:b1,b2,b3", "C:c1"])
		}

		@Test("A subchapter dropped above a chapter row goes to the end of the previous chapter")
		func moveSubBeforeChapter() throws {
			let book = try makeBook()
			let c1 = try sub("c1", in: book)
			let result = try #require(book.chapters(moving: c1.id, to: .beforeChapter(id: book.chapters[1].id)))
			#expect(layout(result) == ["A:a1,a2,a3,c1", "B:b1,b2,b3", "C:"])
		}

		@Test("A subchapter dropped at the end goes to the last chapter")
		func moveSubToEnd() throws {
			let book = try makeBook()
			let a1 = try sub("a1", in: book)
			let result = try #require(book.chapters(moving: a1.id, to: .end))
			#expect(layout(result) == ["A:a2,a3", "B:b1,b2,b3", "C:c1,a1"])
		}

		@Test("Chapters reorder and are renumbered")
		func moveChapters() throws {
			let book = try makeBook()
			let (a, c) = (book.chapters[0], book.chapters[2])
			let toEnd = try #require(book.chapters(moving: a.id, to: .end))
			#expect(toEnd.map(\.title) == ["B", "C", "A"])
			#expect(toEnd.map(\.number) == [1, 2, 3])

			let toFront = try #require(book.chapters(moving: c.id, to: .beforeChapter(id: a.id)))
			#expect(toFront.map(\.title) == ["C", "A", "B"])
			#expect(toFront.map(\.number) == [1, 2, 3])
		}

		@Test("Invalid moves are rejected")
		func invalidMoves() throws {
			let book = try makeBook()
			let a1 = try sub("a1", in: book)
			#expect(book.chapters(moving: "no-such-id", to: .end) == nil)
			// No chapter precedes the first chapter
			#expect(book.chapters(moving: a1.id, to: .beforeChapter(id: book.chapters[0].id)) == nil)
			// Chapters can't be dropped among subchapters
			#expect(book.chapters(moving: book.chapters[0].id, to: .beforeSubChapter(id: a1.id)) == nil)
		}
	}

	// MARK: Undo and redo of edits

	/// Stands in for ManageVC so DocEditor can be exercised without a window
	final class FakeHost: DocEditorHost {
		let book: Book?
		let undoManager: UndoManager? = UndoManager()
		let notificationCenter: NotificationCenter? = NotificationCenter()
		var selectedChapter: Chapter?
		var selectedSubChapter: SubChapter?
		var selectedPart: Any? { selectedSubChapter ?? selectedChapter ?? book }

		init(book: Book) {
			self.book = book
			// In the app the run loop groups each event's undo registrations; do it explicitly here
			undoManager?.groupsByEvent = false
		}

		/// Posts an edit notification inside its own undo group, as a single user action would
		func edit(_ name: Notification.Name, _ object: Any? = nil) {
			undoManager?.beginUndoGrouping()
			notificationCenter?.post(name: name, object: object)
			undoManager?.endUndoGrouping()
		}
	}

	@Suite("Undo and redo of chapter and subchapter edits")
	struct UndoRedo {
		private let book: Book
		private let host: FakeHost
		private let editor = DocEditor()

		init() throws {
			book = try Book(fromMarkdown: "# Book\n\n## A\n\na1\n\n***\n\na2\n\n## B\n\nb1")
			host = FakeHost(book: book)
			editor.register(host: host)
		}

		private var layout: [String] {
			book.chapters.map { ch in "\(ch.title):" + ch.subchapters.map { $0.paragraphs.joined() }.joined(separator: ",") }
		}

		/// Performs the edit, then checks undo restores the original and redo reapplies the edit
		private func checkUndoRedo(_ name: Notification.Name, _ object: Any?, expected: [String]) throws {
			let original = layout
			host.edit(name, object)
			#expect(layout == expected, "edit")
			let undo = try #require(host.undoManager)
			undo.undo()
			#expect(layout == original, "undo")
			#expect(undo.canRedo, "redo is available")
			undo.redo()
			#expect(layout == expected, "redo")
		}

		@Test func addChapter() throws {
			host.selectedChapter = book.chapters[0]
			try checkUndoRedo(.addChapter, nil, expected: ["A:a1,a2", ":", "B:b1"])
		}

		@Test func modifyChapter() throws {
			var b = book.chapters[1]
			b.title = "Renamed"
			try checkUndoRedo(.modifyChapter, b, expected: ["A:a1,a2", "Renamed:b1"])
		}

		@Test("Modifying a chapter that is not selected undoes correctly")
		func modifyUnselectedChapter() throws {
			host.selectedChapter = book.chapters[0]
			var b = book.chapters[1]
			b.title = "Renamed"
			try checkUndoRedo(.modifyChapter, b, expected: ["A:a1,a2", "Renamed:b1"])
		}

		@Test func deleteChapter() throws {
			try checkUndoRedo(.deleteChapter, book.chapters[0], expected: ["B:b1"])
		}

		@Test func addSubChapter() throws {
			try checkUndoRedo(.addSubChapter, book.chapters[1], expected: ["A:a1,a2", "B:b1,"])
		}

		@Test("Modifying a subchapter that is not selected undoes correctly")
		func modifyUnselectedSubChapter() throws {
			host.selectedSubChapter = book.chapters[0].subchapters[0]
			var b1 = book.chapters[1].subchapters[0]
			b1.paragraphs = ["changed"]
			try checkUndoRedo(.modifySubChapter, b1, expected: ["A:a1,a2", "B:changed"])
		}

		@Test func deleteSubChapter() throws {
			try checkUndoRedo(.deleteSubChapter, book.chapters[0].subchapters[1], expected: ["A:a1", "B:b1"])
		}

		@Test func dragAndDrop() throws {
			let a1 = book.chapters[0].subchapters[0]
			let moved = try #require(book.chapters(moving: a1.id, to: .end))
			try checkUndoRedo(.modifyChapters, moved, expected: ["A:a2", "B:b1,a1"])
		}

		@Test("Chapters are renumbered after an edit")
		func renumbering() throws {
			host.edit(.deleteChapter, book.chapters[0])
			#expect(book.chapters.map(\.number) == [1])
			try #require(host.undoManager).undo()
			#expect(book.chapters.map(\.number) == [1, 2])
		}
	}

	// MARK: Edge cases

	@Suite("Edge cases")
	struct EdgeCases {
		@Test("Compiling a chapter with no subchapters keeps its heading")
		func compileEmptyChapter() {
			let ch = Chapter(title: "Empty", subtitle: "", number: 1, subchapters: [])
			#expect(ch.compile() == ["## Empty"])
		}

		@Test("Two different single-subchapter chapters are not roughly equal")
		func roughlyEqualSingleScene() {
			let a = Chapter(title: "A", subtitle: "", number: 1, subchapters: [SubChapter(text: "One thing")])
			let b = Chapter(title: "B", subtitle: "", number: 2, subchapters: [SubChapter(text: "Something else")])
			#expect(!a.roughlyEqual(to: b))
		}

		@Test("Type-token ratio of empty text is zero, not NaN")
		func emptyTokenTypeRatio() {
			#expect(BookAnalytics.calculateTokenTypeRatio(text: "") == 0)
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
