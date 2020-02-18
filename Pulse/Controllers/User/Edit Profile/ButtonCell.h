//
//  ButtonCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ButtonCell : UITableViewCell

extern NSString *const ButtonCellTitleAttributeName;
extern NSString *const ButtonCellTitleColorAttributeName;

@property (nonatomic) UIColor *kButtonColorDefault;
@property (nonatomic) UIColor *kButtonColorDestructive;
@property (nonatomic) UIColor *kButtonColorTheme;
@property (nonatomic) UIColor *kButtonColorBonfire;

@property (strong, nonatomic) UILabel *buttonLabel;
@property (strong, nonatomic) UIImageView *iconImageView;
@property (strong, nonatomic) UIImageView *checkIcon;

@property (nonatomic) NSInteger gutterPadding; // default: 12

@property (nonatomic, strong) UIView *topSeparator;
@property (nonatomic, strong) UIView *bottomSeparator;

+ (CGFloat)height;

@end

NS_ASSUME_NONNULL_END
