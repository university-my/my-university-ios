//
//  Classroom.swift
//  My University
//
//  Created by Yura Voevodin on 11/11/18.
//  Copyright © 2018 Yura Voevodin. All rights reserved.
//

import Foundation

struct Classroom {
    
    let id: Int64
    let isFavorite: Bool
    let name: String
    let slug: String
}

extension Classroom: EntityRepresentable {}