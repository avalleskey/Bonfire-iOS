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

#define REPLY_POST_MAX_CHARACTERS 125
#define REPLY_POST_EMOJI_SIZE_MULTIPLIER 1.5

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
        self.contentView.layer.masksToBounds = false;
        
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor clearColor];
        
        self.primaryAvatarView.frame = CGRectMake(replyContentOffset.left, replyContentOffset.top, 24, 24);
        
        self.moreButton.hidden = true;
        
        self.nameLabel.font = [UIFont systemFontOfSize:11.f weight:UIFontWeightRegular];
        self.nameLabel.frame = CGRectMake(70, replyContentOffset.top, self.contentView.frame.size.width - 72 - replyContentOffset.right, ceilf(self.nameLabel.font.lineHeight));
        self.nameLabel.text = @"Display Name";
        self.nameLabel.userInteractionEnabled = YES;
        self.nameLabel.textColor = [[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0.8];
        
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
        
        self.bubbleBackgroundView = [[UIView alloc] init];
        self.bubbleBackgroundView.layer.masksToBounds = false;
        [self.contentView insertSubview:self.bubbleBackgroundView belowSubview:self.primaryAvatarView];
        
        self.bubbleBackgroundDot1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        self.bubbleBackgroundDot1.layer.cornerRadius = self.bubbleBackgroundDot1.frame.size.height / 2;
        self.bubbleBackgroundDot1.layer.masksToBounds = true;
        self.bubbleBackgroundDot1.backgroundColor = [UIColor whiteColor];
        self.bubbleBackgroundDot1.alpha = 1;
        [self.contentView insertSubview:self.bubbleBackgroundDot1 belowSubview:self.bubbleBackgroundView];
        
        self.bubbleBackgroundDot2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 6, 6)];
        self.bubbleBackgroundDot2.layer.cornerRadius = self.bubbleBackgroundDot2.frame.size.height / 2;
        self.bubbleBackgroundDot2.layer.masksToBounds = true;
        self.bubbleBackgroundDot2.backgroundColor = [UIColor whiteColor];
        self.bubbleBackgroundDot2.alpha = 0.25;
        [self.contentView insertSubview:self.bubbleBackgroundDot2 belowSubview:self.bubbleBackgroundView];
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
    
    CGFloat bubbleCornerRadius = (self.textView.messageLabel.font.lineHeight+REPLY_BUBBLE_INSETS.top+REPLY_BUBBLE_INSETS.bottom)/2;
    
    CGFloat yBottom = contentEdgeInsets.top;
    
    if (self.levelsDeep == 0) {
        CGFloat nameLabelWidth = ceilf([self.nameLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - contentEdgeInsets.left - contentEdgeInsets.right - REPLY_BUBBLE_INSETS.left - REPLY_BUBBLE_INSETS.right, self.nameLabel.frame.size.height) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: self.nameLabel.font} context:nil].size.width);
        self.nameLabel.frame = CGRectMake(contentEdgeInsets.left + REPLY_BUBBLE_INSETS.left, yBottom, nameLabelWidth, ceilf(self.nameLabel.font.lineHeight));
        yBottom = self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height;
    }
    
    CGFloat attachmentBottomPadding = 2;
    
    BOOL hasImage = self.post.attributes.media.count > 0 || self.post.attributes.attachments.media.count > 0;
    self.imagesView.hidden = !hasImage;
    if (hasImage) {
        CGFloat imageHeight = [PostImagesView streamImageHeight] * .8;
        self.imagesView.frame = CGRectMake(contentEdgeInsets.left, yBottom, self.frame.size.width - contentEdgeInsets.left - contentEdgeInsets.right, imageHeight);
        [self continuityRadiusForView:self.imagesView withRadius:(replyTextViewFont.lineHeight+REPLY_BUBBLE_INSETS.top+REPLY_BUBBLE_INSETS.bottom)/2];
        
         yBottom = self.imagesView.frame.origin.y + self.imagesView.frame.size.height + attachmentBottomPadding;
    }
    
    if (self.linkAttachmentView) {
        [self.linkAttachmentView layoutSubviews];
        self.linkAttachmentView.frame = CGRectMake(contentEdgeInsets.left, yBottom, self.frame.size.width - contentEdgeInsets.left - contentEdgeInsets.right, [BFLinkAttachmentView heightForLink:self.linkAttachmentView.link width: self.frame.size.width-(contentEdgeInsets.left+contentEdgeInsets.right)]);
        
        yBottom = self.linkAttachmentView.frame.origin.y + self.linkAttachmentView.frame.size.height + attachmentBottomPadding;
    }
    
    if (self.smartLinkAttachmentView) {
        [self.smartLinkAttachmentView layoutSubviews];
        self.smartLinkAttachmentView.frame = CGRectMake(contentEdgeInsets.left, yBottom, self.frame.size.width - contentEdgeInsets.left - contentEdgeInsets.right, [BFSmartLinkAttachmentView heightForSmartLink:self.smartLinkAttachmentView.link width: self.frame.size.width-(contentEdgeInsets.left+contentEdgeInsets.right) showActionButton:true]);
        
        yBottom = self.smartLinkAttachmentView.frame.origin.y + self.smartLinkAttachmentView.frame.size.height + attachmentBottomPadding;
    }
    
    if (self.campAttachmentView) {
        [self.campAttachmentView layoutSubviews];
        self.campAttachmentView.frame = CGRectMake(contentEdgeInsets.left, yBottom, self.frame.size.width - contentEdgeInsets.left - contentEdgeInsets.right, [BFCampAttachmentView heightForCamp:self.campAttachmentView.camp width: self.frame.size.width-(contentEdgeInsets.left+contentEdgeInsets.right)]);
        
        yBottom = self.campAttachmentView.frame.origin.y + self.campAttachmentView.frame.size.height + attachmentBottomPadding;
    }
    
    if (self.identityAttachmentView) {
        [self.identityAttachmentView layoutSubviews];
        self.identityAttachmentView.frame = CGRectMake(contentEdgeInsets.left, yBottom, self.frame.size.width - contentEdgeInsets.left - contentEdgeInsets.right, [BFIdentityAttachmentView heightForIdentity:self.identityAttachmentView.identity width: self.frame.size.width-(contentEdgeInsets.left+contentEdgeInsets.right)]);
        
        yBottom = self.identityAttachmentView.frame.origin.y + self.identityAttachmentView.frame.size.height + attachmentBottomPadding;
    }
    
    // -- text view
    if (self.post.attributes.simpleMessage.length > 0 ||
        self.post.attributes.removedReason.length > 0) {
        self.textView.frame = CGRectMake(contentEdgeInsets.left + REPLY_BUBBLE_INSETS.left, yBottom + REPLY_BUBBLE_INSETS.top, self.frame.size.width - contentEdgeInsets.left - contentEdgeInsets.right - REPLY_BUBBLE_INSETS.left - REPLY_BUBBLE_INSETS.right, self.textView.frame.size.height);
        
        self.textView.tintColor = self.tintColor;
        [self.textView update];
        
        CGFloat bubbleWidth = self.textView.messageLabel.frame.size.width;
        
        bubbleWidth += (REPLY_BUBBLE_INSETS.left + REPLY_BUBBLE_INSETS.right);
        self.bubbleBackgroundView.frame = CGRectMake(contentEdgeInsets.left, self.textView.frame.origin.y - REPLY_BUBBLE_INSETS.top, bubbleWidth, self.textView.messageLabel.frame.size.height + REPLY_BUBBLE_INSETS.top + REPLY_BUBBLE_INSETS.bottom);
        [self continuityRadiusForView:self.bubbleBackgroundView withRadius:bubbleCornerRadius];
        yBottom = self.bubbleBackgroundView.frame.origin.y + self.bubbleBackgroundView.frame.size.height;
        
        CGFloat bubbleDotSize1 = bubbleCornerRadius * 0.7;
        self.bubbleBackgroundDot1.frame = CGRectMake(self.bubbleBackgroundView.frame.origin.x, self.bubbleBackgroundView.frame.origin.y + self.bubbleBackgroundView.frame.size.height - bubbleDotSize1 - (bubbleDotSize1 * 0.05), bubbleDotSize1, bubbleDotSize1);
        self.bubbleBackgroundDot1.layer.cornerRadius = self.bubbleBackgroundDot1.frame.size.height / 2;
        
        CGFloat bubbleDotSize2 = bubbleCornerRadius * 0.25;
        self.bubbleBackgroundDot2.frame = CGRectMake(self.bubbleBackgroundView.frame.origin.x - (bubbleDotSize2 * 1.35), self.bubbleBackgroundView.frame.origin.y + self.bubbleBackgroundView.frame.size.height - bubbleDotSize2, bubbleDotSize2, bubbleDotSize2);
        self.bubbleBackgroundDot2.layer.cornerRadius = self.bubbleBackgroundDot2.frame.size.height / 2;
    }
    
    if (![self.topLevelReplyButton isHidden]) {
        self.topLevelReplyButton.frame = CGRectMake(self.bubbleBackgroundView.frame.origin.x + self.bubbleBackgroundView.frame.size.width + ceilf(REPLY_BUBBLE_INSETS.right * .5), self.bubbleBackgroundView.frame.origin.y + self.bubbleBackgroundView.frame.size.height / 2 - self.topLevelReplyButton.frame.size.height / 2, self.topLevelReplyButton.frame.size.width, self.topLevelReplyButton.frame.size.height);
    }
    
    CGFloat avatarSize = [ReplyCell avatarSizeForLevel:self.levelsDeep];
    self.primaryAvatarView.frame = CGRectMake(edgeInsets.left, 0, avatarSize, avatarSize);
    self.primaryAvatarView.center = CGPointMake(self.primaryAvatarView.center.x, yBottom - bubbleCornerRadius);
        
     NSInteger profilePicPadding = 4;
     self.topLine.frame = CGRectMake(self.primaryAvatarView.frame.origin.x + (self.primaryAvatarView.frame.size.width / 2) - (self.topLine.frame.size.width / 2), - (self.topLine.layer.cornerRadius / 2), self.topLine.frame.size.width, self.primaryAvatarView.frame.origin.y - profilePicPadding + (self.topLine.layer.cornerRadius / 2));
     
     if (![self.bottomLine isHidden]) {
         self.bottomLine.frame = CGRectMake(self.primaryAvatarView.frame.origin.x + (self.primaryAvatarView.frame.size.width / 2) - (self.bottomLine.frame.size.width / 2), self.primaryAvatarView.frame.origin.y + self.primaryAvatarView.frame.size.width + profilePicPadding, self.bottomLine.frame.size.width, self.frame.size.height - (self.primaryAvatarView.frame.origin.y + self.primaryAvatarView.frame.size.width + profilePicPadding) + (self.bottomLine.layer.cornerRadius / 2));
     }
    
    if (!self.lineSeparator.isHidden) {
        self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - self.lineSeparator.frame.size.height, self.frame.size.width, self.lineSeparator.frame.size.height);
    }
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
    
    return 24;
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
    
    if (self.post.attributes.message.length == 0 &&
        self.post.attributes.removedReason.length == 0) {
        self.bubbleBackgroundView.backgroundColor = [UIColor clearColor];
//        self.bubbleBackgroundView.layer.shadowOpacity = 0;
        self.bubbleBackgroundView.alpha = 1;
//        self.textView.textColor = [UIColor bonfirePrimaryColor];
//        self.nameLabel.tintColor = [UIColor bonfirePrimaryColor];
        
        //self.textView.messageLabel.linkAttributes = @{(__bridge NSString *)kCTForegroundColorAttributeName: [UIColor linkColor]};
        self.topLevelReplyButton.hidden = true;
    }
    else {
        if (_levelsDeep == -1) {
            self.bubbleBackgroundView.backgroundColor = [UIColor colorNamed:@"BubbleColor"];
//            self.bubbleBackgroundView.layer.shadowOpacity = 0;
            self.bubbleBackgroundView.alpha = 1;
            self.textView.textColor = [UIColor bonfirePrimaryColor];
            self.textView.messageLabel.tintColor = [UIColor linkColor];
            self.bubbleBackgroundDot2.alpha = 0.75;
            
            self.topLevelReplyButton.hidden = true;
        }
        else if (_levelsDeep == 0) {
            self.bubbleBackgroundView.backgroundColor = [UIColor fromHex:[UIColor toHex:self.tintColor] adjustForOptimalContrast:false];//[UIColor fromHex:[UIColor toHex:self.tintColor] adjustForOptimalContrast:false];
//            self.bubbleBackgroundView.layer.shadowOpacity = 0;
            self.bubbleBackgroundDot2.alpha = 0.5;
            
            UIColor *textColor = [UIColor useWhiteForegroundForColor:self.bubbleBackgroundView.backgroundColor] ? [UIColor whiteColor] : [UIColor blackColor];
            self.textView.textColor = textColor;
            self.textView.messageLabel.tintColor = [textColor colorWithAlphaComponent:0.8];
//            self.nameLabel.tintColor = textColor;
            
            self.topLevelReplyButton.hidden = [self.post isRemoved];
        }
        else {
            self.bubbleBackgroundView.backgroundColor = [UIColor tableViewBackgroundColor];//[UIColor fromHex:[UIColor toHex:[UIColor darkerColorForColor:self.tintColor amount:0.1]] adjustForOptimalContrast:false];
//            self.bubbleBackgroundView.layer.shadowOpacity = 0;
            self.bubbleBackgroundDot2.alpha = 0.25;
            
            UIColor *textColor = [UIColor useWhiteForegroundForColor:self.bubbleBackgroundView.backgroundColor] ? [UIColor whiteColor] : [UIColor blackColor];
            self.textView.textColor = textColor;
            self.textView.messageLabel.tintColor = [textColor colorWithAlphaComponent:0.8];
//            self.nameLabel.tintColor = textColor;
            
            //self.textView.messageLabel.linkAttributes = @{(__bridge NSString *)kCTForegroundColorAttributeName: [UIColor linkColor]};
            self.topLevelReplyButton.hidden = true;
        }
    }
    self.nameLabel.hidden = self.levelsDeep != 0;
    self.bubbleBackgroundDot1.backgroundColor = self.bubbleBackgroundView.backgroundColor;
    self.bubbleBackgroundDot2.backgroundColor = self.bubbleBackgroundView.backgroundColor;
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
        
        if ([self.post isRemoved]) {
            [self.textView setMessage:self.post.attributes.removedReason entities:nil];
            self.textView.alpha = 0.5;
        }
        else {
            [self.textView setMessage:self.post.attributes.simpleMessage entities:self.post.attributes.entities];
            self.textView.alpha = 1;
        }
        
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
    }
}

