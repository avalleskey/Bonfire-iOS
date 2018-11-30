//
//  ErrorChannelCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ErrorChannelCell.h"

@implementation ErrorChannelCell

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.layer.cornerRadius = 12.f;
    self.layer.masksToBounds = true;
    self.layer.shadowOffset = CGSizeMake(0, 6.f);
    self.layer.shadowRadius = 22.f;
    self.layer.shadowOpacity = 0.04f;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.clipsToBounds = false;
    
    self.backgroundColor = [UIColor whiteColor];
    
    // setup error view
    self.errorView = [[ErrorView alloc] initWithFrame:CGRectMake(8, 0, self.frame.size.width - 16, 100) title:@"Error Loading" description:@"Check your network settings and tap to try again." type:ErrorViewTypeGeneral];
    [self.contentView addSubview:self.errorView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.errorView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
}

- (void)continuityRadiusForCell:(UICollectionViewCell *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

@end
