//
//  BFCameraViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 2/23/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "BFCameraViewController.h"
#import "BFCameraAnimator.h"
#import "UIColor+Palette.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <HapticHelper/HapticHelper.h>
#import "UIImage+fixOrientation.h"
#import "Launcher.h"
#import "BFAlertController.h"
#import <SKInnerShadowLayer/SKInnerShadowLayer.h>

@interface BFCameraViewController () <AVCapturePhotoCaptureDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic) CGPoint centerBegin;
@property (nonatomic) CGPoint centerFinal;

@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) AVCapturePhotoOutput *stillImageOutput;
@property (nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic) AVCaptureDevice *currentCaptureDevice;

@property (nonatomic) BOOL usingFrontCamera;
@property (nonatomic) BOOL flash;
@property (nonatomic) BOOL allowRotation;

typedef enum {
    BFCameraOverlayModeNone = 0,
    BFCameraOverlayModeGrid = 1,
    BFCameraOverlayModePreview = 2
} BFCameraOverlayMode;
@property (nonatomic) BFCameraOverlayMode overlayMode;
@property (nonatomic, strong) NSArray <UIView *> *overlayModeViews;

@property (nonatomic) UIPanGestureRecognizer *panRecognizer;

@end

@implementation BFCameraViewController

- (id)init {
    if (self = [super init]) {
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        self.transitioningDelegate = nil;
        
        self.theme = [UIColor bonfireBrand];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"viewcontroller is being deallocated");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
        
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"prefersFrontCamera"]) {
        self.usingFrontCamera = [[NSUserDefaults standardUserDefaults] boolForKey:@"prefersFrontCamera"];
    }
    
    [UIView animateWithDuration:0.15f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self setNeedsStatusBarAppearanceUpdate];
    } completion:nil];
    
    [self setup];
    
    self.allowRotation = true;
    self.flash = false;
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"cameraOverlayMode"]) {
        self.overlayMode = (BFCameraOverlayMode)[[NSUserDefaults standardUserDefaults] integerForKey:@"cameraOverlayMode"];
    }
    else {
        // default
        self.overlayMode = BFCameraOverlayModeNone;
    }
    
    self.cameraView.tag = UIDeviceOrientationPortrait;
    [self orientationChanged:[NSNotification notificationWithName:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
       addObserver:self selector:@selector(orientationChanged:)
       name:UIDeviceOrientationDidChangeNotification
       object:[UIDevice currentDevice]];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        UIEdgeInsets safeAreaInsets = [UIApplication sharedApplication].delegate.window.safeAreaInsets;
        
        [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveLinear animations:^{
            self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:1];
        } completion:nil];
        
        self.cameraView.frame = CGRectMake(0, 0, self.cameraView.frame.size.width, self.cameraView.frame.size.height);
        if (!CGPointEqualToPoint(self.centerLaunch, CGPointZero)) {
            self.cameraView.center = self.centerLaunch;
            self.cameraView.transform = CGAffineTransformMakeScale(0.001, 0.001);
            self.cameraView.alpha = 0;
        }
        else {
            self.cameraView.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height * 1.5);
        }
            
        [UIView animateWithDuration:0.075f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.cameraView.alpha = 1;
        } completion:nil];
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.85f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.cameraView.transform = CGAffineTransformMakeScale(1, 1);
            self.cameraView.center = CGPointMake(self.view.frame.size.width / 2, (HAS_ROUNDED_CORNERS ? safeAreaInsets.top : 0) +  ((self.view.frame.size.height - (HAS_ROUNDED_CORNERS ? safeAreaInsets.top + safeAreaInsets.bottom : 0)) / 2));
        } completion:^(BOOL finished) {
        }];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self loadCamera];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.captureSession stopRunning];
    
    [UIView animateWithDuration:0.15f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self setNeedsStatusBarAppearanceUpdate];
    } completion:nil];
    
    self.cameraShutterButton.userInteractionEnabled = false;
    [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.captureView.alpha = 0;
        self.cameraShutterButton.alpha = 0.75;
        self.captureBlurView.alpha = 1;
    } completion:nil];
    
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
//    @property (nonatomic) AVCaptureSession *captureSession;
//    @property (nonatomic) AVCapturePhotoOutput *stillImageOutput;
//    @property (nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;
//    @property (nonatomic) AVCaptureDevice *currentCaptureDevice;
    self.captureSession = nil;
    self.stillImageOutput = nil;
    self.videoPreviewLayer = nil;
    self.currentCaptureDevice = nil;
}

- (void)setupLivePreview {
    if (!self.videoPreviewLayer) {
        self.videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
        
        self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
        [self.captureView.layer addSublayer:self.videoPreviewLayer];
    }
    
    dispatch_queue_t globalQueue =  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(globalQueue, ^{
        [self.captureSession startRunning];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.videoPreviewLayer.frame = self.captureView.bounds;
            
            self.cameraShutterButton.userInteractionEnabled = true;
            [UIView animateWithDuration:0.2f delay:0.1f options:UIViewAnimationOptionCurveEaseIn animations:^{
                self.captureView.alpha = 1;
                self.cameraShutterButton.alpha = 1;
                self.captureBlurView.alpha = 0;
            } completion:nil];
        });
    });
}

- (AVCaptureDevice *)getBackCamera {
    return [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack].devices.firstObject;
}

- (AVCaptureDevice *)getFrontCamera {
    return [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront].devices.firstObject;
}

- (void)loadCamera {
    if (self.captureSession == nil) {
        self.captureSession = [AVCaptureSession new];
        self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    }
    
    if (self.captureSession.inputs.count > 0) {
        [self.captureSession removeInput:self.captureSession.inputs.firstObject];
    }
    
    NSError *error;
    self.currentCaptureDevice = (self.usingFrontCamera ? [self getFrontCamera] : [self getBackCamera]);
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.currentCaptureDevice
                                                                        error:&error];
    if (!error) {
        [self.captureSession removeOutput:self.stillImageOutput];
        
        self.stillImageOutput = [AVCapturePhotoOutput new];
        self.stillImageOutput.highResolutionCaptureEnabled = true;
        
        if ([self.captureSession canAddInput:input] && [self.captureSession canAddOutput:self.stillImageOutput]) {
            [self.captureSession addInput:input];
            [self.captureSession addOutput:self.stillImageOutput];
            [self setupLivePreview];
        }
    }
    else {
        NSLog(@"Error Unable to initialize back camera: %@", error.localizedDescription);
    }
}

