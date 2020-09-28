//
//  UniversalTicker.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 9/19/20.
//  Copyright © 2020 jCat.io. All rights reserved.
//

import Foundation
import AppKit
import os

class UniversalTicker
{
	private static var log = OSLog(subsystem: Bundle.main.bundleIdentifier! + ".UniversalTicker", category: "jcat")
	private var log: OSLog { UniversalTicker.log }

	static let shared: UniversalTicker = UniversalTicker()

	var controllers: Array<DetachedViewController> = []
	var timer: Timer? = nil

	init()
	{
		let not = NSWorkspace.shared.notificationCenter
		not.addObserver(self, selector: #selector(wakeOrSleepe(_:)), name: NSWorkspace.didWakeNotification, object: nil)
		not.addObserver(self, selector: #selector(wakeOrSleepe(_:)), name: NSWorkspace.willSleepNotification, object: nil)
	}

	@objc func wakeOrSleepe(_ n: Notification)
	{
		os_log(.debug, log: log, "wakeOrSleepe(), %s", String(describing: n))

		if n.name == NSWorkspace.willSleepNotification {
			invalidateTimer()
		} else if n.name == NSWorkspace.didWakeNotification {
			if !controllers.isEmpty {
				startTimer()
			}
		}
	}

	func addController(_ ctrl: DetachedViewController)
	{
		if controllers.firstIndex(of: ctrl) == nil { // if it's not there
			controllers.append(ctrl)
		}

		startTimer() // if isn't started
	}

	func removeController(_ ctrl: DetachedViewController)
	{
		if let i = controllers.firstIndex(of: ctrl) {
			controllers.remove(at: i)
		}

		if controllers.isEmpty {
			invalidateTimer()
		}
	}

	func startTimer()
	{
		os_log(.debug, log: log, "startTimer()")

		if (timer == nil) || !(timer?.isValid ?? false) {
			let d = Date(timeIntervalSince1970: round(Date().timeIntervalSince1970) + 1.05) // the next date that starts in exactly the second+0.05

			timer = Timer(fire: d, interval: 1.0, repeats: true, block: tickTok)
			RunLoop.main.add(timer!, forMode: .default)
		}
	}

	func invalidateTimer()
	{
		os_log(.debug, log: log, "invalidateTimer(), %s", String(describing: timer))

		if timer != nil {
			timer!.invalidate()
			timer = nil
		}
	}

	func tickTok(_ timer: Timer)
	{
		os_log(.debug, log: log, "tickTok(), %s", String(describing: timer.fireDate))
		
		controllers.forEach { dvc in
			if dvc.isWindowVisible {
				dvc.refreshOtp()
			}
		}
	}
}
