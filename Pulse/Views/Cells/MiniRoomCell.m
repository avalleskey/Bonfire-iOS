//
//  MiniRoomCell.m
//  Pulse
//
//  Created by Austin Valleskey on 12/22/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "MiniRoomCell.h"
#import "UIColor+Palette.h"

@implementation MiniRoomCell

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.updates = false;
    self.roomPicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - 32, 8, 64, 64)];
    self.roomPicture.userInteractionEnabled = false;
    [self.contentView addSubview:self.roomPicture];
    
    self.roomTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, self.roomPicture.frame.origin.y + self.roomPicture.frame.size.height + 8, self.frame.size.width - 8, 30)];
    self.roomTitleLabel.numberOfLines = 0;
    self.roomTitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.roomTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.roomTitleLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightSemibold];
    self.roomTitleLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
    [self.contentView addSubview:self.roomTitleLabel];
    
    self.updatesDotView = [[UIImageView alloc] initWithFrame:CGRectMake(self.roomPicture.frame.origin.x + self.roomPicture.frame.size.width - 18 - 1, self.roomPicture.frame.origin.y + 1, 18, 18)];
    self.updatesDotView.image = [UIImage imageNamed:@"roomUpdatesDot"];
    [self.contentView addSubview:self.updatesDotView];
    
    self.loading = true;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.roomPicture.center = CGPointMake(self.frame.size.width / 2, self.roomPicture.center.y);
    self.updatesDotView.frame = CGRectMake(self.roomPicture.frame.origin.x + self.roomPicture.frame.size.width - self.updatesDotView.frame.size.width - 1, self.roomPicture.frame.origin.y + 1, self.updatesDotView.frame.size.width, self.updatesDotView.frame.size.height);
    
    if (self.loading) self.updatesDotView.hidden = true;
    else self.updatesDotView.hidden = !self.updates;
    
    // [self updateTitleFrame];
}

- (void)updateTitleFrame {
    CGSize titleSize = [self.roomTitleLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - 8, MAXFLOAT) options:(NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName:self.roomTitleLabel.font} context:nil].size;
    NSLog(@"TITLE SIZE: %f", titleSize.height);
    if (self.loading) {
        self.roomTitleLabel.frame = CGRectMake(self.roomTitleLabel.frame.origin.x, self.roomTitleLabel.frame.origin.y, ceilf(titleSize.width), ceilf(titleSize.height));
    }
    else {
        self.roomTitleLabel.frame = CGRectMake(self.roomTitleLabel.frame.origin.x, self.roomTitleLabel.frame.origin.y, self.frame.size.width - (self.roomTitleLabel.frame.origin.x * 2), ceilf(titleSize.height));
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    if (!self.loading) {
        if (highlighted) {
            [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                //self.alpha = 0.75;
                self.transform = CGAffineTransformMakeScale(0.92, 0.92);
            } completion:nil];
        }
        else {
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
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
            self.roomTitleLabel.textColor = [UIColor clearColor];
            self.roomTitleLabel.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
            self.roomTitleLabel.layer.masksToBounds = true;
            self.roomTitleLabel.layer.cornerRadius = 4.f;
        }
        else {
            self.roomTitleLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
            self.roomTitleLabel.backgroundColor = [UIColor clearColor];
            self.roomTitleLabel.layer.masksToBounds = false;
            self.roomTitleLabel.layer.cornerRadius = 0;
        }
    }
}

@end
