//
//  OTP.swift
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

import Foundation
import CryptoKit
import os

fileprivate let log = OSLog(subsystem: Bundle.main.bundleIdentifier! + ".otp", category: "jcat")

enum DecodingScheme
{
	case none
	case base32
	case zBase32
	case base64
}

enum HashingAlgorithm: Int
{
	case sha1
	case sha256
	case sha384
	case sha512
}

protocol OTPGenerator
{
	var name: String { get }
	var digits: Int { get }
	var period: TimeInterval { get }

	func generate() -> (code:String, count:Int)
	func save() throws -> Data
}

struct OTP<H> where H: HashFunction
{
	let name: String
	let secretKey: Data
	let algorithm: HMAC<H>.Type
	let digits: Int
	let period: TimeInterval

	init?(name: String, secret: String, scheme: DecodingScheme = .base32, digits:Int = 6, period tseg:Int = 30)
	{
		let data: Data?

		self.name = name
		self.algorithm = HMAC<H>.self
		self.digits = digits
		self.period = TimeInterval(tseg)

		switch scheme {
			case .base32:
				data = Data(baseTable: b32table, base32str: secret)
			case .zBase32:
				data = Data(baseTable: zB32table, base32str: secret)
			case .base64:
				data = Data(base64Encoded: secret)
			case .none:
				data = nil
		}

		if data != nil {
			self.secretKey = data!
		} else {
			return nil
		}
	}

	/// Algorithm
	/// from: https://developer.apple.com/forums/thread/120918
	/// see also: https://tools.ietf.org/html/rfc6238#section-4
	func generate() -> (code:String, count:Int)
	{
		let counter = Date().timeIntervalSince1970/period
		var t = UInt64(counter).bigEndian

		let counterData = withUnsafeBytes(of: &t) { Array($0) }
		let hash = algorithm.authenticationCode(for: counterData, using: SymmetricKey(data: secretKey))

		var truncatedHash = hash.withUnsafeBytes { ptr -> UInt32 in
			let offset = ptr[hash.byteCount - 1] & 0x0F

			let truncatedHashPtr = ptr.baseAddress! + Int(offset)
			return truncatedHashPtr.bindMemory(to: UInt32.self, capacity: 1).pointee
		}

		truncatedHash = UInt32(bigEndian: truncatedHash)
		truncatedHash = truncatedHash & 0x7FFF_FFFF
		truncatedHash = truncatedHash % UInt32(pow(10, Float(digits)))

		return (String(format: "%0*u", digits, truncatedHash), Int(period*modf(counter).1 + 1))
	}
}

extension OTP: CustomDebugStringConvertible
{
	var debugDescription: String { "OTPGenerator for \(name)" }
}

extension OTP: OTPGenerator // for loading and saving
{
	init(name: String, secretKey: Data, digits: Int, period: Int)
	{
		self.name = name
		self.secretKey = secretKey
		self.digits = digits
		self.period = TimeInterval(period)
		self.algorithm = HMAC<H>.self
	}

	func save() throws -> Data
	{
		os_log(.debug, log: log, "save() %s", name)

		let algo: HashingAlgorithm

		if algorithm is HMAC<SHA256>.Type {
			algo = .sha256
		} else if algorithm is HMAC<SHA384>.Type {
			algo = .sha384
		} else if algorithm is HMAC<SHA512>.Type {
			algo = .sha512
		} else {
			algo = .sha1
		}

		let info: Dictionary<String, Any> = ["name": self.name,
														 "secretKey": self.secretKey,
														 "algorithm": algo.rawValue,
														 "digits": self.digits,
														 "period": Int(self.period)];

		return try PropertyListSerialization.data(fromPropertyList: info, format: .binary, options: .zero)
	}
}

func OTPRestore(from data: Data) -> OTPGenerator?
{
	os_log(.debug, log: log, "OTPRestore(from:)")

	if let info = try? PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? Dictionary<String, Any> {
		if let name = info["name"] as? String,
			let secretKey = info["secretKey"] as? Data,
			let algo = info["algorithm"] as? Int, let algorithm = HashingAlgorithm(rawValue: algo),
			let digits = info["digits"] as? Int,
			let period = info["period"] as? Int {

			switch algorithm {
				case .sha1:
					return OTP<Insecure.SHA1>(name: name, secretKey: secretKey, digits: digits, period: period)
				case .sha256:
					return OTP<SHA256>(name: name, secretKey: secretKey, digits: digits, period: period)
				case .sha384:
					return OTP<SHA384>(name: name, secretKey: secretKey, digits: digits, period: period)
				case .sha512:
					return OTP<SHA512>(name: name, secretKey: secretKey, digits: digits, period: period)
			}
		} else {
			os_log(.error, log: log, "OTPRestore(from:), could not get data")
		}
	} else {
		os_log(.error, log: log, "OTPRestore(from:), could not deserialize data")
	}

	return nil
}

// MARK: - base 32 & family
// see: https://en.wikipedia.org/wiki/Base32 & https://www.ietf.org/rfc/rfc4648.txt

private let zB32table: Array<Character> = ["y", "b", "n", "d", "r", "f", "g", "8",
														 "e", "j", "k", "m", "c", "p", "q", "x",
														 "o", "t", "1", "u", "w", "i", "s", "z",
														 "a", "3", "4", "5", "h", "7", "6", "9"]

private let b32table: Array<Character> = ["a", "b", "c", "d", "e", "f", "g", "h",
														"i", "j", "k", "l", "m", "n", "o", "p",
														"q", "r", "s", "t", "u", "v", "w", "x",
														"y", "z", "2", "3", "4", "5", "6", "7"]

private extension Data
{
	init?(baseTable: Array<Character> = b32table, base32str: String)
	{
		self.init(capacity: 5*base32str.count/8)

		let trimmingChars = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "="))
		let str = base32str.lowercased().trimmingCharacters(in: trimmingChars) // normalize it

		var value40: UInt64 = 0 // we'll only use the first 40 bits of this becuase 5*8 = 40
		let lastIndex = str.count - 1 // index of the last char in the str, isn't: str.index(before: str.endIndex).utf16Offset(in: str) more clear?

		var counter = 1 // recycling counter of the number of b32 words read

		for (w, char) in str.enumerated() { // w = b32 word counter, b32 word == 5 bits
			if let value = baseTable.firstIndex(where: { $0 == char }) { // search for the word value in the table
				let m = (w + 1) % 8 // mod of the word count +1 with 8, when ZERO then matched with an exact byte (8 bits)

				value40 = (value40 << 5) | UInt64(value) // storing the b32 value and putting it in its place

				if (m == 0) || (w == lastIndex) { // if we can write an exact number of bytes or we are the last one
					var be = (value40 << 24).bigEndian // the value to be written into the data, moved to the left the remaining bites and in standard endianess
					let c = counter*5/8 + ((m == 0) ? 0 : 1) // the bytes to be written into the data, we write 5 bytes and the time which correspond to 8 b32 words

					self.append(Data(bytes: &be, count: c)) // writing the data

					value40 = 0 // reset
					counter = 0
				}
			} else {
				return nil
			}

			counter += 1
		}
	}
}