- (void)setup {
    UIEdgeInsets safeAreaInsets = [UIApplication sharedApplication].delegate.window.safeAreaInsets;
    
    CGFloat cameraHeight = self.view.frame.size.height - (HAS_ROUNDED_CORNERS ? safeAreaInsets.top + safeAreaInsets.bottom : 0);
    self.cameraView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, self.view.frame.size.width, cameraHeight)];
    [self continuityRadiusForView:self.cameraView withRadius:HAS_ROUNDED_CORNERS?32.f:8.f];
    self.cameraView.backgroundColor = [UIColor colorWithWhite:0.04 alpha:1];
    [self.view addSubview:self.cameraView];
    [self initDragToDismiss];
    
    self.captureView = [[UIView alloc] initWithFrame:self.cameraView.bounds];
    self.captureView.alpha = 0;
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchToZoomRecognizer:)];
    [self.captureView addGestureRecognizer:pinchGesture];
    
    UITapGestureRecognizer *doubleTapToSwitch = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(flipCamera)];
    doubleTapToSwitch.numberOfTapsRequired = 2;
    [self.cameraView addGestureRecognizer:doubleTapToSwitch];
    
    UITapGestureRecognizer *focusGesture = [[UITapGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        if ([self.captureImageView isHidden] && [self.currentCaptureDevice isFocusPointOfInterestSupported]) {
            CGFloat focus_x = location.x/self.cameraView.frame.size.width;
            CGFloat focus_y = location.y/self.cameraView.frame.size.height;

            UIView *circleFocus = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 52, 52)];
            circleFocus.center = location;
            circleFocus.layer.borderWidth = 3.f;
            circleFocus.layer.borderColor = [UIColor whiteColor].CGColor;
            circleFocus.layer.cornerRadius = circleFocus.frame.size.width / 2;
            circleFocus.transform = CGAffineTransformMakeScale(0.8, 0.8);
            circleFocus.alpha = 0;
            [UIView animateWithDuration:0.3f delay:0 usingSpringWithDamping:0.85f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                circleFocus.transform = CGAffineTransformMakeScale(1, 1);
                circleFocus.alpha = 1;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.2f delay:0.1f options:UIViewAnimationOptionCurveEaseIn animations:^{
                    circleFocus.alpha = 0;
                } completion:^(BOOL finished) {
                    [circleFocus removeFromSuperview];
                }];
            }];
            [self.cameraView addSubview:circleFocus];
            
            NSError *error;
            [self.currentCaptureDevice lockForConfiguration:&error];
            if ([self.currentCaptureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                [self.currentCaptureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            }
            else if ([self.currentCaptureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                [self.currentCaptureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
            }
            
            [self.currentCaptureDevice setFocusPointOfInterest:CGPointMake(focus_x,focus_y)];
            
            [self.currentCaptureDevice unlockForConfiguration];
        }
    }];
    [focusGesture requireGestureRecognizerToFail:doubleTapToSwitch];
    focusGesture.numberOfTapsRequired = 1;
    focusGesture.delaysTouchesEnded = true;
    [self.cameraView addGestureRecognizer:focusGesture];
    
    [self.cameraView addSubview:self.captureView];
    
    self.captureImageView = [[UIImageView alloc] initWithFrame:self.captureView.frame];
    [self continuityRadiusForView:self.captureImageView withRadius:HAS_ROUNDED_CORNERS?32.f:8.f];
    self.captureImageView.hidden = true;
    self.captureImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.cameraView addSubview:self.captureImageView];
    
    self.captureBlurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    self.captureBlurView.frame = self.captureView.frame;
    [self.cameraView insertSubview:self.captureBlurView aboveSubview:self.captureView];
        
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.closeButton setImage:[[UIImage imageNamed:@"navCloseIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.closeButton.frame = CGRectMake(self.view.frame.size.width - 44 - 11, 12, 44, 44);
    self.closeButton.tintColor = [UIColor whiteColor];
    self.closeButton.layer.shadowOffset = CGSizeMake(0, 1);
    self.closeButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.closeButton.layer.shadowOpacity = 0.16;
    self.closeButton.layer.shadowRadius = 2.f;
    self.closeButton.adjustsImageWhenHighlighted = false;
    self.closeButton.contentMode = UIViewContentModeCenter;
    [self.closeButton bk_whenTapped:^{
        [self dismissWithCompletion:nil];
    }];
    [self.cameraView addSubview:self.closeButton];
    
    self.overlayButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.overlayButton.frame = CGRectMake(self.view.frame.size.width / 2 - 22, 12, 44, 44);
    self.overlayButton.tintColor = [UIColor whiteColor];
    self.overlayButton.layer.shadowOffset = CGSizeMake(0, 1);
    self.overlayButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.overlayButton.layer.shadowOpacity = 0.16;
    self.overlayButton.layer.shadowRadius = 2.f;
    self.overlayButton.adjustsImageWhenHighlighted = false;
    self.overlayButton.contentMode = UIViewContentModeCenter;
    [self.overlayButton bk_whenTapped:^{
        self.overlayMode = self.overlayMode+1;
    }];
    [self.cameraView addSubview:self.overlayButton];
    [self setupOverlayModeViews];
    
    self.flashButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.flashButton.frame = CGRectMake(11, 12, 44, 44);
    self.flashButton.tintColor = [UIColor whiteColor];
    self.flashButton.layer.shadowOffset = CGSizeMake(0, 1);
    self.flashButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.flashButton.layer.shadowOpacity = 0.16;
    self.flashButton.layer.shadowRadius = 2.f;
    self.flashButton.adjustsImageWhenHighlighted = false;
    self.flashButton.contentMode = UIViewContentModeCenter;
    [self.flashButton bk_whenTapped:^{
        self.flash = !self.flash;
        
        self.flashButton.userInteractionEnabled = false;
        [self showText:(self.flash ? @"Flash On" : @"Flash Off")];
        wait(0.75, ^{
            self.flashButton.userInteractionEnabled = true;
        });
        
        [HapticHelper generateFeedback:FeedbackType_Selection];
    }];
    [self.cameraView addSubview:self.flashButton];
    
    CGFloat shutterDiameter = 76;
    CGFloat shutterButtonDiameter = 64;
    
    self.cameraShutter = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 - (shutterDiameter / 2), self.cameraView.frame.size.height - shutterDiameter - 48, shutterDiameter, shutterDiameter)];
    self.cameraShutter.layer.cornerRadius = self.cameraShutter.frame.size.height / 2;
    self.cameraShutter.layer.borderWidth = 4;
    self.cameraShutter.layer.borderColor = [UIColor whiteColor].CGColor;
    self.cameraShutter.backgroundColor = [UIColor colorWithWhite:0 alpha:0.25f];
    [self.cameraView addSubview:self.cameraShutter];
    
    self.cameraShutterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cameraShutterButton.frame = CGRectMake(self.cameraShutter.frame.size.width / 2 - shutterButtonDiameter / 2, self.cameraShutter.frame.size.height / 2 - shutterButtonDiameter / 2, shutterButtonDiameter, shutterButtonDiameter);
    self.cameraShutterButton.layer.masksToBounds = false;
    self.cameraShutterButton.layer.cornerRadius = self.cameraShutterButton.frame.size.width / 2;
    
    CAGradientLayer *gradientSublayer = [BFCameraViewController cameraGradientLayerWithColor:self.theme withSize:self.cameraShutterButton.frame.size];
    gradientSublayer.cornerRadius = gradientSublayer.frame.size.height / 2;
    gradientSublayer.borderColor = [UIColor colorWithWhite:1 alpha:0.08].CGColor;
    gradientSublayer.borderWidth = 1;
    [self.cameraShutterButton.layer addSublayer:gradientSublayer];
    
    self.cameraShutterButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.cameraShutterButton.layer.shadowOffset = CGSizeMake(0, 1);
    self.cameraShutterButton.layer.shadowRadius = 2.f;
    self.cameraShutterButton.layer.shadowOpacity = 0.16;
    
    self.cameraShutterButton.userInteractionEnabled = false;
    self.cameraShutterButton.alpha = 0.75;
    
    SKInnerShadowLayer *innerShadowLayer = [[SKInnerShadowLayer alloc] init];
    innerShadowLayer.frame = self.cameraShutterButton.bounds;
    innerShadowLayer.cornerRadius = self.cameraShutterButton.layer.cornerRadius;
    innerShadowLayer.innerShadowColor = [BFCameraViewController gradientSecondaryColorForColor:self.theme].CGColor;
    innerShadowLayer.innerShadowOffset = CGSizeMake(0, 2);
    innerShadowLayer.innerShadowRadius = 5;
    innerShadowLayer.innerShadowOpacity = 1;
    [self.cameraShutterButton.layer addSublayer:innerShadowLayer];
    
    [self.cameraShutterButton bk_whenTapped:^{
        self.allowRotation = false;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self shutter];
            
            [self updateState:1];
            
            AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey: AVVideoCodecTypeJPEG}];
            settings.autoStillImageStabilizationEnabled = false;
            settings.flashMode = self.flash ? AVCaptureFlashModeOn : AVCaptureFlashModeOff;

            [self.stillImageOutput capturePhotoWithSettings:settings delegate:self];
        });
    }];
    [self.cameraShutterButton bk_addEventHandler:^(id sender) {
        [HapticHelper generateFeedback:FeedbackType_Selection];
        [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            self.cameraShutterButton.transform = CGAffineTransformMakeScale(0.96, 0.96);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    [self.cameraShutterButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            self.cameraShutterButton.transform = CGAffineTransformIdentity;
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    [self.cameraShutter addSubview:self.cameraShutterButton];
    
    self.mostRecentContainerView = [[UIView alloc] initWithFrame:CGRectMake(32, self.cameraShutter.frame.origin.y + self.cameraShutter.frame.size.height / 2 - 56 / 2, 56, 56)];
    self.mostRecentContainerView.layer.cornerRadius = self.mostRecentContainerView.frame.size.height / 2;
    self.mostRecentContainerView.userInteractionEnabled = true;
    self.mostRecentContainerView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.mostRecentContainerView.layer.shadowOffset = CGSizeMake(0, 1);
    self.mostRecentContainerView.layer.shadowRadius = 2.f;
    self.mostRecentContainerView.layer.shadowOpacity = 0.16;
    [self.mostRecentContainerView bk_whenTapped:^{
        [self chooseFromLibrary:self];
    }];
    self.mostRecentContainerView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self.cameraView addSubview:self.mostRecentContainerView];
    
    self.mostRecentImageView = [[UIImageView alloc] initWithFrame:self.mostRecentContainerView.bounds];
    self.mostRecentImageView.layer.cornerRadius = self.mostRecentImageView.frame.size.height / 2;
    self.mostRecentImageView.layer.masksToBounds = true;
    self.mostRecentImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self addMostRecentImage];
    
    SKInnerShadowLayer *mostRecentInnerShadowLayer = [[SKInnerShadowLayer alloc] init];
    mostRecentInnerShadowLayer.frame = self.mostRecentContainerView.bounds;
    mostRecentInnerShadowLayer.cornerRadius = self.mostRecentContainerView.layer.cornerRadius;
    mostRecentInnerShadowLayer.innerShadowColor = [UIColor whiteColor].CGColor;
    mostRecentInnerShadowLayer.innerShadowOffset = CGSizeMake(0, 1.5);
    mostRecentInnerShadowLayer.innerShadowRadius = 2;
    mostRecentInnerShadowLayer.innerShadowOpacity = 0.4;
    [self.mostRecentContainerView.layer addSublayer:mostRecentInnerShadowLayer];
    
    [self.mostRecentContainerView addSubview:self.mostRecentImageView];
    
    self.cameraFlipButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cameraFlipButton.layer.masksToBounds = true;
    self.cameraFlipButton.frame = CGRectMake(self.view.frame.size.width - 32 - 56, self.cameraShutter.frame.origin.y + self.cameraShutter.frame.size.height / 2 - 56 / 2, 56, 56);
    self.cameraFlipButton.layer.cornerRadius = self.cameraFlipButton.frame.size.height / 2;
    UIVisualEffectView *cameraSwapButtonBlurBg = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    cameraSwapButtonBlurBg.frame = self.cameraFlipButton.bounds;
    [self.cameraFlipButton insertSubview:cameraSwapButtonBlurBg atIndex:0];
    UIImageView *flipIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cameraFlipIcon"]];
    flipIcon.layer.shadowOffset = CGSizeMake(0, 1);
    flipIcon.layer.shadowColor = [UIColor blackColor].CGColor;
    flipIcon.layer.shadowOpacity = 0.12;
    flipIcon.layer.shadowRadius = 2.f;
    flipIcon.userInteractionEnabled = false;
    flipIcon.center = CGPointMake(self.cameraFlipButton.frame.size.width / 2, self.cameraFlipButton.frame.size.height /2 - 1);
    [self.cameraFlipButton addSubview:flipIcon];
    [self.cameraFlipButton bk_whenTapped:^{
        [self flipCamera];
    }];
    [self.cameraView addSubview:self.cameraFlipButton];
    
    self.capturedImageCancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.capturedImageCancelButton.frame = CGRectMake(32, self.cameraShutter.frame.origin.y + self.cameraShutter.frame.size.height / 2 - 56 / 2, 56, 56);
    self.capturedImageCancelButton.layer.cornerRadius = self.capturedImageCancelButton.frame.size.height / 2;
    [self.capturedImageCancelButton bk_whenTapped:^{
        self.allowRotation = true;
        [self orientationChanged:[NSNotification notificationWithName:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]]];
        
        [UIView animateWithDuration:0.15f delay:0.2f usingSpringWithDamping:1.0f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.captureImageView.alpha = 0;
        } completion:^(BOOL finished) {
            self.captureImageView.hidden = true;
            self.captureImageView.image = nil;
        }];
        
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.85f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.captureImageView.center = self.cameraShutter.center;
            self.captureImageView.transform = CGAffineTransformMakeScale(0.001, 0.001);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                self.captureBlurView.alpha = 0;
            } completion:nil];
        }];
        
        [UIView animateWithDuration:0.1f delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.captureBlurView.alpha = 1;
        } completion:^(BOOL finished) {
            
        }];
        
        [self updateState:0];
    }];
    self.capturedImageCancelButton.layer.masksToBounds = true;
    UIVisualEffectView *capturedImageCancelButtonBlurBg = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    capturedImageCancelButtonBlurBg.frame = self.capturedImageCancelButton.bounds;
    [self.capturedImageCancelButton insertSubview:capturedImageCancelButtonBlurBg atIndex:0];
    UIImageView *cancelIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cameraCancelIcon"]];
    cancelIcon.userInteractionEnabled = false;
    cancelIcon.layer.shadowOffset = CGSizeMake(0, 1);
    cancelIcon.layer.shadowColor = [UIColor blackColor].CGColor;
    cancelIcon.layer.shadowOpacity = 0.12;
    cancelIcon.layer.shadowRadius = 2.f;
    cancelIcon.center = CGPointMake(self.capturedImageCancelButton.frame.size.width / 2, self.capturedImageCancelButton.frame.size.height / 2);
    [self.capturedImageCancelButton addSubview:cancelIcon];
    [self.cameraView addSubview:self.capturedImageCancelButton];
    
    self.capturedImageDoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.capturedImageDoneButton.layer.masksToBounds = true;
    self.capturedImageDoneButton.frame = CGRectMake(self.view.frame.size.width - 32 - 56, self.cameraShutter.frame.origin.y + self.cameraShutter.frame.size.height / 2 - 56 / 2, 56, 56);
    self.capturedImageDoneButton.layer.cornerRadius = self.capturedImageDoneButton.frame.size.height / 2;
    [self.capturedImageDoneButton setImage:[[UIImage imageNamed:@"cameraDoneIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.capturedImageDoneButton.tintColor = [UIColor highContrastForegroundForBackground:self.theme];
    self.capturedImageDoneButton.adjustsImageWhenHighlighted = false;
    [self.capturedImageDoneButton.layer addSublayer:[BFCameraViewController cameraGradientLayerWithColor:self.theme withSize:self.capturedImageDoneButton.frame.size]];
    [self.capturedImageDoneButton bringSubviewToFront:self.capturedImageDoneButton.imageView];
    [self.capturedImageDoneButton bk_whenTapped:^{
        UIImage *image = self.captureImageView.image;
        
        UIImageOrientation orientation = UIImageOrientationUp;
        if ((UIDeviceOrientation)self.cameraView.tag == UIDeviceOrientationLandscapeLeft) {
            orientation = UIImageOrientationLeft;
        }
        else if ((UIDeviceOrientation)self.cameraView.tag == UIDeviceOrientationLandscapeLeft) {
            orientation = UIImageOrientationRight;
        }
        image = [UIImage imageWithCGImage:[image CGImage]
                                    scale:[image scale]
                              orientation:orientation];
                
//        [self saveToAlbum:image];
        
        if ([self.delegate respondsToSelector:@selector(cameraViewController:didFinishPickingImage:)]) {
            [self.delegate cameraViewController:self didFinishPickingImage:image];
        }
        
        image = nil;
        
        [self dismissWithCompletion:nil];
    }];
    [self.cameraView addSubview:self.capturedImageDoneButton];
    
    [self addHighlightEventsToButton:self.cameraFlipButton];
    [self addHighlightEventsToButton:self.capturedImageCancelButton];
    [self addHighlightEventsToButton:self.capturedImageDoneButton];
    
    [self updateState:0];
    
    SKInnerShadowLayer *captureViewInnerShadow = [[SKInnerShadowLayer alloc] init];
    captureViewInnerShadow.frame = self.cameraView.bounds;
    captureViewInnerShadow.cornerRadius = HAS_ROUNDED_CORNERS?32.f:8.f;
    captureViewInnerShadow.innerShadowColor = [UIColor whiteColor].CGColor;
    captureViewInnerShadow.innerShadowOffset = CGSizeMake(0, 2);
    captureViewInnerShadow.innerShadowRadius = 3;
    captureViewInnerShadow.innerShadowOpacity = 0.4;
    [self.cameraView.layer addSublayer:captureViewInnerShadow];
}

- (void)setOverlayMode:(BFCameraOverlayMode)overlayMode {
    if ((NSInteger)overlayMode > 2) overlayMode = BFCameraOverlayModeNone;
    
    if (overlayMode != _overlayMode) {
        _overlayMode = overlayMode;
        
        [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)overlayMode forKey:@"cameraOverlayMode"];
        
        
        switch (overlayMode) {
            case BFCameraOverlayModeNone:
                NSLog(@"BFCameraOverlayMode: None");
                break;
            case BFCameraOverlayModeGrid:
                NSLog(@"BFCameraOverlayMode: Grid");
                break;
            case BFCameraOverlayModePreview:
                NSLog(@"BFCameraOverlayMode: Preview");
                break;
                
            default:
                break;
        }
    }
    
    [self updateOverlayModeViews:true];
}
- (void)updateOverlayModeViews:(BOOL)animated {
    // set button image
    if (_overlayMode == BFCameraOverlayModeGrid) {
        [self.overlayButton setImage:[UIImage imageNamed:@"cameraOvelrayOption_grid"] forState:UIControlStateNormal];
    }
    else if (_overlayMode == BFCameraOverlayModePreview) {
        [self.overlayButton setImage:[UIImage imageNamed:@"cameraOvelrayOption_preview"] forState:UIControlStateNormal];
    }
    else {
        // default
        [self.overlayButton setImage:[UIImage imageNamed:@"cameraOvelrayOption_default"] forState:UIControlStateNormal];
    }
    
    [UIView animateWithDuration:animated?0.25f:0 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        for (NSInteger i = 0; i < self.overlayModeViews.count; i++) {
            UIView *view = self.overlayModeViews[i];
            
            if (i == (NSInteger)self.overlayMode) {
                // show
                view.alpha = 1;
            }
            else {
                // hide
                view.alpha = 0;
            }
        }
    } completion:nil];
}
- (void)setupOverlayModeViews {
    NSMutableArray *mutableOverlayModeViews = [NSMutableArray new];
    
    UIView *overlayMode_default = [[UIView alloc] init];
    [self.cameraView insertSubview:overlayMode_default aboveSubview:self.captureBlurView];
    [mutableOverlayModeViews addObject:overlayMode_default];
    
    UIView *overlayMode_grid = [[UIView alloc] initWithFrame:self.cameraView.bounds];
    UIView *gridView = [[UIView alloc] initWithFrame:overlayMode_grid.bounds];
    gridView.alpha = 0.25;
    for (NSInteger i = 1; i < 3; i++) {
        UIView *h_l = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, self.cameraView.frame.size.height)];
        h_l.center = CGPointMake(self.cameraView.frame.size.width / 3 * i, h_l.center.y);
        h_l.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];
        [gridView addSubview:h_l];
    }
    for (NSInteger i = 1; i < 3; i++) {
        UIView *v_l = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.cameraView.frame.size.width, 1)];
        v_l.center = CGPointMake(v_l.center.x, self.cameraView.frame.size.height / 3 * i);
        v_l.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];
        [gridView addSubview:v_l];
    }
    [overlayMode_grid addSubview:gridView];
    [self.cameraView insertSubview:overlayMode_grid aboveSubview:self.captureBlurView];
    [mutableOverlayModeViews addObject:overlayMode_grid];
    
    UIView *overlayMode_preview = [[UIView alloc] initWithFrame:self.cameraView.bounds];
    overlayMode_preview.backgroundColor = [UIColor colorWithWhite:0 alpha:0.05];
    [overlayMode_preview.backgroundColor setFill];
    UIRectFill(overlayMode_preview.frame);
    
    CAShapeLayer *shapeLayer = [CAShapeLayer new];
    CGMutablePathRef path = CGPathCreateMutable();
    
    UIView *cutoutView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.cameraView.frame.size.width, self.cameraView.frame.size.width)];
    cutoutView.center = CGPointMake(self.cameraView.frame.size.width / 2, self.cameraView.frame.size.height / 2);
    
    CGPathAddRect(path, nil, cutoutView.frame);
    CGPathAddRect(path, nil, overlayMode_preview.bounds);
    
    shapeLayer.path = path;
    shapeLayer.fillRule = kCAFillRuleEvenOdd;
    overlayMode_preview.layer.mask = shapeLayer;
    
    UIView *co_v_l_1 = [[UIView alloc] initWithFrame:CGRectMake(0, cutoutView.frame.origin.y - 1, self.cameraView.frame.size.width, 1)];
    co_v_l_1.backgroundColor = [UIColor colorWithWhite:0.98 alpha:0.25];
    [overlayMode_preview addSubview:co_v_l_1];
    UIView *co_v_l_2 = [[UIView alloc] initWithFrame:CGRectMake(0, cutoutView.frame.origin.y + cutoutView.frame.size.height, self.cameraView.frame.size.width, 1)];
    co_v_l_2.backgroundColor = [UIColor colorWithWhite:0.98 alpha:0.25];
    [overlayMode_preview addSubview:co_v_l_2];
    
    [self.cameraView insertSubview:overlayMode_preview aboveSubview:self.captureBlurView];
    [mutableOverlayModeViews addObject:overlayMode_preview];
    
    CGPathRelease(path);
    
    self.overlayModeViews = [mutableOverlayModeViews copy];
}

