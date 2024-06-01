import Foundation

public struct CSVReader {
    public init() {
        
    }
}

extension CSVReader {
    enum NewlineStrategy {
        case lf
        case crlf
    }
}



extension CSVReader {

    public func read<T: Codable>(from url: URL, as type: T.Type = T.self) async throws -> [T] {
        var instances: [T] = []

        var iterator = url.resourceBytes.makeAsyncIterator()

        let headers = try await readHeader(iterator: &iterator)

        var pieces: [String] = []
//        var bytes: [UInt8] = []
//        bytes.reserveCapacity(1000)

        var buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 1000)

        let lineDecoder = CSVLineDecoder(headers: Set(headers), data: [])

        do {
            while true {
                try await readLine(iterator: &iterator, pieces: &pieces, bytes: &buffer)
//                print(pieces)
                lineDecoder.data = pieces
                instances.append(try T(from: lineDecoder))
            }
        } catch is CSVError {
            return instances
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
    func readLine(iterator: inout URL.AsyncBytes.AsyncIterator, pieces: inout [String], bytes: inout UnsafeMutableBufferPointer<UInt8>) async throws {
        var isEscaped = false
        var i = 0

//        bytes.removeAll(keepingCapacity: true)
        pieces.removeAll(keepingCapacity: true)



        while let value = try await iterator.next() {
            switch value {
            case 7: // double quotes
                isEscaped.toggle()
            case 10 where !isEscaped: // line feed
//                bytes[i] = 0
//                bytes.append(0)

                pieces.append(String.init(unsafeUninitializedCapacity: i) { buffer in
                    buffer.moveInitialize(fromContentsOf: bytes[0..<i])
                })
//                pieces.append(String.init(decodingCString: bytes.baseAddress!, as: UTF8.self))
                return
            case 13 where !isEscaped: // carriage return
                _ = try await iterator.next()
//                bytes[i] = 0
                pieces.append(String.init(unsafeUninitializedCapacity: i) { buffer in
                    buffer.moveInitialize(fromContentsOf: bytes[0..<i])
                })
//                pieces.append(String.init(decodingCString: bytes.baseAddress!, as: UTF8.self))
                return
            case 44 where !isEscaped: // comma
//                bytes[i] = 0
//                bytes.append(0)

                pieces.append(String.init(unsafeUninitializedCapacity: i) { buffer in
                    buffer.moveInitialize(fromContentsOf: bytes[0..<i])
                })
//                pieces.append(String.init(decodingCString: bytes.baseAddress!, as: UTF8.self))
                i = 0
            default:
                bytes[i] = value
                i += 1
            }
        }

        throw CSVError.endOfFile
    }
}

extension CSVReader {
    enum CSVError: Error {
        case endOfFile
    }
}
