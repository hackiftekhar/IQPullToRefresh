//
//  HorizontalCollectionViewController.swift
//  Pull To Refresh Demo
//
//  Created by Iftekhar on 03/01/24.
//

import UIKit
import IQListKit
import IQPullToRefresh
import IQAPIClient

class HorizontalCollectionViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    typealias Cell = UserCollectionViewCell

    let pageSize = 3

    lazy var list = IQList(listView: collectionView, delegateDataSource: self)
    private lazy var usersStore: UsersStore = UsersStore(scrollView: collectionView,
                                                         pageOffsetStyle: .pageFrom1,
                                                         pageSize: pageSize)

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshUI(animated: false)
        collectionView.contentInset = .zero
        usersStore.pullToRefresh.refreshControl.mode = .userInteraction
        usersStore.pullToRefresh.refreshControl.refreshStyle = .touchRelease
        usersStore.pullToRefresh.loadMoreControl.mode = .userInteraction
        usersStore.pullToRefresh.loadMoreControl.refreshStyle = .touchRelease
        usersStore.pullToRefresh.enablePullToRefresh = true
        addObservers()
    }

    private func addObservers() {
        usersStore.addModelsUpdatedObserver(identifier: "\(Self.self)") { result in
            switch result {
            case .success:
                self.refreshUI(animated: true)
            case .failure:
                break
            }
        }

        usersStore.addStateObserver(identifier: "\(Self.self)") { result in
            switch result {
            case .none:
                print("None")
            case .refreshing:
                print("Refreshing")
            case .moreLoading:
                print("More Loading")
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        usersStore.pullToRefresh.refresh()
    }
}

extension HorizontalCollectionViewController: IQListViewDelegateDataSource {

    func refreshUI(animated: Bool = true) {
        list.performUpdates({
            let section = IQSection(identifier: 0)
            list.append(section)

            list.append(Cell.self, models: usersStore.models, section: section)
        }, completion: { [weak self] in
            self?.collectionView.bounces = true
        })
    }
}
