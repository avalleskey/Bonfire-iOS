//
//  BFCameraSwiper.h
//

#import <UIKit/UIKit.h>

/**
 * `SloppySwiperDelegate` is a protocol for treaking the behavior of the
 * `SloppySwiper` object.
 */

@class BFCameraSwiper;

@protocol BFCameraSwiperDelegate <NSObject>

@optional

- (void)didFinishSwiping;

@end

/**
 *  `SloppySwiper` is a class conforming to `UINavigationControllerDelegate` protocol that allows pan back gesture to be started from anywhere on the screen (not only from the left edge).
 */
@interface BFCameraSwiper : NSObject <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>

@property (nonatomic, weak) id<BFCameraSwiperDelegate> delegate;

@property (nonatomic, strong) UIScrollView *contentScrollView;
@property (nonatomic, assign, getter = isAppearing) BOOL appearing;

/// Designated initializer if the class isn't used from the Interface Builder.
- (instancetype)initWithViewController:(UIViewController *)viewController;

@end
