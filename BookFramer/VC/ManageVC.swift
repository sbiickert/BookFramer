//
//  ManageVC.swift
//  BookFramer
//
//  Created by Simon Biickert on 2022-01-25.
//

import Cocoa

class ManageVC: NSViewController {
	@IBOutlet weak var chaptersContainerView: NSView!
	@IBOutlet weak var detailContainerView: NSView!

	private var _observersAdded = false
	var book: Book? {
		didSet {
			chapters?.book = book
			detail?.book = book
			personas?.book = book
			if _observersAdded == false {
				// Nothing at the moment
				_observersAdded = true
			}
		}
	}
	
	var chapters: ChaptersDetailVC? {
	 for childVC in children {
		 if let cdvc = childVC as? ChaptersDetailVC {
			 return cdvc
		 }
	 }
	 return nil
 }
 
 var detail: DetailTabVC? {
	 for childVC in children {
		 if let dtvc = childVC as? DetailTabVC {
			 return dtvc
		 }
	 }
	 return nil
 }
 
 var personas: PersonasDetailVC? {
	 for childVC in children {
		 if let pdvc = childVC as? PersonasDetailVC {
			 return pdvc
		 }
	 }
	 return nil
 }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
