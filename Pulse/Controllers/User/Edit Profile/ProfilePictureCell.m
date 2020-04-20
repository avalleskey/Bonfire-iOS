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
        
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor contentBackgroundColor];
        
        self.clipsToBounds = NO;                        //cell's view
        self.contentView.clipsToBounds = NO;            //contentView
        self.contentView.superview.clipsToBounds = NO;  //scrollView

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
        [self addSubview:self.profilePictureContainer];
        
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
        [self addSubview:self.editPictureImageViewContainer];
        
        self.editPictureImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        self.editPictureImageView.frame = CGRectMake(4, 4, 32, 32);
        self.editPictureImageView.image = [[UIImage imageNamed:@"editProfilePictureIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.editPictureImageView.tintColor = [UIColor bonfirePrimaryColor];
        [self.editPictureImageViewContainer addSubview:self.editPictureImageView];
        
        
        self.editCoverPhotoImageViewContainer = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width - 40 + 12, self.frame.size.height - 40 + 6, 40, 40)];
        self.editCoverPhotoImageViewContainer.backgroundColor = [UIColor bonfireDetailColor];
        self.editCoverPhotoImageViewContainer.layer.cornerRadius = self.editPictureImageViewContainer.frame.size.height / 2;
        self.editCoverPhotoImageViewContainer.layer.shadowColor = [UIColor blackColor].CGColor;
        self.editCoverPhotoImageViewContainer.layer.shadowOffset = CGSizeMake(0, 1);
        self.editCoverPhotoImageViewContainer.layer.shadowRadius = 2.f;
        self.editCoverPhotoImageViewContainer.layer.shadowOpacity = 0.12;
//        [self addSubview:self.editCoverPhotoImageViewContainer];
        
        self.editCoverPhotoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        self.editCoverPhotoImageView.frame = CGRectMake(4, 4, 32, 32);
        self.editCoverPhotoImageView.image = [[UIImage imageNamed:@"editProfilePictureIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.editCoverPhotoImageView.tintColor = [UIColor bonfirePrimaryColor];
        [self.editCoverPhotoImageViewContainer addSubview:self.editCoverPhotoImageView];
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
        
    self.profilePictureContainer.frame = CGRectMake(self.frame.size.width / 2 - self.profilePictureContainer.frame.size.width / 2, 16, self.profilePictureContainer.frame.size.width, self.profilePictureContainer.frame.size.height);
    self.editPictureImageViewContainer.frame = CGRectMake(self.profilePictureContainer.frame.origin.x + self.profilePictureContainer.frame.size.width - 40 - 6, self.profilePictureContainer.frame.origin.y + self.profilePictureContainer.frame.size.height - 40 - 6, 40, 40);
    
    self.contentView.frame = CGRectMake(0, 16 + ceilf(128 * 0.65), self.frame.size.width, self.frame.size.height - (16 + ceilf(128 * 0.65)));
    
    self.editCoverPhotoImageViewContainer.frame = CGRectMake(self.frame.size.width - self.editCoverPhotoImageViewContainer.frame.size.width - 12, self.contentView.frame.origin.y + (-.5 * self.editCoverPhotoImageViewContainer.frame.size.height), self.editCoverPhotoImageViewContainer.frame.size.width, self.editCoverPhotoImageViewContainer.frame.size.height);
}

+ (CGFloat)height {
    return 128 + 32;
}

@end
