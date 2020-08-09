//
//  OutlineViewController.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 8/1/20.
//  Copyright © 2020 jCat.io. All rights reserved.
//

import Cocoa
import CryptoKit

class OutlineViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource
{
	typealias OTPWrapper = Dictionary<String, Any>

	@IBOutlet var otpOutlineView: NSOutlineView?

	var passwords: Array<OTPWrapper> = [] // The array of OTP passwords

	lazy var otpViewControler: OTPViewController? = {
		if let svi = (parent as? NSSplitViewController)?.splitViewItems.first(where: { $0.viewController is OTPViewController }) {
			return svi.viewController as? OTPViewController
		} else {
			return nil
		}
	}()

	override func viewDidLoad()
	{
		super.viewDidLoad()

		// Do view setup here.
		testAddOTP()
	}

	func testAddOTP()
	{
		if let testOTP = OTP<Insecure.SHA1>(name: "My test OTP", secret: "7OH6HVLLVW6VZRP7") {
			addOtp(testOTP)
		}
	}

	func addOtp(_ otp: OTPGenerator)
	{
		let wrapper = ["otp": otp]

		passwords.append(wrapper)
		otpOutlineView?.reloadData()
		otpOutlineView?.expandItem(nil, expandChildren: true)
	}

	@IBAction func addOTP(_ sender: Any)
	{
		performSegue(withIdentifier: "newOtp", sender: self)
	}

	override func prepare(for segue: NSStoryboardSegue, sender: Any?)
	{
		super.prepare(for: segue, sender: sender)

		(segue.destinationController as? NewOtpViewController)?.ovc = self // setting the ovc in the new otp sheet
	}

	// MARK: Data source and delegate

	func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int
	{
		if item == nil {
			return 1
		} else {
			return passwords.count
		}
	}

	func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any
	{
		if item == nil {
			return "OTPs"
		} else {
			return passwords[index]
		}
	}

	func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool
	{
		return (item as? String) == "OTPs"
	}

	func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool
	{
		return (item as? String) == "OTPs"
	}

	func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView?
	{
		if tableColumn == nil { // groups are the ones that have nil tableColumns
			let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: self) as! NSTableCellView

			view.textField?.stringValue = item as? String ?? ""
			return view
		} else {
			let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self) as! NSTableCellView

			view.imageView?.image = NSImage(named: NSImage.statusNoneName)
			view.textField?.stringValue = ((item as? OTPWrapper)?["otp"] as? OTPGenerator)?.name ?? ""
			return view
		}
	}

	func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool
	{
		return item is OTPWrapper
	}

	func outlineViewSelectionDidChange(_ notification: Notification)
	{
		guard otpOutlineView != nil else { return }

		let sr = otpOutlineView!.selectedRow
		if sr >= 0 {
			if let item = otpOutlineView!.item(atRow: sr) as? OTPWrapper {
				otpViewControler?.selectedOtp = item["otp"] as? OTPGenerator
				return
			}
		}

		otpViewControler?.selectedOtp = nil
	}
}
