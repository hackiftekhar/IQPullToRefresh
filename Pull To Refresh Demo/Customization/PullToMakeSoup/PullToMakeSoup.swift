//
//  Created by Anastasiya Gorban on 4/14/15.
//  Copyright (c) 2015 Yalantis. All rights reserved.
//
//  Licensed under the MIT license: http://opensource.org/licenses/MIT
//  Latest version can be found at https://github.com/Yalantis/PullToMakeSoup
//

import Foundation
import UIKit
import IQPullToRefresh

// swiftlint:disable file_length
// swiftlint:disable type_body_length
class SoupView: UIView, IQAnimatableRefresh {
    @IBOutlet
    fileprivate var pan: UIImageView!
    @IBOutlet
    fileprivate var cover: UIImageView!
    @IBOutlet
    fileprivate var potato: UIImageView!
    @IBOutlet
    fileprivate var leftPea: UIImageView!
    @IBOutlet
    fileprivate var rightPea: UIImageView!
    @IBOutlet
    fileprivate var carrot: UIImageView!
    @IBOutlet
    fileprivate var circle: UIImageView!
    @IBOutlet
    fileprivate var water: UIImageView!
    @IBOutlet
    fileprivate var flame: UIImageView!
    @IBOutlet
    fileprivate var shadow: UIImageView!

    static func soapView() -> SoupView {
        guard let refreshView = Bundle(for: self).loadNibNamed("SoupView", owner: nil,
                                                               options: nil)!.first as? SoupView else {
            fatalError("can't initiate SoupView")
        }
        return refreshView
    }

    var refreshHeight: CGFloat {
        return 130
    }

    override var frame: CGRect {
        didSet {
            print(frame)
        }
    }

    override var bounds: CGRect {
        didSet {
            print(bounds)
        }
    }

    override var center: CGPoint {
        didSet {
            print(center)
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: refreshHeight)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        print(frame)
    }

    fileprivate var bubbleTimer: Timer?

    fileprivate let animationDuration = 0.3

    var refreshState: IQAnimatableRefreshState = .unknown {
        didSet {
            if oldValue != refreshState {
                switch refreshState {
                case .none, .unknown:
                    initalLayout()
                    self.alpha = 0.0
                    bubbleTimer?.invalidate()
                case .pulling(let progress):
                    self.alpha = 1.0
                    releasingAnimation(progress)
                case .eligible:
                    self.alpha = 1.0
                    releasingAnimation(1)
                case .refreshing:
                    self.alpha = 1.0
                    startLoading()
                }
            }
        }
    }

    // MARK: - Helpers

