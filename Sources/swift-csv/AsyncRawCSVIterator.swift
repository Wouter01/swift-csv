//
//  File.swift
//  
//
//  Created by Wouter on 2/6/24.
//

import Foundation

/// A CSV iterator can lazily parse a CSV file. The whole file is not loaded into memory. Instead, it is parsed when the data is requested. If the data is not stored outside the iterator, the file can be parsed without using a lot of memory. The iterator can parse local and remote data.
public struct AsyncRawCSVIterator<Encoding: _UnicodeEncoding>: AsyncIteratorProtocol where Encoding.CodeUnit == UInt8 {
    public typealias Element = [String]

    var iterator: URL.AsyncBytes.AsyncIterator

    @usableFromInline
    var pieces: [String] = []

    var bytes: [UInt8] = []

    public private(set) var headers: [String]?

    @usableFromInline
    var headerCount: Int?
    @usableFromInline
    let skipInvalidRows: Bool
    let delimiter: UInt8
    let escapeCharacter: UInt8

    /// Create a new CSV iterator for the given URL.
    /// - Parameters:
    ///   - url: The CSV source. This can be a URL to a local or remote file.
    ///   - as: The type to decode to.
    ///   - hasHeaders: Mark whether the CSV file has a header. If true, the header will be used to check if each row has a valid length. If false, the first row length will be used instead.
    ///   - skipInvalidRows: If enabled, no errors will be thrown for rows that have an incorrect amount of columns.
    ///   - delimiter: The delimiter used in the CSV file. By default, a comma ',' is used.
    ///   - escapeCharacter: The escape character used in the CSV file. By default, a double quote '"' is used.
    ///   - encoding: The encoding for the fields in the CSV. Before splitting the data into multiple fields, it is interpreted as being ASCII, following the CSV specification. Afterwards, fields are converted to strings with the specified encoding. By default, UTF8 is used.
    public init(
        url: URL,
        hasHeaders: Bool = true,
        skipInvalidRows: Bool = false,
        delimiter: Character = ",",
        escapeCharacter: Character = "\"",
        encoding: Encoding.Type = UTF8.self
    ) async throws {
        let iterator = url.resourceBytes.makeAsyncIterator()

        self.skipInvalidRows = skipInvalidRows
        self.iterator = iterator

        guard let delimiter = delimiter.asciiValue else {
            throw CSVError.invalidDelimiter
        }

        guard let escapeCharacter = escapeCharacter.asciiValue else {
            throw CSVError.invalidEscapeCharacter
        }

        self.delimiter = delimiter
        self.escapeCharacter = escapeCharacter

        if hasHeaders {
            _ = try await readLine()
            self.headers = pieces
            let headerCount = pieces.count
            self.headerCount = headerCount
            pieces.reserveCapacity(headerCount)
        }
    }

    @inlinable
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

        return pieces
    }

    @usableFromInline
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

extension AsyncRawCSVIterator: AsyncSequence {
    @inlinable
    public func makeAsyncIterator() -> Self {
        self
    }
}
