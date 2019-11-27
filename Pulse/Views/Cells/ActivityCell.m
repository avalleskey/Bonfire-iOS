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

#define ACTIVITY_CELL_CONTENT_INSET UIEdgeInsetsMake(12, 70, 12, 12)
#define ACTIVITY_CELL_ATTACHMENT_PADDING 8

@implementation ActivityCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.backgroundColor = [UIColor contentBackgroundColor];

        self.textLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.textLabel.backgroundColor = [UIColor clearColor];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.accessoryType = UITableViewCellAccessoryNone;
        
        self.profilePicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(12, ACTIVITY_CELL_CONTENT_INSET.top - 2, 48, 48)];
        self.profilePicture.openOnTap = true;
        [self.contentView addSubview:self.profilePicture];
        
        self.typeIndicator = [[UIImageView alloc] initWithFrame:CGRectMake(2, 2, 20, 20)];
        self.typeIndicator.layer.cornerRadius = self.typeIndicator.frame.size.height / 2;
        self.typeIndicator.layer.masksToBounds = false;
        self.typeIndicator.backgroundColor = [UIColor bonfirePrimaryColor];
        self.typeIndicator.contentMode = UIViewContentModeCenter;
        self.typeIndicator.tintColor = [UIColor contentBackgroundColor];
        
        // blur bg
        UIView *typeBackgroundBlurView = [[UIView alloc] init];
        typeBackgroundBlurView.frame = CGRectMake(self.profilePicture.frame.origin.x + self.profilePicture.frame.size.width - 20, self.profilePicture.frame.origin.y + self.profilePicture.frame.size.height - (self.typeIndicator.frame.size.height + 4) + 4, self.typeIndicator.frame.size.width + 4, self.typeIndicator.frame.size.height + 4);
        typeBackgroundBlurView.backgroundColor = [UIColor contentBackgroundColor];
        typeBackgroundBlurView.layer.cornerRadius = typeBackgroundBlurView.frame.size.height / 2;
        typeBackgroundBlurView.layer.masksToBounds = true;
        [typeBackgroundBlurView addSubview:self.typeIndicator];
        [self.contentView addSubview:typeBackgroundBlurView];
        
        self.textLabel.frame = CGRectMake(ACTIVITY_CELL_CONTENT_INSET.left, ACTIVITY_CELL_CONTENT_INSET.top + 6, self.frame.size.width - ACTIVITY_CELL_CONTENT_INSET.left - ACTIVITY_CELL_CONTENT_INSET.right, 32);
        self.textLabel.font = [UIFont systemFontOfSize:15.f];
        self.textLabel.textColor = [UIColor bonfireGrayWithLevel:900];
        
        self.imagePreview = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - (self.profilePicture.frame.size.width - 4) - 12, self.profilePicture.frame.origin.y + 2, self.profilePicture.frame.size.width - 4, self.profilePicture.frame.size.height - 4)];
        self.imagePreview.backgroundColor = [UIColor colorWithRed:0.92 green:0.92 blue:0.93 alpha:1];
        self.imagePreview.contentMode = UIViewContentModeScaleAspectFill;
        self.imagePreview.layer.masksToBounds = true;
        self.imagePreview.layer.cornerRadius = 4.f;
        [self.contentView addSubview:self.imagePreview];
        
        self.userPreviewView = [[BFUserAttachmentView alloc] initWithFrame:CGRectMake(self.frame.size.width - (self.profilePicture.frame.size.width - 4) - 12, self.profilePicture.frame.origin.y + 2, self.profilePicture.frame.size.width - 4, self.profilePicture.frame.size.height - 4)];
         [self.contentView addSubview:self.userPreviewView];
        
        self.campPreviewView = [[BFCampAttachmentView alloc] initWithFrame:CGRectMake(self.frame.size.width - (self.profilePicture.frame.size.width - 4) - 12, self.profilePicture.frame.origin.y + 2, self.profilePicture.frame.size.width - 4, self.profilePicture.frame.size.height - 4)];
         [self.contentView addSubview:self.campPreviewView];
        
        self.lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        self.lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
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
    
    BOOL hasImagePreview = ![self.imagePreview isHidden];
    if (hasImagePreview) {
        self.imagePreview.frame = CGRectMake(self.frame.size.width - (self.profilePicture.frame.size.width - 4) - 12, self.profilePicture.frame.origin.y + 2, self.profilePicture.frame.size.width - 4, self.profilePicture.frame.size.height - 4);
    }
    
    CGFloat leftOffset = 70;
    CGFloat contentWidth = self.frame.size.width - leftOffset - 12;
    CGFloat textLabelWidth = ([self.imagePreview isHidden] ? contentWidth : self.imagePreview.frame.origin.x - 8 - leftOffset);
    
    CGRect textLabelRect = [self.textLabel.attributedText boundingRectWithSize:CGSizeMake(textLabelWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
    CGFloat textLabelHeight = textLabelRect.size.height;
    
    long charSize = lroundf(self.textLabel.font.lineHeight);
    long rHeight = lroundf(textLabelHeight);
    int lineCount = roundf(rHeight/charSize);
    
    if (lineCount > 2 || self.campPreviewView || self.userPreviewView) {
        self.textLabel.frame = CGRectMake(leftOffset, ACTIVITY_CELL_CONTENT_INSET.top, textLabelWidth, ceilf(textLabelRect.size.height));
    }
    else if (lineCount == 1) {
        self.textLabel.frame = CGRectMake(leftOffset, self.profilePicture.frame.origin.y, textLabelWidth, self.profilePicture.frame.size.height);
    }
    else if (lineCount == 2) {
        self.textLabel.frame = CGRectMake(leftOffset, ACTIVITY_CELL_CONTENT_INSET.top + 5, textLabelWidth, ceilf(textLabelRect.size.height));
        self.textLabel.center = CGPointMake(self.textLabel.center.x, self.profilePicture.center.y);
    }
        
    if (self.campPreviewView) {
        [self.campPreviewView layoutSubviews];
        self.campPreviewView.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.origin.y + self.textLabel.frame.size.height + ACTIVITY_CELL_ATTACHMENT_PADDING, contentWidth, self.campPreviewView.frame.size.height);
    }
    else if (self.userPreviewView) {
        [self.userPreviewView layoutSubviews];
        self.userPreviewView.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.origin.y + self.textLabel.frame.size.height + ACTIVITY_CELL_ATTACHMENT_PADDING, contentWidth, self.userPreviewView.frame.size.height);
    }
    
    if (![self.lineSeparator isHidden]) {
        self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - self.lineSeparator.frame.size.height, self.frame.size.width, self.lineSeparator.frame.size.height);
    }
}

