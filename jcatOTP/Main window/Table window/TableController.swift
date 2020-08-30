//
//  TableController.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 8/15/20.
//  Copyright © 2020 jCat.io. All rights reserved.
//

import Cocoa
import CryptoKit

class TableController: NSViewController, AddOtpFunction
{
	typealias OTPWrapper = Dictionary<String, Any>

	@IBOutlet var otpTableView: NSTableView!

	var passwords: Array<OTPWrapper> = [] // The array of OTP passwords

	override func viewDidLoad()
	{
		super.viewDidLoad()
		testAddOTP()
	}


	func testAddOTP()
	{
		if let testOTP = OTP<Insecure.SHA1>(name: "My test OTP", secret: "7OH6HVLLVW6VZRP7") {
			add(otp: testOTP)
		}
	}

	func add(otp: OTPGenerator)
	{
		let wrapper = ["otp": otp]

		passwords.append(wrapper)
		otpTableView.reloadData()
	}

	// normally from the menu item
	@IBAction func addOTP(_ sender: Any)
	{
		performSegue(withIdentifier: "NewOTP", sender: self)
	}

	// normally from the menu item
	@IBAction func deleteOTP(_ sender: Any)
	{
		let selRow = otpTableView.selectedRow

		if (selRow >= 0) { // if there is something selected
			let w = passwords[selRow]
			if let otpg = (w["otp"] as? OTPGenerator) {
				let alert = NSAlert()

				alert.alertStyle = .warning
				alert.messageText = "Delete \"\(otpg.name)\""
				alert.informativeText = "Are you sure you want to delete this OTP?"
				alert.addButton(withTitle: "Delete")
				alert.addButton(withTitle: "Cancel")

				let r = alert.runModal()
				if r == .alertFirstButtonReturn {
					passwords.remove(at: selRow)
					otpTableView.reloadData()
				}
			}
		}
	}

	override func prepare(for segue: NSStoryboardSegue, sender: Any?)
	{
		super.prepare(for: segue, sender: sender)

		(segue.destinationController as? NewOtpViewController)?.ovc = self // setting the ovc in the new otp sheet
	}

}

// MARK: - Delegate and data source extension

extension TableController: NSTableViewDataSource, NSTableViewDelegate
{
	func numberOfRows(in tableView: NSTableView) -> Int
	{
		return passwords.count
	}

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
	{
		if let ident = tableColumn?.identifier { // if we have an identifier
			if let view = tableView.makeView(withIdentifier: ident, owner: self) as? NSTableCellView {
				view.objectValue = passwords[row]

				if ident.rawValue == "Service" {
					view.textField?.stringValue = (passwords[row]["otp"] as? OTPGenerator)?.name ?? "noname"
				} else if ident.rawValue == "Otp" {
					if let (otpValue, _) = (passwords[row]["otp"] as? OTPGenerator)?.generate() {
						view.textField?.integerValue = otpValue
					} else {
						view.textField?.stringValue = "..."
					}
				}

				return view
			}
		}

		return nil
	}

}
