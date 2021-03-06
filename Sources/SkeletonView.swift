//  Copyright © 2017 SkeletonView. All rights reserved.

import UIKit

public extension UIView {
    
    func showSkeleton(usingColor color: UIColor = SkeletonAppearance.default.tintColor) {
        showSkeleton(withType: .solid, usingColors: [color])
    }
    
    func showGradientSkeleton(usingGradient gradient: SkeletonGradient = SkeletonAppearance.default.gradient) {
        showSkeleton(withType: .gradient, usingColors: gradient.colors)
    }
    
    func showAnimatedSkeleton(usingColor color: UIColor = SkeletonAppearance.default.tintColor, animation: SkeletonLayerAnimation? = nil) {
        showSkeleton(withType: .solid, usingColors: [color], animated: true, animation: animation)
    }
    
    func showAnimatedGradientSkeleton(usingGradient gradient: SkeletonGradient = SkeletonAppearance.default.gradient, animation: SkeletonLayerAnimation? = nil) {
        showSkeleton(withType: .gradient, usingColors: gradient.colors, animated: true, animation: animation)
    }

    func updateSkeleton(usingColor color: UIColor = SkeletonAppearance.default.tintColor) {
        updateSkeleton(withType: .solid, usingColors: [color])
    }

    func updateGradientSkeleton(usingGradient gradient: SkeletonGradient = SkeletonAppearance.default.gradient) {
        updateSkeleton(withType: .gradient, usingColors: gradient.colors)
    }

    func updateAnimatedSkeleton(usingColor color: UIColor = SkeletonAppearance.default.tintColor, animation: SkeletonLayerAnimation? = nil) {
        updateSkeleton(withType: .solid, usingColors: [color], animated: true, animation: animation)
    }

    func updateAnimatedGradientSkeleton(usingGradient gradient: SkeletonGradient = SkeletonAppearance.default.gradient, animation: SkeletonLayerAnimation? = nil) {
        updateSkeleton(withType: .gradient, usingColors: gradient.colors, animated: true, animation: animation)
    }

    func layoutSkeletonIfNeeded() {
        guard let flowDelegate = flowDelegate else { return }
        flowDelegate.willBeginLayingSkeletonsIfNeeded(withRootView: self)
        recursiveLayoutSkeletonIfNeeded(root: self)
    }
    
    func hideSkeleton(reloadDataAfter reload: Bool = true) {
        flowDelegate?.willBeginHidingSkeletons(withRootView: self)
        recursiveHideSkeleton(reloadDataAfter: reload, root: self)
    }
    
    func startSkeletonAnimation(_ anim: SkeletonLayerAnimation? = nil) {
        skeletonIsAnimated = true
        subviewsSkeletonables.recursiveSearch(leafBlock: startSkeletonLayerAnimationBlock(anim)) { subview in
            subview.startSkeletonAnimation(anim)
        }
    }

    func stopSkeletonAnimation() {
        skeletonIsAnimated = false
        subviewsSkeletonables.recursiveSearch(leafBlock: stopSkeletonLayerAnimationBlock) { subview in
            subview.stopSkeletonAnimation()
        }
    }
}

extension UIView {
    
    func showSkeleton(withType type: SkeletonType = .solid, usingColors colors: [UIColor], animated: Bool = false, animation: SkeletonLayerAnimation? = nil) {
        skeletonIsAnimated = animated
        flowDelegate = SkeletonFlowHandler()
        flowDelegate?.willBeginShowingSkeletons(withRootView: self)
        recursiveShowSkeleton(withType: type, usingColors: colors, animated: animated, animation: animation, root: self)
    }

    func updateSkeleton(withType type: SkeletonType = .solid, usingColors colors: [UIColor], animated: Bool = false, animation: SkeletonLayerAnimation? = nil) {
        guard let flowDelegate = flowDelegate else { return }
        skeletonIsAnimated = animated
        flowDelegate.willBeginUpdatingSkeletons(withRootView: self)
        recursiveUpdateSkeleton(withType: type, usingColors: colors, animated: animated, animation: animation, root: self)
    }

    fileprivate func recursiveShowSkeleton(withType type: SkeletonType, usingColors colors: [UIColor], animated: Bool, animation: SkeletonLayerAnimation?, root: UIView? = nil) {
        layoutIfNeeded()

        addDummyDataSourceIfNeeded()
        subviewsSkeletonables.recursiveSearch(leafBlock: {
            showSkeletonIfNotActive(withType: type, usingColors: colors, animated: animated, animation: animation)
        }){ subview in
            subview.recursiveShowSkeleton(withType: type, usingColors: colors, animated: animated, animation: animation)
        }

        if let root = root {
            flowDelegate?.didShowSkeletons(withRootView: root)
        }
    }
    
