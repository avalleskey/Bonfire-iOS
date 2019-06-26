//
//  ProfilePictureCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ProfilePictureCell.h"
#import "Session.h"
#import "UIColor+Palette.h"

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
        
        self.editPictureImageViewContainer = [[UIView alloc] initWithFrame:CGRectMake(self.profilePicture.frame.size.width - 40 + 6, self.profilePicture.frame.size.height - 40 + 6, 40, 40)];
        self.editPictureImageViewContainer.backgroundColor = [UIColor whiteColor];
        self.editPictureImageViewContainer.layer.cornerRadius = self.editPictureImageViewContainer.frame.size.height / 2;
        [self.contentView addSubview:self.editPictureImageViewContainer];
        
        self.editPictureImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        self.editPictureImageView.frame = CGRectMake(4, 4, 32, 32);
        self.editPictureImageView.image = [[UIImage imageNamed:@"editProfilePictureIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.editPictureImageView.tintColor = [UIColor bonfireBlack];
        [self.editPictureImageViewContainer addSubview:self.editPictureImageView];
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
    self.editPictureImageViewContainer.frame = CGRectMake(self.profilePicture.frame.origin.x + self.profilePicture.frame.size.width - 40 + 8, self.profilePicture.frame.origin.y + self.profilePicture.frame.size.height - 40 + 8, 40, 40);
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

@end
