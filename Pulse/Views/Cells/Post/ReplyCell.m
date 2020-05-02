//
//  ReplyCell.m
//  Pulse
//
//  Created by Austin Valleskey on 3/10/18.
//  Copyright © 2018 Ingenious, Inc. All rights reserved.
//

#import "ReplyCell.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import <SafariServices/SafariServices.h>
#import <HapticHelper/HapticHelper.h>
#import "Session.h"
#import "ComplexNavigationController.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import "StreamPostCell.h"
#import "BFStreamComponent.h"

#define REPLY_POST_MAX_CHARACTERS 125
#define REPLY_POST_EMOJI_SIZE_MULTIPLIER 1

#define repliesButtonLineTag 10
#define repliesButtonHeight 24

@interface ReplyCell () <BFComponentProtocol>

@property (nonatomic, strong) CAShapeLayer *bubbleLayer;
@property (nonatomic, strong) CAShapeLayer *bubbleBigDotLayer;
@property (nonatomic, strong) CAShapeLayer *bubbleLittleDotLayer;

@end

@implementation ReplyCell

@synthesize post = _post;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.clipsToBounds = false;
        self.layer.masksToBounds = false;
        self.contentView.layer.masksToBounds = true;
        
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor clearColor];
        
        self.primaryAvatarView.frame = CGRectMake(replyContentOffset.left, replyContentOffset.top, 24, 24);
        
        self.moreButton.hidden = true;
        
        self.nameLabel.font = replyNameLabelFont;
        self.nameLabel.frame = CGRectMake(64, replyContentOffset.top, self.contentView.frame.size.width - 72 - replyContentOffset.right, ceilf(self.nameLabel.font.lineHeight));
        self.nameLabel.text = @"Display Name";
        self.nameLabel.userInteractionEnabled = YES;
        self.nameLabel.textColor = [UIColor bonfirePrimaryColor];
        [self.nameLabel bk_whenTapped:^{
            [Launcher openIdentity:self.post.attributes.creator];
        }];
        
        self.dateLabel.frame = CGRectMake(0, self.nameLabel.frame.origin.y, self.nameLabel.frame.origin.y, self.nameLabel.frame.size.height);
        self.dateLabel.font = [UIFont systemFontOfSize:self.nameLabel.font.pointSize weight:UIFontWeightRegular];
        self.dateLabel.textAlignment = NSTextAlignmentRight;
        self.dateLabel.hidden = true;
        
        self.voted = false;
        
        // text view
        self.textView.frame = CGRectMake(replyContentOffset.left, 28, [UIScreen mainScreen].bounds.size.width - (replyContentOffset.left + replyContentOffset.right), 200);
        self.textView.messageLabel.font = replyTextViewFont;
        self.textView.delegate = self;
        self.textView.maxCharacters = REPLY_POST_MAX_CHARACTERS;
        self.textView.postId = self.post.identifier;
        self.textView.styleAsBubble = true;

        //        self.actionsView = [[PostActionsView alloc] initWithFrame:CGRectMake(self.nameLabel.frame.origin.x + postTextViewInset.left, 0, self.nameLabel.frame.size.width - (postTextViewInset.left + postTextViewInset.right), POST_ACTIONS_VIEW_HEIGHT)];
