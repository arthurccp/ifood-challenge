//
//  Data.swift
//  ifood-challenge
//
//  Created by Arthur Silva on 14/10/26.
//

import Foundation

struct ApiRest: Codable {
    let results : [Result]
}

struct Result : Codable {
    let id: Int
    let name,status,species,gender, image: String
    let type: String
    let url: String
    let created: String
    let origin: CharacterPlace
    let location: CharacterPlace
    let episode: [String]
}

struct CharacterPlace: Codable {
    let name: String
    let url: String
}
