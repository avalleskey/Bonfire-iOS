//
//  BFColorPickerViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 5/10/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFColorPickerViewController.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "UIColor+Palette.h"
#import <HapticHelper/HapticHelper.h>

@interface BFColorPickerViewController ()

@property (nonatomic) CGPoint centerBegin;
@property (nonatomic) CGPoint centerFinal;

@property (nonatomic, strong) UILabel *previewColorLabel;
@property (nonatomic, strong) UILabel *previewHexLabel;

@property (nonatomic, strong) CAGradientLayer *saturationGradient;
@property (nonatomic, strong) CAGradientLayer *brightnessGradient;
@property (nonatomic, strong) CAGradientLayer *hueGradient;

@property (nonatomic, strong) UIView *hueSliderContainer;
@property (nonatomic, strong) UISlider *hueSlider;

@property (nonatomic, strong) UIView *saturationSliderContainer;
@property (nonatomic, strong) UISlider *saturationSlider;

@property (nonatomic, strong) UIView *brightnessSliderContainer;
@property (nonatomic, strong) UISlider *brightnessSlider;

@end

@implementation BFColorPickerViewController

- (id)initWithColor:(UIColor *)color {
    self = [super init];
    if (self) {
        self.selectedColor = color;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Set Custom Color";
    
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    
    [self initTapToDismiss];
    
    [self initContentView];
    
    [self updateColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveLinear animations:^{
            self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        } completion:nil];
        
        self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.view.frame.size.height, self.contentView.frame.size.width, self.contentView.frame.size.height);
        
        [UIView animateWithDuration:0.5f delay:0.1f usingSpringWithDamping:0.85f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.view.frame.size.height - self.contentView.frame.size.height - (HAS_ROUNDED_CORNERS ? 0 : 8) - [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom, self.contentView.frame.size.width, self.contentView.frame.size.height);
        } completion:nil];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)initTapToDismiss {
    UIView *tapToDismissView = [[UIView alloc] initWithFrame:self.view.bounds];
    [tapToDismissView bk_whenTapped:^{
        [self dismiss];
    }];
    [self.view addSubview:tapToDismissView];
}

- (void)initContentView {
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(8, self.view.frame.size.height, self.view.frame.size.width - 16, 425)];
    [self continuityRadiusForView:self.contentView withRadius:HAS_ROUNDED_CORNERS?24:6];
    self.contentView.backgroundColor = [UIColor contentBackgroundColor];
    [self.view addSubview:self.contentView];
    
//    [self setupPanRecognizer];
    
    UIView *pullTabIndicator = [[UIView alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width / 2 - 35 / 2, 8, 35, 6)];
    pullTabIndicator.backgroundColor = [UIColor tableViewSeparatorColor];
    pullTabIndicator.layer.cornerRadius = pullTabIndicator.frame.size.height / 2;
//    [self.contentView addSubview:pullTabIndicator];
    
    self.previewColorLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 32, 64, 64)];
    self.previewColorLabel.center = CGPointMake(self.contentView.frame.size.width / 2, self.previewColorLabel.center.y);
    self.previewColorLabel.layer.cornerRadius = self.previewColorLabel.frame.size.height / 2;
    self.previewColorLabel.layer.masksToBounds = true;
    self.previewColorLabel.text = @"Aa";
    self.previewColorLabel.textAlignment = NSTextAlignmentCenter;
    self.previewColorLabel.font = [UIFont systemFontOfSize:28.f weight:UIFontWeightHeavy];
    [self.contentView addSubview:self.previewColorLabel];
    
    self.previewHexLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 108, self.contentView.frame.size.width, 21)];
    self.previewHexLabel.textColor = [UIColor bonfireSecondaryColor];
    self.previewHexLabel.textAlignment = NSTextAlignmentCenter;
    self.previewHexLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium];
//    [self.contentView addSubview:self.previewHexLabel];
    
    [self initSliders];
    [self initButtons];
}