//        [self.actionsView.voteButton bk_whenTapped:^{
//            [self setVoted:!self.voted animated:YES];
//
//            if (self.voted) {
//                // not voted -> vote it
//                [BFAPI votePost:self.post completion:^(BOOL success, id responseObject) {
//                    if (success) {
//                        // NSLog(@"success upvoting!");
//                    }
//                }];
//            }
//            else {
//                // not voted -> vote it
//                [BFAPI unvotePost:self.post completion:^(BOOL success, id responseObject) {
//                    if (success) {
//                        // NSLog(@"success downvoting.");
//                    }
//                }];
//            }
//        }];
//        [self.contentView addSubview:self.actionsView];
        
        // image view
        self.imagesView.frame = CGRectMake(self.textView.frame.origin.x, 56, self.textView.frame.size.width, [PostImagesView streamImageHeight]);
        self.imagesView.layer.cornerRadius = 0;
        self.imagesView.userInteractionEnabled = true;
        
        self.repliesButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.repliesButton setImage:[[UIImage imageNamed:@"postRepliesIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self.repliesButton setTintColor:[[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0.75]];
        [self.repliesButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 6)];
        [self.repliesButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 6, 0, 0)];
        self.repliesButton.frame = CGRectMake(0, 0, self.frame.size.width, repliesButtonHeight);
        [self.repliesButton setTitle:@"2 Replies" forState:UIControlStateNormal];
        [self.repliesButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        [self.repliesButton setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateNormal];
        [self.repliesButton.titleLabel setFont:[UIFont systemFontOfSize:14.f weight:UIFontWeightRegular]];
        
//        UIView *repliesLine = [[UIView alloc] initWithFrame:CGRectMake(replyContentOffset.left+REPLY_BUBBLE_INSETS.left, 0, 12, 1 + HALF_PIXEL)];
//
//        repliesLine.layer.cornerRadius = repliesLine.frame.size.height / 2;
//        repliesLine.backgroundColor = [UIColor bonfireSecondaryColor];
//        repliesLine.tag = repliesButtonLineTag;
//        repliesLine.alpha = 0.75;
//        [self.repliesButton addSubview:repliesLine];
        
        [self addSubview:self.repliesButton];
        
        self.topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 3, 0)];
        self.topLine.backgroundColor = [UIColor threadLineColor];
        self.topLine.layer.cornerRadius = self.topLine.frame.size.width / 2;
        // [self.contentView addSubview:self.topLine];
        
        self.bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.topLine.frame.size.width, 0)];
        self.bottomLine.backgroundColor = [UIColor threadLineColor];
        self.bottomLine.layer.cornerRadius = self.topLine.layer.cornerRadius;
        // [self.contentView addSubview:self.bottomLine];
        
        self.lineSeparator.hidden = false;
        
        self.levelsDeep = 0;
        
        self.topLevelReplyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.topLevelReplyButton.frame = CGRectMake(-40, 0, 40, 40);
//        self.topLevelReplyButton.backgroundColor = [[UIColor bonfirePrimaryColor] colorWithAlphaComponent:0.04];
        self.topLevelReplyButton.layer.cornerRadius = self.topLevelReplyButton.frame.size.height / 2;
        self.topLevelReplyButton.tintColor = [UIColor bonfireSecondaryColor];
        [self.topLevelReplyButton setImage:[[UIImage imageNamed:@"postActionReply"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self.topLevelReplyButton bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.topLevelReplyButton.transform = CGAffineTransformMakeScale(0.85, 0.85);
                self.topLevelReplyButton.backgroundColor = [[UIColor bonfirePrimaryColor] colorWithAlphaComponent:0.08];
            } completion:nil];
        } forControlEvents:UIControlEventTouchDown];
        [self.topLevelReplyButton bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.topLevelReplyButton.transform = CGAffineTransformMakeScale(1, 1);
                self.topLevelReplyButton.backgroundColor = [UIColor clearColor];
            } completion:nil];
        } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
        [self.contentView addSubview:self.topLevelReplyButton];
        
        self.bubbleLayer = [CAShapeLayer layer];
        self.bubbleLayer.fillColor = [UIColor blueColor].CGColor;
        [self.contentView.layer insertSublayer:self.bubbleLayer atIndex:0];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    UIEdgeInsets edgeInsets = [ReplyCell edgeInsetsForLevel:self.levelsDeep];
    UIEdgeInsets contentEdgeInsets = [ReplyCell contentEdgeInsetsForLevel:self.levelsDeep];
    if (self.levelsDeep == 0 && [self.post isRemoved]) {
        contentEdgeInsets.right = replyContentOffset.right;
    }
