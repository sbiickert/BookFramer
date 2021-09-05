//
//  ChaptersDetailVC.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-24.
//

import Cocoa

class ChaptersDetailVC: BFViewController {
    
    var book: Book? {
        didSet {
            updateUI()
        }
    }
    
    @IBOutlet weak var tableView: NSTableView!
    
    @IBOutlet weak var colStatus: NSTableColumn!
    @IBOutlet weak var colInfo: NSTableColumn!
    @IBOutlet weak var colPOV: NSTableColumn!
    @IBOutlet weak var colLocation: NSTableColumn!
    @IBOutlet weak var colWords: NSTableColumn!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        tableView.delegate = self
        tableView.dataSource = self
        tableView.doubleAction = #selector(tableViewWasDoubleClicked)
        tableView.registerForDraggedTypes([.tableViewIndex])
    }
    
    private func updateUI() {
        tableView.reloadData()
    }
    
    @objc func tableViewWasDoubleClicked() {
        //print("Double click on row \(tableView.clickedRow) and column \(tableView.clickedColumn)")
        guard tableView.clickedRow >= 0 else {
            return // click on header
        }
        if let rowObject = objectFor(row: tableView.clickedRow) {
            if let sub = rowObject as? SubChapter {
                // Double click on scene
                document?.notificationCenter.post(name: .selectedItemDidChange, object: sub)
            }
            else if let ch = rowObject as? Chapter {
                // Double click on chapter
                document?.notificationCenter.post(name: .selectedItemDidChange, object: ch)
            }
        }
    }
    
}

extension ChaptersDetailVC: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 24.0
    }
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        if let rowObject = objectFor(row: row) as? IDable {
            return TableReorderPasteboardWriter(id: rowObject.id, at: row)
        }
        return nil
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        guard dropOperation == .above else {
            return []
        }
        
        // Only drops from same table, chapters can only drop
        // above/below other chapters
        if let source = info.draggingSource as? NSTableView,
           source === tableView,
           let items = info.draggingPasteboard.pasteboardItems {
            tableView.draggingDestinationFeedbackStyle = .regular
            // What got dragged? Chapter or SubChapter?
            let ids:[String] = items.compactMap {
                $0.string(forType: .string)
            }
            if let id = ids.first,
               let draggedObject = objectFor(id: id) {
                if draggedObject is SubChapter {
                    // OK, can go anywhere.
                    return .move
                }
                else if let _ = objectFor(row: row) as? Chapter {
                    // Dragged onto another chapter
                    return .move
                }
                else if row >= numberOfRows(in: tableView) {
                    // Dragging chapter to end
                    return .move
                }
            }
        }
        
        return []
    }
}

extension ChaptersDetailVC: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        // One row for each chapter, one row for each subchapter
        var n = 0
        if let b = book {
            n = b.chapters.count
            for c in b.chapters {
                n += c.subchapters.count
            }
        }
        return n
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cellView: NSTableCellView?
        
        if let rowObject = objectFor(row: row) {
            if tableColumn == colStatus {
                cellView = tableView.makeView(withIdentifier: .chaptersDetailStatus, owner: self) as? NSTableCellView
                var status = EditStatus.multiple
                if let ch = rowObject as? Chapter {
                    status = ch.status
                }
                else if let sub = rowObject as? SubChapter {
                    status = sub.headerInfo.status
                }
                let image = NSImage(systemSymbolName: status.imageName, accessibilityDescription: status.rawValue)
                cellView?.imageView?.contentTintColor = status.tint
                cellView?.imageView?.image = image
            }
            
            if tableColumn == colInfo {
                cellView = tableView.makeView(withIdentifier: .chaptersDetailInfo, owner: self) as? NSTableCellView
                let f = cellView?.textField?.font
                if let sub = rowObject as? SubChapter {
                    cellView?.textField?.stringValue = sub.headerInfo.description
                    cellView?.textField?.font = f?.unbolded()?.resized(to: 11)
                }
                else if let ch = rowObject as? Chapter {
                    cellView?.textField?.stringValue = ch.titleSubtitle
                    cellView?.textField?.font = f?.bolded()?.resized(to: 13)
                    tableView.rowView(atRow: row, makeIfNecessary: false)?.backgroundColor = NSColor.unemphasizedSelectedTextBackgroundColor
                }
            }
            
            if tableColumn == colPOV {
                cellView = tableView.makeView(withIdentifier: .chaptersDetailPOV, owner: self) as? NSTableCellView
                if let sub = rowObject as? SubChapter {
                    cellView?.textField?.stringValue = sub.headerInfo.pov
                }
                else {
                    cellView?.textField?.stringValue = ""
                }
            }
            
            if tableColumn == colLocation {
                cellView = tableView.makeView(withIdentifier: .chaptersDetailLocation, owner: self) as? NSTableCellView
                if let sub = rowObject as? SubChapter {
                    cellView?.textField?.stringValue = sub.headerInfo.location
                }
                else {
                    cellView?.textField?.stringValue = ""
                }
            }
            
            if tableColumn == colWords {
                cellView = tableView.makeView(withIdentifier: .chaptersDetailWords, owner: self) as? NSTableCellView
                if let sub = rowObject as? SubChapter {
                    cellView?.textField?.stringValue = "\(sub.wordCount)"
                }
                else if let ch = rowObject as? Chapter {
                    cellView?.textField?.stringValue = "\(ch.wordCount)"
                }
            }
        }
        
        return cellView
    }
    
    private func objectFor(row: Int) -> Any? {
        if let b = book {
            var index = -1
            for c in b.chapters {
                index += 1
                if index == row {
                    return c as Any
                }
                for sub in c.subchapters {
                    index += 1
                    if index == row {
                        return sub as Any
                    }
                }
            }
        }
        return nil
    }
    
    private func objectFor(id: String) -> Any? {
        if let b = book {
            for c in b.chapters {
                if c.id == id {
                    return c as Any
                }
                for sub in c.subchapters {
                    if sub.id == id {
                        return sub as Any
                    }
                }
            }
        }
        return nil
    }
}

extension NSUserInterfaceItemIdentifier {
    static let chaptersDetailStatus = NSUserInterfaceItemIdentifier(rawValue: "ChapterOrSubChapterStatus")
    static let chaptersDetailInfo = NSUserInterfaceItemIdentifier(rawValue: "ChapterOrSubChapterInfo")
    static let chaptersDetailPOV = NSUserInterfaceItemIdentifier(rawValue: "ChapterOrSubChapterPOV")
    static let chaptersDetailLocation = NSUserInterfaceItemIdentifier(rawValue: "ChapterOrSubChapterLocation")
    static let chaptersDetailWords = NSUserInterfaceItemIdentifier(rawValue: "ChapterOrSubChapterWords")
}