- (void)saveToAlbum:(UIImage *)image {
    NSString *albumName = @"Bonfire";

    void (^saveBlock)(PHAssetCollection *assetCollection) = ^void(PHAssetCollection *assetCollection) {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
            PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
            [assetCollectionChangeRequest addAssets:@[[assetChangeRequest placeholderForCreatedAsset]]];

        } completionHandler:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"Error creating asset: %@", error);
            }
        }];
    };

    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"localizedTitle = %@", albumName];
    PHFetchResult *fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:fetchOptions];
    if (fetchResult.count > 0) {
        saveBlock(fetchResult.firstObject);
    } else {
        __block PHObjectPlaceholder *albumPlaceholder;
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetCollectionChangeRequest *changeRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:albumName];
            albumPlaceholder = changeRequest.placeholderForCreatedAssetCollection;

        } completionHandler:^(BOOL success, NSError *error) {
            if (success) {
                PHFetchResult *fetchResult = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[albumPlaceholder.localIdentifier] options:nil];
                if (fetchResult.count > 0) {
                    saveBlock(fetchResult.firstObject);
                }
            } else {
                NSLog(@"Error creating album: %@", error);
            }
        }];
    }
}

- (void)chooseFromLibrary:(id)sender {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        switch (status) {
            case PHAuthorizationStatusAuthorized: {
                NSLog(@"PHAuthorizationStatusAuthorized");
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                    picker.delegate = self;
                    picker.allowsEditing = NO;
                    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                    [[Launcher topMostViewController] presentViewController:picker animated:YES completion:nil];
                });
                
                break;
            }
            case PHAuthorizationStatusDenied:
            case PHAuthorizationStatusNotDetermined:
            {
                NSLog(@"PHAuthorizationStatusDenied");
                // confirm action
                dispatch_async(dispatch_get_main_queue(), ^{
                    BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:@"Allow Bonfire to access your phtoos" message:@"To allow Bonfire to access your photos, go to Settings > Privacy > Camera > Set Bonfire to ON" preferredStyle:BFAlertControllerStyleAlert];

                    BFAlertAction *openSettingsAction = [BFAlertAction actionWithTitle:@"Open Settings" style:BFAlertActionStyleDefault handler:^{
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                    }];
                    [actionSheet addAction:openSettingsAction];
                
                    BFAlertAction *closeAction = [BFAlertAction actionWithTitle:@"Close" style:BFAlertActionStyleCancel handler:nil];
                    [actionSheet addAction:closeAction];
                    
                    [actionSheet show];
                });

                break;
            }
            case PHAuthorizationStatusRestricted: {
                NSLog(@"PHAuthorizationStatusRestricted");
                break;
            }
        }
    }];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    // dismiss picker
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    // dismiss camera view
    [self dismissWithCompletion:nil];
    
    // send delegate methods
    PHAsset *asset = info[UIImagePickerControllerPHAsset];
    if (asset) {
        if ([self.delegate respondsToSelector:@selector(cameraViewController:didFinishPickingAsset:)]) {
            [self.delegate cameraViewController:self didFinishPickingAsset:asset];
        }
    }
    else {
        UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
        
        if ([self.delegate respondsToSelector:@selector(cameraViewController:didFinishPickingImage:)]) {
            [self.delegate cameraViewController:self didFinishPickingImage:chosenImage];
        }
    }
}