//    if (![self.repliesButton isHidden]) {
//        contentEdgeInsets.bottom += repliesButtonHeight;
//    }
    
    CGFloat bubbleCornerRadius = ceilf((self.textView.messageLabel.font.lineHeight+REPLY_BUBBLE_INSETS.top+REPLY_BUBBLE_INSETS.bottom)/1.8);
    CGFloat yBottom = contentEdgeInsets.top + REPLY_BUBBLE_INSETS.top;
        
    CGFloat bubbleWidth = 0;
    
    if (![self.nameLabel isHidden]) {
        CGFloat nameLabelWidth = ceilf([self.nameLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - contentEdgeInsets.left - contentEdgeInsets.right - REPLY_BUBBLE_INSETS.left - REPLY_BUBBLE_INSETS.right, self.nameLabel.frame.size.height) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: self.nameLabel.font} context:nil].size.width);
        self.nameLabel.frame = CGRectMake(contentEdgeInsets.left + REPLY_BUBBLE_INSETS.left, yBottom, nameLabelWidth, ceilf(self.nameLabel.font.lineHeight));
        
        bubbleWidth = MAX(bubbleWidth, self.nameLabel.frame.size.width + 12 + (REPLY_BUBBLE_INSETS.left + REPLY_BUBBLE_INSETS.right));
        
        yBottom = self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height + REPLY_NAME_BOTTOM_PADDING;
    }
    
    CGFloat attachmentCornerRadius = ceilf(bubbleCornerRadius * .8);
    CGFloat attachmentBottomPadding = REPLY_BUBBLE_INSETS.bottom;
    CGFloat attachmentXOrigin = contentEdgeInsets.left + REPLY_BUBBLE_INSETS.left;
    CGFloat attachmentWidth = self.frame.size.width - contentEdgeInsets.left - contentEdgeInsets.right - REPLY_BUBBLE_INSETS.left - REPLY_BUBBLE_INSETS.right;
    
    BOOL hasImage = self.post.attributes.media.count > 0 || self.post.attributes.attachments.media.count > 0;
    self.imagesView.hidden = !hasImage;
    if (hasImage) {
        CGFloat imageWidth = attachmentWidth;
        CGFloat imageHeight = ceilf(imageWidth * .75);
        self.imagesView.frame = CGRectMake(attachmentXOrigin, yBottom, imageWidth, imageHeight);
        self.imagesView.layer.cornerRadius = attachmentCornerRadius;
        
        [self.imagesView startSpinnersAsNeeded];
        
        bubbleWidth = MAX(bubbleWidth, self.imagesView.frame.size.width + REPLY_BUBBLE_INSETS.left + REPLY_BUBBLE_INSETS.right);
        
        yBottom = self.imagesView.frame.origin.y + self.imagesView.frame.size.height + attachmentBottomPadding;
    }
    
    if (self.linkAttachmentView) {
        self.linkAttachmentView.layer.cornerRadius = attachmentCornerRadius;
        [self.linkAttachmentView layoutSubviews];
        self.linkAttachmentView.frame = CGRectMake(attachmentXOrigin, yBottom, attachmentWidth, [BFLinkAttachmentView heightForLink:self.linkAttachmentView.link width:attachmentWidth]);
        
        bubbleWidth = MAX(bubbleWidth, self.linkAttachmentView.frame.size.width + REPLY_BUBBLE_INSETS.left + REPLY_BUBBLE_INSETS.right);
        
        yBottom = self.linkAttachmentView.frame.origin.y + self.linkAttachmentView.frame.size.height + attachmentBottomPadding;
    }
    
    if (self.smartLinkAttachmentView) {
        self.smartLinkAttachmentView.layer.cornerRadius = attachmentCornerRadius;
        [self.smartLinkAttachmentView layoutSubviews];
        self.smartLinkAttachmentView.frame = CGRectMake(attachmentXOrigin, yBottom, attachmentWidth, [BFSmartLinkAttachmentView heightForSmartLink:self.smartLinkAttachmentView.link width:attachmentWidth showActionButton:true]);
        
        bubbleWidth = MAX(bubbleWidth, self.smartLinkAttachmentView.frame.size.width + REPLY_BUBBLE_INSETS.left + REPLY_BUBBLE_INSETS.right);
        
        yBottom = self.smartLinkAttachmentView.frame.origin.y + self.smartLinkAttachmentView.frame.size.height + attachmentBottomPadding;
    }
    
    if (self.campAttachmentView) {
        self.campAttachmentView.layer.cornerRadius = attachmentCornerRadius;
        [self.campAttachmentView layoutSubviews];
        self.campAttachmentView.frame = CGRectMake(attachmentXOrigin, yBottom, attachmentWidth, [BFCampAttachmentView heightForCamp:self.campAttachmentView.camp width:attachmentWidth]);
        
        bubbleWidth = MAX(bubbleWidth, self.campAttachmentView.frame.size.width + REPLY_BUBBLE_INSETS.left + REPLY_BUBBLE_INSETS.right);
        
        yBottom = self.campAttachmentView.frame.origin.y + self.campAttachmentView.frame.size.height + attachmentBottomPadding;
    }
    
    if (self.identityAttachmentView) {
        self.identityAttachmentView.layer.cornerRadius = attachmentCornerRadius;
        [self.identityAttachmentView layoutSubviews];
        self.identityAttachmentView.frame = CGRectMake(attachmentXOrigin, yBottom, attachmentWidth, [BFIdentityAttachmentView heightForIdentity:self.identityAttachmentView.identity width:attachmentWidth]);
        
        bubbleWidth = MAX(bubbleWidth, self.identityAttachmentView.frame.size.width + REPLY_BUBBLE_INSETS.left + REPLY_BUBBLE_INSETS.right);
        
        yBottom = self.identityAttachmentView.frame.origin.y + self.identityAttachmentView.frame.size.height + attachmentBottomPadding;
    }
    
    // -- text view
    if (![self.textView isHidden]) {
        self.textView.frame = CGRectMake(contentEdgeInsets.left + REPLY_BUBBLE_INSETS.left, yBottom, self.frame.size.width - contentEdgeInsets.left - contentEdgeInsets.right - REPLY_BUBBLE_INSETS.left - REPLY_BUBBLE_INSETS.right, self.textView.frame.size.height);
        
        self.textView.tintColor = self.tintColor;
        [self.textView update];
        
        CGFloat messageWidth = self.textView.messageLabel.frame.size.width + (REPLY_BUBBLE_INSETS.left + REPLY_BUBBLE_INSETS.right);
        
        bubbleWidth = MAX(bubbleWidth, messageWidth);
        
        yBottom = self.textView.frame.origin.y + self.textView.frame.size.height;
    }
    
    CGFloat avatarSize = [ReplyCell avatarSizeForLevel:self.levelsDeep];
    self.primaryAvatarView.frame = CGRectMake(edgeInsets.left, 0, avatarSize, avatarSize);
    self.primaryAvatarView.center = CGPointMake(self.primaryAvatarView.center.x, self.frame.size.height - contentEdgeInsets.bottom - ((replyTextViewFont.lineHeight + REPLY_BUBBLE_INSETS.top + REPLY_BUBBLE_INSETS.bottom) / 2));
    
    if (![self.repliesButton isHidden]) {
        self.repliesButton.frame = CGRectMake(contentEdgeInsets.left + REPLY_BUBBLE_INSETS.left, yBottom, [self.repliesButton intrinsicContentSize].width + self.repliesButton.imageEdgeInsets.right, self.repliesButton.frame.size.height);
        
        bubbleWidth = MAX(bubbleWidth, self.repliesButton.frame.size.width + (REPLY_BUBBLE_INSETS.left + REPLY_BUBBLE_INSETS.right));
    }
    
    self.bubbleLayer.frame = CGRectMake(contentEdgeInsets.left, contentEdgeInsets.top, bubbleWidth, self.frame.size.height - contentEdgeInsets.top - contentEdgeInsets.bottom);
    self.bubbleLayer.path = [self createBubblePath:self.bubbleLayer.bounds cornerRadius:bubbleCornerRadius];
    
     NSInteger profilePicPadding = 4;
     self.topLine.frame = CGRectMake(self.primaryAvatarView.frame.origin.x + (self.primaryAvatarView.frame.size.width / 2) - (self.topLine.frame.size.width / 2), - (self.topLine.layer.cornerRadius / 2), self.topLine.frame.size.width, self.primaryAvatarView.frame.origin.y - profilePicPadding + (self.topLine.layer.cornerRadius / 2));
     
     if (![self.bottomLine isHidden]) {
         self.bottomLine.frame = CGRectMake(self.primaryAvatarView.frame.origin.x + (self.primaryAvatarView.frame.size.width / 2) - (self.bottomLine.frame.size.width / 2), self.primaryAvatarView.frame.origin.y + self.primaryAvatarView.frame.size.width + profilePicPadding, self.bottomLine.frame.size.width, self.frame.size.height - (self.primaryAvatarView.frame.origin.y + self.primaryAvatarView.frame.size.width + profilePicPadding) + (self.bottomLine.layer.cornerRadius / 2));
     }
    
    if (!self.lineSeparator.isHidden) {
        self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - self.lineSeparator.frame.size.height, self.frame.size.width, self.lineSeparator.frame.size.height);
    }
}

