//
//  NotificationCell.m
//  Pulse
//
//  Created by Austin Valleskey on 12/5/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ActivityCell.h"
#import "UIColor+Palette.h"
#import "Session.h"
#import "NSDate+NVTimeAgo.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Launcher.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation ActivityCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        self.textLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.accessoryType = UITableViewCellAccessoryNone;
        
        self.profilePicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(12, 10, 48, 48)];
        self.profilePicture.openOnTap = true;
        [self.contentView addSubview:self.profilePicture];
        
        self.typeIndicator = [[UIImageView alloc] initWithFrame:CGRectMake(self.profilePicture.frame.origin.x + self.profilePicture.frame.size.width - 20 + 1, self.profilePicture.frame.origin.y + self.profilePicture.frame.size.height - 20 + 1, 20, 20)];
        self.typeIndicator.layer.cornerRadius = self.typeIndicator.frame.size.height / 2;
        self.typeIndicator.layer.masksToBounds = false;
        self.typeIndicator.backgroundColor = [UIColor bonfireBlack];
        self.typeIndicator.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.1f].CGColor;
        self.typeIndicator.layer.shadowOpacity = 1;
        self.typeIndicator.layer.shadowOffset = CGSizeMake(0, 1);
        self.typeIndicator.layer.shadowRadius = 3.f;
        self.typeIndicator.contentMode = UIViewContentModeCenter;
        self.typeIndicator.tintColor = [UIColor whiteColor];
        [self.contentView addSubview:self.typeIndicator];
        
        self.actionButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 96 - 36, 0, 96, 32)];
        self.actionButton.center = CGPointMake(self.actionButton.center.x, self.profilePicture.center.y);
        self.actionButton.layer.cornerRadius = 8.f;
        self.actionButton.layer.masksToBounds = true;
        self.actionButton.layer.borderColor = [UIColor colorWithRed:0.92 green:0.93 blue:0.94 alpha:1.0].CGColor;
        self.actionButton.layer.borderWidth = 0;
        self.actionButton.titleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
        
        [self.actionButton bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.actionButton.transform = CGAffineTransformMakeScale(0.92, 0.92);
            } completion:nil];
        } forControlEvents:UIControlEventTouchDown];
        [self.actionButton bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.actionButton.transform = CGAffineTransformIdentity;
            } completion:nil];
        } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
        [self.actionButton bk_whenTapped:^{
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.actionButton.transform = CGAffineTransformIdentity;
            } completion:nil];
        }];
        [self.contentView addSubview:self.actionButton];
        
        self.moreButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.moreButton.frame = CGRectMake(self.frame.size.width - 36, 18, 36, 44);
        [self.moreButton setImage:[UIImage imageNamed:@"notificationsMoreIcon"] forState:UIControlStateNormal];
        self.moreButton.tintColor = [UIColor colorWithWhite:0.47f alpha:1];
        self.moreButton.center = CGPointMake(self.moreButton.center.x, self.profilePicture.center.y);
        [self.moreButton bk_whenTapped:^{
            [self presentNotificationActions];
        }];
        // [self.contentView addSubview:self.moreButton];
        
        self.textLabel.frame = CGRectMake(70, 18, self.frame.size.width - 70 - self.actionButton.frame.size.width - 6, 32);
        self.textLabel.font = [UIFont systemFontOfSize:15.f];
        self.textLabel.textColor = [UIColor bonfireGrayWithLevel:900];
        
        self.imagePreview = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - (self.profilePicture.frame.size.width - 4) - 12, self.profilePicture.frame.origin.y + 2, self.profilePicture.frame.size.width - 4, self.profilePicture.frame.size.height - 4)];
        self.imagePreview.backgroundColor = [UIColor colorWithRed:0.92 green:0.92 blue:0.93 alpha:1];
        self.imagePreview.contentMode = UIViewContentModeScaleAspectFill;
        self.imagePreview.layer.masksToBounds = true;
        self.imagePreview.layer.cornerRadius = 4.f;
        [self.contentView addSubview:self.imagePreview];
        
        self.lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        self.lineSeparator.backgroundColor = [UIColor separatorColor];
        [self addSubview:self.lineSeparator];
        
#ifdef DEBUG
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            if (state == UIGestureRecognizerStateBegan) {
                // recognized long press
                [Launcher openDebugView:self.activity];
            }
        }];
        [self addGestureRecognizer:longPress];
