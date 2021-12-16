//
//  UsersViewController.swift
//  RefreshLoadMore
//
//  Created by iftekhar on 07/02/21.
//

import UIKit
import IQAPIClient
import IQListKit
import IQPullToRefresh

class UsersViewController: UITableViewController {

    typealias Cell = UserCell
    typealias Model = User

    let pageSize = 3

    @IBOutlet var refreshButton: UIBarButtonItem!
    @IBOutlet var loadMoreButton: UIBarButtonItem!
    @IBOutlet var clearButton: UIBarButtonItem!
    var models = [Model]()

    lazy var list = IQList(listView: tableView, delegateDataSource: self)
    lazy var refresher = IQPullToRefresh(scrollView: tableView, refresher: self, moreLoader: self)

    override func viewDidLoad() {
        super.viewDidLoad()

//        tableView.contentInset = UIEdgeInsets(top: 100, left: 0, bottom: 100, right: 0)

        refresher.enablePullToRefresh = true

//        let customPullToRefresh = CustomPullToRefresh()
//        refresher.refreshControl = customPullToRefresh

//        let soupPullToRefresh = SoupView.soapView()
//        refresher.refreshControl = soupPullToRefresh

//        let customPullToRefresh = ProgressPullToRefresh()
//        refresher.refreshControl = customPullToRefresh

//        let customLoadMore = ProgressPullToRefresh()
//        refresher.loadMoreControl = customLoadMore

//        let customLoadMore = PreloadActivityIndicatorView(style: .gray)
//        refresher.loadMoreControl = customLoadMore

//        let newRefreshIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
//        newRefreshIndicatorView.hidesWhenStopped = false
//        newRefreshIndicatorView.color = UIColor.green
//        refresher.refreshControl = newRefreshIndicatorView

//        let newLoadMoreIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
//        newLoadMoreIndicatorView.hidesWhenStopped = false
//        newLoadMoreIndicatorView.color = UIColor.purple
//        refresher.loadMoreControl = newLoadMoreIndicatorView

        refreshUI(animated: false)
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        refresher.refresh()
    }

    @IBAction func clearAction(_ sender: UIBarButtonItem) {
        models = []
        refresher.enableLoadMore = false
        refreshUI()
    }

    @IBAction func refreshAction(_ sender: UIBarButtonItem) {
        refresher.refresh()
    }

    @IBAction func loadMoreAction(_ sender: UIBarButtonItem) {
        refresher.loadMore()
    }
}

// Refresher
extension UsersViewController: Refreshable, MoreLoadable {

    func refreshTriggered(type: IQPullToRefresh.RefreshType,
                          loadingBegin: @escaping (Bool) -> Void,
                          loadingFinished: @escaping (Bool) -> Void) {

        refresher.enableLoadMore = false
        loadingBegin(true)

        IQAPIClient.users(page: 1, perPage: pageSize, completion: { [weak self] result in
            guard let self = self else {
                return
            }

            loadingFinished(true)

            switch result {
            case .success(let models):
                self.models = models
                let gotAllRecords = models.count == self.pageSize
                self.refresher.enableLoadMore = gotAllRecords

                let allIDs = self.models.map { $0.id }
                print(allIDs)
                print("\n\n")

                self.refreshUI()
            case .failure:
                break
            }
        })
    }

    func loadMoreTriggered(type: IQPullToRefresh.LoadMoreType,
                           loadingBegin: @escaping (Bool) -> Void,
                           loadingFinished: @escaping (Bool) -> Void) {

        //If it's not multiple of 10 then probably we've loaded all records
        guard models.count.isMultiple(of: pageSize) else {
            loadingBegin(false)
            return
        }

        loadingBegin(true)

        let page = (models.count / pageSize) + 1

        IQAPIClient.users(page: page, perPage: pageSize, completion: { [weak self] result in
            guard let self = self else {
                return
            }

            loadingFinished(true)

            switch result {
            case .success(let models):
                self.models.append(contentsOf: models)
                let gotAllRecords = models.count == self.pageSize
                self.refresher.enableLoadMore = gotAllRecords

                self.refreshUI()
            case .failure:
                break
            }
        })
    }
}

extension UsersViewController: IQListViewDelegateDataSource {

    func refreshUI(animated: Bool = true) {
        list.performUpdates({
            let section = IQSection(identifier: 0)
            list.append(section)

            list.append(Cell.self, models: models, section: section)
        }, completion: { [weak self] in
            self?.tableView.bounces = true
        })
    }
}