+ (CGFloat)heightForPost:(Post *)post levelsDeep:(NSInteger)levelsDeep {
    UIEdgeInsets contentEdgeInsets = [ReplyCell contentEdgeInsetsForLevel:levelsDeep];
    if (levelsDeep == 0 && [post isRemoved]) {
        contentEdgeInsets.right = replyContentOffset.right;
    }
    
    CGFloat height = contentEdgeInsets.top;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    if (levelsDeep == 0) {
        CGFloat headerHeight = ceilf([UIFont systemFontOfSize:11.f weight:UIFontWeightRegular].lineHeight); // 3pt padding underneath
        height += headerHeight;
    }
    
    CGFloat attachmentBottomPadding = 2;
    
    // image
    BOOL hasImage = (post.attributes.media.count > 0 || post.attributes.attachments.media.count > 0); // postAtIndex.images != nil && postAtIndex.images.count > 0;
    if (hasImage) {
        CGFloat imageHeight = [PostImagesView streamImageHeight] * .8;
        imageHeight = imageHeight;
        height = height + imageHeight + attachmentBottomPadding;
    }
    
    // link
    BOOL hasLinkPreview = [post hasLinkAttachment];
    if (hasLinkPreview) {
        CGFloat linkPreviewHeight;
        if ([post.attributes.attachments.link isSmartLink]) {
            linkPreviewHeight = [BFSmartLinkAttachmentView heightForSmartLink:post.attributes.attachments.link  width:screenWidth-contentEdgeInsets.left-contentEdgeInsets.right showActionButton:true];
        }
        else {
            linkPreviewHeight = [BFLinkAttachmentView heightForLink:post.attributes.attachments.link  width:screenWidth-contentEdgeInsets.left-contentEdgeInsets.right];
        }

        height = height + linkPreviewHeight + attachmentBottomPadding;
    }
    
    // camp
    BOOL hasCampAttachment = [post hasCampAttachment];
    if (hasCampAttachment) {
        Camp *camp = post.attributes.attachments.camp;
        
        CGFloat campAttachmentHeight = [BFCampAttachmentView heightForCamp:camp width:screenWidth-contentEdgeInsets.left-contentEdgeInsets.right];
        height = height + campAttachmentHeight + attachmentBottomPadding;
    }
    
    // user
    BOOL hasUserAttachment = [post hasUserAttachment];
    if (hasUserAttachment) {
        User *user = post.attributes.attachments.user;
        
        CGFloat userAttachmentHeight = [BFIdentityAttachmentView heightForIdentity:user width:screenWidth-contentEdgeInsets.left-contentEdgeInsets.right];
        height = height + userAttachmentHeight + attachmentBottomPadding;
    }
    
    // message
    if (post.attributes.simpleMessage.length > 0 || post.attributes.removedReason.length > 0) {
        UIFont *font = [post isEmojiPost] ? [UIFont systemFontOfSize:replyTextViewFont.pointSize*REPLY_POST_EMOJI_SIZE_MULTIPLIER] : replyTextViewFont;
        
        NSString *message;
        if ([post isRemoved]) {
            message = post.attributes.removedReason;
        }
        else {
            message = post.attributes.simpleMessage;
        }
            
        CGFloat messageHeight = [PostTextView sizeOfBubbleWithMessage:message withConstraints:CGSizeMake(screenWidth - contentEdgeInsets.left - contentEdgeInsets.right - REPLY_BUBBLE_INSETS.left - REPLY_BUBBLE_INSETS.right, CGFLOAT_MAX) font:font maxCharacters:[PostTextView entityBasedMaxCharactersForMessage:post.attributes.simpleMessage maxCharacters:REPLY_POST_MAX_CHARACTERS entities:post.attributes.entities] styleAsBubble:true].height;

        CGFloat textViewHeight = ceilf(messageHeight); // 4 on top
        height += textViewHeight + REPLY_BUBBLE_INSETS.bottom;
    }
    
    // details view
    CGFloat detailsHeight = 0;
    height = REPLY_BUBBLE_INSETS.top + height + detailsHeight + contentEdgeInsets.bottom;
    
    return height;
}

@end
