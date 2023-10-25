//
//  UsersViewModelController.swift
//  Pull To Refresh Demo
//
//  Created by Iftekhar on 1/18/23.
//

import UIKit
import IQAPIClient
import IQPullToRefresh
import IQListKit

class UsersViewModelController: UITableViewController {

    typealias Cell = UserCell
    typealias Model = User

    let pageSize = 3

    @IBOutlet var refreshButton: UIBarButtonItem!
    @IBOutlet var loadMoreButton: UIBarButtonItem!
    @IBOutlet var clearButton: UIBarButtonItem!

    lazy var list = IQList(listView: tableView, delegateDataSource: self)
    private lazy var usersStore: UsersStore = UsersStore(scrollView: tableView,
                                                         pageOffsetSyle: .pageFrom1,
                                                         pageSize: pageSize)

    override func viewDidLoad() {
        super.viewDidLoad()

        (usersStore.pullToRefresh.loadMoreControl as? UIActivityIndicatorView)?.style = .large

        usersStore.modelsUpdatedObserver = { result in
            switch result {
            case .success:
                self.refreshUI(animated: true)
            case .failure:
                break
            }
        }

        usersStore.loadingObserver = { result in
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

    @IBAction func clearAction(_ sender: UIBarButtonItem) {
        usersStore.models = []
        refreshUI()
    }

    @IBAction func refreshAction(_ sender: UIBarButtonItem) {
        usersStore.pullToRefresh.refresh()
    }

    @IBAction func loadMoreAction(_ sender: UIBarButtonItem) {
        usersStore.pullToRefresh.loadMore()
    }

    @IBAction func stopRefreshAction(_ sender: UIBarButtonItem) {
        usersStore.pullToRefresh.stopRefresh()
    }

    @IBAction func stopLoadMoreAction(_ sender: UIBarButtonItem) {
        usersStore.pullToRefresh.stopLoadMore()
    }
}

extension UsersViewModelController: IQListViewDelegateDataSource {

    func refreshUI(animated: Bool = true) {
        list.performUpdates({
            let section = IQSection(identifier: 0)
            list.append(section)

            list.append(Cell.self, models: usersStore.models, section: section)
        }, completion: { [weak self] in
            self?.tableView.bounces = true
        })
    }
}
