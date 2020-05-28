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
#import "BFAlertController.h"
#import "NSDate+NVTimeAgo.h"
#import "AddManagerTableViewController.h"
#import "BFMiniNotificationManager.h"

#define CAMP_CONTEXT_BUBBLE_TAG_ACTIVE 1
#define CAMP_CONTEXT_BUBBLE_TAG_NEW_CAMP 2
#define CAMP_CONTEXT_BUBBLE_TAG_LIVE_MODE_CHAT 3
#define CAMP_CONTEXT_BUBBLE_TAG_LIVE_MODE_AUDIO 4
#define CAMP_CONTEXT_BUBBLE_TAG_LIVE_MODE_VIDEO 5
#define CAMP_CONTEXT_BUBBLE_TAG_LIVE_MODE_STORY 6

#define testingGroundsCampId @"-ZL8PgwP2aGl9"

@implementation CampHeaderCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor contentBackgroundColor];
        
        self.clipsToBounds = NO;                        //cell's view
        self.contentView.clipsToBounds = NO;            //contentView
        self.contentView.superview.clipsToBounds = NO;  //scrollView
        
        self.avatarContainer = [[UIView alloc] initWithFrame:CGRectMake(0, CAMP_HEADER_EDGE_INSETS.top - CAMP_HEADER_AVATAR_BORDER_WIDTH, CAMP_HEADER_AVATAR_SIZE + (CAMP_HEADER_AVATAR_BORDER_WIDTH * 2), CAMP_HEADER_AVATAR_SIZE + (CAMP_HEADER_AVATAR_BORDER_WIDTH * 2))];
        self.avatarContainer.backgroundColor = [UIColor contentBackgroundColor];
        self.avatarContainer.layer.cornerRadius = self.avatarContainer.frame.size.height / 2;
        self.avatarContainer.layer.masksToBounds = false;
        self.avatarContainer.layer.shadowColor = [UIColor blackColor].CGColor;
        self.avatarContainer.layer.shadowOffset = CGSizeMake(0, 1);
        self.avatarContainer.layer.shadowRadius = 2.f;
        self.avatarContainer.layer.shadowOpacity = 0.12;
        self.avatarContainer.center = CGPointMake(self.contentView.frame.size.width / 2, self.avatarContainer.center.y);
        [self addSubview:self.avatarContainer];
        
        self.campAvatar = [[BFAvatarView alloc] initWithFrame:CGRectMake(CAMP_HEADER_AVATAR_BORDER_WIDTH, CAMP_HEADER_AVATAR_BORDER_WIDTH, CAMP_HEADER_AVATAR_SIZE, CAMP_HEADER_AVATAR_SIZE)];
        self.campAvatar.dimsViewOnTap = true;
        [self.campAvatar bk_whenTapped:^{
            if (self.liveMode == BFCampHeaderLiveModeStory ||
                self.liveMode == BFCampHeaderLiveModeVideo) {
                BFVideoPlayerViewController *videoVC = [Launcher openVideoViewer:self.campAvatar delegate:nil];
                videoVC.videoURL = @"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4";
                if (self.liveMode == BFCampHeaderLiveModeStory) {
                    videoVC.format = BFVideoPlayerFormatStory;
                }
                else {
                    videoVC.format = BFVideoPlayerFormatVideo;
                }
            }
            else if (self.liveMode == BFCampHeaderLiveModeAudio) {
                [Launcher openLiveAudioCamp:self.camp sender:self.campAvatar delegate:nil];
            }
            else if (self.liveMode == BFCampHeaderLiveModeChat) {
                
            }
            else {
                void(^expandProfilePic)(void) = ^() {
                    [Launcher expandImageView:self.campAvatar.imageView];
                };
                
                BOOL hasPicture = (self.campAvatar.camp.attributes.media.avatar.suggested.url.length > 0);
                if ([self.camp.attributes.context.camp.permissions canUpdate]) {
                    void(^openEditCamp)(void) = ^() {
                        [Launcher openEditCamp:self.camp];
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
                        
                        [actionSheet show];
                    }
                    else {
                        openEditCamp();
                    }
                }
                else if (hasPicture) {
                    expandProfilePic();
                }
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
        self.campAvatarReasonView.alpha = 0;
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
                    if (self.camp.attributes.summaries.counts.scoreIndex >= .66) {
                        title = @"On Fire";
                        message = @"Join conversations in this Camp to keep the fire alive!";
                    }
                    else if (self.camp.attributes.summaries.counts.scoreIndex >= .33) {
                        title = @"Hot";
                        message = @"Join conversations in this Camp to help it become more popular!";
                    }
                    else {
                        title = @"Warming Up";
                        message = @"New posts and sparks will\nmake this Camp more popular";
                        cta = [BFAlertAction actionWithTitle:@"Create a Post" style:BFAlertActionStyleDefault handler:^{
                            [Launcher openComposePost:self.camp inReplyTo:nil withMessage:nil media:nil quotedObject:nil];
                        }];
                    }
                }
                else if (self.campAvatarReasonView.tag == CAMP_CONTEXT_BUBBLE_TAG_NEW_CAMP) {
                    title = @"New Camp";
                    message = [NSString stringWithFormat:@"This Camp was created %@.", [NSDate mysqlDatetimeFormattedAsTimeAgo:self.camp.attributes.createdAt withForm:TimeAgoLongForm]];
                    
                    cta = [BFAlertAction actionWithTitle:@"Share Camp via..." style:BFAlertActionStyleDefault handler:^{
                        [Launcher shareCamp:self.camp];
                    }];
                }
                else if (self.campAvatarReasonView.tag > CAMP_CONTEXT_BUBBLE_TAG_NEW_CAMP && self.campAvatarReasonView.tag <=BFCampHeaderLiveModeStory) {
                    
                }
                
                if (!title && !message && !cta) return;
                
                BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:title message:message preferredStyle:BFAlertControllerStyleActionSheet];
                
                if (cta) {
                    [actionSheet addAction:cta];
                }
                
                BFAlertAction *cancelActionSheet = [BFAlertAction actionWithTitle:@"Close" style:BFAlertActionStyleCancel handler:nil];
                [actionSheet addAction:cancelActionSheet];
                
                [actionSheet show];
            }
        }];
        [self addSubview:self.campAvatarReasonView];
        
        self.campAvatarReasonLabel = [[UILabel alloc] initWithFrame:self.campAvatarReasonView.bounds];
        self.campAvatarReasonLabel.textAlignment = NSTextAlignmentCenter;
        self.campAvatarReasonLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightSemibold];
        self.campAvatarReasonLabel.text = @"🔥";
        [self.campAvatarReasonView addSubview:self.campAvatarReasonLabel];
        
        self.campAvatarReasonImageView = [[UIImageView alloc] initWithFrame:self.campAvatarReasonView.bounds];
        self.campAvatarReasonImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.campAvatarReasonImageView.hidden = true;
        self.campAvatarReasonImageView.layer.cornerRadius = self.campAvatarReasonView.layer.cornerRadius;
        self.campAvatarReasonImageView.layer.masksToBounds = true;
        [self.campAvatarReasonView addSubview:self.campAvatarReasonImageView];
        
        self.gradientRingLayer = [CAGradientLayer layer];
        self.gradientRingLayer.frame = CGRectMake(7, 7, CAMP_HEADER_AVATAR_SIZE + 7 * 2, CAMP_HEADER_AVATAR_SIZE + 7 * 2);
        self.gradientRingLayer.cornerRadius = self.gradientRingLayer.frame.size.height / 2;
        
        CGRect outerRect = CGRectMake(0, 0, self.gradientRingLayer.frame.size.width, self.gradientRingLayer.frame.size.height);
        CGFloat inset = 3; // adjust as necessary for more or less meaty donuts
        CGFloat innerDiameter = outerRect.size.width - 2.0 * inset;
        CGRect innerRect = CGRectMake(inset, inset, innerDiameter, innerDiameter);
        UIBezierPath *outerCircle = [UIBezierPath bezierPathWithRoundedRect:outerRect cornerRadius:outerRect.size.width * 0.5];
        UIBezierPath *innerCircle = [UIBezierPath bezierPathWithRoundedRect:innerRect cornerRadius:innerRect.size.width * 0.5];
        [outerCircle appendPath:innerCircle];
        CAShapeLayer *maskLayer = [CAShapeLayer new];
        maskLayer.fillRule = kCAFillRuleEvenOdd; // Going from the outside of the layer, each time a path is crossed, add one. Each time the count is odd, we are "inside" the path.
        maskLayer.path = outerCircle.CGPath;
        self.gradientRingLayer.mask = maskLayer;
        [self.avatarContainer.layer insertSublayer:self.gradientRingLayer atIndex:0];
        
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
        
        self.textLabel.font = CAMP_HEADER_NAME_FONT;
        self.textLabel.textColor = [UIColor bonfirePrimaryColor];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;

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
        
        self.detailsCollectionView = [[BFDetailsCollectionView alloc] initWithFrame:CGRectMake(CAMP_HEADER_EDGE_INSETS.left, 0, [UIScreen mainScreen].bounds.size.width - CAMP_HEADER_EDGE_INSETS.left - CAMP_HEADER_EDGE_INSETS.right, 16)];
        [self.contentView addSubview:self.detailsCollectionView];
        
        self.actionButton = [CampFollowButton buttonWithType:UIButtonTypeCustom];
        
        [self.actionButton bk_whenTapped:^{
            // update state if possible
            if ([self.actionButton.status isEqualToString:CAMP_STATUS_MEMBER]) {
                // confirm they want to leave
                [self openCampOptions];
            }
            else if ([self.actionButton.status isEqualToString:CAMP_STATUS_REQUESTED]) {
                [self leaveCamp];
                [self.actionButton updateStatus:CAMP_STATUS_NO_RELATION];
            }
            else if ([self.actionButton.status isEqualToString:CAMP_STATUS_LEFT] ||
                     [self.actionButton.status isEqualToString:CAMP_STATUS_NO_RELATION] ||
                     [self.actionButton.status isEqualToString:CAMP_STATUS_INVITED] ||
                     self.actionButton.status.length == 0) {
                if ([self.camp isSupported]) {
                    // join the camp
                    if ([self.camp isPrivate] &&
                        ![self.actionButton.status isEqualToString:CAMP_STATUS_INVITED]) {
                        [self.actionButton updateStatus:CAMP_STATUS_REQUESTED];
                    }
                    else {
                        // since they've been invited already, jump straight to being a member
                        [self.actionButton updateStatus:CAMP_STATUS_MEMBER];
                    }
                    [self updateCampStatus];
                    
                    [HapticHelper generateFeedback:FeedbackType_Notification_Success];
                    
                    [BFAPI followCamp:self.camp completion:^(BOOL success, id responseObject) {
                        if (success) {
                        }
                    }];
                }
                else {
                    BFAlertController *alert = [BFAlertController alertControllerWithIcon:[UIImage imageNamed:@"alert_icon_general"] title:@"Update Bonfire to Join" message:@"This Camp requires a newer version in order to join" preferredStyle:BFAlertControllerStyleAlert];
                    BFAlertAction *openAppStore = [BFAlertAction actionWithTitle:([Configuration isRelease]?@"Open App Store":@"Open TestFlight") style:BFAlertActionStyleDefault handler:^{
                        NSURL *url;
                        if ([Configuration isRelease]) {
                            url = [NSURL URLWithString:@"https://itunes.apple.com/app/1438702812"];
                        }
                    else {
                            url = [NSURL URLWithString:@"https://beta.itunes.apple.com/v1/app/1438702812"];
                        }
                        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                            NSLog(@"opened url!");
                        }];
                    }];
                    [alert addAction:openAppStore];
                    alert.preferredAction = openAppStore;
                    BFAlertAction *cancelAction = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
                    [alert addAction:cancelAction];
                    
                    [alert show];
                }
            }
            else if ([self.actionButton.status isEqualToString:CAMP_STATUS_BLOCKED]) {
                // show alert maybe? --> ideally we don't even show the button.
            }
        }];
        [self.contentView addSubview:self.actionButton];
        
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
    camp.status = self.actionButton.status;
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
        else {
            if ([responseObject objectForKey:@"error"]) {
                NSError *error = (NSError *)responseObject[@"error"];
                NSInteger code = [error bonfireErrorCode];
                DLog(@"code: %lu", code);
                if (code == CAMP_MIN_MEMBERS_VIOLATION) {
                    BFAlertController *alert = [BFAlertController alertControllerWithTitle:@"Musical Chairs 🎶" message:@"All Camps must have at least one director. Assign one before leaving this Camp." preferredStyle:BFAlertControllerStyleAlert];
                    BFAlertAction *assignDirector = [BFAlertAction actionWithTitle:@"Assign a Director" style:BFAlertActionStyleDefault handler:^{
                        AddManagerTableViewController *addManagerTableVC = [[AddManagerTableViewController alloc] init];
                        addManagerTableVC.camp = self.camp;
                        addManagerTableVC.managerType = @"admin";
                        
                        SimpleNavigationController *navController = [[SimpleNavigationController alloc] initWithRootViewController:addManagerTableVC];
                        navController.transitioningDelegate = [Launcher sharedInstance];
                        navController.modalPresentationStyle = UIModalPresentationFullScreen;
                        navController.currentTheme = [UIColor clearColor];
                        
                        [[Launcher topMostViewController] presentViewController:navController animated:YES completion:nil];
                    }];
                    [alert addAction:assignDirector];
                    alert.preferredAction = assignDirector;
                    BFAlertAction *cancelAction = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
                    [alert addAction:cancelAction];
                    
                    [alert show];
               }
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
        
    // profile pic collage
    self.avatarContainer.center = CGPointMake(self.frame.size.width / 2, self.avatarContainer.center.y);
    bottomY = CAMP_HEADER_EDGE_INSETS.top + (CAMP_HEADER_AVATAR_SIZE + (CAMP_HEADER_AVATAR_BORDER_WIDTH * 2));
    
    if (![self.campAvatarReasonView isHidden]) {
        self.campAvatarReasonView.center = CGPointMake(self.avatarContainer.frame.origin.x + self.avatarContainer.frame.size.width - (40 / 2) - 3, self.avatarContainer.frame.origin.y + self.avatarContainer.frame.size.height - (40 / 2) - 3);
    }
        
    CGFloat contentViewYOffset = CAMP_HEADER_EDGE_INSETS.top +  ceilf(CAMP_HEADER_AVATAR_SIZE * 0.65);
    self.contentView.frame = CGRectMake(0, contentViewYOffset, self.frame.size.width, self.frame.size.height - contentViewYOffset);
    
    // subtract content view inset
    bottomY -= self.contentView.frame.origin.y;
    
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
        bottomY = self.detailTextLabel.frame.origin.y + self.detailTextLabel.frame.size.height;
    }
    
    if (![self.descriptionLabel isHidden]) {
        if (![self.detailTextLabel isHidden]) {
            bottomY += CAMP_HEADER_TAG_BOTTOM_PADDING;
        }
        
        // detail text label
        CGRect detailLabelRect = [self.descriptionLabel.attributedText boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
        self.descriptionLabel.frame = CGRectMake(CAMP_HEADER_EDGE_INSETS.left, bottomY, maxWidth, ceilf(detailLabelRect.size.height));
        bottomY = self.descriptionLabel.frame.origin.y + self.descriptionLabel.frame.size.height;
    }
    
    if (![self.detailsCollectionView isHidden]) {
        if (![self.descriptionLabel isHidden]) {
            bottomY += CAMP_HEADER_DESCRIPTION_BOTTOM_PADDING;
        }
        else if (![self.detailTextLabel isHidden]) {
            bottomY += CAMP_HEADER_TAG_BOTTOM_PADDING;
        }
        
        self.detailsCollectionView.frame = CGRectMake(CAMP_HEADER_EDGE_INSETS.left, bottomY, self.frame.size.width - (CAMP_HEADER_DETAILS_EDGE_INSETS.left + CAMP_HEADER_DETAILS_EDGE_INSETS.right), self.detailsCollectionView.contentSize.height);
        bottomY = self.detailsCollectionView.frame.origin.y + self.detailsCollectionView.frame.size.height;
    }
    
    if (![self.actionButton isHidden]) {
        CGFloat actionButtonHeight = 38;
        CGFloat actionButtonY = bottomY + CAMP_HEADER_FOLLOW_BUTTON_TOP_PADDING;
        self.actionButton.frame = CGRectMake(12, actionButtonY, self.frame.size.width - (12 * 2), actionButtonHeight);
    }

    // line separator
    self.lineSeparator.frame = CGRectMake(0, self.lineSeparator.superview.frame.size.height - HALF_PIXEL, self.frame.size.width, HALF_PIXEL);
}

//- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
//    [self updateDetailTextLabel];
//}

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
    
    [self addSubview:borderView];
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

- (void)updateDetailTextLabel {
    UIFont *font = self.detailTextLabel.font;
    NSMutableAttributedString *camptagAttributedString = [NSMutableAttributedString new];
    
    UIImage *attachmentImage;
    NSString *camptag = _camp.attributes.identifier.length > 0 ? [NSString stringWithFormat:@"#%@", _camp.attributes.identifier] : nil;
    NSString *label;
    UIColor *color = _camp.attributes.color.length > 0 ? [UIColor fromHex:_camp.attributes.color adjustForOptimalContrast:true] : [UIColor bonfireSecondaryColor];
    
    if ([_camp isPrivate]) {
        attachmentImage = [UIImage imageNamed:@"details_label_private"];
        
        if (!camptag) label = @"Private";
    }
    else if ([_camp isFeed]) {
        attachmentImage = [UIImage imageNamed:@"details_label_feed"];
        
        if (!camptag) label = @"Feed";
    }
    else if ([_camp isChannel]) {
        attachmentImage = [UIImage imageNamed:@"details_label_source"];
        
        if (!camptag) label = @"Channel";
    }
    
    NSAttributedString *spacer = [[NSAttributedString alloc] initWithString:@" " attributes:@{NSFontAttributeName: font}];
    
    if (camptag) {
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:camptag attributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: color}];
        
        [camptagAttributedString appendAttributedString:attributedString];
    }
    
    if (attachmentImage) {
        if (camptagAttributedString.length > 0) {
            [camptagAttributedString appendAttributedString:spacer];
        }
        
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = [self colorImage:attachmentImage color:color];
        CGFloat attachmentHeight = MIN(ceilf(font.lineHeight * 0.7), attachment.image.size.height);
        CGFloat attachmentWidth = attachmentHeight * (attachment.image.size.width / attachment.image.size.height);
        [attachment setBounds:CGRectMake(0, roundf(font.capHeight - attachmentHeight)/2.f + 0.5, attachmentWidth, attachmentHeight)];
        
        NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
        [camptagAttributedString appendAttributedString:attachmentString];
    }
    
    if (!camptag && label) {
        if (camptagAttributedString.length > 0) {
            [camptagAttributedString appendAttributedString:spacer];
        }
        
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:label attributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
        
        [camptagAttributedString appendAttributedString:attributedString];
    }
    
    self.detailTextLabel.attributedText = camptagAttributedString;
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
            campTitle = [NSString stringWithFormat:@"#%@", camp.attributes.identifier];
        }
        else {
            campTitle = @"Loading...";
        }
        NSMutableAttributedString *displayNameAttributedString = [[NSMutableAttributedString alloc] initWithString:campTitle attributes:@{NSFontAttributeName:CAMP_HEADER_NAME_FONT}];
        if ([camp isVerified]) {
            NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
            [spacer addAttribute:NSFontAttributeName value:CAMP_HEADER_NAME_FONT range:NSMakeRange(0, spacer.length)];
            [displayNameAttributedString appendAttributedString:spacer];
            
            // verified icon ☑️
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.image = [UIImage imageNamed:@"verifiedIcon_large"];
            
            CGFloat attachmentHeight = MIN(ceilf(CAMP_HEADER_NAME_FONT.lineHeight * 0.9), ceilf(attachment.image.size.height));
            CGFloat attachmentWidth = ceilf(attachmentHeight * (attachment.image.size.width / attachment.image.size.height));
            
            [attachment setBounds:CGRectMake(0, roundf(CAMP_HEADER_NAME_FONT.capHeight - attachmentHeight)/2.f, attachmentWidth, attachmentHeight)];
            
            NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
            [displayNameAttributedString appendAttributedString:attachmentString];
        }
        self.textLabel.attributedText = displayNameAttributedString;
        
