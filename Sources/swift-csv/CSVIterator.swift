//
//  File.swift
//  
//
//  Created by Wouter on 2/6/24.
//

import Foundation

public struct CSVIterator<T: Decodable, Encoding: _UnicodeEncoding>: AsyncIteratorProtocol where Encoding.CodeUnit == UInt8 {
    public typealias Element = T

    var iterator: URL.AsyncBytes.AsyncIterator

    var pieces: [String] = []

    var bytes: [UInt8] = []

    public internal(set) var headers: [String]?
    var headerCount: Int?
    let skipInvalidRows: Bool
    let lineDecoder: CSVLineDecoder
    let delimiter: UInt8
    let escapeCharacter: UInt8

    public init(url: URL, hasHeaders: Bool = true, skipInvalidRows: Bool = false, delimiter: Character = ",", escapeCharacter: Character = "\"", encoding: Encoding.Type = UTF8.self) async throws {
        var iterator = url.resourceBytes.makeAsyncIterator()

        self.skipInvalidRows = skipInvalidRows
        self.iterator = iterator
        self.lineDecoder = CSVLineDecoder(headers: [], data: [])

        guard let delimiter = delimiter.asciiValue else {
            throw CSVError.invalidDelimiter
        }

        guard let escapeCharacter = escapeCharacter.asciiValue else {
            throw CSVError.invalidEscapeCharacter
        }

        self.delimiter = delimiter
        self.escapeCharacter = escapeCharacter

        if hasHeaders {
            try await readLine()
            self.headers = pieces
            let headerCount = pieces.count
            self.headerCount = headerCount
            self.lineDecoder.headers = Set(pieces)
            pieces.reserveCapacity(headerCount)
        }
    }

    public mutating func next() async throws -> Element? {
        guard try await readLine() else {
            return nil
        }

        if headerCount == nil {
            headerCount = pieces.count
        }

        guard pieces.count == headerCount else {
            if skipInvalidRows {
                return try await next()
            } else {
                throw CSVError.invalidRow(pieces: pieces)
            }
        }
        lineDecoder.data = pieces
        return try T(from: lineDecoder)
    }

    mutating func readLine() async throws -> Bool {
        var isEscaped = false

        var startIndex: Int = 0

        bytes.removeAll(keepingCapacity: true)
        pieces.removeAll(keepingCapacity: true)

        while let value = try await iterator.next() {
            switch value {

            case escapeCharacter: // double quotes
                startIndex = 1
                isEscaped.toggle()
                if isEscaped {
                    bytes.append(value)
                }

            case delimiter where !isEscaped: // comma
                pieces.append(String(decoding: bytes[startIndex...], as: Encoding.self))
                bytes.removeAll(keepingCapacity: true)
                startIndex = 0


            case 10 where !isEscaped: // line feed
                pieces.append(String(decoding: bytes[startIndex...], as: Encoding.self))
                return true

            case 13 where !isEscaped: // carriage return
                _ = try await iterator.next()
                pieces.append(String(decoding: bytes[startIndex...], as: Encoding.self))
                return true




            default:
                bytes.append(value)
            }
        }

        if !bytes.isEmpty {
            pieces.append(String(decoding: bytes[startIndex...], as: UTF8.self))
        }

        return !pieces.isEmpty
    }
}

extension CSVIterator: AsyncSequence {
    public func makeAsyncIterator() -> CSVIterator<T, Encoding> {
        self
    }
    
    public typealias AsyncIterator = Self


}
