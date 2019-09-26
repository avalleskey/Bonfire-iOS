//
//  CampHeaderCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/1/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "InviteFriendHeaderCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <HapticHelper/HapticHelper.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Session.h"
#import "Defaults.h"
#import "CampViewController.h"
#import "UIColor+Palette.h"

#define UIViewParentController(__view) ({ \
        UIResponder *__responder = __view; \
        while ([__responder isKindOfClass:[UIView class]]) \
        __responder = [__responder nextResponder]; \
        (UIViewController *)__responder; \
        })

@implementation InviteFriendHeaderCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        //self.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
        self.backgroundColor = [UIColor whiteColor];
        
        self.contentView.layer.masksToBounds = false;
        self.layer.masksToBounds = false;
        
        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.font = [UIFont systemFontOfSize:30.f weight:UIFontWeightHeavy];
        self.nameLabel.textColor = [UIColor colorWithWhite:0.07f alpha:1];
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        self.nameLabel.numberOfLines = 0;
        self.nameLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.nameLabel.text = @"Invite Friends";
        [self.contentView addSubview:self.nameLabel];
        
        self.descriptionLabel = [[UILabel alloc] init];
        self.descriptionLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightMedium];
        self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
        self.descriptionLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1];
        self.descriptionLabel.numberOfLines = 0;
        self.descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.descriptionLabel.text = @"Bonfire is more fun with friends!";
        [self.contentView addSubview:self.descriptionLabel];
        
        // general cell styling
        self.separatorInset = UIEdgeInsetsMake(0, self.frame.size.width, 0, 0);
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.member1 = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
        self.member1.imageView.image = [[UIImage imageNamed:@"inviteFriendHeaderImage"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        self.member1.imageView.contentMode = UIViewContentModeScaleToFill;
        
        self.member2 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        self.member3 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        
        self.member4 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        self.member5 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        
        self.member6 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        self.member7 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        
        [self.contentView addSubview:self.member1];
        [self.contentView addSubview:self.member2];
        [self.contentView addSubview:self.member3];
        [self.contentView addSubview:self.member4];
        [self.contentView addSubview:self.member5];
        [self.contentView addSubview:self.member6];
        [self.contentView addSubview:self.member7];
        
        [self styleMemberProfilePictureView:self.member2];
        [self styleMemberProfilePictureView:self.member3];
        [self styleMemberProfilePictureView:self.member4];
        [self styleMemberProfilePictureView:self.member5];
        [self styleMemberProfilePictureView:self.member6];
        [self styleMemberProfilePictureView:self.member7];
        
        self.lineSeparator = [[UIView alloc] init];
        self.lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
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
    
    // line separator
    self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - 1 / [UIScreen mainScreen].scale, self.frame.size.width, 1 / [UIScreen mainScreen].scale);
        
    self.contentView.frame = self.bounds;
    
    // profile pic collage
    self.member1.frame = CGRectMake(self.frame.size.width / 2 - (self.member1.frame.size.width / 2), 24, self.member1.frame.size.width, self.member1.frame.size.height);
    self.member2.frame = CGRectMake(self.member1.frame.origin.x - self.member2.frame.size.width - 32, 49, self.member2.frame.size.width, self.member2.frame.size.height);
    self.member3.frame = CGRectMake(self.frame.size.width - self.member2.frame.origin.x - self.member3.frame.size.width, 33, self.member3.frame.size.width, self.member3.frame.size.height);
    
    self.member4.frame = CGRectMake(self.member2.frame.origin.x - self.member4.frame.size.width - 24, 20, self.member4.frame.size.width, self.member4.frame.size.height);
    self.member5.frame = CGRectMake(self.frame.size.width - self.member4.frame.origin.x - self.member5.frame.size.width, 74, self.member5.frame.size.width, self.member5.frame.size.height);
    
    self.member6.frame = CGRectMake(self.member4.frame.origin.x - self.member6.frame.size.width - 8, 75, self.member6.frame.size.width, self.member6.frame.size.height);
    self.member7.frame = CGRectMake(self.frame.size.width - self.member6.frame.origin.x - self.member7.frame.size.width, 27, self.member7.frame.size.width, self.member7.frame.size.height);
    
    // text label
    CGRect textLabelRect = [self.nameLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - (24 * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.nameLabel.font} context:nil];
    self.nameLabel.frame = CGRectMake(24, 116, self.frame.size.width - (24 * 2), ceilf(textLabelRect.size.height));
    
    // detail text label
    CGRect detailLabelRect = [self.descriptionLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - (12 * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.descriptionLabel.font} context:nil];
    self.descriptionLabel.frame = CGRectMake(self.nameLabel.frame.origin.x, self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height + 4, self.nameLabel.frame.size.width, ceilf(detailLabelRect.size.height));
}

- (void)styleMemberProfilePictureView:(UIImageView *)imageView  {
    [self continuityRadiusForView:imageView withRadius:imageView.frame.size.height * .5];
    
    imageView.image = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    imageView.tintColor = [UIColor whiteColor];
    imageView.backgroundColor = [UIColor bonfireSecondaryColor];
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

@end