//        [self updateDetailTextLabel];
        if (camp.attributes.identifier.length > 0) {
            self.detailTextLabel.text = [@"#" stringByAppendingFormat:@"%@", camp.attributes.identifier];
            self.detailTextLabel.textColor = [UIColor fromHex:camp.attributes.color adjustForOptimalContrast:true];
        }
        else {
            self.detailTextLabel.text = @"";
        }
        self.detailTextLabel.hidden = self.detailTextLabel.text.length == 0;
                
        self.descriptionLabel.hidden = camp.attributes.theDescription.length == 0;
        if (![self.descriptionLabel isHidden]) {
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
        
        BOOL useText = false;
        BOOL useImage = false;

        NSDateComponents *components;
        if (camp.attributes.createdAt.length > 0) {
            NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
                [inputFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
            NSDate *date = [inputFormatter dateFromString:camp.attributes.createdAt];
            
            NSUInteger unitFlags = NSCalendarUnitDay;
            NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            components = [calendar components:unitFlags fromDate:date toDate:[NSDate new] options:0];
        }
        
        BFCampHeaderLiveMode mockMode = BFCampHeaderLiveModeAudio;
        if ([camp.identifier isEqualToString:testingGroundsCampId]) {
            [self setLiveMode:BFCampHeaderLiveModeAudio];
        }
        else {
            [self setLiveMode:BFCampHeaderLiveModeNone];
        }
        
        if (self.liveMode == BFCampHeaderLiveModeVideo ||
            self.liveMode == BFCampHeaderLiveModeStory) {
            useText = true;
            self.campAvatarReasonLabel.text = @"📹";
            self.campAvatarReasonView.tag = (self.liveMode == BFCampHeaderLiveModeVideo ? CAMP_CONTEXT_BUBBLE_TAG_LIVE_MODE_VIDEO : CAMP_CONTEXT_BUBBLE_TAG_LIVE_MODE_STORY);
        }
        else if (self.liveMode == BFCampHeaderLiveModeAudio) {
            useText = true;
            self.campAvatarReasonLabel.text = @"🎤";
            self.campAvatarReasonView.tag = CAMP_CONTEXT_BUBBLE_TAG_LIVE_MODE_AUDIO;
        }
        else if (self.liveMode == BFCampHeaderLiveModeChat) {
            useText = true;
            self.campAvatarReasonLabel.text = @"💬";
            self.campAvatarReasonView.tag = CAMP_CONTEXT_BUBBLE_TAG_LIVE_MODE_CHAT;
        }
        else {
            if (camp.attributes.summaries.counts.scoreIndex > 0) {
                useImage = true;
                self.campAvatarReasonLabel.text = @"";
                self.campAvatarReasonImageView.image = [UIImage imageNamed:@"hotIcon"];
                self.campAvatarReasonImageView.backgroundColor = [UIColor fromHex:camp.scoreColor];
                self.campAvatarReasonView.tag = CAMP_CONTEXT_BUBBLE_TAG_ACTIVE;
            }
            else if (components && [components day] < 7) {
                useImage = true;
                self.campAvatarReasonImageView.image = [UIImage imageNamed:@"newIcon"];
                self.campAvatarReasonView.tag = CAMP_CONTEXT_BUBBLE_TAG_NEW_CAMP;
            }
        }
        
        BOOL hideReasonView = !useText && !useImage;
        if (hideReasonView != [self.campAvatarReasonView isHidden]) {
            self.campAvatarReasonView.hidden = hideReasonView;
            
            if (!hideReasonView) {
                self.campAvatarReasonView.transform = CGAffineTransformMakeScale(0.25, 0.25);
                self.campAvatarReasonView.alpha = 0;
                
                [UIView animateWithDuration:0.55f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.campAvatarReasonView.alpha = 1;
                    self.campAvatarReasonView.transform = CGAffineTransformMakeScale(1, 1);
                } completion:nil];
            }
        }
        self.campAvatarReasonImageView.hidden = !useImage;
        self.campAvatarReasonLabel.hidden = !useText;
        
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
            avatarView.superview.hidden = ![self.camp isDefaultCamp];
            
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
        
        NSArray *details = [CampHeaderCell detailItemsForCamp:camp];
        
        self.detailsCollectionView.hidden = (details.count == 0);
        self.detailsCollectionView.tintColor = [UIColor fromHex:self.camp.attributes.color adjustForOptimalContrast:true];
        
        if (![self.detailsCollectionView isHidden]) {
            self.detailsCollectionView.details = [details copy];
        }
        
        if ([camp isChannel] || [camp isFeed]) {
            self.actionButton.followString = @"Subscribe";
            self.actionButton.followingString = @"Subscribed";
        }
        else {
            self.actionButton.followString = @"Join Camp";
            self.actionButton.followingString = @"Joined";
        }
    }
}

