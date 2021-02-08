//
//  User.swift
//
//  Created by Iftekhar on 14/04/20.
//  Copyright © 2020 Iftekhar. All rights reserved.
//

import Foundation

/**
 {
   "id": 2,
   "email": "janet.weaver@reqres.in",
   "first_name": "Janet",
   "last_name": "Weaver",
   "avatar": "https://reqres.in/img/faces/2-image.jpg"
 }
 */
struct User: Decodable, Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id: Int
    var first_name: String
    var last_name: String
    var email: String
    var avatar: URL?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case first_name = "first_name"
        case last_name = "last_name"
        case email = "email"
        case avatar = "avatar"
    }

    init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        first_name = try container.decode(String.self, forKey: .first_name)
        last_name = try container.decode(String.self, forKey: .last_name)
        email = try container.decode(String.self, forKey: .email)
        avatar = try container.decodeIfPresent(URL.self, forKey: .avatar)
    }
}
