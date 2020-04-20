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
#import "NSString+Validation.h"
#import "BFAlertController.h"
#import "NSDate+NVTimeAgo.h"
#import "UIView+BFEffects.h"

#define USER_CONTEXT_BUBBLE_TAG_NEW_USER 1
#define USER_CONTEXT_BUBBLE_TAG_BIRTHDAY 2
#define USER_CONTEXT_BUBBLE_TAG_CAMP_CRAZY 3
#define USER_CONTEXT_BUBBLE_TAG_EDIT 4

@implementation ProfileHeaderCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor contentBackgroundColor];
        
        self.clipsToBounds = NO;                        //cell's view
        self.contentView.clipsToBounds = NO;            //contentView
        self.contentView.superview.clipsToBounds = NO;  //scrollView
                
        self.profilePictureContainer = [[UIView alloc] initWithFrame:CGRectMake(0, PROFILE_HEADER_EDGE_INSETS.top - PROFILE_HEADER_AVATAR_BORDER_WIDTH, PROFILE_HEADER_AVATAR_SIZE + (PROFILE_HEADER_AVATAR_BORDER_WIDTH * 2), PROFILE_HEADER_AVATAR_SIZE + (PROFILE_HEADER_AVATAR_BORDER_WIDTH * 2))];
        self.profilePictureContainer.backgroundColor = [UIColor contentBackgroundColor];
        self.profilePictureContainer.layer.cornerRadius = self.profilePictureContainer.frame.size.height / 2;
        self.profilePictureContainer.layer.masksToBounds = false;
        self.profilePictureContainer.layer.shadowColor = [UIColor blackColor].CGColor;
        self.profilePictureContainer.layer.shadowOffset = CGSizeMake(0, 1);
        self.profilePictureContainer.layer.shadowRadius = 2.f;
        self.profilePictureContainer.layer.shadowOpacity = 0.12;
        self.profilePictureContainer.center = CGPointMake(self.contentView.frame.size.width / 2, self.profilePictureContainer.center.y);
        [self addSubview:self.profilePictureContainer];
        
        self.profilePicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(PROFILE_HEADER_AVATAR_BORDER_WIDTH, PROFILE_HEADER_AVATAR_BORDER_WIDTH, PROFILE_HEADER_AVATAR_SIZE, PROFILE_HEADER_AVATAR_SIZE)];
        self.profilePicture.dimsViewOnTap = true;
        [self.profilePicture bk_whenTapped:^{
            BOOL hasPicture = (self.profilePicture.user.attributes.media.avatar.suggested.url.length > 0);
            
            void(^expandProfilePic)(void) = ^() {
                [Launcher expandImageView:self.profilePicture.imageView];
            };
            void(^openEditProfile)(void) = ^() {
                [Launcher openEditProfile];
            };
            
            if ([self.user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
                if (hasPicture) {
                    // confirm action
                    BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:nil message:nil preferredStyle:BFAlertControllerStyleActionSheet];
                    
                    BFAlertAction *action1 = [BFAlertAction actionWithTitle:@"View User Photo" style:BFAlertActionStyleDefault handler:^{
                        expandProfilePic();
                    }];
                    [actionSheet addAction:action1];
                    
                    BFAlertAction *action2 = [BFAlertAction actionWithTitle:@"Edit Profile" style:BFAlertActionStyleDefault handler:^{
                        openEditProfile();
                    }];
                    [actionSheet addAction:action2];
                    
                    BFAlertAction *cancelActionSheet = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
                    [actionSheet addAction:cancelActionSheet];
                    
                    [[Launcher topMostViewController] presentViewController:actionSheet animated:true completion:nil];
                }
                else {
                    openEditProfile();
                }
            }
            else if (hasPicture) {
                expandProfilePic();
            }
        }];
        for (id interaction in self.profilePicture.interactions) {
            if (@available(iOS 13.0, *)) {
                if ([interaction isKindOfClass:[UIContextMenuInteraction class]]) {
                    [self.profilePicture removeInteraction:interaction];
                }
            }
        }
        [self.profilePictureContainer addSubview:self.profilePicture];
        
        self.campAvatarReasonView = [[UIView alloc] initWithFrame:CGRectMake(self.profilePicture.frame.size.width - 40 + 6, self.profilePicture.frame.size.height - 40 + 6, 40, 40)];
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
                
                if (self.campAvatarReasonView.tag == USER_CONTEXT_BUBBLE_TAG_EDIT) {
                    [Launcher openEditProfile];
                }
                else if (self.campAvatarReasonView.tag == USER_CONTEXT_BUBBLE_TAG_NEW_USER) {
                    title = @"New User";
                    message = [NSString stringWithFormat:@"%@ joined %@.", [self isCurrentUser] ? @"You" : @"This user", [NSDate mysqlDatetimeFormattedAsTimeAgo:self.user.attributes.createdAt withForm:TimeAgoLongForm]];
                }
                else if (self.campAvatarReasonView.tag == USER_CONTEXT_BUBBLE_TAG_BIRTHDAY) {
                    title = [self isCurrentUser] ? @"Happy Birthday!" : @"Birthday";
                    message = [self isCurrentUser] ? @"From all of us at Bonfire,\nwe hope you have a great one!" : @"Today is their birthday!";
                    
                    if (![self isCurrentUser]) {
                        cta = [BFAlertAction actionWithTitle:@"Say Happy Birthday" style:BFAlertActionStyleDefault handler:^{
                            [Launcher openComposePost:nil inReplyTo:nil withMessage:[NSString stringWithFormat:@"@%@ ", self.user.attributes.identifier] media:nil quotedObject:nil];
                        }];
                    }
                }
                else if (self.campAvatarReasonView.tag == USER_CONTEXT_BUBBLE_TAG_CAMP_CRAZY) {
                    title = @"Crazy for Camps";
                    if (self.user.attributes.summaries.counts.camps >= 100) {
                        message = [self isCurrentUser] ? @"You have joined 100 or more Camps." : @"This user has joined 100 or more Camps.";
                    }
                    else {
                        message = [self isCurrentUser] ? @"You have joined 50 or more Camps." : @"This user has joined 50 or more Camps.";
                    }
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
        [self addSubview:self.campAvatarReasonView];
        
        self.campAvatarReasonLabel = [[UILabel alloc] initWithFrame:self.campAvatarReasonView.bounds];
        self.campAvatarReasonLabel.textAlignment = NSTextAlignmentCenter;
        self.campAvatarReasonLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightSemibold];
        self.campAvatarReasonLabel.text = @"🆕";
        [self.campAvatarReasonView addSubview:self.campAvatarReasonLabel];
        
        self.campAvatarReasonImageView = [[UIImageView alloc] initWithFrame:self.campAvatarReasonView.bounds];
        self.campAvatarReasonImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.campAvatarReasonImageView.hidden = true;
        self.campAvatarReasonImageView.layer.cornerRadius = self.campAvatarReasonView.layer.cornerRadius;
        self.campAvatarReasonImageView.layer.masksToBounds = true;
        [self.campAvatarReasonView addSubview:self.campAvatarReasonImageView];
        
        self.textLabel.font = PROFILE_HEADER_DISPLAY_NAME_FONT;
        self.textLabel.textColor = [UIColor bonfirePrimaryColor];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.textLabel.backgroundColor = [UIColor clearColor];
        
        self.detailTextLabel.font = [UIFont systemFontOfSize:PROFILE_HEADER_USERNAME_FONT.pointSize weight:UIFontWeightHeavy];
        self.detailTextLabel.textAlignment = NSTextAlignmentCenter;
        self.detailTextLabel.textColor = [UIColor bonfireSecondaryColor];
        self.detailTextLabel.numberOfLines = 0;
        self.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        self.detailTextLabel.userInteractionEnabled = true;
        [self.detailTextLabel bk_whenTapped:^{
            if ([self.user isBetaTester]) {
                BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:@"Early Adopter" message:([self isCurrentUser] ? @"Thank you for being a part of the Bonfire beta!" : @"This user was part of the limited Bonfire beta.") preferredStyle:BFAlertControllerStyleActionSheet];
                
                BFAlertAction *cancelActionSheet = [BFAlertAction actionWithTitle:@"Close" style:BFAlertActionStyleCancel handler:nil];
                [actionSheet addAction:cancelActionSheet];
                                
                [[Launcher topMostViewController] presentViewController:actionSheet animated:true completion:^{
                    [[[UIApplication sharedApplication] keyWindow] showEffect:BFEffectTypeBalloons completion:nil];
                }];
            }
        }];
        
        // bio
        self.bioLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(24, 0, self.frame.size.width - 48, 18)];
        self.bioLabel.extendsLinkTouchArea = false;
        self.bioLabel.userInteractionEnabled = true;
        self.bioLabel.font = PROFILE_HEADER_BIO_FONT;
        self.bioLabel.textAlignment = NSTextAlignmentCenter;
        self.bioLabel.textColor = [UIColor bonfirePrimaryColor];
        self.bioLabel.numberOfLines = 0;
        self.bioLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.bioLabel.delegate = self;
        
        // bio link styling
        NSMutableDictionary *mutableActiveLinkAttributes = [NSMutableDictionary dictionary];
        [mutableActiveLinkAttributes setValue:[NSNumber numberWithBool:NO] forKey:(NSString *)kCTUnderlineStyleAttributeName];
        [mutableActiveLinkAttributes setValue:(__bridge id)[[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.1f] CGColor] forKey:(NSString *)kTTTBackgroundFillColorAttributeName];
        [mutableActiveLinkAttributes setValue:[NSNumber numberWithFloat:4.0f] forKey:(NSString *)kTTTBackgroundCornerRadiusAttributeName];
        [mutableActiveLinkAttributes setValue:[NSNumber numberWithFloat:0] forKey:(NSString *)kTTTBackgroundLineWidthAttributeName];
        self.bioLabel.activeLinkAttributes = mutableActiveLinkAttributes;
        
        // update tint color
        NSMutableDictionary *mutableLinkAttributes = [NSMutableDictionary dictionary];
        [mutableLinkAttributes setObject:[UIColor linkColor] forKey:(__bridge NSString *)kCTForegroundColorAttributeName];
        self.bioLabel.linkAttributes = mutableLinkAttributes;
        
        [self.contentView addSubview:self.bioLabel];
        
        self.detailsCollectionView = [[BFDetailsCollectionView alloc] initWithFrame:CGRectMake(PROFILE_HEADER_EDGE_INSETS.left, 0, [UIScreen mainScreen].bounds.size.width - PROFILE_HEADER_EDGE_INSETS.left - PROFILE_HEADER_EDGE_INSETS.right, 16)];
        [self.contentView addSubview:self.detailsCollectionView];
        
        self.actionButton = [UserFollowButton buttonWithType:UIButtonTypeCustom];
        [self.actionButton bk_whenTapped:^{
            // update state if possible
            if ([self.actionButton.status isEqualToString:USER_STATUS_ME]) {
                [Launcher openInviteFriends:nil];
            }
            else if ([self.actionButton.status isEqualToString:USER_STATUS_FOLLOWS] ||
                     [self.actionButton.status isEqualToString:USER_STATUS_FOLLOW_BOTH]) {
                // UNFOLLOW User
                if ([self.actionButton.status isEqualToString:USER_STATUS_FOLLOWS]) {
                    [self.actionButton updateStatus:USER_STATUS_NO_RELATION];
                }
                else if ([self.actionButton.status isEqualToString:USER_STATUS_FOLLOW_BOTH]) {
                    [self.actionButton updateStatus:USER_STATUS_FOLLOWED];
                }
                [self updateUserStatus];
                
                [BFAPI unfollowUser:self.user completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // NSLog(@"success unfollowing user");
                    }
                }];
            }
            else if ([self.actionButton.status isEqualToString:USER_STATUS_FOLLOWED] ||
                     [self.actionButton.status isEqualToString:USER_STATUS_NO_RELATION] ||
                     self.actionButton.status.length == 0) {
                // follow the user
                if ([self.actionButton.status isEqualToString:USER_STATUS_FOLLOWED]) {
                    [self.actionButton updateStatus:USER_STATUS_FOLLOW_BOTH];
                }
                else {
                    [self.actionButton updateStatus:USER_STATUS_FOLLOWS];
                }
                [self updateUserStatus];
                
                [HapticHelper generateFeedback:FeedbackType_Notification_Success];
                
                [BFAPI followUser:self.user completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // NSLog(@"success following user");
                    }
                }];
            }
            else if ([self.actionButton.status isEqualToString:USER_STATUS_BLOCKED]) {
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
                [Launcher openDebugView:self.user];
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

- (void)attributedLabel:(TTTAttributedLabel *)label
   didSelectLinkWithURL:(NSURL *)url {
    NSLog(@"did select link with url: %@", url);
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        if ([url.scheme isEqualToString:LOCAL_APP_URI]) {
            // local url
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                NSLog(@"opened url!");
            }];
        }
        else {
            // extern url
            [Launcher openURL:url.absoluteString];
        }
    }
}