    // swiftlint:disable function_body_length
    func initalLayout() {
        let centerX = frame.size.width / 2

        // Circle
        circle.center = CGPoint(x: centerX, y: refreshHeight / 2)

        // Carrot
        carrot.removeAllAnimations()

        carrot.addAnimation(
            CAKeyframeAnimation.animationPosition(
                PocketSVG.pathFromSVGFileNamed("carrot-path-only",
                    origin: CGPoint(x: centerX + 11, y: 10),
                    mirrorX: true,
                    mirrorY: false,
                    scale: 0.5),
                duration: animationDuration,
                timingFunction: TimingFunction.easeIn,
                beginTime: 0)
        )

        carrot.addAnimation(CAKeyframeAnimation.animationWith(
            AnimationType.rotation,
            values: [4.131, 5.149, 6.294],
            keyTimes: [0, 0.5, 1],
            duration: animationDuration,
            beginTime: 0))
        carrot.addAnimation(CAKeyframeAnimation.animationWith(
            AnimationType.opacity,
            values: [0, 1],
            keyTimes: [0, 1],
            duration: animationDuration,
            beginTime: 0))

        carrot.layer.timeOffset = 0.0

        // Pan
        pan.removeAllAnimations()

        pan.center = CGPoint(x: centerX, y: pan.center.y)
        pan.addAnimation(CAKeyframeAnimation.animationWith(
            AnimationType.translationY,
            values: [-200, 0],
            keyTimes: [0, 0.5],
            duration: animationDuration,
            beginTime: 0))
        shadow.alpha = 0
        shadow.center = CGPoint(x: centerX + 11, y: shadow.center.y)
        pan.layer.timeOffset = 0.0

        // Water

        water.center = CGPoint(x: centerX, y: water.center.y)
        water.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        water.transform = CGAffineTransform(scaleX: 1, y: 0.00001)

        // Potato
        potato.removeAllAnimations()

        potato.addAnimation(
            CAKeyframeAnimation.animationPosition(
                PocketSVG.pathFromSVGFileNamed("potato-path-only",
                    origin: CGPoint(x: centerX - 65, y: 5),
                    mirrorX: true,
                    mirrorY: false,
                    scale: 1),
                duration: animationDuration,
                timingFunction: TimingFunction.easeIn,
                beginTime: 0)
        )

        potato.addAnimation(
            CAKeyframeAnimation.animationWith(
                AnimationType.opacity,
                values: [0, 1],
                keyTimes: [0, 1],
                duration: animationDuration,
                beginTime: 0)
        )

        potato.addAnimation(CAKeyframeAnimation.animationWith(
            AnimationType.rotation,
            values: [5.663, 4.836, 3.578],
            keyTimes: [0, 0.5, 1],
            duration: animationDuration,
            beginTime: 0))

        potato.layer.timeOffset = 0.0

        // Left pea
        leftPea.removeAllAnimations()

        leftPea.addAnimation(
            CAKeyframeAnimation.animationPosition(
                PocketSVG.pathFromSVGFileNamed("pea-from-left-path-only",
                    origin: CGPoint(x: centerX - 80, y: 12),
                    mirrorX: false,
                    mirrorY: false,
                    scale: 1),
                duration: animationDuration,
                timingFunction: TimingFunction.easeIn,
                beginTime: 0)
        )

        leftPea.addAnimation(
            CAKeyframeAnimation.animationWith(
                AnimationType.opacity,
                values: [0, 1],
                keyTimes: [0, 1],
                duration: animationDuration,
                beginTime: 0)
        )

        leftPea.layer.timeOffset = 0.0

        // Right pea
        rightPea.removeAllAnimations()

        rightPea.addAnimation(
            CAKeyframeAnimation.animationPosition(
                PocketSVG.pathFromSVGFileNamed("pea-from-right-path-only",
                    origin: CGPoint(x: centerX - 10, y: -13),
                    mirrorX: true,
                    mirrorY: false,
                    scale: 1),
                duration: animationDuration,
                timingFunction: TimingFunction.easeIn,
                beginTime: 0)
        )

        rightPea.addAnimation(
            CAKeyframeAnimation.animationWith(
                AnimationType.opacity,
                values: [0, 1],
                keyTimes: [0, 1],
                duration: animationDuration,
                beginTime: 0)
        )

        rightPea.layer.timeOffset = 0.0

        // Flame

        flame.center = CGPoint(x: frame.size.width / 2, y: flame.center.y)
        flame.image = nil
        flame.stopAnimating()
        flame.animationImages = nil

        // Cover

        cover.layer.anchorPoint = CGPoint(x: 1, y: 0.5)
        cover.center = CGPoint(x: frame.size.width / 2 + cover.frame.size.width/2, y: cover.center.y)

        cover.removeAllAnimations()

        cover.addAnimation(
            CAKeyframeAnimation.animationPosition(
                PocketSVG.pathFromSVGFileNamed("cover-path-only",
                    origin: CGPoint(x: pan.center.x + 34, y: -51),
                    mirrorX: true,
                    mirrorY: true,
                    scale: 0.5),
                duration: animationDuration,
                timingFunction: TimingFunction.easeIn,
                beginTime: 0)
        )

        cover.addAnimation(
            CAKeyframeAnimation.animationWith(
                AnimationType.rotation,
                values: [2.009, 0],
                keyTimes: [0, 1],
                duration: animationDuration,
                beginTime: 0)
        )

        cover.layer.timeOffset = 0.0
    }
    // swiftlint:enable function_body_length

