//
//  RoomCardCell.m
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "MediumRoomCardCell.h"
#import "UIColor+Palette.h"

#define padding 16

@implementation MediumRoomCardCell

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.room = [[Room alloc] init];
    
    self.backgroundColor = [UIColor whiteColor];
    self.layer.cornerRadius = 12.f;
    self.layer.masksToBounds = false;
    self.layer.shadowRadius = 2.f;
    self.layer.shadowOffset = CGSizeMake(0, 1);
    self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.1f].CGColor;
    self.layer.shadowOpacity = 1.f;
    self.contentView.layer.cornerRadius = self.layer.cornerRadius;
    self.contentView.layer.masksToBounds = true;
    
    self.roomHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 72)];
    self.roomHeaderView.backgroundColor = [UIColor bonfireOrange];
    [self.contentView addSubview:self.roomHeaderView];
    
    self.profilePictureContainerView = [[UIView alloc] initWithFrame:CGRectMake(20, 20, 80, 80)];
    self.profilePictureContainerView.userInteractionEnabled = false;
    self.profilePictureContainerView.backgroundColor = [UIColor whiteColor];
    self.profilePictureContainerView.layer.cornerRadius = self.profilePictureContainerView.frame.size.width / 2;
    // self.profilePictureContainerView.layer.shadowOffset = CGSizeMake(0, 1);
    // self.profilePictureContainerView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.08].CGColor;
    self.profilePictureContainerView.layer.masksToBounds = false;
    // self.profilePictureContainerView.layer.shadowRadius = 2.f;
    //self.profilePictureContainerView.layer.shadowOpacity = 1;
    
    self.profilePicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(4, 4, 72, 72)];
    self.profilePicture.center = CGPointMake(self.profilePictureContainerView.frame.size.width / 2, self.profilePictureContainerView.frame.size.height / 2);
    [self.profilePictureContainerView addSubview:self.profilePicture];
    [self.contentView addSubview:self.profilePictureContainerView];
    
    self.member1 = [[BFAvatarView alloc] initWithFrame:CGRectMake(38, 60, 32, 32)];
    self.member1.tag = 0;
    self.member2 = [[BFAvatarView alloc] initWithFrame:CGRectMake(198, 28, 32, 32)];
    self.member2.tag = 1;
    self.member3 = [[BFAvatarView alloc] initWithFrame:CGRectMake(-6, 34, 22, 22)];
    self.member3.tag = 2;
    self.member4 = [[BFAvatarView alloc] initWithFrame:CGRectMake(252, 64, 22, 22)];
    self.member4.tag = 3;
    
    [self.contentView addSubview:self.member1];
    [self.contentView addSubview:self.member2];
    [self.contentView addSubview:self.member3];
    [self.contentView addSubview:self.member4];
    
    [self styleMemberProfilePictureView:self.member1];
    [self styleMemberProfilePictureView:self.member2];
    [self styleMemberProfilePictureView:self.member3];
    [self styleMemberProfilePictureView:self.member4];
    
    self.roomTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, self.profilePictureContainerView.frame.origin.y + self.profilePictureContainerView.frame.size.height + 8, self.frame.size.width - 40, 21)];
    self.roomTitleLabel.font = [UIFont systemFontOfSize:28.f weight:UIFontWeightHeavy];
    self.roomTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.roomTitleLabel.numberOfLines = 0;
    self.roomTitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.roomTitleLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
    self.roomTitleLabel.text = @"Baseball Fans";
    [self.contentView addSubview:self.roomTitleLabel];
    
    self.roomDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.roomTitleLabel.frame.origin.x, self.roomTitleLabel.frame.origin.y + self.roomTitleLabel.frame.size.height + 2, self.roomTitleLabel.frame.size.width, 14)];
    self.roomDescriptionLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
    self.roomDescriptionLabel.textAlignment = NSTextAlignmentCenter;
    self.roomDescriptionLabel.numberOfLines = 0;
    self.roomDescriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.roomDescriptionLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
    self.roomDescriptionLabel.text = @"We just really like pinball machines, ok?";
    [self.contentView addSubview:self.roomDescriptionLabel];
    
    self.loading = true;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.roomHeaderView.frame = CGRectMake(self.roomHeaderView.frame.origin.x, self.roomHeaderView.frame.origin.y, self.frame.size.width, self.roomHeaderView.frame.size.height);
    self.profilePictureContainerView.center = CGPointMake(self.roomHeaderView.frame.size.width / 2, self.profilePictureContainerView.center.y);
    
    // title
    CGSize titleSize = [self.roomTitleLabel.text boundingRectWithSize:CGSizeMake(self.roomTitleLabel.frame.size.width, self.roomTitleLabel.font.lineHeight * 2)
                                                     options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                                  attributes:@{NSFontAttributeName:self.roomTitleLabel.font}
                                                     context:nil].size;
    CGRect titleLabelRect = self.roomTitleLabel.frame;
    titleLabelRect.size.width = self.frame.size.width - 40;
    titleLabelRect.size.height = ceilf(titleSize.height);
    self.roomTitleLabel.frame = titleLabelRect;
    
    // description
    CGSize descriptionSize = [self.roomDescriptionLabel.text boundingRectWithSize:CGSizeMake(self.roomDescriptionLabel.frame.size.width, self.roomDescriptionLabel.font.lineHeight * 3)
                                                              options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                                           attributes:@{NSFontAttributeName:self.roomDescriptionLabel.font}
                                                              context:nil].size;
    CGRect descriptionLabelRect = self.roomTitleLabel.frame;
    descriptionLabelRect.origin.y = titleLabelRect.origin.y + titleLabelRect.size.height + 2;
    descriptionLabelRect.size.width = titleLabelRect.size.width;
    descriptionLabelRect.size.height = ceilf(descriptionSize.height);
    self.roomDescriptionLabel.frame = descriptionLabelRect;
}

