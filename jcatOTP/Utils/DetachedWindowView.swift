//
//  DetachedWindowView.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 9/14/20.
//  Copyright © 2020 jCat.io. All rights reserved.
//

import Cocoa

class DetachedWindowView: NSVisualEffectView
{
	override var allowsVibrancy: Bool { true }

	override func awakeFromNib()
	{
		super.awakeFromNib()

		material = .hudWindow
	}
}
