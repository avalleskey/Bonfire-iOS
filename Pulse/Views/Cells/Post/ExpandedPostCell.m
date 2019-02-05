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
#import <Tweaks/FBTweakInline.h>

@implementation ExpandedPostCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor whiteColor];
        self.layer.masksToBounds = false;
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        
        self.contentView.frame = CGRectMake(0, 0, screenWidth, 100);
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.contentView.layer.masksToBounds = false;
        //self.contentView.layer.shadowOffset = CGSizeMake(0, 0);
        //self.contentView.layer.shadowColor = [UIColor blackColor].CGColor;
        //self.contentView.layer.shadowRadius = 2.f;
        //self.contentView.layer.shadowOpacity = 0.08f;
        
        self.post = [[Post alloc] init];
        
        self.profilePicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(12, expandedPostContentOffset.top, 48, 48)];
        self.profilePicture.openOnTap = true;
        [self addSubview:self.profilePicture];
        
        self.nameLabel = [[ResponsiveLabel alloc] initWithFrame:CGRectMake(70, expandedPostContentOffset.top + 9, self.contentView.frame.size.width - 70 - 50, 16)];
        self.nameLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
        self.nameLabel.textAlignment = NSTextAlignmentLeft;
        self.nameLabel.text = @"Display Name";
        self.nameLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
        self.nameLabel.numberOfLines = 1;
        self.nameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        self.nameLabel.userInteractionEnabled = true;
        [self.contentView addSubview:self.nameLabel];
        
        self.postedInButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.postedInButton.frame = CGRectMake(70, self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height + 2, self.nameLabel.frame.size.width, 14);
        self.postedInButton.titleLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightSemibold];
        self.postedInButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [self.postedInButton setTitle:@"Camp Name" forState:UIControlStateNormal];
        [self.postedInButton setTitleColor:[UIColor bonfireOrange] forState:UIControlStateNormal];
        [self.postedInButton setImage:[[UIImage imageNamed:@"replyingToIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self.postedInButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 4, 0, 0)];
        [self.contentView addSubview:self.postedInButton];
        
        // text view
        self.textView = [[PostTextView alloc] initWithFrame:CGRectMake(expandedPostContentOffset.left, self.profilePicture.frame.origin.y + self.profilePicture.frame.size.height + 12, self.contentView.frame.size.width - expandedPostContentOffset.right - expandedPostContentOffset.left, 200)]; // 58 will change based on whether or not the detail label is shown
        self.textView.messageLabel.font = expandedTextViewFont;
        self.textView.delegate = self;
        [self.contentView addSubview:self.textView];
        
        // details label
        self.detailsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.textView.frame.origin.y + self.textView.frame.size.height + 12, self.frame.size.width, 14)];
        self.detailsLabel.textAlignment = NSTextAlignmentLeft;
        self.detailsLabel.font = [UIFont systemFontOfSize:11.f weight:UIFontWeightRegular];
        self.detailsLabel.textColor = [UIColor colorWithRed:0.56 green:0.55 blue:0.57 alpha:1.00];
        [self.contentView addSubview:self.detailsLabel];
        
        // actions view
        self.actionsView = [[PostActionsView alloc] initWithFrame:CGRectMake(expandedPostContentOffset.left, 56, self.frame.size.width - (expandedPostContentOffset.left + expandedPostContentOffset.right), expandedActionsViewHeight)];
        [self.actionsView.sparkButton bk_whenTapped:^{
            [self setSparked:!self.sparked withAnimation:true];
            
            if (self.sparked) {
                [HapticHelper generateFeedback:FeedbackType_Notification_Success];
                
                // not sparked -> spark it
                [[Session sharedInstance] sparkPost:self.post completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // NSLog(@"success upvoting!");
                    }
                }];
            }
            else {
                // sparked -> unspark it
                [[Session sharedInstance] unsparkPost:self.post completion:^(BOOL success, id responseObject) {
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
        self.pictureView = [[UIImageView alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x, 56, self.textView.frame.size.width, 120)];
        self.pictureView.backgroundColor = [UIColor colorWithRed:0.91 green:0.92 blue:0.93 alpha:1.0];
        self.pictureView.contentMode = UIViewContentModeScaleAspectFill;
        self.pictureView.layer.masksToBounds = true;
        self.pictureView.userInteractionEnabled = true;
        [self.contentView addSubview:self.pictureView];
        
        self.lineSeparator = [[UIView alloc] init];
        self.lineSeparator.backgroundColor = [[UIColor separatorColor] colorWithAlphaComponent:0.5];
        //[self.contentView addSubview:self.lineSeparator];
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
    [self.textView resize];
    self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.profilePicture.frame.origin.y + self.profilePicture.frame.size.height + 12, self.textView.frame.size.width, self.textView.frame.size.height);
    
    self.nameLabel.frame = CGRectMake(self.nameLabel.frame.origin.x, self.nameLabel.frame.origin.y, self.frame.size.width - self.nameLabel.frame.origin.x - expandedPostContentOffset.right, self.nameLabel.frame.size.height);
    self.postedInButton.frame = CGRectMake(self.postedInButton.frame.origin.x, self.postedInButton.frame.origin.y, self.frame.size.width - self.postedInButton.frame.origin.x - expandedPostContentOffset.right, self.postedInButton.frame.size.height);
    
    BOOL hasImage = FBTweakValue(@"Post", @"General", @"Show Image", NO); //self.post.images != nil && self.post.images.count > 0;
    if (hasImage) {
        self.pictureView.hidden = false;
        
        CGFloat contentWidth = self.frame.size.width;
        CGFloat imageHeight = expandedImageHeightDefault;
        
        UIImage *diskImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:@"https://images.unsplash.com/photo-1490349368154-73de9c9bc37c?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=2250&q=80"];
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
            UIImage *memoryImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:@"https://images.unsplash.com/photo-1490349368154-73de9c9bc37c?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=2250&q=80"];
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
        
        self.pictureView.frame = CGRectMake(0, self.textView.frame.origin.y + self.textView.frame.size.height + 8, self.frame.size.width, imageHeight);
        //[self.pictureView sd_setImageWithURL:[NSURL URLWithString:self.post.images[0]]];
        
        // -- details
        self.detailsLabel.frame = CGRectMake(expandedPostContentOffset.left + self.textView.messageLabel.frame.origin.x, self.pictureView.frame.origin.y + self.pictureView.frame.size.height + 6, self.frame.size.width - (expandedPostContentOffset.left + expandedPostContentOffset.right + self.textView.messageLabel.frame.origin.x), self.detailsLabel.frame.size.height);
    }
    else {
        self.pictureView.hidden = true;
        
        // -- details
        self.detailsLabel.frame = CGRectMake(expandedPostContentOffset.left + self.textView.messageLabel.frame.origin.x, self.textView.frame.origin.y + self.textView.frame.size.height + 6, self.frame.size.width - (expandedPostContentOffset.left + expandedPostContentOffset.right + self.textView.messageLabel.frame.origin.x), self.detailsLabel.frame.size.height);
    }
    
    self.lineSeparator.frame = CGRectMake(self.detailsLabel.frame.origin.x, self.detailsLabel.frame.origin.y - (1 / [UIScreen mainScreen].scale), self.detailsLabel.frame.size.width, (1 / [UIScreen mainScreen].scale));
    
    // -- actions view
    self.actionsView.frame = CGRectMake(self.actionsView.frame.origin.x, self.detailsLabel.frame.origin.y + self.detailsLabel.frame.size.height + 12, self.frame.size.width - (expandedPostContentOffset.left + expandedPostContentOffset.right), self.actionsView.frame.size.height);
    
    self.actionsView.topSeparator.frame = CGRectMake(0, self.actionsView.topSeparator.frame.origin.y, self.actionsView.frame.size.width, self.actionsView.topSeparator.frame.size.height);
    self.actionsView.middleSeparator.frame = CGRectMake(self.actionsView.frame.size.width / 2 - .5, 8, 1, self.actionsView.frame.size.height - 16);
    self.actionsView.bottomSeparator.frame = CGRectMake(0, self.actionsView.frame.size.height - self.actionsView.bottomSeparator.frame.size.height, self.actionsView.frame.size.width, self.actionsView.bottomSeparator.frame.size.height);
    
    self.actionsView.shareButton.frame = CGRectMake(expandedPostContentOffset.left, 0, self.actionsView.frame.size.width / 2 - expandedPostContentOffset.left, self.actionsView.frame.size.height);
    self.actionsView.sparkButton.frame = CGRectMake(self.actionsView.frame.size.width / 2, 0, self.actionsView.frame.size.width / 2 - expandedPostContentOffset.right, self.actionsView.frame.size.height);
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
        
        /*
        if (animated && self.sparked) {
            [UIView animateWithDuration:1.9f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.actionsView.sparkButton.transform = CGAffineTransformMakeScale(1.2, 1.2);
            } completion:^(BOOL finished) {
                // self.actionsView.sparkButton.transform = CGAffineTransformMakeScale(1, 1);
                [UIView animateWithDuration:1.2f delay:0.2f usingSpringWithDamping:0.4f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.actionsView.sparkButton.transform = CGAffineTransformMakeScale(1, 1);
                } completion:nil];
            }];
        }*/
        
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
            
            self.actionsView.sparkButton.tintColor = sparkedColor;
        }
        else {
            self.actionsView.sparkButton.tintColor = [UIColor bonfireGrayWithLevel:800];
        }
        [self.actionsView.sparkButton setTitleColor:self.actionsView.sparkButton.tintColor forState:UIControlStateNormal];
    }
}

