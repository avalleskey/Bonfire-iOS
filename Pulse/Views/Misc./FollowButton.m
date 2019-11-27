//
//  FollowButton.m
//  Pulse
//
//  Created by Austin Valleskey on 9/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "FollowButton.h"
#import "Session.h"
#import "UIColor+Palette.h"

@implementation FollowButton

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 6);
        self.titleLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightBold];
        self.adjustsImageWhenHighlighted = false;
        self.backgroundColor = [UIColor bonfirePrimaryColor];
        self.layer.cornerRadius = 14.f;
        self.layer.masksToBounds = false;
        self.layer.borderColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.06f].CGColor;
        self.layer.borderWidth = 0;
    }
    return self;
}

- (void)setImage:(UIImage *)image forState:(UIControlState)state {
    [super setImage:image forState:state];
    
    if (image) {
        self.titleEdgeInsets = UIEdgeInsetsMake(0, self.imageEdgeInsets.right, 0, 0);
    }
    else {
        self.titleEdgeInsets = UIEdgeInsetsZero;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.transform = CGAffineTransformIdentity;
    
    // update border color when trait collection changes
    self.layer.borderColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.06f].CGColor;
}

@end
