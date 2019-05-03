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

@implementation ReplyCell

@synthesize post = _post;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.profilePicture.frame = CGRectMake(80, replyContentOffset.top, 32, 32);
        self.profilePicture.openOnTap = false;
        self.profilePicture.dimsViewOnTap = true;
        self.profilePicture.allowOnlineDot = true;
        
        self.nameLabel.frame = CGRectMake(replyContentOffset.left, replyContentOffset.top, self.contentView.frame.size.width - replyContentOffset.left - replyContentOffset.right, 18);
        self.nameLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightSemibold];
        self.nameLabel.text = @"Display Name";
        self.nameLabel.userInteractionEnabled = YES;
        
        self.dateLabel.frame = CGRectMake(0, self.nameLabel.frame.origin.y, self.nameLabel.frame.origin.y, self.nameLabel.frame.size.height);
        self.dateLabel.font = [UIFont systemFontOfSize:self.nameLabel.font.pointSize weight:UIFontWeightRegular];
        self.dateLabel.textAlignment = NSTextAlignmentRight;
        
        self.sparked = false;
        
        // text view
        self.textView.frame = CGRectMake(replyContentOffset.left, 28, self.contentView.frame.size.width - (replyContentOffset.left + replyContentOffset.right), 200);
        self.textView.messageLabel.font = textViewFont;
        self.textView.delegate = self;
        
        self.actionsView = [[PostActionsView alloc] initWithFrame:CGRectMake(self.nameLabel.frame.origin.x + postTextViewInset.left, 0, self.nameLabel.frame.size.width - (postTextViewInset.left + postTextViewInset.right), POST_ACTIONS_VIEW_HEIGHT)];
        [self.actionsView.sparkButton bk_whenTapped:^{
            [self setSparked:!self.sparked animated:YES];
            
            if (self.sparked) {
                // not sparked -> spark it
                [BFAPI sparkPost:self.post completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // NSLog(@"success upvoting!");
                    }
                }];
            }
            else {
                // not sparked -> spark it
                [BFAPI unsparkPost:self.post completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // NSLog(@"success downvoting.");
                    }
                }];
            }
        }];
        [self.contentView addSubview:self.actionsView];
        
        // image view
        self.imagesView.frame = CGRectMake(self.textView.frame.origin.x, 56, self.textView.frame.size.width, [PostImagesView streamImageHeight]);
        self.imagesView.layer.cornerRadius = 8.f;
        self.imagesView.userInteractionEnabled = true;
        
        self.insetLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 3, 0)];
        self.insetLine.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.96 alpha:1.0];
//        self.insetLine.layer.cornerRadius = self.insetLine.frame.size.width / 2;
        //[self.contentView addSubview:self.insetLine];
        
        self.lineSeparator.hidden = false;
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    UIEdgeInsets offset = replyContentOffset;
    
    CGFloat yBottom = offset.top;
    
    if (![self.moreButton isHidden]) {
        CGFloat moreButtonPadding = 8;
        CGFloat moreButtonWidth = self.moreButton.currentImage.size.width + (moreButtonPadding * 2);
        self.moreButton.frame = CGRectMake(self.frame.size.width - moreButtonWidth - replyContentOffset.right + moreButtonPadding, yBottom - moreButtonPadding, moreButtonWidth, self.nameLabel.frame.size.height + (moreButtonPadding * 2));
    }
    
    CGSize dateLabelSize = [self.dateLabel.text boundingRectWithSize:CGSizeMake(100, self.actionsView.frame.size.height) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: self.dateLabel.font} context:nil].size;
    self.dateLabel.frame = CGRectMake(self.moreButton.frame.origin.x - ceilf(dateLabelSize.width), yBottom, ceilf(dateLabelSize.width), self.dateLabel.frame.size.height);
    self.nameLabel.frame = CGRectMake(offset.left, yBottom + 3, (self.dateLabel.frame.origin.x - 8) - offset.left, self.nameLabel.frame.size.height);
    yBottom = self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height;
    
    // -- text view
    self.textView.tintColor = self.tintColor;
    self.textView.frame = CGRectMake(offset.left, yBottom, self.frame.size.width - offset.left - offset.right, self.textView.frame.size.height);
    [self.textView update];
    yBottom = self.textView.frame.origin.y + self.textView.frame.size.height;
    
    BOOL hasImage = self.post.attributes.details.media.count > 0 || self.post.attributes.details.attachments.media.count > 0;
    self.imagesView.hidden = !hasImage;
    if (hasImage) {
        CGFloat imageHeight = [PostImagesView streamImageHeight] * .8;
        self.imagesView.frame = CGRectMake(offset.left, yBottom + 4, self.textView.frame.size.width, imageHeight);
        
        yBottom = self.imagesView.frame.origin.y + self.imagesView.frame.size.height;
    }
    else {
        yBottom = self.textView.frame.origin.y + self.textView.frame.size.height;
    }
    
    self.actionsView.frame = CGRectMake(offset.left, yBottom + 6, self.frame.size.width - offset.left - offset.right, self.actionsView.frame.size.height);
    
    self.insetLine.frame = CGRectMake(0, self.topCell?replyContentOffset.top:-2, 12, self.frame.size.height);
    
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
 
 [self setSparked:!self.sparked withAnimation:SparkAnimationTypeAll];
 }*/