- (void)setLiveMode:(BFCampHeaderLiveMode)liveMode {
    if (liveMode != _liveMode) {
        CGPoint avatarContainerCenterPoint = self.avatarContainer.center;
        if (_liveMode == BFCampHeaderLiveModeNone) {
            // from  not live -> live
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.avatarContainer.frame = CGRectMake(0, 0, CAMP_HEADER_AVATAR_SIZE + (CAMP_HEADER_AVATAR_BORDER_WIDTH * 4), CAMP_HEADER_AVATAR_SIZE + (CAMP_HEADER_AVATAR_BORDER_WIDTH * 4));
                self.avatarContainer.layer.cornerRadius = self.avatarContainer.frame.size.width / 2;
                self.avatarContainer.center = avatarContainerCenterPoint;
                self.campAvatar.center = CGPointMake(self.avatarContainer.frame.size.width / 2, self.avatarContainer.frame.size.height / 2);
                self.gradientRingLayer.opacity = 1;
                self.gradientRingLayer.frame = CGRectMake(self.avatarContainer.frame.size.width / 2 - self.gradientRingLayer.frame.size.width / 2, self.avatarContainer.frame.size.height / 2 - self.gradientRingLayer.frame.size.height / 2, self.gradientRingLayer.frame.size.width, self.gradientRingLayer.frame.size.height);
            } completion:nil];
        }
        else if (liveMode == BFCampHeaderLiveModeNone) {
            // from live -> not live
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.avatarContainer.frame = CGRectMake(0, 0, CAMP_HEADER_AVATAR_SIZE + (CAMP_HEADER_AVATAR_BORDER_WIDTH * 2), CAMP_HEADER_AVATAR_SIZE + (CAMP_HEADER_AVATAR_BORDER_WIDTH * 2));
                self.avatarContainer.layer.cornerRadius = self.avatarContainer.frame.size.width / 2;
                self.avatarContainer.center = avatarContainerCenterPoint;
                self.campAvatar.center = CGPointMake(self.avatarContainer.frame.size.width / 2, self.avatarContainer.frame.size.height / 2);
                self.gradientRingLayer.opacity = 0;
            } completion:nil];
        }
        
        _liveMode = liveMode;
        
        if (liveMode == BFCampHeaderLiveModeNone) {
            
        }
        else {
            NSArray *gradientColors = [NSArray arrayWithObjects:(id)[UIColor bonfireBrand].CGColor, (id)[UIColor yellowColor].CGColor, nil];
            if (liveMode == BFCampHeaderLiveModeStory) {
                gradientColors = [NSArray arrayWithObjects:(id)[UIColor colorWithRed: 1.00 green: 0.00 blue: 0.00 alpha: 1.00].CGColor, (id)[UIColor colorWithRed: 1.00 green: 0.50 blue: 0.00 alpha: 1.00].CGColor, nil];
            }
            else if (liveMode == BFCampHeaderLiveModeVideo) {
                gradientColors = [NSArray arrayWithObjects:(id)[UIColor colorWithRed: 1.00 green: 0.00 blue: 0.00 alpha: 1.00].CGColor, (id)[UIColor colorWithRed: 1.00 green: 0.50 blue: 0.00 alpha: 1.00].CGColor, nil];
            }
            else if (liveMode == BFCampHeaderLiveModeAudio) {
                gradientColors = [NSArray arrayWithObjects:(id)[UIColor colorWithRed: 0.18 green: 0.00 blue: 1.00 alpha: 1.00].CGColor, (id)[UIColor colorWithRed: 0.97 green: 0.00 blue: 1.00 alpha: 1.00].CGColor, nil];
            }
            else if (liveMode == BFCampHeaderLiveModeChat) {
                gradientColors = [NSArray arrayWithObjects:(id)[UIColor colorWithRed: 0.39 green: 0.85 blue: 0.14 alpha: 1.00].CGColor, (id)[UIColor colorWithRed: 0.00 green: 0.83 blue: 1.00 alpha: 1.00].CGColor, nil];
            }
            
            self.gradientRingLayer.colors = gradientColors;
            self.gradientRingLayer.startPoint = CGPointMake(0, 0);
            self.gradientRingLayer.endPoint = CGPointMake(1, 1);
        }
    }
}

