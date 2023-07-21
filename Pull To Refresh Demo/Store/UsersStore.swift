//
//  UsersStore.swift
//  Pull To Refresh Demo
//
//  Created by Iftekhar on 1/18/23.
//

import UIKit
import IQPullToRefresh
import IQAPIClient

class UsersStore: IQRefreshAbstractWrapper<User> {

    override func request(page: Int, size: Int, completion: @escaping (Result<[User], Error>) -> Void) {
        IQAPIClient.users(page: page, perPage: size, completion: completion)
    }
}
