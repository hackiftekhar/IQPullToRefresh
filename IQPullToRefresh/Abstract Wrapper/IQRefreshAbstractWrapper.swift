//
//  IQRefreshAbstractWrapper.swift
//  https://github.com/hackiftekhar/IQPullToRefresh
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

open class IQRefreshAbstractWrapper<T: Decodable> {

    public let pullToRefresh: IQPullToRefresh
    public var pageOffset: Int {
        didSet {
            self.models = []
        }
    }
    public var pageSize: Int {
        didSet {
            self.models = []
        }
    }

    public var modelsUpdatedObserver: ((_ result: Swift.Result<[T], Error>) -> Void)?

    public var models: [T] {
        didSet {
            pullToRefresh.enableLoadMore = !models.isEmpty && models.count.isMultiple(of: pageSize)
            self.modelsUpdatedObserver?(.success(self.models))
        }
    }

    private init() {
        fatalError("Cannot use init function directly")
    }

    public init(scrollView: UIScrollView, pageOffset: Int, pageSize: Int,
                modelsUpdatedObserver: ((_ result: Swift.Result<[T], Error>) -> Void)? = nil) {
        precondition(pageSize > 0)

        self.models = []
        self.pageOffset = pageOffset
        self.pageSize = pageSize
        self.modelsUpdatedObserver = modelsUpdatedObserver
        self.pullToRefresh = IQPullToRefresh(scrollView: scrollView)
        defer {
            self.pullToRefresh.refresher = self
            self.pullToRefresh.moreLoader = self
            self.pullToRefresh.enablePullToRefresh = true
        }
    }

    open func request(page: Int, size: Int, completion: @escaping (Result<[T], Error>) -> Void) {
        fatalError("\(#function) has not been implemented by \(Self.self)")
    }
}

extension IQRefreshAbstractWrapper: Refreshable, MoreLoadable {

    public func refreshTriggered(type: IQPullToRefresh.RefreshType,
                                 loadingBegin: @escaping (Bool) -> Void,
                                 loadingFinished: @escaping (Bool) -> Void) {

        pullToRefresh.enableLoadMore = false
        loadingBegin(true)

        self.request(page: pageOffset, size: pageSize, completion: { [weak self] result in

            guard let self = self else {
                return
            }
            let isReallyRefreshing: Bool = self.pullToRefresh.enablePullToRefresh && self.pullToRefresh.isRefreshing

            loadingFinished(true)

            guard isReallyRefreshing else {
                return
            }

            switch result {
            case .success(let models):

                self.models = models
                self.pullToRefresh.enableLoadMore = (models.count == self.pageSize)
            case .failure(let error):
                self.modelsUpdatedObserver?(.failure(error))
            }
        })
    }

    public func loadMoreTriggered(type: IQPullToRefresh.LoadMoreType,
                                  loadingBegin: @escaping (Bool) -> Void,
                                  loadingFinished: @escaping (Bool) -> Void) {

        //If it's not multiple of pageSize then probably we've loaded all records
        guard models.count.isMultiple(of: pageSize) else {
            loadingBegin(false)
            return
        }

        loadingBegin(true)

        let pageIndex = (models.count / pageSize) + pageOffset

        self.request(page: pageIndex, size: pageSize, completion: { [weak self] result in

            guard let self = self else {
                return
            }

            let isReallyMoreLoading: Bool = self.pullToRefresh.enableLoadMore && self.pullToRefresh.isMoreLoading

            loadingFinished(true)

            guard isReallyMoreLoading else {
                return
            }

            switch result {
            case .success(let models):

                self.models += models

                self.pullToRefresh.enableLoadMore = (models.count == self.pageSize)
            case .failure(let error):
                self.modelsUpdatedObserver?(.failure(error))
            }
        })
    }
}
