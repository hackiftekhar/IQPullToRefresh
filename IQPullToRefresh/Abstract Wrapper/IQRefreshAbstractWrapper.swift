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

@MainActor
open class IQRefreshAbstractWrapper<T: Sendable> {

    public enum RefreshingState: Sendable {
        case none
        case refreshing
        case moreLoading
    }

    public enum PageOffsetStyle: Sendable {

        // It behave like there is no load more feature. It just fetch
        // new records for each pull to request and that's it.
        case none

        // It behave like index: Page index starts with 0 as 1st page,
        // and increment by 1 with every next page like 1, 2, 3, 4 etc
        case pageFrom0

        // It behave like a number: Page number starts with 1 as 1st page,
        // and increment by 1 with every next page like 1, 2, 3, 4 etc
        case pageFrom1

        // Offset number records to skip. For example it's 0 for the 1st page of 10 records,
        // and 10 for 2nd page, 20 for 3rd page etc
        case offsetFrom0

        // Offset the record number from where it should start return next records.
        // For example it's 1 for the 1st page of 10 records, and 11 for 2nd page, 21 for 3rd page etc
        case offsetFrom1
    }

    public let pullToRefresh: IQPullToRefresh
    public var pageOffsetStyle: PageOffsetStyle {
        didSet {
            models = []
        }
    }
    public var pageSize: Int {
        didSet {
            models = []
        }
    }

    // swiftlint:disable line_length
    private var stateObservers: [AnyHashable: @Sendable @MainActor (_ result: RefreshingState) -> Void] = [:]
    private var modelsUpdateObservers: [AnyHashable: @Sendable @MainActor (_ result: Swift.Result<[T], any Error>) -> Void] = [:]
    // swiftlint:enable line_length

    public var state: RefreshingState = .none

    public var models: [T] {
        didSet {
            pullToRefresh.enableLoadMore = !models.isEmpty && models.count.isMultiple(of: pageSize)
            notifyModelsUpdate(update: .success(models))
        }
    }

    private init() {
        fatalError("Cannot use init function directly")
    }

    public init(scrollView: UIScrollView, pageOffsetStyle: PageOffsetStyle, pageSize: Int) {
        precondition(pageSize != 0) // This is because pageSize is used in division operation

        defer {
            pullToRefresh.refresher = self
            pullToRefresh.moreLoader = self
            pullToRefresh.enablePullToRefresh = true
        }

        models = []
        self.pageOffsetStyle = pageOffsetStyle
        self.pageSize = pageSize
        pullToRefresh = IQPullToRefresh(scrollView: scrollView)
    }

    open func request(page: Int, size: Int,
                      completion: @Sendable @escaping @MainActor (Result<[T], any Error>) -> Void) {
        fatalError("\(#function) has not been implemented by \(Self.self)")
    }
}

@MainActor
extension IQRefreshAbstractWrapper {

    // swiftlint:disable line_length
    public func addModelsUpdatedObserver(identifier: AnyHashable,
                                         observer: (@Sendable @escaping @MainActor (_ result: Swift.Result<[T], any Error>) -> Void)) {
        modelsUpdateObservers[identifier] = observer
    }
    // swiftlint:enable line_length

    public func removeModelsUpdatedObserver(identifier: AnyHashable) {
        modelsUpdateObservers[identifier] = nil
    }

    private func notifyModelsUpdate(update: Swift.Result<[T], any Error>) {
        for (_, observer) in modelsUpdateObservers {
            observer(update)
        }
    }
}

@MainActor
extension IQRefreshAbstractWrapper {

    public func addStateObserver(identifier: AnyHashable,
                                 observer: (@Sendable @escaping @MainActor (_ result: RefreshingState) -> Void)) {
        stateObservers[identifier] = observer
    }

    public func removeStateObserver(identifier: AnyHashable) {
        stateObservers[identifier] = nil
    }

    private func notifyStateUpdate(state: RefreshingState) {
        for (_, observer) in stateObservers {
            observer(state)
        }
    }
}

@MainActor
extension IQRefreshAbstractWrapper: Refreshable, MoreLoadable {

    public func refreshTriggered(type: IQPullToRefresh.RefreshType,
                                 loadingBegin: @Sendable @escaping @MainActor (Bool) -> Void,
                                 loadingFinished: @Sendable @escaping @MainActor (Bool) -> Void) {

        let page: Int
        switch pageOffsetStyle {
        case .none:
            page = -1
        case .pageFrom0:
            page = 0
        case .pageFrom1:
            page = 1
        case .offsetFrom0:
            page = 0
        case .offsetFrom1:
            page = 1
        }

        pullToRefresh.enableLoadMore = false
        loadingBegin(true)
        state = .refreshing
        notifyStateUpdate(state: .refreshing)

        self.request(page: page, size: pageSize, completion: { [weak self] result in

            guard let self = self else {
                return
            }
            let isReallyRefreshing: Bool = self.pullToRefresh.enablePullToRefresh && self.pullToRefresh.isRefreshing

            loadingFinished(true)
            state = .none
            notifyStateUpdate(state: .none)

            guard isReallyRefreshing else {
                return
            }

            switch result {
            case .success(let models):

                if pageOffsetStyle == .none {
                    pullToRefresh.enableLoadMore = false
                } else {
                    pullToRefresh.enableLoadMore = (models.count == self.pageSize)
                }
                self.models = models
            case .failure(let error):
                notifyModelsUpdate(update: .failure(error))
            }
        })
    }

    // swiftlint:disable cyclomatic_complexity
    public func loadMoreTriggered(type: IQPullToRefresh.LoadMoreType,
                                  loadingBegin: @Sendable @escaping @MainActor (Bool) -> Void,
                                  loadingFinished: @Sendable @escaping @MainActor (Bool) -> Void) {

        // If it's not multiple of pageSize then probably we've loaded all records
        guard models.count.isMultiple(of: pageSize) else {
            loadingBegin(false)
            pullToRefresh.enableLoadMore = false
            return
        }

        let page: Int
        switch pageOffsetStyle {
        case .none:
            loadingBegin(false)
            return
        case .pageFrom0:
            page = models.count / pageSize
        case .pageFrom1:
            page = (models.count / pageSize) + 1
        case .offsetFrom0:
            page = models.count
        case .offsetFrom1:
            page = models.count + 1
        }

        loadingBegin(true)
        state = .moreLoading
        notifyStateUpdate(state: .moreLoading)

        self.request(page: page, size: pageSize, completion: { [weak self] result in

            guard let self = self else {
                return
            }

            let isReallyMoreLoading: Bool = self.pullToRefresh.enableLoadMore && self.pullToRefresh.isMoreLoading

            loadingFinished(true)
            state = .none
            notifyStateUpdate(state: .none)

            guard isReallyMoreLoading else {
                return
            }

            switch result {
            case .success(let models):

                self.models += models

                if self.pageOffsetStyle == .none {
                    self.pullToRefresh.enableLoadMore = false
                } else {
                    self.pullToRefresh.enableLoadMore = (models.count == self.pageSize)
                }

            case .failure(let error):
                notifyModelsUpdate(update: .failure(error))
            }
        })
    }
    // swiftlint:enable cyclomatic_complexity
}
