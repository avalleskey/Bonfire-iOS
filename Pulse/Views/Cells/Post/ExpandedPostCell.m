//
//  ExpandedPostCell.m
//  Hallway App
//
//  Created by Austin Valleskey on 3/10/18.
//  Copyright © 2018 Ingenious, Inc. All rights reserved.
//

#import "ExpandedPostCell.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import <SafariServices/SafariServices.h>
#import "NSDate+NVTimeAgo.h"
#import <HapticHelper/HapticHelper.h>
#import "Session.h"
#import "Launcher.h"
#import "UIColor+Palette.h"

@implementation ExpandedPostCell

@synthesize post = _post;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.nameLabel.hidden = true;
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        
        self.contentView.frame = CGRectMake(0, 0, screenWidth, 100);
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.contentView.layer.masksToBounds = false;
        
        self.profilePicture.frame = CGRectMake(12, 12, 48, 48);
        self.profilePicture.openOnTap = true;
        
        self.nameButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.nameButton.frame = CGRectMake(72, expandedPostContentOffset.top + 9, self.contentView.frame.size.width - 72 - 50, 16);
        self.nameButton.titleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
        self.nameButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [self.nameButton setTitleColor:[UIColor colorWithWhite:0.07f alpha:1] forState:UIControlStateNormal];
        [self.nameButton bk_whenTapped:^{
            [[Launcher sharedInstance] openProfile:self.post.attributes.details.creator];
        }];
        [self.contentView addSubview:self.nameButton];
        
        self.postedInButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.postedInButton.frame = CGRectMake(72, self.nameButton.frame.origin.y + self.nameButton.frame.size.height + 2, self.nameButton.frame.size.width, 14);
        self.postedInButton.titleLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightSemibold];
        self.postedInButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [self.postedInButton setTitle:@"Camp Name" forState:UIControlStateNormal];
        [self.postedInButton setTitleColor:[UIColor bonfireOrange] forState:UIControlStateNormal];
        [self.postedInButton setImage:[[UIImage imageNamed:@"replyingToIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self.postedInButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 4, 0, 0)];
        [self.contentView addSubview:self.postedInButton];
        
        // text view
        self.textView.frame = CGRectMake(expandedPostContentOffset.left, self.profilePicture.frame.origin.y + self.profilePicture.frame.size.height + 12, self.contentView.frame.size.width - expandedPostContentOffset.right - expandedPostContentOffset.left, 200);
        self.textView.messageLabel.font = expandedTextViewFont;
        self.textView.delegate = self;
        
        self.dateLabel.hidden = true;
        self.moreButton.hidden = true;
        
        self.activityView = [[PostActivityView alloc] initWithFrame:CGRectMake(0, self.textView.frame.origin.y + self.textView.frame.size.height, self.frame.size.width, 30)];
        [self.contentView addSubview:self.activityView];
        
        // actions view
        self.actionsView = [[ExpandedPostActionsView alloc] initWithFrame:CGRectMake(0, 56, self.frame.size.width, expandedActionsViewHeight)];
        [self.actionsView.sparkButton bk_whenTapped:^{
            [self setSparked:!self.sparked withAnimation:true];
            
            if (self.sparked) {
                [HapticHelper generateFeedback:FeedbackType_Notification_Success];
                
                // not sparked -> spark it
                [BFAPI sparkPost:self.post completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // NSLog(@"success upvoting!");
                    }
                }];
            }
            else {
                // sparked -> unspark it
                [BFAPI unsparkPost:self.post completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // NSLog(@"success downvoting.");
                    }
                }];
            }
        }];
        [self.actionsView.shareButton bk_whenTapped:^{
            [[Launcher sharedInstance] sharePost:self.post];
        }];
        [self.contentView addSubview:self.actionsView];
        
        // image view
        // self.pictureView = [[UIImageView alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x, 56, self.textView.frame.size.width, 120)];
        self.imagesView.layer.cornerRadius = 0;
        
        self.lineSeparator.hidden = false;
        self.lineSeparator.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
        [self bringSubviewToFront:self.lineSeparator];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.contentView.frame = self.bounds;
    
    // -- spark button
    BOOL isSparked = self.post.attributes.context.vote != nil;
    [self setSparked:isSparked withAnimation:false];
    
    // -- text view
    self.textView.tintColor = self.tintColor;
    [self.textView update];
    self.textView.frame = CGRectMake(expandedPostContentOffset.left, self.profilePicture.frame.origin.y + self.profilePicture.frame.size.height + 12, self.frame.size.width - (expandedPostContentOffset.left + expandedPostContentOffset.right), self.textView.frame.size.height);
    
    self.nameButton.frame = CGRectMake(self.nameButton.frame.origin.x, self.nameButton.frame.origin.y, self.frame.size.width - (self.nameButton.frame.origin.x + expandedPostContentOffset.right), self.nameButton.frame.size.height);
    self.postedInButton.frame = CGRectMake(self.nameButton.frame.origin.x, self.postedInButton.frame.origin.y, self.frame.size.width - self.nameButton.frame.origin.x - expandedPostContentOffset.right, self.postedInButton.frame.size.height);
    
    BOOL hasImage = (self.post.attributes.details.media.count > 0 || self.post.attributes.details.attachments.media.count > 0); //self.post.images != nil && self.post.images.count > 0;
    if (hasImage) {
        self.imagesView.hidden = false;
        
        CGFloat contentWidth = self.frame.size.width;
        CGFloat imageHeight = expandedImageHeightDefault;
        
        if (self.post.attributes.details.media.count == 1 && [[self.post.attributes.details.media firstObject] isKindOfClass:[NSString class]]) {
            NSString *imageURL = self.post.attributes.details.media[0];
            UIImage *diskImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:imageURL];
            if (diskImage) {
                // disk image!
                CGFloat heightToWidthRatio = diskImage.size.height / diskImage.size.width;
                imageHeight = roundf(contentWidth * heightToWidthRatio);
                
                if (imageHeight < 100) {
                    // NSLog(@"too small muchacho");
                    imageHeight = 100;
                }
                if (imageHeight > 600) {
                    // NSLog(@"too big muchacho");
                    imageHeight = 600;
                }
            }
            else {
                UIImage *memoryImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:imageURL];
                if (memoryImage) {
                    CGFloat heightToWidthRatio = diskImage.size.height / diskImage.size.width;
                    imageHeight = roundf(contentWidth * heightToWidthRatio);
                    
                    if (imageHeight < 100) {
                        // NSLog(@"too small muchacho");
                        imageHeight = 100;
                    }
                    if (imageHeight > 600) {
                        // NSLog(@"too big muchacho");
                        imageHeight = 600;
                    }
                }
            }
        }
        
        self.imagesView.frame = CGRectMake(0, self.textView.frame.origin.y + self.textView.frame.size.height + 8, self.frame.size.width, imageHeight);
    }
    else {
        self.imagesView.hidden = true;
    }
    
    // -- actions view
    self.actionsView.frame = CGRectMake(expandedPostContentOffset.left, (hasImage ? self.imagesView.frame.origin.y + self.imagesView.frame.size.height : self.textView.frame.origin.y + self.textView.frame.size.height) + 16, self.frame.size.width - (expandedPostContentOffset.left + expandedPostContentOffset.right), self.actionsView.frame.size.height);
    
    self.activityView.frame = CGRectMake(0, self.actionsView.frame.origin.y + self.actionsView.frame.size.height, self.frame.size.width, 30);
    
    self.lineSeparator.frame = CGRectMake(0, self.activityView.frame.origin.y + self.activityView.frame.size.height - self.lineSeparator.frame.size.height, self.frame.size.width, self.lineSeparator.frame.size.height);
    
    self.actionsView.topSeparator.frame = CGRectMake(0, self.actionsView.topSeparator.frame.origin.y, self.actionsView.frame.size.width, self.actionsView.topSeparator.frame.size.height);
    self.actionsView.bottomSeparator.frame = CGRectMake(-1 * self.actionsView.frame.origin.x, self.actionsView.frame.size.height - self.actionsView.bottomSeparator.frame.size.height, self.frame.size.width, self.actionsView.bottomSeparator.frame.size.height);
    // self.actionsView.middleSeparator.frame = CGRectMake(self.actionsView.frame.size.width / 2 - .5, 8, 1, self.actionsView.frame.siz e.height - 16);
    
    self.actionsView.replyButton.frame = CGRectMake(0, 0, self.actionsView.frame.size.width / 3, self.actionsView.frame.size.height);
    self.actionsView.sparkButton.frame = CGRectMake(self.actionsView.replyButton.frame.size.width, 0, self.actionsView.frame.size.width / 3, self.actionsView.frame.size.height);
    self.actionsView.shareButton.frame = CGRectMake(self.actionsView.frame.size.width - (self.actionsView.frame.size.width / 3), 0, self.actionsView.frame.size.width / 3, self.actionsView.frame.size.height);
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

