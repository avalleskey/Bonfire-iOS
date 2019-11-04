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
        self.backgroundColor = [UIColor contentBackgroundColor];

        CGFloat profilePicBorderWidth = 6;
        self.profilePictureContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 24 - profilePicBorderWidth, 128 + (profilePicBorderWidth * 2), 128 + (profilePicBorderWidth * 2))];
        self.profilePictureContainer.backgroundColor = [UIColor contentBackgroundColor];
        self.profilePictureContainer.layer.cornerRadius = self.profilePictureContainer.frame.size.height / 2;
        self.profilePictureContainer.layer.masksToBounds = false;
        self.profilePictureContainer.layer.shadowColor = [UIColor blackColor].CGColor;
        self.profilePictureContainer.layer.shadowOffset = CGSizeMake(0, 1);
        self.profilePictureContainer.layer.shadowRadius = 2.f;
        self.profilePictureContainer.layer.shadowOpacity = 0.12;
        self.profilePictureContainer.center = CGPointMake(self.contentView.frame.size.width / 2, self.profilePictureContainer.center.y);
        [self.contentView addSubview:self.profilePictureContainer];
        
        self.profilePicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(profilePicBorderWidth, profilePicBorderWidth, 128, 128)];
        self.profilePicture.user = [Session sharedInstance].currentUser;
        self.profilePicture.userInteractionEnabled = false;
        [self.profilePictureContainer addSubview:self.profilePicture];
        
        self.editPictureImageViewContainer = [[UIView alloc] initWithFrame:CGRectMake(self.profilePicture.frame.size.width - 40 + 6, self.profilePicture.frame.size.height - 40 + 6, 40, 40)];
        self.editPictureImageViewContainer.backgroundColor = [UIColor bonfireDetailColor];
        self.editPictureImageViewContainer.layer.cornerRadius = self.editPictureImageViewContainer.frame.size.height / 2;
        self.editPictureImageViewContainer.layer.shadowColor = [UIColor blackColor].CGColor;
        self.editPictureImageViewContainer.layer.shadowOffset = CGSizeMake(0, 1);
        self.editPictureImageViewContainer.layer.shadowRadius = 2.f;
        self.editPictureImageViewContainer.layer.shadowOpacity = 0.12;
        [self.contentView addSubview:self.editPictureImageViewContainer];
        
        self.editPictureImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        self.editPictureImageView.frame = CGRectMake(4, 4, 32, 32);
        self.editPictureImageView.image = [[UIImage imageNamed:@"editProfilePictureIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.editPictureImageView.tintColor = [UIColor bonfirePrimaryColor];
        [self.editPictureImageViewContainer addSubview:self.editPictureImageView];
    }
    
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  if (!self.clipsToBounds && !self.hidden && self.alpha > 0) {
    for (UIView *subview in self.contentView.subviews.reverseObjectEnumerator) {
      CGPoint subPoint = [subview convertPoint:point fromView:self];
      UIView *result = [subview hitTest:subPoint withEvent:event];
      if (result != nil) {
        return result;
      }
    }
  }
  
  return [super hitTest:point withEvent:event];
}

- (void)layoutSubviews {
    [super layoutSubviews];
        
    self.profilePictureContainer.frame = CGRectMake(self.frame.size.width / 2 - self.profilePictureContainer.frame.size.width / 2, ceilf(self.profilePictureContainer.frame.size.height * -0.65), self.profilePictureContainer.frame.size.width, self.profilePictureContainer.frame.size.height);
    self.editPictureImageViewContainer.frame = CGRectMake(self.profilePictureContainer.frame.origin.x + self.profilePictureContainer.frame.size.width - 40 - 6, self.profilePictureContainer.frame.origin.y + self.profilePictureContainer.frame.size.height - 40 - 6, 40, 40);
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

+ (CGFloat)height {
    return ceilf(128 * -0.65) + 128 + 32;
}

@end
