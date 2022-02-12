//
//  PreviewVC.swift
//  BookFramer
//
//  Created by Simon Biickert on 2022-01-25.
//

import Cocoa

class PreviewVC: BFViewController {
	@IBOutlet var textView: NSTextView!

	var titleAttributes: AttributeContainer!
	var subtitleAttributes: AttributeContainer!
	var paragraphAttributes: AttributeContainer!
	
	private var _observersAdded = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
		//textView.usesInspectorBar = false
		
		textView.font = NSFont(name: "Times New Roman", size: 16)
		
		let titlePS = NSMutableParagraphStyle()
		titlePS.paragraphSpacing = 16.0
		titleAttributes = AttributeContainer()
		titleAttributes.font = textView.font?.bolded()?.resized(to: 20)
		titleAttributes.foregroundColor = NSColor.controlTextColor
		titleAttributes.paragraphStyle = titlePS
		
		let subtitlePS = NSMutableParagraphStyle()
		subtitlePS.paragraphSpacing = 16.0
		subtitleAttributes = AttributeContainer()
		subtitleAttributes.font = textView.font?.bolded()?.resized(to: 18)
		subtitleAttributes.foregroundColor = NSColor.controlTextColor
		subtitleAttributes.paragraphStyle = subtitlePS
		
		let ps = NSMutableParagraphStyle()
		ps.firstLineHeadIndent = 32.0
		ps.paragraphSpacing = 16.0
		paragraphAttributes = AttributeContainer()
		paragraphAttributes.font = textView.font
		paragraphAttributes.foregroundColor = NSColor.controlTextColor
		paragraphAttributes.paragraphStyle = ps
	}
	
	override func viewDidAppear() {
		super.viewDidAppear()
		// The view.window isn't non-nil until after the view appears
		
		if _observersAdded == false {
			assert(document != nil)
			document?.notificationCenter.addObserver(self, selector: #selector(contextChanged(notification:)), name: .contextDidChange, object: nil)
			_observersAdded = true
		}

		updateUI()
	}
	
	
	override func bookEdited(notification: Notification) {
		needsCompile = true
		updateUI()
	}
	
	@objc func contextChanged(notification: Notification) {
		needsCompile = true
		updateUI()
	}

	// Set when book is edited or context changes
	private var needsCompile = true

	override func updateUI() {
		super.updateUI()
		if #available(macOS 10.14, *) {
			textView.appearance = NSAppearance.currentDrawing()
		}
		if view.window != nil && needsCompile {
			compilePreview()
			needsCompile = false
		}
	}
	
	private func compilePreview() {
		var mdParts: [String]?
		if let context = context {
			if let sub = context.selectedPart as? SubChapter {
				mdParts = sub.compile()
			}
			else if let ch = context.selectedPart as? Chapter {
				mdParts = ch.compile()
				mdParts!.removeFirst() // the first thing is the LaTeX \newpage
			}
		}
//		else if let b = selectedPart as? Book {
//			// Book
//			md = b.compile()
//		}
		if let mdParts = mdParts {
			var aStrings = [NSAttributedString]()
			for part in mdParts {
				// Each part is a string that contains one of:
				// Chapter title, prefixed with ##
				// Chapter subtitle, prefixed with ###
				// Scene break, ***
				// Paragraph, containing inline markdown text
				if part.starts(with: "## ") {
					let aString = AttributedString(part.dropFirst(3), attributes: titleAttributes)
					aStrings.append(NSAttributedString(aString))
				}
				else if part.starts(with: "### ") {
					let aString = AttributedString(part.dropFirst(4), attributes: subtitleAttributes)
					aStrings.append(NSAttributedString(aString))
				}
				else if part.starts(with: "***") {
					let aString = AttributedString(part, attributes: paragraphAttributes)
					aStrings.append(NSAttributedString(aString))
				}
				else {
					do {
						var aString = try AttributedString(markdown: part, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnly))
						// To not eliminate italics, can't just setAttributes:
						aString.mergeAttributes(paragraphAttributes)

						// Need to remove _ and * from part, b/c the AttributedString lost them
						var plain = part.replacingOccurrences(of: "*", with: "")
						plain = plain.replacingOccurrences(of: "_", with: "")
						
						// Grammar highlighting
						let adverbs = BookAnalytics.tagAdverbs(in: plain)
						let sentences = BookAnalytics.tokens(in: plain, unit: .sentence)
						for sentence in sentences {
							let fres = BookAnalytics.calculateFleschReadingEaseScore(text: sentence)
							let difficulty = BookAnalytics.classifyFRES(score: fres)
							let passiveVoiceRange = BookAnalytics.tagPassiveVoice(in: sentence)
							
							if let sRange = aString.range(of: sentence) {
								if difficulty == .veryHard {
									aString[sRange].backgroundColor = HighlightType.veryHard.color
								}
								else if difficulty == .hard {
									aString[sRange].backgroundColor = HighlightType.hard.color
								}
								if let passiveVoiceRange = passiveVoiceRange {
									// passiveVoiceRange is a range in sentence. Need to translate to aString.
									let lower = aString.index(sRange.lowerBound, offsetByCharacters: passiveVoiceRange.lowerBound.utf16Offset(in: sentence))
									let upper = aString.index(sRange.lowerBound, offsetByCharacters: passiveVoiceRange.upperBound.utf16Offset(in: sentence))
									let range = lower..<upper
									aString[range].backgroundColor = HighlightType.passive.color
								}
								for adverb in adverbs {
									// adverb is a range in plain. Need to translate to aString.
									//print("\(plain[adverb])")
									var offset = adverb.lowerBound.utf16Offset(in: plain)
									let lower = aString.index(aString.startIndex, offsetByCharacters: offset)
									offset = adverb.upperBound.utf16Offset(in: plain)
									//offset = min(offset, aString.characters.count)
									let upper = aString.index(aString.startIndex, offsetByCharacters: offset)
									let range = lower..<upper
									aString[range].backgroundColor = HighlightType.adverb.color
								}
							}
						}
						aStrings.append(NSAttributedString(aString))
					} catch {
						aStrings.append(NSAttributedString(string: "Error compiling: \(error)"))
					}
				}
			}
			
			let compiled = NSMutableAttributedString("\n")
			for aString in aStrings {
				compiled.append(aString)
				compiled.append(NSAttributedString("\n"))
			}
			textView.textStorage?.setAttributedString(compiled)
		}
		else {
			textView.string = ""
		}
	}
	
	enum HighlightType {
		case veryHard
		case hard
		case passive
		case adverb
		
		var color: NSColor {
			switch self {
			case .veryHard:
				// Reddish
				return NSColor.init(named: "GrammarVHard") ?? NSColor.magenta
			case .hard:
				// Yellow
				return NSColor.init(named: "GrammarHard") ?? NSColor.magenta
			case .passive:
				// Green
				return NSColor.init(named: "GrammarPassive") ?? NSColor.magenta
			case .adverb:
				// Blue
				return NSColor.init(named: "GrammarAdverb") ?? NSColor.magenta
			}
		}
	}
}
