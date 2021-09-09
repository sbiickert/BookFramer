//
//  PersonasDetailVC.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-24.
//

import Cocoa

class PersonasDetailVC: BFViewController {
	var book: Book? {
		didSet {
			self.personas = book?.allPersonas
		}
	}
	
	var personas: [Persona]? {
		didSet {
			updateUI()
		}
	}

	@IBOutlet weak var tableView: NSTableView!
	@IBOutlet weak var colType: NSTableColumn!
	@IBOutlet weak var colName: NSTableColumn!
	@IBOutlet weak var colAliases: NSTableColumn!
	@IBOutlet weak var colDescription: NSTableColumn!
	
	override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
		tableView.delegate = self
		tableView.dataSource = self
		
		// Create sort descriptors
		let descriptorImportance = NSSortDescriptor(key: "importance", ascending: true)
		let descriptorName = NSSortDescriptor(key: "name", ascending: true)
		let descriptorDesc = NSSortDescriptor(key: "description", ascending: true)
		let descriptorAliases = NSSortDescriptor(key: "aliases", ascending: true)

		colType.sortDescriptorPrototype = descriptorImportance
		colName.sortDescriptorPrototype = descriptorName
		colDescription.sortDescriptorPrototype = descriptorDesc
		colAliases.sortDescriptorPrototype = descriptorAliases
    }
	
	private func updateUI() {
		tableView.reloadData()
	}

}

extension PersonasDetailVC: NSTableViewDelegate {
	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		return 24.0
	}
}

extension PersonasDetailVC: NSTableViewDataSource {
	func numberOfRows(in tableView: NSTableView) -> Int {
		return book?.allPersonas.count ?? 0
	}
	
	func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		guard row >= 0 && row < (self.personas?.count ?? 0) else {
			return nil
		}
		return self.personas![row]
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		var cellView: NSTableCellView?
		
		if let persona = self.tableView(tableView, objectValueFor: nil, row: row) as? Persona {
			if tableColumn == colType {
				cellView = tableView.makeView(withIdentifier: .personaImportance, owner: self) as? NSTableCellView
				let isMajor = book!.isMajor(persona: persona)
				let image = isMajor ? Persona.MAJOR_IMAGE : Persona.MINOR_IMAGE
				cellView?.imageView?.contentTintColor = isMajor ? .black : .gray
				cellView?.imageView?.image = image
			}
			if tableColumn == colName {
				cellView = tableView.makeView(withIdentifier: .personaName, owner: self) as? NSTableCellView
				cellView?.textField?.stringValue = persona.name
			}
			if tableColumn == colAliases {
				cellView = tableView.makeView(withIdentifier: .personaAliases, owner: self) as? NSTableCellView
				cellView?.textField?.stringValue = persona.joinedAliases
			}
			if tableColumn == colDescription {
				cellView = tableView.makeView(withIdentifier: .personaDescription, owner: self) as? NSTableCellView
				cellView?.textField?.stringValue = persona.description

			}
		}
		
		return cellView
	}
	
	func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
		// Array of NSSortDescriptor. The most recent column clicked on is first.
		guard let sortDescriptor = tableView.sortDescriptors.first else {
			tableView.reloadData()
			return
		}

		// Sort functions
		func sortByImportance(lhs: Persona, rhs: Persona) -> Bool {
			let lhsIsMajor = book?.isMajor(persona: lhs)
			let rhsIsMajor = book?.isMajor(persona: rhs)
			if sortDescriptor.ascending {
				return lhsIsMajor == false && lhsIsMajor != rhsIsMajor
			}
			return lhsIsMajor == true && lhsIsMajor != rhsIsMajor
		}
		func sortByName(lhs: Persona, rhs: Persona) -> Bool {
			if sortDescriptor.ascending {
				return lhs.name < rhs.name
			}
			return lhs.name > rhs.name
		}
		func sortByAliases(lhs: Persona, rhs: Persona) -> Bool {
			if sortDescriptor.ascending {
				return lhs.joinedAliases < rhs.joinedAliases
			}
			return lhs.joinedAliases > rhs.joinedAliases
		}
		func sortByDesc(lhs: Persona, rhs: Persona) -> Bool {
			if sortDescriptor.ascending {
				return lhs.description < rhs.description
			}
			return lhs.description > rhs.description
		}
		
		// Sort
		switch sortDescriptor.key {
		case "importance":
			self.personas?.sort(by: sortByImportance(lhs:rhs:))
		case "name":
			self.personas?.sort(by: sortByName(lhs:rhs:))
		case "aliases":
			self.personas?.sort(by: sortByAliases(lhs:rhs:))
		default:
			self.personas?.sort(by: sortByDesc(lhs:rhs:))
		}
		tableView.reloadData()

	}
}

extension NSUserInterfaceItemIdentifier {
	static let personaImportance = NSUserInterfaceItemIdentifier(rawValue: "PersonaImportance")
	static let personaName = NSUserInterfaceItemIdentifier(rawValue: "PersonaName")
	static let personaAliases = NSUserInterfaceItemIdentifier(rawValue: "PersonaAliases")
	static let personaDescription = NSUserInterfaceItemIdentifier(rawValue: "PersonaDescription")
}
