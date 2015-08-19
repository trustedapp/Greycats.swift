//
//  AutolayoutStack.swift
//
//  Created by Rex Sheng on 3/25/15.
//  Copyright (c) 2015 Rex Sheng. All rights reserved.
//

// available in pod 'Greycats', '~> 0.4.0'

import UIKit

public func _id<T: AnyObject>(object: T) -> String {
	return "<\(_stdlib_getDemangledTypeName(object)): 0x\(String(ObjectIdentifier(object).uintValue, radix: 16))>"
}

func edge0(axis: UILayoutConstraintAxis) -> NSLayoutAttribute {
	return axis == .Vertical ? .Top : .Leading
}
func edge1(axis: UILayoutConstraintAxis) -> NSLayoutAttribute {
	return axis == .Vertical ? .Bottom : .Trailing
}
func perpendicularEdge0(axis: UILayoutConstraintAxis) -> NSLayoutAttribute {
	return axis == .Horizontal ? .Top : .Leading
}
func perpendicularEdge1(axis: UILayoutConstraintAxis) -> NSLayoutAttribute {
	return axis == .Horizontal ? .Bottom : .Trailing
}
func perpendicularDimension(axis: UILayoutConstraintAxis) -> NSLayoutAttribute {
	return axis == .Horizontal ? .Height : .Width
}

