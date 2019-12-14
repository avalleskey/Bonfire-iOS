//
//  CampHeaderCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/1/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "CampHeaderCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIView+WebCache.h>
#import <HapticHelper/HapticHelper.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Session.h"
#import "Defaults.h"
#import "CampViewController.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import "EditCampViewController.h"
#import "BFAlertController.h"
#import "NSDate+NVTimeAgo.h"

#define UIViewParentController(__view) ({ \
        UIResponder *__responder = __view; \
        while ([__responder isKindOfClass:[UIView class]]) \
        __responder = [__responder nextResponder]; \
        (UIViewController *)__responder; \
        })

#define CAMP_CONTEXT_BUBBLE_TAG_ACTIVE 1
#define CAMP_CONTEXT_BUBBLE_TAG_NEW_CAMP 2
#define CAMP_CONTEXT_BUBBLE_TAG_ADMIN 3
#define CAMP_CONTEXT_BUBBLE_TAG_MODERATOR 4

@implementation CampHeaderCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor contentBackgroundColor];
        
        self.contentView.layer.masksToBounds = false;
        self.layer.masksToBounds = false;
        
        self.textLabel.font = CAMP_HEADER_NAME_FONT;
        self.textLabel.textColor = [UIColor bonfirePrimaryColor];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        // username
        //UIFont *heavyItalicFont = [UIFont fontWithDescriptor:[[[UIFont systemFontOfSize:CAMP_HEADER_TAG_FONT.pointSize weight:UIFontWeightHeavy] fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic] size:CAMP_HEADER_TAG_FONT.pointSize];
        self.detailTextLabel.font = [UIFont systemFontOfSize:CAMP_HEADER_TAG_FONT.pointSize weight:UIFontWeightHeavy];
        self.detailTextLabel.textAlignment = NSTextAlignmentCenter;
        self.detailTextLabel.textColor = [UIColor bonfireSecondaryColor];
        self.detailTextLabel.numberOfLines = 0;
        self.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        
        self.descriptionLabel = [[UILabel alloc] init];
        self.descriptionLabel.font = CAMP_HEADER_DESCRIPTION_FONT;
        self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
        self.descriptionLabel.textColor = [UIColor bonfirePrimaryColor];
        self.descriptionLabel.numberOfLines = 0;
        self.descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.contentView addSubview:self.descriptionLabel];
        
        // general cell styling
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        CGFloat profilePicBorderWidth = 6;
        self.avatarContainer = [[UIView alloc] initWithFrame:CGRectMake(0, CAMP_HEADER_EDGE_INSETS.top - profilePicBorderWidth, CAMP_HEADER_AVATAR_SIZE + (profilePicBorderWidth * 2), CAMP_HEADER_AVATAR_SIZE + (profilePicBorderWidth * 2))];
        self.avatarContainer.backgroundColor = [UIColor contentBackgroundColor];
        self.avatarContainer.layer.cornerRadius = self.avatarContainer.frame.size.height / 2;
        self.avatarContainer.layer.masksToBounds = false;
        self.avatarContainer.layer.shadowColor = [UIColor blackColor].CGColor;
        self.avatarContainer.layer.shadowOffset = CGSizeMake(0, 1);
        self.avatarContainer.layer.shadowRadius = 2.f;
        self.avatarContainer.layer.shadowOpacity = 0.12;
        self.avatarContainer.center = CGPointMake(self.contentView.frame.size.width / 2, self.avatarContainer.center.y);
        
        [self.contentView addSubview:self.avatarContainer];
        
        self.campAvatar = [[BFAvatarView alloc] initWithFrame:CGRectMake(profilePicBorderWidth, profilePicBorderWidth, CAMP_HEADER_AVATAR_SIZE, CAMP_HEADER_AVATAR_SIZE)];
        self.campAvatar.dimsViewOnTap = true;
        [self.campAvatar bk_whenTapped:^{
            void(^expandProfilePic)(void) = ^() {
                [Launcher expandImageView:self.campAvatar.imageView];
            };
            
            BOOL hasPicture = (self.campAvatar.camp.attributes.media.avatar.suggested.url.length > 0);
            if ([self.camp.attributes.context.camp.permissions canUpdate]) {
                void(^openEditCamp)(void) = ^() {
                    [self openEditCamp];
                };
                
                if (hasPicture) {
                    // confirm action
                    BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:nil message:nil preferredStyle:BFAlertControllerStyleActionSheet];
                    
                    BFAlertAction *action1 = [BFAlertAction actionWithTitle:@"View Camp Photo" style:BFAlertActionStyleDefault handler:^{
                        expandProfilePic();
                    }];
                    [actionSheet addAction:action1];
                    
                    BFAlertAction *action2 = [BFAlertAction actionWithTitle:@"Edit Camp" style:BFAlertActionStyleDefault handler:^{
                        openEditCamp();
                    }];
                    [actionSheet addAction:action2];
                    
                    BFAlertAction *cancelActionSheet = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
                    [actionSheet addAction:cancelActionSheet];
                    
                    [[Launcher topMostViewController] presentViewController:actionSheet animated:true completion:nil];
                }
                else {
                    openEditCamp();
                }
            }
            else if (hasPicture) {
                expandProfilePic();
            }
        }];
        for (id interaction in self.campAvatar.interactions) {
            if (@available(iOS 13.0, *)) {
                if ([interaction isKindOfClass:[UIContextMenuInteraction class]]) {
                    [self.campAvatar removeInteraction:interaction];
                }
            }
        }
        
        [self.avatarContainer addSubview:self.campAvatar];
        
        self.campAvatarReasonView = [[UIView alloc] initWithFrame:CGRectMake(self.campAvatar.frame.size.width - 40 + 6, self.campAvatar.frame.size.height - 40 + 6, 40, 40)];
        self.campAvatarReasonView.hidden = true;
        self.campAvatarReasonView.backgroundColor = [UIColor bonfireDetailColor];
        self.campAvatarReasonView.layer.cornerRadius = self.campAvatarReasonView.frame.size.height / 2;
        self.campAvatarReasonView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.campAvatarReasonView.layer.shadowOffset = CGSizeMake(0, 1);
        self.campAvatarReasonView.layer.shadowRadius = 2.f;
        self.campAvatarReasonView.layer.shadowOpacity = 0.12;
        [self.campAvatarReasonView bk_whenTapped:^{
            if (self.campAvatarReasonView.tag != 0) {
                NSString *title;
                NSString *message;
                BFAlertAction *cta;
                
                if (self.campAvatarReasonView.tag == CAMP_CONTEXT_BUBBLE_TAG_ACTIVE) {
                    title = @"On Fire";
                    message = @"More than 5 users were active in the last 24hr.";
                }
                else if (self.campAvatarReasonView.tag == CAMP_CONTEXT_BUBBLE_TAG_NEW_CAMP) {
                    title = @"New Camp";
                    message = [NSString stringWithFormat:@"This Camp was created %@.", [NSDate mysqlDatetimeFormattedAsTimeAgo:self.camp.attributes.createdAt withForm:TimeAgoLongForm]];
                    
                    cta = [BFAlertAction actionWithTitle:@"Share Camp via..." style:BFAlertActionStyleDefault handler:^{
                        [Launcher shareCamp:self.camp];
                    }];
                }
                else if (self.campAvatarReasonView.tag == CAMP_CONTEXT_BUBBLE_TAG_MODERATOR) {
                    title = @"Manager";
                    message = @"You can accept new member requests, block members, remove posts, and more.";
                    
                    cta = [BFAlertAction actionWithTitle:@"Manage Members" style:BFAlertActionStyleDefault handler:^{
                        [Launcher openCampMembersForCamp:self.camp];
                    }];
                }
                else if (self.campAvatarReasonView.tag == CAMP_CONTEXT_BUBBLE_TAG_ADMIN) {
                    title = @"Director";
                    message = @"You can customize the Camp settings, accept new member requests, block members, remove posts, and more.";
                    
                    cta = [BFAlertAction actionWithTitle:@"Edit Camp" style:BFAlertActionStyleDefault handler:^{
                        [self openEditCamp];
                    }];
                }
                
                if (!title && !message && !cta) return;
                
                BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:title message:message preferredStyle:BFAlertControllerStyleActionSheet];
                
                if (cta) {
                    [actionSheet addAction:cta];
                }
                
                BFAlertAction *cancelActionSheet = [BFAlertAction actionWithTitle:@"Close" style:BFAlertActionStyleCancel handler:nil];
                [actionSheet addAction:cancelActionSheet];
                
                [[Launcher topMostViewController] presentViewController:actionSheet animated:true completion:nil];
            }
        }];
        [self.contentView addSubview:self.campAvatarReasonView];
        
        self.campAvatarReasonLabel = [[UILabel alloc] initWithFrame:self.campAvatarReasonView.bounds];
        self.campAvatarReasonLabel.textAlignment = NSTextAlignmentCenter;
        self.campAvatarReasonLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightSemibold];
        self.campAvatarReasonLabel.text = @"🔥";
        [self.campAvatarReasonView addSubview:self.campAvatarReasonLabel];
        
        self.campAvatarReasonImageView = [[UIImageView alloc] initWithFrame:self.campAvatarReasonView.bounds];
        self.campAvatarReasonImageView.contentMode = UIViewContentModeCenter;
        self.campAvatarReasonImageView.hidden = true;
        [self.campAvatarReasonView addSubview:self.campAvatarReasonImageView];
        
        self.member2 = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, 46, 46)];
        self.member2.tag = 0;
        self.member3 = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, 46, 46)];
        self.member3.tag = 1;
        
        self.member4 = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        self.member4.tag = 2;
        self.member5 = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        self.member5.tag = 3;
        
        self.member6 = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        self.member6.tag = 4;
        self.member7 = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        self.member7.tag = 5;
        
        [self styleMemberProfilePictureView:self.member2];
        [self styleMemberProfilePictureView:self.member3];
        [self styleMemberProfilePictureView:self.member4];
        [self styleMemberProfilePictureView:self.member5];
        [self styleMemberProfilePictureView:self.member6];
        [self styleMemberProfilePictureView:self.member7];
        
        [self addTapHandlers:@[self.member2, self.member2, self.member3, self.member4, self.member5, self.member6, self.member7]];
        
        self.detailsCollectionView = [[BFDetailsCollectionView alloc] initWithFrame:CGRectMake(CAMP_HEADER_EDGE_INSETS.left, 0, [UIScreen mainScreen].bounds.size.width - CAMP_HEADER_EDGE_INSETS.left - CAMP_HEADER_EDGE_INSETS.right, 16)];
        [self.contentView addSubview:self.detailsCollectionView];
        
        self.followButton = [CampFollowButton buttonWithType:UIButtonTypeCustom];
        
        [self.followButton bk_whenTapped:^{
            // update state if possible
            if ([self.followButton.status isEqualToString:CAMP_STATUS_CAN_EDIT]) {
                [self openEditCamp];
            }
            else if ([self.followButton.status isEqualToString:CAMP_STATUS_MEMBER] ||
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
                        
                        BFAlertController *confirmDeletePostActionSheet = [BFAlertController alertControllerWithTitle:([self.camp isChannel] ? @"Unsubscribe?" : @"Leave Camp?") message:message preferredStyle:BFAlertControllerStyleAlert];
                        
                        BFAlertAction *confirmLeaveCamp = [BFAlertAction actionWithTitle:([self.camp isChannel] ? @"Unsubscribe" : @"Leave") style:BFAlertActionStyleDestructive handler:^{
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
            else if ([self.followButton.status isEqualToString:CAMP_STATUS_LEFT] ||
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
        
        self.lineSeparator = [[UIView alloc] init];
        self.lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        [self.contentView addSubview:self.lineSeparator];
        
        #ifdef DEBUG
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            if (state == UIGestureRecognizerStateBegan) {
                // recognized long press
                [Launcher openDebugView:self.camp];
            }
        }];
        [self addGestureRecognizer:longPress];
        #endif
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

- (void)openEditCamp {
    EditCampViewController *epvc = [[EditCampViewController alloc] init];
    epvc.themeColor = [UIColor fromHex:self.camp.attributes.color];
    epvc.view.tintColor = epvc.themeColor;
    epvc.camp = self.camp;
    
    SimpleNavigationController *newNavController = [[SimpleNavigationController alloc] initWithRootViewController:epvc];
    newNavController.transitioningDelegate = [Launcher sharedInstance];
    newNavController.modalPresentationStyle = UIModalPresentationFullScreen;
    newNavController.opaqueOnScroll = false;
    newNavController.shadowOnScroll = true;
    newNavController.transparentOnLoad = true;
    
    [Launcher present:newNavController animated:YES];
}

- (void)addTapHandlers:(NSArray *)views {
    for (UIImageView *view in views) {
        view.userInteractionEnabled = true;
        [view bk_whenTapped:^{
            if (self.camp.attributes.summaries.members.count > view.tag) {
                // open member
                User *userForImageView = self.camp.attributes.summaries.members[view.tag];
                [Launcher openProfile:userForImageView];
            }
            else {
                // open invite friends
                [Launcher openInviteFriends:self.camp];
            }
        }];
    }
}

- (void)updateCampStatus {
    BFContext *context = [[BFContext alloc] initWithDictionary:[self.camp.attributes.context toDictionary] error:nil];
    BFContextCamp *camp = [[BFContextCamp alloc] initWithDictionary:[context.camp toDictionary] error:nil];
    camp.status = self.followButton.status;
    context.camp = camp;
    self.camp.attributes.context = context;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CampUpdated" object:self.camp];
}
//- (void)incrementMembersCount {
//    CampCounts *counts = [[CampCounts alloc] initWithDictionary:[self.camp.attributes.summaries.counts toDictionary] error:nil];
//    counts.members = counts.members + 1;
//    self.camp.attributes.summaries.counts = counts;
//
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"CampUpdated" object:self.camp];
//}
//- (void)decrementMembersCount {
//    // only decrement if they were a member before! requests don't count.
//    CampCounts *counts = [[CampCounts alloc] initWithDictionary:[self.camp.attributes.summaries.counts toDictionary] error:nil];
//    counts.members = counts.members > 0 ? counts.members - 1 : 0;
//    self.camp.attributes.summaries.counts = counts;
//
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"CampUpdated" object:self.camp];
//}
- (void)leaveCamp {
    [BFAPI unfollowCamp:self.camp completion:^(BOOL success, id responseObject) {
        if (success) {
            if ([responseObject isKindOfClass:[Camp class]]) {
            }
        }
    }];
    
    [self updateCampStatus];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat bottomY;
    
    CGFloat maxWidth = self.frame.size.width - (CAMP_HEADER_EDGE_INSETS.left + CAMP_HEADER_EDGE_INSETS.right);
    
    // line separator
    self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - 1 / [UIScreen mainScreen].scale, self.frame.size.width, 1 / [UIScreen mainScreen].scale);
    
    self.contentView.frame = self.bounds;
    
    // profile pic collage
    self.avatarContainer.center = CGPointMake(self.contentView.frame.size.width / 2, self.avatarContainer.center.y);
    bottomY = CAMP_HEADER_EDGE_INSETS.top + self.campAvatar.frame.size.height;
    
    if (![self.campAvatarReasonView isHidden]) {
        self.campAvatarReasonView.frame = CGRectMake(self.avatarContainer.frame.origin.x + self.avatarContainer.frame.size.width - 40 - 6, self.avatarContainer.frame.origin.y + self.avatarContainer.frame.size.height - 40 - 6, 40, 40);
        
        if (self.campAvatarReasonView.alpha == 0) {
            self.campAvatarReasonView.transform = CGAffineTransformMakeScale(0.8, 0.8);
            [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.campAvatarReasonView.alpha = 1;
                self.campAvatarReasonView.transform = CGAffineTransformIdentity;
            } completion:nil];
        }
    }
    
    self.member2.superview.frame = CGRectMake(self.avatarContainer.frame.origin.x - self.member2.superview.frame.size.width - 26, CAMP_HEADER_EDGE_INSETS.top + 62, self.member2.superview.frame.size.width, self.member2.superview.frame.size.height);
    self.member3.superview.frame = CGRectMake(self.frame.size.width - self.member2.superview.frame.origin.x - self.member3.superview.frame.size.width, CAMP_HEADER_EDGE_INSETS.top + 12, self.member3.superview.frame.size.width, self.member3.superview.frame.size.height);
    
    self.member4.superview.frame = CGRectMake(self.member2.superview.frame.origin.x - self.member4.superview.frame.size.width + 8, CAMP_HEADER_EDGE_INSETS.top + 12, self.member4.superview.frame.size.width, self.member4.superview.frame.size.height);
    self.member5.superview.frame = CGRectMake(self.frame.size.width - self.member4.superview.frame.origin.x - self.member5.superview.frame.size.width, CAMP_HEADER_EDGE_INSETS.top + 72, self.member5.superview.frame.size.width, self.member5.superview.frame.size.height);
    
    self.member6.superview.frame = CGRectMake(self.member4.superview.frame.origin.x - self.member6.superview.frame.size.width + 4, CAMP_HEADER_EDGE_INSETS.top + 64, self.member6.superview.frame.size.width, self.member6.superview.frame.size.height);
    self.member7.superview.frame = CGRectMake(self.frame.size.width - self.member6.superview.frame.origin.x - self.member7.superview.frame.size.width, CAMP_HEADER_EDGE_INSETS.top + 32, self.member7.superview.frame.size.width, self.member7.superview.frame.size.height);
    
    // text label
    CGRect nameLabelRect = [self.textLabel.text boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.textLabel.font} context:nil];
    self.textLabel.frame = CGRectMake(CAMP_HEADER_EDGE_INSETS.left, bottomY + CAMP_HEADER_AVATAR_BOTTOM_PADDING, maxWidth, ceilf(nameLabelRect.size.height));
    bottomY = self.textLabel.frame.origin.y + self.textLabel.frame.size.height + CAMP_HEADER_NAME_BOTTOM_PADDING;

    // detail text label
    if (![self.detailTextLabel isHidden]) {
        CGRect detailLabelRect = [self.detailTextLabel.text boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.detailTextLabel.font} context:nil];
        self.detailTextLabel.frame = CGRectMake(self.textLabel.frame.origin.x, bottomY, self.textLabel.frame.size.width, ceilf(detailLabelRect.size.height));
        bottomY = self.detailTextLabel.frame.origin.y + self.detailTextLabel.frame.size.height + CAMP_HEADER_TAG_BOTTOM_PADDING;
    }
    
    if (self.descriptionLabel.text.length > 0) {
        // detail text label
        CGRect detailLabelRect = [self.descriptionLabel.attributedText boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
        self.descriptionLabel.frame = CGRectMake(CAMP_HEADER_EDGE_INSETS.left, bottomY, maxWidth, ceilf(detailLabelRect.size.height));
        bottomY = self.descriptionLabel.frame.origin.y + self.descriptionLabel.frame.size.height + CAMP_HEADER_DESCRIPTION_BOTTOM_PADDING;
    }
    
    if (![self.detailsCollectionView isHidden]) {
        self.detailsCollectionView.frame = CGRectMake(CAMP_HEADER_EDGE_INSETS.left, bottomY, self.frame.size.width - (CAMP_HEADER_DETAILS_EDGE_INSETS.left + CAMP_HEADER_DETAILS_EDGE_INSETS.right), self.detailsCollectionView.contentSize.height);
        bottomY = self.detailsCollectionView.frame.origin.y + self.detailsCollectionView.frame.size.height;
    }
    
    self.followButton.frame = CGRectMake(12, bottomY + CAMP_HEADER_FOLLOW_BUTTON_TOP_PADDING, self.frame.size.width - 24, 38);
}

