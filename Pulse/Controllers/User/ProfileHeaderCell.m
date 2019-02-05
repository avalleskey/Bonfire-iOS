//
//  ProfileHeaderself.m
//  Pulse
//
//  Created by Austin Valleskey on 10/1/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ProfileHeaderCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <HapticHelper/HapticHelper.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Session.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import <Tweaks/FBTweakInline.h>

@implementation ProfileHeaderCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        // general cell styling
        self.backgroundColor = [UIColor whiteColor];
        self.separatorInset = UIEdgeInsetsMake(0, 62, 0, 0);
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.profilePicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, PROFILE_HEADER_EDGE_INSETS.top, PROFILE_HEADER_AVATAR_SIZE, PROFILE_HEADER_AVATAR_SIZE)];
        self.profilePicture.center = CGPointMake(self.contentView.frame.size.width / 2, self.profilePicture.center.y);
        [self.contentView addSubview:self.profilePicture];
        
        self.followingButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.followingButton.frame = CGRectMake(PROFILE_HEADER_EDGE_INSETS.left, 0, self.profilePicture.frame.origin.x - PROFILE_HEADER_EDGE_INSETS.left, 34);
        self.followingButton.center = CGPointMake(self.followingButton.center.x, self.profilePicture.center.y);
        [self.followingButton setTitleColor:[UIColor colorWithWhite:0.33f alpha:1] forState:UIControlStateNormal];
        [self.followingButton.titleLabel setFont:[UIFont systemFontOfSize:16.f weight:UIFontWeightBold]];
        self.followingButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.followingButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.followingButton setTitle:@"0\nfollowing" forState:UIControlStateNormal];
        [self.followingButton bk_whenTapped:^{
            [[Launcher sharedInstance] openProfileUsersFollowing:self.user];
        }];
        [self.contentView addSubview:self.followingButton];
        
        self.campsButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.campsButton.frame = CGRectMake(self.profilePicture.frame.origin.x + self.profilePicture.frame.size.width, 0, self.followingButton.frame.size.width, 34);
        self.campsButton.center = CGPointMake(self.campsButton.center.x, self.profilePicture.center.y);
        [self.campsButton setTitleColor:[UIColor colorWithWhite:0.33f alpha:1] forState:UIControlStateNormal];
        [self.campsButton.titleLabel setFont:self.followingButton.titleLabel.font];
        self.campsButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.campsButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.campsButton setTitle:@"0\ncamps" forState:UIControlStateNormal];
        [self.campsButton bk_whenTapped:^{
            [[Launcher sharedInstance] openProfileCampsJoined:self.user];
        }];
        [self.contentView addSubview:self.campsButton];
        
        self.textLabel.font = PROFILE_HEADER_DISPLAY_NAME_FONT;
        self.textLabel.textColor = [UIColor colorWithWhite:0.07f alpha:1];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.textLabel.backgroundColor = [UIColor clearColor];
        
        // username
        self.detailTextLabel.font = PROFILE_HEADER_USERNAME_FONT;
        self.detailTextLabel.textAlignment = NSTextAlignmentCenter;
        self.detailTextLabel.textColor = [UIColor colorWithWhite:0.47f alpha:1];
        self.detailTextLabel.numberOfLines = 0;
        self.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        
        // bio
        self.bioLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, 0, self.frame.size.width - 48, 18)];
        self.bioLabel.font = PROFILE_HEADER_BIO_FONT;
        self.bioLabel.textColor = [UIColor colorWithWhite:0.33f alpha:1];
        self.bioLabel.numberOfLines = 0;
        self.bioLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.contentView addSubview:self.bioLabel];
        
        self.detailsLabel = [[BFDetailsLabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 16)];
        self.detailsLabel.layer.cornerRadius = 4.f;
        self.detailsLabel.layer.masksToBounds = true;
        [self.contentView addSubview:self.detailsLabel];
        
        self.followButton = [UserFollowButton buttonWithType:UIButtonTypeCustom];
        
        [self.followButton bk_whenTapped:^{
            // update state if possible
            if ([self.followButton.status isEqualToString:USER_STATUS_ME]) {
                [[Launcher sharedInstance] openEditProfile];
            }
            else if ([self.followButton.status isEqualToString:USER_STATUS_FOLLOWS] ||
                     [self.followButton.status isEqualToString:USER_STATUS_FOLLOW_BOTH]) {
                // UNFOLLOW User
                if ([self.followButton.status isEqualToString:USER_STATUS_FOLLOWS]) {
                    [self.followButton updateStatus:USER_STATUS_NO_RELATION];
                }
                else if ([self.followButton.status isEqualToString:USER_STATUS_FOLLOW_BOTH]) {
                    [self.followButton updateStatus:USER_STATUS_FOLLOWED];
                }
                [self updateUserStatus];
                
                [[Session sharedInstance] unfollowUser:self.user completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // NSLog(@"success unfollowing user");
                    }
                }];
            }
            else if ([self.followButton.status isEqualToString:USER_STATUS_FOLLOWED] ||
                     [self.followButton.status isEqualToString:USER_STATUS_NO_RELATION] ||
                     self.followButton.status.length == 0) {
                // follow the user
                
                // TODO: Add private user check -> "Requested"
                // (self.user.attributes.status.visibility.isPrivate) &&
                // ![self.followButton.status isEqualToString:USER_STATUS_FOLLOWED]
                
                if ([self.followButton.status isEqualToString:USER_STATUS_FOLLOWED]) {
                    [self.followButton updateStatus:USER_STATUS_FOLLOW_BOTH];
                }
                else {
                    [self.followButton updateStatus:USER_STATUS_FOLLOWS];
                }
                [self updateUserStatus];
                
                [HapticHelper generateFeedback:FeedbackType_Notification_Success];
                
                [[Session sharedInstance] followUser:self.user completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // NSLog(@"success following user");
                    }
                }];
            }
            else if ([self.followButton.status isEqualToString:USER_STATUS_BLOCKED]) {
                // show alert maybe? --> ideally we don't even show the button.
            }
        }];
        [self.contentView addSubview:self.followButton];
        
        self.lineSeparator = [[UIView alloc] init];
        self.lineSeparator.backgroundColor = [UIColor separatorColor];
        [self.contentView addSubview:self.lineSeparator];
    }
    return self;
}