#endif
    }
    else {
        
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.moreButton.frame = CGRectMake(self.frame.size.width - self.moreButton.frame.size.width, self.profilePicture.frame.origin.y + (self.profilePicture.frame.size.height / 2) - (self.moreButton.frame.size.height / 2), self.moreButton.frame.size.width, self.moreButton.frame.size.height);
    self.actionButton.frame = CGRectMake(self.frame.size.width - self.actionButton.frame.size.width - 12, self.actionButton.frame.origin.y, self.actionButton.frame.size.width, self.actionButton.frame.size.height);
    
    BOOL hasImagePreview = ![self.imagePreview isHidden];
    if (hasImagePreview) {
        self.imagePreview.frame = CGRectMake(self.frame.size.width - (self.profilePicture.frame.size.width - 4) - 12, self.profilePicture.frame.origin.y + 2, self.profilePicture.frame.size.width - 4, self.profilePicture.frame.size.height - 4);
    }
    
    CGFloat textLabelWidth = ([self.imagePreview isHidden] ? self.frame.size.width - 70 - 12 : self.imagePreview.frame.origin.x - 8 - 70);
    
    CGRect textLabelRect = [self.textLabel.attributedText boundingRectWithSize:CGSizeMake(textLabelWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
    CGFloat textLabelHeight = textLabelRect.size.height;
    
    long charSize = lroundf(self.textLabel.font.lineHeight);
    long rHeight = lroundf(textLabelHeight);
    int lineCount = roundf(rHeight/charSize);
    
    if (lineCount == 1) {
        self.textLabel.frame = CGRectMake(70, 17, textLabelWidth, ceilf(textLabelRect.size.height));
        self.textLabel.center = CGPointMake(self.textLabel.center.x, self.profilePicture.center.y);
    }
    else if (lineCount == 2) {
        self.textLabel.frame = CGRectMake(70, 17, textLabelWidth, ceilf(textLabelRect.size.height));
    }
    else {
        self.textLabel.frame = CGRectMake(70, 12, textLabelWidth, ceilf(textLabelRect.size.height));
    }
    
    if (![self.lineSeparator isHidden]) {
        self.lineSeparator.frame = CGRectMake(self.textLabel.frame.origin.x, self.frame.size.height - self.lineSeparator.frame.size.height, self.frame.size.width - self.textLabel.frame.origin.x, self.lineSeparator.frame.size.height);
    }
}

- (void)updateActivityType {
    // if type is unkown, hide the indicator
    self.typeIndicator.hidden = (self.activity.type == USER_ACTIVITY_TYPE_UNKNOWN);
    if (self.activity.attributes.type == USER_ACTIVITY_TYPE_USER_FOLLOW) {
        self.typeIndicator.image = [UIImage imageNamed:@"notificationIndicator_profile"];
        self.typeIndicator.backgroundColor = [UIColor bonfireBlue];
        // TODO: set dynamically based on following context
        [self.actionButton setTitle:@"Follow" forState:UIControlStateNormal];
        self.actionButton.hidden = true;
    }
    else if (self.activity.attributes.type == USER_ACTIVITY_TYPE_USER_ACCEPTED_ACCESS) {
        self.typeIndicator.image = [UIImage imageNamed:@"notificationIndicator_check"];
        self.typeIndicator.backgroundColor = [UIColor bonfireGreen];
        [self.actionButton setTitle:@"Open" forState:UIControlStateNormal];
        self.actionButton.hidden = true;
    }
    else if (self.activity.attributes.type == USER_ACTIVITY_TYPE_CAMP_ACCESS_REQUEST) {
        self.typeIndicator.image = [UIImage imageNamed:@"notificationIndicator_clock"];
        self.typeIndicator.backgroundColor = [UIColor colorWithRed:0.52 green:0.53 blue:0.55 alpha:1.0];
        [self.actionButton setTitle:@"Open" forState:UIControlStateNormal];
        self.actionButton.hidden = true;
    }
    else if (self.activity.attributes.type == USER_ACTIVITY_TYPE_POST_REPLY) {
        self.typeIndicator.image = [UIImage imageNamed:@"notificationIndicator_reply"];
        self.typeIndicator.backgroundColor = [UIColor bonfireViolet];
        [self.actionButton setTitle:@"View" forState:UIControlStateNormal];
        self.actionButton.hidden = true;
    }
    else if (self.activity.attributes.type == USER_ACTIVITY_TYPE_POST_VOTED) {
        self.typeIndicator.image = [UIImage imageNamed:@"notificationIndicator_vote"];
        self.typeIndicator.backgroundColor = [UIColor bonfireBrand];
        [self.actionButton setTitle:@"View" forState:UIControlStateNormal];
        self.actionButton.hidden = true;
    }
    else if (self.activity.attributes.type == USER_ACTIVITY_TYPE_USER_POSTED || self.activity.attributes.type == USER_ACTIVITY_TYPE_USER_POSTED_CAMP) {
        // TODO: Create user posted icon/color combo
        self.typeIndicator.image = [UIImage imageNamed:@"notificationIndicator_user_posted"];
        self.typeIndicator.backgroundColor = [UIColor bonfireGreen];
        self.actionButton.hidden = true;
    }
    else if (self.activity.attributes.type == USER_ACTIVITY_TYPE_POST_MENTION) {
        self.typeIndicator.image = [UIImage imageNamed:@"notificationIndicator_mention"];
        self.typeIndicator.backgroundColor = [UIColor colorWithRed:0.07 green:0.78 blue:1.00 alpha:1.0];
        [self.actionButton setTitle:@"View" forState:UIControlStateNormal];
        self.actionButton.hidden = true;
    }
    else {
        // unknown
        self.typeIndicator.hidden = true;
    }

    /*
    case NotificationTypeCampNewMember:
        self.typeIndicator.image = [UIImage imageNamed:@"notificationIndicator_plus"];
        self.typeIndicator.backgroundColor = [UIColor bonfireGreen];
        [self.actionButton setTitle:@"Open" forState:UIControlStateNormal];
        // self.state = NotificationStateOutline;
        self.actionButton.hidden = true;
        break;*/
}

- (void)presentNotificationActions {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // imessage , share via...
    
    UIAlertAction *hideAction = [UIAlertAction actionWithTitle:@"Hide this Notification" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"Hide this Notifications");
    }];
    [actionSheet addAction:hideAction];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"cancel");
    }];
    [actionSheet addAction:cancel];
    
    [[Launcher activeViewController] presentViewController:actionSheet animated:YES completion:nil];
}

