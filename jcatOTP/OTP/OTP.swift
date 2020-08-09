//
//  OTP.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 8/2/20.
//  Copyright © 2020 jCat.io. All rights reserved.
//

import Foundation
import CryptoKit

enum DecodingScheme
{
	case none
	case base32
	case zBase32
	case base64
}

protocol OTPGenerator
{
	var name: String { get }
	var digits: Int { get }
	var period: TimeInterval { get }

	func generate() -> (code:Int, count:Int)
}

struct OTP<H>: OTPGenerator where H: HashFunction
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
	func generate() -> (code:Int, count:Int)
	{
		let counter = Date().timeIntervalSince1970/period
		var t = UInt64(counter).bigEndian

		let counterData = withUnsafeBytes(of: &t) { Array($0) }
		let hash = algorithm.authenticationCode(for: counterData, using: SymmetricKey(data: secretKey))

		var truncatedHash = hash.withUnsafeBytes { ptr -> UInt32 in
			let offset = ptr[hash.byteCount - 1] & 0x0f

			let truncatedHashPtr = ptr.baseAddress! + Int(offset)
			return truncatedHashPtr.bindMemory(to: UInt32.self, capacity: 1).pointee
		}

		truncatedHash = UInt32(bigEndian: truncatedHash)
		truncatedHash = truncatedHash & 0x7FFF_FFFF
		truncatedHash = truncatedHash % UInt32(pow(10, Float(digits)))

		return (Int(truncatedHash), Int(period*modf(counter).1 + 1))
		//return String(format: "%0*u", digits, truncatedHash)
	}
}

extension OTP: CustomDebugStringConvertible
{
	var debugDescription: String { "OTPGenerator for \(name)" }
}

// MARK: - base 32
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

extension String
{
	func isValid(baseTable: Array<Character> = b32table) -> Bool
	{
		return true
	}
}
