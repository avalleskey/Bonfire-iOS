//
//  SparkInfoViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 4/10/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SparkInfoViewController : UIViewController

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;

@property (nonatomic, strong) UIButton *closeButton;

@end

NS_ASSUME_NONNULL_END
