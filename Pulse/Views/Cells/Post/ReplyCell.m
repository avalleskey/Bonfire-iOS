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

#define REPLY_POST_MAX_CHARACTERS 125
#define REPLY_BUBBLE_INSETS UIEdgeInsetsMake(0, 0, 0, 0)

@implementation ReplyCell

@synthesize post = _post;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.primaryAvatarView.frame = CGRectMake(70, replyContentOffset.top, 32, 32);
        self.primaryAvatarView.openOnTap = false;
        self.primaryAvatarView.dimsViewOnTap = true;
        
        self.moreButton.hidden = true;
        
        self.nameLabel.frame = CGRectMake(70, replyContentOffset.top, self.contentView.frame.size.width - 72 - replyContentOffset.right, 18);
        self.nameLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightSemibold];
        self.nameLabel.text = @"Display Name";
        self.nameLabel.userInteractionEnabled = YES;
        
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
        self.imagesView.layer.cornerRadius = 12.f;
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
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    UIEdgeInsets offset = replyContentOffset;
    
    // content view size
    
    if (![self.moreButton isHidden]) {
        CGFloat moreButtonPadding = 12;
        CGFloat moreButtonWidth = self.moreButton.currentImage.size.width + (moreButtonPadding * 2);
        self.moreButton.frame = CGRectMake(self.frame.size.width - moreButtonWidth - replyContentOffset.right + moreButtonPadding, self.primaryAvatarView.frame.origin.y - moreButtonPadding, moreButtonWidth, self.primaryAvatarView.frame.size.height + (moreButtonPadding * 2));
    }
    
    self.nameLabel.frame = CGRectMake(offset.left, self.primaryAvatarView.frame.origin.y, self.frame.size.width - offset.left - offset.right, 16);
    CGFloat yBottom = self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height;
    
    // -- text view
    self.textView.frame = CGRectMake(offset.left, yBottom + 3, self.frame.size.width - offset.left - offset.right, self.textView.frame.size.height);
    if (self.post.attributes.details.simpleMessage.length > 0) {
        self.textView.tintColor = self.tintColor;
        [self.textView update];
        yBottom = self.textView.frame.origin.y + self.textView.frame.size.height;
    }
    
    BOOL hasImage = self.post.attributes.details.media.count > 0 || self.post.attributes.details.attachments.media.count > 0;
    self.imagesView.hidden = !hasImage;
    if (hasImage) {
        CGFloat imageHeight = [PostImagesView streamImageHeight] * .8;
        self.imagesView.frame = CGRectMake(offset.left, yBottom + 6, self.frame.size.width - offset.left - offset.right, imageHeight);
        
        // yBottom = self.imagesView.frame.origin.y + self.imagesView.frame.size.height;
    }
    else {
        // yBottom = self.textView.frame.origin.y + self.textView.frame.size.height;
    }
    
    // self.actionsView.frame = CGRectMake(offset.left, yBottom + 6, self.frame.size.width - offset.left - offset.right, self.actionsView.frame.size.height);
    
     NSInteger profilePicPadding = 4;
     self.topLine.frame = CGRectMake(self.primaryAvatarView.frame.origin.x + (self.primaryAvatarView.frame.size.width / 2) - (self.topLine.frame.size.width / 2), - (self.topLine.layer.cornerRadius / 2), self.topLine.frame.size.width, self.primaryAvatarView.frame.origin.y - profilePicPadding + (self.topLine.layer.cornerRadius / 2));
     
     self.bottomLine.hidden = self.bottomCell;
     if (![self.bottomLine isHidden]) {
     self.bottomLine.frame = CGRectMake(self.primaryAvatarView.frame.origin.x + (self.primaryAvatarView.frame.size.width / 2) - (self.bottomLine.frame.size.width / 2), self.primaryAvatarView.frame.origin.y + self.primaryAvatarView.frame.size.width + profilePicPadding, self.bottomLine.frame.size.width, self.frame.size.height - (self.primaryAvatarView.frame.origin.y + self.primaryAvatarView.frame.size.width + profilePicPadding) + (self.bottomLine.layer.cornerRadius / 2));
     }
    
    if (!self.lineSeparator.isHidden) {
        // self.lineSeparator.frame = CGRectMake(self.profilePicture.frame.origin.x, self.frame.size.height - self.lineSeparator.frame.size.height, self.frame.size.width - self.profilePicture.frame.origin.x, self.lineSeparator.frame.size.height);
        self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - self.lineSeparator.frame.size.height, self.frame.size.width, self.lineSeparator.frame.size.height);
    }
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
            
            if (self.post.attributes.details.message.length == 0)
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
}*/

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (self.selectable) {
        if (highlighted) {
            [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.backgroundColor = [UIColor contentHighlightedColor];
            } completion:nil];
        }
        else {
            [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.backgroundColor = [UIColor contentBackgroundColor];
            } completion:nil];
        }
    }
}

