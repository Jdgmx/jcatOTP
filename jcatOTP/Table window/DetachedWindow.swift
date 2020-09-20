//
//  DetachedWindowController.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 9/15/20.
//  Copyright © 2020 jCat.io. All rights reserved.
//

import Cocoa

class DetachedWindowController: NSWindowController, NSWindowDelegate
{
	var dvc: DetachedViewController? { contentViewController as? DetachedViewController }

	var otp: OTPGenerator? {
		get { dvc?.otp }
		set { dvc?.otp = newValue }
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
//		wantsLayer = true
		material = .sidebar
		blendingMode = .behindWindow
	}
}

