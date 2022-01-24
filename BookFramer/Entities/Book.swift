//
//  Book.swift
//  SwiftBookBuilder
//
//  Created by Simon Biickert on 2021-08-02.
//

import Foundation

class Book: Equatable, ObservableObject {
	/**
	Test for equality. Evaluates equality of title, subtitle, headerInfo and chapters.
	*/
	static func == (lhs: Book, rhs: Book) -> Bool {
		return lhs.title == rhs.title &&
			lhs.subtitle == rhs.subtitle &&
			lhs.headerInfo == rhs.headerInfo &&
			lhs.chapters == rhs.chapters
	}
	
	/// URL to the file holding this book. If it does not represent a book file on disk, this is nil
	var sourceFile: URL?
	/// The time when the Book was constructed.
	var readAtTime: Date
	
	var title:String = "Title"
	var subtitle:String = "Subtitle"
	var headerInfo = BookHeader()
	var chapters = [Chapter]()
	
	/**
	Creates an empty book with an opening Chapter with one SubChapter
	*/
	init(text: String) {
		readAtTime = Date()
		var c = Chapter()
		let sc = SubChapter(text: text)
		c.subchapters.append(sc)
		add(chapter: c)
		let p = Persona(name: "Snoopy", description: "A beagle", aliases: ["Joe Cool"])
		headerInfo.personas[Persona.MAJOR] = [p]
	}
	
	/**
	Creates a book from a URL of a book file on disk.
	
	- Parameter fileURL: the file to open
	
	- Throws: SBSError.invalidBookHeader
		bubbled up from parseHeader
	*/
	convenience init(fromFile fileURL:URL) throws {
		let content:String
		do {
			content = try String(contentsOf: fileURL, encoding: .utf8)
		}
		catch {
			throw SBSError.fileNotFound
		}
		try self.init(fromMarkdown: content)
		sourceFile = fileURL
	}
	
	/**
	Creates a book from a markdown string
	
	- Throws: SBSError.invalidBookHeader
		bubbled up from parseHeader
	*/
	convenience init(fromMarkdown md:String) throws {
		let blocks = BookBlock.parse(fromMarkdown: md)
		try self.init(fromBlocks: blocks)
	}
	
	/**
	Creates a book from an array of BookBlocks
	
	- Throws: SBSError.invalidBookHeader
		bubbled up from parseHeader
	*/
	init(fromBlocks blocks: [BookBlock]) throws {
		var currentChapter: Chapter?
		var currentScene: SubChapter?
		var prevBlockType = BookBlockType.unknown

		readAtTime = Date() // Any time a book is read from a source, mark time

		for block in blocks {
			switch block.type {
			case .title:
				let titleSubtitle = block.content.split(separator: ":")
				self.title = String(titleSubtitle[0])
				self.subtitle = titleSubtitle.count > 1 ? String(titleSubtitle[1]) : ""
			case .chapterTitle:
				// Starting a new chapter
				if var chapter = currentChapter {
					if let scene = currentScene {
						chapter.subchapters.append(scene)
						currentScene = nil
					}
					chapters.append(chapter)
				}
				currentChapter = Chapter()
				let titleSubtitle = block.content.split(separator: ":")
				currentChapter?.title = String(titleSubtitle[0])
				currentChapter?.subtitle = titleSubtitle.count > 1 ? String(titleSubtitle[1]) : ""
			case .header:
				if prevBlockType == .title {
					// This is a book header
					try parseHeader(json: block.content)
				}
				else {
					// This is a scene header. Starting new scene.
					assert(currentChapter != nil)
					if let scene = currentScene {
						currentChapter?.subchapters.append(scene)
					}
					currentScene = try SubChapter(withBlock: block)
				}
			case .paragraph:
				assert(currentScene != nil)
				currentScene?.paragraphs.append(block.content)
			default:
				// Unknown
				print("Unknown block found: \(block.content)")
			}
			prevBlockType = block.type
		}
		
		if currentScene != nil {
			currentChapter?.subchapters.append(currentScene!)
		}
		if currentChapter != nil {
			chapters.append(currentChapter!)
		}
		
		// Number chapters
		renumberChapters()
		
	}
	
	/**
	Sums the word counts in all chapters
	
	- Returns: word count for the book
	*/
	var wordCount: Int {
		var wc = 0
		for chapter in chapters {
			wc += chapter.wordCount
		}
		return wc
	}
	
