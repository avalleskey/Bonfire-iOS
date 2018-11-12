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
        
        self.profilePicture = [[UIImageView alloc] initWithFrame:CGRectMake(12, 16, 40, 40)];
        [self continuityRadiusForView:self.profilePicture withRadius:10.f];
        [self.profilePicture setImage:[[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.profilePicture.layer.masksToBounds = true;
        self.profilePicture.userInteractionEnabled = true;
        [self addSubview:self.profilePicture];
        
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(62, expandedPostContentOffset.top, self.contentView.frame.size.width - 62 - 50, 16)];
        self.nameLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
        self.nameLabel.textAlignment = NSTextAlignmentLeft;
        self.nameLabel.text = @"Display Name";
        self.nameLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
        [self.contentView addSubview:self.nameLabel];
        
        self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - 100 - expandedPostContentOffset.right, expandedPostContentOffset.top, 100, self.nameLabel.frame.size.height)];
        self.dateLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightMedium];
        self.dateLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1];
        self.dateLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:self.dateLabel];
        
        
        self.postDetailsButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.postDetailsButton.frame = CGRectMake(62, 39, self.nameLabel.frame.size.width, 16);
        self.postDetailsButton.titleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
        self.postDetailsButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [self.postDetailsButton setTitle:@"Room Name" forState:UIControlStateNormal];
        [self.postDetailsButton setTitleColor:[UIColor colorWithWhite:0.6f alpha:1] forState:UIControlStateNormal];
        self.postDetailsButton.titleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightMedium];
        [self.contentView addSubview:self.postDetailsButton];
        
        // text view
        self.textView = [[PostTextView alloc] initWithFrame:CGRectMake(expandedPostContentOffset.left, expandedTextViewYPos, self.contentView.frame.size.width - expandedPostContentOffset.right - expandedPostContentOffset.left, 200)]; // 58 will change based on whether or not the detail label is shown
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
                        NSLog(@"success upvoting!");
                    }
                }];
            }
            else {
                // sparked -> unspark it
                [[Session sharedInstance] unsparkPost:self.post completion:^(BOOL success, id responseObject) {
                    if (success) {
                        NSLog(@"success downvoting.");
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
    
    // -- name
    NSString *displayName = self.post.attributes.details.creator.attributes.details.displayName != nil ? self.post.attributes.details.creator.attributes.details.displayName : @"Anonymous";
    NSString *username = self.post.attributes.details.creator.attributes.details.identifier;
    NSString *greyText = [NSString stringWithFormat:@"@%@", username];
    
    NSMutableAttributedString *combinedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", displayName, greyText]];
    [combinedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.2f alpha:1] range:NSMakeRange(0, displayName.length)];
    [combinedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14.f weight:UIFontWeightBold] range:NSMakeRange(0, displayName.length)];
    [combinedString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.6f alpha:1] range:NSMakeRange(displayName.length + 1, greyText.length)];
    [combinedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14.f weight:UIFontWeightRegular] range:NSMakeRange(displayName.length + 1, greyText.length)];
    
    self.nameLabel.attributedText = combinedString;
    
    NSString *timeAgo = [NSDate mysqlDatetimeFormattedAsTimeAgo:self.post.attributes.status.createdAt];
    self.dateLabel.text = timeAgo;
    
    if (self.post.attributes.details.creator.attributes.details.media.profilePicture.length > 0) {
        [self.profilePicture sd_setImageWithURL:[NSURL URLWithString:self.post.attributes.details.creator.attributes.details.media.profilePicture]];
    }
    else {
        self.profilePicture.image = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    [self.postDetailsButton setTitle:[NSString stringWithFormat:@"%@", self.post.attributes.status.postedIn.attributes.details.title] forState:UIControlStateNormal];
    
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
    self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, self.textView.frame.size.width, self.textView.frame.size.height);
    
    self.nameLabel.frame = CGRectMake(self.nameLabel.frame.origin.x, self.nameLabel.frame.origin.y, self.frame.size.width - 96 - expandedPostContentOffset.right, self.nameLabel.frame.size.height);
    self.dateLabel.frame = CGRectMake(self.frame.size.width - 80 - expandedPostContentOffset.right, self.dateLabel.frame.origin.y, 80, self.dateLabel.frame.size.height);
    
    BOOL hasImage = false; //self.post.images != nil && self.post.images.count > 0;
    if (hasImage) {
        self.pictureView.hidden = false;
        
        CGFloat contentWidth = self.frame.size.width - expandedPostContentOffset.left - expandedPostContentOffset.right;
        CGFloat imageHeight = expandedImageHeightDefault;
        
        UIImage *diskImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:@"https://images.unsplash.com/photo-1538681105587-85640961bf8b?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=03f0a1a4e6f1a7291ecb256b6a237b68&auto=format&fit=crop&w=1000&q=80"];
        if (diskImage) {
            // disk image!
            NSLog(@"disk image!");
            CGFloat heightToWidthRatio = diskImage.size.height / diskImage.size.width;
            imageHeight = roundf(contentWidth * heightToWidthRatio);
            
            if (imageHeight < 100) {
                NSLog(@"too small muchacho");
                imageHeight = 100;
            }
            if (imageHeight > 600) {
                NSLog(@"too big muchacho");
                imageHeight = 600;
            }
        }
        else {
            UIImage *memoryImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:@"https://images.unsplash.com/photo-1538681105587-85640961bf8b?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=03f0a1a4e6f1a7291ecb256b6a237b68&auto=format&fit=crop&w=1000&q=80"];
            if (memoryImage) {
                NSLog(@"memory image!");
                CGFloat heightToWidthRatio = diskImage.size.height / diskImage.size.width;
                imageHeight = roundf(contentWidth * heightToWidthRatio);
                
                if (imageHeight < 100) {
                    NSLog(@"too small muchacho");
                    imageHeight = 100;
                }
                if (imageHeight > 600) {
                    NSLog(@"too big muchacho");
                    imageHeight = 600;
                }
            }
        }
        
        self.pictureView.frame = CGRectMake(self.pictureView.frame.origin.x, self.textView.frame.origin.y + self.textView.frame.size.height + 10, self.pictureView.frame.size.width, imageHeight);
        //[self.pictureView sd_setImageWithURL:[NSURL URLWithString:self.post.images[0]]];
        
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

- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    if (hexString != nil && hexString.length == 6) {
        NSScanner *scanner = [NSScanner scannerWithString:hexString];
        [scanner setScanLocation:0]; // bypass '#' character
        [scanner scanHexInt:&rgbValue];
        return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
    }
    else {
        return [UIColor colorWithWhite:0.2f alpha:1];
    }
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
