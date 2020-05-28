//
//  BFCameraViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 2/23/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFCameraSwiper.h"
#import "BFCameraAnimator.h"
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@class BFCameraViewController;

@protocol BFCameraViewControllerDelegate <NSObject>

- (void)cameraViewController:(BFCameraViewController *)cameraView didFinishPickingImage:(UIImage *)image;
- (void)cameraViewController:(BFCameraViewController *)cameraView didFinishPickingAsset:(PHAsset *)asset;

@end

@interface BFCameraViewController : UIViewController <BFCameraSwiperDelegate>

@property (nonatomic, weak) id <BFCameraViewControllerDelegate> delegate;

// top buttons
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *overlayButton;
@property (nonatomic, strong) UIButton *flashButton;

// container for all camera views
@property (nonatomic, strong) UIView *cameraView;

// container for capture preview views
@property (nonatomic, strong) UIView *captureView;
@property (nonatomic, strong) UIImageView *captureImageView;
@property (nonatomic, strong) UIVisualEffectView *captureBlurView;

// bottom buttons
// -- shutter
@property (nonatomic, strong) UIView *cameraShutter;
@property (nonatomic, strong) UIButton *cameraShutterButton;
// -- most recent
@property (nonatomic, strong) UIView *mostRecentContainerView;
@property (nonatomic, strong) UIImageView *mostRecentImageView;
// -- flip
@property (nonatomic, strong) UIButton *cameraFlipButton;

// confirm buttons
@property (nonatomic, strong) UIButton *capturedImageCancelButton;
@property (nonatomic, strong) UIButton *capturedImageDoneButton;

// options
@property (nonatomic, strong) UIColor *theme;
@property (nonatomic) CGPoint centerLaunch;

// public methods
+ (CAGradientLayer *)cameraGradientLayerWithColor:(UIColor * _Nullable)baseColor withSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