- (void)setActivity:(UserActivity *)activity {
    if (activity != _activity) {
        _activity = activity;
        
        // set type
        [self updateActivityType];
        
        // set profile picture
        self.profilePicture.user = activity.attributes.actioner;
        
        // set text
        self.textLabel.attributedText = activity.attributes.attributedString;
        
        // set image preview (if needed)
        BOOL hasImagePreview = false;
        if (self.activity.attributes.replyPost &&
            self.activity.attributes.replyPost.attributes.details.attachments.media.count > 0) {
            hasImagePreview = true;
        }
        else if (!self.activity.attributes.replyPost &&
                 self.activity.attributes.post.attributes.details.attachments.media.count > 0) {
            hasImagePreview = true;
        }
        self.imagePreview.hidden = !hasImagePreview;
        if (hasImagePreview) {
            if (self.activity.attributes.replyPost) {
                [self.imagePreview sd_setImageWithURL:[NSURL URLWithString:self.activity.attributes.replyPost.attributes.details.attachments.media[0].attributes.hostedVersions.suggested.url]];
            }
            else {
                [self.imagePreview sd_setImageWithURL:[NSURL URLWithString:self.activity.attributes.post.attributes.details.attachments.media[0].attributes.hostedVersions.suggested.url]];
            }
        }
    }
}

+ (CGFloat)heightForUserActivity:(UserActivity *)activity {
    CGFloat minHeight = 68;
    
    CGFloat topPadding = 10;
    
    CGFloat actionButtonWidth = 0; //(activity.attributes.type == USER_ACTIVITY_TYPE_USER_FOLLOW ? 96 + 6 : 0);
    CGFloat textLabelWidth = [UIScreen mainScreen].bounds.size.width - 70 - actionButtonWidth - 12; // 36 = action button distance from right
    CGRect textLabelRect = [activity.attributes.attributedString boundingRectWithSize:CGSizeMake(textLabelWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
    CGFloat textLabelHeight = textLabelRect.size.height;
    
    long charSize = lroundf( [UIFont systemFontOfSize:15.f].lineHeight);
    long rHeight = lroundf(textLabelHeight);
    int lineCount = roundf(rHeight/charSize);
    
    if (lineCount > 2) {
        // 12 from top
        topPadding = 12;
    }
    else {
        // 18 from top
        topPadding = 16;
    }
    CGFloat bottomPadding = topPadding;
    
    CGFloat calculatedHeight = topPadding + ceilf(textLabelRect.size.height) + bottomPadding;
    
    return calculatedHeight < minHeight ? minHeight : calculatedHeight;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (self.activity && highlighted) {
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.contentView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.03];
        } completion:nil];
    }
    else {
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.contentView.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
        } completion:nil];
    }
}

- (void)setUnread:(BOOL)unread {
    self.backgroundColor = [UIColor whiteColor];
}

@end
