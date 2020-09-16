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
	}

	func windowDidBecomeKey(_ notification: Notification)
	{
		dvc?.startTimer()
	}

	func windowWillMiniaturize(_ notification: Notification)
	{
		dvc?.invalidateTimer()
	}

	func windowDidDeminiaturize(_ notification: Notification)
	{
		dvc?.startTimer()
	}

	func windowWillClose(_ notification: Notification)
	{
		dvc?.invalidateTimer()
	}
}

// MARK: - Detached View Controller

class DetachedViewController: NSViewController
{
	var timer: Timer?

	@IBOutlet weak var progress: NSProgressIndicator!

	var otp: OTPGenerator? {
		willSet { willSetupOtp() }
		didSet { didSetupOtp() }
	}

	@objc var name: String { otp?.name ?? "" }
	@objc dynamic var code: String = ""

	func willSetupOtp()
	{
		willChangeValue(forKey: "name")
	}

	func didSetupOtp()
	{
		didChangeValue(forKey: "name")

		progress.maxValue = Double(otp?.period ?? 0)
	}

	func startTimer()
	{
		invalidateTimer()
		timer = Timer(timeInterval: 1.0, repeats: true, block: timerFire)

		RunLoop.current.add(timer!, forMode: .default)
	}

	func invalidateTimer()
	{
		if timer != nil {
			timer!.invalidate()
			timer = nil
		}
	}

	func timerFire(_ t: Timer)
	{
		if let (code, count) = otp?.generate() {
			self.code = OTPFormatter().string(for: code) ?? "🐜"
			self.progress.doubleValue = Double(count)
		}
	}
}

// MARK: - Detached Window View

class DetachedWindowView: NSVisualEffectView
{
	override var allowsVibrancy: Bool { true }

	override func awakeFromNib()
	{
		super.awakeFromNib()

		material = .sidebar
		blendingMode = .behindWindow
	}
}

