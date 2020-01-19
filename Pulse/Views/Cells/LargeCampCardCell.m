//
//  LargeCampCardCell.m
//  Pulse
//
//  Created by Austin Valleskey on 12/22/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "LargeCampCardCell.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <HapticHelper/HapticHelper.h>
#import "Session.h"
#import "UIColor+Palette.h"
#import "BFAlertController.h"

#define UIViewParentController(__view) ({ \
                                        UIResponder *__responder = __view; \
                                        while ([__responder isKindOfClass:[UIView class]]) \
                                        __responder = [__responder nextResponder]; \
                                        (UIViewController *)__responder; \
                                        })

@interface LargeCampCardCell () {
    CAGradientLayer *gradientLayer;
}

@end

@implementation LargeCampCardCell

@synthesize camp = _camp;

- (id)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
        self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.layer.cornerRadius].CGPath;
        self.contentView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.layer.cornerRadius].CGPath;
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.camp = [[Camp alloc] init];
    
    self.backgroundColor = [UIColor cardBackgroundColor];
    self.layer.cornerRadius = 12.f;
    self.layer.masksToBounds = false;
    self.layer.shadowRadius = 1.f;
    self.layer.shadowOffset = CGSizeMake(0, 1);
    self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.08f].CGColor;
    self.layer.shadowOpacity = 1.f;
    self.layer.borderWidth = (1 / [UIScreen mainScreen].scale);
    self.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.1f].CGColor;
    self.contentView.layer.cornerRadius = self.layer.cornerRadius;
    self.contentView.layer.masksToBounds = true;
    self.layer.shouldRasterize = true;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    self.campHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 72)];
    self.campHeaderView.backgroundColor = [UIColor bonfireOrange];
    
    gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.campHeaderView.bounds;
    [self.campHeaderView.layer addSublayer:gradientLayer];
    
    [self.contentView addSubview:self.campHeaderView];
    
    self.profilePictureContainerView = [[UIView alloc] initWithFrame:CGRectMake(20, 20, 80, 80)];
    self.profilePictureContainerView.userInteractionEnabled = false;
    self.profilePictureContainerView.backgroundColor = [UIColor contentBackgroundColor];
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
    
    self.member1 = [[BFAvatarView alloc] initWithFrame:CGRectMake(42, 64, 32, 32)];
    self.member1.tag = 0;
    self.member2 = [[BFAvatarView alloc] initWithFrame:CGRectMake(194, 24, 32, 32)];
    self.member2.tag = 1;
    self.member3 = [[BFAvatarView alloc] initWithFrame:CGRectMake(-10, 24, 32, 32)];
    self.member3.tag = 2;
    self.member4 = [[BFAvatarView alloc] initWithFrame:CGRectMake(244, 64, 32, 32)];
    self.member4.tag = 3;
    
    [self.contentView addSubview:self.member1];
    [self.contentView addSubview:self.member2];
    [self.contentView addSubview:self.member3];
    [self.contentView addSubview:self.member4];
    
    [self styleMemberProfilePictureView:self.member1];
    [self styleMemberProfilePictureView:self.member2];
    [self styleMemberProfilePictureView:self.member3];
    [self styleMemberProfilePictureView:self.member4];
    
    self.campTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, self.profilePictureContainerView.frame.origin.y + self.profilePictureContainerView.frame.size.height + 8, self.frame.size.width - 40, 21)];
    self.campTitleLabel.font = [UIFont systemFontOfSize:26.f weight:UIFontWeightHeavy];
    self.campTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.campTitleLabel.numberOfLines = 0;
    self.campTitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.campTitleLabel.text = @"Baseball Fans";
    [self.contentView addSubview:self.campTitleLabel];
    
    self.campTagLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, self.campTitleLabel.frame.origin.y + self.campTitleLabel.frame.size.height + 4, self.frame.size.width - 32, 18)];
    self.campTagLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightHeavy];
    self.campTagLabel.textAlignment = NSTextAlignmentCenter;
    self.campTagLabel.numberOfLines = 0;
    self.campTagLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.campTagLabel.textColor = [UIColor bonfirePrimaryColor];
    self.campTagLabel.text = @"#Camptag";
    [self.contentView addSubview:self.campTagLabel];
    
    self.campDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.campTitleLabel.frame.origin.x, self.campTitleLabel.frame.origin.y + self.campTitleLabel.frame.size.height + 2, self.campTitleLabel.frame.size.width, 14)];
    self.campDescriptionLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
    self.campDescriptionLabel.textAlignment = NSTextAlignmentCenter;
    self.campDescriptionLabel.numberOfLines = 0;
    self.campDescriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.campDescriptionLabel.text = @"We just really like pinball machines, ok?";
    self.campDescriptionLabel.textColor = [UIColor bonfireSecondaryColor];
    [self.contentView addSubview:self.campDescriptionLabel];
    
    self.followButton = [CampFollowButton buttonWithType:UIButtonTypeCustom];
    self.followButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08f];
    [self.followButton bk_whenTapped:^{
        // update state if possible
        if ([self.followButton.status isEqualToString:CAMP_STATUS_MEMBER] ||
                 [self.followButton.status isEqualToString:CAMP_STATUS_REQUESTED]) {
            // leave the camp
            
            if ([self.followButton.status isEqualToString:CAMP_STATUS_MEMBER]) {
                // confirm action
                BOOL privateCamp = [self.camp isPrivate];
                BOOL lastMember = self.camp.attributes.summaries.counts.members <= 1;
                
                void (^leave)(void) = ^(){
                    [self.followButton updateStatus:CAMP_STATUS_LEFT];
                    [self leaveCamp];
                };
                
                if (privateCamp || lastMember) {
                    NSString *message;
                    if (privateCamp && lastMember) {
                        message = @"All camps must have at least one member. If you leave, this Camp and all of its posts will be deleted after 30 days of inactivity.";
                    }
                    else if (lastMember) {
                        // leaving as the last member in a public camp
                        message = @"All camps must have at least one member. If you leave, this Camp will be archived and eligible for anyone to reopen.";
                    }
                    else {
                        // leaving a private camp, but the user isn't the last one
                        message = @"You will no longer have access to this Camp's posts";
                    }
                    
                    BFAlertController *confirmDeletePostActionSheet = [BFAlertController alertControllerWithTitle:(([self.camp isChannel] | [self.camp isFeed]) ? @"Unsubscribe?" : @"Leave Camp?") message:message preferredStyle:BFAlertControllerStyleAlert];
                    
                    BFAlertAction *confirmLeaveCamp = [BFAlertAction actionWithTitle:(([self.camp isChannel] | [self.camp isFeed]) ? @"Unsubscribe" : @"Leave") style:BFAlertActionStyleDestructive handler:^{
                        leave();
                    }];
                    [confirmDeletePostActionSheet addAction:confirmLeaveCamp];
                    
                    BFAlertAction *cancelLeaveCamp = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
                    [confirmDeletePostActionSheet addAction:cancelLeaveCamp];
                    
                    [UIViewParentController(self) presentViewController:confirmDeletePostActionSheet animated:true completion:nil];
                }
                else {
                    leave();
                }
            }
            else {
                [self.followButton updateStatus:CAMP_STATUS_NO_RELATION];
                [self leaveCamp];
            }
        }
        else if (!self.followButton.status ||
                 [self.followButton.status isEqualToString:CAMP_STATUS_LEFT] ||
                 [self.followButton.status isEqualToString:CAMP_STATUS_NO_RELATION] ||
                 [self.followButton.status isEqualToString:CAMP_STATUS_INVITED] ||
                 self.followButton.status.length == 0) {
            // join the camp
            if ([self.camp isPrivate] &&
                ![self.followButton.status isEqualToString:CAMP_STATUS_INVITED]) {
                [self.followButton updateStatus:CAMP_STATUS_REQUESTED];
            }
            else {
                // since they've been invited already, jump straight to being a member
                [self.followButton updateStatus:CAMP_STATUS_MEMBER];
            }
            [self updateCampStatus];
            
            [HapticHelper generateFeedback:FeedbackType_Notification_Success];
            
            NSLog(@"biiiiiiingo");
            [BFAPI followCamp:self.camp completion:^(BOOL success, id responseObject) {
                if (success) {
                }
            }];
        }
        else if ([self.followButton.status isEqualToString:CAMP_STATUS_BLOCKED]) {
            // show alert maybe? --> ideally we don't even show the button.
        }
    }];
    [self.contentView addSubview:self.followButton];
    
    self.detailsCollectionView = [[BFDetailsCollectionView alloc] initWithFrame:CGRectMake(16, self.followButton.frame.origin.x - 16 - 12, self.frame.size.width - 32, 16)];
    self.detailsCollectionView.userInteractionEnabled = false;
    [self.contentView addSubview:self.detailsCollectionView];
    
    self.loading = true;
}

