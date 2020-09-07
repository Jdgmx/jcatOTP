//
//  OTPService.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 9/6/20.
//  Copyright © 2020 jCat.io. All rights reserved.
//

import Cocoa

class OTPService: NSObject
{
	typealias OTPWrapper = Dictionary<String, Any>

	static let shared: OTPService = OTPService() // shared/common instance

	var changeCallback: (() -> Void)?

	private var passwords: Array<OTPWrapper> = [] // The array of OTP passwords

	var count: Int { passwords.count }

	// MARK: Methods

	func otp(at index:Int) -> OTPGenerator?
	{
		guard (index >= 0) && (index <= passwords.endIndex) else { return nil }

		return passwords[index]["otp"] as? OTPGenerator
	}

	func add(otp: OTPGenerator, at index:Int = -1)
	{
		guard index <= passwords.endIndex else { return }

		let wrapper = ["otp": otp]

		if index < 0 {
			passwords.append(wrapper)
		} else {
			passwords.insert(wrapper, at: index)
		}

		if changeCallback != nil {
			OperationQueue.main.addOperation(changeCallback!)
		}
	}

	func removeOtp(at index: Int)
	{
		guard (index >= 0) && (index <= passwords.endIndex) else { return }

		passwords.remove(at: index)

		if changeCallback != nil {
			OperationQueue.main.addOperation(changeCallback!)
		}
	}

	// Calculate refreshSeconds, or the second of each minute where the table must be reloaded.
	func getRefreshPeriods() -> Set<TimeInterval>
	{
		// get the seconds of where this should refresh
		let secs = passwords.map { (w) -> TimeInterval in
			if let otp = w["otp"] as? OTPGenerator {
				return trunc(otp.period)
			} else {
				return 0.0
			}
		}

		return Set(secs) // note this is a set, we want them unique
	}

	// MARK: Saving and loading

	private static let fileName = "otps.jcat"

	// Stores the OTPs in the array in a undisclosed location.
	func store() throws
	{
		if let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
			let otps = passwords.compactMap { $0["otp"] as? OTPGenerator }
			let datas = try otps.compactMap { try $0.save() }
			let fileData = try PropertyListSerialization.data(fromPropertyList: datas, format: .binary, options: .zero)

			FileManager.default.createFile(atPath: dir.appendingPathComponent(OTPService.fileName).path, contents: fileData, attributes: nil)
		}
	}

	func restoreOtps() throws
	{
		if let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
			if let fileData = FileManager.default.contents(atPath: dir.appendingPathComponent(OTPService.fileName).path) {
				if let datas = try PropertyListSerialization.propertyList(from: fileData, options: .mutableContainers, format: nil) as? Array<Data> {
					passwords = datas.compactMap { (d) -> OTPWrapper? in
						if let g = OTPRestore(from: d) {
							return ["otp": g]
						} else {
							return nil
						}
					}
					return
				}
			}
		}

		passwords = []
	}
}
