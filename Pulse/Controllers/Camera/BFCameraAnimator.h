//
//  BFCameraAnimator.h
//

#import <UIKit/UIKit.h>

@class BFCameraAnimator;

@protocol BFCameraAnimatorDelegate <NSObject>

@required
- (CGFloat)animatorTransitionDimAmount:(BFCameraAnimator *)animator;

@end

@interface BFCameraAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign, getter = isAppearing) BOOL appearing;

@property (nonatomic, weak) id<BFCameraAnimatorDelegate> delegate;

@end
