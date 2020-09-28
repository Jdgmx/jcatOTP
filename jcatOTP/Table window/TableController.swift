//
//  TableController.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 8/15/20.
//  Copyright © 2020 jCat.io. All rights reserved.
//

import Cocoa
import CryptoKit
import os

class TableController: NSViewController
{
	private static var log = OSLog(subsystem: Bundle.main.bundleIdentifier! + ".TableController", category: "jcat")
	private var log: OSLog { TableController.log }

	@IBOutlet var otpTableView: NSTableView!

	var onReturn: Bool = true // value from Defaults
	private var obs: NSObjectProtocol? // to retain the notiofication

	var timers: Dictionary<Int, Any>? // set of timers used to refresh the otp codes
	var service: OTPService { OTPService.shared } // the otp service

	required init?(coder: NSCoder)
	{
		super.init(coder: coder)

		// need to know when the notifications change
		obs = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: OperationQueue.main, using: defaultsChanged)

		let not = NSWorkspace.shared.notificationCenter
		not.addObserver(self, selector: #selector(wakeOrSleepe(_:)), name: NSWorkspace.didWakeNotification, object: nil)
		not.addObserver(self, selector: #selector(wakeOrSleepe(_:)), name: NSWorkspace.willSleepNotification, object: nil)
	}

	deinit
	{
		if obs != nil { // no longer need to know
			NotificationCenter.default.removeObserver(obs!)
		}
	}

	@objc func wakeOrSleepe(_ n: Notification)
	{
		os_log(.debug, log: log, "wakeOrSleepe(), %s", String(describing: n))

		if n.name == NSWorkspace.willSleepNotification {
			timers?.forEach { ($0.value as? Timer)?.invalidate() }
			try? OTPService.shared.store() // save!
		} else if n.name == NSWorkspace.didWakeNotification {
			if view.window?.isVisible ?? false {
				updatedOtps() // and for thew first time...
				defaultsChanged(nil)
			}
		}
	}

	override func viewDidLoad()
	{
		os_log(.debug, log: log, "viewDidLoad()")

		super.viewDidLoad()

		// this table view can drag
		otpTableView.setDraggingSourceOperationMask(.move, forLocal: true)
		otpTableView.registerForDraggedTypes([.string])

		// the callback is called from the service every time the collection of otps changes
		OTPService.shared.changeCallback = self.updatedOtps
//		updatedOtps() // and for thew first time...
//		defaultsChanged(nil)
	}

	override func viewWillAppear()
	{
		os_log(.debug, log: log, "viewWillAppear()")

		super.viewWillAppear()

		updatedOtps() // and for thew first time...
		defaultsChanged(nil)
	}

	override func viewWillDisappear()
	{
		os_log(.debug, log: log, "viewWillDisappear()")

		super.viewWillDisappear()

		// invalidate all the previous timers
		timers?.forEach { ($0.value as? Timer)?.invalidate() }

		try? OTPService.shared.store() // save!
	}

	override func prepare(for segue: NSStoryboardSegue, sender: Any?)
	{
		super.prepare(for: segue, sender: sender)

		if segue.identifier == "NewOTP" {
			(segue.destinationController as? NewOtpViewController)?.ovc = self // setting the ovc in the new otp sheet
		} else if segue.identifier == "DetachOTP" {
			if let vc = segue.destinationController as? DetachedWindowController {
				let selRow = otpTableView.selectedRow

				if (selRow >= 0) { // if there is something selected
					vc.otp = service.otp(at: selRow)
				}
			}
		}
	}

	// normally from the menu item and toolbar
	@IBAction func addOTP(_ sender: Any)
	{
		performSegue(withIdentifier: "NewOTP", sender: self) // this pulls the add sheet
	}

	// normally from the menu item and toolbar
	@IBAction func deleteOTP(_ sender: Any)
	{
		let selRow = otpTableView.selectedRow

		if (selRow >= 0) { // if there is something selected
			if let otpg = service.otp(at: selRow) {
				let alert = NSAlert()

				alert.icon = NSImage(named: "jcat")
				alert.alertStyle = .warning
				alert.messageText = "Delete \"\(otpg.name)\""
				alert.informativeText = "Are you sure you want to delete this OTP?"
				alert.addButton(withTitle: "Delete")
				alert.addButton(withTitle: "Cancel")

				let r = alert.runModal()
				if r == .alertFirstButtonReturn {
					service.removeOtp(at: selRow) // bye bye
				}
			}
		}
	}

	@IBAction func detachOTP(_ sender: Any)
	{
		performSegue(withIdentifier: "DetachOTP", sender: self) // this pulls the add sheet
	}

	// action if we double click on the table, comes from the nib
	@IBAction func doubleClick(_ sender: Any)
	{
		copySelectedOTP()
	}

	override func keyUp(with event: NSEvent)
	{
		if onReturn && (event.keyCode == 36) { // return
			copySelectedOTP()
		} else {
			super.keyUp(with: event)
		}
	}

	@IBAction func copy(_ sender: Any?)
	{
		copySelectedOTP()
	}

	override func keyDown(with event: NSEvent)
	{
		if !onReturn || !(event.keyCode == 36) {
			super.keyDown(with: event)
		}
	}

	private func copySelectedOTP()
	{
		let selRow = otpTableView.selectedRow

		if (selRow >= 0) { // if there is something selected
			service.copyOtp(at: selRow)
		}
	}

	// MARK: Utils

	// Calculate refreshSeconds, or the second of each minute where the table must be reloaded.
	// Note that for now we are refreshing the whole table, that can be optimized
	func calcRefreshTimers()
	{
		os_log(.debug, log: log, "calcRefreshTimers()")

		let refreshPerioids = service.getRefreshPeriods()

		// invalidate all the previous timers
		timers?.forEach { (t) in
			(t.value as? Timer)?.invalidate()
		}

		// create the timers
		timers = [:]
		for p in refreshPerioids.map({ Int($0) }) { // the periods in Int
			if let nd = nextDateFor(period: p) { // this is the next fire date
				let t = Timer(fire: nd, interval: TimeInterval(p), repeats: true, block: { [weak self] (timer) in
					os_log(.debug, log: TableController.log, "timer %s fiered, %s, %f", String(describing:timer), String(describing:timer.fireDate), timer.tolerance)

					self?.otpTableView.reloadData(forRowIndexes: IndexSet(0..<(self?.service.count ?? 0)), columnIndexes: IndexSet(integer: 1))
				})

				RunLoop.current.add(t, forMode: .default)
				timers?.updateValue(t, forKey: p)
			}
		}
	}

	// we need to do this if the array of otps changes
	func updatedOtps()
	{
		os_log(.debug, log: log, "updatedOtps()")

		calcRefreshTimers()
		otpTableView.reloadData() // always do it right now
	}

	// need to do this if the user defaults change
	func defaultsChanged(_ n: Notification?)
	{
		onReturn = UserDefaults.standard.value(forKey: "copyOnReturn") as? Bool ?? false
	}
}

// MARK: - Delegate and data source extension

extension TableController: NSTableViewDataSource, NSTableViewDelegate
{
	func numberOfRows(in tableView: NSTableView) -> Int
	{
		return service.count
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
	{
		if let ident = tableColumn?.identifier { // if we have an identifier
			if let view = tableView.makeView(withIdentifier: ident, owner: self) as? NSTableCellView {
				if ident.rawValue == "Name" {
					view.textField?.stringValue = service.otp(at: row)?.name ?? "🐜"
				} else if ident.rawValue == "Otp" {
					if let (otpValue, _) = service.otp(at: row)?.generate() {
						view.textField?.stringValue = OTPFormatter().string(for: otpValue) ?? "🐜"
					} else {
						view.textField?.stringValue = "🐜"
					}
				} else if ident.rawValue == "Service" {
					if let sb = view.subviews.first as? NSButton {
						let chk = service.isOtpService(at: row)

						sb.state = chk ? .on : .off
						sb.isEnabled = chk || service.canAddToServices
						sb.tag = row // the tag has the row number
						sb.action = #selector(TableController.updateServiceCheck(_:))
						sb.target = self
					}
				}

				return view
			}
		}

		return nil
	}

	// when the check box in the services column is clicked
	@IBAction func updateServiceCheck(_ sender: Any?)
	{
		if let sb = sender as? NSButton {
			let success = service.toggleOtpService(at: sb.tag) // because in tag comes the row

			if !success {
				let alert = NSAlert()

				alert.icon = NSImage(named: "jcat")
				alert.alertStyle = .warning
				alert.messageText = "Can't Add Item to Services"
				alert.informativeText = "Make sure you don't have 5 or more items already in the Services."
				alert.runModal()
			}

			otpTableView.reloadData(forRowIndexes: IndexSet(integersIn: 0..<service.endIndex), columnIndexes: IndexSet(integer: 2))
		}
	}

	func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool
	{
		return true // for now
	}

	func tableViewSelectionDidChange(_ notification: Notification)
	{
		if !onReturn { // if not on return then its on select
			copySelectedOTP()
		}
	}

	func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting?
	{
		return NSString(format: "%i", row) // in a string, the row that initiaied the drag
	}

	func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation
	{
		if let s = info.draggingSource as? NSTableView, s == otpTableView {
			return .move
		}

		return .generic
	}

	func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool
	{
		if let s = info.draggingSource as? NSTableView, s == otpTableView {
			if let data = info.draggingPasteboard.pasteboardItems?.first?.data(forType: .string) {
				if let irs = String(bytes: data, encoding: .utf8), let iri = Int(irs) {  // in the pasteboard comes the row that initiated the drag
					var r = row

					if dropOperation == .above { // if above, in general is on top of the destionation one
						let d = r - iri
						if (d == 0) || (d == 1) {
							return false
						} else if d > 1 {
							r -= 1
						}
					}

					if r > service.endIndex {
						r = service.endIndex - 1 // just to be sure
					}

					service.moveOtp(at: iri, to: r)
					OperationQueue.main.addOperation { self.otpTableView.reloadData() } // refresh

					return true
				}
			}
		}

		return false
	}
}

// MARK: - Menu item validation

extension TableController: NSMenuItemValidation, NSToolbarItemValidation
{
	func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
	{
		let t = menuItem.tag

		if (t == 220) || (t == 230) || (t == 340) { // delete || detach OTP || copy OTP
			return otpTableView.selectedRow >= 0
		} else {
			return true
		}
	}

	func validateToolbarItem(_ item: NSToolbarItem) -> Bool
	{
		let i = item.itemIdentifier

		if (i == .deleteOtpTb) || (i == .detachOtpTb) {  // delete || detach OTP
			return otpTableView.selectedRow >= 0
		} else {
			return true
		}
	}
}
