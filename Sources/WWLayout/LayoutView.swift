//
//===----------------------------------------------------------------------===//
//
//  LayoutView.swift
//  WWLayout
//
//  Created by Steven Grosmark on 5/4/18.
//  Copyright © 2018 WW International, Inc. All rights reserved.
//
//
//  This source file is part of the WWLayout open source project
//
//     https://github.com/ww-tech/wwlayout
//
//  Copyright © 2017-2018 WW International, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//===----------------------------------------------------------------------===//
//

import UIKit

internal enum SizeClass {
    case hcompact, hregular
    case hcompact_vcompact, hcompact_vregular
    case hregular_vcompact, hregular_vregular
    case vcompact, vregular
    
    init?(horizontal: UIUserInterfaceSizeClass?, vertical: UIUserInterfaceSizeClass?) {
        switch (horizontal, vertical) {
        case (.compact?, .compact?): self = .hcompact_vcompact
        case (.compact?, .regular?): self = .hcompact_vregular
        case (.regular?, .compact?): self = .hregular_vcompact
        case (.regular?, .regular?): self = .hregular_vregular
        case (.compact?, _): self = .hcompact
        case (.regular?, _): self = .hregular
        case (_, .compact?): self = .vcompact
        case (_, .regular?): self = .vregular
        default: return nil
        }
    }
    
    func matches() -> Set<SizeClass> {
        switch self {
        case .hcompact_vcompact: return [.hcompact_vcompact, .hcompact, .vcompact]
        case .hcompact_vregular: return [.hcompact_vregular, .hcompact, .vregular]
        case .hregular_vcompact: return [.hregular_vcompact, .hregular, .vcompact]
        case .hregular_vregular: return [.hregular_vregular, .hregular, .vregular]
        case .hcompact, .hregular, .vcompact, .vregular: return [self]
        }
    }
}

/// Hidden UIView that gets added to a UIViewController's hierarchy,
/// used to keep track of constraints that are tagged.
/// The hidden view is only created when constraints are tagged.
internal final class LayoutView: UIView {
    
    // MARK: - API
    
    /// Retrieve the LayoutView used to manage constraints created against a particular UIView
    internal static func layoutView(for view: UIView) -> LayoutView {
        let rootView = view.owningSuperview()
        for child in rootView.subviews {
            if let layoutView = child as? LayoutView {
                return layoutView
            }
        }
        let layoutView = LayoutView()
        rootView.insertSubview(layoutView, at: 0)
        return layoutView
    }
    
    /// Add a constraint to the list of managed constraints.
    /// A constraint is only added when it is tagged (i.e. constarint.tag != 0)
    internal func add(_ constraint: LayoutConstraint) {
        guard constraint.tag != 0 else { return }
        taggedConstraints[constraint.tag, default: []] += [constraint]
    }
    
    internal func add(_ constraint: LayoutConstraint, sizeClass: SizeClass) {
        sizedConstraints[sizeClass, default: []] += [constraint]
    }
    
    /// Get a list of constraints tagged with a specific tag
    internal func getConstraints(with tag: Int) -> [LayoutConstraint] {
        return taggedConstraints[tag, default:[]]
    }
    
    /// Activate / Deactivate all constraints with a specific tag
    internal func setActive(_ active: Bool, tag: Int) {
        taggedConstraints[tag, default:[]].setActive(active)
    }
    
    internal func switchSizeClass(from fromSizeClass: SizeClass?, to toSizeClass: SizeClass?) {
        let activate = toSizeClass?.matches() ?? []
        if let old = fromSizeClass {
            let deactivate = old.matches().subtracting(activate)
            for sizeClass in deactivate {
                sizedConstraints[sizeClass, default: []].setActive(false)
            }
        }
        for sizeClass in activate {
            sizedConstraints[sizeClass, default: []].setActive(true)
        }
    }
    
    // MARK: - Private implementation
    
    private var taggedConstraints = [Int: [LayoutConstraint]]()
    private var sizedConstraints = [SizeClass: [LayoutConstraint]]()
    
    private init() {
        super.init(frame: .zero)
        isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("unsupported") }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        let newSizeClass = SizeClass(horizontal: traitCollection.horizontalSizeClass, vertical: traitCollection.verticalSizeClass)
        let oldSizeClass = SizeClass(horizontal: previousTraitCollection?.horizontalSizeClass, vertical: previousTraitCollection?.verticalSizeClass)
        switchSizeClass(from: oldSizeClass, to: newSizeClass)
    }
}
