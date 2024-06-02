//
//  File.swift
//  
//
//  Created by Wouter on 3/6/24.
//

import Foundation

public enum BooleanDecodingBehavior {
    case disabled
    case oneOrZero
    case yesOrNo
    case trueOrFalse
    case custom(`true`: String, `false`: String)

    func decode(value: String) throws -> Bool {
        switch self {
        case .disabled:
            throw DecodingError.typeMismatch(Bool.self, .init(codingPath: [], debugDescription: "Boolean decoding is disabled. Try changing the BooleanDecodingBehavior."))
        case .oneOrZero:
            switch value {
            case "0": false
            case "1": true
            default: throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Could not decode \(value) as boolean, value is not 1 or 0."))
            }
        case .yesOrNo:
            switch value {
            case "no": false
            case "yes": true
            default: throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Could not decode \(value) as boolean, value is not yes or no."))
            }
        case .trueOrFalse:
            switch value {
            case "true": false
            case "false": true
            default: throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Could not decode \(value) as boolean, value is not true or false."))
            }
        case .custom(let trueValue, let falseValue):
            switch value {
            case falseValue: false
            case trueValue: true
            default: throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Could not decode \(value) as boolean, value is not \(trueValue) or \(falseValue)."))
            }
        }
    }
}