extension UIView {
	public func horizontalStack(views: [UIView], marginX: CGFloat = 0, equalWidth: Bool = false) -> [NSLayoutConstraint] {
		for v in subviews {
			v.removeFromSuperview()
		}
		var previous: UIView? = nil
		var constraints: [NSLayoutConstraint] = []
		for view in views {
			view.setTranslatesAutoresizingMaskIntoConstraints(false)
			addSubview(view)
			constraints.append(NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0))
			constraints.append(NSLayoutConstraint(item: view, attribute: .Height, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: 1, constant: -2))
			constraints.append(NSLayoutConstraint(item: view, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: -2))
			if equalWidth {
				if self is UIScrollView {
					constraints.append(NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: self, attribute: .Width, multiplier: 1, constant: -2 * marginX))
				} else if let previous = previous {
					constraints.append(NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: previous, attribute: .Width, multiplier: 1, constant: 0))
				}
			}
			if let previous = previous {
				constraints.append(NSLayoutConstraint(item: view, attribute: .Leading, relatedBy: .Equal, toItem: previous, attribute: .Trailing, multiplier: 1, constant: 2 * marginX))
			} else {
				constraints.append(NSLayoutConstraint(item: view, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: marginX))
			}
			previous = view
		}
		if let previous = previous {
			let constraint = NSLayoutConstraint(item: previous, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: -marginX)
			constraint.priority = 999
			constraints.append(constraint)
		}
		addConstraints(constraints)
		return constraints
	}
	
	public func verticalStack(views: [UIView], marginX: CGFloat = 0) {
		for v in subviews {
			v.removeFromSuperview()
		}
		var previous: UIView? = nil
		for view in views {
			injectView(view, axis: .Vertical, after: previous, marginX: marginX)
			previous = view
		}
	}
	
	func _previousView(view: UIView, axis: UILayoutConstraintAxis) -> NSLayoutConstraint? {
		let gaps = constraints() as! [NSLayoutConstraint]
		let attr = edge0(axis)
		for gap in gaps {
			if gap.firstAttribute == attr && gap.firstItem as? UIView == view {
				return gap
			}
		}
		return nil
	}
	
	func _firstView(axis: UILayoutConstraintAxis) -> NSLayoutConstraint? {
		let gaps = constraints() as! [NSLayoutConstraint]
		let attr = edge0(axis)
		for gap in gaps {
			if gap.secondAttribute == attr && gap.secondItem as? UIView == self {
				return gap
			}
		}
		return nil
	}
	
	func _lastView(axis: UILayoutConstraintAxis) -> NSLayoutConstraint? {
		let gaps = constraints() as! [NSLayoutConstraint]
		let attr = edge1(axis)
		for gap in gaps {
			if gap.firstAttribute == attr && gap.firstItem as? UIView == self {
				return gap
			}
		}
		return nil
	}
	
	func _nextView(view: UIView, axis: UILayoutConstraintAxis) -> NSLayoutConstraint? {
		let gaps = constraints() as! [NSLayoutConstraint]
		let attr = edge1(axis)
		for gap in gaps {
			if gap.secondAttribute == attr && gap.secondItem as? UIView == view {
				return gap
			}
		}
		return nil
	}
	
	public func ejectView(view: UIView, axis: UILayoutConstraintAxis) {
		if let prev = _previousView(view, axis: axis),
			let next = _nextView(view, axis: axis) {
				let newConstraint = NSLayoutConstraint(item: next.firstItem, attribute: next.firstAttribute, relatedBy: .Equal, toItem: prev.secondItem, attribute: prev.secondAttribute, multiplier: 1, constant: view.bounds.height)
				self.addConstraint(newConstraint)
				self.layoutIfNeeded()
				UIView.animateWithDuration(0.25, animations: {
					view.alpha = 0
					}) { _ in
						self.removeConstraint(prev)
						self.removeConstraint(next)
						view.removeFromSuperview()
				}
				
				UIView.animateWithDuration(0.15, delay: 0.2, options: .CurveEaseIn, animations: {
					newConstraint.constant = 0
					self.layoutIfNeeded()
					}, completion: nil)
		}
	}
	
	public func injectView(view: UIView, axis: UILayoutConstraintAxis, after previous: UIView?, marginX: CGFloat = 0, animated: Bool = false) {
		view.setTranslatesAutoresizingMaskIntoConstraints(false)
		addSubview(view)
		let _edge0 = edge0(axis)
		let _edge1 = edge1(axis)
		let pedge0 = perpendicularEdge0(axis)
		let pedge1 = perpendicularEdge1(axis)
		let attr = perpendicularDimension(axis)
		addConstraint(NSLayoutConstraint(item: view, attribute: pedge0, relatedBy: .Equal, toItem: self, attribute: pedge0, multiplier: 1, constant: marginX))
		addConstraint(NSLayoutConstraint(item: view, attribute: pedge1, relatedBy: .Equal, toItem: self, attribute: pedge1, multiplier: 1, constant: -marginX))
		addConstraint(NSLayoutConstraint(item: view, attribute: attr, relatedBy: .Equal, toItem: self, attribute: attr, multiplier: 1, constant: -2 * marginX))
		
		let edge0Constraint: NSLayoutConstraint
		if let previous = previous {
			// let us found original next view, and link it to this view
			if let c = _nextView(previous, axis: axis) {
				removeConstraint(c)
				let bottom = NSLayoutConstraint(item: c.firstItem, attribute: c.firstAttribute, relatedBy: .Equal, toItem: view, attribute: _edge1, multiplier: 1, constant: c.constant)
				addConstraint(bottom)
			}
			edge0Constraint = NSLayoutConstraint(item: view, attribute: _edge0, relatedBy: .Equal, toItem: previous, attribute: _edge1, multiplier: 1, constant: 0)
		} else {
			// view is gonna be first, find current first and unlink it
			if let c = _firstView(axis) {
				addConstraint(NSLayoutConstraint(item: c.firstItem, attribute: _edge0, relatedBy: .Equal, toItem: view, attribute: _edge1, multiplier: 1, constant: 0))
				removeConstraint(c)
			} else {
				let bottom = NSLayoutConstraint(item: self, attribute: _edge1, relatedBy: .Equal, toItem: view, attribute: _edge1, multiplier: 1, constant: 2)
				addConstraint(bottom)
			}
			edge0Constraint = NSLayoutConstraint(item: view, attribute: _edge0, relatedBy: .Equal, toItem: self, attribute: _edge0, multiplier: 1, constant: 0)
		}
		addConstraint(edge0Constraint)
		if animated {
			let size = view.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
			edge0Constraint.constant = axis == .Vertical ? -size.height : -size.width
			layoutIfNeeded()
			view.alpha = 0
			UIView.animateWithDuration(0.25) {
				edge0Constraint.constant = 0
				self.layoutIfNeeded()
			}
			
			UIView.animateWithDuration(0.15, delay: 0.2, options: .CurveEaseIn, animations: {
				view.alpha = 1
				}, completion: nil)
		}
	}
}

infix operator |< {}
public func |< (view: UIView, views: [UIView]) {
	view.verticalStack(views, marginX: 0)
}

infix operator -< {}
public func -< (view: UIView, views: [UIView]) {
	view.horizontalStack(views, marginX: 0)
}

infix operator --< {}
public func --< (view: UIView, views: [UIView]) {
	view.horizontalStack(views, marginX: 0, equalWidth: true)
}