- (void)setPost:(Post *)post {
    if ([post toDictionary] != [_post toDictionary]) {
        _post = post;
        
        self.nameLabel.attributedText = [PostCell attributedCreatorStringForPost:_post includeTimestamp:true showCamptag:false];
        
        self.userInteractionEnabled = (!_post.tempId);
        if (self.contentView.alpha != 1 && !_post.tempId) {
            [UIView animateWithDuration:0.15f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.contentView.alpha = 1;
            } completion:^(BOOL finished) {
                
            }];
        }
        else {
            self.contentView.alpha = (_post.tempId ? 0.5 : 1);
        }
        
        UIFont *font = [post isEmojiPost] ? [UIFont systemFontOfSize:textViewFont.pointSize*2] : replyTextViewFont;
        self.textView.messageLabel.font = font;
        self.textView.postId = self.post.identifier;
        
        [self.textView setMessage:self.post.attributes.details.simpleMessage entities:self.post.attributes.details.entities];
        
        if (self.primaryAvatarView.user != _post.attributes.details.creator) {
            self.primaryAvatarView.user = _post.attributes.details.creator;
        }
        
        self.primaryAvatarView.online = false;
        
        // [self setVoted:(_post.attributes.context.post.vote != nil) animated:false];
        
        if (self.post.attributes.details.attachments.media.count > 0) {
            [self.imagesView setMedia:self.post.attributes.details.attachments.media];
        }
        else if (self.post.attributes.details.media.count > 0) {
            [self.imagesView setMedia:self.post.attributes.details.media];
        }
        else {
            [self.imagesView setMedia:@[]];
        }
    }
}

+ (CGFloat)heightForPost:(Post *)post {    
    CGFloat height = replyContentOffset.top;
    
    /*
     BOOL hasContext = false;
     if (hasContext) {
     height = height + postContextHeight + 8;
     }*/
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    CGFloat headerHeight = 16; // 3pt padding underneath
    height = height + headerHeight;
    
    // message
    if (post.attributes.details.simpleMessage.length > 0) {
        UIFont *font = [post isEmojiPost] ? [UIFont systemFontOfSize:textViewFont.pointSize*POST_EMOJI_SIZE_MULTIPLIER] : replyTextViewFont;
        
        CGFloat messageHeight = [PostTextView sizeOfBubbleWithMessage:post.attributes.details.simpleMessage withConstraints:CGSizeMake(screenWidth - replyContentOffset.left - replyContentOffset.right - REPLY_BUBBLE_INSETS.left - REPLY_BUBBLE_INSETS.right, CGFLOAT_MAX) font:font maxCharacters:[PostTextView entityBasedMaxCharactersForMessage:post.attributes.details.simpleMessage maxCharacters:REPLY_POST_MAX_CHARACTERS entities:post.attributes.details.entities]].height;
//
        CGFloat textViewHeight = ceilf(messageHeight) + 3; // 4 on top
        height = height + textViewHeight;
    }
    
    // image
    BOOL hasImage = (post.attributes.details.media.count > 0 || post.attributes.details.attachments.media.count > 0); // postAtIndex.images != nil && postAtIndex.images.count > 0;
    if (hasImage) {
        CGFloat imageHeight = [PostImagesView streamImageHeight] * .8;
        imageHeight = imageHeight + 6; // 6 above
        height = height + imageHeight;
    }
    
    // details view
    CGFloat detailsHeight = 0; // 6 + POST_ACTIONS_VIEW_HEIGHT; // 6 + 32; // 8 above
    height = height + detailsHeight + replyContentOffset.bottom;
    
    return height;
}

@end