- (void)setFlash:(BOOL)flash {
    if (flash != _flash) {
        _flash = flash;
    }
    
    if (self.flash) {
        [self.flashButton setImage:[[UIImage imageNamed:@"cameraFlashOn"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    else {
        [self.flashButton setImage:[[UIImage imageNamed:@"cameraFlashOff"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
}

- (void)addMostRecentImage {
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:false selector:nil]];
    fetchOptions.fetchLimit = 1;
    
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
    
    if (fetchResult.count > 0) {
        self.mostRecentContainerView.hidden = false;
        PHImageRequestOptions *requestOptions = [PHImageRequestOptions new];
        requestOptions.synchronous = true;
        
        [[PHImageManager defaultManager] requestImageForAsset:fetchResult.firstObject targetSize:CGSizeMake(self.mostRecentContainerView.frame.size.width * [UIScreen mainScreen].scale, self.mostRecentContainerView.frame.size.height * [UIScreen mainScreen].scale) contentMode:PHImageContentModeAspectFill options:requestOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            self.mostRecentImageView.image = result;
        }];
    }
    else {
        self.mostRecentContainerView.hidden = true;
    }
}

- (void)addHighlightEventsToButton:(UIButton *)button {
    [button bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            button.transform = CGAffineTransformConcat(CGAffineTransformMakeRotation(atan2(button.transform.b, button.transform.a)), CGAffineTransformMakeScale(0.92, 0.92));
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    [button bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            button.transform = CGAffineTransformConcat(CGAffineTransformMakeRotation(atan2(button.transform.b, button.transform.a)), CGAffineTransformMakeScale(1, 1));
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
}

- (void)flipCamera {
    [self.captureSession stopRunning];
    
    [UIView animateWithDuration:0.1f delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.captureBlurView.alpha = 1;
    } completion:nil];
    
    self.usingFrontCamera = !self.usingFrontCamera;
    [[NSUserDefaults standardUserDefaults] setBool:self.usingFrontCamera forKey:@"prefersFrontCamera"];
    
    [self loadCamera];
    
    [HapticHelper generateFeedback:FeedbackType_Selection];
}

- (void)updateState:(int)state {
    // 0 = beginning / default state
    // 1 = image taken
    // 2 = video taken
    
    NSArray <UIView *> *hideViews = @[];
    NSArray <UIView *> *showViews = @[];
    
    if (state == 0) {
        self.panRecognizer.enabled = true;
        
        if (![self.captureSession isRunning]) {
            if ([_currentCaptureDevice lockForConfiguration:nil]) {
                _currentCaptureDevice.videoZoomFactor = 1;
                [_currentCaptureDevice unlockForConfiguration];
            }
            
            [self.captureSession startRunning];
        }
        
        hideViews = @[self.capturedImageCancelButton, self.capturedImageDoneButton];
        showViews = @[self.mostRecentContainerView, self.cameraFlipButton, self.cameraShutter, self.closeButton, self.overlayButton, self.flashButton];
    }
    else if (state == 1) {
        self.panRecognizer.enabled = false;
        
        hideViews = @[self.mostRecentContainerView, self.cameraFlipButton, self.cameraShutter, self.closeButton, self.overlayButton, self.flashButton];
        hideViews = [hideViews arrayByAddingObjectsFromArray:self.overlayModeViews];
        
        showViews = @[self.capturedImageCancelButton, self.capturedImageDoneButton];
    }
//    else if (state == 2) {
//        hideViews = @[self.capturedImageCancelButton, self.capturedImageDoneButton];
//        showViews = @[self.mostRecentContainerView, self.cameraCameraSwapButton];
//    }
    
    for (UIView *view in hideViews) {
        [view.layer removeAllAnimations];
        
        view.userInteractionEnabled = false;
        [UIView animateWithDuration:0.3f delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
//            view.transform = CGAffineTransformConcat(CGAffineTransformMakeRotation(atan2(view.transform.b, view.transform.a)), CGAffineTransformMakeScale(0.9, 0.9));;
            view.alpha = 0;
        } completion:nil];
    }
    for (UIView *view in showViews) {
        [view.layer removeAllAnimations];
        
        view.userInteractionEnabled = false;
        [UIView animateWithDuration:0.5f delay:0.25f usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
//            view.transform = CGAffineTransformConcat(CGAffineTransformMakeRotation(atan2(view.transform.b, view.transform.a)), CGAffineTransformMakeScale(1, 1));
            view.alpha = 1;
        } completion:^(BOOL finished) {
            view.userInteractionEnabled = true;
        }];
    }
}

- (void)shutter {
    UIView *shutter = [[UIView alloc] initWithFrame:self.captureView.bounds];
    shutter.backgroundColor = [UIColor colorWithWhite:1 alpha:0.25f];
    shutter.alpha = 0;
    [self.captureView.superview insertSubview:shutter aboveSubview:self.captureView];
    
    [UIView animateWithDuration:0.1f animations:^{
        shutter.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2f animations:^{
            shutter.alpha = 0;
        } completion:^(BOOL finished) {
            [shutter removeFromSuperview];
        }];
    }];
}

- (void)showText:(NSString *)text {
    UIView *bg = [[UIView alloc] initWithFrame:self.captureView.bounds];
    bg.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    bg.alpha = 0;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(24, self.closeButton.frame.origin.y + self.closeButton.frame.size.height, self.view.frame.size.width - 24 * 2, self.cameraShutter.frame.origin.y - (self.closeButton.frame.origin.y + self.closeButton.frame.size.height))];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.alpha = 0.8;
    label.font = [UIFont systemFontOfSize:28.f weight:UIFontWeightMedium];
    label.text = text;
    label.transform = CGAffineTransformMakeRotation(atan2(self.cameraShutter.transform.b, self.cameraShutter.transform.a));
    [bg addSubview:label];
    
    [self.captureView.superview insertSubview:bg aboveSubview:self.captureView];
    
    [UIView animateWithDuration:0.2f animations:^{
        bg.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15f delay:0.4f options:UIViewAnimationOptionCurveEaseOut animations:^{
            bg.alpha = 0;
        } completion:^(BOOL finished) {
            [bg removeFromSuperview];
        }];
    }];
}

- (void)initDragToDismiss {
    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.panRecognizer setMinimumNumberOfTouches:1];
    [self.panRecognizer setMaximumNumberOfTouches:1];
    [self.cameraView addGestureRecognizer:self.panRecognizer];
}
- (void)removeDragToDismiss {
    for (UIGestureRecognizer *gestureRecognizer in self.cameraView.gestureRecognizers) {
        [self.cameraView removeGestureRecognizer:gestureRecognizer];
    }
}
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [UIView animateWithDuration:0.35f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.flashButton.alpha = 0;
            self.overlayButton.alpha = 0;
            self.closeButton.alpha = 0;
        } completion:^(BOOL finished) {
            
        }];
        
        self.centerBegin = recognizer.view.center;
        self.centerFinal = CGPointMake(self.centerBegin.x, self.centerBegin.y + (self.cameraView.frame.size.height / 6));
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:self.view];
        if (translation.y > 0 || recognizer.view.center.y >= self.centerBegin.y) {
            CGFloat newCenterY = recognizer.view.center.y + translation.y;
            CGFloat diff = fabs(_centerBegin.y - newCenterY);
            CGFloat max = self.centerFinal.y - self.centerBegin.y;
            CGFloat percentage = CLAMP(diff / max, 0, 1);
            newCenterY = recognizer.view.center.y + (translation.y / (1 + 6 * percentage));

            recognizer.view.center = CGPointMake(recognizer.view.center.x,
                                                 newCenterY);
            
            [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
            
            percentage = MAX(0, MIN(1, (recognizer.view.center.y - self.centerBegin.y) / (self.centerFinal.y - self.centerBegin.y)));
            
            if (percentage > 0) {
                CGFloat minScale = 0.92;
                CGFloat minAlpha = 0.8;
                
                recognizer.view.transform = CGAffineTransformMakeScale(1.0 - (1.0 - minScale) * percentage, 1.0 - (1.0 - minScale) * percentage);
                self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:1.0 - (1.0 - minAlpha) * percentage];
            }
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [recognizer velocityInView:self.view];
        
        CGFloat percentage = (recognizer.view.center.y - self.centerBegin.y) / (self.centerFinal.y - self.centerBegin.y);
        
        CGFloat fromCenterY = fabs(self.centerBegin.y - recognizer.view.center.y);
        CGFloat duration = 0.15+(0.05*(fromCenterY/60));
                
        if (percentage >= 0.35 || velocity.y > self.centerFinal.y - self.centerBegin.y) {
            [self dismissWithCompletion:nil];
        }
        else {
            [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                recognizer.view.center = self.centerBegin;
                recognizer.view.transform = CGAffineTransformIdentity;
                self.view.backgroundColor = [UIColor blackColor];
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.35f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.flashButton.alpha = 1;
                    self.overlayButton.alpha = 1;
                    self.closeButton.alpha = 1;
                } completion:^(BOOL finished) {
                    
                }];
            }];
        }
    }
}

