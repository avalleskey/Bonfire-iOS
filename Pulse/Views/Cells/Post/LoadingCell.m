//
//  PostCell.m
//  Pulse
//
//  Created by Austin Valleskey on 3/10/18.
//  Copyright © 2018 Ingenious, Inc. All rights reserved.
//

#import "LoadingCell.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import <SafariServices/SafariServices.h>
#import "NSDate+NVTimeAgo.h"
#import "StreamPostCell.h"
#import "UIColor+Palette.h"

@implementation LoadingCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor contentBackgroundColor];
        
        self.shimmerContainer = [[FBShimmeringView alloc] init];
        self.shimmerContainer.shimmeringSpeed = 800;
        [self addSubview:self.shimmerContainer];
        
        self.shimmerContentView = [[UIView alloc] init];
        
        self.primaryAvatarView.imageView.image = [UIImage new];
        self.primaryAvatarView.imageView.backgroundColor = [[UIColor tableViewSeparatorColor] colorWithAlphaComponent:0.5];
        self.primaryAvatarView.allowOnlineDot = false;
        [self.primaryAvatarView removeFromSuperview];
        [self.shimmerContentView addSubview:self.primaryAvatarView];
        
        self.nameLabel.textColor = [UIColor clearColor];
        self.nameLabel.layer.cornerRadius = 8.f;
        self.nameLabel.layer.masksToBounds = true;
        self.nameLabel.backgroundColor = [[UIColor tableViewSeparatorColor] colorWithAlphaComponent:0.5];
        [self.nameLabel removeFromSuperview];
        [self.shimmerContentView addSubview:self.nameLabel];
        
        // text view
        self.textView.backgroundColor = [[UIColor tableViewSeparatorColor] colorWithAlphaComponent:0.5];
        self.textView.layer.cornerRadius = 8.f;
        self.textView.layer.masksToBounds = true;
        [self.textView removeFromSuperview];
        [self.shimmerContentView addSubview:self.textView];
                
        // image view
        self.imagesView.containerView.backgroundColor = [[UIColor tableViewSeparatorColor] colorWithAlphaComponent:0.5];
        [self.imagesView removeFromSuperview];
        self.imagesView.containerView.layer.borderColor = [UIColor clearColor].CGColor;
        self.imagesView.containerView.layer.borderWidth = 0;
        [self.shimmerContentView addSubview:self.imagesView];
        
        self.shimmerContainer.contentView = self.shimmerContentView;
        
        self.dateLabel.hidden =
        self.moreButton.hidden = true;
        
        self.shimmerContainer.shimmering = true;
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // self.lineSeparator.frame = CGRectMake(self.textView.frame.origin.x, self.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width - self.textView.frame.origin.x, 1 / [UIScreen mainScreen].scale);
    self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, 1 / [UIScreen mainScreen].scale);
    
    self.shimmerContainer.frame = self.bounds;
    self.shimmerContentView.frame = self.bounds;
    self.nameLabel.frame = CGRectMake(postContentOffset.left, self.nameLabel.frame.origin.y, (self.frame.size.width - postContentOffset.left - postContentOffset.right) * (.4 + (.1 * self.type)), self.nameLabel.frame.size.height);
        
    if (self.type == loadingCellTypeShortPost) {
        self.textView.frame = CGRectMake(postContentOffset.left, self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height + 4, (self.frame.size.width - postContentOffset.left - postContentOffset.right) * .7, 34);
        
        self.imagesView.hidden = true;
    }
    else if (self.type == loadingCellTypeLongPost) {
        self.textView.frame = CGRectMake(postContentOffset.left, self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height + 4, (self.frame.size.width - postContentOffset.left - postContentOffset.right) * .9, 56);
        
        self.imagesView.hidden = true;
    }
    else if (self.type == loadingCellTypePicturePost) {
        self.textView.frame = CGRectMake(postContentOffset.left, self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height + 4, (self.frame.size.width - postContentOffset.left - postContentOffset.right) * .8, 34);
        
        self.imagesView.hidden = false;
        self.imagesView.frame = CGRectMake(postContentOffset.left, self.textView.frame.origin.y + self.textView.frame.size.height + 6, self.frame.size.width - postContentOffset.left - postContentOffset.right, self.imagesView.frame.size.height);
    }

    // self.repliesSnapshotView.hidden = true;
    // self.usernameLabel.frame = CGRectMake(self.usernameLabel.frame.origin.x, self.usernameLabel.frame.origin.y + 2, (self.frame.size.width - self.usernameLabel.frame.origin.x - postContentOffset.right) * (.2 + (.1 * self.type)), 11);
}

- (void)setType:(NSInteger)type {
    if (type != _type) {
        _type = type;
        
        [self layoutSubviews];
    }
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

- (void)stylize:(UIView *)view {
    view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    
    view.layer.masksToBounds = true;
}

@end
