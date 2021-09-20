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
	
	override func updateUI() {
		tableView.reloadData()
	}

	private enum EditAction {
		case create
		case update
		case delete
	}
	
	private func actionsForSelectedRow() -> [EditAction] {
		return actionsFor(row: tableView.selectedRow)
	}
	private func actionsFor(row: Int) -> [EditAction] {
		guard personas != nil else {
			return []
		}
		if row == -1 {
			return []
		}
		if row < personas!.count {
			return [.update, .delete]
		}
		return [.create]
	}
	
	@IBAction func importanceChanged(_ sender: NSButton) {
		updatePersona(at: tableView.row(for: sender))
	}
	@IBAction func nameChanged(_ sender: NSTextField) {
		updatePersona(at: tableView.selectedRow)
	}
	@IBAction func aliasesChanged(_ sender: NSTextField) {
		updatePersona(at: tableView.selectedRow)
	}
	@IBAction func descriptionChanged(_ sender: NSTextField) {
		updatePersona(at: tableView.selectedRow)
	}
	
	private func updatePersona(at row: Int) {
		guard book != nil && personas != nil && row > -1 else {
			return
		}
		var majorPersonas = personas!.filter { book!.isMajor(persona: $0) }
		var minorPersonas = personas!.filter { book!.isMajor(persona: $0) == false }
		let availableActions = actionsFor(row: row)
		
		if let idxColType = tableView.tableColumns.firstIndex(of: colType),
		   let checkbox = (tableView.view(atColumn: idxColType, row: row, makeIfNecessary: false) as? CheckboxTableCellView)?.checkbox,
		   let idxColName = tableView.tableColumns.firstIndex(of: colName),
		   let nameField = (tableView.view(atColumn: idxColName, row: row, makeIfNecessary: false) as? NSTableCellView)?.textField,
		   let idxColAlias = tableView.tableColumns.firstIndex(of: colAliases),
		   let aliasField = (tableView.view(atColumn: idxColAlias, row: row, makeIfNecessary: false) as? NSTableCellView)?.textField,
		   let idxColDesc = tableView.tableColumns.firstIndex(of: colDescription),
		   let descField = (tableView.view(atColumn: idxColDesc, row: row, makeIfNecessary: false) as? NSTableCellView)?.textField {
			
			let isMajor = checkbox.state == .on
			
			if availableActions.contains(.create) {
				// This is a new persona
				var p = Persona(name: nameField.stringValue, description: descField.stringValue, aliases: [])
				p.joinedAliases = aliasField.stringValue
				if isMajor {
					majorPersonas.append(p)
				}
				else {
					minorPersonas.append(p)
				}
				setPersonas(major: majorPersonas, minor: minorPersonas)
			}
			else if availableActions.contains(.update) {
				var p = personas![row]
				p.name = nameField.stringValue
				p.joinedAliases = aliasField.stringValue
				p.description = descField.stringValue
				let wasMajor = book!.isMajor(persona: p)
				
				if wasMajor {
					if let idx = majorPersonas.firstIndex(where: {$0.id == p.id}) {
						majorPersonas.remove(at: idx)
						if isMajor {
							majorPersonas.insert(p, at: idx)
						}
						else {
							minorPersonas.append(p)
						}
					}
				}
				else {
					if let idx = minorPersonas.firstIndex(where: {$0.id == p.id}) {
						minorPersonas.remove(at: idx)
						if isMajor {
							majorPersonas.append(p)
						}
						else {
							minorPersonas.insert(p, at: idx)
						}
					}
				}
				setPersonas(major: majorPersonas, minor: minorPersonas)
			}
		}
	}

	@IBAction func delete(_ sender: AnyObject) {
		print("Delete pressed")
		if actionsForSelectedRow().contains(.delete) {
			deletePersona(at: tableView.selectedRow)
		}
	}
	
	private func deletePersona(at row:Int) {
		print("Delete persona at row \(row)")
		let availableActions = actionsFor(row: row)
		guard book != nil && personas != nil && availableActions.contains(.delete) else {
			return
		}
		
		let pToDelete = personas![row]
		// Using filter to remove the persona. Simple!
		let majorPersonas = personas!.filter { book!.isMajor(persona: $0) && $0.id != pToDelete.id }
		let minorPersonas = personas!.filter { book!.isMajor(persona: $0) == false && $0.id != pToDelete.id }
		
		setPersonas(major: majorPersonas, minor: minorPersonas)
	}
	
	private func setPersonas(major: [Persona], minor: [Persona]) {
		guard book != nil && personas != nil else {
			return
		}
		let oldMajor = book!.majorPersonas
		let oldMinor = book!.minorPersonas
		undoManager?.beginUndoGrouping()
		undoManager?.registerUndo(withTarget: self) {
			$0.setPersonas(major: oldMajor, minor: oldMinor)
			self.document?.notificationCenter.post(name: .bookEdited, object: [oldMajor])
		}
		book!.majorPersonas = major
		book!.minorPersonas = minor
		undoManager?.endUndoGrouping()
		self.document?.notificationCenter.post(name: .bookEdited, object: [major])
		self.book = book!
	}
}

extension PersonasDetailVC: NSTableViewDelegate {
	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		return 24.0
	}
	
	// TODO: disabling menu item not working at the moment
	func tableViewSelectionDidChange(_ notification: Notification) {
//		if let editMenu = NSApplication.shared.menu?.item(withTitle: "Edit"),
//		   let deleteMenuItem = editMenu.submenu?.item(withTitle: "Delete") {
//			deleteMenuItem.isEnabled = actionsForSelectedRow().contains(.delete) ? true : false
//			print("Delete menu isEnabled: \(deleteMenuItem.isEnabled)")
//		}
	}
	
	func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
		switch edge {
		case .trailing:
			if row == personas?.count ?? -1 {
				// Don't want a row action for the new persona row
				return []
			}
			let deleteAction = NSTableViewRowAction(style: .destructive, title: "Delete") { action, row in
				self.deletePersona(at: row)
			}
			return [deleteAction]
		default:
			return []
		}
	}
}

extension PersonasDetailVC: NSTableViewDataSource {
	func numberOfRows(in tableView: NSTableView) -> Int {
		// Returns one extra row for adding a new persona
		return (self.personas?.count ?? 0) + 1
	}
	
	func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		let availableActions = actionsFor(row: row)
		guard availableActions.isEmpty == false else {
			return nil
		}
		if availableActions.contains(.create)  {
			// This is the extra row for adding a new persona
			// Maybe could return nil instead?
			return Persona(name: "", description: "", aliases: [])
		}
		return self.personas![row]
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		var cellView: NSTableCellView?
		
		if let persona = self.tableView(tableView, objectValueFor: nil, row: row) as? Persona {
			if tableColumn == colType {
				let cbView = tableView.makeView(withIdentifier: .personaImportance, owner: self) as? CheckboxTableCellView
				let isMajor = book!.isMajor(persona: persona)
				cbView?.checkbox?.state = isMajor ? .on : .off
				cellView = cbView
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
