//
//  CustomPullToRefresh.swift
//  Pull To Refresh Demo
//
//  Created by Iftekhar on 08/02/21.
//

import UIKit
import IQPullToRefresh

class ProgressPullToRefresh: UILabel, IQAnimatableRefresh {

    var refreshHeight: CGFloat {
        return 100
    }

    var refreshState: IQAnimatableRefreshState = .unknown {
        didSet {
            guard refreshState != oldValue else {
                return
            }

            switch refreshState {
            case .unknown, .none:
                alpha = 0
            case .pulling(let progress):
                alpha = progress
                text = NSString(format: "Pull progress... %.0f%%", progress*100) as String
                progressView.progress = Float(progress)
            case .eligible:
                alpha = 1
                text = "Release to refresh..."
                progressView.progress = 1
            case .refreshing:
                alpha = 1
                progressView.progress = 1
                text = "Refreshing..."
            }
        }
    }

    let progressView = UIProgressView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        textAlignment = .center
        textColor = UIColor.white
        backgroundColor = .systemGreen
        self.addSubview(progressView)
        alpha = 0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        progressView.frame = CGRect(origin: .zero, size: CGSize(width: self.frame.width, height: progressView.frame.height))
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 200, height: refreshHeight)
    }
}