	var startLineNumber = 1
	
	func lineNumberFor(chapter: Chapter) -> Int {
		var count = startLineNumber + 4 // for title, header
		for ch in chapters {
			if ch.id == chapter.id {
				break
			}
			count += ch.lineCount
		}
		return count
	}
	
	func lineNumberFor(subchapter: SubChapter) -> Int {
		var count = startLineNumber + 4 // for title, header
		for ch in chapters {
			if let idx = ch.indexOf(subchapter: subchapter) {
				count += 2
				for i in 0..<idx {
					count += ch.subchapters[i].lineCount
				}
				break
			}
			count += ch.lineCount
		}
		return count
	}
	
	var count: Int {
		var i = 0
		for chapter in chapters {
			i += 1
			i += chapter.subchapters.count
		}
		return i
	}
	
	var status: EditStatus {
		var chapterStatus = Set<EditStatus>()
		for chapter in chapters {
			chapterStatus.insert(chapter.status)
		}
		if chapterStatus.count == 1 {
			return chapterStatus.first!
		}
		return EditStatus.multiple
	}
	
	/**
	Convenience property joining the title and the (optional) subtitle
	
	- Returns: "title" or "title: subtitle"
	*/
	var titleSubtitle: String {
		if subtitle.trimmingCharacters(in: .whitespaces) == "" {
			return title
		}
		return "\(title): \(subtitle)"
	}

	/**
	 Subscript accessor for chapters and subchapters. First element at [0] is the first chapter,
	 The second element will be the first subchapter in the chapter, etc.
	 - Returns: Chapter or SubChapter if a valid index. nil if not.
	 */
	subscript(index: Int) -> Any? {
		get {
			var i = -1
			for c in chapters {
				i += 1
				if i == index {
					return c as Any
				}
				for sub in c.subchapters {
					i += 1
					if i == index {
						return sub as Any
					}
				}
			}
			return nil
		}
	}
	
	/**
	Convenience property for referencing `headerInfo.personas[Persona.MAJOR]`
	
	- Returns: array of Personas. Array is empty if there are no major personas in the book.
	*/
	var majorPersonas: [Persona] {
		get {
			if let personas = headerInfo.personas[Persona.MAJOR] {
				return personas
			}
			return [Persona]()
		}
		set {
			var h = headerInfo
			h.personas[Persona.MAJOR] = newValue
			self.headerInfo = h
		}
	}
    
    /**
    Convenience property for referencing `headerInfo.personas[Persona.MINOR]`
    
    - Returns: array of Personas. Array is empty if there are no minor personas in the book.
    */
    var minorPersonas: [Persona] {
		get {
			if let personas = headerInfo.personas[Persona.MINOR] {
				return personas
			}
			return [Persona]()
		}
		set {
			var h = headerInfo
			h.personas[Persona.MINOR] = newValue
			self.headerInfo = h
		}
    }
    
    /**
    Convenience property for getting all personas from `headerInfo.personas`
    
    - Returns: array of Personas. Array is empty if there are no personas in the book.
    */
    var allPersonas: [Persona] {
		get {
			var result = [Persona]()
			if let personas = headerInfo.personas[Persona.MAJOR] {
				result.append(contentsOf: personas)
			}
			if let personas = headerInfo.personas[Persona.MINOR] {
				result.append(contentsOf: personas)
			}
			return result
		}
	}
	
	/**
	Check if a given persona is considered major
	- Parameter persona: the persona to evaluate.
	*/
	func isMajor(persona: Persona) -> Bool {
		return majorPersonas.contains(where: { $0.id == persona.id })
	}

	/**
	 Iterates through all subchapters in the book, finding unique locations.
	 - Returns: array of Strings, sorted.
	 */
	var allLocations: [String] {
		var locs = Set<String>()
		for chapter in chapters {
			for sub in chapter.subchapters {
				locs.insert(sub.headerInfo.location)
			}
		}
		return locs.sorted()
	}
	
	/**
	Searches major and minor personas for name or alias matching `name`
	
	- Parameter name: the name to search for
	
	- Returns: Persona that matches `name` or nil if nothing matches
	*/
	func findPersona(named name: String) -> Persona? {
		var partialMatches = [Persona]()
		for p in majorPersonas + minorPersonas {
			if name == p.name || p.aliases.contains(name) {
				return p
			}
			else if name.contains(p.name) || p.name.contains(name) {
				partialMatches.append(p)
			}
		}
		return partialMatches.first
	}