- (void)updateUserStatus {
    BFContext *context = [[BFContext alloc] initWithDictionary:[self.user.attributes.context toDictionary] error:nil];
    context.me.status = self.actionButton.status;
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
    
    // profile picture
    self.profilePictureContainer.center = CGPointMake(self.contentView.frame.size.width / 2, self.profilePictureContainer.center.y);
    bottomY = PROFILE_HEADER_EDGE_INSETS.top + self.profilePictureContainer.frame.size.height;
    
    if (![self.campAvatarReasonView isHidden]) {
        self.campAvatarReasonView.frame = CGRectMake(self.profilePictureContainer.frame.origin.x + self.profilePictureContainer.frame.size.width - 40 - 6, self.profilePictureContainer.frame.origin.y + self.profilePictureContainer.frame.size.height - 40 - 6, 40, 40);
    }
    
    CGFloat contentViewOffset = self.profilePictureContainer.frame.origin.y + self.profilePicture.frame.origin.y +  ceilf(self.profilePicture.frame.size.height * 0.65);
    self.contentView.frame = CGRectMake(0, contentViewOffset, self.frame.size.width, self.frame.size.height - contentViewOffset);
    
    // subtract content view inset
    bottomY -= self.contentView.frame.origin.y;
    
    // text label
    CGRect textLabelRect = [self.textLabel.attributedText boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
    self.textLabel.frame = CGRectMake(self.frame.size.width / 2 - maxWidth / 2, bottomY + PROFILE_HEADER_AVATAR_BOTTOM_PADDING, maxWidth, ceilf(textLabelRect.size.height));
    bottomY = self.textLabel.frame.origin.y + self.textLabel.frame.size.height + PROFILE_HEADER_DISPLAY_NAME_BOTTOM_PADDING;
    
    // detail text label
    CGRect detailLabelRect = [self.detailTextLabel.text boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.detailTextLabel.font} context:nil];
    self.detailTextLabel.frame = CGRectMake(self.textLabel.frame.origin.x, bottomY, self.textLabel.frame.size.width, ceilf(detailLabelRect.size.height));
    bottomY = self.detailTextLabel.frame.origin.y + self.detailTextLabel.frame.size.height;
    
    if (![self.bioLabel isHidden]) {
        CGRect bioLabelRect = [self.bioLabel.attributedText boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
        self.bioLabel.frame = CGRectMake(self.textLabel.frame.origin.x, PROFILE_HEADER_USERNAME_BOTTOM_PADDING  + bottomY, self.textLabel.frame.size.width, ceilf(bioLabelRect.size.height));
        bottomY = self.bioLabel.frame.origin.y + self.bioLabel.frame.size.height;
    }
    
    if (![self.detailsCollectionView isHidden] && self.detailsCollectionView.details.count > 0) {
        self.detailsCollectionView.frame = CGRectMake(PROFILE_HEADER_EDGE_INSETS.left, bottomY + ([self.bioLabel isHidden] ? PROFILE_HEADER_USERNAME_BOTTOM_PADDING : PROFILE_HEADER_BIO_BOTTOM_PADDING), self.frame.size.width - (PROFILE_HEADER_EDGE_INSETS.left + PROFILE_HEADER_EDGE_INSETS.right), self.detailsCollectionView.collectionViewLayout.collectionViewContentSize.height);
        bottomY = self.detailsCollectionView.frame.origin.y + self.detailsCollectionView.frame.size.height;
    }
    
    self.actionButton.frame = CGRectMake(12, PROFILE_HEADER_FOLLOW_BUTTON_TOP_PADDING + bottomY, self.frame.size.width - 24, 38);
    
    // line separator
    self.lineSeparator.frame = CGRectMake(0, self.lineSeparator.superview.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, (1 / [UIScreen mainScreen].scale));
}

- (BOOL)isCurrentUser {
    return [self.user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier];
}

- (void)setUser:(User *)user {
    if (user != _user) {
        _user = user;
                
        self.tintColor = [UIColor fromHex:user.attributes.color];
        
        self.profilePicture.user = user;
        
        // set camp indicator
        BOOL useText = false;
        BOOL useImage = false;

        NSDateComponents *components;
        if (user.attributes.createdAt.length > 0) {
            NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
                [inputFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
            NSDate *date = [inputFormatter dateFromString:user.attributes.createdAt];
            
            NSUInteger unitFlags = NSCalendarUnitDay;
            NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            components = [calendar components:unitFlags fromDate:date toDate:[NSDate new] options:0];
        }
        
        if (components && [components day] < 30) {
            useImage = true;
            self.campAvatarReasonImageView.image = [UIImage imageNamed:@"newIcon"];
            self.campAvatarReasonView.tag = USER_CONTEXT_BUBBLE_TAG_NEW_USER;
        }
        else if ([user isKindOfClass:[User class]] && [(User *)user isBirthday]) {
            useText = true;
            self.campAvatarReasonLabel.text = @"🥳";
            self.campAvatarReasonView.tag = USER_CONTEXT_BUBBLE_TAG_BIRTHDAY;
        }
        else if (user.attributes.summaries.counts.camps >= 100) {
            useImage = true;
            self.campAvatarReasonImageView.image = [UIImage imageNamed:@"crazyCamps100"];
            self.campAvatarReasonView.tag = USER_CONTEXT_BUBBLE_TAG_CAMP_CRAZY;
        }
        else if (user.attributes.summaries.counts.camps >= 50) {
            useImage = true;
            self.campAvatarReasonImageView.image = [UIImage imageNamed:@"crazyCamps50"];
            self.campAvatarReasonView.tag = USER_CONTEXT_BUBBLE_TAG_CAMP_CRAZY;
        }
        self.campAvatarReasonView.hidden = !useText && !useImage;
        self.campAvatarReasonImageView.hidden = !useImage;
        self.campAvatarReasonLabel.hidden = !useText;
        
        // display name
        NSString *displayName;
        if (user.attributes.displayName.length > 0) {
            displayName = user.attributes.displayName;
        }
        else if (user.attributes.identifier.length > 0) {
            displayName = [NSString stringWithFormat:@"@%@", user.attributes.identifier];
        }
        else {
            displayName = @"Unknown User";
        }
        NSMutableAttributedString *displayNameAttributedString = [[NSMutableAttributedString alloc] initWithString:displayName attributes:@{NSFontAttributeName:PROFILE_HEADER_DISPLAY_NAME_FONT}];
        if ([user isVerified]) {
            NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
            [spacer addAttribute:NSFontAttributeName value:PROFILE_HEADER_DISPLAY_NAME_FONT range:NSMakeRange(0, spacer.length)];
            [displayNameAttributedString appendAttributedString:spacer];
            
            // verified icon ☑️
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.image = [UIImage imageNamed:@"verifiedIcon_large"];
            [attachment setBounds:CGRectMake(0, roundf(PROFILE_HEADER_DISPLAY_NAME_FONT.capHeight - attachment.image.size.height)/2.f-1, attachment.image.size.width, attachment.image.size.height)];
            
            NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
            [displayNameAttributedString appendAttributedString:attachmentString];
        }
//        else if ([user isBetaTester]) {
//            NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@"  "];
//            [spacer addAttribute:NSFontAttributeName value:PROFILE_HEADER_DISPLAY_NAME_FONT range:NSMakeRange(0, spacer.length)];
//            [displayNameAttributedString appendAttributedString:spacer];
//
//            // verified icon ☑️
//            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
//            attachment.image = [UIImage imageNamed:@"betaIcon_large"];
//            [attachment setBounds:CGRectMake(0, roundf(PROFILE_HEADER_DISPLAY_NAME_FONT.capHeight - attachment.image.size.height)/2.f-1, attachment.image.size.width, attachment.image.size.height)];
//
//            NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
//            [displayNameAttributedString appendAttributedString:attachmentString];
//        }
        self.textLabel.attributedText = displayNameAttributedString;
        
        // username
        if (user.attributes.identifier.length > 0) {
            NSMutableAttributedString *usernameAttributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"@%@", user.attributes.identifier] attributes:@{NSFontAttributeName:PROFILE_HEADER_USERNAME_FONT, NSForegroundColorAttributeName: [UIColor fromHex:user.attributes.color adjustForOptimalContrast:true]}];
            
            if ([user isBetaTester]) {
                NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@"  "];
                [spacer addAttribute:NSFontAttributeName value:PROFILE_HEADER_USERNAME_FONT range:NSMakeRange(0, spacer.length)];
                [usernameAttributedString appendAttributedString:spacer];
                
                // beta tag
                NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
                attachment.image = [UIImage imageNamed:@"betaTag"];
                
                CGFloat attachmentHeight = MIN(ceilf(PROFILE_HEADER_USERNAME_FONT.lineHeight * 0.9), ceilf(attachment.image.size.height));
                CGFloat attachmentWidth = ceilf(attachmentHeight * (attachment.image.size.width / attachment.image.size.height));
                
                [attachment setBounds:CGRectMake(0, roundf(PROFILE_HEADER_USERNAME_FONT.capHeight - attachmentHeight)/2.f - HALF_PIXEL, attachmentWidth, attachmentHeight)];
                
                NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
                [usernameAttributedString appendAttributedString:attachmentString];
            }
            
            self.detailTextLabel.attributedText = usernameAttributedString;
        }
        else {
            self.detailTextLabel.text = @"";
        }
        
        // bio
        self.bioLabel.hidden = user.attributes.bio.length == 0;
        if (![self.bioLabel isHidden]) {
            NSMutableAttributedString *attrString = [[NSMutableAttributedString  alloc] initWithString:user.attributes.bio];
            NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
            [style setLineSpacing:3.f];
            [style setAlignment:NSTextAlignmentCenter];
            [attrString addAttribute:NSParagraphStyleAttributeName
                               value:style
                               range:NSMakeRange(0, attrString.length)];
            [attrString addAttribute:NSFontAttributeName value:PROFILE_HEADER_BIO_FONT range:NSMakeRange(0, attrString.length)];
            [attrString addAttribute:NSForegroundColorAttributeName value:self.bioLabel.textColor range:NSMakeRange(0, attrString.length)];
            self.bioLabel.attributedText = attrString;
            
            NSArray *usernameRanges = [self.user.attributes.bio rangesForUsernameMatches];
            for (NSValue *value in usernameRanges) {
                NSRange range = [value rangeValue];
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://u/%@", LOCAL_APP_URI, [[self.user.attributes.bio substringWithRange:range] stringByReplacingOccurrencesOfString:@"@" withString:@""]]];
                [self.bioLabel addLinkToURL:url withRange:range];
            }
        
            NSArray *campRanges = [self.user.attributes.bio rangesForCampTagMatches];
            for (NSValue *value in campRanges) {
                NSRange range = [value rangeValue];
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://c/%@", LOCAL_APP_URI, [[self.user.attributes.bio substringWithRange:range] stringByReplacingOccurrencesOfString:@"#" withString:@""]]];
                [self.bioLabel addLinkToURL:url withRange:range];
            }
        }
        else {
            self.bioLabel.text = @"";
        }
        
        NSMutableArray *details = [[NSMutableArray alloc] init];
        if (user.attributes.location.displayText.length > 0) {
            BFDetailItem *item = [[BFDetailItem alloc] initWithType:BFDetailItemTypeLocation value:user.attributes.location.displayText action:nil];
            [details addObject:item];
        }
        if (user.attributes.website.displayUrl.length > 0) {
            BFDetailItem *item = [[BFDetailItem alloc] initWithType:BFDetailItemTypeWebsite value:user.attributes.website.displayUrl action:^{
                [Launcher openURL:user.attributes.website.actionUrl];
            }];
            [details addObject:item];
        }
        if (details.count == 0) {
            if ([user isCurrentIdentity]) {
                BFDetailItem *item = [[BFDetailItem alloc] initWithType:BFDetailItemTypeEdit value:(details.count==0?@"Edit Profile":@"") action:^{
                    [Launcher openEditProfile];
                }];
                [details addObject:item];
            }
            else if (user.attributes.createdAt.length > 0) {
                BFDetailItem *item = [[BFDetailItem alloc] initWithType:BFDetailItemTypeJoinedAt value:user.attributes.createdAt action:nil];
                [details addObject:item];
            }
        }
        
        self.detailsCollectionView.tintColor = self.detailTextLabel.textColor;
        self.detailsCollectionView.details = [details copy];
        
        self.detailsCollectionView.hidden = (details.count == 0);
    }
}

