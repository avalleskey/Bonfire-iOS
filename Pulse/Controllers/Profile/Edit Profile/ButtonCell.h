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

@property (nonatomic) UIColor *kButtonColorDefault;
@property (nonatomic) UIColor *kButtonColorDestructive;
@property (nonatomic) UIColor *kButtonColorTheme;

@property (strong, nonatomic) UILabel *buttonLabel;

@end

NS_ASSUME_NONNULL_END