- (void)updateActivityType {
    // if type is unknown, hide the indicator
    self.typeIndicator.superview.hidden = (self.activity.type == USER_ACTIVITY_TYPE_UNKNOWN);
    if (self.activity.attributes.type == USER_ACTIVITY_TYPE_USER_FOLLOW) {
        self.typeIndicator.image = [UIImage imageNamed:@"notificationIndicator_profile"];
        self.typeIndicator.backgroundColor = [UIColor bonfireBlue];
    }
    else if (self.activity.attributes.type == USER_ACTIVITY_TYPE_USER_ACCEPTED_ACCESS) {
        self.typeIndicator.image = [UIImage imageNamed:@"notificationIndicator_check"];
        self.typeIndicator.backgroundColor = [UIColor bonfireGreen];
    }
    else if (self.activity.attributes.type == USER_ACTIVITY_TYPE_CAMP_ACCESS_REQUEST) {
        self.typeIndicator.image = [UIImage imageNamed:@"notificationIndicator_clock"];
        self.typeIndicator.backgroundColor = [UIColor colorWithRed:0.52 green:0.53 blue:0.55 alpha:1.0];
    }
    else if (self.activity.attributes.type == USER_ACTIVITY_TYPE_POST_REPLY) {
        self.typeIndicator.image = [UIImage imageNamed:@"notificationIndicator_reply"];
        self.typeIndicator.backgroundColor = [UIColor bonfireViolet];
    }
    else if (self.activity.attributes.type == USER_ACTIVITY_TYPE_POST_VOTED) {
        self.typeIndicator.image = [UIImage imageNamed:@"notificationIndicator_vote"];
        self.typeIndicator.backgroundColor = [UIColor bonfireBrand];
    }
    else if (self.activity.attributes.type == USER_ACTIVITY_TYPE_USER_POSTED || self.activity.attributes.type == USER_ACTIVITY_TYPE_USER_POSTED_CAMP) {
        // TODO: Create user posted icon/color combo
        self.typeIndicator.image = [UIImage imageNamed:@"notificationIndicator_user_posted"];
        self.typeIndicator.backgroundColor = [UIColor bonfireGreen];
    }
    else if (self.activity.attributes.type == USER_ACTIVITY_TYPE_POST_MENTION) {
        self.typeIndicator.image = [UIImage imageNamed:@"notificationIndicator_mention"];
        self.typeIndicator.backgroundColor = [UIColor colorWithRed:0.07 green:0.78 blue:1.00 alpha:1.0];
    }
    
    // init/remove attachments
    if ([ActivityCell includeUserAttachmentForActivity:self.activity]) {
        [self removeCampAttachment];
        [self initUserAttachmentWithUser:self.activity.attributes.actioner];
    }
    else if ([ActivityCell includeCampAttachmentForActivity:self.activity]) {
        [self removeUserAttachment];
        [self initCampAttachmentWithCamp:self.activity.attributes.camp];
    }
    else {
        [self removeCampAttachment];
        [self removeUserAttachment];
    }
}

