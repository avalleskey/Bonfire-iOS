//
//  OneWayPanGestureRecognizer.swift
//  Bonfire
//
//  Created by Daniel Gauthier on 2020-09-11.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

// This simple subclass implements a pan gesture recognizer that only responds to a gesture
// in a single, specified direction. It currently only supports up and down swipes, but could
// easily be extended to support left and right as well.
class OneWayPanGestureRecognizer: UIPanGestureRecognizer {

    enum Direction {
        case up
        case down
        case left
        case right
    }

    private var gestureIsConfirmed: Bool = false
    private var moveX: Int = 0
    private var moveY: Int = 0
    var direction: Direction = .down

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        if state == .failed {
            return
        }

        // As this gesture starts to receive touches, we keep track of how much the pan moves vertically
        // from one touch point to the next. If we detect movement in the opposite direction
        // to this gesture recognizer's specified direction, we immediately fail the gesture. As soon as
        // we detect movement in the correct direction, we allow the rest of the gesture to proceed.

        let touch: UITouch = touches.first! as UITouch
        let nowPoint: CGPoint = touch.location(in: view)
        let prevPoint: CGPoint = touch.previousLocation(in: view)
        moveX += Int(prevPoint.x - nowPoint.x)
        moveY += Int(prevPoint.y - nowPoint.y)
        
        if !gestureIsConfirmed {
            if direction == .left || direction == .right {
                if moveX == 0 {
                    gestureIsConfirmed = false
                } else if (direction == .right && moveX > 0) || (direction == .left && moveX < 0) {
                    state = .failed
                } else {
                    gestureIsConfirmed = true
                }
            } else {
                if moveY == 0 {
                    gestureIsConfirmed = false
                } else if (direction == .down && moveY > 0) || (direction == .up && moveY < 0) {
                    state = .failed
                } else {
                    gestureIsConfirmed = true
                }
            }
        }
    }

    public override func reset() {
        super.reset()
        gestureIsConfirmed = false
        moveX = 0
        moveY = 0
    }
}