- (void)dismissWithCompletion:(void (^ _Nullable)(void))handler {
    self.view.userInteractionEnabled = false;
    [self.captureSession stopRunning];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    CGPoint centerDestination = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height * 1.5);
    if (!CGPointEqualToPoint(self.centerLaunch, CGPointZero)) {
        centerDestination = self.centerLaunch;
        
        [UIView animateWithDuration:0.1f delay:0.25f usingSpringWithDamping:1 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            if (!CGPointEqualToPoint(self.centerLaunch, CGPointZero)) {
                self.cameraView.alpha = 0;
            }
        } completion:^(BOOL finished) {
        }];
    }
    
    [UIView animateWithDuration:0.35f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
        self.cameraView.center = centerDestination;
        
        if (!CGPointEqualToPoint(self.centerLaunch, CGPointZero)) {
            self.cameraView.transform = CGAffineTransformMakeScale(0.001, 0.001);
        }
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:false completion:^{
            if (handler) {
                handler();
            }
        }];
    }];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(nullable NSError *)error {
    NSData *imageData = photo.fileDataRepresentation;
    if (imageData) {
        UIImage *image = [UIImage imageWithData:imageData];
        if (self.usingFrontCamera) {
            image = [UIImage imageWithCGImage:image.CGImage
                                        scale:image.scale
                                  orientation:UIImageOrientationLeftMirrored];
        }
        image = [image fixOrientation];
        
        CGFloat ratio = self.captureView.frame.size.width / self.captureView.frame.size.height;// = (width / height)
        CGFloat newWidth = floorf(image.size.height * ratio);
        CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(floorf((image.size.width - newWidth) / 2), 0, newWidth, image.size.height));
        // or use the UIImage wherever you like
        image = [UIImage imageWithCGImage:imageRef]; // cropped
        CGImageRelease(imageRef);
        
        // Add the image to captureImageView here...
        self.captureImageView.transform = CGAffineTransformMakeScale(1, 1);
        self.captureImageView.alpha = 1;
        self.captureImageView.center = CGPointMake(self.cameraView.frame.size.width / 2, self.cameraView.frame.size.height / 2);
        self.captureImageView.image = image;
        self.captureImageView.hidden = false;
        
        [self.captureSession stopRunning];
        
        imageData = nil;
        image = nil;
    }
}