- (void)layoutSubviews {
    [super layoutSubviews];
        
    self.campHeaderView.frame = CGRectMake(self.campHeaderView.frame.origin.x, self.campHeaderView.frame.origin.y, self.frame.size.width, self.campHeaderView.frame.size.height);
    gradientLayer.frame = self.campHeaderView.bounds;
    self.profilePictureContainerView.center = CGPointMake(self.campHeaderView.frame.size.width / 2, self.profilePictureContainerView.center.y);
    
    // title
    CGSize titleSize = [self.campTitleLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - 40, self.campTitleLabel.font.lineHeight * 2)
                                                              options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                                           attributes:@{NSFontAttributeName:self.campTitleLabel.font}
                                                              context:nil].size;
    CGRect titleLabelRect = self.campTitleLabel.frame;
    titleLabelRect.size.width = ceilf(titleSize.width);
    titleLabelRect.size.height = ceilf(titleSize.height);
    titleLabelRect.origin.x = (self.frame.size.width / 2) - (titleLabelRect.size.width / 2);
    self.campTitleLabel.frame = titleLabelRect;
    
    if (self.loading) {
        self.campTagLabel.frame = CGRectMake(self.frame.size.width / 4, self.campTitleLabel.frame.origin.y + self.campTitleLabel.frame.size.height + 4, self.frame.size.width / 2, self.campTagLabel.frame.size.height);
    }
    else {
        self.campTagLabel.frame = CGRectMake(16, self.campTitleLabel.frame.origin.y + self.campTitleLabel.frame.size.height + 4, self.frame.size.width - 32, self.campTagLabel.frame.size.height);
    }
    
    // description
    CGSize descriptionSize = [self.campDescriptionLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - (self.campDescriptionLabel.frame.origin.x * 2), self.campDescriptionLabel.font.lineHeight * 2)
                                                                          options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                                                       attributes:@{NSFontAttributeName:self.campDescriptionLabel.font}
                                                                          context:nil].size;
    CGRect descriptionLabelRect = self.campDescriptionLabel.frame;
    descriptionLabelRect.origin.y = self.campTagLabel.frame.origin.y + self.campTagLabel.frame.size.height + 6;
    descriptionLabelRect.size.width = descriptionLabelRect.size.width;
    descriptionLabelRect.size.height = ceilf(descriptionSize.height);
    self.campDescriptionLabel.frame = descriptionLabelRect;
    
    self.followButton.frame = CGRectMake(20, self.frame.size.height - 20 - 36, self.frame.size.width - 40, 36);
    
    self.detailsCollectionView.frame = CGRectMake(self.detailsCollectionView.frame.origin.x, self.followButton.frame.origin.y - 12 - self.detailsCollectionView.frame.size.height, self.frame.size.width - (self.detailsCollectionView.frame.origin.x * 2), self.detailsCollectionView.frame.size.height);
}