- (void)setHighlighted:(BOOL)highlighted {
    if (!self.loading) {
        if (highlighted) {
            [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                //self.alpha = 0.75;
                self.transform = CGAffineTransformMakeScale(0.96, 0.96);
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

- (void)styleMemberProfilePictureView:(UIView *)imageView  {
    imageView.userInteractionEnabled = false;
    
    CGFloat borderWidth = 3.f;
    UIView *borderVeiw = [[UIView alloc] initWithFrame:CGRectMake(imageView.frame.origin.x - borderWidth, imageView.frame.origin.y - borderWidth, imageView.frame.size.width + (borderWidth * 2), imageView.frame.size.height + (borderWidth * 2))];
    borderVeiw.backgroundColor = [UIColor whiteColor];
    borderVeiw.layer.cornerRadius = borderVeiw.frame.size.height / 2;
    borderVeiw.layer.masksToBounds = true;
    [self.contentView insertSubview:borderVeiw belowSubview:imageView];
    
    // move imageview to child of border view
    [imageView removeFromSuperview];
    imageView.frame = CGRectMake(borderWidth, borderWidth, imageView.frame.size.width, imageView.frame.size.height);
    [borderVeiw addSubview:imageView];
}

- (void)setLoading:(BOOL)loading {
    _loading = loading;
    
    if (_loading) {
        self.roomTitleLabel.text = @"Loading Camp";
        self.roomTitleLabel.textColor = [UIColor clearColor];
        self.roomTitleLabel.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
        self.roomTitleLabel.layer.masksToBounds = true;
        self.roomTitleLabel.layer.cornerRadius = 4.f;
        
        self.roomDescriptionLabel.text = @"Mini description!";
        self.roomDescriptionLabel.textColor = [UIColor clearColor];
        self.roomDescriptionLabel.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1];
        self.roomDescriptionLabel.layer.masksToBounds = true;
        self.roomDescriptionLabel.layer.cornerRadius = 4.f;
        
        self.roomHeaderView.backgroundColor = [UIColor bonfireGrayWithLevel:100];
        self.profilePicture.room = nil;
        self.profilePicture.tintColor = [UIColor bonfireGrayWithLevel:500];
        
        self.member1.superview.hidden =
        self.member2.superview.hidden =
        self.member3.superview.hidden =
        self.member4.superview.hidden = true;
    }
    else {
        self.roomTitleLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
        self.roomTitleLabel.backgroundColor = [UIColor clearColor];
        self.roomTitleLabel.layer.masksToBounds = false;
        self.roomTitleLabel.layer.cornerRadius = 0;
        
        self.roomDescriptionLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
        self.roomDescriptionLabel.backgroundColor = [UIColor clearColor];
        self.roomDescriptionLabel.layer.masksToBounds = false;
        self.roomDescriptionLabel.layer.cornerRadius = 0;
    }
}

@end
