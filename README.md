IQPullToRefresh
==========================
Easy Pull to refresh and Load more handling on a UIScrollView subclass


![Pull To Refresh & Load More](https://raw.githubusercontent.com/hackiftekhar/IQPullToRefresh/master/Documents/pull_to_refresh_load_more.gif)
![Load More](https://raw.githubusercontent.com/hackiftekhar/IQPullToRefresh/master/Documents/load_more.gif)
![Custom Pull To Refresh 1](https://raw.githubusercontent.com/hackiftekhar/IQPullToRefresh/master/Documents/custom_pull_to_refresh1.gif)
![Custom Pull To Refresh 2](https://raw.githubusercontent.com/hackiftekhar/IQPullToRefresh/master/Documents/custom_pull_to_refresh2.gif)

[![Build Status](https://travis-ci.org/hackiftekhar/IQPullToRefresh.svg)](https://travis-ci.org/hackiftekhar/IQPullToRefresh)

IQPullToRefresh is a standalone library which can be plugged with UIScrollView subclasses like UITableView/UICollectionView to provide pull-to-refresh and load-more feature without any hassle.
It also Provide customization mechanism using which you can create your own custom pull-to-refresh or custom load-more UI.

## Requirements
[![Platform iOS](https://img.shields.io/badge/Platform-iOS-blue.svg?style=fla)]()

| Library                | Language | Minimum iOS Target | Minimum Xcode Version |
|------------------------|----------|--------------------|-----------------------|
| IQPullToRefresh(1.0.0) | Swift    | iOS 11.0           | Xcode 11              |

#### Swift versions support
5.0 and above

Installation
==========================

#### Installation with CocoaPods

[![CocoaPods](https://img.shields.io/cocoapods/v/IQListKit.svg)](http://cocoadocs.org/docsets/IQListKit)

IQPullToRefresh is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'IQPullToRefresh'
```

*Or you can choose the version you need based on the Swift support table from [Requirements](README.md#requirements)*

```ruby
pod 'IQPullToRefresh', '1.0.0'
```

#### Installation with Source Code

[![Github tag](https://img.shields.io/github/tag/hackiftekhar/IQListKit.svg)]()

***Drag and drop*** `IQPullToRefresh` directory from demo project to your project

#### Installation with Swift Package Manager

[Swift Package Manager(SPM)](https://swift.org/package-manager/) is Apple's dependency manager tool. It is now supported in Xcode 11. So it can be used in all appleOS types of projects. It can be used alongside other tools like CocoaPods and Carthage as well. 

To install IQPullToRefresh package into your packages, add a reference to IQPullToRefresh and a targeting release version in the dependencies section in `Package.swift` file:

```swift
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    products: [],
    dependencies: [
        .package(url: "https://github.com/hackiftekhar/IQPullToRefresh.git", from: "1.0.0")
    ]
)
```

To install IQPullToRefresh package via Xcode

 * Go to File -> Swift Packages -> Add Package Dependency...
 * Then search for https://github.com/hackiftekhar/IQPullToRefresh.git
 * And choose the version you would like

Things you should understand before going into deep
==========================

#### RefreshType (Enumeration)
```swift
enum RefreshType {
   case manual  // When we manually trigger the refresh
   case refreshControl  // When the refreshControl trigger the refresh
}
```
   
#### LoadMoreType (Enumeration)
```swift
enum LoadMoreType {
    case manual // When we manually trigger the load more
    case reachAtEnd // When the moreLoader trigger the load more
}
```

#### Refreshable protocol (For Pull-To-Refresh feature)
It is used to get callback when refresh is triggered and also responsible to inform if loading has begin or loading has finished
```swift
func refreshTriggered(type: IQPullToRefresh.RefreshType,
                      loadingBegin: @escaping (_ success: Bool) -> Void,
                      loadingFinished: @escaping (_ success: Bool) -> Void)
```

#### MoreLoadable protocol (For Load-More feature)
It is used to get callback when load more is triggered and also responsible to inform if loading has begin or loading has finished

```swift
func loadMoreTriggered(type: IQPullToRefresh.LoadMoreType,
                       loadingBegin: @escaping (_ success: Bool) -> Void,
                       loadingFinished: @escaping (_ success: Bool) -> Void)
```

🤯 Current UsersViewController logic for load more 🥴 🤦
==========================
#### Approach 1
```swift
class UsersViewController: UITableViewController {
    var users = [User]()
    private func getInitialUsers() { ... }
    private func getMoreUsers() { ... }
    private func refreshUI() { ... }

    // Our Dirty 💩 logic to find load more condition, but this is not reliable to fulfil all edge cases
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {            
            if canLoadMore == true, loadMoreIndicatorView.isAnimating == false, (scrollView.isTracking == true || scrollView.isDecelerating == true) {
                let bottomEdge = scrollView.contentOffset.y + scrollView.frame.height
                let edgeToLoadMore = scrollView.contentSize.height - 100
                if (bottomEdge >= edgeToLoadMore) {
                    getMoreUsers()
                }
            }
        }
    }
}
```
#### Approach 2
```swift
class UsersViewController: UITableViewController {
    var users = [User]()
    private func getInitialUsers() { ... }
    private func getMoreUsers() { ... }
    private func refreshUI() { ... }

    // Our Dirty 💩 logic to find load more condition, or some peoples also use another logic to load more when last cell visible, but this also have it’s own limitations like don’t have users control when user can decide to load more.

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if canLoadMore == true,
loadMoreIndicatorView.isAnimating == false,
(indexPath.row + 1) == users.count {
            getMoreUsers()
        }
    }
}
```

🤩 New UsersViewController (Pull To Refresh)
==========================
```swift
class UsersViewController: UITableViewController {
    lazy var refresher = IQPullToRefresh(scrollView: tableView, refresher: self, moreLoader: self)
    override func viewDidLoad() {
        super.viewDidLoad()
        refresher.enablePullToRefresh = true
        refresher.enableLoadMore = false
    }
}
extension UsersViewController: Refreshable {
    func refreshTriggered(type: IQPullToRefresh.RefreshType,
                          loadingBegin: @escaping (Bool) -> Void,
                          loadingFinished: @escaping (Bool) -> Void) {
    loadingBegin(true)
    let pageSize = 10

    APIClient.users(page: 1, perPage: pageSize, completion: { [weak self] result in
            loadingFinished(true)

            switch result {
            case .success(let models):
                self.models = models
                let gotAllRecords = models.count.isMultiple(of:pageSize)
                self.refresher.enableLoadMore = models.count != 0 && gotAllRecords
                self.refreshUI()
            case .failure:
                break
            }
        })
    }
}
```

🤩 New UsersViewController (Load More)
==========================
```swift
class UsersViewController: UITableViewController {
    lazy var refresher = IQPullToRefresh(scrollView: tableView, refresher: self, moreLoader: self)
    override func viewDidLoad() {
        super.viewDidLoad()
        refresher.enablePullToRefresh = true
        refresher.enableLoadMore = false
    }
}
extension UsersViewController: Refreshable, MoreLoadable {
    func loadMoreTriggered(type: IQPullToRefresh.LoadMoreType,
                           loadingBegin: @escaping (Bool) -> Void,
                           loadingFinished: @escaping (Bool) -> Void) {
    loadingBegin(true)
    let pageSize = 10
    let page = (models.count / pageSize) + 1

    APIClient.users(page: page, perPage: pageSize, completion: { [weak self] result in
            loadingFinished(true)

            switch result {
            case .success(let models):
self.models.append(contentsOf: models)
                let gotAllRecords = models.count.isMultiple(of:pageSize)
                self.refresher.enableLoadMore = models.count != 0 && gotAllRecords
                self.refreshUI()
            case .failure:
                break
            }
        })
    }
}
```

🥳
You have done adding pull-to-refresh and load more without any dirty 💩 & 🐞 buggy code
![Pull To Refresh & Load More](https://raw.githubusercontent.com/hackiftekhar/IQPullToRefresh/master/Documents/pull_to_refresh_load_more.gif)


An abstract IQPullToRefresh wrapper class 
==========================
Most of the time, the pull to refresh and load more erquirements are same like

- On pull to refresh, load 10 records using an api with page_index = 0 (or page_no = 1) and page_size = 10
- On load more, load next batch of 10 records using same api with page_index = 1	(or page_no = 2)and page_size = 10
- Keep current state of [Model] array which comes from servers. Example like on load more success then add new records at the end of array etc.
- Once server don’t have more records, disable load more feature.

## IQRefreshAbstractWrapper abstract class blueprint
The IQRefreshAbstractWrapper mainly handles IQPullToRefresh delegate functions in most optimized way
```swift
open class IQRefreshAbstractWrapper<T: Decodable> {

    public let pullToRefresh: IQPullToRefresh
    public var pageOffset: Int
    public var pageSize: Int
    public var models: [T]
    public var modelsUpdatedObserver: ((_ result: Swift.Result<[T], Error>) -> Void)?

    public init(scrollView: UIScrollView,
                     pageOffset: Int, pageSize: Int,
                     modelsUpdatedObserver: ((_ result: Swift.Result<[T], Error>) -> Void)? = nil)

    open func request(page: Int, size: Int, completion: @escaping (Result<[T], Error>) -> Void)
}
```

### How to use IQRefreshAbstractWrapper
Let’s assume, we would like to get list of many users (assume 100+), but 10 record each time when user pull to refresh or if user scroll then next 10 batch with load more. We'll need to create a subclass of IQRefreshAbstractWrapper class

#### UserViewModel subclass
```swift
class UserViewModel: IQRefreshAbstractWrapper<User> {

	// Override the request function and return users based on page and size, that’s it.
  override func request(page: Int, size: Int, completion: @escaping (Result<[User], Error>) -> Void) {
	    APIClient.users(page: page, perPage: size, completion: completion)
  }
}
```

#### UsersViewController Implementation
You just need to create it's object and observe the modelsUpdatedObserver, when models list get's updated with either pull to refresh or load more, you'll get a callback here and you just need to connect those models with your UI now. It's this much simple to implement load more and pull to refresh now.

```swift
class UsersViewModelController: UITableViewController {

  private lazy var userViewModel: UserViewModel = UserViewModel(scrollView: tableView, pageOffset: 1, pageSize: 10)

  override func viewDidLoad() {
    super.viewDidLoad()

    // userViewModel.pullToRefresh.enablePullToRefresh = false	// You can always customize most of the things here
    userViewModel.modelsUpdatedObserver = { result in
      switch result {
        case .success:
          self.refreshUI(animated: true)
        case .failure:
          break
      }
    }
  }

  func refreshUI(animated: Bool = true) {
	  // Access userViewModel.models to get list of users
  }
}
```

Custom Pull To Refresh or Load more UI
==========================
This is all possible with implementing IQAnimatableRefresh protocol to your own UIView's subclasses.

### IQAnimatableRefresh protocol Requirement

- The class who adopt it must be a UIView
- The class must implement 2 variables

```swift
var refreshHeight: CGFloat { get }	// Height of your refresh view
var refreshState: IQAnimatableRefreshState { get set } //State handling
```

This can be 
```swift
public enum IQAnimatableRefreshState: Equatable {
    case unknown            // Unknown state for initialization
    case none               // refreshControler is not active
    case pulling(CGFloat)   // Pulling the refreshControl
    case eligible           // Progress is completed but touch not released
    case refreshing         // Triggered refreshing
}
```

#### Protocol Adoption
```swift
class CustomPullToRefresh: UILabel, IQAnimatableRefresh {
    var refreshHeight: CGFloat {
        return 80
    }
    var refreshState: IQAnimatableRefreshState = .none {
        didSet {
            guard refreshState != oldValue else { return }
            switch refreshState {
            case .none:
                    alpha = 0
                    text = ""
            case .pulling(let progress):
                    alpha = progress
                    text = "Pull to refresh"
            case .eligible:
                    alpha = 1
                    text = "Release to refresh"
            case .refreshing:
                    alpha = 1
                    text = "Loading"
            }
        }
    }
    ...
}
```

#### Assigning custom pull to refresh
```swift
class UsersViewController: UITableViewController {
    ...
    override func viewDidLoad() {
        super.viewDidLoad()
        ...
  let customPullToRefresh = CustomPullToRefresh()
        refresher.refreshControl = customPullToRefresh
        ...
    }
    ...
}
```


Other useful functions
==========================

```swift
- public var enablePullToRefresh: Bool //Enable/Disable Pull To refresh
- var isRefreshing: Bool { get } //Return true if refreshing in progress
- func refresh() //Manually trigger refresh
- public var refreshControl: IQAnimatableRefresh //Custom refreshControl

- public var enableLoadMore: Bool //Enable/Disable load more feature
- var isMoreLoading: Bool { get } //Return true if load more in progress
- func loadMore() //Manually trigger load more
- public var loadMoreControl: IQAnimatableRefresh //Custom loadMore
```

LICENSE
---
Distributed under the MIT License.

Contributions
---
Any contribution is more than welcome! You can contribute through pull requests and issues on GitHub.

Author
---
If you wish to contact me, email me: hack.iftekhar@gmail.com
