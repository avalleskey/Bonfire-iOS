//
//  CampHeaderCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/1/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "CampHeaderCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <HapticHelper/HapticHelper.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Session.h"
#import "Defaults.h"
#import "CampViewController.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import "EditCampViewController.h"

#define UIViewParentController(__view) ({ \
        UIResponder *__responder = __view; \
        while ([__responder isKindOfClass:[UIView class]]) \
        __responder = [__responder nextResponder]; \
        (UIViewController *)__responder; \
        })

@implementation CampHeaderCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        //self.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
        self.backgroundColor = [UIColor whiteColor];
        
        self.contentView.layer.masksToBounds = false;
        self.layer.masksToBounds = false;
        
        self.textLabel.font = CAMP_HEADER_NAME_FONT;
        self.textLabel.textColor = [UIColor bonfireBlack];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        // username
        //UIFont *heavyItalicFont = [UIFont fontWithDescriptor:[[[UIFont systemFontOfSize:CAMP_HEADER_TAG_FONT.pointSize weight:UIFontWeightHeavy] fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic] size:CAMP_HEADER_TAG_FONT.pointSize];
        self.detailTextLabel.font = [UIFont systemFontOfSize:CAMP_HEADER_TAG_FONT.pointSize weight:UIFontWeightHeavy];
        self.detailTextLabel.textAlignment = NSTextAlignmentCenter;
        self.detailTextLabel.textColor = [UIColor bonfireGray];
        self.detailTextLabel.numberOfLines = 0;
        self.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        
        self.descriptionLabel = [[UILabel alloc] init];
        self.descriptionLabel.font = CAMP_HEADER_DESCRIPTION_FONT;
        self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
        self.descriptionLabel.textColor = [UIColor bonfireBlack];
        self.descriptionLabel.numberOfLines = 0;
        self.descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.contentView addSubview:self.descriptionLabel];
        
        // general cell styling
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.campPicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, CAMP_HEADER_EDGE_INSETS.top, CAMP_HEADER_AVATAR_SIZE, CAMP_HEADER_AVATAR_SIZE)];
        [self.campPicture bk_whenTapped:^{
            void(^expandProfilePic)(void) = ^() {
                [Launcher expandImageView:self.campPicture.imageView];
            };
            
            BOOL hasPicture = (self.campPicture.camp.attributes.details.media.campAvatar.suggested.url.length > 0);
            if ([self.camp.attributes.context.camp.permissions canUpdate]) {
                void(^openEditCamp)(void) = ^() {
                    [self openEditCamp];
                };
                
                if (hasPicture) {
                    // confirm action
                    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
                    
                    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"View Camp Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [actionSheet dismissViewControllerAnimated:YES completion:nil];
                        
                        expandProfilePic();
                    }];
                    [actionSheet addAction:action1];
                    
                    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"Edit Camp" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        openEditCamp();
                    }];
                    [actionSheet addAction:action2];
                    
                    UIAlertAction *cancelActionSheet = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
                    [actionSheet addAction:cancelActionSheet];
                    
                    [[Launcher topMostViewController] presentViewController:actionSheet animated:YES completion:nil];
                }
                else {
                    openEditCamp();
                }
            }
            else if (hasPicture) {
                expandProfilePic();
            }
        }];
        [self.contentView addSubview:self.campPicture];
        
        self.infoButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
        self.infoButton.layer.cornerRadius = self.infoButton.frame.size.height / 2;
        self.infoButton.layer.masksToBounds = true;
        self.infoButton.layer.borderColor = self.backgroundColor.CGColor;
        self.infoButton.layer.borderWidth = 2.f;
        self.infoButton.backgroundColor = [UIColor whiteColor];
        [self.infoButton setImage:[[UIImage imageNamed:@"infoIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        self.infoButton.hidden = true;
        //[self.contentView addSubview:self.infoButton];
        
        self.member2 = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        self.member2.placeholderAvatar = true;
        self.member2.tag = 0;
        self.member3 = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        self.member3.placeholderAvatar = true;
        self.member3.tag = 1;
        
        self.member4 = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        self.member4.placeholderAvatar = true;
        self.member4.tag = 2;
        self.member5 = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        self.member5.placeholderAvatar = true;
        self.member5.tag = 3;
        
        self.member6 = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        self.member6.placeholderAvatar = true;
        self.member6.tag = 4;
        self.member7 = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        self.member7.placeholderAvatar = true;
        self.member7.tag = 5;
        
        [self.contentView addSubview:self.member2];
        [self.contentView addSubview:self.member3];
        [self.contentView addSubview:self.member4];
        [self.contentView addSubview:self.member5];
        [self.contentView addSubview:self.member6];
        [self.contentView addSubview:self.member7];
        
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
                    BOOL privateCamp = self.camp.attributes.status.visibility.isPrivate;
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
                        
                        UIAlertController *confirmDeletePostActionSheet = [UIAlertController alertControllerWithTitle:@"Leave Camp?" message:message preferredStyle:UIAlertControllerStyleAlert];
                        
                        UIAlertAction *confirmLeaveCamp = [UIAlertAction actionWithTitle:@"Leave" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                            leave();
                        }];
                        [confirmDeletePostActionSheet addAction:confirmLeaveCamp];
                        
                        UIAlertAction *cancelLeaveCamp = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
                        [confirmDeletePostActionSheet addAction:cancelLeaveCamp];
                        
                        [UIViewParentController(self) presentViewController:confirmDeletePostActionSheet animated:YES completion:nil];
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
                if (self.camp.attributes.status.visibility.isPrivate &&
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
        self.lineSeparator.backgroundColor = [UIColor separatorColor];
        //[self.contentView addSubview:self.lineSeparator];
        
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

- (void)openEditCamp {
    EditCampViewController *epvc = [[EditCampViewController alloc] initWithStyle:UITableViewStyleGrouped];
    epvc.themeColor = [UIColor fromHex:self.camp.attributes.details.color];
    epvc.view.tintColor = epvc.themeColor;
    epvc.camp = self.camp;
    
    SimpleNavigationController *newNavController = [[SimpleNavigationController alloc] initWithRootViewController:epvc];
    newNavController.transitioningDelegate = [Launcher sharedInstance];
    newNavController.modalPresentationStyle = UIModalPresentationFullScreen;
    
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
    self.campPicture.center = CGPointMake(self.contentView.frame.size.width / 2, self.campPicture.center.y);
    bottomY = self.campPicture.frame.origin.y + self.campPicture.frame.size.height;
    
    self.infoButton.frame = CGRectMake(self.campPicture.frame.origin.x + self.campPicture.frame.size.width - self.infoButton.frame.size.width - 2, self.campPicture.frame.origin.y + self.campPicture.frame.size.height - self.infoButton.frame.size.height - 2, self.infoButton.frame.size.width, self.infoButton.frame.size.height);
    
    self.member2.frame = CGRectMake(self.campPicture.frame.origin.x - self.member2.frame.size.width - 24, 57, self.member2.frame.size.width, self.member2.frame.size.height);
    self.member3.frame = CGRectMake(self.frame.size.width - self.member2.frame.origin.x - self.member3.frame.size.width, 41, self.member3.frame.size.width, self.member3.frame.size.height);
    
    self.member4.frame = CGRectMake(self.member2.frame.origin.x - self.member4.frame.size.width - 16, 28, self.member4.frame.size.width, self.member4.frame.size.height);
    self.member5.frame = CGRectMake(self.frame.size.width - self.member4.frame.origin.x - self.member5.frame.size.width, 82, self.member5.frame.size.width, self.member5.frame.size.height);
    
    self.member6.frame = CGRectMake(self.member4.frame.origin.x - self.member6.frame.size.width - 8, 83, self.member6.frame.size.width, self.member6.frame.size.height);
    self.member7.frame = CGRectMake(self.frame.size.width - self.member6.frame.origin.x - self.member7.frame.size.width, 35, self.member7.frame.size.width, self.member7.frame.size.height);
    
    // text label
    CGRect nameLabelRect = [self.textLabel.text boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.textLabel.font} context:nil];
    self.textLabel.frame = CGRectMake(CAMP_HEADER_EDGE_INSETS.left, bottomY + CAMP_HEADER_AVATAR_BOTTOM_PADDING, maxWidth, ceilf(nameLabelRect.size.height));
    bottomY = self.textLabel.frame.origin.y + self.textLabel.frame.size.height;

    // detail text label
    CGRect detailLabelRect = [self.detailTextLabel.text boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.detailTextLabel.font} context:nil];
    self.detailTextLabel.frame = CGRectMake(self.textLabel.frame.origin.x, bottomY + CAMP_HEADER_NAME_BOTTOM_PADDING, self.textLabel.frame.size.width, ceilf(detailLabelRect.size.height));
    bottomY = self.detailTextLabel.frame.origin.y + self.detailTextLabel.frame.size.height;
    
    if (self.descriptionLabel.text.length > 0) {
        // detail text label
        CGRect detailLabelRect = [self.descriptionLabel.attributedText boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
        self.descriptionLabel.frame = CGRectMake(CAMP_HEADER_EDGE_INSETS.left, self.detailTextLabel.frame.origin.y + self.detailTextLabel.frame.size.height + CAMP_HEADER_TAG_BOTTOM_PADDING, maxWidth, ceilf(detailLabelRect.size.height));
        bottomY = self.descriptionLabel.frame.origin.y + self.descriptionLabel.frame.size.height;
    }
    
    if (!self.detailsCollectionView.isHidden) {
        self.detailsCollectionView.frame = CGRectMake(CAMP_HEADER_EDGE_INSETS.left, bottomY + (self.descriptionLabel.text.length > 0 ? CAMP_HEADER_DESCRIPTION_BOTTOM_PADDING : CAMP_HEADER_TAG_BOTTOM_PADDING) + CAMP_HEADER_DETAILS_EDGE_INSETS.top, self.frame.size.width - (CAMP_HEADER_DETAILS_EDGE_INSETS.left + CAMP_HEADER_DETAILS_EDGE_INSETS.right), self.detailsCollectionView.contentSize.height);
        bottomY = self.detailsCollectionView.frame.origin.y + self.detailsCollectionView.frame.size.height;
    }
    
    self.followButton.frame = CGRectMake(CAMP_HEADER_EDGE_INSETS.left, bottomY + CAMP_HEADER_FOLLOW_BUTTON_TOP_PADDING, maxWidth, 36);
}

- (void)styleMemberProfilePictureView:(UIImageView *)imageView  {
    BOOL circleProfilePictures = YES;
    if (circleProfilePictures) {
        [self continuityRadiusForView:imageView withRadius:imageView.frame.size.height * .5];
    }
    else {
        [self continuityRadiusForView:imageView withRadius:imageView.frame.size.height * .25];
    }
    
    imageView.backgroundColor = [UIColor whiteColor];
//    imageView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2f];
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
        
        if (camp.attributes.details.title) {
            self.textLabel.text = camp.attributes.details.title.length > 0 ? camp.attributes.details.title : @"Unknown Camp";
        }
        else if (camp.attributes.details.identifier) {
            self.textLabel.text = [NSString stringWithFormat:@"#%@", camp.attributes.details.identifier];
        }
        else {
            self.textLabel.text = @"Unknown Camp";
        }
        
        self.detailTextLabel.text = [NSString stringWithFormat:@"#%@", camp.attributes.details.identifier];
        self.detailTextLabel.textColor = [UIColor fromHex:camp.attributes.details.color];
        
        if (camp.attributes.details.theDescription.length > 0) {
            NSMutableAttributedString *attrString = [[NSMutableAttributedString  alloc] initWithString:camp.attributes.details.theDescription];
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
        self.campPicture.camp = camp;
        
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
            
            if (camp.attributes.summaries.members.count > i) {
                User *userForImageView = camp.attributes.summaries.members[i];
                
                avatarView.user = userForImageView;
                avatarView.dimsViewOnTap = true;
            }
            else {
                avatarView.dimsViewOnTap = false;
            }
        }
        
        NSMutableArray *details = [[NSMutableArray alloc] init];
        if (camp.attributes.details.identifier.length > 0 || camp.identifier.length > 0) {
            if (self.camp.attributes.status.visibility != nil) {
                BFDetailItem *visibility = [[BFDetailItem alloc] initWithType:(camp.attributes.status.visibility.isPrivate ? BFDetailItemTypePrivacyPrivate : BFDetailItemTypePrivacyPublic) value:(camp.attributes.status.visibility.isPrivate ? @"Private" : @"Public") action:nil];
                [details addObject:visibility];
            }
            
            if (self.camp.attributes.summaries.counts != nil) {
                BFDetailItem *members = [[BFDetailItem alloc] initWithType:BFDetailItemTypeMembers value:[NSString stringWithFormat:@"%ld", (long)camp.attributes.summaries.counts.members] action:^{
                    [Launcher openCampMembersForCamp:self.camp];
                }];
                if (self.camp.attributes.status.visibility.isPrivate && ![self.camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_MEMBER]) {
                    members.selectable = false;
                }
                [details addObject:members];
            }
        }
        
        self.detailsCollectionView.hidden = (details.count == 0);
        
        if (![self.detailsCollectionView isHidden]) {
            self.detailsCollectionView.details = [details copy];
        }
    }
}

+ (CGFloat)heightForCamp:(Camp *)camp isLoading:(BOOL)loading {
    CGFloat maxWidth = [UIScreen mainScreen].bounds.size.width - (CAMP_HEADER_EDGE_INSETS.left + CAMP_HEADER_EDGE_INSETS.right);

    // knock out all the required bits first
    CGFloat height = CAMP_HEADER_EDGE_INSETS.top + CAMP_HEADER_AVATAR_SIZE + CAMP_HEADER_AVATAR_BOTTOM_PADDING;

    CGRect textLabelRect = [(camp.attributes.details.title.length > 0 ? camp.attributes.details.title : @"Unkown Camp") boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:CAMP_HEADER_NAME_FONT} context:nil];
    CGFloat campTitleHeight = ceilf(textLabelRect.size.height);
    height = height + campTitleHeight;

    CGRect campTagRect = [[NSString stringWithFormat:@"#%@", camp.attributes.details.identifier] boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:CAMP_HEADER_TAG_FONT} context:nil];
    CGFloat campTagHeight = ceilf(campTagRect.size.height);
    height = height + CAMP_HEADER_NAME_BOTTOM_PADDING + campTagHeight;

    if (camp.attributes.details.theDescription.length > 0) {
        NSMutableAttributedString *attrString = [[NSMutableAttributedString  alloc] initWithString:camp.attributes.details.theDescription];
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:3.f];
        [style setAlignment:NSTextAlignmentCenter];
        [attrString addAttribute:NSParagraphStyleAttributeName
                           value:style
                           range:NSMakeRange(0, attrString.length)];
        [attrString addAttribute:NSFontAttributeName value:CAMP_HEADER_DESCRIPTION_FONT range:NSMakeRange(0, attrString.length)];
        
        CGRect descriptionRect = [attrString boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)  context:nil];
        CGFloat campDescriptionHeight = ceilf(descriptionRect.size.height);
        height = height + CAMP_HEADER_TAG_BOTTOM_PADDING + campDescriptionHeight;
    }

    if (camp.attributes.details.identifier.length > 0 || camp.identifier.length > 0) {
        CGFloat detailsHeight = 0;
        NSMutableArray *details = [[NSMutableArray alloc] init];
        
        if (camp.attributes.status.visibility != nil) {
            BFDetailItem *visibility = [[BFDetailItem alloc] initWithType:(camp.attributes.status.visibility.isPrivate ? BFDetailItemTypePrivacyPrivate : BFDetailItemTypePrivacyPublic) value:(camp ? @"Private" : @"Public") action:nil];
            [details addObject:visibility];
        }
        
        if (camp.attributes.summaries.counts != nil) {
            BFDetailItem *members = [[BFDetailItem alloc] initWithType:BFDetailItemTypeMembers value:[NSString stringWithFormat:@"%ld", (long)camp.attributes.summaries.counts.members] action:nil];
            [details addObject:members];
        }
                
        if (details.count > 0) {
            BFDetailsCollectionView *detailCollectionView = [[BFDetailsCollectionView alloc] initWithFrame:CGRectMake(CAMP_HEADER_EDGE_INSETS.left, 0, [UIScreen mainScreen].bounds.size.width - CAMP_HEADER_EDGE_INSETS.left - CAMP_HEADER_EDGE_INSETS.right, 16)];
            detailCollectionView.delegate = detailCollectionView;
            detailCollectionView.dataSource = detailCollectionView;
            [detailCollectionView setDetails:details];
            
            detailsHeight = CAMP_HEADER_DETAILS_EDGE_INSETS.top + detailCollectionView.collectionViewLayout.collectionViewContentSize.height;
            height = height + (camp.attributes.details.theDescription.length > 0 ? CAMP_HEADER_DESCRIPTION_BOTTOM_PADDING : CAMP_HEADER_TAG_BOTTOM_PADDING) + detailsHeight;
        }
    }
    
    if (camp.identifier.length > 0 || loading) {
        CGFloat userPrimaryActionHeight = CAMP_HEADER_FOLLOW_BUTTON_TOP_PADDING + 36;
        height = height + userPrimaryActionHeight;
    }

    // add bottom padding and line separator
    height = height + CAMP_HEADER_EDGE_INSETS.bottom + (1 / [UIScreen mainScreen].scale);

    return height;
}

@end
