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

		let wrapper = ["otp": otp, "service": false] as OTPWrapper

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

	func isOtpService(at index: Int) -> Bool
	{
		guard (index >= 0) && (index <= passwords.endIndex) else { return false }

		return (passwords[index]["service"] as? Bool) ?? false
	}

	func setOtpService(at index: Int, service: Bool = true)
	{
		guard (index >= 0) && (index <= passwords.endIndex) else { return }

		passwords[index]["service"] = service
	}

	func toggleOtpService(at index: Int) -> Bool
	{
		guard (index >= 0) && (index <= passwords.endIndex) else { return false }

		if var s = passwords[index]["service"] as? Bool {
			s.toggle()
			passwords[index]["service"] = s
			return s
		}

		return false
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

	// MARK: Services

	// Generates the OTP code at a given index and copies it into the pasteboard.
	func copyOtp(at index:Int)
	{
		if let otp = otp(at: index) {
			let pb = NSPasteboard.general
			let (code, _) = otp.generate()

			pb.clearContents()
			pb.setString(String(code), forType: .string)
		}
	}

	// The following methods are the callbacks from the services menu

	@objc func otpPassword0(from pboard: NSPasteboard, userData: String) throws
	{
		NSLog("Services pasteboard: \(pboard), userData: \(userData)")

		pboard.clearContents()
		pboard.setString("PASTE COSA 0", forType: .string)

	}

	@objc func otpPassword1(from pboard: NSPasteboard, userData: String) throws
	{
		NSLog("Services pasteboard: \(pboard), userData: \(userData)")

		pboard.clearContents()
		pboard.setString("PASTE COSA 2", forType: .string)
	}

	@objc func otpPassword2(from pboard: NSPasteboard, userData: String) throws
	{
		NSLog("Services pasteboard: \(pboard), userData: \(userData)")

		pboard.clearContents()
		pboard.setString("PASTE COSA 2", forType: .string)
	}

}