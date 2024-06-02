//
//  File.swift
//  
//
//  Created by Wouter on 3/6/24.
//

import Foundation

/// A CSV iterator can lazily parse a CSV file. The whole file is not loaded into memory. Instead, it is parsed when the data is requested. If the data is not stored outside the iterator, the file can be parsed without using a lot of memory. The iterator can parse local and remote data.
public struct AsyncRawAsDictCSVIterator<Encoding: _UnicodeEncoding>: AsyncIteratorProtocol where Encoding.CodeUnit == UInt8 {
    public typealias Element = [String: String]

    var iterator: AsyncRawCSVIterator<Encoding>

    public internal(set) var headers: [String]

    /// Create a new CSV iterator for the given URL.
    /// - Parameters:
    ///   - url: The CSV source. This can be a URL to a local or remote file.
    ///   - skipInvalidRows: If enabled, no errors will be thrown for rows that have an incorrect amount of columns.
    ///   - delimiter: The delimiter used in the CSV file. By default, a comma ',' is used.
    ///   - escapeCharacter: The escape character used in the CSV file. By default, a double quote '"' is used.
    ///   - encoding: The encoding for the fields in the CSV. Before splitting the data into multiple fields, it is interpreted as being ASCII, following the CSV specification. Afterwards, fields are converted to strings with the specified encoding. By default, UTF8 is used.
    public init(
        url: URL,
        skipInvalidRows: Bool = false,
        delimiter: Character = ",",
        escapeCharacter: Character = "\"",
        encoding: Encoding.Type = UTF8.self
    ) async throws {
        let iterator = try await AsyncRawCSVIterator(url: url, hasHeaders: true, skipInvalidRows: skipInvalidRows, delimiter: delimiter, escapeCharacter: escapeCharacter, encoding: encoding)

        self.iterator = iterator

        self.headers = iterator.headers!
    }

    public mutating func next() async throws -> Element? {
        try await iterator.next().map { Dictionary(uniqueKeysWithValues: zip(headers, $0)) }
    }
}

extension AsyncRawAsDictCSVIterator: AsyncSequence {
    public func makeAsyncIterator() -> Self {
        self
    }
}