    fileprivate func recursiveUpdateSkeleton(withType type: SkeletonType, usingColors colors: [UIColor], animated: Bool, animation: SkeletonLayerAnimation?, root: UIView? = nil) {
        layoutIfNeeded()

        updateDummyDataSourceIfNeeded()
        subviewsSkeletonables.recursiveSearch(leafBlock: {
            guard isSkeletonActive else { return }

            if skeletonLayer?.type != type {
                hideSkeleton()
            }

            if isSkeletonActive {
                updateSkeletonLayer(usingColors: colors, animated: animated, animation: animation)
            } else {
                showSkeletonIfNotActive(withType: type, usingColors:colors, animated: animated, animation: animation)
            }
        }) { subview in
            subview.recursiveUpdateSkeleton(withType: type, usingColors: colors, animated: animated, animation: animation)
        }

        if let root = root {
            flowDelegate?.didUpdateSkeletons(withRootView: root)
        }
    }

    fileprivate func recursiveLayoutSkeletonIfNeeded(root: UIView? = nil) {
        layoutIfNeeded()

        subviewsSkeletonables.recursiveSearch(leafBlock: {
            guard isSkeletonActive else {
                if let type = currentSkeletonConfig?.type,
                   let colors = currentSkeletonConfig?.colors,
                   let animated = currentSkeletonConfig?.animated {
                    let animation = currentSkeletonConfig?.animation
                    showSkeletonIfNotActive(withType: type, usingColors: colors, animated: animated, animation: animation)
                }

                return
            }

            layoutSkeletonLayerIfNeeded()
        }) { subview in
            subview.recursiveLayoutSkeletonIfNeeded()
        }

        if let root = root {
            flowDelegate?.didLayoutSkeletonsIfNeeded(withRootView: root)
        }
    }

    fileprivate func showSkeletonIfNotActive(withType type: SkeletonType, usingColors colors: [UIColor], animated: Bool, animation: SkeletonLayerAnimation?) {
        guard !self.isSkeletonActive else { return }
        self.isUserInteractionEnabled = false
        self.saveViewState()
        (self as? PrepareForSkeleton)?.prepareViewForSkeleton()
        self.addSkeletonLayer(withType: type, usingColors: colors, animated: animated, animation: animation)
    }
    
    
    fileprivate func recursiveHideSkeleton(reloadDataAfter reload: Bool, root: UIView? = nil) {
        removeDummyDataSourceIfNeeded(reloadAfter: reload)
        isUserInteractionEnabled = true
        subviewsSkeletonables.recursiveSearch(leafBlock: {
            recoverViewState(forced: false)
            removeSkeletonLayer()
        }) { subview in
            subview.recursiveHideSkeleton(reloadDataAfter: reload)
        }

        if let root = root {
            flowDelegate?.didHideSkeletons(withRootView: root)
        }
    }
    
    fileprivate func startSkeletonLayerAnimationBlock(_ anim: SkeletonLayerAnimation? = nil) -> VoidBlock {
        return {
            guard let layer = self.skeletonLayer else { return }
            layer.start(anim)
        }
    }
    
    fileprivate var stopSkeletonLayerAnimationBlock: VoidBlock {
        return {
            guard let layer = self.skeletonLayer else { return }
            layer.stopAnimation()
        }
    }
}

extension UIView {
    
    func addSkeletonLayer(withType type: SkeletonType, usingColors colors: [UIColor], gradientDirection direction: GradientDirection? = nil, animated: Bool, animation: SkeletonLayerAnimation? = nil) {
        guard let skeletonLayer = SkeletonLayerBuilder()
            .setSkeletonType(type)
            .addColors(colors)
            .setHolder(self)
            .build()
            else { return }

        self.skeletonLayer = skeletonLayer
        layer.insertSublayer(skeletonLayer.contentLayer, at: UInt32.max)
        if animated { skeletonLayer.start(animation) }
        status = .on
        currentSkeletonConfig = SkeletonConfig(type: type, colors: colors, gradientDirection: direction, animated: animated, animation: animation)
    }
    
    func updateSkeletonLayer(usingColors colors: [UIColor], gradientDirection direction: GradientDirection? = nil, animated: Bool, animation: SkeletonLayerAnimation? = nil) {
        guard let skeletonLayer = skeletonLayer else { return }
        skeletonLayer.update(usingColors: colors)
        if animated { skeletonLayer.start(animation) }
        else { skeletonLayer.stopAnimation() }
    }

    func layoutSkeletonLayerIfNeeded() {
        guard let skeletonLayer = skeletonLayer else { return }
        skeletonLayer.layoutIfNeeded()
    }
    
    func removeSkeletonLayer() {
        guard isSkeletonActive,
            let skeletonLayer = skeletonLayer else { return }
        skeletonLayer.stopAnimation()
        skeletonLayer.removeLayer()
        self.skeletonLayer = nil
        status = .off
        currentSkeletonConfig = nil
    }
}

