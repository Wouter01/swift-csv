//
//  File.swift
//  
//
//  Created by Wouter on 2/6/24.
//

public enum CSVError: Error {
    case invalidRow(pieces: [String])
    case invalidDelimiter
    case invalidEscapeCharacter
}