- (void)initSliders {
    self.hueSliderContainer = [[UIView alloc] initWithFrame:CGRectMake(32, 129, self.contentView.frame.size.width - 64, 20)];
    self.hueSliderContainer.layer.cornerRadius = self.hueSliderContainer.frame.size.height / 2;
    // add hue slider gradient background
    self.hueGradient = [CAGradientLayer layer];
    self.hueGradient.colors = [self hueGradientColors];
    self.hueGradient.startPoint = CGPointMake(0, 0.5);
    self.hueGradient.endPoint = CGPointMake(1, 0.5);
    self.hueGradient.frame = self.hueSliderContainer.bounds;
    self.hueGradient.cornerRadius = self.hueSliderContainer.layer.cornerRadius;
    [self.hueSliderContainer.layer addSublayer:self.hueGradient];
    self.hueSlider = [[UISlider alloc] initWithFrame:CGRectMake(-9, 0, self.hueSliderContainer.frame.size.width + (9 * 2), self.hueSliderContainer.frame.size.height)];
    [self.hueSlider addTarget:self action:@selector(hslDidSlide) forControlEvents:UIControlEventValueChanged];
    [self.hueSlider setMinimumTrackTintColor:[UIColor clearColor]];
    [self.hueSlider setMaximumTrackTintColor:[UIColor clearColor]];
    [self.hueSlider setThumbImage:[UIImage imageNamed:@"sliderThumbImage"] forState:UIControlStateNormal];
    [self.hueSliderContainer addSubview:self.hueSlider];
    [self.contentView addSubview:self.hueSliderContainer];
    
    self.saturationSliderContainer = [[UIView alloc] initWithFrame:CGRectMake(self.hueSliderContainer.frame.origin.x, 193, self.hueSliderContainer.frame.size.width, self.hueSliderContainer.frame.size.height)];
    self.saturationSliderContainer.layer.cornerRadius = self.saturationSliderContainer.frame.size.height / 2;
    // add saturation slider gradient background
    self.saturationGradient = [CAGradientLayer layer];
    self.saturationGradient.colors = [self saturationGradientColors];
    self.saturationGradient.startPoint = CGPointMake(0, 0.5);
    self.saturationGradient.endPoint = CGPointMake(1, 0.5);
    self.saturationGradient.frame = self.hueSliderContainer.bounds;
    self.saturationGradient.cornerRadius = self.saturationSliderContainer.layer.cornerRadius;
    [self.saturationSliderContainer.layer addSublayer:self.saturationGradient];
    
    self.saturationSlider = [[UISlider alloc] initWithFrame:self.hueSlider.frame];
    [self.saturationSlider addTarget:self action:@selector(hslDidSlide) forControlEvents:UIControlEventValueChanged];
    [self.saturationSlider setMinimumTrackTintColor:[UIColor clearColor]];
    [self.saturationSlider setMaximumTrackTintColor:[UIColor clearColor]];
    [self.saturationSlider setThumbImage:[UIImage imageNamed:@"sliderThumbImage"] forState:UIControlStateNormal];
    [self.saturationSliderContainer addSubview:self.saturationSlider];
    [self.contentView addSubview:self.saturationSliderContainer];
    
    self.brightnessSliderContainer = [[UIView alloc] initWithFrame:CGRectMake(self.hueSliderContainer.frame.origin.x, 257, self.hueSliderContainer.frame.size.width, self.hueSliderContainer.frame.size.height)];
    self.brightnessSliderContainer.layer.cornerRadius = self.brightnessSliderContainer.frame.size.height / 2;
    // add saturation slider gradient background
    self.brightnessGradient = [CAGradientLayer layer];
    self.brightnessGradient.colors = [self brightnessGradientColors];
    self.brightnessGradient.startPoint = CGPointMake(0, 0.5);
    self.brightnessGradient.endPoint = CGPointMake(1, 0.5);
    self.brightnessGradient.frame = self.brightnessSliderContainer.bounds;
    self.brightnessGradient.cornerRadius = self.saturationSliderContainer.layer.cornerRadius;
    [self.brightnessSliderContainer.layer addSublayer:self.brightnessGradient];
    
    self.brightnessSlider = [[UISlider alloc] initWithFrame:self.hueSlider.frame];
    [self.brightnessSlider addTarget:self action:@selector(hslDidSlide) forControlEvents:UIControlEventValueChanged];
    [self.brightnessSlider setMinimumTrackTintColor:[UIColor clearColor]];
    [self.brightnessSlider setMaximumTrackTintColor:[UIColor clearColor]];
    [self.brightnessSlider setThumbImage:[UIImage imageNamed:@"sliderThumbImage"] forState:UIControlStateNormal];
    [self.brightnessSliderContainer addSubview:self.brightnessSlider];
    [self.contentView addSubview:self.brightnessSliderContainer];
    
    self.hueSlider.maximumValue = kColorPickerViewHueScale;
    self.saturationSlider.maximumValue = kColorPickerViewSaturationBrightnessScale;
    self.brightnessSlider.maximumValue = kColorPickerViewSaturationBrightnessScale;
    
    self.hueSlider.value = self.selectedColor.hue * kColorPickerViewHueScale;
    self.saturationSlider.value = self.selectedColor.saturation * kColorPickerViewSaturationBrightnessScale;
    self.brightnessSlider.value = self.selectedColor.brightness * kColorPickerViewSaturationBrightnessScale;
}

