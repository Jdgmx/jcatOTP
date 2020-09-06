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
	var onReturn: Bool = true
	private var obs: NSObjectProtocol?

	var timers: Dictionary<Int, Any>?
	var refreshSeconds: Set<TimeInterval> = [0.0] // at which secongs the table must be refreshed

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

		if let savedOtps = try? restoreOtps() {
			passwords = savedOtps.map { ["otp": $0] }
			calcRefreshTimers()
			otpTableView.reloadData() // always do it right now
		}
	}

	override func viewWillDisappear()
	{
		super.viewWillDisappear()

		try? store(otps: passwords.compactMap({ $0["otp"] as? OTPGenerator }))
	}

	override func prepare(for segue: NSStoryboardSegue, sender: Any?)
	{
		super.prepare(for: segue, sender: sender)

		(segue.destinationController as? NewOtpViewController)?.ovc = self // setting the ovc in the new otp sheet
	}

	func add(otp: OTPGenerator)
	{
		let wrapper = ["otp": otp]

		passwords.append(wrapper)
		calcRefreshTimers()
		otpTableView.reloadData() // always do it right now
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

		calcRefreshTimers()
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
			let w = passwords[selRow]

			if let otpg = (w["otp"] as? OTPGenerator) {
				let pb = NSPasteboard.general
				let (code, _) = otpg.generate()

				pb.clearContents()
				pb.setString(String(code), forType: .string)
			}
		}
	}

	// MARK: Utils

	// Calculate refreshSeconds, or the second of each minute where the table must be reloaded.
	// Note that for now we are refreshing the whole table, that can be optimized
	func calcRefreshTimers()
	{
		// get the seconds of where this should refresh
		let secs = passwords.map { (w) -> TimeInterval in
			if let otp = w["otp"] as? OTPGenerator {
				return trunc(otp.period)
			} else {
				return 0.0
			}
		}
		let refreshPerioids = Set(secs) // note this is a set, we want them unique

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
					self.otpTableView.reloadData(forRowIndexes: IndexSet(0..<self.passwords.count), columnIndexes: IndexSet(integer: 1))
				})

				RunLoop.current.add(t, forMode: .default)
				timers?.updateValue(t, forKey: p)
			}
		}
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
}
