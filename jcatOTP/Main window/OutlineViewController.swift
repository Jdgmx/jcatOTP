//
//  OutlineViewController.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 8/1/20.
//  Copyright © 2020 jCat.io. All rights reserved.
//

import Cocoa

class OutlineViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource
{

	override func viewDidLoad()
	{
		super.viewDidLoad()
		// Do view setup here.
	}

	// MARK: Data source and delegate

	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int
	{
		
	}
}
