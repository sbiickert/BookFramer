//
//  ViewController.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-08-23.
//

import Cocoa

class DocVC: NSSplitViewController {

    var book: Book? {
        return representedObject as? Book
    }
    
    var sidebar: SidebarVC? {
        for svi in self.splitViewItems {
            if let sbvc = svi.viewController as? SidebarVC {
                return sbvc
            }
        }
        return nil
    }
	
	var detail: DetailTabVC? {
		for svi in self.splitViewItems {
			if let dtvc = svi.viewController as? DetailTabVC {
				return dtvc
			}
		}
		return nil
	}
        
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
            sidebar?.book = book
			detail?.book = book
        }
    }


}