+ (BOOL)includeUserAttachmentForActivity:(UserActivity *)activity {
    return activity.attributes.type == USER_ACTIVITY_TYPE_USER_FOLLOW && (activity.attributes.actioner.attributes.bio.length > 0 || activity.attributes.actioner.attributes.location.displayText.length > 0 || activity.attributes.actioner.attributes.website.displayUrl.length > 0);
}
+ (BOOL)includeCampAttachmentForActivity:(UserActivity *)activity {
    return activity.attributes.type == USER_ACTIVITY_TYPE_USER_ACCEPTED_ACCESS;
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
            self.activity.attributes.replyPost.attributes.attachments.media.count > 0) {
            hasImagePreview = true;
        }
        else if (!self.activity.attributes.replyPost &&
                 self.activity.attributes.post.attributes.attachments.media.count > 0) {
            hasImagePreview = true;
        }
        self.imagePreview.hidden = !hasImagePreview;
        if (hasImagePreview) {
            if (self.activity.attributes.replyPost) {
                [self.imagePreview sd_setImageWithURL:[NSURL URLWithString:self.activity.attributes.replyPost.attributes.attachments.media[0].attributes.hostedVersions.suggested.url]];
            }
            else {
                [self.imagePreview sd_setImageWithURL:[NSURL URLWithString:self.activity.attributes.post.attributes.attachments.media[0].attributes.hostedVersions.suggested.url]];
            }
        }
        
        if (activity.attributes.read) {
            self.contentView.backgroundColor = [UIColor contentBackgroundColor];
        }
        else {
            self.contentView.backgroundColor = [UIColor colorNamed:@"NewBackgroundColor"];
        }
    }
}

- (void)initCampAttachmentWithCamp:(Camp *)camp {
    if (!camp) {
        [self removeCampAttachment];
        return;
    }
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width - (ACTIVITY_CELL_CONTENT_INSET.left + ACTIVITY_CELL_CONTENT_INSET.right);
    CGRect frame = CGRectMake(ACTIVITY_CELL_CONTENT_INSET.left, self.textLabel.frame.origin.y + self.textLabel.frame.size.height + ACTIVITY_CELL_ATTACHMENT_PADDING, width, [BFCampAttachmentView heightForCamp:camp width:width]);
    
    if (self.campPreviewView) {
        self.campPreviewView.camp = camp;
        self.campPreviewView.frame = frame;
    }
    else {
        // need to initialize a user preview view
        self.campPreviewView = [[BFCampAttachmentView alloc] initWithCamp:camp frame:frame];
        [self.contentView addSubview:self.campPreviewView];
    }
}
- (void)removeCampAttachment {
    [self.campPreviewView removeFromSuperview];
    self.campPreviewView = nil;
}
- (void)initUserAttachmentWithUser:(User *)user {    
    if (!user) {
        [self removeUserAttachment];
        return;
    }
    
    // need to initialize a user preview view
    CGFloat width = [UIScreen mainScreen].bounds.size.width - (ACTIVITY_CELL_CONTENT_INSET.left + ACTIVITY_CELL_CONTENT_INSET.right);
    CGRect frame = CGRectMake(ACTIVITY_CELL_CONTENT_INSET.left, self.textLabel.frame.origin.y + self.textLabel.frame.size.height + ACTIVITY_CELL_ATTACHMENT_PADDING, width, [BFUserAttachmentView heightForUser:user width:width]);
    
    if (self.userPreviewView) {
        self.userPreviewView.user = user;
        self.userPreviewView.frame = frame;
    }
    else {
        self.userPreviewView = [[BFUserAttachmentView alloc] initWithUser:user frame:frame];
        NSLog(@"heightttt: %f", self.userPreviewView.frame.size.height);
        [self.contentView addSubview:self.userPreviewView];
    }
}
- (void)removeUserAttachment {
    [self.userPreviewView removeFromSuperview];
    self.userPreviewView = nil;
}

