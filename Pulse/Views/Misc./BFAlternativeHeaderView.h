//
//  BFAlternativeHeaderView.h
//  Pulse
//
//  Created by Austin Valleskey on 5/22/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFAlternativeHeaderView : UIView

@property (nonatomic) NSString *title;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic) BOOL separator; // default: true
@property (nonatomic, strong) UIView *topLineSeparator;
@property (nonatomic, strong) UIView *bottomLineSeparator;

+ (CGFloat)height;

@end

NS_ASSUME_NONNULL_END
