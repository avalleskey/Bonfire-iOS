//
//  MiniReplyCell.m
//  Pulse
//
//  Created by Austin Valleskey on 3/10/18.
//  Copyright © 2018 Ingenious, Inc. All rights reserved.
//

#import "MiniReplyCell.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import <SafariServices/SafariServices.h>
#import <HapticHelper/HapticHelper.h>
#import "Session.h"
#import "ComplexNavigationController.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import <Tweaks/FBTweakInline.h>
#import "ReplyCell.h"

@implementation MiniReplyCell

@synthesize post = _post;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectable = true;
        
        self.profilePicture.openOnTap = false;
        self.profilePicture.dimsViewOnTap = true;
        self.profilePicture.allowOnlineDot = true;
        
        self.nameLabel.frame = CGRectMake(miniReplyContentOffset.left, miniReplyContentOffset.top, self.contentView.frame.size.width - miniReplyContentOffset.left - miniReplyContentOffset.right, 15);
        self.nameLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold];
        self.nameLabel.text = @"Display Name";
        self.nameLabel.textColor = [UIColor colorWithWhite:0.33f alpha:1];
        self.nameLabel.userInteractionEnabled = YES;
        
        self.sparked = false;
        
        // text view
        self.textView.frame = CGRectMake(miniReplyContentOffset.left - miniReplyBubbleInset.left, 58, self.contentView.frame.size.width - (miniReplyContentOffset.left + miniReplyContentOffset.right), 200);
        self.textView.messageLabel.font = miniReplyTextViewFont;
        self.textView.delegate = self;
        
        self.dateLabel.hidden = true;
        self.lineSeparator.hidden = true;
        
        UILongPressGestureRecognizer *longPressForPostOptions = [[UILongPressGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            if (state == UIGestureRecognizerStateBegan) {
                [self openPostActions];
            }
        }];
        [self addGestureRecognizer:longPressForPostOptions];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    UIEdgeInsets offset = miniReplyContentOffset;
    
    CGFloat yBottom = offset.top;
    
    BOOL hasContext = false;
    self.contextView.hidden = !hasContext;
    if (hasContext) {
        self.contextView.frame = CGRectMake(self.profilePicture.frame.origin.x, offset.top, self.frame.size.width - (self.profilePicture.frame.origin.x + offset.right), postContextHeight);
        yBottom = self.contextView.frame.origin.y + self.contextView.frame.size.height + 8;
    }
    
    self.profilePicture.frame = CGRectMake(replyContentOffset.left, yBottom, 36, 36);
    
    self.nameLabel.frame = CGRectMake(offset.left, yBottom, self.frame.size.width - offset.left - offset.right, self.nameLabel.frame.size.height);
    yBottom = self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height;
    
    // -- text view
    self.textView.tintColor = self.tintColor;
    self.textView.frame = CGRectMake(offset.left - miniReplyBubbleInset.left, yBottom + 4, self.frame.size.width - offset.left - offset.right + (miniReplyBubbleInset.left + miniReplyBubbleInset.right), self.textView.frame.size.height);
    [self.textView update];
    yBottom = self.textView.frame.origin.y + self.textView.frame.size.height;
    
    BOOL hasImage = FBTweakValue(@"Post", @"General", @"Show Image", NO); //self.post.images != nil && self.post.images.count > 0;
    self.imagesView.hidden = !hasImage;
    if (hasImage) {
        CGFloat imageHeight = [PostImagesView streamImageHeight] * .6;
        self.imagesView.frame = CGRectMake(offset.left, yBottom + (self.post.attributes.details.message.length != 0 ? 4 : 0), (self.frame.size.width - 35) - offset.left, imageHeight);
        
        yBottom = self.imagesView.frame.origin.y + self.imagesView.frame.size.height;
    }
    else {
        yBottom = self.textView.frame.origin.y + self.textView.frame.size.height;
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
        
        if (animated && self.sparked)
            [HapticHelper generateFeedback:FeedbackType_Notification_Success];
        
        UIColor *sparkedColor;
        if (self.sparked) {
            if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"star"]) {
                sparkedColor = [UIColor colorWithDisplayP3Red:0.99 green:0.58 blue:0.12 alpha:1.0];
            }
            else if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"heart"]) {
                sparkedColor = [UIColor colorWithDisplayP3Red:0.89 green:0.10 blue:0.13 alpha:1.0];
            }
            else if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"thumb"]) {
                sparkedColor = [UIColor colorWithDisplayP3Red:0.00 green:0.46 blue:1.00 alpha:1.0];
            }
            else if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"flame"]) {
                sparkedColor = [UIColor colorWithDisplayP3Red:0.99 green:0.42 blue:0.12 alpha:1.0];
            }
            else {
                sparkedColor = [UIColor colorWithDisplayP3Red:0.99 green:0.26 blue:0.12 alpha:1.0];
            }
        }
        
        void(^rippleAnimation)(void) = ^() {
            if (!self.sparked)
                return;
            
            if (self.post.attributes.details.message.length == 0)
                return;
            
            CGFloat bubbleDiamater = self.frame.size.width * 1.6;
            UIView *bubble = [[UIView alloc] initWithFrame:CGRectMake(0, 0, bubbleDiamater, bubbleDiamater)];
            bubble.center = self.textView.center;
            bubble.backgroundColor = [sparkedColor colorWithAlphaComponent:0.06];
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
    if (post != _post) {
        _post = post;
        // BOOL isCreator = [cell.post.attributes.details.creator.identifier isEqualToString:[Session sharedInstance].currentUser.identifier];
        
        self.nameLabel.attributedText = [PostCell attributedCreatorStringForPost:_post includeTimestamp:true includePostedIn:false];
        
        if (_post.tempId) {
            self.dateLabel.text = @"1s";
            
            self.userInteractionEnabled = false;
        }
        else {
            NSString *timeAgo = [NSDate mysqlDatetimeFormattedAsTimeAgo:_post.attributes.status.createdAt withForm:TimeAgoShortForm];
            self.dateLabel.text = timeAgo;
            
            self.userInteractionEnabled = true;
        }
        
        self.textView.message = _post.attributes.details.simpleMessage;
        
        if (self.profilePicture.user != _post.attributes.details.creator) {
            self.profilePicture.user = _post.attributes.details.creator;
        }
        else {
            NSLog(@"no need to load new user");
        }
        
        self.profilePicture.online = false;
        
        [self setSparked:(_post.attributes.context.vote != nil) animated:false];
        
        [self.imagesView setMedia:@[@"https://source.unsplash.com/daily"]];
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
    CGFloat height = miniReplyContentOffset.top;
    
    /*
     BOOL hasContext = false;
     if (hasContext) {
     height = height + postContextHeight + 8;
     }*/
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat leftOffset = miniReplyContentOffset.left;
    
    CGFloat nameHeight = 15 + 4; // 2pt padding underneath
    height = height + nameHeight;
    
    // message
    CGSize messageSize = [PostTextView sizeOfBubbleWithMessage:post.attributes.details.simpleMessage withConstraints:CGSizeMake(screenWidth - leftOffset - (miniReplyBubbleInset.left + miniReplyBubbleInset.right) - miniReplyContentOffset.right, CGFLOAT_MAX) font:miniReplyTextViewFont];
    CGFloat textViewHeight = post.attributes.details.message.length == 0 ? 0 :  ceilf(messageSize.height) + (miniReplyBubbleInset.top + miniReplyBubbleInset.bottom);
    height = height + textViewHeight;
    
    // image
    BOOL hasImage = FBTweakValue(@"Post", @"General", @"Show Image", NO); // postAtIndex.images != nil && postAtIndex.images.count > 0;
    if (hasImage) {
        CGFloat imageHeight = [PostImagesView streamImageHeight] * .6;
        imageHeight = imageHeight + 8; // 8 above
        height = height + imageHeight;
    }
    
    // 4 on top and 4 on bottom
    BOOL hasURLPreview = [post requiresURLPreview];
    if (hasURLPreview) {
        CGFloat urlPreviewHeight = !hasImage && hasURLPreview ? [PostImagesView streamImageHeight] + 4 : 0; // 4 on bottom
        height = height + urlPreviewHeight;
    }
    
    height = height + miniReplyContentOffset.bottom;
    
    return height;
}

@end
