//
//  UniversalTicker.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 9/19/20.
//  Copyright © 2020 jCat.io. All rights reserved.
//

import Foundation

class UniversalTicker
{
	static let shared: UniversalTicker = UniversalTicker()

	var controllers: Array<DetachedViewController> = []
	var timer: Timer? = nil

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
		if (timer == nil) || !(timer?.isValid ?? false) {
			let d = Date(timeIntervalSince1970: round(Date().timeIntervalSince1970) + 1.05) // the next date that starts in exactly the second

			timer = Timer(fire: d, interval: 1.0, repeats: true, block: tickTok)
			RunLoop.main.add(timer!, forMode: .default)
		}
	}

	func invalidateTimer()
	{
		if timer != nil {
			timer!.invalidate()
			timer = nil
		}
	}

	func tickTok(_ timer: Timer)
	{
		controllers.forEach { dvc in
			if dvc.isWindowVisible {
				dvc.refreshOtp()
			}
		}
	}
}
