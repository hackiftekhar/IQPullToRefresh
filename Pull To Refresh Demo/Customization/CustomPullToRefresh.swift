//
//  CustomPullToRefresh.swift
//  Pull To Refresh Demo
//
//  Created by Iftekhar on 08/02/21.
//

import UIKit
import IQPullToRefresh

class CustomPullToRefresh: UILabel, IQAnimatableRefresh {

    let progressView = UIProgressView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        textAlignment = .center
        self.addSubview(progressView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        progressView.frame = CGRect(origin: .zero, size: CGSize(width: self.frame.width, height: progressView.frame.height))
    }

    var progress: CGFloat = 0 {
        didSet {
            guard !isRefreshing else {
                return
            }
            alpha = progress
            text = NSString(format: "Refresh... %.0f%%", progress*100) as String
            progressView.progress = Float(progress)
        }
    }

    var isRefreshing: Bool = false

    func beginRefreshing() {
        text = "Refreshing..."
        isRefreshing = true
    }

    func endRefreshing() {
        text = "Refresh"
        isRefreshing = false
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 200, height: 20)
    }
}
