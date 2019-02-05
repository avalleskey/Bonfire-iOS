//
//  ChannelCell.m
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "EmptyChannelCell.h"
#import "UIColor+Palette.h"
#import "Launcher.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>

#define padding 24

@implementation EmptyChannelCell

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.backgroundColor = [UIColor clearColor];
    
    _errorView = [[ErrorView alloc] initWithFrame:CGRectMake(16, 0, self.frame.size.width - 32, 100) title:@"Recents" description:@"Rooms you open will appear here" type:ErrorViewTypeClock];
    _errorView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    [self.contentView addSubview:_errorView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // ticker
    self.errorView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
}

- (void)continuityRadiusForCell:(UICollectionViewCell *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

- (void)resizeHeight:(UILabel *)label withWidth:(CGFloat)width {
    CGRect rect = [label.text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:label.font} context:nil];
    
    label.frame = CGRectMake(label.frame.origin.x, label.frame.origin.y, width, rect.size.height);
}

- (void)resizeWidth:(UILabel *)label withHeight:(CGFloat)height withPadding:(CGFloat)p {
    CGRect rect = [label.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, height) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:label.font} context:nil];
    
    label.frame = CGRectMake(label.frame.origin.x, label.frame.origin.y, rect.size.width + (p * 2), height);
}

@end
