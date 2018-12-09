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
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        
        self.contentView.frame = CGRectMake(0, 0, screenWidth, 100);
        self.contentView.backgroundColor = [UIColor clearColor];
        
        self.post = [[Post alloc] init];
        
        self.leftBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, self.frame.size.height)];
        self.leftBar.hidden = true;
        [self addSubview:self.leftBar];
        
        self.profilePicture = [[UIImageView alloc] initWithFrame:CGRectMake(12, 12, 42, 42)];
        
        BOOL circleProfilePictures = FBTweakValue(@"Post", @"General", @"Circle Profile Pictures", NO);
        if (circleProfilePictures) {
            [self continuityRadiusForView:self.profilePicture withRadius:self.profilePicture.frame.size.height * .5];
        }
        else {
            [self continuityRadiusForView:self.profilePicture withRadius:10.f];
        }
        
        [self.profilePicture setImage:[[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.profilePicture.layer.masksToBounds = true;
        self.profilePicture.userInteractionEnabled = true;
        [self addSubview:self.profilePicture];
        
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(66, expandedPostContentOffset.top, self.contentView.frame.size.width - 66 - 50, 16)];
        self.nameLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
        self.nameLabel.textAlignment = NSTextAlignmentLeft;
        self.nameLabel.text = @"Display Name";
        self.nameLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
        self.nameLabel.numberOfLines = 0;
        self.nameLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.contentView addSubview:self.nameLabel];
        
        self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(66, 39, self.nameLabel.frame.size.width, 16)];
        self.dateLabel.font = [UIFont systemFontOfSize:13.f weight:UIFontWeightRegular];
        self.dateLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1];
        self.dateLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:self.dateLabel];
        
        // text view
        self.textView = [[PostTextView alloc] initWithFrame:CGRectMake(expandedPostContentOffset.left, self.dateLabel.frame.origin.y + self.dateLabel.frame.size.height + 14, self.contentView.frame.size.width - expandedPostContentOffset.right - expandedPostContentOffset.left, 200)]; // 58 will change based on whether or not the detail label is shown
        self.textView.textView.editable = false;
        self.textView.textView.selectable = false;
        self.textView.textView.userInteractionEnabled = false;
        self.textView.textView.font = expandedTextViewFont;
        [self.contentView addSubview:self.textView];
        
        // details view
        self.actionsView = [[PostActionsView alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x, 56, self.textView.frame.size.width, expandedActionsViewHeight)];
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
        [self.contentView addSubview:self.actionsView];
        
        // image view
        self.pictureView = [[UIImageView alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x, 56, self.textView.frame.size.width, 120)];
        self.pictureView.backgroundColor = [UIColor colorWithRed:0.91 green:0.92 blue:0.93 alpha:1.0];
        [self continuityRadiusForView:self.pictureView withRadius:12.f];
        self.pictureView.contentMode = UIViewContentModeScaleAspectFill;
        self.pictureView.layer.masksToBounds = true;
        self.pictureView.userInteractionEnabled = true;
        [self.contentView addSubview:self.pictureView];
        
        self.lineSeparator = [[UIView alloc] init];
        self.lineSeparator.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
        [self.contentView addSubview:self.lineSeparator];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // line separator
    self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, (1 / [UIScreen mainScreen].scale));
    
    // data
    self.textView.textView.text = self.post.attributes.details.message;
    
    NSString *timeAgo = [NSDate mysqlDatetimeFormattedAsTimeAgo:self.post.attributes.status.createdAt withForm:TimeAgoLongForm];
    self.dateLabel.text = timeAgo;
    
    if (self.post.attributes.details.creator.attributes.details.media.profilePicture.length > 0) {
        [self.profilePicture sd_setImageWithURL:[NSURL URLWithString:self.post.attributes.details.creator.attributes.details.media.profilePicture]];
    }
    else {
        self.profilePicture.image = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    
    // -- spark button
    BOOL isSparked = self.post.attributes.context.vote != nil;
    [self setSparked:isSparked withAnimation:false];
    
    // style
    // -- post type [new, trending, pinned, n.a.]
    NSString *post_type = @"";
    self.leftBar.frame = CGRectMake(0, 0, self.leftBar.frame.size.width, self.frame.size.height);
    if ([post_type isEqualToString:@"trending_post"]) {
        self.leftBar.hidden = false;
        self.leftBar.backgroundColor = [UIColor colorWithDisplayP3Red:0.96 green:0.54 blue:0.14 alpha:1.0];
        self.backgroundColor = [UIColor colorWithRed:1.00 green:0.98 blue:0.96 alpha:1.0];
    }
    else if ([post_type isEqualToString:@"new_post"]) {
        self.leftBar.hidden = false;
        self.leftBar.backgroundColor = [UIColor colorWithDisplayP3Red:0.00 green:0.46 blue:1.00 alpha:1.0];
        self.backgroundColor = [UIColor colorWithRed:0.95 green:0.97 blue:1.00 alpha:1.0];
    }
    else if ([post_type isEqualToString:@"pinned_post"]) {
        self.leftBar.hidden = false;
        self.leftBar.backgroundColor = [UIColor colorWithDisplayP3Red:0.87 green:0.09 blue:0.09 alpha:1.0];
        self.backgroundColor = [UIColor colorWithRed:0.99 green:0.95 blue:0.95 alpha:1.0];
    }
    else {
        self.leftBar.hidden = true;
        self.backgroundColor = [UIColor whiteColor];
    }
    
    // -- text view
    [self.textView resize];
    self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.dateLabel.frame.origin.y + self.dateLabel.frame.size.height + 14, self.textView.frame.size.width, self.textView.frame.size.height);
    
    CGRect nameLabelRect = [self.nameLabel.attributedText boundingRectWithSize:CGSizeMake(self.frame.size.width - self.nameLabel.frame.origin.x - expandedPostContentOffset.right, CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) context:nil];
    self.nameLabel.frame = CGRectMake(self.nameLabel.frame.origin.x, self.nameLabel.frame.origin.y, self.frame.size.width - 96 - expandedPostContentOffset.right, nameLabelRect.size.height);
    self.dateLabel.frame = CGRectMake(self.dateLabel.frame.origin.x, self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height + 2, self.frame.size.width - self.dateLabel.frame.origin.x - expandedPostContentOffset.right, self.dateLabel.frame.size.height);
    
    BOOL hasImage = FBTweakValue(@"Post", @"General", @"Show Image", NO); //self.post.images != nil && self.post.images.count > 0;
    if (hasImage) {
        self.pictureView.hidden = false;
        
        CGFloat contentWidth = self.frame.size.width - expandedPostContentOffset.left - expandedPostContentOffset.right;
        CGFloat imageHeight = expandedImageHeightDefault;
        
        UIImage *diskImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:@"https://images.unsplash.com/photo-1540720936278-94ab04d51f62?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=2000&q=80"];
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
            UIImage *memoryImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:@"https://images.unsplash.com/photo-1540720936278-94ab04d51f62?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=2000&q=80"];
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
        
        self.pictureView.frame = CGRectMake(self.pictureView.frame.origin.x, self.textView.frame.origin.y + self.textView.frame.size.height + 4, self.pictureView.frame.size.width, imageHeight);
        //[self.pictureView sd_setImageWithURL:[NSURL URLWithString:self.post.images[0]]];
        [self continuityRadiusForView:self.pictureView withRadius:12.f];
        
        // -- details
        self.actionsView.frame = CGRectMake(self.actionsView.frame.origin.x, self.pictureView.frame.origin.y + self.pictureView.frame.size.height + 10, self.actionsView.frame.size.width, self.actionsView.frame.size.height);
    }
    else {
        self.pictureView.hidden = true;
        
        // -- details
        self.actionsView.frame = CGRectMake(self.actionsView.frame.origin.x, self.textView.frame.origin.y + self.textView.frame.size.height + 10, self.actionsView.frame.size.width, self.actionsView.frame.size.height);
    }
    self.actionsView.sparkButton.frame = CGRectMake(self.actionsView.frame.size.width / 2, 0, self.actionsView.frame.size.width / 2, self.actionsView.frame.size.height);
    self.actionsView.shareButton.frame = CGRectMake(0, 0, self.actionsView.frame.size.width / 2, self.actionsView.frame.size.height);
    self.actionsView.lineSeparator.frame = CGRectMake(0, 0, self.actionsView.frame.size.width, 1 / [UIScreen mainScreen].scale);
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

// Setter method
- (void)setSparked:(BOOL)isSparked withAnimation:(BOOL)animated {
    if (!animated || (animated && isSparked != self.sparked)) {
        self.sparked = isSparked;
        
        NSString *sparkText = [Session sharedInstance].defaults.post.displayVote.text;
        [self.actionsView.sparkButton setTitle:[NSString stringWithFormat:@"%@%@", sparkText, (self.sparked ? @"ed" : @"")] forState:UIControlStateNormal];
        
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
            
            [self.actionsView.sparkButton setTintColor:sparkedColor];
            [self.actionsView.sparkButton setTitleColor:sparkedColor forState:UIControlStateNormal];
        }
        else {
            [self.actionsView.sparkButton setTintColor:[UIColor colorWithWhite:0.47 alpha:1]];
            [self.actionsView.sparkButton setTitleColor:[UIColor colorWithWhite:0.47 alpha:1] forState:UIControlStateNormal];
        }
    }
}

@end
