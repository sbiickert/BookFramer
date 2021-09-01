//
//  BFViewController.swift
//  BookFramer
//
//  Created by Simon Biickert on 2021-09-01.
//

import Cocoa

class BFViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
	
	public var document: Document? {
		return self.view.window?.windowController?.document as? Document
	}

}