+ (NSArray<BFDetailItem *> *)detailItemsForCamp:(Camp *)camp {
    NSMutableArray *details = [[NSMutableArray alloc] init];
    if (camp.attributes.identifier.length > 0 || camp.identifier.length > 0) {
        // camp type (& visibility)
        if (camp.attributes.display.sourceLink || camp.attributes.display.sourceUser) {
            if (camp.attributes.display.sourceLink) {
                BFDetailItem *sourceLink = [[BFDetailItem alloc] initWithType:([camp isFeed] ? BFDetailItemTypeSourceLink_Feed : BFDetailItemTypeSourceLink) value:[NSString stringWithFormat:@"%@", camp.attributes.display.sourceLink.attributes.canonicalUrl] action:^{
                    [Launcher openURL:camp.attributes.display.sourceLink.attributes.actionUrl];
                }];
                sourceLink.selectable = true;
                [details addObject:sourceLink];
            }
            else if (camp.attributes.display.sourceUser) {
                BFDetailItem *sourceUser = [[BFDetailItem alloc] initWithType:([camp isFeed] ? BFDetailItemTypeSourceUser_Feed : BFDetailItemTypeSourceUser) value:[NSString stringWithFormat:@"%@", camp.attributes.display.sourceUser.attributes.identifier] action:^{
                    [Launcher openProfile:camp.attributes.display.sourceUser];
                }];
                sourceUser.selectable = true;
                [details addObject:sourceUser];
            }
        }
            
        if (![camp isChannel]) {
            BFDetailItem *visibility = [[BFDetailItem alloc] initWithType:([camp isPrivate] ? BFDetailItemTypePrivacyPrivate : BFDetailItemTypePrivacyPublic) value:([camp isPrivate] ? @"Private" : @"Public") action:nil];
            [details addObject:visibility];
        }
        
        if (camp.attributes.nsfw) {
            BFDetailItem *nsfw = [[BFDetailItem alloc] initWithType:BFDetailItemTypeMatureContent value:@"Mature" action:nil];
            [details addObject:nsfw];
        }
        
        // member / subscriber count
        if (![camp isFeed] && camp.attributes.summaries.counts != nil) {
            if ([camp isChannel]) {
                BFDetailItem *subscribers = [[BFDetailItem alloc] initWithType:BFDetailItemTypeSubscribers value:[NSString stringWithFormat:@"%ld", (long)camp.attributes.summaries.counts.members] action:nil];
                subscribers.selectable = false;
                [details addObject:subscribers];
            }
            else {
                BFDetailItem *members = [[BFDetailItem alloc] initWithType:BFDetailItemTypeMembers value:[NSString stringWithFormat:@"%ld", (long)camp.attributes.summaries.counts.members] action:^{
                    [Launcher openCampMembersForCamp:camp];
                }];
                if ([camp isPrivate] && ![camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_MEMBER]) {
                    members.selectable = false;
                }
                [details addObject:members];
            }
        }
        
        BOOL campPostNotifications = camp.attributes.context.camp.membership.subscription != nil;
        BFDetailItem *notifications = [[BFDetailItem alloc] initWithType:(campPostNotifications?BFDetailItemTypePostNotificationsOn:BFDetailItemTypePostNotificationsOff) value:@"" action:^{
            BOOL campPostNotifications = camp.attributes.context.camp.membership.subscription != nil;
            UIImage *icon = (campPostNotifications ? [UIImage imageNamed:@"alert_icon_notifications_on"] : [UIImage imageNamed:@"alert_icon_notifications_off"]);
            
            BFAlertController *postNotifications = [BFAlertController alertControllerWithIcon:icon title:(campPostNotifications?@"Post Notifications are on":@"Post Notifications are off") message:(campPostNotifications ? @"You will receive notifications for new posts inside this Camp" : @"You will only receive notifications when you are mentioned or replied to") preferredStyle:BFAlertControllerStyleActionSheet];
            
            NSString *actionTitle = [@"Turn Post Notifications " stringByAppendingString:(campPostNotifications?@"Off":@"On")];

            BFAlertAction *togglePostNotifications = [BFAlertAction actionWithTitle:actionTitle style:BFAlertActionStyleDefault handler:^{
                NSLog(@"toggle post notifications");
                // confirm action
                Camp *campCopy = [camp copy];
                if (campPostNotifications) {
                    BFMiniNotificationObject *notificationObject = [BFMiniNotificationObject notificationWithText:@"Saved!" action:nil];
                    [[BFMiniNotificationManager manager] presentNotification:notificationObject completion:nil];
                    
                    [campCopy unsubscribeFromCamp];
                }
                else {
                    BFMiniNotificationObject *notificationObject = [BFMiniNotificationObject notificationWithText:@"Saved!" action:nil];
                    [[BFMiniNotificationManager manager] presentNotification:notificationObject completion:nil];
                    
                    [campCopy subscribeToCamp];
                }
            }];
            [postNotifications addAction:togglePostNotifications];
            
            // confirm action
            BFAlertAction *alertCancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
            [postNotifications addAction:alertCancel];
            
            [postNotifications show];
        }];
        [details addObject:notifications];
        
        if ([camp.attributes.context.camp.permissions canUpdate]) {
            BFDetailItem *edit = [[BFDetailItem alloc] initWithType:BFDetailItemTypeEdit value:@"" action:^{
                [Launcher openEditCamp:camp];
            }];
            [details addObject:edit];
        }
    }
    
    return [details copy];
}
- (void)openCampOptions {
    BFAlertController *postNotifications = [BFAlertController alertControllerWithIcon:nil title:self.camp.attributes.title message:(self.camp.attributes.identifier.length>0 ? [@"#" stringByAppendingString:self.camp.attributes.identifier] : nil) preferredStyle:BFAlertControllerStyleActionSheet];
    
    BFAlertAction *leaveCamp = [BFAlertAction actionWithTitle:([self.camp isChannel] || [self.camp isFeed] ? @"Unsubscribe" : @"Leave Camp") style:BFAlertActionStyleDefault handler:^{
        // confirm action
        BOOL privateCamp = [self.camp isPrivate];
        BOOL lastMember = self.camp.attributes.summaries.counts.members <= 1;
        BOOL isMember = [self.camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_MEMBER];
        
        void (^leave)(void) = ^(){
            [self.actionButton updateStatus:CAMP_STATUS_LEFT];
            [self leaveCamp];
        };
        
        if (privateCamp || lastMember || isMember) {
            NSString *message;
            if (privateCamp && lastMember) {
                message = @"All camps must have at least one member. If you leave, this Camp and all of its posts will be deleted after 30 days of inactivity.";
            }
            else if (lastMember) {
                // leaving as the last member in a public camp
                message = @"All camps must have at least one member. If you leave, this Camp will be archived and eligible for anyone to reopen.";
            }
            else if (privateCamp) {
                // leaving a private camp, but the user isn't the last one
                message = @"You will no longer have access to this Camp's posts";
            }
            else {
                // leaving a public camp (generic)
                if ([self.camp isChannel]) {
                    message = @"You will no longer receive posts from this Camp";
                }
                else if ([self.camp isFeed]) {
                    message = @"You will no longer receive posts from this Feed";
                }
                else {
                    message = @"You will no longer be a part of this Camp";
                }
            }
            
            BFAlertController *confirmDeletePostActionSheet = [BFAlertController alertControllerWithTitle:(([self.camp isChannel] || [self.camp isFeed]) ? @"Unsubscribe?" : @"Leave Camp?") message:message preferredStyle:BFAlertControllerStyleAlert];
            
            BFAlertAction *confirmLeaveCamp = [BFAlertAction actionWithTitle:(([self.camp isChannel] || [self.camp isFeed]) ? @"Unsubscribe" : @"Leave") style:BFAlertActionStyleDestructive handler:^{
                leave();
            }];
            [confirmDeletePostActionSheet addAction:confirmLeaveCamp];
            
            BFAlertAction *cancelLeaveCamp = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
            [confirmDeletePostActionSheet addAction:cancelLeaveCamp];
            
            [confirmDeletePostActionSheet show];
        }
        else {
            leave();
        }
    }];
    [postNotifications addAction:leaveCamp];
    
    // confirm action
    BFAlertAction *alertCancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
    [postNotifications addAction:alertCancel];
    
    [postNotifications show];
}

