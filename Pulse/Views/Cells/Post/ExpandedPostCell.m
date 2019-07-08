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
#import <SDWebImage/SDImageCache.h>

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
        self.contentView.layer.masksToBounds = false;
        
        self.primaryAvatarView.frame = CGRectMake(12, 12, 48, 48);
        self.primaryAvatarView.openOnTap = true;
        
        self.nameButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.nameButton.frame = CGRectMake(70, expandedPostContentOffset.top + 9, self.contentView.frame.size.width - 70 - 50, 16);
        self.nameButton.titleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
        self.nameButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [self.nameButton setTitleColor:[UIColor colorWithWhite:0.07f alpha:1] forState:UIControlStateNormal];
        [self.nameButton bk_whenTapped:^{
            [Launcher openProfile:self.post.attributes.details.creator];
        }];
        [self.contentView addSubview:self.nameButton];
        
        self.postedInButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.postedInButton.frame = CGRectMake(70, self.nameButton.frame.origin.y + self.nameButton.frame.size.height + 2, self.nameButton.frame.size.width, 14);
        self.postedInButton.titleLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightSemibold];
        self.postedInButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [self.postedInButton setTitle:@"Camp Name" forState:UIControlStateNormal];
        [self.postedInButton setTitleColor:[UIColor bonfireOrange] forState:UIControlStateNormal];
        [self.postedInButton setImage:[[UIImage imageNamed:@"replyingToIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self.postedInButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 4, 0, 0)];
        [self.contentView addSubview:self.postedInButton];
        
        // text view
        self.textView.frame = CGRectMake(expandedPostContentOffset.left, self.primaryAvatarView.frame.origin.y + self.primaryAvatarView.frame.size.height + 12, self.contentView.frame.size.width - expandedPostContentOffset.right - expandedPostContentOffset.left, 200);
        self.textView.messageLabel.font = expandedTextViewFont;
        self.textView.delegate = self;
        
        self.dateLabel.hidden = true;
        
        self.activityView = [[PostActivityView alloc] initWithFrame:CGRectMake(0, self.textView.frame.origin.y + self.textView.frame.size.height, self.frame.size.width, 30)];
        [self.contentView addSubview:self.activityView];
        
        // actions view
        self.actionsView = [[ExpandedPostActionsView alloc] initWithFrame:CGRectMake(0, 56, self.frame.size.width, expandedActionsViewHeight)];
        [self.actionsView.voteButton bk_whenTapped:^{
            [self setVoted:!self.voted withAnimation:true];
            
            if (self.voted) {
                [HapticHelper generateFeedback:FeedbackType_Notification_Success];
                
                // not voted -> vote it
                [BFAPI votePost:self.post completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // NSLog(@"success upvoting!");
                    }
                }];
            }
            else {
                // voted -> unvote it
                [BFAPI unvotePost:self.post completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // NSLog(@"success downvoting.");
                    }
                }];
            }
        }];
        [self.actionsView.shareButton bk_whenTapped:^{
            [Launcher sharePost:self.post];
        }];
        [self.contentView addSubview:self.actionsView];
        
        // image view
        // self.pictureView = [[UIImageView alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x, 56, self.textView.frame.size.width, 120)];
        self.imagesView.layer.cornerRadius = 16.f;
        
        self.lineSeparator.hidden = false;
        self.lineSeparator.backgroundColor = [UIColor separatorColor];
        [self bringSubviewToFront:self.lineSeparator];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.contentView.frame = self.bounds;
    
    // -- vote button
    BOOL isVoted = self.post.attributes.context.post.vote != nil;
    [self setVoted:isVoted withAnimation:false];
    
    // -- text view
    self.textView.tintColor = self.tintColor;
    [self.textView update];
    self.textView.frame = CGRectMake(expandedPostContentOffset.left, self.primaryAvatarView.frame.origin.y + self.primaryAvatarView.frame.size.height + 12, self.frame.size.width - (expandedPostContentOffset.left + expandedPostContentOffset.right), self.textView.frame.size.height);
    
    if (![self.moreButton isHidden]) {
        CGFloat moreButtonPadding = 12;
        CGFloat moreButtonWidth = self.moreButton.currentImage.size.width + (moreButtonPadding * 2);
        self.moreButton.frame = CGRectMake(self.frame.size.width - moreButtonWidth - expandedPostContentOffset.right + moreButtonPadding, (self.primaryAvatarView.frame.origin.y + self.primaryAvatarView.frame.size.height / 2) - 20 - moreButtonPadding, moreButtonWidth, 40 + (moreButtonPadding * 2));
    }
    
    self.nameButton.frame = CGRectMake(self.nameButton.frame.origin.x, self.nameButton.frame.origin.y, self.frame.size.width - (self.nameButton.frame.origin.x + expandedPostContentOffset.right), self.nameButton.frame.size.height);
    self.postedInButton.frame = CGRectMake(self.nameButton.frame.origin.x, self.postedInButton.frame.origin.y, self.frame.size.width - self.nameButton.frame.origin.x - expandedPostContentOffset.right, self.postedInButton.frame.size.height);
    
    BOOL hasImage = (self.post.attributes.details.media.count > 0 || self.post.attributes.details.attachments.media.count > 0); //self.post.images != nil && self.post.images.count > 0;
    if (hasImage) {
        self.imagesView.hidden = false;
        
        CGFloat imageWidth = self.frame.size.width - (expandedPostContentOffset.left + expandedPostContentOffset.right);
        CGFloat imageHeight = expandedImageHeightDefault;
        
        if (self.post.attributes.details.attachments.media.count == 1 && [[self.post.attributes.details.attachments.media firstObject] isKindOfClass:[PostAttachmentsMedia class]]) {
            NSString *imageURL = self.post.attributes.details.attachments.media[0].attributes.hostedVersions.suggested.url;
            UIImage *memoryImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:imageURL];
            if (memoryImage) {
                UIImage *memoryImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:imageURL];
                if (memoryImage) {
                    CGFloat heightToWidthRatio = memoryImage.size.height / memoryImage.size.width;
                    imageHeight = roundf(imageWidth * heightToWidthRatio);
                    
                    if (imageHeight < 100) {
                        // NSLog(@"too small muchacho");
                        imageHeight = 100;
                    }
                    if (imageHeight > 480) {
                        // NSLog(@"too big muchacho");
                        imageHeight = 480;
                    }
                }
            }
            else {
                UIImage *diskImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:imageURL];
                
                if (diskImage) {
                    // disk image!
                    CGFloat heightToWidthRatio = diskImage.size.height / diskImage.size.width;
                    imageHeight = roundf(imageWidth * heightToWidthRatio);
                    
                    if (imageHeight < 100) {
                        // NSLog(@"too small muchacho");
                        imageHeight = 100;
                    }
                    if (imageHeight > 480) {
                        // NSLog(@"too big muchacho");
                        imageHeight = 480;
                    }
                }
            }
        }
        
        self.imagesView.frame = CGRectMake(expandedPostContentOffset.left, self.textView.frame.origin.y + (self.post.attributes.details.message.length > 0 ? self.textView.frame.size.height + 8 : 0), imageWidth, imageHeight);
    }
    else {
        self.imagesView.hidden = true;
    }
    
    // -- actions view
    self.actionsView.frame = CGRectMake(expandedPostContentOffset.left, (hasImage ? self.imagesView.frame.origin.y + self.imagesView.frame.size.height : self.textView.frame.origin.y + self.textView.frame.size.height) + 16, self.frame.size.width - (expandedPostContentOffset.left + expandedPostContentOffset.right), self.actionsView.frame.size.height);
    
    self.activityView.frame = CGRectMake(0, self.actionsView.frame.origin.y + self.actionsView.frame.size.height, self.frame.size.width, 30);
    
    self.lineSeparator.frame = CGRectMake(0, self.activityView.frame.origin.y + self.activityView.frame.size.height - self.lineSeparator.frame.size.height, self.frame.size.width, self.lineSeparator.frame.size.height);
    
    self.actionsView.topSeparator.frame = CGRectMake(0, self.actionsView.topSeparator.frame.origin.y, self.actionsView.frame.size.width, self.actionsView.topSeparator.frame.size.height);
    self.actionsView.bottomSeparator.frame = CGRectMake(-self.actionsView.frame.origin.x, self.actionsView.frame.size.height - self.actionsView.bottomSeparator.frame.size.height, self.actionsView.frame.size.width + (self.actionsView.frame.origin.x * 2), self.actionsView.bottomSeparator.frame.size.height);
    // self.actionsView.middleSeparator.frame = CGRectMake(self.actionsView.frame.size.width / 2 - .5, 8, 1, self.actionsView.frame.siz e.height - 16);
    
    self.actionsView.replyButton.frame = CGRectMake(0, 0, self.actionsView.frame.size.width / 3, self.actionsView.frame.size.height);
    self.actionsView.voteButton.frame = CGRectMake(self.actionsView.replyButton.frame.size.width, 0, self.actionsView.frame.size.width / 3, self.actionsView.frame.size.height);
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
    
    if (!self.voted) {
        [HapticHelper generateFeedback:FeedbackType_Notification_Success];
    }
    
    [self setVoted:!self.voted withAnimation:true];
}
- (void)setVoted:(BOOL)isVoted withAnimation:(BOOL)animated {
    if (!animated || (animated && isVoted != self.voted)) {
        self.voted = isVoted;
        
        if (animated && self.voted) {
            [UIView animateWithDuration:1.9f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
                self.actionsView.voteButton.transform = CGAffineTransformMakeScale(1.2, 1.2);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:1.2f delay:0.2f usingSpringWithDamping:0.4f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
                    self.actionsView.voteButton.transform = CGAffineTransformMakeScale(1, 1);
                } completion:nil];
            }];
        }
        
        if (self.voted) {
            [self.actionsView.voteButton setImage:[[UIImage imageNamed:@"boltIcon_active"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        else {
            [self.actionsView.voteButton setImage:[[UIImage imageNamed:@"boltIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
    }
}

- (void)setPost:(Post *)post {
    if ([post toDictionary] != [_post toDictionary]) {
        _post = post;
        
        BOOL isReply = _post.attributes.details.parentId.length > 0;
        Camp *postedInCamp = self.post.attributes.status.postedIn;
        
        NSString *username = self.post.attributes.details.creator.attributes.details.identifier;
        if (username != nil) {
            NSMutableAttributedString *attributedCreatorName = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"@%@", username] attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.2f alpha:1], NSFontAttributeName: [UIFont systemFontOfSize:self.nameButton.titleLabel.font.pointSize weight:UIFontWeightSemibold]}];
            
            [self.nameButton setAttributedTitle:attributedCreatorName forState:UIControlStateNormal];
        }
        
        UIFont *font = [post isEmojiPost] ? [UIFont systemFontOfSize:expandedTextViewFont.pointSize*POST_EMOJI_SIZE_MULTIPLIER] : expandedTextViewFont;
        self.textView.messageLabel.font = font;
        
        [self.textView setMessage:self.post.attributes.details.simpleMessage entities:self.post.attributes.details.entities];
        
        // todo: activity view init views
        self.activityView.post = self.post;
        
        self.postedInButton.userInteractionEnabled = (isReply || postedInCamp != nil);
        if (postedInCamp) {
            [UIView performWithoutAnimation:^{
                [self.postedInButton setTitle:[NSString stringWithFormat:@"#%@", post.attributes.status.postedIn.attributes.details.identifier] forState:UIControlStateNormal];
                [self.postedInButton layoutIfNeeded];
            }];
            self.postedInButton.userInteractionEnabled = true;
            [self.postedInButton setImage:[[UIImage imageNamed:@"replyingToIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            self.postedInButton.tintColor = [UIColor fromHex:_post.attributes.status.postedIn.attributes.details.color];
            if (self.postedInButton.gestureRecognizers.count == 0 && post.attributes.status.postedIn) {
                [self.postedInButton bk_whenTapped:^{
                    [Launcher openCamp:post.attributes.status.postedIn];
                }];
            }
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
        
        if (self.primaryAvatarView.user != _post.attributes.details.creator) {
            self.primaryAvatarView.user = _post.attributes.details.creator;
        }
        self.primaryAvatarView.online = false;
        
        NSArray *media;
        if (self.post.attributes.details.attachments.media.count > 0) {
            media = self.post.attributes.details.attachments.media;
        }
        else if (self.post.attributes.details.media.count > 0) {
            media = self.post.attributes.details.media;
        }
        else {
            media = @[];
        }
        
        UIColor *theme = [UIColor bonfireGrayWithLevel:800];
        if (postedInCamp) {
            theme = [UIColor fromHex:self.post.attributes.status.postedIn.attributes.details.color];
        }
        else {
            theme = [UIColor fromHex:self.post.attributes.details.creator.attributes.details.color];
        }
        self.activityView.backgroundColor = [theme colorWithAlphaComponent:0.03f];
        self.activityView.tintColor = theme;
        
        [self.imagesView setMedia:media];
    }
}

+ (CGFloat)heightForPost:(Post *)post {
    CGFloat height = 0;
    
    // name @username • 2hr
    CGFloat avatarHeight = 48; // 2pt padding underneath
    CGFloat avatarBottomPadding = 12; //15 + 14; // 14pt padding underneath
    
    height = avatarHeight + avatarBottomPadding;
    
    // message
    CGFloat contentWidth = [UIScreen mainScreen].bounds.size.width;
    
    BOOL hasMessage = post.attributes.details.message.length > 0;
    if (hasMessage) {
        UIFont *font = [post isEmojiPost] ? [UIFont systemFontOfSize:expandedTextViewFont.pointSize*POST_EMOJI_SIZE_MULTIPLIER] : expandedTextViewFont;
        CGFloat textViewHeight = [PostTextView sizeOfBubbleWithMessage:post.attributes.details.simpleMessage withConstraints:CGSizeMake(contentWidth - expandedPostContentOffset.left - expandedPostContentOffset.right, CGFLOAT_MAX) font:font].height;
        height = height + textViewHeight;
    }
    
    // image
    BOOL hasImage = (post.attributes.details.media.count > 0 || post.attributes.details.attachments.media.count > 0);
    if (hasMessage && hasImage) {
        // spacing between message and image
        height = height + 8;
    }
    
    CGFloat imageWidth = contentWidth - (expandedPostContentOffset.left + expandedPostContentOffset.right);
    CGFloat imageHeight = expandedImageHeightDefault;
    
    if (post.attributes.details.attachments.media.count == 1 && [[post.attributes.details.attachments.media firstObject] isKindOfClass:[PostAttachmentsMedia class]]) {
        NSString *imageURL = post.attributes.details.attachments.media[0].attributes.hostedVersions.suggested.url;
        
        UIImage *memoryImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:imageURL];
        if (memoryImage) {
            UIImage *memoryImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:imageURL];
            if (memoryImage) {
                CGFloat heightToWidthRatio = memoryImage.size.height / memoryImage.size.width;
                imageHeight = roundf(imageWidth * heightToWidthRatio);
                
                if (imageHeight < 100) {
                    // NSLog(@"too small muchacho");
                    imageHeight = 100;
                }
                if (imageHeight > 480) {
                    // NSLog(@"too big muchacho");
                    imageHeight = 480;
                }
            }
        }
        else {
            UIImage *diskImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:imageURL];
            
            if (diskImage) {
                // disk image!
                CGFloat heightToWidthRatio = diskImage.size.height / diskImage.size.width;
                imageHeight = roundf(imageWidth * heightToWidthRatio);
                
                if (imageHeight < 100) {
                    // NSLog(@"too small muchacho");
                    imageHeight = 100;
                }
                if (imageHeight > 480) {
                    // NSLog(@"too big muchacho");
                    imageHeight = 480;
                }
            }
        }
        imageHeight = imageHeight;
    }
    if (hasImage) {
        height = height + imageHeight;
    }
    
    // deatils label
    CGFloat dateHeight = 16 + 30; // 6 + 14 + 12;
    height = height + dateHeight;
    
    // actions
    CGFloat actionsHeight = expandedActionsViewHeight; // 12 = padding above actions view
    height = height + actionsHeight;
    
    return expandedPostContentOffset.top + height + expandedPostContentOffset.bottom; // 1 = line separator
}

@end
