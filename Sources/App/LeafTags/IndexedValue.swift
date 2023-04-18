//
//  File.swift
//  
//
//  Created by Ben Schultz on 4/18/23.
//

import Vapor
import Leaf

public final class IndexedValue: LeafTag {
    public func render(_ parsed: LeafContext) throws -> LeafData {
        try parsed.requireParameterCount(2)

        if let index = parsed.parameters[1].int,
           let labels = parsed.parameters[0].array
        {
            if labels.count <= index {
                return .nil(.string)
            }
            else {
                return labels[index]
            }
        } else {
            return .nil(.string)
        }
        
    }
}