+ (CGFloat)heightForCamp:(Camp *)camp isLoading:(BOOL)loading {
    CGFloat maxWidth = [UIScreen mainScreen].bounds.size.width - (CAMP_HEADER_EDGE_INSETS.left + CAMP_HEADER_EDGE_INSETS.right);

    CGFloat height = CAMP_HEADER_EDGE_INSETS.top + (CAMP_HEADER_AVATAR_SIZE + (CAMP_HEADER_AVATAR_BORDER_WIDTH * 2)) + CAMP_HEADER_AVATAR_BOTTOM_PADDING;

    // camp title
    NSString *campTitle;
    if (camp.attributes.title.length > 0) {
        campTitle = camp.attributes.title;
    }
    else if (camp.attributes.identifier.length > 0) {
        campTitle = [NSString stringWithFormat:@"#%@", camp.attributes.identifier];
    }
    else {
        campTitle = @"Loading...";
    }
    NSMutableAttributedString *displayNameAttributedString = [[NSMutableAttributedString alloc] initWithString:campTitle attributes:@{NSFontAttributeName:CAMP_HEADER_NAME_FONT}];
    if ([camp isVerified]) {
        NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
        [spacer addAttribute:NSFontAttributeName value:CAMP_HEADER_NAME_FONT range:NSMakeRange(0, spacer.length)];
        [displayNameAttributedString appendAttributedString:spacer];
        
        // verified icon ☑️
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = [UIImage imageNamed:@"verifiedIcon_large"];
        
        CGFloat attachmentHeight = MIN(ceilf(CAMP_HEADER_NAME_FONT.lineHeight * 0.9), ceilf(attachment.image.size.height));
        CGFloat attachmentWidth = ceilf(attachmentHeight * (attachment.image.size.width / attachment.image.size.height));
        
        [attachment setBounds:CGRectMake(0, roundf(CAMP_HEADER_NAME_FONT.capHeight - attachmentHeight)/2.f, attachmentWidth, attachmentHeight)];
        
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
        
        if (camp.attributes.identifier.length > 0) {
            height += CAMP_HEADER_TAG_BOTTOM_PADDING;
        }
        
        height += campDescriptionHeight;
    }

    if (camp.attributes.identifier.length > 0 || camp.identifier.length > 0) {
        NSArray *details = [CampHeaderCell detailItemsForCamp:camp];
         
        if (details.count > 0) {
            BFDetailsCollectionView *detailCollectionView = [[BFDetailsCollectionView alloc] initWithFrame:CGRectMake(CAMP_HEADER_EDGE_INSETS.left, 0, [UIScreen mainScreen].bounds.size.width - CAMP_HEADER_EDGE_INSETS.left - CAMP_HEADER_EDGE_INSETS.right, 16)];
            detailCollectionView.delegate = detailCollectionView;
            detailCollectionView.dataSource = detailCollectionView;
            [detailCollectionView setDetails:details];
            
            CGFloat detailsHeight = detailCollectionView.collectionViewLayout.collectionViewContentSize.height;
            
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
        height += userPrimaryActionHeight;
    }

    // add bottom padding
    height += CAMP_HEADER_EDGE_INSETS.bottom;

    return height;
}

- (UIImage *)colorImage:(UIImage *)image color:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);

    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextDrawImage(context, rect, image.CGImage);
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    [color setFill];
    CGContextFillRect(context, rect);


    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return coloredImage;
}

@end
