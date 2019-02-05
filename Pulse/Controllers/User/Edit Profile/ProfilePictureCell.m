//
//  ProfilePictureCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ProfilePictureCell.h"
#import <Tweaks/FBTweakInline.h>
#import "Session.h"

@implementation ProfilePictureCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.profilePicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 24, 96, 96)];
        self.profilePicture.user = [Session sharedInstance].currentUser;
        self.profilePicture.userInteractionEnabled = false;
        [self.contentView addSubview:self.profilePicture];
        
        self.changeProfilePictureLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 96, 28)];
        self.changeProfilePictureLabel.text = @"Edit Photo";
        self.changeProfilePictureLabel.textAlignment = NSTextAlignmentCenter;
        self.changeProfilePictureLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold];
        self.changeProfilePictureLabel.userInteractionEnabled = false;
        self.changeProfilePictureLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
        
        CALayer *layer = self.changeProfilePictureLabel.layer;
        layer.cornerRadius = 14.f;
        layer.masksToBounds = NO;
        
        layer.shadowOffset = CGSizeMake(0, (1 / [UIScreen mainScreen].scale));
        layer.shadowColor = [[UIColor blackColor] CGColor];
        layer.shadowRadius = 1.f;
        layer.shadowOpacity = 0.14f;
        layer.shadowPath = [[UIBezierPath bezierPathWithRoundedRect:layer.bounds cornerRadius:layer.cornerRadius] CGPath];
        
        CGColorRef  bColor = [UIColor whiteColor].CGColor;
        layer.backgroundColor =  bColor;

        
        [self.contentView addSubview:self.changeProfilePictureLabel];
    }
    
    return self;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted) {
        [UIView animateWithDuration:0.2f animations:^{
            self.backgroundColor = [UIColor colorWithDisplayP3Red:0.92 green:0.92 blue:0.92 alpha:1.00];
        }];
    }
    else {
        [UIView animateWithDuration:0.2f animations:^{
            self.backgroundColor = [UIColor whiteColor];
        }];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.profilePicture.center = CGPointMake(self.frame.size.width / 2, self.profilePicture.center.y);
    self.changeProfilePictureLabel.frame = CGRectMake(self.frame.size.width / 2 - self.changeProfilePictureLabel.frame.size.width / 2, 104, self.changeProfilePictureLabel.frame.size.width, self.changeProfilePictureLabel.frame.size.height);
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

@end