-(void)handlePinchToZoomRecognizer:(UIPinchGestureRecognizer *)pinchRecognizer {
    const CGFloat pinchVelocityDividerFactor = 7.0f;

    if (pinchRecognizer.state == UIGestureRecognizerStateChanged) {
        NSError *error = nil;
        if ([_currentCaptureDevice lockForConfiguration:&error]) {
            CGFloat desiredZoomFactor = _currentCaptureDevice.videoZoomFactor + atan2f(pinchRecognizer.velocity, pinchVelocityDividerFactor);
            // Check if desiredZoomFactor fits required range from 1.0 to activeFormat.videoMaxZoomFactor
            CGFloat zoom = MAX(1.0, MIN(desiredZoomFactor, _currentCaptureDevice.activeFormat.videoMaxZoomFactor));
            if (_currentCaptureDevice.videoZoomFactor != zoom) {
                _currentCaptureDevice.videoZoomFactor = zoom;
                
                if (zoom == 1) {
                    [HapticHelper generateFeedback:FeedbackType_Impact_Light];
                }
            }
            [_currentCaptureDevice unlockForConfiguration];
        } else {
            NSLog(@"error: %@", error);
        }
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    maskLayer.borderWidth = 1;
    maskLayer.borderColor = [UIColor colorWithWhite:1 alpha:0.06].CGColor;
    
    sender.layer.mask = maskLayer;
}

#define DEGREES_TO_RADIANS(x) (M_PI * (x) / 180.0)
- (void) orientationChanged:(NSNotification *)note
{
    if (self.allowRotation) {
        UIDevice * device = note.object;
        if (device.orientation == UIDeviceOrientationLandscapeLeft ||
            device.orientation == UIDeviceOrientationLandscapeRight ||
            device.orientation == UIDeviceOrientationPortrait) {
            self.cameraView.tag = (NSInteger)device.orientation;
            
            NSArray *rotateViews = @[self.cameraShutter, self.mostRecentContainerView, self.cameraFlipButton, self.capturedImageDoneButton, self.capturedImageCancelButton, self.flashButton, self.closeButton];
            /* start special animation */
            CGFloat rotation = 0;
            if (device.orientation == UIDeviceOrientationLandscapeLeft) {
                rotation = 90;
            }
            else if (device.orientation == UIDeviceOrientationLandscapeRight) {
                rotation = -90;
            }
            
            [UIView animateWithDuration:0.7f delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                for (UIView *view in rotateViews) {
                    view.transform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(rotation));
                }
            } completion:nil];
        }
    }
}

