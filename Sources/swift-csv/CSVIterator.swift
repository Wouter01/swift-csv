//
//  File.swift
//  
//
//  Created by Wouter on 2/6/24.
//

import Foundation

public struct CSVIterator<T: Decodable>: AsyncIteratorProtocol {
    public typealias Element = T

    var iterator: URL.AsyncBytes.AsyncIterator

    var pieces: [String] = []

    var bytes: [UInt8] = []

    public let headers: [String]
    let headerCount: Int
    let skipInvalidRows: Bool
    let lineDecoder: CSVLineDecoder

    public init(url: URL, skipInvalidRows: Bool = false) async throws {
        var iterator = url.resourceBytes.makeAsyncIterator()

        self.headers = try await Self.readHeader(iterator: &iterator)
        self.skipInvalidRows = skipInvalidRows
        self.iterator = iterator
        self.headerCount = headers.count
        self.lineDecoder = CSVLineDecoder(headers: Set(headers), data: [])

        pieces.reserveCapacity(headerCount)
    }

    public mutating func next() async throws -> Element? {
        guard try await readLine() else {
            return nil
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

    static func readHeader(iterator: inout URL.AsyncBytes.AsyncIterator) async throws -> [String] {
        var headers: [String] = []
        var piece: [UInt8] = []

        while let el = try await iterator.next() {
            switch el {
            case 44: // comma
                piece.append(0)
                headers.append(String(cString: piece))
                piece.removeAll()
            case 10: // line feed
                piece.append(0)
                headers.append(String(cString: piece))
                return headers
            case 13: // carriage return
                // LF is expected as next character, do nothing
                continue
            default:
                piece.append(el)
            }
        }

        return headers
    }


    mutating func readLine() async throws -> Bool {
        var isEscaped = false

        var startIndex: Int = 0

        bytes.removeAll(keepingCapacity: true)
        pieces.removeAll(keepingCapacity: true)

        while let value = try await iterator.next() {
            switch value {
            case 34: // double quotes
                startIndex = 1
                isEscaped.toggle()
                if isEscaped {
                    bytes.append(value)
                }

            case 10 where !isEscaped: // line feed
                pieces.append(String(decoding: bytes[startIndex...], as: UTF8.self))
                return true

            case 13 where !isEscaped: // carriage return
                _ = try await iterator.next()
                pieces.append(String(decoding: bytes[startIndex...], as: UTF8.self))
                return true

            case 44 where !isEscaped: // comma
                pieces.append(String(decoding: bytes[startIndex...], as: UTF8.self))
                bytes.removeAll(keepingCapacity: true)
                startIndex = 0

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
    public func makeAsyncIterator() -> CSVIterator<T> {
        self
    }
    
    public typealias AsyncIterator = Self


}
