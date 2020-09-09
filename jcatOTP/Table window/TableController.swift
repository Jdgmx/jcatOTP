//
//  TableController.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 8/15/20.
//  Copyright © 2020 jCat.io. All rights reserved.
//

import Cocoa
import CryptoKit

class TableController: NSViewController
{
	@IBOutlet var otpTableView: NSTableView!

	var onReturn: Bool = true // value from Defaults
	private var obs: NSObjectProtocol? // to retain the notiofication

	var timers: Dictionary<Int, Any>?

	var service: OTPService { OTPService.shared }

	required init?(coder: NSCoder)
	{
		super.init(coder: coder)

		obs = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: OperationQueue.main, using: defaultsChanged)
	}

	deinit
	{
		if obs != nil {
			NotificationCenter.default.removeObserver(obs!)
		}
	}

	override func viewDidLoad()
	{
		super.viewDidLoad()

		otpTableView.setDraggingSourceOperationMask(.move, forLocal: true)
		otpTableView.registerForDraggedTypes([.string])

		OTPService.shared.changeCallback = self.updatedOtps
		updatedOtps()
	}

	override func viewWillDisappear()
	{
		super.viewWillDisappear()
		try? OTPService.shared.store()
	}

	override func prepare(for segue: NSStoryboardSegue, sender: Any?)
	{
		super.prepare(for: segue, sender: sender)

		(segue.destinationController as? NewOtpViewController)?.ovc = self // setting the ovc in the new otp sheet
	}

	// normally from the menu item
	@IBAction func addOTP(_ sender: Any)
	{
		performSegue(withIdentifier: "NewOTP", sender: self) // this pulls the add sheet
	}

	// normally from the menu item
	@IBAction func deleteOTP(_ sender: Any)
	{
		let selRow = otpTableView.selectedRow

		if (selRow >= 0) { // if there is something selected
			if let otpg = service.otp(at: selRow) {
				let alert = NSAlert()

				alert.alertStyle = .warning
				alert.messageText = "Delete \"\(otpg.name)\""
				alert.informativeText = "Are you sure you want to delete this OTP?"
				alert.addButton(withTitle: "Delete")
				alert.addButton(withTitle: "Cancel")

				let r = alert.runModal()
				if r == .alertFirstButtonReturn {
					service.removeOtp(at: selRow)
				}
			}
		}
	}

	@IBAction func dobleClick(_ sender: Any)
	{
		copySelectedOTP()
	}

	override func keyUp(with event: NSEvent)
	{
		if onReturn && (event.keyCode == 36) {
			copySelectedOTP()
		} else {
			super.keyUp(with: event)
		}
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
		let refreshPerioids = service.getRefreshPeriods()

		// invalidate all the previous timers
		timers?.forEach { (t) in
			(t.value as? Timer)?.invalidate()
		}

		// create the timers
		timers = [:]
		let c = Calendar.current
		for p in refreshPerioids.map({ Int($0) }) {
			let date = Date()
			var dc = c.dateComponents([.minute, .second], from: date)

			// want to have the next moment where the time should fire
			if (dc.second! + p) > 60 {
				dc.second = 0
				dc.minute = (dc.minute! < 59) ? dc.minute! + 1 : 0
			} else {
				dc.second = p // BUG: we are skipping one case: p=20, second=30, fire at 40 should be valid
			}
			dc.nanosecond = 500000000 // want to be half a second ahead

			if let nd = c.nextDate(after: date, matching: dc, matchingPolicy: .nextTime) { // this is the next fire date
				let t = Timer(fire: nd, interval: TimeInterval(p), repeats: true, block: { (timer) in
					self.otpTableView.reloadData(forRowIndexes: IndexSet(0..<self.service.count), columnIndexes: IndexSet(integer: 1))
				})

				RunLoop.current.add(t, forMode: .default)
				timers?.updateValue(t, forKey: p)
			}
		}
	}

	func updatedOtps()
	{
		calcRefreshTimers()
		otpTableView.reloadData() // always do it right now
	}
}

// MARK: - Delegate and data source extension

extension TableController: NSTableViewDataSource, NSTableViewDelegate
{
	func defaultsChanged(_ n: Notification)
	{
		onReturn = UserDefaults.standard.value(forKey: "copyOnReturn") as? Bool ?? false
	}

	func numberOfRows(in tableView: NSTableView) -> Int
	{
		return service.count
	}
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?
	{
		if let ident = tableColumn?.identifier { // if we have an identifier
			if let view = tableView.makeView(withIdentifier: ident, owner: self) as? NSTableCellView {
				if ident.rawValue == "Name" {
					view.textField?.stringValue = service.otp(at: row)?.name ?? "noname"
				} else if ident.rawValue == "Otp" {
					if let (otpValue, _) = service.otp(at: row)?.generate() {
						view.textField?.stringValue = otpValue 
					} else {
						view.textField?.stringValue = "..."
					}
				} else if ident.rawValue == "Service" {
					if let sb = view.subviews.first as? NSButton {
						sb.state = service.isOtpService(at: row) ? .on : .off
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

	@IBAction func updateServiceCheck(_ sender: Any?)
	{
		if let sb = sender as? NSButton {
			_ = service.toggleOtpService(at: sb.tag) // because in tag comes the row
			otpTableView.reloadData(forRowIndexes: IndexSet(integer: sb.tag), columnIndexes: IndexSet(integer: 2))
		}
	}

	func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool
	{
		return true // for now
	}

	func tableViewSelectionDidChange(_ notification: Notification)
	{
		if !onReturn {
			copySelectedOTP()
		}
	}

	func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting?
	{
		return NSString(format: "%i", row) // in a string, the row that initiaied the drag
	}

	func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation
	{
		if let s = info.draggingSource as? NSTableView {
			if s == otpTableView {
				return .move
			}
		}
		return .generic
	}

	func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool
	{
		if let s = info.draggingSource as? NSTableView, s == otpTableView {
			if let data = info.draggingPasteboard.pasteboardItems?.first?.data(forType: .string) {
				if let irs = String(bytes: data, encoding: .utf8), let iri = Int(irs) {  // in the pasteboard comes the row that initiated the drag
					let r: Int
					if row >= service.endIndex { // if its beyond the end...
						r = service.endIndex - 1 // ...then it's at the end
					} else {
						r = row
					}

					service.swapOtp(at: iri, with: r)
					OperationQueue.main.addOperation { self.otpTableView.reloadData() }

					return true
				}
			}
		}

		return false
	}
}
