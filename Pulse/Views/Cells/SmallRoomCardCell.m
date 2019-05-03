//
//  SmallRoomCardCell.m
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "SmallRoomCardCell.h"
#import "UIColor+Palette.h"
#import "Session.h"

#define padding 16

@implementation SmallRoomCardCell

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
    
    self.profilePicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(16, 12, 48, 48)];
    self.profilePicture.userInteractionEnabled = false;
    [self.contentView addSubview:self.profilePicture];
    
    self.themeLine = [[UIView alloc] initWithFrame:CGRectMake(self.profilePicture.frame.origin.x - 4, self.profilePicture.frame.origin.y - 4, self.profilePicture.frame.size.width + 8, self.profilePicture.frame.size.height + 8)];
    self.themeLine.layer.cornerRadius = self.themeLine.frame.size.width / 2;
    self.themeLine.layer.borderWidth = 2.f;
    self.themeLine.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1].CGColor;
    [self.contentView addSubview:self.themeLine];
    
    self.member1 = [[BFAvatarView alloc] initWithFrame:CGRectMake(76, 70, 16, 16)];
    self.member1.tag = 0;
    self.member2 = [[BFAvatarView alloc] initWithFrame:CGRectMake(self.member1.frame.origin.x + 10, self.member1.frame.origin.y, self.member1.frame.size.width, self.member1.frame.size.height)];
    self.member2.tag = 1;
    self.member3 = [[BFAvatarView alloc] initWithFrame:CGRectMake(self.member2.frame.origin.x + 10, self.member1.frame.origin.y, self.member1.frame.size.width, self.member1.frame.size.height)];
    self.member3.tag = 2;
    
    [self.contentView addSubview:self.member3];
    [self.contentView addSubview:self.member2];
    [self.contentView addSubview:self.member1];
    
    [self styleMemberProfilePictureView:self.member1];
    [self styleMemberProfilePictureView:self.member2];
    [self styleMemberProfilePictureView:self.member3];
    
    self.roomTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(76, 10, self.frame.size.width - 76 - 16, 19)];
    self.roomTitleLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightBold];
    self.roomTitleLabel.textAlignment = NSTextAlignmentLeft;
    self.roomTitleLabel.numberOfLines = 1;
    self.roomTitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.roomTitleLabel.textColor = [UIColor bonfireBlack];
    self.roomTitleLabel.text = @"";
    [self.contentView addSubview:self.roomTitleLabel];
    
    self.roomDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.roomTitleLabel.frame.origin.x, self.roomTitleLabel.frame.origin.y + self.roomTitleLabel.frame.size.height + 2, self.roomTitleLabel.frame.size.width, 28)];
    self.roomDescriptionLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightRegular];
    self.roomDescriptionLabel.textAlignment = NSTextAlignmentLeft;
    self.roomDescriptionLabel.numberOfLines = 0;
    self.roomDescriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.roomDescriptionLabel.textColor = [UIColor bonfireGray];
    self.roomDescriptionLabel.text = @"";
    [self.contentView addSubview:self.roomDescriptionLabel];
    
    self.membersLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.member3.frame.origin.x + self.member3.frame.size.width + 6, self.member1.frame.origin.y, 110, self.member1.frame.size.height)];
    self.membersLabel.textAlignment = NSTextAlignmentLeft;
    self.membersLabel.font = [UIFont systemFontOfSize:10.f weight:UIFontWeightMedium];
    self.membersLabel.textColor = [UIColor colorWithWhite:0.47f alpha:1];
    [self.contentView addSubview:self.membersLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // title
    CGRect titleLabelRect = self.roomTitleLabel.frame;
    titleLabelRect.size.width = self.frame.size.width - 76 - 16;
    self.roomTitleLabel.frame = titleLabelRect;
    
    // description
    CGSize descriptionSize = [self.roomDescriptionLabel.text boundingRectWithSize:CGSizeMake(self.roomDescriptionLabel.frame.size.width, self.roomDescriptionLabel.font.lineHeight * 2)
                                                              options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                                           attributes:@{NSFontAttributeName:self.roomDescriptionLabel.font}
                                                              context:nil].size;
    CGRect descriptionLabelRect = self.roomTitleLabel.frame;
    descriptionLabelRect.origin.y = titleLabelRect.origin.y + titleLabelRect.size.height + 2;
    descriptionLabelRect.size.width = titleLabelRect.size.width;
    descriptionLabelRect.size.height = self.roomDescriptionLabel.text.length == 0 ? 0 :  ceilf(descriptionSize.height);
    self.roomDescriptionLabel.frame = descriptionLabelRect;
    
    CGRect membersLabelFrame = self.membersLabel.frame;
    CGFloat membersLabelLeftPadding = 6;
    if (self.member1.isHidden) {
        membersLabelFrame.origin.x = self.member1.frame.origin.x;
    }
    else if (self.member2.isHidden) {
        membersLabelFrame.origin.x = self.member1.frame.origin.x + self.member1.frame.size.width + membersLabelLeftPadding;
    }
    else if (self.member3.isHidden) {
        membersLabelFrame.origin.x = self.member2.frame.origin.x + self.member2.frame.size.width + membersLabelLeftPadding;
    }
    else {
        membersLabelFrame.origin.x = self.member3.frame.origin.x + self.member3.frame.size.width + membersLabelLeftPadding;
    }
    membersLabelFrame.size.width = self.frame.size.width - membersLabelFrame.origin.x - 16;
    self.membersLabel.frame = membersLabelFrame;
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
    
    CGFloat borderWidth = 2.f;
    UIView *borderVeiw = [[UIView alloc] initWithFrame:CGRectMake(imageView.frame.origin.x - borderWidth, imageView.frame.origin.y - borderWidth, imageView.frame.size.width + (borderWidth * 2), imageView.frame.size.height + (borderWidth * 2))];
    borderVeiw.backgroundColor = [UIColor whiteColor];
    borderVeiw.layer.cornerRadius = borderVeiw.frame.size.height / 2;
    borderVeiw.layer.masksToBounds = true;
    [self.contentView insertSubview:borderVeiw belowSubview:imageView];
}