- (void)updateUserStatus {
    UserContext *context = [[UserContext alloc] initWithDictionary:[self.user.attributes.context toDictionary] error:nil];
    context.status = self.followButton.status;
    self.user.attributes.context = context;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UserContextUpdated" object:self.user];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat bottomY;
    
    CGFloat maxWidth = self.frame.size.width - (PROFILE_HEADER_EDGE_INSETS.left + PROFILE_HEADER_EDGE_INSETS.right);
    
    // line separator
    self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, (1 / [UIScreen mainScreen].scale));
    
    // profile picture
    self.profilePicture.center = CGPointMake(self.contentView.frame.size.width / 2, self.profilePicture.center.y);
    bottomY = self.profilePicture.frame.origin.y + self.profilePicture.frame.size.height;
    
    // stats to the left/right of the profile picture
    CGRect followingStatRect = self.followingButton.frame;
    followingStatRect.origin.x = (PROFILE_HEADER_EDGE_INSETS.left / 2);
    followingStatRect.size.width = self.profilePicture.frame.origin.x - followingStatRect.origin.x;
    self.followingButton.frame = followingStatRect;
    CGRect campsStatRect = self.campsButton.frame;
    campsStatRect.size.width = followingStatRect.size.width;
    campsStatRect.origin.x = self.frame.size.width - campsStatRect.size.width - (PROFILE_HEADER_EDGE_INSETS.left / 2);
    self.campsButton.frame = campsStatRect;
    
    // text label
    CGRect textLabelRect = [self.textLabel.text boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.textLabel.font} context:nil];
    self.textLabel.frame = CGRectMake(PROFILE_HEADER_EDGE_INSETS.left, bottomY + PROFILE_HEADER_AVATAR_BOTTOM_PADDING, maxWidth, ceilf(textLabelRect.size.height));
    bottomY = self.textLabel.frame.origin.y + self.textLabel.frame.size.height;
    
    // detail text label
    CGRect detailLabelRect = [self.detailTextLabel.text boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.detailTextLabel.font} context:nil];
    self.detailTextLabel.frame = CGRectMake(self.textLabel.frame.origin.x, bottomY + PROFILE_HEADER_DISPLAY_NAME_BOTTOM_PADDING, self.textLabel.frame.size.width, ceilf(detailLabelRect.size.height));
    bottomY = self.detailTextLabel.frame.origin.y + self.detailTextLabel.frame.size.height;
    
    BOOL hasBio = self.bioLabel.attributedText.length > 0;
    self.bioLabel.hidden = !hasBio;
    if (hasBio) {
        CGRect bioLabelRect = [self.bioLabel.attributedText boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
        self.bioLabel.frame = CGRectMake(self.textLabel.frame.origin.x, bottomY + PROFILE_HEADER_USERNAME_BOTTOM_PADDING, self.textLabel.frame.size.width, ceilf(bioLabelRect.size.height));
        bottomY = self.bioLabel.frame.origin.y + self.bioLabel.frame.size.height;
    }
    
    BOOL hasDetails = self.detailsLabel.attributedText.length > 0;
    self.detailsLabel.hidden = !hasDetails;
    if (hasDetails) {
        self.detailsLabel.frame = CGRectMake(self.textLabel.frame.origin.x, bottomY + (hasBio ? PROFILE_HEADER_BIO_BOTTOM_PADDING : PROFILE_HEADER_USERNAME_BOTTOM_PADDING) + PROFILE_HEADER_DETAILS_EDGE_INSETS.top, self.textLabel.frame.size.width, self.detailsLabel.frame.size.height);
        bottomY = self.detailsLabel.frame.origin.y + self.detailsLabel.frame.size.height;
    }
    
    self.followButton.frame = CGRectMake(PROFILE_HEADER_EDGE_INSETS.left, bottomY + PROFILE_HEADER_FOLLOW_BUTTON_TOP_PADDING, maxWidth, 36);
}