+ (CGFloat)heightForUserActivity:(UserActivity *)activity {
    CGFloat minHeight = ACTIVITY_CELL_CONTENT_INSET.top + 48 + ACTIVITY_CELL_CONTENT_INSET.bottom;
    
    CGFloat topPadding = ACTIVITY_CELL_CONTENT_INSET.top;
    CGFloat contentHeight = 0;
    
    BOOL hasImagePreview = false;
    if (activity.attributes.replyPost &&
        activity.attributes.replyPost.attributes.attachments.media.count > 0) {
        hasImagePreview = true;
    }
    else if (!activity.attributes.replyPost &&
             activity.attributes.post.attributes.attachments.media.count > 0) {
        hasImagePreview = true;
    }
    CGFloat pictureWidth = hasImagePreview ? 44 + 8 : 0;
    
    CGFloat textLabelWidth = [UIScreen mainScreen].bounds.size.width - ACTIVITY_CELL_CONTENT_INSET.left - pictureWidth - ACTIVITY_CELL_CONTENT_INSET.right; // 36 = action button distance from right
    CGRect textLabelRect = [activity.attributes.attributedString boundingRectWithSize:CGSizeMake(textLabelWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
    CGFloat textLabelHeight = textLabelRect.size.height;
    contentHeight += ceilf(textLabelRect.size.height);
    
    long charSize = lroundf( [UIFont systemFontOfSize:15.f].lineHeight);
    long rHeight = lroundf(textLabelHeight);
    int lineCount = roundf(rHeight/charSize);
    
    if (lineCount > 2 || [ActivityCell includeCampAttachmentForActivity:activity] || [ActivityCell includeUserAttachmentForActivity:activity]) {
        topPadding = ACTIVITY_CELL_CONTENT_INSET.top;
    }
    else if (lineCount == 1) {
        topPadding = 0;
    }
    else if (lineCount == 2) {
        topPadding = ACTIVITY_CELL_CONTENT_INSET.top + 5;
    }
    
    // attachments
    CGFloat attachmentWidth = ([UIScreen mainScreen].bounds.size.width - (ACTIVITY_CELL_CONTENT_INSET.left + ACTIVITY_CELL_CONTENT_INSET.right));
    if ([ActivityCell includeUserAttachmentForActivity:activity]) {
        contentHeight += (ACTIVITY_CELL_ATTACHMENT_PADDING + [BFUserAttachmentView heightForUser:activity.attributes.actioner width:attachmentWidth]);
    }
    else if ([ActivityCell includeCampAttachmentForActivity:activity]) {
        contentHeight += (ACTIVITY_CELL_ATTACHMENT_PADDING + [BFCampAttachmentView heightForCamp:activity.attributes.camp width:attachmentWidth]);
    }

    CGFloat bottomPadding = ACTIVITY_CELL_CONTENT_INSET.bottom;
    
    CGFloat calculatedHeight = topPadding + contentHeight + bottomPadding;
    
    return calculatedHeight < minHeight ? minHeight : calculatedHeight;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (self.activity && highlighted) {
        [UIView animateWithDuration:0.15f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            if (self.activity.attributes.read) {
                self.contentView.backgroundColor = [UIColor contentHighlightedColor];
            }
            else {
                self.contentView.backgroundColor = [UIColor colorNamed:@"NewBackgroundColor_Highlighted"];
            }
        } completion:nil];
    }
    else {
        [UIView animateWithDuration:0.15f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            if (self.activity.attributes.read) {
                self.contentView.backgroundColor = [UIColor contentBackgroundColor];
            }
            else {
                self.contentView.backgroundColor = [UIColor colorNamed:@"NewBackgroundColor"];
            }
        } completion:nil];
    }
}

- (void)setUnread:(BOOL)unread {
    self.backgroundColor = [UIColor contentBackgroundColor];
}

@end