- (void)setPost:(Post *)post {
    if (post != _post) {
        _post = post;
        
        BOOL isReply = self.post.attributes.details.parent != 0;
        Room *postedInRoom = self.post.attributes.status.postedIn;
        
        self.textView.message = self.post.attributes.details.simpleMessage;
        
        NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
        [inputFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        NSDate *date = [inputFormatter dateFromString:self.post.attributes.status.createdAt];
        if (date) {
            NSDateFormatter *outputFormatter_part1 = [[NSDateFormatter alloc] init];
            [outputFormatter_part1 setDateFormat:@"EEE, MMM d, yyyy "];
            NSDateFormatter *outputFormatter_part2 = [[NSDateFormatter alloc] init];
            [outputFormatter_part2 setDateFormat:@"h:mm a"];
            NSMutableAttributedString *dateString = [[NSMutableAttributedString alloc] initWithString:[outputFormatter_part1 stringFromDate:date]];
            [dateString addAttribute:NSForegroundColorAttributeName value:self.detailsLabel.textColor range:NSMakeRange(0, dateString.length)];
            [dateString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:11.f weight:UIFontWeightSemibold] range:NSMakeRange(0, dateString.length)];
            NSMutableAttributedString *timeString = [[NSMutableAttributedString alloc] initWithString:[outputFormatter_part2 stringFromDate:date]];
            [timeString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:11.f weight:UIFontWeightRegular] range:NSMakeRange(0, timeString.length)];
            [dateString appendAttributedString:timeString];
            [dateString addAttribute:NSForegroundColorAttributeName value:self.detailsLabel.textColor range:NSMakeRange(0, dateString.length)];
            self.detailsLabel.attributedText = dateString;
        }
        else {
            self.detailsLabel.text = @"";
        }
        
        BOOL showPostedIn = (!isReply && postedInRoom != nil);
        self.postedInButton.userInteractionEnabled = showPostedIn;
        if (showPostedIn) {
            [UIView performWithoutAnimation:^{
                [self.postedInButton setTitle:self.post.attributes.status.postedIn.attributes.details.title forState:UIControlStateNormal];
                [self.postedInButton layoutIfNeeded];
            }];
            [self.postedInButton setImage:[[UIImage imageNamed:@"replyingToIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            self.postedInButton.tintColor = [UIColor fromHex:self.post.attributes.status.postedIn.attributes.details.color];
            [self.postedInButton setTitleColor:self.postedInButton.tintColor forState:UIControlStateNormal];
            if (self.postedInButton.gestureRecognizers.count == 0 && self.post.attributes.status.postedIn) {
                [self.postedInButton bk_whenTapped:^{
                    [[Launcher sharedInstance] openRoom:self.post.attributes.status.postedIn];
                }];
            }
        }
        else {
            [UIView performWithoutAnimation:^{
                [self.postedInButton setTitle:@"Public" forState:UIControlStateNormal];
                [self.postedInButton layoutIfNeeded];
            }];
            self.postedInButton.tintColor = [UIColor colorWithWhite:0.6 alpha:1];
            [self.postedInButton setTitleColor:self.postedInButton.tintColor forState:UIControlStateNormal];
            [self.postedInButton setImage:[[UIImage imageNamed:@"expanded_post_public"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        
        self.profilePicture.user = post.attributes.details.creator;
        
        [self.pictureView sd_setImageWithURL:[NSURL URLWithString:@"https://images.unsplash.com/photo-1490349368154-73de9c9bc37c?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=2250&q=80"]];
    }
}

@end