- (CGPathRef)createBubblePath:(CGRect)rect cornerRadius:(CGFloat)cornerRadius {
    UIBezierPath *bubble = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius*.9];
    
    CGFloat bubbleDotSize1 = cornerRadius * 0.7;
    CGFloat bubbleDotSize2 = cornerRadius * 0.25;
    
    UIBezierPath *bigDot = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(rect.origin.x, rect.origin.y + rect.size.height - bubbleDotSize1 - (bubbleDotSize1 * 0.05), bubbleDotSize1, bubbleDotSize1) cornerRadius:bubbleDotSize1/2];
    UIBezierPath *littleDot = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(rect.origin.x - (bubbleDotSize2 * 1.35), rect.origin.y + rect.size.height - bubbleDotSize2, bubbleDotSize2, bubbleDotSize2) cornerRadius:bubbleDotSize2/2];
    
    [bubble appendPath:bigDot];
    [bubble appendPath:littleDot];
    
    return bubble.CGPath;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [self updateBubbleStyling];
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    sender.layer.cornerRadius = radius;
//    CAShapeLayer * maskLayer = [CAShapeLayer layer];
//    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
//                                           byRoundingCorners:UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
//                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
//
//    sender.layer.mask = maskLayer;
}

+ (CGFloat)avatarSizeForLevel:(NSInteger)level {
    if (level == 0) {
        return replyTextViewFont.lineHeight + ((REPLY_BUBBLE_INSETS.top + REPLY_BUBBLE_INSETS.bottom) / 2);
    }
    
    return 28;
}
+ (CGFloat)avatarPaddingForLevel:(NSInteger)level {
    if (level == 0) {
        return ceilf([self avatarSizeForLevel:level] / 4.5);
    }
    
    return ceilf([self avatarSizeForLevel:level] / 4);
}
+ (UIEdgeInsets)edgeInsetsForLevel:(NSInteger)level {
    UIEdgeInsets edgeInsets = replyContentOffset;
    
    if (level == -1) {
        edgeInsets.left = postContentOffset.left;
    }
    else if (level > 0) {
        CGFloat topLevelAvatarSize = [self avatarSizeForLevel:0];
        CGFloat topLevelAvatarPadding = [self avatarPaddingForLevel:0];
        
        edgeInsets.left = edgeInsets.left + (topLevelAvatarSize + topLevelAvatarPadding);
    }
    
    return edgeInsets;
}
+ (UIEdgeInsets)contentEdgeInsetsForLevel:(NSInteger)level {
    UIEdgeInsets contentEdgeInsets = [self edgeInsetsForLevel:level];
    contentEdgeInsets.left += ([self avatarSizeForLevel:level] + [self avatarPaddingForLevel:level]);
    if (level == 0) {
        contentEdgeInsets.right += 40 + replyContentOffset.right;
    }
    
    return contentEdgeInsets;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [UIView animateWithDuration:0.15f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.contentView.alpha = highlighted ? 0.9 : 1;
    } completion:nil];
}

