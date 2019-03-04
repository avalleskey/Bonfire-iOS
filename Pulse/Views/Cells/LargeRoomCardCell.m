//
//  LargeRoomCardCell.m
//  Pulse
//
//  Created by Austin Valleskey on 12/22/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "LargeRoomCardCell.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <HapticHelper/HapticHelper.h>
#import "Session.h"
#import "UIColor+Palette.h"

#define UIViewParentController(__view) ({ \
                                        UIResponder *__responder = __view; \
                                        while ([__responder isKindOfClass:[UIView class]]) \
                                        __responder = [__responder nextResponder]; \
                                        (UIViewController *)__responder; \
                                        })

@implementation LargeRoomCardCell

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
    self.profilePictureContainerView.layer.shadowOffset = CGSizeMake(0, 1);
    self.profilePictureContainerView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.08].CGColor;
    self.profilePictureContainerView.layer.masksToBounds = false;
    self.profilePictureContainerView.layer.shadowRadius = 2.f;
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
    self.roomTitleLabel.text = @"Baseball Fans";
    [self.contentView addSubview:self.roomTitleLabel];
    
    self.roomDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.roomTitleLabel.frame.origin.x, self.roomTitleLabel.frame.origin.y + self.roomTitleLabel.frame.size.height + 2, self.roomTitleLabel.frame.size.width, 14)];
    self.roomDescriptionLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
    self.roomDescriptionLabel.textAlignment = NSTextAlignmentCenter;
    self.roomDescriptionLabel.numberOfLines = 0;
    self.roomDescriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.roomDescriptionLabel.text = @"We just really like pinball machines, ok?";
    [self.contentView addSubview:self.roomDescriptionLabel];
    
    self.statsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 40)];
    [self.contentView addSubview:self.statsView];
    
    self.membersLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width / 2, 14)];
    self.membersLabel.textAlignment = NSTextAlignmentCenter;
    self.membersLabel.textColor = [UIColor colorWithWhite:0.47 alpha:1];
    self.membersLabel.font = [UIFont systemFontOfSize:11.f weight:UIFontWeightSemibold];
    self.membersLabel.text = [NSString stringWithFormat:@"0 %@", [Session sharedInstance].defaults.room.membersTitle.plural];
    [self.statsView addSubview:self.membersLabel];
    
    self.postsCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width / 2, 0, self.frame.size.width / 2, 14)];
    self.postsCountLabel.textAlignment = NSTextAlignmentCenter;
    self.postsCountLabel.textColor = [UIColor colorWithWhite:0.47 alpha:1];
    self.postsCountLabel.font = [UIFont systemFontOfSize:11.f weight:UIFontWeightSemibold];
    self.postsCountLabel.text = @"450 posts";
    [self.statsView addSubview:self.postsCountLabel];
    
    self.statsViewMiddleSeparator = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - 0.5, 16, 1, 16)];
    self.statsViewMiddleSeparator.backgroundColor = [UIColor colorWithWhite:0 alpha:0.06f];
    self.statsViewMiddleSeparator.layer.cornerRadius = 1.f;
    self.statsViewMiddleSeparator.layer.masksToBounds = true;
    [self.statsView addSubview:self.statsViewMiddleSeparator];
    
    self.followButton = [RoomFollowButton buttonWithType:UIButtonTypeCustom];
    self.followButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08f];
    [self.followButton bk_whenTapped:^{
        // update state if possible
        if ([self.followButton.status isEqualToString:ROOM_STATUS_MEMBER] ||
            [self.followButton.status isEqualToString:ROOM_STATUS_REQUESTED]) {
            // leave the room
            
            if ([self.followButton.status isEqualToString:ROOM_STATUS_MEMBER]) {
                // confirm action
                BOOL requiresConfirm = self.room.attributes.status.visibility.isPrivate;
                
                if (requiresConfirm) {
                    UIAlertController *confirmDeletePostActionSheet = [UIAlertController alertControllerWithTitle:@"Are you sure you want to leave this Camp?" message:@"You will no longer have access to the posts" preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *confirmLeaveRoom = [UIAlertAction actionWithTitle:@"Leave" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                        [self.followButton updateStatus:ROOM_STATUS_LEFT];
                        [self decrementMembersCount];
                    }];
                    [confirmDeletePostActionSheet addAction:confirmLeaveRoom];
                    
                    UIAlertAction *cancelLeaveRoom = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
                    [confirmDeletePostActionSheet addAction:cancelLeaveRoom];
                    
                    [UIViewParentController(self) presentViewController:confirmDeletePostActionSheet animated:YES completion:nil];
                }
                else {
                    [self.followButton updateStatus:ROOM_STATUS_LEFT];
                    [self decrementMembersCount];
                }
                
            }
            else {
                [self.followButton updateStatus:ROOM_STATUS_NO_RELATION];
            }
            [self updateRoomStatus];
            
            [[Session sharedInstance] unfollowRoom:self.room.identifier completion:^(BOOL success, id responseObject) {
                if (success) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMyRooms" object:nil];
                }
            }];
        }
        else if ([self.followButton.status isEqualToString:ROOM_STATUS_LEFT] ||
                 [self.followButton.status isEqualToString:ROOM_STATUS_NO_RELATION] ||
                 [self.followButton.status isEqualToString:ROOM_STATUS_INVITED] ||
                 self.followButton.status.length == 0) {
            // join the room
            if (self.room.attributes.status.visibility.isPrivate &&
                ![self.followButton.status isEqualToString:ROOM_STATUS_INVITED]) {
                [self.followButton updateStatus:ROOM_STATUS_REQUESTED];
            }
            else {
                // since they've been invited already, jump straight to being a member
                [self.followButton updateStatus:ROOM_STATUS_MEMBER];
                [self incrementMembersCount];
            }
            [self updateRoomStatus];
            
            [HapticHelper generateFeedback:FeedbackType_Notification_Success];
            
            [[Session sharedInstance] followRoom:self.room.identifier completion:^(BOOL success, id responseObject) {
                if (success) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMyRooms" object:nil];
                }
            }];
        }
        else if ([self.followButton.status isEqualToString:ROOM_STATUS_BLOCKED]) {
            // show alert maybe? --> ideally we don't even show the button.
        }
    }];
    [self.contentView addSubview:self.followButton];
    
    self.loading = true;
}