	/**
	Search for which Chapter contains a given SubChapter
	
	- Parameter subchapter: the subchapter to search for. Must be equal.
	*/
	func chapterContaining(subchapter: SubChapter) -> Chapter? {
		for c in chapters {
			if c.subchapters.contains(where: { $0.id == subchapter.id }) {
				return c
			}
		}
		return nil
	}

	/**
	Search for SubChapter with id
	
	- Parameter id: the subchapter id to search for.
	*/
	func findSubChapter(id: String) -> SubChapter? {
		for c in chapters {
			if c.subchapters.contains(where: { $0.id == id }) {
				return c.subchapters.first(where: {$0.id == id})
			}
		}
		return nil
	}

	/**
	Renders the `Book` into logical `BookBlocks`, ready to write to markdown.
	
	- Throws: SBSError.cannotEncodeHeader
		if encoding the book header or any subchapter header fails
	
	- Returns: array of BookBlocks, in book order
	*/
	func toBlocks() throws -> [BookBlock] {
		// Title
		// Header
		// Chapters
			// Title
			// SubChapters
				// Header
				// Paragraphs
		let encoder = JSONEncoder()
		encoder.keyEncodingStrategy = .convertToSnakeCase
		//encoder.outputFormatting = .prettyPrinted
		
		var blocks = [BookBlock]()
		
		let titleBlock = BookBlock(type: .title, content: "\(title ):\(subtitle )")
		blocks.append(titleBlock)

		do {
			let data = try encoder.encode(headerInfo)
			let json = String(data: data, encoding: .utf8)!
			let headerBlock = BookBlock(type: .header, content: json)
			blocks.append(headerBlock)
			
			for chapter in chapters {
				let chTitleBlock = BookBlock(type: .chapterTitle, content: "\(chapter.title):\(chapter.subtitle)")
				blocks.append(chTitleBlock)
				for sub in chapter.subchapters {
					let subHeaderData = try encoder.encode(sub.headerInfo)
					let subJson = String(data: subHeaderData, encoding: .utf8)!
					let sceneHeaderBlock = BookBlock(type: .header, content: subJson)
					blocks.append(sceneHeaderBlock)
					
					for para in sub.paragraphs {
						let paraBlock = BookBlock(type: .paragraph, content: para)
						blocks.append(paraBlock)
					}
				}
			}
		}
		catch {
			throw SBSError.cannotEncodeHeader
		}
		
		return blocks
	}
	
	/**
	Renders the book as markdown text
	
	Throws: SBSError.cannotEncodeHeader
		if the book or subchapter headers can't be JSON encoded.
	
	Returns: String containing markdown text
	*/
	func toMarkdown() throws -> String {
		let blocks = try toBlocks()
		let markdowns = blocks.map { $0.markdown }
		return markdowns.joined(separator: "\n\n")
	}
	
	/**
	Combines all chapters into a single Markdown string, suitable
	for printing. Metadata is stripped and breaks are added between SubChapters.
	
	Returns: Printable markdown string
	*/
	func compile() -> String {
		var markdownContent = [
			"# \(self.title)",
			"\(self.subtitle)",
			"©\(self.headerInfo.author), \(self.headerInfo.author)"]
		for chapter in self.chapters {
			markdownContent.append(contentsOf: chapter.compile())
		}

		return markdownContent.joined(separator: "\n\n")
	}
	
	/**
	Resets the number property on each `Chapter` in `chapters`, starting at 1
	*/
	private func renumberChapters() {
		if chapters.count > 0 {
			for i in 1...chapters.count {
				chapters[i-1].number = i
			}
		}
	}
	
	/**
	Adds `chapter` to the end of the book if no index provided, or
	inserts at `index` if `index` is valid for `self.chapters`
	Renumbers the chapters after the action.

	- Parameter chapter: the `Chapter` to add to the `Book`
	- Parameter index: optional index to insert at. Otherwise, appended to end.
	*/
	public func add(chapter: Chapter, at index:Int? = nil) {
		if let i = index {
			if (0...chapters.count).contains(i) {
				chapters.insert(chapter, at: i)
			}
		}
		else {
			self.chapters.append(chapter)
		}
		renumberChapters()
	}
	
