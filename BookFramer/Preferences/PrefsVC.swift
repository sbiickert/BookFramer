//
//  PrefsVC.swift
//  BookFramer
//
//  Created by Simon Biickert on 2022-02-11.
//

import Cocoa

class PrefsVC: NSViewController {

	@IBOutlet weak var bbEditField: NSTextField!
	@IBOutlet weak var pandocField: NSTextField!
	@IBOutlet weak var pdflatexField: NSTextField!
	
	@IBOutlet weak var bbeditStatus: NSTextField!
	@IBOutlet weak var pandocStatus: NSTextField!
	@IBOutlet weak var pdflatexStatus: NSTextField!
	
	@IBAction func bbEditChanged(_ sender: Any) {
		defaults.set(bbEditField.stringValue, forKey: DefaultNames.bbedit)
	}
	@IBAction func pandocChanged(_ sender: Any) {
		defaults.set(pandocField.stringValue, forKey: DefaultNames.pandoc)
	}
	@IBAction func pdflatexChanged(_ sender: Any) {
		defaults.set(pdflatexField.stringValue, forKey: DefaultNames.pdflatex)
	}
	
	@IBAction func testBBEdit(_ sender: Any) {
		bbEditChanged(self)
		if let file = defaults.string(forKey: DefaultNames.bbedit) {
			bbeditStatus.stringValue = FileManager.default.fileExists(atPath: file) ? TestResult.ok : TestResult.fail
		}
	}
	
	@IBAction func testPandoc(_ sender: Any) {
		pandocChanged(self)
		if let file = defaults.string(forKey: DefaultNames.pandoc) {
			pandocStatus.stringValue = FileManager.default.fileExists(atPath: file) ? TestResult.ok : TestResult.fail
		}
	}
	
	@IBAction func testPDFLatex(_ sender: Any) {
		pdflatexChanged(self)
		if let file = defaults.string(forKey: DefaultNames.pdflatex) {
			pdflatexStatus.stringValue = FileManager.default.fileExists(atPath: file) ? TestResult.ok : TestResult.fail
		}
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		self.preferredContentSize = NSMakeSize(self.view.frame.size.width,
											   self.view.frame.size.height)
        
		updateUI()
    }
	
	private func updateUI() {
		bbEditField.stringValue = defaults.string(forKey: DefaultNames.bbedit) ?? ""
		pandocField.stringValue = defaults.string(forKey: DefaultNames.pandoc) ?? ""
		pdflatexField.stringValue = defaults.string(forKey: DefaultNames.pdflatex) ?? ""
		
		bbeditStatus.stringValue = TestResult.unknown
		pandocStatus.stringValue = TestResult.unknown
		pdflatexStatus.stringValue = TestResult.unknown
	}

	// MARK: Accessing defaults
	
	struct DefaultNames {
		static let bbedit = "BBEditPath"
		static let pandoc = "PandocPath"
		static let pdflatex = "PDFLatexPath"
	}
	
	struct TestResult {
		static let unknown = "❓"
		static let ok = "✅"
		static let fail = "❌"
	}
	
	var defaults: UserDefaults {
		return UserDefaults.standard
	}

}