- (void)layoutSubviews {
    [super layoutSubviews];
        
    self.roomHeaderView.frame = CGRectMake(self.roomHeaderView.frame.origin.x, self.roomHeaderView.frame.origin.y, self.frame.size.width, self.roomHeaderView.frame.size.height);
    self.profilePictureContainerView.center = CGPointMake(self.roomHeaderView.frame.size.width / 2, self.profilePictureContainerView.center.y);
    
    // title
    CGSize titleSize = [self.roomTitleLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - 40, self.roomTitleLabel.font.lineHeight * 2)
                                                              options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                                           attributes:@{NSFontAttributeName:self.roomTitleLabel.font}
                                                              context:nil].size;
    CGRect titleLabelRect = self.roomTitleLabel.frame;
    titleLabelRect.size.width = ceilf(titleSize.width);
    titleLabelRect.size.height = ceilf(titleSize.height);
    titleLabelRect.origin.x = (self.frame.size.width / 2) - (titleLabelRect.size.width / 2);
    self.roomTitleLabel.frame = titleLabelRect;
    
    // description
    CGSize descriptionSize = [self.roomDescriptionLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - 40, self.roomDescriptionLabel.font.lineHeight * 3) options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:self.roomDescriptionLabel.font} context:nil].size;
    CGRect descriptionLabelRect = self.roomDescriptionLabel.frame;
    descriptionLabelRect.origin.y = titleLabelRect.origin.y + titleLabelRect.size.height + 2 + (self.loading ? 4 : 0);
    descriptionLabelRect.size.width = ceilf(descriptionSize.width);
    descriptionLabelRect.size.height = ceilf(descriptionSize.height);
    descriptionLabelRect.origin.x = (self.frame.size.width / 2) - (descriptionLabelRect.size.width / 2);
    self.roomDescriptionLabel.frame = descriptionLabelRect;
    
    self.statsView.frame = CGRectMake(self.statsView.frame.origin.x, self.frame.size.height - self.statsView.frame.size.height - 4, self.frame.size.width, self.statsView.frame.size.height);
    self.membersLabel.frame = CGRectMake(20, 0, self.statsView.frame.size.width / 2 - 20, self.statsView.frame.size.height);
    self.postsCountLabel.frame = CGRectMake(self.statsView.frame.size.width / 2, 0, self.statsView.frame.size.width / 2 - 20, self.statsView.frame.size.height);
    self.statsViewMiddleSeparator.center = CGPointMake(self.statsView.frame.size.width / 2, self.statsView.frame.size.height / 2);
    self.followButton.frame = CGRectMake(20, self.statsView.frame.origin.y - 36, self.frame.size.width - 40, 36);
}

- (void)updateRoomStatus {
    RoomContext *context = [[RoomContext alloc] initWithDictionary:[self.room.attributes.context toDictionary] error:nil];
    context.status = self.followButton.status;
    self.room.attributes.context = context;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RoomUpdated" object:self.room];
}
- (void)incrementMembersCount {
    RoomCounts *counts = [[RoomCounts alloc] initWithDictionary:[self.room.attributes.summaries.counts toDictionary] error:nil];
    counts.members = counts.members + 1;
    self.room.attributes.summaries.counts = counts;
    
    [self updateMembersLabel];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RoomUpdated" object:self.room];
}
- (void)decrementMembersCount {
    RoomCounts *counts = [[RoomCounts alloc] initWithDictionary:[self.room.attributes.summaries.counts toDictionary] error:nil];
    counts.members = counts.members > 0 ? counts.members - 1 : 0;
    self.room.attributes.summaries.counts = counts;
    
    [self updateMembersLabel];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RoomUpdated" object:self.room];
}
- (void)updateMembersLabel {
    DefaultsRoomMembersTitle *membersTitle = [Session sharedInstance].defaults.room.membersTitle;
    if (self.room.attributes.summaries.counts.members) {
        NSInteger members = self.room.attributes.summaries.counts.members;
        [UIView performWithoutAnimation:^{
            self.membersLabel.text = [NSString stringWithFormat:@"%ld %@", members, members == 1 ? [membersTitle.singular lowercaseString] : [membersTitle.plural lowercaseString]];
            self.membersLabel.alpha = 1;
        }];
    }
    else {
        [UIView performWithoutAnimation:^{
            self.membersLabel.text = [NSString stringWithFormat:@"0 %@", [membersTitle.plural lowercaseString]];
            self.membersLabel.alpha = 0.5;
        }];
    }
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
        
        self.followButton.hidden =
        self.statsView.hidden =
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
        
        self.followButton.hidden = false;
        self.statsView.hidden = false;
    }

}

@end
