//
//  ProfileHeaderCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/1/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ProfileHeaderCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <HapticHelper/HapticHelper.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Session.h"

@implementation ProfileHeaderCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        self.textLabel.font = [UIFont systemFontOfSize:28.f weight:UIFontWeightHeavy];
        self.textLabel.textColor = [UIColor colorWithWhite:0.07f alpha:1];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.textLabel.backgroundColor = [UIColor clearColor];
        
        self.detailTextLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightRegular];
        self.detailTextLabel.textAlignment = NSTextAlignmentCenter;
        self.detailTextLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
        self.detailTextLabel.numberOfLines = 0;
        self.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        
        // general cell styling
        self.separatorInset = UIEdgeInsetsMake(0, 62, 0, 0);
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.profilePicture = [[UIImageView alloc] initWithFrame:CGRectMake(0, 24, 72, 72)];
        [self continuityRadiusForView:self.profilePicture withRadius:self.profilePicture.frame.size.height * .25];
        self.profilePicture.image = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.contentView addSubview:self.profilePicture];
        
        self.followButton = [FollowButton buttonWithType:UIButtonTypeCustom];
        self.followButton.layer.borderWidth = 1.f;
        self.followButton.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
        self.followButton.backgroundColor = [UIColor clearColor];

        [self.contentView addSubview:self.followButton];
        
        self.lineSeparator = [[UIView alloc] init];
        self.lineSeparator.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
        [self.contentView addSubview:self.lineSeparator];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.profilePicture.tintColor = self.tintColor;
    
    // line separator
    self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width, (1 / [UIScreen mainScreen].scale));
    
    // profile picture
    self.profilePicture.frame = CGRectMake(self.frame.size.width / 2 - self.profilePicture.frame.size.width / 2, self.profilePicture.frame.origin.y, self.profilePicture.frame.size.width, self.profilePicture.frame.size.height);
    
    self.followButton.tintColor = self.tintColor;
    [self.followButton setTitleColor:self.tintColor forState:UIControlStateNormal];
    
    // text label
    CGRect textLabelRect = [self.textLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - (24 * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.textLabel.font} context:nil];
    self.textLabel.frame = CGRectMake(24, self.profilePicture.frame.origin.y + self.profilePicture.frame.size.height + 12, self.frame.size.width - 48, textLabelRect.size.height);
    
    // detail text label
    CGRect detailLabelRect = [self.detailTextLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - (24 * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.detailTextLabel.font} context:nil];
    self.detailTextLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.origin.y + self.textLabel.frame.size.height + 2, self.textLabel.frame.size.width, detailLabelRect.size.height);
    
    self.followButton.frame = CGRectMake(12, self.detailTextLabel.frame.origin.y + self.detailTextLabel.frame.size.height + 12, self.frame.size.width - 24, 40);
}

- (void)styleMemberProfilePictureView:(UIImageView *)imageView  {
    imageView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
    imageView.layer.borderWidth = 1 / [UIScreen mainScreen].scale;
    imageView.layer.cornerRadius = imageView.frame.size.height / 2;
    imageView.layer.masksToBounds = true;
    
    UIView * externalBorder = [[UIView alloc] init];
    externalBorder.frame = CGRectMake(imageView.frame.origin.x - 2, imageView.frame.origin.y - 2, imageView.frame.size.width+4, imageView.frame.size.height+4);
    externalBorder.backgroundColor = [UIColor whiteColor];
    externalBorder.layer.cornerRadius = externalBorder.frame.size.height / 2;
    externalBorder.layer.masksToBounds = true;
    
    [imageView.superview insertSubview:externalBorder belowSubview:imageView];
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

@end