- (void)updateCampStatus {
    BFContext *context = [[BFContext alloc] initWithDictionary:[self.camp.attributes.context toDictionary] error:nil];
    BFContextCamp *camp = [[BFContextCamp alloc] initWithDictionary:[context.camp toDictionary] error:nil];
    camp.status = self.followButton.status;
    context.camp = camp;
    self.camp.attributes.context = context;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CampUpdated" object:self.camp];
}
- (void)updateDetailsView {
    // set details view up with members
    BFDetailItem *members = [[BFDetailItem alloc] initWithType:BFDetailItemTypeMembers value:[NSString stringWithFormat:@"%ld", (long)self.camp.attributes.summaries.counts.members] action:nil];
    self.detailsCollectionView.details = @[members];
}


- (void)setHighlighted:(BOOL)highlighted {
    if (!self.loading) {
        if (highlighted) {
            [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
                //self.alpha = 0.75;
                self.transform = CGAffineTransformMakeScale(0.96, 0.96);
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

- (void)styleMemberProfilePictureView:(UIView *)imageView  {
    imageView.userInteractionEnabled = false;
    
    CGFloat borderWidth = 3.f;
    UIView *borderVeiw = [[UIView alloc] initWithFrame:CGRectMake(imageView.frame.origin.x - borderWidth, imageView.frame.origin.y - borderWidth, imageView.frame.size.width + (borderWidth * 2), imageView.frame.size.height + (borderWidth * 2))];
    borderVeiw.backgroundColor = [UIColor contentBackgroundColor];
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
        self.campTitleLabel.text = @"Loading Camp";
        self.campTitleLabel.textColor = [UIColor clearColor];
        self.campTitleLabel.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
        self.campTitleLabel.layer.masksToBounds = true;
        self.campTitleLabel.layer.cornerRadius = 4.f;
        
        self.campDescriptionLabel.text = @"Mini description!";
        self.campDescriptionLabel.textColor = [UIColor clearColor];
        self.campDescriptionLabel.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1];
        self.campDescriptionLabel.layer.masksToBounds = true;
        self.campDescriptionLabel.layer.cornerRadius = 4.f;
        
        self.campHeaderView.backgroundColor = [UIColor bonfireGrayWithLevel:100];
        self.profilePicture.camp = nil;
        self.profilePicture.tintColor = [UIColor bonfireGrayWithLevel:500];
        
        self.followButton.hidden =
        self.detailsCollectionView.hidden =
        self.campDescriptionLabel.hidden =
        self.member1.superview.hidden =
        self.member2.superview.hidden =
        self.member3.superview.hidden =
        self.member4.superview.hidden = true;
    }
    else {
        self.campTitleLabel.textColor = [UIColor bonfirePrimaryColor];
        self.campTitleLabel.backgroundColor = [UIColor clearColor];
        self.campTitleLabel.layer.masksToBounds = false;
        self.campTitleLabel.layer.cornerRadius = 0;
        
        self.campDescriptionLabel.backgroundColor = [UIColor clearColor];
        self.campDescriptionLabel.textColor = [UIColor bonfireSecondaryColor];
        self.campDescriptionLabel.layer.masksToBounds = false;
        self.campDescriptionLabel.layer.cornerRadius = 0;
        
        self.followButton.hidden =
        self.detailsCollectionView.hidden =
        self.campDescriptionLabel.hidden = false;
    }

}

- (void)setCamp:(Camp *)camp {
    if (camp != _camp) {
        _camp = camp;
        
        self.tintColor = [UIColor fromHex:camp.attributes.color];
        
        self.campHeaderView.backgroundColor = [UIColor fromHex:camp.attributes.color];
        
        // set profile pictures
        for (NSInteger i = 0; i < 4; i++) {
            BFAvatarView *avatarView;
            if (i == 0) { avatarView = self.member1; }
            else if (i == 1) { avatarView = self.member2; }
            else if (i == 2) { avatarView = self.member3; }
            else { avatarView = self.member4; }
            
            if (camp.attributes.summaries.members.count > i) {
                avatarView.superview.hidden = false;
                
                User *userForImageView = camp.attributes.summaries.members[i];
                
                avatarView.user = userForImageView;
            }
            else {
                avatarView.superview.hidden = true;
            }
        }
        
        self.campTitleLabel.text = camp.attributes.title;
        self.campTagLabel.text = [NSString stringWithFormat:@"#%@", camp.attributes.identifier];
        self.campTagLabel.textColor = [UIColor fromHex:camp.attributes.color];
        self.campDescriptionLabel.text = camp.attributes.theDescription;
        
        self.profilePicture.camp = camp;
        
        [self updateFollowButtonStatus];
        
        [self updateDetailsView];
    }
}

- (void)updateFollowButtonStatus {
    if (self.loading && self.camp.attributes.context == nil) {
        [self.followButton updateStatus:CAMP_STATUS_LOADING];
    }
    else {
        [self.followButton updateStatus:self.camp.attributes.context.camp.status];
    }
}

- (void)leaveCamp {
    [BFAPI unfollowCamp:self.camp completion:^(BOOL success, id responseObject) {
        if (success) {
            if ([responseObject isKindOfClass:[Camp class]]) {
            }
        }
    }];
    
    [self updateCampStatus];
}

@end
