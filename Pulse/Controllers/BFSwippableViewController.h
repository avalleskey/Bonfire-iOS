//
//  BFSwippableViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 5/17/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFActivityIndicatorView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BFSwippableViewControllerDelegate <NSObject>

- (void)draggableView:(UIView *)draggableView didPan:(UIPanGestureRecognizer *)recognizer;
- (void)swipeableViewControllerWillDismiss;
- (void)swipeableViewControllerDidDisappear;

@end

@interface BFSwippableViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic) CGPoint centerLaunch;

@property (nonatomic) BOOL loading;

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *contentOverlayView;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) BFActivityIndicatorView *spinner;
@property (nonatomic) BOOL showCloseButtonShadow;

@property (nonatomic, strong) UIView * _Nullable senderView;
@property (nonatomic, copy) void (^senderViewFinalState)(void);
@property (nonatomic) BOOL innerShadow;
@property (nonatomic) BOOL hideStatusBar;

- (void)setTopGradientColor:(UIColor *)color length:(CGFloat)length;
- (void)setBottomGradientColor:(UIColor *)color length:(CGFloat)length;

@property (nonatomic, weak) id <BFSwippableViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
