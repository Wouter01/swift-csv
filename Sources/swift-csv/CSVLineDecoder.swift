//
//  File.swift
//  
//
//  Created by Wouter on 1/6/24.
//

import Foundation

class CSVLineDecoder: Decoder {
    let headers: Set<String>
    var data: [String]
    var tempData: String?

    var codingPath: [any CodingKey] = []

    var userInfo: [CodingUserInfoKey : Any] = [:]

    init(headers: Set<String>, data: [String]) {
        self.headers = headers
        self.data = data
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        KeyedDecodingContainer(KeyContainerDecoder<Key>(headers: headers, data: data, decoder: self))
    }

    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        fatalError()
    }

    func singleValueContainer() throws -> any SingleValueDecodingContainer {
        SVD(codingPath: codingPath, value: tempData!, decoder: self)
    }
}

extension CSVLineDecoder {

    struct SVD: SingleValueDecodingContainer {
        var codingPath: [any CodingKey]
        let value: String
        let decoder: CSVLineDecoder

        func decodeLossless<T>(_ type: T.Type) throws -> T where T: LosslessStringConvertible {
            switch T(value) {
            case .some(let value):
                return value
            case .none:
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "Could not decode double")
            }
        }

        func decodeNil() -> Bool {
            value.isEmpty
        }

        func decode(_ type: Bool.Type) throws -> Bool {
            switch value {
            case "true": true
            case "false": false
            default: throw DecodingError.dataCorruptedError(in: self, debugDescription: #"Value is not "true" or "false""#)
            }
        }

        func decode(_ type: String.Type) throws -> String {
            try decodeLossless(type)
        }

        func decode(_ type: Double.Type) throws -> Double {
            try decodeLossless(type)
        }

        func decode(_ type: Float.Type) throws -> Float {
            try decodeLossless(type)
        }

        func decode(_ type: Int.Type) throws -> Int {
            try decodeLossless(type)
        }

        func decode(_ type: Int8.Type) throws -> Int8 {
            try decodeLossless(type)
        }

        func decode(_ type: Int16.Type) throws -> Int16 {
            try decodeLossless(type)
        }

        func decode(_ type: Int32.Type) throws -> Int32 {
            try decodeLossless(type)
        }

        func decode(_ type: Int64.Type) throws -> Int64 {
            try decodeLossless(type)
        }

        func decode(_ type: UInt.Type) throws -> UInt {
            try decodeLossless(type)
        }

        func decode(_ type: UInt8.Type) throws -> UInt8 {
            try decodeLossless(type)
        }

        func decode(_ type: UInt16.Type) throws -> UInt16 {
            try decodeLossless(type)
        }

        func decode(_ type: UInt32.Type) throws -> UInt32 {
            try decodeLossless(type)
        }

        func decode(_ type: UInt64.Type) throws -> UInt64 {
            try decodeLossless(type)
        }

        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            try T(from: decoder)
        }


    }
}

extension CSVLineDecoder {
    struct KeyContainerDecoder<Key: CodingKey>: KeyedDecodingContainerProtocol {
        let headers: Set<String>
        let data: [String]
        let decoder: CSVLineDecoder

        var codingPath: [any CodingKey] = []

        var allKeys: [Key] {
            fatalError()
        }

        func contains(_ key: Key) -> Bool {
            headers.contains(key.stringValue)
        }

        func decodeNil(forKey key: Key) throws -> Bool {
            data[key.intValue!].isEmpty
        }

        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
            switch data[key.intValue!] {
            case "true": true
            case "false": false
            default: throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: #"Value is not "true" or "false""#)
            }
        }

        func decode(_ type: String.Type, forKey key: Key) throws -> String {
            return data[key.intValue!]
        }

        @inline(__always)
        func decodeLossless<T>(_ type: T.Type, forKey key: Key) throws -> T where T: LosslessStringConvertible {
            switch T(data[key.intValue!]) {
            case .some(let value):
                return value
            case .none:
                throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Could not decode double from \(data[key.intValue!])")
            }
        }

        @inline(__always)
        func decodeLossless<T>(_ type: T.Type, forKey key: Key) -> T? where T: LosslessStringConvertible {
            T(data[key.intValue!])
        }

        func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
            try decodeLossless(type, forKey: key)
        }

        func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
            try decodeLossless(type, forKey: key)
        }

        func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
            try decodeLossless(type, forKey: key)
        }

        func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
            try decodeLossless(type, forKey: key)
        }

        func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
            try decodeLossless(type, forKey: key)
        }

        func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
            try decodeLossless(type, forKey: key)
        }

        func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
            try decodeLossless(type, forKey: key)
        }

        func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
            try decodeLossless(type, forKey: key)
        }

        func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
            try decodeLossless(type, forKey: key)
        }

        func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
            try decodeLossless(type, forKey: key)
        }

        func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
            try decodeLossless(type, forKey: key)
        }

        func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
            try decodeLossless(type, forKey: key)
        }

        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
//            let decoder = JSONDecoder()
            decoder.tempData = data[key.intValue!]
            let v = try T.init(from: decoder)
            decoder.tempData = nil
            return v
//            return try decoder.decode(Map<T>.self, from: "{ \"a\": \"\(data[key.intValue!])\" }".data(using: .ascii)!).a

        }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError()
        }

        func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
            fatalError()
        }

        func superDecoder() throws -> any Decoder {
            decoder
        }

        func superDecoder(forKey key: Key) throws -> any Decoder {
            decoder
        }

        func decodeIfPresent(_ type: Double.Type, forKey key: Key) throws -> Double? {
            decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: Float.Type, forKey key: Key) throws -> Float? {
            decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: Int.Type, forKey key: Key) throws -> Int? {
            decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: Int8.Type, forKey key: Key) throws -> Int8? {
            decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: Int16.Type, forKey key: Key) throws -> Int16? {
            decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: Int32.Type, forKey key: Key) throws -> Int32? {
            decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: Int64.Type, forKey key: Key) throws -> Int64? {
            decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: UInt.Type, forKey key: Key) throws -> UInt? {
            decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: UInt8.Type, forKey key: Key) throws -> UInt8? {
            decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: UInt16.Type, forKey key: Key) throws -> UInt16? {
            decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: UInt32.Type, forKey key: Key) throws -> UInt32? {
            decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: UInt64.Type, forKey key: Key) throws -> UInt64? {
            decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: Bool.Type, forKey key: Key) throws -> Bool? {
            switch data[key.intValue!] {
            case "true": true
            case "false": false
            case "": nil
            default: throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: #"Value is not "true" or "false""#)
            }
        }

        func decodeIfPresent(_ type: String.Type, forKey key: Key) throws -> String? {
            data[key.intValue!]
        }


    }
}
