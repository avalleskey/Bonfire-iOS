//
//  MiniAvatarCell.m
//  Pulse
//
//  Created by Austin Valleskey on 12/22/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "MiniAvatarCell.h"
#import "UIColor+Palette.h"

@implementation MiniAvatarCell

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.layer.shouldRasterize = true;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    self.updates = false;
    self.campAvatar = [[BFAvatarView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - 30, 12, 60, 60)];
    self.campAvatar.userInteractionEnabled = false;
    [self.contentView addSubview:self.campAvatar];
    
    self.campTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, self.campAvatar.frame.origin.y + self.campAvatar.frame.size.height + 6, self.frame.size.width - 8, 13)];
    self.campTitleLabel.numberOfLines = 1;
    self.campTitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.campTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.campTitleLabel.font = [UIFont systemFontOfSize:11.f weight:UIFontWeightMedium];
    self.campTitleLabel.textColor = [UIColor bonfirePrimaryColor];
    [self.contentView addSubview:self.campTitleLabel];
    
    self.updatesDotView = [[UIImageView alloc] initWithFrame:CGRectMake(self.campAvatar.frame.origin.x + self.campAvatar.frame.size.width - 18 - 1, self.campAvatar.frame.origin.y + 1, 18, 18)];
    self.updatesDotView.image = [UIImage imageNamed:@"campUpdatesDot"];
    [self.contentView addSubview:self.updatesDotView];
    
    self.loading = true;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.campAvatar.center = CGPointMake(self.frame.size.width / 2, self.campAvatar.center.y);
    self.updatesDotView.frame = CGRectMake(self.campAvatar.frame.origin.x + self.campAvatar.frame.size.width - self.updatesDotView.frame.size.width - 1, self.campAvatar.frame.origin.y + 1, self.updatesDotView.frame.size.width, self.updatesDotView.frame.size.height);
    
    if (self.loading) self.updatesDotView.hidden = true;
    else self.updatesDotView.hidden = !self.updates;
    
    [self updateTitleFrame];
}

- (void)updateTitleFrame {
    if (self.loading) {
        self.campTitleLabel.frame = CGRectMake(12, self.campTitleLabel.frame.origin.y, self.frame.size.width - 24, self.campTitleLabel.frame.size.height);
    }
    else {
        self.campTitleLabel.frame = CGRectMake(self.campTitleLabel.frame.origin.x, self.campTitleLabel.frame.origin.y, self.frame.size.width - (self.campTitleLabel.frame.origin.x * 2), self.campTitleLabel.frame.size.height);
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    if (!self.loading) {
        if (highlighted) {
            [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
                //self.alpha = 0.75;
                self.transform = CGAffineTransformMakeScale(0.92, 0.92);
            } completion:nil];
        }
        else {
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
                self.alpha = 1;
                self.transform = CGAffineTransformIdentity;
            } completion:nil];
        }
    }
}

- (void)setLoading:(BOOL)loading {
    if (loading != _loading) {
        _loading = loading;
        
        if (_loading) {
            self.campTitleLabel.textColor = [UIColor clearColor];
            self.campTitleLabel.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
            self.campTitleLabel.layer.masksToBounds = true;
            self.campTitleLabel.layer.cornerRadius = 4.f;
        }
        else {
            self.campTitleLabel.textColor = [UIColor bonfirePrimaryColor];
            self.campTitleLabel.backgroundColor = [UIColor clearColor];
            self.campTitleLabel.layer.masksToBounds = false;
            self.campTitleLabel.layer.cornerRadius = 0;
        }
    }
}

@end