- (BOOL)isCurrentUser {
    return [self.user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier];
}

- (void)setUser:(User *)user {
    if (user != _user) {
        _user = user;
        
        self.tintColor = [[user.attributes.details.color lowercaseString] isEqualToString:@"ffffff"] ? [UIColor colorWithWhite:0.2f alpha:1] : [UIColor fromHex:user.attributes.details.color];
        
        self.profilePicture.user = user;
        
        // display name
        if (user.attributes.details.displayName.length > 0) {
            self.textLabel.text = user.attributes.details.displayName;
        }
        else if (user.attributes.details.identifier.length > 0) {
            self.textLabel.text = [NSString stringWithFormat:@"@%@", user.attributes.details.identifier];
        }
        else {
            self.textLabel.text = [NSString stringWithFormat:@"@%@", user.attributes.details.identifier];
        }
        
        // username
        self.detailTextLabel.text = [NSString stringWithFormat:@"@%@", user.attributes.details.identifier];
        
        // bio
        if (user.attributes.details.bio.length > 0) {
            NSMutableAttributedString *attrString = [[NSMutableAttributedString  alloc] initWithString:user.attributes.details.bio];
            NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
            [style setLineSpacing:3.f];
            [style setAlignment:NSTextAlignmentCenter];
            [attrString addAttribute:NSParagraphStyleAttributeName
                               value:style
                               range:NSMakeRange(0, attrString.length)];
            [attrString addAttribute:NSFontAttributeName value:PROFILE_HEADER_BIO_FONT range:NSMakeRange(0, attrString.length)];
            [attrString addAttribute:NSForegroundColorAttributeName value:self.bioLabel.textColor range:NSMakeRange(0, attrString.length)];
            self.bioLabel.attributedText = attrString;
        }
        
        NSMutableAttributedString * (^attributedStatString)(NSInteger s, NSString *l) = ^NSMutableAttributedString *(NSInteger s, NSString *l) {
            NSMutableAttributedString *attrString = [[NSMutableAttributedString  alloc] initWithString:[NSString stringWithFormat:@"%ld\n%@", (long)s, l]];
            NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
            [style setAlignment:NSTextAlignmentCenter];
            [attrString addAttribute:NSParagraphStyleAttributeName
                               value:style
                               range:NSMakeRange(0, attrString.length)];
            // style stat
            [attrString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:self.campsButton.titleLabel.font.pointSize weight:UIFontWeightBold] range:NSMakeRange(0, [NSString stringWithFormat:@"%ld", (long)s].length)];
            [attrString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:(s == 0 ? 0.6f : 0.33f) alpha:1] range:NSMakeRange(0, [NSString stringWithFormat:@"%ld", (long)s].length)];
            // style label
            [attrString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:self.campsButton.titleLabel.font.pointSize weight:UIFontWeightMedium] range:NSMakeRange([NSString stringWithFormat:@"%ld", (long)s].length + 1, l.length)];
            [attrString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.6f alpha:1] range:NSMakeRange([NSString stringWithFormat:@"%ld", (long)s].length + 1, l.length)];
            
            return attrString;
        };
        
        NSInteger stat = user.attributes.summaries.counts.following;
        NSString *statLabel = @"following";
        
        NSInteger camps;
        if (user.attributes.summaries.counts.rooms) {
            camps = user.attributes.summaries.counts.rooms;
        }
        else {
            camps = 0;
        }
        NSString *campsString = (camps == 1) ? @"camp" : @"camps";
        
        [UIView performWithoutAnimation:^{
            [self.campsButton setAttributedTitle:attributedStatString(camps, campsString) forState:UIControlStateNormal];
            [self.campsButton layoutIfNeeded];
            
            [self.followingButton setAttributedTitle:attributedStatString(stat, statLabel) forState:UIControlStateNormal];
            [self.followingButton layoutIfNeeded];
        }];
        
        NSMutableArray *details = [[NSMutableArray alloc] init];
        if (user.attributes.details.location) {
            [details addObject:[BFDetailsLabel BFDetailWithType:BFDetailTypeLocation value:user.attributes.details.location.value action:nil]];
        }
        if (user.attributes.details.website) {
            [details addObject:[BFDetailsLabel BFDetailWithType:BFDetailTypeWebsite value:user.attributes.details.website.value action:^(NSString *tappedString) {
                [[Launcher sharedInstance] openURL:user.attributes.details.website.value];
            }]];
        }
        
        self.detailsLabel.details = details;
    }
}

@end