// Setter method
/*
 - (void)postTextViewDidDoubleTap:(PostTextView *)postTextView {
 if (postTextView != self.textView)
 return;
 
 [self setVoted:!self.voted withAnimation:VoteAnimationTypeAll];
 }
- (void)setVoted:(BOOL)isVoted animated:(BOOL)animated {
    if (!animated || (isVoted != self.voted)) {
        self.voted = isVoted;
        
        //[self.actionsView setVoted:isVoted animated:animated];
        
        void(^rippleAnimation)(void) = ^() {
            if (!self.voted)
                return;
            
            if (self.post.attributes.message.length == 0)
                return;
            
            CGFloat bubbleDiamater = self.frame.size.width * 1.6;
            UIView *bubble = [[UIView alloc] initWithFrame:CGRectMake(0, 0, bubbleDiamater, bubbleDiamater)];
            bubble.userInteractionEnabled = false;
            bubble.center = self.textView.center;
            bubble.backgroundColor = [self.actionsView.voteButton.tintColor colorWithAlphaComponent:0.06];
            bubble.layer.cornerRadius = bubble.frame.size.height / 2;
            bubble.layer.masksToBounds = true;
            bubble.transform = CGAffineTransformMakeScale(0.01, 0.01);
            
            [self.contentView bringSubviewToFront:self.textView];
            [self.contentView insertSubview:bubble belowSubview:self.textView];
            
            [UIView animateWithDuration:animated?1.f:0 delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                bubble.transform = CGAffineTransformIdentity;
            } completion:nil];
            [UIView animateWithDuration:animated?1.f:0 delay:animated?0.1f:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                bubble.alpha = 0;
            } completion:nil];
        };
        
        if (animated) {
            rippleAnimation();
        }
    }
}
 */