- (void)setLoading:(BOOL)loading {
    _loading = loading;
    
    if (_loading) {
        self.roomTitleLabel.text = @"Loading Camp";
        self.roomTitleLabel.textColor = [UIColor clearColor];
        self.roomTitleLabel.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
        self.roomTitleLabel.layer.masksToBounds = true;
        self.roomTitleLabel.layer.cornerRadius = 4.f;
        
        self.profilePicture.room = nil;
        self.profilePicture.tintColor = [UIColor bonfireGrayWithLevel:500];
        
        self.roomDescriptionLabel.hidden =
        self.membersLabel.hidden =
        self.member1.superview.hidden =
        self.member2.superview.hidden =
        self.member3.superview.hidden = true;
    }
    else {
        self.roomTitleLabel.textColor = [UIColor bonfireBlack];
        self.roomTitleLabel.backgroundColor = [UIColor clearColor];
        self.roomTitleLabel.layer.masksToBounds = false;
        self.roomTitleLabel.layer.cornerRadius = 0;
        
        self.roomDescriptionLabel.hidden =
        self.membersLabel.hidden = false;
    }
}

- (void)setRoom:(Room *)room {
    if (room != _room) {
        _room = room;
        
        self.tintColor = [UIColor fromHex:self.room.attributes.details.color];
        
        self.themeLine.layer.borderColor = [UIColor fromHex:self.room.attributes.details.color].CGColor;
        
        self.roomTitleLabel.text = _room.attributes.details.title;
        self.roomDescriptionLabel.text = _room.attributes.details.theDescription;
        
        self.profilePicture.room = _room;
        
        DefaultsRoomMembersTitle *membersTitle = [Session sharedInstance].defaults.room.membersTitle;
        if (self.room.attributes.summaries.counts.members) {
            NSInteger members = self.room.attributes.summaries.counts.members;
            self.membersLabel.text = [NSString stringWithFormat:@"%ld %@", members, members == 1 ? [membersTitle.singular lowercaseString] : [membersTitle.plural lowercaseString]];
            
            if (members > 0) {
                // setup the replies view
                for (NSInteger i = 0; i < 3; i++) {
                    BFAvatarView *avatarView;
                    if (i == 0) avatarView = self.member1;
                    if (i == 1) avatarView = self.member2;
                    if (i == 2) avatarView = self.member3;
                    
                    if (self.room.attributes.summaries.members.count > i) {
                        avatarView.hidden = false;
                        
                        User *userForImageView = [[User alloc] initWithDictionary:self.room.attributes.summaries.members[i] error:nil];
                        
                        avatarView.user = userForImageView;
                    }
                    else {
                        avatarView.hidden = true;
                    }
                }
            }
        }
        else {
            self.membersLabel.text = [NSString stringWithFormat:@"0 %@", [membersTitle.plural lowercaseString]];
        }
    }
}

@end
