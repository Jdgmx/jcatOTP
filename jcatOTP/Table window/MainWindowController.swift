//
//  WindowController.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 8/30/20.
//  Copyright © 2020 jCat.io. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published
//  by the Free Software Foundation, either version 3 of the License, or
//  any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import Cocoa

// MARK: Item identifiers

extension NSToolbarItem.Identifier
{
	static let newOtpTb: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "newOtp")
	static let deleteOtpTb: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "deleteOtp")
	static let detachOtpTb: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "detachOtp")
}

// MARK: - Window controller

class MainWindowController: NSWindowController, NSToolbarDelegate, NSWindowDelegate
{
	@IBOutlet weak var toolbar: NSToolbar!
	@IBOutlet weak var progressView: NSView!

	let autoSaveName = "jCatWindow"

	override func windowWillLoad()
	{
		super.windowWillLoad()

		shouldCascadeWindows = false
		windowFrameAutosaveName = autoSaveName
	}

	override func windowDidLoad()
	{
		super.windowDidLoad()

		// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
		toolbar.allowsUserCustomization = true
		toolbar.sizeMode = .small
	}

	// MARK: Toolbar delegate

	func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier]
	{
		return [.newOtpTb, .deleteOtpTb, .flexibleSpace, .detachOtpTb]
	}

	func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier]
	{
		return [.newOtpTb, .deleteOtpTb, .detachOtpTb, .space, .flexibleSpace, .separator]
	}

	func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem?
	{
		if itemIdentifier == .newOtpTb {
			let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)

			toolbarItem.label = "New"
			toolbarItem.toolTip = "New OTP"
			toolbarItem.image = NSImage(named: NSImage.addTemplateName)
			toolbarItem.action = #selector(TableController.addOTP(_:)) // note that if no target then goes to first responder

			return toolbarItem
		} else if itemIdentifier == .deleteOtpTb {
			let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)

			toolbarItem.label = "Delete"
			toolbarItem.toolTip = "Delete OTP"
			toolbarItem.image = NSImage(named: NSImage.removeTemplateName)
			toolbarItem.action = #selector(TableController.deleteOTP(_:)) // note that if no target then goes to first responder

			return toolbarItem
		} else if itemIdentifier == .detachOtpTb {
			let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)

			toolbarItem.label = "Detach"
			toolbarItem.toolTip = "Detach floating OTP"
			toolbarItem.image = NSImage(named: NSImage.rightFacingTriangleTemplateName)
			toolbarItem.action = #selector(TableController.detachOTP(_:)) // note that if no target then goes to first responder

			return toolbarItem
		}

		return nil
	}
}
