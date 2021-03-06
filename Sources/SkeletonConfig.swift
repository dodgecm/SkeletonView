// Copyright © 2018 SkeletonView. All rights reserved.

import UIKit

/// Used to store all config needed to activate the skeleton layer.
struct SkeletonConfig {
    /// Type of skeleton layer
    let type: SkeletonType
    /// Colors used in skeleton layer
    let colors: [UIColor]
    /// If type is gradient, which gradient direction
    let gradientDirection: GradientDirection?
    /// Specify if skeleton is animated or not
    let animated: Bool
    /// Used to execute a custom animation
    let animation: SkeletonLayerAnimation?
}
