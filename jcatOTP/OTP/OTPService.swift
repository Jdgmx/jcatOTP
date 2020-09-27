//
//  OTPService.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 9/6/20.
//  Copyright © 2020 jCat.io. All rights reserved.
//
// See: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/SysServices/introduction.html

import Cocoa
import os
import CryptoKit

class OTPService: NSObject
{
	private static var log = OSLog(subsystem: Bundle.main.bundleIdentifier! + ".OTPService", category: "jcat")
	private var log: OSLog { OTPService.log }

	typealias OTPWrapper = Dictionary<String, Any>

	static let shared: OTPService = OTPService() // shared/common instance

	var changeCallback: (() -> Void)? // called every time an otp is added or removed from the passwords array

	private var passwords: Array<OTPWrapper> = [] // The array of OTP passwords
	private var inServices: Array<OTPWrapper> = [] // the OTPs that respond to the services menu

	var count: Int { passwords.count }
	var endIndex: Int { passwords.endIndex }
	var canAddToServices: Bool { (count < 5) ? true : (inServices.count < 5) }
	var isSafe: Bool = false

	// MARK: Methods

	// because the order of the items in services is important
	private func getInServices()
	{
		inServices = passwords.filter({ $0["service"] as? Bool ?? false }) // because order is important
	}

	func otp(at index:Int) -> OTPGenerator?
	{
		guard (index >= 0) && (index < endIndex) else { return nil }

		return passwords[index]["otp"] as? OTPGenerator
	}

	func add(otp: OTPGenerator, at index:Int = -1)
	{
		guard index <= endIndex else { return }

		let wrapper = ["otp": otp, "service": false] as OTPWrapper

		isSafe = false

		if index < 0 {
			passwords.append(wrapper)
		} else {
			passwords.insert(wrapper, at: index)
		}
		getInServices()

		if changeCallback != nil {
			OperationQueue.main.addOperation(changeCallback!)
		}
	}

	func removeOtp(at index: Int)
	{
		guard (index >= 0) && (index < endIndex) else { return }

		isSafe = false

		passwords.remove(at: index)
		getInServices()

		if changeCallback != nil {
			OperationQueue.main.addOperation(changeCallback!)
		}
	}

	func moveOtp(at org: Int, to dest: Int)
	{
		guard org != dest else { return }
		guard (org >= 0) && (org < endIndex) else { return }
		guard (dest >= 0) && (dest < endIndex) else { return }

		isSafe = false

		passwords.insert(passwords.remove(at: org), at: dest)
		getInServices() // because order is important
	}

	func isOtpService(at index: Int) -> Bool
	{
		guard (index >= 0) && (index < endIndex) else { return false }

		return (passwords[index]["service"] as? Bool) ?? false
	}

	func toggleOtpService(at index: Int) -> Bool
	{
		guard (index >= 0) && (index < endIndex) else { return false }
		defer { getInServices() }

		isSafe = false

		if var s = passwords[index]["service"] as? Bool {
			if s || canAddToServices { // is was false then we wanted to turn it on, but can only do it if we can
				s.toggle()
				passwords[index]["service"] = s
				return true
			}
		}

		return false
	}

	// Calculate refreshSeconds, or the second of each minute where the table must be reloaded.
	// returns a Set of all the periods for the OTPs
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
		guard !isSafe else { os_log(.debug, log: log, "store(), is safe"); return }
		guard AppDelegate.decryptKey != nil else { os_log(.debug, log: log, "store(), key is nil"); return }

		os_log(.debug, log: log, "store()")

		if let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
			let datas = passwords.map { ["data":(try? ($0["otp"] as? OTPGenerator)?.save()) ?? Data(), "service": $0["service"]] } // Array<[String: Any]>
			let fileData = try PropertyListSerialization.data(fromPropertyList: datas, format: .binary, options: .zero)
			let encrypted = try ChaChaPoly.seal(fileData, using: AppDelegate.decryptKey!)