// Setter method
- (void)postTextViewDidDoubleTap:(PostTextView *)postTextView {
    if (postTextView != self.textView)
        return;
    
    if (!self.sparked) {
        [HapticHelper generateFeedback:FeedbackType_Notification_Success];
    }
    
    [self setSparked:!self.sparked withAnimation:true];
}
- (void)setSparked:(BOOL)isSparked withAnimation:(BOOL)animated {
    if (!animated || (animated && isSparked != self.sparked)) {
        self.sparked = isSparked;
        
        if (animated && self.sparked) {
            [UIView animateWithDuration:1.9f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.actionsView.sparkButton.transform = CGAffineTransformMakeScale(1.2, 1.2);
            } completion:^(BOOL finished) {
                // self.actionsView.sparkButton.transform = CGAffineTransformMakeScale(1, 1);
                [UIView animateWithDuration:1.2f delay:0.2f usingSpringWithDamping:0.4f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.actionsView.sparkButton.transform = CGAffineTransformMakeScale(1, 1);
                } completion:nil];
            }];
        }
        
        if (self.sparked) {
            UIColor *sparkedColor;
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
            
            [self.actionsView.sparkButton setImage:[[UIImage imageNamed:@"boltIcon_active"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        else {
            [self.actionsView.sparkButton setImage:[[UIImage imageNamed:@"boltIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
    }
}

- (void)setPost:(Post *)post {
    if (post != _post) {
        _post = post;
        
        BOOL isReply = _post.attributes.details.parentId != 0;
        Room *postedInRoom = self.post.attributes.status.postedIn;
        
        NSString *username = self.post.attributes.details.creator.attributes.details.identifier;
        if (username != nil) {
            NSMutableAttributedString *attributedCreatorName = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"@%@", username] attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.2f alpha:1], NSFontAttributeName: [UIFont systemFontOfSize:self.nameButton.titleLabel.font.pointSize weight:UIFontWeightSemibold]}];
            
            [self.nameButton setAttributedTitle:attributedCreatorName forState:UIControlStateNormal];
        }
        
        UIFont *font = [post isEmojiPost] ? [UIFont systemFontOfSize:expandedTextViewFont.pointSize*POST_EMOJI_SIZE_MULTIPLIER] : expandedTextViewFont;
        self.textView.messageLabel.font = font;
        self.textView.message = self.post.attributes.details.simpleMessage;
        
        // todo: activity view init views
        [self.activityView initViewsWithPost:_post];
        
        self.postedInButton.userInteractionEnabled = (isReply || postedInRoom != nil);
        if (postedInRoom && !isReply) {
            [UIView performWithoutAnimation:^{
                [self.postedInButton setTitle:[NSString stringWithFormat:@"#%@", post.attributes.status.postedIn.attributes.details.identifier] forState:UIControlStateNormal];
                [self.postedInButton layoutIfNeeded];
            }];
            self.postedInButton.userInteractionEnabled = true;
            [self.postedInButton setImage:[[UIImage imageNamed:@"replyingToIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            self.postedInButton.tintColor = [UIColor fromHex:_post.attributes.status.postedIn.attributes.details.color];
            if (self.postedInButton.gestureRecognizers.count == 0 && post.attributes.status.postedIn) {
                [self.postedInButton bk_whenTapped:^{
                    [[Launcher sharedInstance] openRoom:post.attributes.status.postedIn];
                }];
            }
        }
        else if (isReply) {
            [UIView performWithoutAnimation:^{
                [self.postedInButton setTitle:[NSString stringWithFormat:@"@%@'s post", post.attributes.details.parentUsername] forState:UIControlStateNormal];
                [self.postedInButton layoutIfNeeded];
            }];
            [self.postedInButton setImage:[[UIImage imageNamed:@"replyingToIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            self.postedInButton.tintColor = [UIColor bonfireGray];
            self.postedInButton.userInteractionEnabled = false;
        }
        else {
            [UIView performWithoutAnimation:^{
                [self.postedInButton setTitle:@"Public" forState:UIControlStateNormal];
                [self.postedInButton layoutIfNeeded];
            }];
            self.postedInButton.tintColor = [UIColor colorWithWhite:0.6 alpha:1];
            [self.postedInButton setImage:[[UIImage imageNamed:@"expanded_post_public"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            self.postedInButton.userInteractionEnabled = false;
        }
        [self.postedInButton setTitleColor:self.postedInButton.tintColor forState:UIControlStateNormal];
        
        self.profilePicture.user = post.attributes.details.creator;
        
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
    // name @username • 2hr
    CGFloat avatarHeight = 48; // 2pt padding underneath
    CGFloat avatarBottomPadding = 12; //15 + 14; // 14pt padding underneath
    
    // message
    CGFloat contentWidth = [UIScreen mainScreen].bounds.size.width;
    NSStringDrawingContext *context = [[NSStringDrawingContext alloc] init];
    
    UIFont *font = [post isEmojiPost] ? [UIFont systemFontOfSize:expandedTextViewFont.pointSize*POST_EMOJI_SIZE_MULTIPLIER] : expandedTextViewFont;
    CGRect textViewRect = [post.attributes.details.message boundingRectWithSize:CGSizeMake(contentWidth - 12 - 12, 1200) options:(NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName:font} context:context];
    CGFloat textViewHeight = ceilf(textViewRect.size.height);
    
    // image
    BOOL hasImage = (post.attributes.details.media.count > 0 || post.attributes.details.attachments.media.count > 0);
    CGFloat imageHeight = hasImage ? expandedImageHeightDefault + 8 : 0;
    
    if (post.attributes.details.media.count == 1 && [[post.attributes.details.media firstObject] isKindOfClass:[NSString class]]) {
        NSString *imageURL = post.attributes.details.media[0];
        UIImage *diskImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:imageURL];
        if (diskImage) {
            // disk image!
            CGFloat heightToWidthRatio = diskImage.size.height / diskImage.size.width;
            imageHeight = roundf(contentWidth * heightToWidthRatio);
            
            if (imageHeight < 100) {
                // NSLog(@"too small muchacho");
                imageHeight = 100;
            }
            if (imageHeight > 600) {
                // NSLog(@"too big muchacho");
                imageHeight = 600;
            }
        }
        else {
            UIImage *memoryImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:imageURL];
            if (memoryImage) {
                CGFloat heightToWidthRatio = diskImage.size.height / diskImage.size.width;
                imageHeight = roundf(contentWidth * heightToWidthRatio);
                
                if (imageHeight < 100) {
                    // NSLog(@"too small muchacho");
                    imageHeight = 100;
                }
                if (imageHeight > 600) {
                    // NSLog(@"too big muchacho");
                    imageHeight = 600;
                }
            }
        }
        imageHeight = imageHeight + 8;
    }
    
    // deatils label
    CGFloat dateHeight = 16 + 30; // 6 + 14 + 12;
    
    // actions
    CGFloat actionsHeight = expandedActionsViewHeight; // 12 = padding above actions view
    
    return expandedPostContentOffset.top + avatarHeight + avatarBottomPadding + textViewHeight + imageHeight + actionsHeight + dateHeight + expandedPostContentOffset.bottom; // 1 = line separator
}

@end