	/**
	Moves the chapter from the book from `fromIndex` to `toIndex`
	Renumbers the chapters after the action.
	Takes no action if `fromIndex` or `toIndex` is invalid.
	
	- Parameter fromIndex: the index of the chapter to move
	- Parameter toIndex: the index to move the chapter to
	*/
	public func reorderChapter(fromIndex: Int, toIndex: Int) {
		guard (0..<chapters.count).contains(fromIndex) && (0..<chapters.count).contains(toIndex) else {
			print("fromIndex or toIndex was out of range.")
			return
		}
		var arr = chapters
		let c = arr.remove(at: fromIndex)
		arr.insert(c, at: toIndex)
		chapters = arr
		renumberChapters()
	}
    
    /**
     Returns the index of chapter in the book, based on id. If  id does not exist,
     returns nil.
     
     - Parameter toFind: the chapter to find
     - Returns: index of the chapter in the book, nil if not found
     */
    public func indexOf(chapter toFind: Chapter) -> Int? {
        for i in 0..<chapters.count {
            if chapters[i].id == toFind.id {
                return i
            }
        }
        return nil
    }
	
	/**
	Removes the chapter from the book at `index`
	Renumbers the chapters after the action.
	Takes no action if `index` is invalid.
	
	- Parameter index: the index of the chapter to remove from `chapters`
	*/
	public func removeChapter(at index: Int) {
		guard (0..<chapters.count).contains(index) else {
			print("index was out of range.")
			return
		}
		let _ = chapters.remove(at: index)
		renumberChapters()
	}
	
	/**
	Replaces the chapter from the book identified by the same id
	Renumbers the chapters after the action.
	Takes no action if no chapter in the book has the same id.
	
	- Parameter chapter: the revised Chapter
	*/
	public func replace(chapter: Chapter) {
		for (index, ch) in chapters.enumerated() {
			if ch.id == chapter.id {
				chapters[index] = chapter
				break
			}
		}
		renumberChapters()
	}
	
	/**
	Checks the file modification date against readAtTime.
	
	- Throws: `SBSError.fileNotFound`
	
	- Returns: `true` if the file modification date is newer than readAtTime
	*/
	public func isFileUpdatedSinceRead() throws -> Bool {
		guard sourceFile != nil else {
			return false
		}
		do {
			let attrs = try FileManager.default.attributesOfItem(atPath: sourceFile!.path)
			let mDate = attrs[FileAttributeKey.modificationDate] as! Date
			return mDate > readAtTime
		}
		catch {
			throw SBSError.fileNotFound
		}
	}
	
	/**
	Parses the JSON book header
	
	- Throws: `SBSError.invalidBookHeader` if it cannot be decoded
	
	- Parameter json: JSON-formatted string compatible with decoding to `BookHeader`
	*/
	private func parseHeader(json: String) throws {
		let jsonData = json.data(using: .utf8)!
		do {
			let header: BookHeader = try JSONDecoder().decode(BookHeader.self, from: jsonData)
			self.headerInfo = header
		}
		catch {
			throw SBSError.invalidBookHeader
		}
	}
}

struct BookHeader: Codable, Equatable {
	static func == (lhs: BookHeader, rhs: BookHeader) -> Bool {
		return lhs.author == rhs.author &&
			lhs.year == rhs.year &&
			lhs.keywords == rhs.keywords &&
			lhs.genres == rhs.genres &&
			lhs.personas == rhs.personas
	}
	
	enum CodingKeys: String, CodingKey {
		case author, year, keywords, genres
		case personas = "characters"
	}
	
	var author: String = ""
	var year: String = "\(Calendar.current.component(.year, from: Date()))"
	var personas = Dictionary<String, [Persona]>()
	
	var genreIndex: Int {
		get {
			return genre.index!
		}
		set {
			genre = Genre.allCases[newValue]
		}
	}
	var genre: Genre {
		get {
			return genres.first != nil ? genres.first! : .fantasy
		}
		set {
			genres = [newValue]
		}
	}
	var genres = [Genre]()

	var joinedKeywords: String {
		get {
			return keywords.joined(separator: ", ")
		}
		set {
			self.keywords = _keywordsToArray(csv: newValue)
		}
	}

	private func _keywordsToArray(csv: String) -> [String] {
		let s = csv.replacingOccurrences(of: ", *", with: ",", options: .regularExpression, range: nil)
		let kw: [String] = s.split(separator: ",").map {String($0)}
		return kw
	}
	
	var keywords = [String]()
}
