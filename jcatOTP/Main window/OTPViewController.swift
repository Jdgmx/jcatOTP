//
//  OTPViewController.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 8/2/20.
//  Copyright © 2020 jCat.io. All rights reserved.
//

import Cocoa

class OTPViewController: NSViewController
{
	@IBOutlet var progress: NSProgressIndicator!
	@IBOutlet weak var otpFormatter: NumberFormatter!

	@objc dynamic var otpValue: Int = 0
	@objc dynamic var name: String = ""
	@objc dynamic var counter: Int = 0

	var selectedOtp: OTPGenerator? = nil {
		didSet { updateSelectedOtp() }
	}

	var timer: Timer? = nil

	override func viewDidAppear()
	{
		NSLog("viewDidAppear")

		configureTimer()
	}

	override func viewWillDisappear()
	{
		NSLog("viewWillDisappear")

		invalidateTimer()
	}

	// MARK: Updated selection

	func updateSelectedOtp()
	{
		if selectedOtp != nil {
			progress.minValue = 0.0
			progress.maxValue = selectedOtp!.period.rounded(.down)

			otpFormatter.numberStyle = .decimal
			otpFormatter.maximumFractionDigits = 0
			otpFormatter.minimumIntegerDigits = selectedOtp!.digits

			configureTimer()
		}
	}

	// MARK: Timer

	func configureTimer()
	{
		if (timer == nil) && (selectedOtp != nil){
			timer = Timer(timeInterval: TimeInterval(1), repeats: true, block: timerClick)
			RunLoop.current.add(timer!, forMode: .default)
		}
	}

	func invalidateTimer()
	{
		if timer != nil {
			timer!.invalidate()
			timer = nil
		}
	}

	func timerClick(_ t: Timer)
	{
		guard selectedOtp != nil else { return }

		(otpValue, counter) = selectedOtp!.generate()
		name = selectedOtp!.name

		NSLog("timer = \(t), \(otpValue) \(counter)")
	}
}