+ (CGFloat)heightForUser:(User *)user isLoading:(BOOL)loading {
    return [ProfileHeaderCell heightForUser:user isLoading:loading showDetails:true showActionButton:true];
}

+ (CGFloat)heightForUser:(User *)user isLoading:(BOOL)loading showDetails:(BOOL)details showActionButton:(BOOL)actionButton {
    CGFloat maxWidth = [UIScreen mainScreen].bounds.size.width - (PROFILE_HEADER_EDGE_INSETS.left + PROFILE_HEADER_EDGE_INSETS.right);
    
    // knock out all the required bits first
    CGFloat height = PROFILE_HEADER_EDGE_INSETS.top + (PROFILE_HEADER_AVATAR_SIZE + (PROFILE_HEADER_AVATAR_BORDER_WIDTH * 2)) + PROFILE_HEADER_AVATAR_BOTTOM_PADDING;
    
    // display name
    NSString *displayName;
    if (user.attributes.displayName.length > 0) {
        displayName = user.attributes.displayName;
    }
    else if (user.attributes.identifier.length > 0) {
        displayName = [NSString stringWithFormat:@"@%@", user.attributes.identifier];
    }
    else {
        displayName = @"Camper";
    }
    
    NSMutableAttributedString *displayNameAttributedString = [[NSMutableAttributedString alloc] initWithString:displayName attributes:@{NSFontAttributeName:PROFILE_HEADER_DISPLAY_NAME_FONT}];
    if ([user isVerified]) {
        NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
        [spacer addAttribute:NSFontAttributeName value:PROFILE_HEADER_DISPLAY_NAME_FONT range:NSMakeRange(0, spacer.length)];
        [displayNameAttributedString appendAttributedString:spacer];
        
        // verified icon ☑️
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = [UIImage imageNamed:@"verifiedIcon_large"];
        
        CGFloat attachmentHeight = MIN(ceilf(PROFILE_HEADER_DISPLAY_NAME_FONT.lineHeight * 0.9), ceilf(attachment.image.size.height));
        CGFloat attachmentWidth = ceilf(attachmentHeight * (attachment.image.size.width / attachment.image.size.height));
        
        [attachment setBounds:CGRectMake(0, roundf(PROFILE_HEADER_DISPLAY_NAME_FONT.capHeight - attachmentHeight)/2.f, attachmentWidth, attachmentHeight)];
        
        NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
        [displayNameAttributedString appendAttributedString:attachmentString];
    }
//    else if ([user isBetaTester]) {
//        NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
//        [spacer addAttribute:NSFontAttributeName value:PROFILE_HEADER_DISPLAY_NAME_FONT range:NSMakeRange(0, spacer.length)];
//        [displayNameAttributedString appendAttributedString:spacer];
//
//        // verified icon ☑️
//        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
//        attachment.image = [UIImage imageNamed:@"betaIcon_large"];
//        [attachment setBounds:CGRectMake(0, roundf(PROFILE_HEADER_DISPLAY_NAME_FONT.capHeight - attachment.image.size.height)/2.f-1, attachment.image.size.width, attachment.image.size.height)];
//
//        NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
//        [displayNameAttributedString appendAttributedString:attachmentString];
//    }

    CGRect textLabelRect = [displayNameAttributedString boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) context:nil];
    CGFloat userDisplayNameHeight = ceilf(textLabelRect.size.height);
    height += userDisplayNameHeight + PROFILE_HEADER_DISPLAY_NAME_BOTTOM_PADDING;
    
    NSMutableAttributedString *usernameAttributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"@%@", user.attributes.identifier] attributes:@{NSFontAttributeName:PROFILE_HEADER_USERNAME_FONT}];
    if ([user isBetaTester]) {
        NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@"  "];
        [spacer addAttribute:NSFontAttributeName value:PROFILE_HEADER_USERNAME_FONT range:NSMakeRange(0, spacer.length)];
        [usernameAttributedString appendAttributedString:spacer];
        
        // beta tag
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = [UIImage imageNamed:@"betaTag"];
        
        CGFloat attachmentHeight = MIN(ceilf(PROFILE_HEADER_USERNAME_FONT.lineHeight * 0.9), ceilf(attachment.image.size.height));
        CGFloat attachmentWidth = ceilf(attachmentHeight * (attachment.image.size.width / attachment.image.size.height));
        
        [attachment setBounds:CGRectMake(0, roundf(PROFILE_HEADER_USERNAME_FONT.capHeight - attachmentHeight)/2.f - HALF_PIXEL, attachmentWidth, attachmentHeight)];
        
        NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
        [usernameAttributedString appendAttributedString:attachmentString];
    }
    
    CGRect usernameRect = [usernameAttributedString boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) context:nil];
    CGFloat usernameHeight = ceilf(usernameRect.size.height);
    height += usernameHeight;
    
    if (details) {
        BOOL hasBio = user.attributes.bio.length > 0;
        if (hasBio) {
            NSMutableAttributedString *attrString = [[NSMutableAttributedString  alloc] initWithString:user.attributes.bio];
            NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
            [style setLineSpacing:3.f];
            [style setAlignment:NSTextAlignmentCenter];
            [attrString addAttribute:NSParagraphStyleAttributeName
                               value:style
                               range:NSMakeRange(0, attrString.length)];
            [attrString addAttribute:NSFontAttributeName value:PROFILE_HEADER_BIO_FONT range:NSMakeRange(0, attrString.length)];
            
            CGRect bioRect = [attrString boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)  context:nil];
            CGFloat bioHeight = ceilf(bioRect.size.height);
            height += PROFILE_HEADER_USERNAME_BOTTOM_PADDING + bioHeight;
        }
        
        if (loading || user.identifier) {
            NSMutableArray *details = [[NSMutableArray alloc] init];
            if (user.attributes.location.displayText.length > 0) {
                BFDetailItem *item = [[BFDetailItem alloc] initWithType:BFDetailItemTypeLocation value:user.attributes.location.displayText action:nil];
                [details addObject:item];
            }
            if (user.attributes.website.displayUrl.length > 0) {
                BFDetailItem *item = [[BFDetailItem alloc] initWithType:BFDetailItemTypeWebsite value:user.attributes.website.displayUrl action:nil];
                [details addObject:item];
            }
            if (details.count == 0) {
                if ([user isCurrentIdentity]) {
                    BFDetailItem *item = [[BFDetailItem alloc] initWithType:BFDetailItemTypeEdit value:(details.count==0?@"Edit Profile":@"") action:nil];
                    [details addObject:item];
                }
                else if (user.attributes.createdAt.length > 0) {
                    BFDetailItem *item = [[BFDetailItem alloc] initWithType:BFDetailItemTypeJoinedAt value:user.attributes.createdAt action:nil];
                    [details addObject:item];
                }
            }
            
            if (details.count > 0) {
                BFDetailsCollectionView *detailCollectionView = [[BFDetailsCollectionView alloc] initWithFrame:CGRectMake(PROFILE_HEADER_EDGE_INSETS.left, 0, [UIScreen mainScreen].bounds.size.width - PROFILE_HEADER_EDGE_INSETS.left - PROFILE_HEADER_EDGE_INSETS.right, 16)];
                detailCollectionView.delegate = detailCollectionView;
                detailCollectionView.dataSource = detailCollectionView;
                [detailCollectionView setDetails:details];
                
                CGFloat detailsHeight = detailCollectionView.collectionViewLayout.collectionViewContentSize.height;
                
                if (hasBio) {
                    height += PROFILE_HEADER_BIO_BOTTOM_PADDING;
                }
                
                height += (!hasBio ? PROFILE_HEADER_USERNAME_BOTTOM_PADDING : 0) + detailsHeight;
            }
        }
    }
    
    if (actionButton) {
        BOOL isCurrentUser = [user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier];
        
        CGFloat userPrimaryActionHeight = (!loading && user.attributes.context == nil && !isCurrentUser) ? 0 : PROFILE_HEADER_FOLLOW_BUTTON_TOP_PADDING + 38;
        height += userPrimaryActionHeight;
    }
    
    // add bottom padding and line separator
    height += PROFILE_HEADER_EDGE_INSETS.bottom;
    
    return height;
}

@end
