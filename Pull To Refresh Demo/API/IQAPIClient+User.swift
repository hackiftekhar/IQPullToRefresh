//
//  ITAPiClient+User.swift
//  Institute
//
//  Created by Iftekhar on 31/05/20.
//  Copyright © 2020 Iftekhar. All rights reserved.
//

import IQAPIClient
import Alamofire

extension IQAPIClient {

    @discardableResult
    func users(page: Int, perPage: Int,
               completion: @escaping (_ result: Swift.Result<[User], Error>) -> Void) -> DataRequest {
        //        let delay = page <= 1 ? 5 : 5
        let delay = 2
        let parameters = ["delay": delay, "page": page, "per_page": perPage]
        let path = APIPath.users.rawValue
        return sendRequest(path: path, parameters: parameters, completionHandler: completion)
    }

    @discardableResult
    func user(id: Int,
              completion: @escaping (_ result: Swift.Result<User, Error>) -> Void) -> DataRequest {
        let parameters = ["delay": 2, "per_page": 10]
        let path = APIPath.users.rawValue + "/\(id)"
        return sendRequest(path: path, parameters: parameters, completionHandler: completion)
    }
}