			isSafe = FileManager.default.createFile(atPath: dir.appendingPathComponent(OTPService.fileName).path, contents: encrypted.combined, attributes: nil)
		} else {
			os_log(.error, log: log, "store(), could not save file")
		}
	}

	func restoreOtps() throws
	{
		os_log(.debug, log: log, "restoreOtps()")

		if let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
			if let encrypted = FileManager.default.contents(atPath: dir.appendingPathComponent(OTPService.fileName).path) {
				if let sealedBox = try? ChaChaPoly.SealedBox(combined: encrypted), let data = try? ChaChaPoly.open(sealedBox, using: AppDelegate.decryptKey!) {
					if let datas = try PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? Array<[String: Any]> {
						passwords = datas.compactMap { (d) -> OTPWrapper? in
							if let data = d["data"] as? Data, data.count > 0 {
								let s = d["service"] as? Bool ?? false

								if let g = OTPRestore(from: data) {
									return ["otp": g, "service": s]
								} else {
									return nil
								}
							}

							return nil
						}
						getInServices()
						isSafe = true

						return // we have the passwords set
					} else {
						os_log(.error, log: log, "restoreOtps(), could not deserialize data")
					}
				} else {
					os_log(.error, log: log, "restoreOtps(), could not decrypt file")
				}
			} else {
				os_log(.error, log: log, "restoreOtps(), could not read file")
			}
		} else {
			os_log(.error, log: log, "restoreOtps(), no file found")
		}

		passwords = []
	}

	// MARK: Services Provider

	// Generates the OTP code at a given index and copies it into the pasteboard.
	func copyOtp(at index:Int)
	{
		if let otp = otp(at: index) {
			let pb = NSPasteboard.general
			let (code, _) = otp.generate()

			pb.clearContents()
			pb.setString(code, forType: .string)
		}
	}

	// The following methods are the callbacks from the services menu

	private func otpForService(index: Int) -> OTPGenerator?
	{
		if !inServices.isEmpty && (index < inServices.endIndex) {
			return inServices[index]["otp"] as? OTPGenerator
		} else {
			return nil
		}
	}

	@objc func otpPassword0(from pboard: NSPasteboard, userData: String) throws
	{
		pboard.clearContents()

		if let otp = otpForService(index: 0) {
			let (code, _) = otp.generate()

			os_log(.debug, log: log, "otp index 0 returning %s: %s", otp.name, code)
			pboard.setString(code, forType: .string)
		} else {
			os_log(.error, log: log, "otp index 0 not found")
			pboard.setString("", forType: .string)
		}
	}

	@objc func otpPassword1(from pboard: NSPasteboard, userData: String) throws
	{
		pboard.clearContents()

		if let otp = otpForService(index: 1) {
			let (code, _) = otp.generate()

			os_log(.debug, log: log, "otp index 1 returning %s: %s", otp.name, code)
			pboard.setString(code, forType: .string)
		} else {
			os_log(.error, log: log, "otp index 1 not found")
			pboard.setString("", forType: .string)
		}
	}

	@objc func otpPassword2(from pboard: NSPasteboard, userData: String) throws
	{
		pboard.clearContents()

		if let otp = otpForService(index: 2) {
			let (code, _) = otp.generate()

			os_log(.debug, log: log, "otp index 2 returning %s: %s", otp.name, code)
			pboard.setString(code, forType: .string)
		} else {
			os_log(.error, log: log, "otp index 2 not found")
			pboard.setString("", forType: .string)
		}
	}

	@objc func otpPassword3(from pboard: NSPasteboard, userData: String) throws
	{
		pboard.clearContents()
		if let otp = otpForService(index: 3) {
			let (code, _) = otp.generate()

			os_log(.debug, log: log, "otp index 3 returning %s: %s", otp.name, code)
			pboard.setString(code, forType: .string)
		} else {
			os_log(.error, log: log, "otp index 3 not found")
			pboard.setString("", forType: .string)
		}
	}

	@objc func otpPassword4(from pboard: NSPasteboard, userData: String) throws
	{
		pboard.clearContents()

		if let otp = otpForService(index: 4) {
			let (code, _) = otp.generate()

			os_log(.debug, log: log, "otp index 4 returning %s: %s", otp.name, code)
			pboard.setString(code, forType: .string)
		} else {
			os_log(.error, log: log, "otp index 4 not found")
			pboard.setString("", forType: .string)
		}
	}
}
