//
//  File.swift
//  
//
//  Created by Wouter on 2/6/24.
//

import Foundation

/// A CSV iterator can lazily parse a CSV file. The whole file is not loaded into memory. Instead, it is parsed when the data is requested. If the data is not stored outside the iterator, the file can be parsed without using a lot of memory. The iterator can parse local and remote data.
public struct AsyncCodableCSVIterator<T: Decodable, Encoding: _UnicodeEncoding>: AsyncIteratorProtocol where Encoding.CodeUnit == UInt8 {
    public typealias Element = T

    var iterator: AsyncRawCSVIterator<Encoding>

    var pieces: [String] = []

    var bytes: [UInt8] = []

    public var headers: [String]? {
        didSet {
            lineDecoder.decoderData.headers = headers
        }
    }
    
    let lineDecoder: CSVLineDecoder


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
        as: T.Type = T.self,
        hasHeaders: Bool = true,
        skipInvalidRows: Bool = false,
        delimiter: Character = ",",
        escapeCharacter: Character = "\"",
        encoding: Encoding.Type = UTF8.self,
        booleanDecodingBehavior: BooleanDecodingBehavior = .disabled
    ) async throws {
        let iterator = try await AsyncRawCSVIterator(url: url, hasHeaders: hasHeaders, skipInvalidRows: skipInvalidRows, delimiter: delimiter, escapeCharacter: escapeCharacter, encoding: encoding)

        self.iterator = iterator
        self.headers = iterator.headers
        self.lineDecoder = CSVLineDecoder(data: .init(booleanDecodingBehavior: booleanDecodingBehavior))
    }

    public mutating func next() async throws -> Element? {
        guard let pieces = try await iterator.next() else {
            return nil
        }
        lineDecoder.decoderData.data = pieces
        return try T(from: lineDecoder)
    }
}

extension AsyncCodableCSVIterator: AsyncSequence {
    @inlinable
    public func makeAsyncIterator() -> Self {
        self
    }
}
