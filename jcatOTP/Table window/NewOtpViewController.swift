//
//  NewOtpViewController.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 8/2/20.
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
import CryptoKit

class NewOtpViewController: NSViewController
{
	@objc dynamic var otpName: String? = ""
	@objc dynamic var secret: String? = ""
	@objc dynamic var digits: NSNumber? = 6
	@objc dynamic var period: NSNumber? = 30

	weak var ovc: AnyObject? = nil

	var encoding: DecodingScheme = .base32
	var algorithm: Int = 1

	@IBAction func setEncoding(_ sender: Any?)
	{
		if let tag = (sender as? NSButton)?.tag {
			switch tag {
				case 100:
					encoding = .base32
				case 200:
					encoding = .zBase32
				case 300:
					encoding = .base64
				default:
					encoding = .none
			}
		}
	}

	@IBAction func setAlgorithm(_ sender: Any?)
	{
		if let tag = (sender as? NSButton)?.tag {
			switch tag {
				case 400:
					algorithm = 1
				case 500:
					algorithm = 2
				case 600:
					algorithm = 3
				case 700:
					algorithm = 4
				default:
					algorithm = -1
			}
		}
	}

	@IBAction func ok(_ sender: Any)
	{
		guard (otpName != nil) && (secret != nil) else { return }
		guard (digits != nil) && (period != nil) else { return }
		guard ovc != nil else { return } // we must know the outline view controller

		var success: Bool = false

		if !otpName!.isEmpty {
			if let trimSecret = secret?.trimmingCharacters(in: .whitespacesAndNewlines), !trimSecret.isEmpty {
				switch algorithm {
					case 1:
						if let otp = OTP<Insecure.SHA1>(name: otpName!, secret: trimSecret, scheme: encoding, digits: digits!.intValue, period: period!.intValue) {
							OTPService.shared.add(otp: otp)
							success = true
						}
					case 2:
						if let otp = OTP<SHA256>(name: otpName!, secret: trimSecret, scheme: encoding, digits: digits!.intValue, period: period!.intValue) {
							OTPService.shared.add(otp: otp)
							success = true
						}
					case 3:
						if let otp = OTP<SHA384>(name: otpName!, secret: trimSecret, scheme: encoding, digits: digits!.intValue, period: period!.intValue) {
							OTPService.shared.add(otp: otp)
							success = true
						}
					case 4:
						if let otp = OTP<SHA512>(name: otpName!, secret: trimSecret, scheme: encoding, digits: digits!.intValue, period: period!.intValue) {
							OTPService.shared.add(otp: otp)
							success = true
						}
					default:
						break
				}
			}
		}

		if !success {
			let alert = NSAlert()

			alert.icon = NSImage(named: "jcat")
			alert.messageText = "Error Creating OTP"
			alert.informativeText = "Check the parameters and please try again."
			alert.alertStyle = .warning
			alert.runModal()
		} else {
			dismiss(self)
		}
	}

	@IBAction func cancel(_ sender: Any)
	{
		dismiss(self)
	}

	// mostly sets the defaults values if the field is left empty
	override func setNilValueForKey(_ key: String)
	{
		if key == "otpName" {
			otpName = "no name"
		} else if key == "secret" {
			secret = ""
		} else if key == "digits" {
			digits = 6
		} else if key == "period" {
			period = 30
		}
	}
}
