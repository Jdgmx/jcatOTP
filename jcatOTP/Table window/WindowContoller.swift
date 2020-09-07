//
//  WindowContoller.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 8/30/20.
//  Copyright © 2020 jCat.io. All rights reserved.
//

import Cocoa

// MARK: Item identifiers

private extension NSToolbarItem.Identifier
{
	static let newOtpTb: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "newOtp")
	static let deleteOtpTb: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "deleteOtp")
}

// MARK: - Window controller

class WindowContoller: NSWindowController, NSToolbarDelegate, NSWindowDelegate
{
	@IBOutlet weak var toolbar: NSToolbar!
	@IBOutlet weak var progressView: NSView!

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
		return [.newOtpTb, .deleteOtpTb]
	}

	func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier]
	{
		return [.newOtpTb, .deleteOtpTb, .space, .flexibleSpace, .separator]
	}

	func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem?
	{
		if itemIdentifier == .newOtpTb {
			let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)

			toolbarItem.label = "New"
			toolbarItem.toolTip = "New OTP"
			toolbarItem.image = NSImage(named: NSImage.addTemplateName)
			toolbarItem.action = #selector(TableController.addOTP(_:))

			return toolbarItem
		} else if itemIdentifier == .deleteOtpTb {
			let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)

			toolbarItem.label = "Delete"
			toolbarItem.toolTip = "Delete OTP"
			toolbarItem.image = NSImage(named: NSImage.removeTemplateName)
			toolbarItem.action = #selector(TableController.deleteOTP(_:))

			return toolbarItem
		}

		return nil
	}
}