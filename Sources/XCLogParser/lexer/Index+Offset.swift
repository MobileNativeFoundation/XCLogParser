//
//  File.swift
//  
//
//  Created by Jose Correia Miranda Ramos on 20/10/2024.
//

import Foundation

extension String.Index {
    init(compilerSafeOffset offset: Int, in string: String) {
#if swift(>=5.0)
        self = String.Index(utf16Offset: offset, in: string)
#else
        self = String.Index(encodedOffset: offset)
#endif
    }
}
