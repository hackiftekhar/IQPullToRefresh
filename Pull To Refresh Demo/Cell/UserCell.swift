//
//  UserCell.swift
//  API Client
//
//  Created by Iftekhar on 05/02/21.
//  Copyright © 2021 Iftekhar. All rights reserved.
//

import UIKit
import IQListKit
import AlamofireImage

class UserCell: UITableViewCell, IQModelableCell {

    @IBOutlet var imageViewProfile: UIImageView?
    @IBOutlet var labelName: UILabel?
    @IBOutlet var labelEmail: UILabel?

    typealias Model = User

    var model: Model? {
        didSet {
            guard let model = model else {
                return
            }

            labelName?.text = model.name
            labelEmail?.text = model.email
            if let avatar = model.avatar {
                imageViewProfile?.af.setImage(withURL: avatar)
            } else {
                imageViewProfile?.image = nil
            }
        }
    }

    nonisolated static func size(for model: AnyHashable?, listView: IQListView) -> CGSize {
        return CGSize(width: 0, height: 80)
    }
}