- (void)initButtons {
    CGFloat buttonFontPointSize = 18;
    CGFloat buttonHeight = 56;
    
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cancelButton setTitleColor:[UIColor bonfirePrimaryColor] forState:UIControlStateNormal];
    self.cancelButton.frame = CGRectMake(0, self.contentView.frame.size.height - buttonHeight, self.contentView.frame.size.width, buttonHeight);
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:buttonFontPointSize weight:UIFontWeightSemibold];
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.cancelButton bk_whenTapped:^{
        [self dismiss];
    }];
    [self.cancelButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.cancelButton.backgroundColor = [UIColor contentHighlightedColor];
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    [self.cancelButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            self.cancelButton.backgroundColor = [UIColor contentBackgroundColor];
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    [self.contentView addSubview:self.cancelButton];
    
    self.saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.saveButton.frame = CGRectMake(0, self.cancelButton.frame.origin.y - buttonHeight, self.contentView.frame.size.width, buttonHeight);
    self.saveButton.titleLabel.font = [UIFont systemFontOfSize:buttonFontPointSize weight:UIFontWeightRegular];
    [self.saveButton setTitle:@"Set" forState:UIControlStateNormal];
    [self.saveButton bk_whenTapped:^{
        [HapticHelper generateFeedback:FeedbackType_Selection];
        [self save];
    }];
    [self.saveButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.saveButton.backgroundColor = [UIColor contentHighlightedColor];
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    [self.saveButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            self.saveButton.backgroundColor = [UIColor contentBackgroundColor];
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    [self.contentView addSubview:self.saveButton];
    
    UIView *lineSeparator1 = [[UIView alloc] initWithFrame:CGRectMake(0, self.cancelButton.frame.origin.y, self.contentView.frame.size.width, HALF_PIXEL)];
    lineSeparator1.backgroundColor = [UIColor tableViewSeparatorColor];
    [self.contentView addSubview:lineSeparator1];
    
    UIView *lineSeparator2 = [[UIView alloc] initWithFrame:CGRectMake(0, self.saveButton.frame.origin.y, self.contentView.frame.size.width, HALF_PIXEL)];
    lineSeparator2.backgroundColor = [UIColor tableViewSeparatorColor];
    [self.contentView addSubview:lineSeparator2];
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

- (void)setupPanRecognizer {
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [self.contentView addGestureRecognizer:panRecognizer];
}
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.centerBegin = recognizer.view.center;
        self.centerFinal = CGPointMake(self.centerBegin.x, self.centerBegin.y + (self.contentView.frame.size.height * 2));
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:self.view];
        if (translation.y > 0 || recognizer.view.center.y >= self.centerBegin.y) {
            recognizer.view.center = CGPointMake(recognizer.view.center.x,
                                                 recognizer.view.center.y + translation.y);
        }
        else {
            CGFloat newCenterY = recognizer.view.center.y + translation.y;
            CGFloat diff = fabs(_centerBegin.y - newCenterY);
            CGFloat max = 24;
            CGFloat percentage = diff / max;
            if (percentage > 1) {
                percentage = 1;
            }
            newCenterY = recognizer.view.center.y + (translation.y / (1 + 10 * percentage));

            recognizer.view.center = CGPointMake(recognizer.view.center.x,
                                                 newCenterY);
        }
        [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
        
        CGFloat percentage = (recognizer.view.center.y - self.centerBegin.y) / (self.centerFinal.y - self.centerBegin.y);
        
        if (percentage > 0) {
            //recognizer.view.transform = CGAffineTransformMakeScale(1.0 - (1.0 - 0.8) * percentage, 1.0 - (1.0 - 0.8) * percentage);
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [recognizer velocityInView:self.view];
        
        CGFloat fromCenterY = fabs(self.centerBegin.y - recognizer.view.center.y);
        CGFloat duration = 0.15+(0.05*(fromCenterY/60));
                
        if (velocity.y > 400) {
            [self dismiss];
        }
        else {
            [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                recognizer.view.center = self.centerBegin;
                recognizer.view.transform = CGAffineTransformIdentity;
            } completion:nil];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)updateColor {
    if (!_selectedColor) {
        _selectedColor = [UIColor bonfireGrayWithLevel:500];
    }
    
    self.previewColorLabel.backgroundColor = _selectedColor;
    if ([UIColor useWhiteForegroundForColor:_selectedColor]) {
        self.previewColorLabel.textColor = [UIColor whiteColor];
    }
    else {
        self.previewColorLabel.textColor = [UIColor blackColor];
    }
    
    self.previewHexLabel.text = [@"#" stringByAppendingString:[UIColor toHex:_selectedColor]];
    
    self.saturationGradient.colors = [self saturationGradientColors];
    self.brightnessGradient.colors = [self brightnessGradientColors];
    
    [self.saveButton setTitleColor:[UIColor fromHex:[UIColor toHex:_selectedColor] adjustForOptimalContrast:true] forState:UIControlStateNormal];
}

CGFloat const kColorPickerViewHueScale = 360;
CGFloat const kColorPickerViewSaturationBrightnessScale = 100;

- (void)hslDidSlide
{
    CGFloat hue = self.hueSlider.value/kColorPickerViewHueScale;
    CGFloat sat = self.saturationSlider.value/kColorPickerViewSaturationBrightnessScale;
    CGFloat bright = self.brightnessSlider.value/kColorPickerViewSaturationBrightnessScale;

    UIColor *color = [UIColor colorWithHue:hue
                                saturation:MAX(sat, 0)
                                brightness:MAX(bright, 0)
                                     alpha:1];
    
    [self setSelectedColor:color];
}

- (void)setSelectedColor:(UIColor *)selectedColor {
    if (selectedColor != _selectedColor) {
        _selectedColor = selectedColor;
        
        [self updateColor];
    }
    
}

- (void)dismiss {
    self.view.userInteractionEnabled = false;

    [UIView animateWithDuration:0.35f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
        self.contentView.frame = CGRectMake(self.contentView.frame.origin.x, self.view.frame.size.height, self.contentView.frame.size.width, self.contentView.frame.size.height);
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:false completion:nil];
    }];
}
- (void)save {
    if ([self.delegate respondsToSelector:@selector(colorPicker:didSelectColor:)]) {
        [self.delegate colorPicker:self didSelectColor:[UIColor toHex:_selectedColor]];
    }
    
    [self dismiss];
}

#pragma mark - Slider

- (NSArray *)hueGradientColors
{
    NSMutableArray *hues = [NSMutableArray arrayWithCapacity:10];
    
    CGFloat hue = 0;
    
    for (int numberOfColors = 0; numberOfColors < 10; numberOfColors++) {
        
        UIColor *color = [UIColor colorWithHue:hue
                                    saturation:1
                                    brightness:1
                                         alpha:1];
        
        [hues addObject:(id)color.CGColor];
        
        hue = hue + 0.1;
    }
    
    NSArray *hueColors = [NSArray arrayWithArray:hues];
    return hueColors;
}

- (NSArray *)saturationGradientColors
{
    UIColor *startSat = [UIColor colorWithHue:self.selectedColor.hue
                                   saturation:0
                                   brightness:self.selectedColor.brightness
                                        alpha:1];
    
    UIColor *endSat = [UIColor colorWithHue:self.selectedColor.hue
                                 saturation:1
                                 brightness:self.selectedColor.brightness
                                      alpha:1];
    
    NSArray *satColors = @[(id)startSat.CGColor, (id)endSat.CGColor];
    return satColors;
}

- (NSArray *)brightnessGradientColors
{
    UIColor *startBright = [UIColor colorWithHue:self.selectedColor.hue
                                      saturation:self.selectedColor.saturation
                                      brightness:0
                                           alpha:1];
    
    UIColor *endBright = [UIColor colorWithHue:self.selectedColor.hue
                                    saturation:self.selectedColor.saturation
                                    brightness:1
                                         alpha:1];
    
    NSArray *brightColors = @[(id)startBright.CGColor, (id)endBright.CGColor];
    return brightColors;
}

@end
