//
//  ProgrrammaticallyUsersViewModelController.swift
//  Pull To Refresh Demo
//
//  Created by Iftekhar on 5/16/23.
//

import UIKit

import UIKit
import IQAPIClient
import IQPullToRefresh
import IQListKit

class ProgrrammaticallyUsersViewModelController: UIViewController {

    typealias Cell = UserCell
    typealias Model = User

    let pageSize = 3

    let tableView = UITableView()
    @IBOutlet var loadMoreButton: UIBarButtonItem!
    @IBOutlet var clearButton: UIBarButtonItem!

    lazy var list = IQList(listView: tableView, delegateDataSource: self)
    private lazy var usersStore: UsersStore = UsersStore(scrollView: tableView,
                                                         pageOffsetSyle: .pageFrom1,
                                                         pageSize: pageSize)

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        usersStore.pullToRefresh.refresh()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor)
        ])

        let searchBar = UISearchBar()
        searchBar.sizeToFit()
        let headerView = UIView(frame: searchBar.bounds)
        headerView.addSubview(searchBar)
        self.tableView.tableHeaderView = headerView


        tableView.separatorStyle = .none
        tableView.allowsSelection = true
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 116
        tableView.estimatedSectionFooterHeight = 1
        tableView.estimatedSectionFooterHeight = 1
        tableView.bounces = true
        tableView.alwaysBounceVertical = true

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }



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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        refresher.refresh()
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

extension ProgrrammaticallyUsersViewModelController: IQListViewDelegateDataSource {

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
