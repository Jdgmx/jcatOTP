//
//  DetachedWindowController.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 9/15/20.
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

class DetachedWindowController: NSWindowController, NSWindowDelegate
{
	var dvc: DetachedViewController? { contentViewController as? DetachedViewController }

	var otp: OTPGenerator? {
		get { dvc?.otp }
		set {
			dvc?.otp = newValue
			windowFrameAutosaveName = dvc?.name ?? "dvc"
		}
	}

	override func windowWillLoad()
	{
		super.windowWillLoad()
		shouldCascadeWindows = false
	}

	override func windowDidLoad()
	{
		super.windowDidLoad()

		window?.level = .floating // this window floats over every other window
		window?.collectionBehavior = .managed

		if dvc != nil {
			UniversalTicker.shared.addController(dvc!)
		}
	}

	func windowWillClose(_ notification: Notification)
	{
		if dvc != nil {
			UniversalTicker.shared.removeController(dvc!)
		}
	}
}

// MARK: - Detached View Controller

class DetachedViewController: NSViewController
{
	@IBOutlet weak var progress: NSProgressIndicator!

	var isWindowVisible: Bool { view.window?.isVisible ?? false }

	var otp: OTPGenerator? {
		willSet { willSetupOtp() }
		didSet { didSetupOtp() }
	}

	@objc var name: String { otp?.name ?? "" }
	@objc dynamic var code: String = ""

	// Called when we are about to setup the OTP for this view
	func willSetupOtp()
	{
		willChangeValue(forKey: "name")
	}

	// Called when we just setup the OTP for this view
	func didSetupOtp()
	{
		didChangeValue(forKey: "name")

		progress.minValue = 1
		progress.maxValue = Double(otp?.period ?? 0)

		refreshOtp()
	}

	func refreshOtp()
	{
		if let (code, count) = otp?.generate() {
			self.code = OTPFormatter().string(for: code) ?? "🐜" // if not bug!
			self.progress.doubleValue = Double(count)
		}
	}

	@IBAction func copy(_ sender: Any?)
	{
		guard otp != nil else { return }

		let pb = NSPasteboard.general
		let (code, _) = otp!.generate()

		pb.clearContents()
		pb.setString(code, forType: .string)
	}

	override func mouseDown(with event: NSEvent)
	{
		if event.clickCount == 2 {
			copy(nil)
		} else {
			super.mouseDown(with: event)
		}
	}
}

// MARK: - Detached Window View

class DetachedWindowView: NSVisualEffectView
{
//	override var allowsVibrancy: Bool { true }

	override func awakeFromNib()
	{
		super.awakeFromNib()
		material = .sidebar
		blendingMode = .behindWindow
	}
}

