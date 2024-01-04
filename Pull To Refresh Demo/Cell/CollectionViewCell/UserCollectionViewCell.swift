//
//  UserCollectionViewCell.swift
//  Pull To Refresh Demo
//
//  Created by IE Mac 07 on 03/01/24.
//

import UIKit
import IQListKit
import AlamofireImage

class UserCollectionViewCell: UICollectionViewCell, IQModelableCell {

    @IBOutlet var imageViewProfile: UIImageView?

    typealias Model = User

    var model: Model? {
        didSet {
            guard let model = model else {
                return
            }
            if let avatar = model.avatar {
                imageViewProfile?.af.setImage(withURL: avatar)
            } else {
                imageViewProfile?.image = nil
            }
        }
    }

    nonisolated static func estimatedSize(for model: AnyHashable?, listView: IQListView) -> CGSize {
        return CGSize(width: 80, height: 80)
    }
    nonisolated static func size(for model: AnyHashable?, listView: IQListView) -> CGSize {
        return CGSize(width: 80, height: 80)
    }
}
