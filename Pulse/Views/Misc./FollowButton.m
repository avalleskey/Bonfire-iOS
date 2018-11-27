//
//  FollowButton.m
//  Pulse
//
//  Created by Austin Valleskey on 9/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "FollowButton.h"
#import "Session.h"

@implementation FollowButton

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 6);
        self.titleEdgeInsets = UIEdgeInsetsMake(0, 6, 0, 0);
        self.titleLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightBold];
        self.adjustsImageWhenHighlighted = false;
        self.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.2f];
        self.layer.cornerRadius = 11.f;
        self.layer.masksToBounds = false;
        self.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
        self.layer.borderWidth = 0;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

@end