+ (UIColor *)gradientBaseColorForColor:(UIColor *)color {
    CGFloat h, s, b, a;
    if (color) {
        [color getHue:&h saturation:&s brightness:&b alpha:&a];
        s = MIN(1, s+0.2);
        
        color = [UIColor colorWithHue:h saturation:MIN(1, s+0.2) brightness:b alpha:1];
    }
    else {
        color = [UIColor bonfireBrand];
        
        [color getHue:&h saturation:&s brightness:&b alpha:&a];
    }
    
    return color;
}
+ (UIColor *)gradientSecondaryColorForColor:(UIColor *)color {
    CGFloat h, s, b, a;
    [[self gradientBaseColorForColor:color] getHue:&h saturation:&s brightness:&b alpha:&a];
    
    return [UIColor colorWithHue:(h > 0.5 ? h - 0.04 : h + 0.04) saturation:s-0.06 brightness:b+0.06 alpha:1];
}

+ (CAGradientLayer *)cameraGradientLayerWithColor:(UIColor * _Nullable)color withSize:(CGSize)size {
    UIColor *baseColor = [BFCameraViewController gradientBaseColorForColor:color];
    UIColor *secondaryColor = [BFCameraViewController gradientSecondaryColorForColor:color];
        
    NSArray *gradientColors = [NSArray arrayWithObjects:(id)baseColor.CGColor, (id)secondaryColor.CGColor, nil];

    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = gradientColors;
    gradientLayer.startPoint = CGPointMake(0.5, 1);
    gradientLayer.endPoint = CGPointMake(0.5, 0);
    gradientLayer.frame = CGRectMake(0, 0, size.width, size.height);
    gradientLayer.name = @"gradient";
    gradientLayer.cornerRadius = size.width / 2;
    gradientLayer.borderWidth = .5;
    gradientLayer.borderColor = [UIColor colorWithWhite:0 alpha:0.08].CGColor;
    
    return gradientLayer;
}

@end