- (void)setSparked:(BOOL)isSparked animated:(BOOL)animated {
    if (!animated || (isSparked != self.sparked)) {
        self.sparked = isSparked;
        
        [self.actionsView setSparked:isSparked animated:animated];
        
        void(^rippleAnimation)(void) = ^() {
            if (!self.sparked)
                return;
            
            if (self.post.attributes.details.message.length == 0)
                return;
            
            CGFloat bubbleDiamater = self.frame.size.width * 1.6;
            UIView *bubble = [[UIView alloc] initWithFrame:CGRectMake(0, 0, bubbleDiamater, bubbleDiamater)];
            bubble.userInteractionEnabled = false;
            bubble.center = self.textView.center;
            bubble.backgroundColor = [self.actionsView.sparkButton.tintColor colorWithAlphaComponent:0.06];
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

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (self.selectable) {
        if (highlighted) {
            // panRecognizer.enabled = false;
            [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                // self.transform = CGAffineTransformMakeScale(0.9, 0.9);
                self.contentView.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
            } completion:nil];
        }
        else {
            // panRecognizer.enabled = true;
            [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                // self.transform = CGAffineTransformMakeScale(1, 1);
                self.contentView.backgroundColor = [UIColor whiteColor];
            } completion:nil];
        }
    }
}

- (void)setPost:(Post *)post {
    if ([post toDictionary] != [_post toDictionary]) {
        _post = post;
        // BOOL isCreator = [cell.post.attributes.details.creator.identifier isEqualToString:[Session sharedInstance].currentUser.identifier];
        
        self.nameLabel.attributedText = [PostCell attributedCreatorStringForPost:_post includeTimestamp:false includeContext:false];
        
        self.actionsView.userInteractionEnabled = (!_post.tempId);
        self.actionsView.alpha = (_post.tempId ? 0.5 : 1);
        if (_post.tempId) {
            self.dateLabel.text = @"1s";
            
            self.userInteractionEnabled = false;
        }
        else {
            NSString *timeAgo = [NSDate mysqlDatetimeFormattedAsTimeAgo:_post.attributes.status.createdAt withForm:TimeAgoShortForm];
            self.dateLabel.text = timeAgo;
            
            self.userInteractionEnabled = true;
        }
        
        UIFont *font = [post isEmojiPost] ? [UIFont systemFontOfSize:textViewFont.pointSize*2] : textViewFont;
        self.textView.messageLabel.font = font;
        self.textView.message = _post.attributes.details.simpleMessage;
        
        if (self.profilePicture.user != _post.attributes.details.creator) {
            self.profilePicture.user = _post.attributes.details.creator;
        }
        
        self.profilePicture.online = false;
        
        [self setSparked:(_post.attributes.context.vote != nil) animated:false];
        
        if (self.post.attributes.details.attachments.media.count > 0) {
            [self.imagesView setMedia:self.post.attributes.details.attachments.media];
        }
        else if (self.post.attributes.details.media.count > 0) {
            [self.imagesView setMedia:self.post.attributes.details.media];
        }
        else {
            [self.imagesView setMedia:@[]];
        }
        
        [self.actionsView updateWithSummaries:post.attributes.summaries];
    }
}
- (void)addTapHandlersToAction:(UIButton *)action {
    [action bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            action.transform = CGAffineTransformMakeScale(0.92, 0.92);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    [action bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            action.transform = CGAffineTransformIdentity;
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
}

+ (CGFloat)heightForPost:(Post *)post {    
    CGFloat height = replyContentOffset.top;
    
    /*
     BOOL hasContext = false;
     if (hasContext) {
     height = height + postContextHeight + 8;
     }*/
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    CGFloat nameHeight = 18 + 3; // 3pt padding underneath
    height = height + nameHeight;
    
    // message
    UIFont *font = [post isEmojiPost] ? [UIFont systemFontOfSize:textViewFont.pointSize*POST_EMOJI_SIZE_MULTIPLIER] : textViewFont;
    CGSize messageSize = [PostTextView sizeOfBubbleWithMessage:post.attributes.details.simpleMessage withConstraints:CGSizeMake(screenWidth - replyContentOffset.left - replyContentOffset.right, CGFLOAT_MAX) font:font];
    CGFloat textViewHeight = post.attributes.details.message.length == 0 ? 0 :  ceilf(messageSize.height);
    height = height + textViewHeight;
    
    // image
    BOOL hasImage = (post.attributes.details.media.count > 0 || post.attributes.details.attachments.media.count > 0); // postAtIndex.images != nil && postAtIndex.images.count > 0;
    if (hasImage) {
        CGFloat imageHeight = [PostImagesView streamImageHeight] * .8;
        imageHeight = imageHeight + 4; // 8 above
        height = height + imageHeight;
    }
    
    // 4 on top and 4 on bottom
    BOOL hasURLPreview = [post requiresURLPreview];
    if (hasURLPreview) {
        CGFloat urlPreviewHeight = !hasImage && hasURLPreview ? [PostImagesView streamImageHeight] + 4 : 0; // 4 on bottom
        height = height + urlPreviewHeight;
    }
    
    // details view
    CGFloat detailsHeight = 6 + POST_ACTIONS_VIEW_HEIGHT; // 6 + 32; // 8 above
    height = height + detailsHeight + replyContentOffset.bottom;
    
    return height;
}

@end