- (void)setLevelsDeep:(NSInteger)levelsDeep {
    if (levelsDeep != _levelsDeep) {
        _levelsDeep = levelsDeep;
    }
    
    [self updateBubbleStyling];
}

- (void)updateBubbleStyling {
    self.textView.textColor = [UIColor bonfirePrimaryColor];
    self.nameLabel.tintColor = [UIColor bonfireSecondaryColor];
    
    if (_levelsDeep == -1) {
        UIColor *themeColor = [UIColor fromHex:[Session sharedInstance].currentUser.attributes.color adjustForOptimalContrast:true];
        if ([self.post.attributes.creator isCurrentIdentity]) {
            if (@available(iOS 13.0, *)) {
                if ([UITraitCollection currentTraitCollection].userInterfaceStyle == UIUserInterfaceStyleDark) {
                    self.bubbleLayer.fillColor = [themeColor colorWithAlphaComponent:0.12].CGColor;
                }
                else {
                    self.bubbleLayer.fillColor = [themeColor colorWithAlphaComponent:0.1].CGColor;
                }
            }
            else {
                self.bubbleLayer.fillColor = [themeColor colorWithAlphaComponent:0.1].CGColor;
            }
            self.nameLabel.textColor = [UIColor fromHex:[Session sharedInstance].currentUser.attributes.color adjustForOptimalContrast:true];
            self.textView.textColor = [UIColor bonfirePrimaryColor];
            self.textView.messageLabel.tintColor = [UIColor colorNamed:@"CreatorLinkColor"];
        }
        else if ([self.post containsMention]) {
            self.bubbleLayer.fillColor = [UIColor colorNamed:@"MentionBackgroundColor"].CGColor;
            self.nameLabel.textColor = [UIColor bonfirePrimaryColor];
            self.textView.textColor = [UIColor bonfirePrimaryColor];;
            self.textView.messageLabel.tintColor = [UIColor colorNamed:@"MentionLinkColor"];
        }
        else {
            self.bubbleLayer.fillColor = [UIColor colorNamed:@"BubbleColor"].CGColor;
            self.nameLabel.textColor = [UIColor bonfirePrimaryColor];
            self.textView.textColor = [UIColor bonfirePrimaryColor];;
            self.textView.messageLabel.tintColor = [UIColor colorNamed:@"LinkColor"];
        }
        
        self.topLevelReplyButton.hidden = true;
    }
    else if (_levelsDeep == 0) {
        self.bubbleLayer.fillColor = [UIColor fromHex:[UIColor toHex:self.tintColor] adjustForOptimalContrast:false].CGColor;//[UIColor fromHex:[UIColor toHex:self.tintColor] adjustForOptimalContrast:false];
        
        UIColor *textColor = [UIColor bonfirePrimaryColor];
        self.textView.textColor = textColor;
        self.textView.messageLabel.tintColor = [textColor colorWithAlphaComponent:0.8];
//            self.nameLabel.tintColor = textColor;
        
        self.topLevelReplyButton.hidden = [self.post isRemoved];
    }
    else {
        self.bubbleLayer.fillColor = [UIColor tableViewBackgroundColor].CGColor;//[UIColor fromHex:[UIColor toHex:[UIColor darkerColorForColor:self.tintColor amount:0.1]] adjustForOptimalContrast:false];
//            self.bubbleBackgroundView.layer.shadowOpacity = 0;
        
        UIColor *textColor = [UIColor bonfirePrimaryColor];
        self.textView.textColor = textColor;
        self.textView.messageLabel.tintColor = [textColor colorWithAlphaComponent:0.8];
//            self.nameLabel.tintColor = textColor;
        
        //self.textView.messageLabel.linkAttributes = @{(__bridge NSString *)kCTForegroundColorAttributeName: [UIColor linkColor]};
        self.topLevelReplyButton.hidden = true;
    }
}

