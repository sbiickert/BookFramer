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
	
	var book: Book? {
		didSet {
			needsCompile = true
			updateUI()
		}
	}
	
	var selectedPart: Any? {
		didSet {
			needsCompile = true
			updateUI()
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
		//textView.usesInspectorBar = false
		
		textView.font = NSFont(name: "Times New Roman", size: 16)
		
		let titlePS = NSMutableParagraphStyle()
		titlePS.paragraphSpacing = 16.0
		titleAttributes = AttributeContainer()
		titleAttributes.font = textView.font?.bolded()?.resized(to: 20)
		titleAttributes.paragraphStyle = titlePS
		
		let subtitlePS = NSMutableParagraphStyle()
		subtitlePS.paragraphSpacing = 16.0
		subtitleAttributes = AttributeContainer()
		subtitleAttributes.font = textView.font?.bolded()?.resized(to: 18)
		subtitleAttributes.paragraphStyle = subtitlePS
		
		let ps = NSMutableParagraphStyle()
		ps.firstLineHeadIndent = 32.0
		ps.paragraphSpacing = 16.0
		paragraphAttributes = AttributeContainer()
		paragraphAttributes.font = textView.font
		paragraphAttributes.paragraphStyle = ps
    }
	
	override func viewDidAppear() {
		super.viewDidAppear()
		// The view.window isn't non-nil until after the view appears
		updateUI()
	}
	
	
	override func bookEdited(notification: Notification) {
		needsCompile = true
		updateUI()
	}

	// Set when book is edited or context changes
	private var needsCompile = true

	override func updateUI() {
		super.updateUI()
		if view.window != nil && needsCompile {
			compilePreview()
			needsCompile = false
		}
	}
	
	private func compilePreview() {
		var mdParts: [String]?
		if let sub = selectedPart as? SubChapter {
			mdParts = sub.compile()
		}
		else if let ch = selectedPart as? Chapter {
			mdParts = ch.compile()
			mdParts!.removeFirst() // the first thing is the LaTeX \newpage
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
				else {
					do {
						var aString = try AttributedString(markdown: part, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnly))
						aString.setAttributes(paragraphAttributes)
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
}
