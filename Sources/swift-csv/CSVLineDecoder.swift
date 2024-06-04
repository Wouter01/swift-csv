//
//  File.swift
//  
//
//  Created by Wouter on 1/6/24.
//

import Foundation

final class CSVLineDecoder: Decoder {


    var codingPath: [any CodingKey] = []

    var userInfo: [CodingUserInfoKey : Any] = [:]

    let decoderData: DecoderData

    init(data: DecoderData) {
        self.decoderData = data
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        KeyedDecodingContainer(KeyContainerDecoder<Key>(decoder: self))
    }

    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        fatalError("Not supported yet. Please file a bug report.")
    }

    func singleValueContainer() throws -> any SingleValueDecodingContainer {
        SVD(codingPath: codingPath, data: decoderData, decoder: self)
    }
}

extension CSVLineDecoder {
    final class DecoderData {
        var headers: [String]?
        var data: [String] = []
        var tempData: [String] = []
        let booleanDecodingBehavior: BooleanDecodingBehavior

        init(booleanDecodingBehavior: BooleanDecodingBehavior) {
            self.booleanDecodingBehavior = booleanDecodingBehavior
        }
    }
}

extension CSVLineDecoder {

    struct SVD: SingleValueDecodingContainer {
        var codingPath: [any CodingKey]
        let data: DecoderData
        let decoder: CSVLineDecoder

        var value: String {
            data.tempData.last!
        }

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
            try data.booleanDecodingBehavior.decode(value: value)
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
    final class KeyContainerDecoder<Key: CodingKey>: KeyedDecodingContainerProtocol {

        let decoder: CSVLineDecoder

        @inline(__always)
        var headers: [String]? {
            decoder.decoderData.headers
        }

        @inline(__always)
        var data: [String] {
            decoder.decoderData.data
        }

        @inline(__always)
        var booleanDecodingBehavior: BooleanDecodingBehavior {
            decoder.decoderData.booleanDecodingBehavior
        }


        var codingPath: [any CodingKey] = []

        init(decoder: CSVLineDecoder) {
            self.decoder = decoder
        }

        lazy var namedData: [String: String] = {
            guard let headers else { return [:] }
            return Dictionary(uniqueKeysWithValues: zip(headers, data))
        }()

        var allKeys: [Key] {
            headers?.compactMap(Key.init) ?? []
        }

        func contains(_ key: Key) -> Bool {
            headers?.contains(key.stringValue) ?? false
        }

        func decodeNil(forKey key: Key) throws -> Bool {
            try getValue(for: key).isEmpty
        }

        func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
            try booleanDecodingBehavior.decode(value: getValue(for: key))
        }

        func decode(_ type: String.Type, forKey key: Key) throws -> String {
            try getValue(for: key)
        }

        @inline(__always)
        func getValue(for key: Key) throws -> String {
            if let intValue = key.intValue, data.indices.contains(intValue) {
                return data[intValue]
            } else if let stringValue = namedData[key.stringValue] {
                return stringValue
            } else {
                throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "Could not find \(key) in headers (\(headers))"))
            }
        }

        @inline(__always)
        func decodeLossless<T>(_ type: T.Type, forKey key: Key) throws -> T where T: LosslessStringConvertible {
            let value = try getValue(for: key)
            switch T(value) {
            case .some(let value):
                return value
            case .none:
                throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Could not decode \(type) from \(value)")
            }
        }

        @inline(__always)
        func decodeLossless<T>(_ type: T.Type, forKey key: Key) throws -> T? where T: LosslessStringConvertible {
            try T(getValue(for: key))
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
            decoder.decoderData.tempData.append(try getValue(for: key))
            let v = try T.init(from: decoder)
            decoder.decoderData.tempData.removeLast()
            return v
        }

        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
            KeyedDecodingContainer(KeyContainerDecoder<NestedKey>(decoder: decoder))
        }

        func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
            fatalError("Not supported yet. Please file a bug report.")
        }

        func superDecoder() throws -> any Decoder {
            decoder
        }

        func superDecoder(forKey key: Key) throws -> any Decoder {
            decoder
        }

        func decodeIfPresent(_ type: Double.Type, forKey key: Key) throws -> Double? {
            try decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: Float.Type, forKey key: Key) throws -> Float? {
            try decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: Int.Type, forKey key: Key) throws -> Int? {
            try decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: Int8.Type, forKey key: Key) throws -> Int8? {
            try decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: Int16.Type, forKey key: Key) throws -> Int16? {
            try decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: Int32.Type, forKey key: Key) throws -> Int32? {
            try decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: Int64.Type, forKey key: Key) throws -> Int64? {
            try decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: UInt.Type, forKey key: Key) throws -> UInt? {
            try decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: UInt8.Type, forKey key: Key) throws -> UInt8? {
            try decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: UInt16.Type, forKey key: Key) throws -> UInt16? {
            try decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: UInt32.Type, forKey key: Key) throws -> UInt32? {
            try decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: UInt64.Type, forKey key: Key) throws -> UInt64? {
            try decodeLossless(type, forKey: key)
        }

        func decodeIfPresent(_ type: Bool.Type, forKey key: Key) throws -> Bool? {
            if try decodeNil(forKey: key) {
                nil
            } else {
                try booleanDecodingBehavior.decode(value: getValue(for: key))
            }
        }

        func decodeIfPresent(_ type: String.Type, forKey key: Key) throws -> String? {
            try getValue(for: key)
        }

        func decodeIfPresent<T>(_ type: T.Type, forKey key: Key) throws -> T? where T : Decodable {
            try decode(type, forKey: key)
        }
    }
}