- (void)setPost:(Post *)post {
    if (post != _post) {
        _post = post;
                
        self.userInteractionEnabled = (!_post.tempId);
        
        [self updateBubbleStyling];
        if (post.attributes.creator.attributes.identifier.length > 0) {
            self.nameLabel.text = [@"@" stringByAppendingString:post.attributes.creator.attributes.identifier];
        }
        else {
            self.nameLabel.text = @"anonymous";
        }
        
//        if ([post containsMention]) {
//            [mutableLinkAttributes setObject:[UIColor colorNamed:@"MentionLinkColor"] forKey:(__bridge NSString *)kCTForegroundColorAttributeName];
//            self.moreButton.tintColor = [UIColor colorNamed:@"MentionSecondaryColor"];
//            self.dateLabel.textColor = [UIColor colorNamed:@"MentionSecondaryColor"];
//        }
        
        UIFont *font = [post isEmojiPost] ? [UIFont systemFontOfSize:replyTextViewFont.pointSize*REPLY_POST_EMOJI_SIZE_MULTIPLIER] : replyTextViewFont;
        if ([self.post isRemoved]) {
            self.textView.messageLabel.font = [UIFont italicSystemFontOfSize:font.pointSize];
        }
        else {
            self.textView.messageLabel.font = font;
        }
        self.textView.postId = self.post.identifier;
        
        if ([self.post.attributes.display.creator isEqualToString:POST_DISPLAY_CREATOR_CAMP] && self.post.attributes.postedIn) {
            if (self.primaryAvatarView.camp != _post.attributes.postedIn) {
                self.primaryAvatarView.camp = _post.attributes.postedIn;
            }
        }
        else {
            if (self.primaryAvatarView.user != _post.attributes.creator && self.primaryAvatarView.bot != _post.attributes.creator) {
                if (_post.attributes.creatorUser) {
                    self.primaryAvatarView.user = _post.attributes.creatorUser;
                }
                else if (_post.attributes.creatorBot) {
                    self.primaryAvatarView.bot = _post.attributes.creatorBot;
                }
            }
        }
        self.primaryAvatarView.online = false;
                
        if (self.post.attributes.attachments.media.count > 0) {
            [self.imagesView setMedia:self.post.attributes.attachments.media];
        }
        else if (self.post.attributes.media.count > 0) {
            [self.imagesView setMedia:self.post.attributes.media];
        }
        else {
            [self.imagesView setMedia:@[]];
        }
        
        if (self.imagesView.media.count > 0 && [PostImagesView useCaptionedImageViewForPost:self.post]) {
            self.textView.hidden = true;
            [self.textView setMessage:@"" entities:nil];
            self.imagesView.caption = self.post.attributes.simpleMessage;
            self.imagesView.captionTextView.backgroundColor = [UIColor fromHex:self.post.themeColor];
            self.imagesView.captionTextView.textColor = [UIColor highContrastForegroundForBackground:self.imagesView.captionTextView.backgroundColor];
        }
        else {
            self.textView.hidden = false;
            if ([self.post isRemoved]) {
                [self.textView setMessage:self.post.attributes.removedReason entities:nil];
                self.textView.alpha = 0.5;
            }
            else {
                [self.textView setMessage:self.post.attributes.simpleMessage entities:self.post.attributes.entities];
                self.textView.alpha = 1;
            }
        }
        
        // TODO: change this to self.post.attributes.attachments.link.attributes.attribution
        BOOL smartLink = [post.attributes.attachments.link isSmartLink];
        
        // smart link attachment
        if ([self.post hasLinkAttachment] && smartLink) {
            [self initSmartLinkAttachment];
        }
        else {
            [self removeSmartLinkAttachment];
        }
        // link attachment
        if ([self.post hasLinkAttachment] && !smartLink) {
            [self initLinkAttachment];
        }
        else {
            [self removeLinkAttachment];
        }
        
        // camp attachment
        if ([self.post hasCampAttachment]) {
            [self initCampAttachment];
        }
        else if (self.campAttachmentView) {
            [self removeCampAttachment];
        }
        
        // user attachment
        if ([self.post hasUserAttachment]) {
            [self initIdentityAttachment];
        }
        else if (self.identityAttachmentView) {
            [self removeIdentityAttachment];
        }
        
        BOOL hasSubReplies = post.attributes.summaries.counts.replies > 0;
        [self.repliesButton setTitle:[NSString stringWithFormat:@"%ld %@", (long)post.attributes.summaries.counts.replies, (post.attributes.summaries.counts.replies == 1) ? @"Reply" : @"Replies"] forState:UIControlStateNormal];
        self.repliesButton.hidden = !hasSubReplies;
    }
}

