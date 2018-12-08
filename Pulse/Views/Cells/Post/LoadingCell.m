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

@implementation LoadingCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor whiteColor];
        
        self.shimmerContainer = [[FBShimmeringView alloc] init];
        self.shimmerContainer.shimmeringSpeed = 400;
        [self addSubview:self.shimmerContainer];
        
        self.shimmerContentView = [[UIView alloc] init];
        
        self.profilePicture.image = [UIImage new];
        self.profilePicture.backgroundColor = [UIColor colorWithWhite:0.94f alpha:1];
        [self.profilePicture removeFromSuperview];
        [self.shimmerContentView addSubview:self.profilePicture];
        
        self.nameLabel.textColor = [UIColor clearColor];
        self.nameLabel.layer.cornerRadius = 4.f;
        self.nameLabel.layer.masksToBounds = true;
        self.nameLabel.backgroundColor = [UIColor colorWithWhite:0.94f alpha:1];
        [self.nameLabel removeFromSuperview];
        [self.shimmerContentView addSubview:self.nameLabel];
        
        // text view
        self.textView.backgroundColor = [UIColor colorWithWhite:0.94f alpha:1];
        self.textView.layer.cornerRadius = 17.f;
        self.textView.layer.masksToBounds = true;
        [self.textView removeFromSuperview];
        [self.shimmerContentView addSubview:self.textView];
        
        self.detailsLabel.hidden = true;
        
        // image view
        self.pictureView.backgroundColor = [UIColor colorWithWhite:0.94f alpha:1];
        [self.pictureView removeFromSuperview];
        [self.shimmerContentView addSubview:self.pictureView];
        
        self.shimmerContainer.contentView = self.shimmerContentView;
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, 1 / [UIScreen mainScreen].scale);
    
    self.shimmerContainer.frame = self.bounds;
    self.shimmerContentView.frame = self.bounds;
    
    self.nameLabel.frame = CGRectMake(self.nameLabel.frame.origin.x, self.nameLabel.frame.origin.y, (self.frame.size.width - self.nameLabel.frame.origin.x - postContentOffset.right) * (.4 + (.1 * self.type)), self.nameLabel.frame.size.height);
    
    if (self.type == loadingCellTypeShortPost) {
        self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, (self.frame.size.width - self.textView.frame.origin.x - postContentOffset.right) * .7, 34);
        
        self.pictureView.hidden = true;
    }
    else if (self.type == loadingCellTypeLongPost) {
        self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, (self.frame.size.width - self.textView.frame.origin.x - postContentOffset.right) * .9, 56);
        
        self.pictureView.hidden = true;
    }
    else if (self.type == loadingCellTypePicturePost) {
        self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, (self.frame.size.width - self.textView.frame.origin.x - postContentOffset.right) * .8, 34);
        
        self.pictureView.hidden = false;
        self.pictureView.frame = CGRectMake(self.pictureView.frame.origin.x, self.textView.frame.origin.y + self.textView.frame.size.height + 6, self.frame.size.width - self.pictureView.frame.origin.x - postContentOffset.right, self.pictureView.frame.size.height);
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