- (void)styleMemberProfilePictureView:(BFAvatarView *)imageView  {
    imageView.layer.cornerRadius = imageView.frame.size.height / 2;
    imageView.layer.masksToBounds = true;
    imageView.tintColor = [UIColor bonfireSecondaryColor];
    imageView.placeholderAvatar = true;
    
    CGFloat borderWidth = 4.f;
    UIView *borderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, imageView.frame.size.width + (borderWidth * 2), imageView.frame.size.height + (borderWidth * 2))];
    borderView.backgroundColor = [UIColor bonfireDetailColor];
    borderView.layer.cornerRadius = borderView.frame.size.height / 2;
    borderView.layer.masksToBounds = false;
    borderView.layer.shadowColor = [UIColor blackColor].CGColor;
    borderView.layer.shadowOffset = CGSizeMake(0, HALF_PIXEL);
    borderView.layer.shadowRadius = 1.f;
    borderView.layer.shadowOpacity = 0.12;
    imageView.frame = CGRectMake(borderWidth, borderWidth, imageView.frame.size.width, imageView.frame.size.height);
    [borderView addSubview:imageView];
    
    [self.contentView addSubview:borderView];
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

- (void)setCamp:(Camp *)camp {
    if (camp != _camp) {
        _camp = camp;
        
        self.tintColor = self.superview.tintColor;
                
        // camp title
        NSString *campTitle;
        if (camp.attributes.title.length > 0) {
            campTitle = camp.attributes.title;
        }
        else if (camp.attributes.identifier.length > 0) {
            campTitle = [NSString stringWithFormat:@"@%@", camp.attributes.identifier];
        }
        else {
            campTitle = @"Secret Camp";
        }
        NSMutableAttributedString *displayNameAttributedString = [[NSMutableAttributedString alloc] initWithString:campTitle attributes:@{NSFontAttributeName:CAMP_HEADER_NAME_FONT}];
        if ([camp isVerified]) {
            NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
            [spacer addAttribute:NSFontAttributeName value:CAMP_HEADER_NAME_FONT range:NSMakeRange(0, spacer.length)];
            [displayNameAttributedString appendAttributedString:spacer];
            
            // verified icon ☑️
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.image = [UIImage imageNamed:@"verifiedIcon_large"];
            [attachment setBounds:CGRectMake(0, roundf(CAMP_HEADER_NAME_FONT.capHeight - attachment.image.size.height)/2.f-1, attachment.image.size.width, attachment.image.size.height)];
            
            NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
            [displayNameAttributedString appendAttributedString:attachmentString];
        }
        self.textLabel.attributedText = displayNameAttributedString;
        
        self.detailTextLabel.hidden = camp.attributes.identifier.length == 0;
        if (![self.detailTextLabel isHidden]) {
            self.detailTextLabel.text = [NSString stringWithFormat:@"#%@", camp.attributes.identifier];
            self.detailTextLabel.textColor = [UIColor fromHex:camp.attributes.color adjustForOptimalContrast:true];
        }
                
        if (camp.attributes.theDescription.length > 0) {
            NSMutableAttributedString *attrString = [[NSMutableAttributedString  alloc] initWithString:camp.attributes.theDescription];
            NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
            [style setLineSpacing:3.f];
            [style setAlignment:NSTextAlignmentCenter];
            [attrString addAttribute:NSParagraphStyleAttributeName
                               value:style
                               range:NSMakeRange(0, attrString.length)];
            [attrString addAttribute:NSFontAttributeName value:CAMP_HEADER_DESCRIPTION_FONT range:NSMakeRange(0, attrString.length)];
            [attrString addAttribute:NSForegroundColorAttributeName value:self.descriptionLabel.textColor range:NSMakeRange(0, attrString.length)];
            self.descriptionLabel.attributedText = attrString;
        }
        else {
            self.descriptionLabel.text = @"";
        }
        
        // set camp picture
        self.campAvatar.camp = camp;
        
        // set camp indicator
        BOOL showIndicator = false;
        if (camp.attributes.summaries.counts.live > 5) {
            showIndicator = true;
            self.campAvatarReasonLabel.text = @"🔥";
            self.campAvatarReasonView.tag = CAMP_CONTEXT_BUBBLE_TAG_ACTIVE;
        }
        if (!showIndicator && camp.attributes.createdAt.length > 0) {
            NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
                [inputFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
            NSDate *date = [inputFormatter dateFromString:camp.attributes.createdAt];
            
            NSUInteger unitFlags = NSCalendarUnitDay;
            NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSDateComponents *components = [calendar components:unitFlags fromDate:date toDate:[NSDate new] options:0];
            
            if ([components day] < 7) {
                showIndicator = true;
                self.campAvatarReasonLabel.text = @"🆕";
                self.campAvatarReasonView.tag = CAMP_CONTEXT_BUBBLE_TAG_NEW_CAMP;
            }
        }
        if (!showIndicator && [camp.attributes.context.camp.membership.role.type isEqualToString:CAMP_ROLE_ADMIN]) {
            showIndicator = true;
            self.campAvatarReasonLabel.text = @"🤠";
            self.campAvatarReasonView.tag = CAMP_CONTEXT_BUBBLE_TAG_ADMIN;
        }
        if (!showIndicator && [camp.attributes.context.camp.membership.role.type isEqualToString:CAMP_ROLE_MODERATOR]) {
            showIndicator = true;
            self.campAvatarReasonLabel.text = @"🛡";
            self.campAvatarReasonView.tag = CAMP_CONTEXT_BUBBLE_TAG_MODERATOR;
        }
        if ([self.campAvatarReasonView isHidden] && showIndicator) {
            self.campAvatarReasonView.alpha = 0;
        }
        self.campAvatarReasonView.hidden = !showIndicator;
        self.campAvatarReasonImageView.hidden = showIndicator;
        self.campAvatarReasonLabel.hidden = !showIndicator;
        
        // set profile pictures
        for (NSInteger i = 0; i < 6; i++) {
            BFAvatarView *avatarView;
            if (i == 0) { avatarView = self.member2; }
            else if (i == 1) { avatarView = self.member3; }
            else if (i == 2) { avatarView = self.member4; }
            else if (i == 3) { avatarView = self.member5; }
            else if (i == 4) { avatarView = self.member6; }
            else { avatarView = self.member7; }
            
            avatarView.hidden = !self.camp.identifier;
            avatarView.superview.hidden = [self.camp isChannel];
            
            if (camp.attributes.summaries.members.count > i) {
                User *userForImageView = camp.attributes.summaries.members[i];
                
                avatarView.user = userForImageView;
                avatarView.dimsViewOnTap = true;
                avatarView.superview.alpha = 1;
            }
            else {
                avatarView.placeholderAvatar = true;
                avatarView.dimsViewOnTap = false;
                avatarView.backgroundColor = [UIColor clearColor];
                avatarView.tintColor = [UIColor fromHex:[UIColor toHex:self.tintColor] adjustForOptimalContrast:true];
            }
        }
        
        NSMutableArray *details = [[NSMutableArray alloc] init];
        if (self.camp.attributes.identifier.length > 0 || self.camp.identifier.length > 0) {
            // camp type (& visibility)
            if ([self.camp isChannel] && (self.camp.attributes.display.sourceLink || self.camp.attributes.display.sourceUser)) {
                if (self.camp.attributes.display.sourceLink) {
                    BFDetailItem *sourceLink = [[BFDetailItem alloc] initWithType:BFDetailItemTypeSourceLink value:[NSString stringWithFormat:@"%@", self.camp.attributes.display.sourceLink.attributes.canonicalUrl] action:^{
                        [Launcher openURL:self.camp.attributes.display.sourceLink.attributes.actionUrl];
                    }];
                    sourceLink.selectable = true;
                    [details addObject:sourceLink];
                }
                else if (self.camp.attributes.display.sourceUser) {
                    BFDetailItem *sourceUser = [[BFDetailItem alloc] initWithType:BFDetailItemTypeSourceUser value:[NSString stringWithFormat:@"%@", self.camp.attributes.display.sourceUser.attributes.identifier] action:^{
                        [Launcher openProfile:self.camp.attributes.display.sourceUser];
                    }];
                    sourceUser.selectable = true;
                    [details addObject:sourceUser];
                }
            }
            else {
                BFDetailItem *visibility = [[BFDetailItem alloc] initWithType:([self.camp isPrivate] ? BFDetailItemTypePrivacyPrivate : BFDetailItemTypePrivacyPublic) value:([self.camp isPrivate] ? @"Private" : @"Public") action:nil];
                [details addObject:visibility];
            }
            
            // member / subscriber count
            if (self.camp.attributes.summaries.counts != nil) {
                if ([self.camp isChannel]) {
                    BFDetailItem *subscribers = [[BFDetailItem alloc] initWithType:BFDetailItemTypeSubscribers value:[NSString stringWithFormat:@"%ld", (long)self.camp.attributes.summaries.counts.members] action:nil];
                    subscribers.selectable = false;
                    [details addObject:subscribers];
                }
                else {
                    BFDetailItem *members = [[BFDetailItem alloc] initWithType:BFDetailItemTypeMembers value:[NSString stringWithFormat:@"%ld", (long)self.camp.attributes.summaries.counts.members] action:^{
                        [Launcher openCampMembersForCamp:self.camp];
                    }];
                    if ([self.camp isPrivate] && ![self.camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_MEMBER]) {
                        members.selectable = false;
                    }
                    [details addObject:members];
                }
            }
            
            if ([self.camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_MEMBER] && self.camp.attributes.context.camp.membership) {
                BOOL subscribed = self.camp.attributes.context.camp.membership.subscription != nil;
                BFDetailItem *subscription = [[BFDetailItem alloc] initWithType:(subscribed ? BFDetailItemTypePostNotificationsOn : BFDetailItemTypePostNotificationsOff) value:@"" action:^{
                    [self openPostNotificationSettings];
                }];
                [details addObject:subscription];
            }
        }
        
        self.detailsCollectionView.hidden = (details.count == 0);
        self.detailsCollectionView.tintColor = [UIColor fromHex:self.camp.attributes.color adjustForOptimalContrast:true];
        
        if (![self.detailsCollectionView isHidden]) {
            self.detailsCollectionView.details = [details copy];
        }
        
        if ([camp isChannel]) {
            self.followButton.followString = @"Subscribe";
            self.followButton.followingString = @"Subscribed";
        }
        else {
            self.followButton.followString = [NSString stringWithFormat:@"Join %@", @"Camp"];
            self.followButton.followingString = @"Joined";
        }
    }
}

- (void)openPostNotificationSettings {
    BOOL campPostNotifications = self.camp.attributes.context.camp.membership.subscription != nil;
    UIImage *icon = (campPostNotifications ? [UIImage imageNamed:@"alert_icon_notifications_on"] : [UIImage imageNamed:@"alert_icon_notifications_off"]);
    
    BFAlertController *postNotifications = [BFAlertController alertControllerWithIcon:icon title:(campPostNotifications?@"Instant Updates are on":@"Muted") message:(campPostNotifications ? @"You will receive notifications for new posts inside this Camp" : @"You will only receive notifications when you are mentioned or replied to") preferredStyle:BFAlertControllerStyleActionSheet];
    
    NSString *actionTitle;
    if (campPostNotifications) {
        actionTitle = @"Mute";
    }
    else {
        actionTitle = @"Turn Instant Updates On";
    }
    BFAlertAction *togglePostNotifications = [BFAlertAction actionWithTitle:actionTitle style:(campPostNotifications?BFAlertActionStyleDestructive:BFAlertActionStyleDefault) handler:^{
        NSLog(@"toggle post notifications");
        // confirm action
        Camp *campCopy = [self.camp copy];
        if (campPostNotifications) {
            [campCopy unsubscribeFromCamp];
        }
        else {
            [campCopy subscribeToCamp];
        }
    }];
    [postNotifications addAction:togglePostNotifications];
    
    // confirm action
    BFAlertAction *alertCancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
    [postNotifications addAction:alertCancel];
    
    [[Launcher topMostViewController] presentViewController:postNotifications animated:true completion:nil];
}

+ (CGFloat)heightForCamp:(Camp *)camp isLoading:(BOOL)loading {
    CGFloat maxWidth = [UIScreen mainScreen].bounds.size.width - (CAMP_HEADER_EDGE_INSETS.left + CAMP_HEADER_EDGE_INSETS.right);

    // knock out all the required bits first
    CGFloat height = CAMP_HEADER_EDGE_INSETS.top + CAMP_HEADER_AVATAR_SIZE + CAMP_HEADER_AVATAR_BOTTOM_PADDING;

    // camp title
    NSString *campTitle;
    if (camp.attributes.title.length > 0) {
        campTitle = camp.attributes.title;
    }
    else if (camp.attributes.identifier.length > 0) {
        campTitle = [NSString stringWithFormat:@"@%@", camp.attributes.identifier];
    }
    else {
        campTitle = @"Secret Camp";
    }
    NSMutableAttributedString *displayNameAttributedString = [[NSMutableAttributedString alloc] initWithString:campTitle attributes:@{NSFontAttributeName:CAMP_HEADER_NAME_FONT}];
    if ([camp isVerified]) {
        NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
        [spacer addAttribute:NSFontAttributeName value:CAMP_HEADER_NAME_FONT range:NSMakeRange(0, spacer.length)];
        [displayNameAttributedString appendAttributedString:spacer];
        
        // verified icon ☑️
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = [UIImage imageNamed:@"verifiedIcon_large"];
        [attachment setBounds:CGRectMake(0, roundf(CAMP_HEADER_NAME_FONT.capHeight - attachment.image.size.height)/2.f-1, attachment.image.size.width, attachment.image.size.height)];
        
        NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
        [displayNameAttributedString appendAttributedString:attachmentString];
    }
    
    CGRect textLabelRect = [displayNameAttributedString boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
    CGFloat campTitleHeight = ceilf(textLabelRect.size.height);
    height += campTitleHeight + CAMP_HEADER_NAME_BOTTOM_PADDING;

    if (camp.attributes.identifier.length > 0) {
        CGRect campTagRect = [[NSString stringWithFormat:@"#%@", camp.attributes.identifier] boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:CAMP_HEADER_TAG_FONT} context:nil];
        CGFloat campTagHeight = ceilf(campTagRect.size.height);
        height += campTagHeight;
    }

    if (camp.attributes.theDescription.length > 0) {
        NSMutableAttributedString *attrString = [[NSMutableAttributedString  alloc] initWithString:camp.attributes.theDescription];
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:3.f];
        [style setAlignment:NSTextAlignmentCenter];
        [attrString addAttribute:NSParagraphStyleAttributeName
                           value:style
                           range:NSMakeRange(0, attrString.length)];
        [attrString addAttribute:NSFontAttributeName value:CAMP_HEADER_DESCRIPTION_FONT range:NSMakeRange(0, attrString.length)];
        
        CGRect descriptionRect = [attrString boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)  context:nil];
        CGFloat campDescriptionHeight = ceilf(descriptionRect.size.height);
        height += campDescriptionHeight + (camp.attributes.identifier.length > 0 ? CAMP_HEADER_TAG_BOTTOM_PADDING : 0);
    }

    if (camp.attributes.identifier.length > 0 || camp.identifier.length > 0) {
        CGFloat detailsHeight = 0;
        NSMutableArray *details = [[NSMutableArray alloc] init];
        
        // camp type (& visibility)
        if ([camp isChannel] && (camp.attributes.display.sourceLink || camp.attributes.display.sourceUser)) {
            if (camp.attributes.display.sourceLink) {
                BFDetailItem *sourceLink = [[BFDetailItem alloc] initWithType:BFDetailItemTypeSourceLink value:[NSString stringWithFormat:@"%@", camp.attributes.display.sourceLink.attributes.canonicalUrl] action:nil];
                [details addObject:sourceLink];
            }
            else if (camp.attributes.display.sourceUser) {
                BFDetailItem *sourceUser = [[BFDetailItem alloc] initWithType:BFDetailItemTypeSourceUser value:[NSString stringWithFormat:@"%@", camp.attributes.display.sourceUser.attributes.identifier] action:nil];
                [details addObject:sourceUser];
            }
        }
        else {
            BFDetailItem *visibility = [[BFDetailItem alloc] initWithType:([camp isPrivate] ? BFDetailItemTypePrivacyPrivate : BFDetailItemTypePrivacyPublic) value:(camp ? @"Private" : @"Public") action:nil];
            [details addObject:visibility];
        }
        
        // member / subscriber count
        if (camp.attributes.summaries.counts != nil) {
            if ([camp.attributes.display.format isEqualToString:CAMP_DISPLAY_FORMAT_CHANNEL]) {
                BFDetailItem *subscribers = [[BFDetailItem alloc] initWithType:BFDetailItemTypeSubscribers value:[NSString stringWithFormat:@"%ld", (long)camp.attributes.summaries.counts.members] action:nil];
                [details addObject:subscribers];
            }
            else {
                BFDetailItem *members = [[BFDetailItem alloc] initWithType:BFDetailItemTypeMembers value:[NSString stringWithFormat:@"%ld", (long)camp.attributes.summaries.counts.members] action:nil];
                [details addObject:members];
            }
        }
        
        if ([camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_MEMBER] && camp.attributes.context.camp.membership) {
            BOOL subscribed = camp.attributes.context.camp.membership.subscription != nil;
            BFDetailItem *subscription = [[BFDetailItem alloc] initWithType:(subscribed ? BFDetailItemTypePostNotificationsOn : BFDetailItemTypePostNotificationsOff) value:@"" action:^{
                
            }];
            [details addObject:subscription];
        }
         
        if (details.count > 0) {
            BFDetailsCollectionView *detailCollectionView = [[BFDetailsCollectionView alloc] initWithFrame:CGRectMake(CAMP_HEADER_EDGE_INSETS.left, 0, [UIScreen mainScreen].bounds.size.width - CAMP_HEADER_EDGE_INSETS.left - CAMP_HEADER_EDGE_INSETS.right, 16)];
            detailCollectionView.delegate = detailCollectionView;
            detailCollectionView.dataSource = detailCollectionView;
            [detailCollectionView setDetails:details];
            
            detailsHeight = detailCollectionView.collectionViewLayout.collectionViewContentSize.height;
            
            // add padding above
            if (camp.attributes.theDescription.length > 0) {
                height += CAMP_HEADER_DESCRIPTION_BOTTOM_PADDING;
            }
            else if (camp.attributes.identifier.length > 0) {
                height += CAMP_HEADER_TAG_BOTTOM_PADDING;
            }
            
            height += detailsHeight;
        }
    }

    if (camp.attributes.context != nil || loading) {
        CGFloat userPrimaryActionHeight = CAMP_HEADER_FOLLOW_BUTTON_TOP_PADDING + 38;
        height = height + userPrimaryActionHeight;
    }

    // add bottom padding and line separator
    height += CAMP_HEADER_EDGE_INSETS.bottom;

    return height;
}

@end
