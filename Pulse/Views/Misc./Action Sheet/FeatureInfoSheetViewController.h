//
//  FeatureInfoSheetViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 4/8/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FeatureInfoSheetViewController : UIViewController

+ (instancetype)featureInfoSheetWithImage:(UIImage *)image title:(nullable NSString *)title message:(nullable NSString *)message;

@property (nonatomic, strong) UIView *alertView;

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *alertTitle;
@property (nonatomic, strong) UILabel *alertDescription;
@property (nonatomic, strong) UIButton *closeButton;

@end

NS_ASSUME_NONNULL_END
