//
//  PersonasDetailVC.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-24.
//

import Cocoa

class PersonasDetailVC: BFViewController {
	private var _observersAdded = false
	var book: Book? {
		didSet {
			if _observersAdded == false {
				document?.notificationCenter.addObserver(self, selector: #selector(addPersona(notification:)), name: .addPersona, object: nil)
				document?.notificationCenter.addObserver(self, selector: #selector(search(notification:)), name: .search, object: nil)
				_observersAdded = true
			}
			updateUI()
		}
	}
	
	// Keep a mutable copy for sorting
	var personas: [Persona]?

	@IBOutlet weak var tableView: NSTableView!
	@IBOutlet weak var colName: NSTableColumn!
	
	@IBOutlet weak var addButton: NSButton!
	@IBOutlet weak var removeButton: NSButton!
	
	@IBOutlet weak var nameField: NSTextField!
	@IBOutlet weak var aliasesField: NSTextField!
	@IBOutlet weak var descriptionField: NSTextField!
	@IBOutlet weak var importanceCheckbox: NSButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
		tableView.delegate = self
		tableView.dataSource = self
				
		// Create sort descriptors
		let descriptorName = NSSortDescriptor(key: "name", ascending: true)

		colName.sortDescriptorPrototype = descriptorName
    }
	
	private var retainSelectedID: String?
	override func updateUI() {
		// Refresh local copy of the personas
		personas = book?.allPersonas
		
		tableView.reloadData()
		if let id = retainSelectedID,
		   let idx = personas?.firstIndex(where: {$0.id == id}) {
			let indexSet = IndexSet(integer: idx)
			tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
		}
		retainSelectedID = nil
		
		updatePersonaForm()
	}
	
	@objc func search(notification: Notification) {
		if let searchText = notification.object as? String,
		   let personas = personas {
			let lowerSearchText = searchText.localizedLowercase
			var firstRow: Int?
			var lastRow: Int?
			for (i, p) in personas.enumerated() {
				let rowView = tableView.rowView(atRow: i, makeIfNecessary: true)
				if p.name.localizedLowercase.contains(lowerSearchText)
					|| p.joinedAliases.localizedLowercase.contains(lowerSearchText) {
					//|| p.description.contains(searchText) {
					rowView?.backgroundColor = NSColor.findHighlightColor
					if firstRow == nil {
						firstRow = i
					}
					lastRow = i
				}
				else {
					rowView?.backgroundColor = NSColor.controlBackgroundColor
				}
			}
			if lastRow != nil {
				tableView.scrollRowToVisible(lastRow!)
			}
			if firstRow != nil {
				tableView.scrollRowToVisible(firstRow!)
			}
		}
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
	
	@IBAction func newPersona(_ sender: Any) {
		// Calls addPersona(notification:) below
		document?.notificationCenter.post(name: .addPersona, object: nil)
	}
	@IBAction func deletePersona(_ sender: Any) {
		// This should probably be removed, and the button connected to "delete" below
		if actionsForSelectedRow().contains(.delete) {
			deletePersona(at: tableView.selectedRow)
		}
	}
	
	@IBAction func importanceChanged(_ sender: NSButton) {
		updatePersona(at: tableView.selectedRow)
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
	
	@objc func addPersona(notification: Notification) {
		guard book != nil else { return }
		let p = Persona(name: "New Character", description: "", aliases: [])
		var major = book!.majorPersonas
		let minor = book!.minorPersonas
		major.append(p)
		retainSelectedID = p.id
		setPersonas(major: major, minor: minor)
	}
	
	private func updatePersona(at row: Int) {
		guard book != nil && personas != nil && row > -1 else {
			return
		}
		var majorPersonas = personas!.filter { book!.isMajor(persona: $0) }
		var minorPersonas = personas!.filter { book!.isMajor(persona: $0) == false }
					
		let isMajor = importanceCheckbox.state == .on
			
		var p = personas![row]
		p.name = nameField.stringValue
		p.joinedAliases = aliasesField.stringValue
		p.description = descriptionField.stringValue
		
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
		retainSelectedID = p.id
		setPersonas(major: majorPersonas, minor: minorPersonas)
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
	}
}

extension PersonasDetailVC: NSTableViewDelegate {
	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		return 18.0
	}
	
	func tableViewSelectionDidChange(_ notification: Notification) {
		updatePersonaForm()
	}
	
	func updatePersonaForm() {
		if let tableView = tableView,
		   let personas = personas,
		   tableView.selectedRow >= 0 {
			let p = personas[tableView.selectedRow]
			nameField.isEnabled = true
			aliasesField.isEnabled = true
			descriptionField.isEnabled = true
			importanceCheckbox.isEnabled = true
			
			nameField.stringValue = p.name
			aliasesField.stringValue = p.joinedAliases
			descriptionField.stringValue = p.description
			importanceCheckbox.state = (book!.isMajor(persona: p)) ? .on : .off
		}
		else {
			nameField.isEnabled = false
			aliasesField.isEnabled = false
			descriptionField.isEnabled = false
			importanceCheckbox.isEnabled = false
			
			nameField.stringValue = ""
			aliasesField.stringValue = ""
			descriptionField.stringValue = ""
			importanceCheckbox.state = .off
		}
	}
	
	func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
		switch edge {
		case .trailing:
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
		return (self.personas?.count ?? 0)
	}
	
	func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		let availableActions = actionsFor(row: row)
		guard availableActions.isEmpty == false else {
			return nil
		}
		return self.personas![row]
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		var cellView: NSTableCellView?
		
		if let persona = self.tableView(tableView, objectValueFor: nil, row: row) as? Persona {
			let isMajor = book!.isMajor(persona: persona)
			if tableColumn == colName {
				cellView = tableView.makeView(withIdentifier: .personaName, owner: self) as? NSTableCellView
				cellView?.textField?.stringValue = "\(isMajor ? "+" : "-") \(persona.name)"
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
		func sortByName(lhs: Persona, rhs: Persona) -> Bool {
			if sortDescriptor.ascending {
				return lhs.name < rhs.name
			}
			return lhs.name > rhs.name
		}
		
		// Sort
		self.personas?.sort(by: sortByName(lhs:rhs:))
		tableView.reloadData()

	}
}

extension NSUserInterfaceItemIdentifier {
	static let personaName = NSUserInterfaceItemIdentifier(rawValue: "PersonaName")
}
