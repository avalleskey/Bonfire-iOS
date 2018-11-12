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
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        
        self.contentView.frame = CGRectMake(0, 0, screenWidth, 100);
        self.contentView.backgroundColor = [UIColor clearColor];
        
        self.shimmerContainer = [[FBShimmeringView alloc] init];
        self.shimmerContainer.shimmeringSpeed = 400;
        [self addSubview:self.shimmerContainer];
        
        self.shimmerContentView = [[UIView alloc] init];
        
        self.profilePicture = [[UIView alloc] initWithFrame:CGRectMake(12, loadingPostContentOffset.top, 40, 40)];
        [self continuityRadiusForView:self.profilePicture withRadius:10.f];
        self.profilePicture.layer.masksToBounds = true;
        self.profilePicture.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        self.profilePicture.userInteractionEnabled = true;
        [self.shimmerContentView addSubview:self.profilePicture];
        
        self.nameLabel = [[UIView alloc] initWithFrame:CGRectMake(loadingPostContentOffset.left, loadingPostContentOffset.top, self.contentView.frame.size.width - loadingPostContentOffset.left - 50, 16)];
        [self stylize:self.nameLabel];
        self.nameLabel.layer.cornerRadius = 6.f;
        self.nameLabel.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        [self.shimmerContentView addSubview:self.nameLabel];
        
        // text view
        self.textView = [[UIView alloc] initWithFrame:CGRectMake(loadingPostContentOffset.left, self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height + 6, self.contentView.frame.size.width - loadingPostContentOffset.right - loadingPostContentOffset.left, 200)];
        [self stylize:self.textView];
        self.textView.layer.cornerRadius = 17.f;
        [self.shimmerContentView addSubview:self.textView];
        
        // image view
        self.pictureView = [[UIImageView alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x, 56, self.textView.frame.size.width, 140)];
        [self stylize:self.pictureView];
        [self continuityRadiusForView:self.pictureView withRadius:12.f];
        [self.shimmerContentView addSubview:self.pictureView];
        
        self.lineSeparator = [[UIView alloc] init];
        self.lineSeparator.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
        [self addSubview:self.lineSeparator];
        
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
    
    self.nameLabel.frame = CGRectMake(self.nameLabel.frame.origin.x, self.nameLabel.frame.origin.y, (self.frame.size.width - self.nameLabel.frame.origin.x - loadingPostContentOffset.right) * (.4 + (.1 * self.type)), self.nameLabel.frame.size.height);
    
    if (self.type == loadingCellTypeShortPost) {
        self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, (self.frame.size.width - self.textView.frame.origin.x - loadingPostContentOffset.right) * .7, 34);
        
        self.pictureView.hidden = true;
    }
    else if (self.type == loadingCellTypeLongPost) {
        self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, (self.frame.size.width - self.textView.frame.origin.x - loadingPostContentOffset.right) * .9, 56);
        
        self.pictureView.hidden = true;
    }
    else if (self.type == loadingCellTypePicturePost) {
        self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, (self.frame.size.width - self.textView.frame.origin.x - loadingPostContentOffset.right) * .8, 34);
        
        self.pictureView.hidden = false;
        self.pictureView.frame = CGRectMake(self.pictureView.frame.origin.x, self.textView.frame.origin.y + self.textView.frame.size.height + 6, self.frame.size.width - self.pictureView.frame.origin.x - loadingPostContentOffset.right, self.pictureView.frame.size.height);
    }
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

- (void)stylize:(UIView *)view {
    view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    
    view.layer.masksToBounds = true;
}

@end