+ (CGFloat)heightForPost:(Post *)post levelsDeep:(NSInteger)levelsDeep {
    UIEdgeInsets contentEdgeInsets = [ReplyCell contentEdgeInsetsForLevel:levelsDeep];
    if (levelsDeep == 0 && [post isRemoved]) {
        contentEdgeInsets.right = replyContentOffset.right;
    }
    
    CGFloat baseHeight = contentEdgeInsets.top + REPLY_BUBBLE_INSETS.top + REPLY_BUBBLE_INSETS.bottom + contentEdgeInsets.bottom;
    CGFloat height = baseHeight;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    // name label
    height += ceilf(replyNameLabelFont.lineHeight) + REPLY_NAME_BOTTOM_PADDING;
    
    CGFloat attachmentBottomPadding = REPLY_BUBBLE_INSETS.bottom;
    CGFloat attachmentWidth = screenWidth - (contentEdgeInsets.left + contentEdgeInsets.right) - (REPLY_BUBBLE_INSETS.left + REPLY_BUBBLE_INSETS.right);
    NSInteger attachments = 0;
    
    // image
    BOOL hasImage = (post.attributes.media.count > 0 || post.attributes.attachments.media.count > 0);
    if (hasImage) {
        attachments++;
        
        CGFloat imageHeight = ceilf(attachmentWidth * .75);
        height += imageHeight + attachmentBottomPadding;
    }
    
    // link
    BOOL hasLinkPreview = [post hasLinkAttachment];
    if (hasLinkPreview) {
        attachments++;
        
        CGFloat linkPreviewHeight;
        if ([post.attributes.attachments.link isSmartLink]) {
            linkPreviewHeight = [BFSmartLinkAttachmentView heightForSmartLink:post.attributes.attachments.link  width:attachmentWidth showActionButton:true];
        }
        else {
            linkPreviewHeight = [BFLinkAttachmentView heightForLink:post.attributes.attachments.link  width:attachmentWidth];
        }

        height += linkPreviewHeight + attachmentBottomPadding;
    }
    
    // camp
    BOOL hasCampAttachment = [post hasCampAttachment];
    if (hasCampAttachment) {
        attachments++;
        
        Camp *camp = post.attributes.attachments.camp;
        
        CGFloat campAttachmentHeight = [BFCampAttachmentView heightForCamp:camp width:attachmentWidth];
        height += campAttachmentHeight + attachmentBottomPadding;
    }
    
    // user
    BOOL hasUserAttachment = [post hasUserAttachment];
    if (hasUserAttachment) {
        attachments++;
        
        User *user = post.attributes.attachments.user;
        
        CGFloat userAttachmentHeight = [BFIdentityAttachmentView heightForIdentity:user width:attachmentWidth];
        height += userAttachmentHeight + attachmentBottomPadding;
    }
    
    // message
    BOOL hasMessage =  ![PostImagesView useCaptionedImageViewForPost:post] && (post.attributes.simpleMessage.length > 0 || post.attributes.removedReason.length > 0);
    if (hasMessage) {
        UIFont *font = [post isEmojiPost] ? [UIFont systemFontOfSize:replyTextViewFont.pointSize*REPLY_POST_EMOJI_SIZE_MULTIPLIER] : replyTextViewFont;
        
        NSString *message;
        if ([post isRemoved]) {
            message = post.attributes.removedReason;
        }
        else {
            message = post.attributes.simpleMessage;
        }
            
        CGFloat messageHeight = [PostTextView sizeOfBubbleWithMessage:message withConstraints:CGSizeMake(screenWidth - contentEdgeInsets.left - contentEdgeInsets.right - REPLY_BUBBLE_INSETS.left - REPLY_BUBBLE_INSETS.right, CGFLOAT_MAX) font:font maxCharacters:[PostTextView entityBasedMaxCharactersForMessage:post.attributes.simpleMessage maxCharacters:REPLY_POST_MAX_CHARACTERS entities:post.attributes.entities] styleAsBubble:true].height;

        CGFloat textViewHeight = ceilf(messageHeight);
        height += textViewHeight;
    }
    else {
        // no message, but has image
    }
    
    BOOL hasSubReplies = post.attributes.summaries.counts.replies > 0;
    if (hasSubReplies) {
        height += repliesButtonHeight;
    }
    
    if (height == baseHeight) {
        return 0;
    }
    
//    if (attachments > 0) {
//        height -= attachmentBottomPadding;
//    }
    
    return height;
}

+ (CGFloat)heightForComponent:(BFStreamComponent *)component {
    Post *post = component.post;
    
    if (!post) return 0;
    
    return [ReplyCell heightForPost:post levelsDeep:-1];
}

@end
