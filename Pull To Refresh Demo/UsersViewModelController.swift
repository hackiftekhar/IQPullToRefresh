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
    private lazy var userViewModel: UserViewModel = UserViewModel(scrollView: tableView,
                                                                  pageOffsetSyle: .pageFrom1,
                                                                  pageSize: pageSize)

    override func viewDidLoad() {
        super.viewDidLoad()

        (userViewModel.pullToRefresh.loadMoreControl as? UIActivityIndicatorView)?.style = .large

        userViewModel.modelsUpdatedObserver = { result in
            switch result {
            case .success:
                self.refreshUI(animated: true)
            case .failure:
                break
            }
        }

        userViewModel.loadingObserver = { result in
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
//        refresher.refresh()
    }

    @IBAction func clearAction(_ sender: UIBarButtonItem) {
        userViewModel.models = []
        refreshUI()
    }

    @IBAction func refreshAction(_ sender: UIBarButtonItem) {
        userViewModel.pullToRefresh.refresh()
    }

    @IBAction func loadMoreAction(_ sender: UIBarButtonItem) {
        userViewModel.pullToRefresh.loadMore()
    }

    @IBAction func stopRefreshAction(_ sender: UIBarButtonItem) {
        userViewModel.pullToRefresh.stopRefresh()
    }

    @IBAction func stopLoadMoreAction(_ sender: UIBarButtonItem) {
        userViewModel.pullToRefresh.stopLoadMore()
    }
}

extension UsersViewModelController: IQListViewDelegateDataSource {

    func refreshUI(animated: Bool = true) {
        list.performUpdates({
            let section = IQSection(identifier: 0)
            list.append(section)

            list.append(Cell.self, models: userViewModel.models, section: section)
        }, completion: { [weak self] in
            self?.tableView.bounces = true
        })
    }
}
