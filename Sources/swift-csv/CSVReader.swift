import Foundation

public struct CSVReader {
    public init() {
        
    }
}

extension CSVReader {

    public func read<T: Codable>(from url: URL, as type: T.Type = T.self, skipInvalidRows: Bool = true) async throws -> [T] {
        var instances: [T] = []

        var iterator = url.resourceBytes.makeAsyncIterator()

        let headers = try await readHeader(iterator: &iterator)
        let headerCount = headers.count

        var pieces: [String] = []
        pieces.reserveCapacity(headerCount)
        var bytes: [UInt8] = []

        let lineDecoder = CSVLineDecoder(headers: Set(headers), data: [])

        while try await readLine(iterator: &iterator, pieces: &pieces, bytes: &bytes) {
            guard pieces.count == headerCount else {
                if skipInvalidRows {
                    continue
                } else {
                    throw CSVError.invalidRow(pieces: pieces)
                }
            }
            lineDecoder.data = pieces
            instances.append(try T(from: lineDecoder))
        }

        if !pieces.isEmpty {
            guard pieces.count == headerCount else {
                if skipInvalidRows {
                    return instances
                } else {
                    throw CSVError.invalidRow(pieces: pieces)
                }
            }
            lineDecoder.data = pieces
            instances.append(try T(from: lineDecoder))
        }

        return instances
    }

    func readHeader(iterator: inout URL.AsyncBytes.AsyncIterator) async throws -> [String] {
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

//    @inline(__always)
    func readLine(iterator: inout URL.AsyncBytes.AsyncIterator, pieces: inout [String], bytes: inout [UInt8]) async throws -> Bool {
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

        return false
    }
}

extension CSVReader {
    enum CSVError: Error {
        case invalidRow(pieces: [String])
    }
}