    // swiftlint:disable function_body_length
    func startLoading() {
        circle.center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        carrot.layer.timeOffset = animationDuration
        pan.layer.timeOffset = animationDuration
        potato.layer.timeOffset = animationDuration
        leftPea.layer.timeOffset = animationDuration
        rightPea.layer.timeOffset = animationDuration
        cover.layer.timeOffset = animationDuration

        // Water & Cover
        water.center = CGPoint(x: water.center.x, y: pan.center.y + 22)
        water.clipsToBounds = true

        UIView.animate(withDuration: 1, delay: 0, options: [], animations: {
            self.shadow.alpha = 1
            self.water.transform = CGAffineTransform(scaleX: 1, y: 1)
            }, completion: { _ in
                self.cover.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                self.cover.center = CGPoint(x: self.cover.center.x - self.cover.frame.size.width/2,
                                            y: self.cover.center.y)
                let coverRotationAnimation = CAKeyframeAnimation.animationWith(
                    AnimationType.rotation,
                    values: [0.05, 0, -0.05, 0, 0.07, -0.03, 0],
                    keyTimes: [0, 0.2, 0.4, 0.6, 0.8, 0.9, 1],
                    duration: 0.5,
                    beginTime: 0
                )

                let coverPositionAnimation = CAKeyframeAnimation.animationWith(
                    AnimationType.translationY,
                    values: [-2, 0, -2, 1, -3, 0],
                    keyTimes: [0, 0.3, 0.5, 0.7, 0.9, 1],
                    duration: 0.5,
                    beginTime: 0)

                let animationGroup = CAAnimationGroup()
                animationGroup.duration = 1
                animationGroup.repeatCount = Float.greatestFiniteMagnitude

                animationGroup.animations = [coverRotationAnimation, coverPositionAnimation]

                self.cover.layer.add(animationGroup, forKey: "group")
                self.cover.layer.speed = 1
        })

        // Bubbles

        bubbleTimer = Timer.scheduledTimer(timeInterval: 0.12, target: self,
                                           selector: #selector(SoupView.addBubble), userInfo: nil, repeats: true)

        // Flame

        var lightsImages = [UIImage]()
        for index in 1...11 {
            let imageName = NSString(format: "Flames%.4d", index)
            let image = UIImage(named: imageName as String, in: Bundle(for: type(of: self)), compatibleWith: nil)
            lightsImages.append(image!)
        }
        flame.animationImages = lightsImages
       flame.animationDuration = 0.7
        flame.startAnimating()

        let delayTime = DispatchTime.now() + Double(Int64(0.7 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            var lightsImages = [UIImage]()
            for index in 11...68 {
                let imageName = NSString(format: "Flames%.4d", index)
                let image = UIImage(named: imageName as String, in: Bundle(for: type(of: self)), compatibleWith: nil)
                lightsImages.append(image!)
            }

            self.flame.animationImages = lightsImages
            self.flame.animationDuration = 2
            self.flame.animationRepeatCount = 0
            self.flame.startAnimating()
        }
    }
    // swiftlint:enable function_body_length

    @objc func addBubble() {
        let radius: CGFloat = 1
        let bubbleX = CGFloat.random(in: 0...self.water.frame.size.width)
        let circle = UIView(frame: CGRect(x: bubbleX, y: self.water.frame.size.height,
                                          width: 2*radius, height: 2*radius))
        circle.layer.cornerRadius = radius
        circle.layer.borderWidth = 1
        circle.layer.masksToBounds = true
        circle.layer.borderColor = UIColor.white.cgColor
        self.water.addSubview(circle)
        UIView.animate(withDuration: 1.3, animations: {
            let radius: CGFloat = 4
            circle.layer.frame = CGRect(x: bubbleX, y: -20, width: 2*radius, height: 2*radius)
            circle.layer.cornerRadius = radius
            }, completion: { _ in
                circle.removeFromSuperview()
        })
    }

    func releasingAnimation(_ progress: CGFloat) {
        let speed: CGFloat = 1.5

        let speededProgress: CGFloat = progress * speed > 1 ? 1 : progress * speed

        circle.alpha = progress
        circle.transform = CGAffineTransform.identity.scaledBy(x: speededProgress, y: speededProgress)
        circle.center = CGPoint(x: frame.size.width / 2,
                                y: refreshHeight / 2 + refreshHeight - (refreshHeight * progress))

        func progressWithOffset(_ offset: Double, _ progress: Double) -> Double {
            return progress < offset ? 0 : (progress - offset) * 1/(1 - offset)
        }

        if progress == 0 {
            pan.alpha = 0
        } else {
            pan.alpha = 1
        }

        pan.layer.timeOffset = Double(speededProgress) * animationDuration
        cover.layer.timeOffset = animationDuration * progressWithOffset(0.9, Double(progress))

        carrot.layer.timeOffset = animationDuration * progressWithOffset(0.5, Double(progress))

        potato.layer.timeOffset = animationDuration * progressWithOffset(0.8, Double(progress))
        leftPea.layer.timeOffset = animationDuration * progressWithOffset(0.5, Double(progress))
        rightPea.layer.timeOffset = animationDuration * progressWithOffset(0.8, Double(progress))
    }
}
// swiftlint:enable type_body_length
