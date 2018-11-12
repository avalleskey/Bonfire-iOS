//
//  HeaderView.m
//  Pulse
//
//  Created by Austin Valleskey on 9/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "HeaderView.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <HapticHelper/HapticHelper.h>
#import "Session.h"
#import "Defaults.h"

@implementation HeaderView

- (id)initWithFrame:(CGRect)frame andTitle:(NSString *)title description:(NSString *)description members:(NSArray *)members buttonTitle:(NSString *)buttonTitle {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.font = [UIFont systemFontOfSize:34.f weight:UIFontWeightHeavy];
        self.nameLabel.textColor = [UIColor whiteColor];
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        self.nameLabel.numberOfLines = 0;
        self.nameLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.nameLabel.text = title;
        [self addSubview:self.nameLabel];
        
        self.descriptionLabel = [[UILabel alloc] init];
        self.descriptionLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightMedium];
        self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
        self.descriptionLabel.textColor = [UIColor colorWithWhite:1 alpha:0.8];
        self.descriptionLabel.numberOfLines = 0;
        self.descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.descriptionLabel.text = description;
        [self addSubview:self.descriptionLabel];
        
        self.statsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 48)];
        [self addSubview:self.statsView];
        
        self.membersLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width / 2, 14)];
        self.membersLabel.textAlignment = NSTextAlignmentCenter;
        self.membersLabel.textColor = [UIColor colorWithWhite:1 alpha:0.75];
        self.membersLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
        self.membersLabel.text = [NSString stringWithFormat:@"0 %@", [Session sharedInstance].defaults.room.membersTitle.plural];
        [self.statsView addSubview:self.membersLabel];
        
        self.postsCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width / 2, 0, self.frame.size.width / 2, 14)];
        self.postsCountLabel.textAlignment = NSTextAlignmentCenter;
        self.postsCountLabel.textColor = [UIColor colorWithWhite:1 alpha:0.75];
        self.postsCountLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
        self.postsCountLabel.text = @"450 posts";
        [self.statsView addSubview:self.postsCountLabel];
        
        self.statsViewMiddleSeparator = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - 0.5, 16, 2, 16)];
        self.statsViewMiddleSeparator.backgroundColor = [UIColor colorWithWhite:1 alpha:0.25f];
        self.statsViewMiddleSeparator.layer.cornerRadius = 1.f;
        self.statsViewMiddleSeparator.layer.masksToBounds = true;
        [self.statsView addSubview:self.statsViewMiddleSeparator];
        
        self.actionsBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 32)];
        [self addSubview:self.actionsBarView];
        
        self.membersContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.actionsBarView.frame.size.width, self.actionsBarView.frame.size.height)];
        [self.actionsBarView addSubview:self.membersContainer];
        
        self.member1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 72, 72)];
        self.member1.layer.cornerRadius = self.member1.frame.size.width / 2;
        self.member1.layer.borderWidth = 4.f;
        self.member1.layer.borderColor = [UIColor whiteColor].CGColor;
        self.member1.layer.masksToBounds = true;
        
        self.member2 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        self.member3 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        
        self.member4 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        self.member5 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        
        self.member6 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        self.member7 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        
        [self.membersContainer addSubview:self.member1];
        [self.membersContainer addSubview:self.member2];
        [self.membersContainer addSubview:self.member3];
        [self.membersContainer addSubview:self.member4];
        [self.membersContainer addSubview:self.member5];
        [self.membersContainer addSubview:self.member6];
        [self.membersContainer addSubview:self.member7];
        
        [self styleMemberProfilePictureView:self.member2];
        [self styleMemberProfilePictureView:self.member3];
        [self styleMemberProfilePictureView:self.member4];
        [self styleMemberProfilePictureView:self.member5];
        [self styleMemberProfilePictureView:self.member6];
        [self styleMemberProfilePictureView:self.member7];
        
        self.followButton = [FollowButton buttonWithType:UIButtonTypeCustom];
        self.followButton.layer.borderWidth = 2.f;
        self.followButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
        self.followButton.backgroundColor = [UIColor clearColor];
        [self.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.followButton setImage:[[UIImage imageNamed:@"plusIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self.followButton setTitle:@"Join Room" forState:UIControlStateNormal];
        [self.followButton bk_whenTapped:^{
            NSLog(@"holaaa");
        }];
        [self addSubview:self.followButton];
        
        self.lineSeparator = [[UIView alloc] init];
        self.lineSeparator.backgroundColor = [UIColor colorWithWhite:0 alpha:0.06f];
        //[self addSubview:self.lineSeparator];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // line separator
    self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - 1, self.frame.size.width, 1);
    
    // profile pic collage
    self.member1.frame = CGRectMake(self.frame.size.width / 2 - (self.member1.frame.size.width / 2), 27, self.member1.frame.size.width, self.member1.frame.size.height);
    
    self.member2.frame = CGRectMake(self.member1.frame.origin.x - self.member2.frame.size.width - 32, 49, self.member2.frame.size.width, self.member2.frame.size.height);
    self.member3.frame = CGRectMake(self.frame.size.width - self.member2.frame.origin.x - self.member3.frame.size.width, 33, self.member3.frame.size.width, self.member3.frame.size.height);
    
    self.member4.frame = CGRectMake(self.member2.frame.origin.x - self.member4.frame.size.width - 24, 20, self.member4.frame.size.width, self.member4.frame.size.height);
    self.member5.frame = CGRectMake(self.frame.size.width - self.member4.frame.origin.x - self.member5.frame.size.width, 74, self.member5.frame.size.width, self.member5.frame.size.height);
    
    self.member6.frame = CGRectMake(self.member4.frame.origin.x - self.member6.frame.size.width - 8, 75, self.member6.frame.size.width, self.member6.frame.size.height);
    self.member7.frame = CGRectMake(self.frame.size.width - self.member6.frame.origin.x - self.member7.frame.size.width, 27, self.member7.frame.size.width, self.member7.frame.size.height);
    
    // colorize ish
    [self.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.followButton.tintColor = [UIColor whiteColor];
    self.followButton.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1f].CGColor;
    
    // text label
    CGRect textLabelRect = [self.nameLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - (24 * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.nameLabel.font} context:nil];
    self.nameLabel.frame = CGRectMake(24, 116, self.frame.size.width - (24 * 2), ceilf(textLabelRect.size.height));
    
    // detail text label
    CGRect detailLabelRect = [self.descriptionLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - (12 * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.descriptionLabel.font} context:nil];
    self.descriptionLabel.frame = CGRectMake(self.nameLabel.frame.origin.x, self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height + 4, self.nameLabel.frame.size.width, ceilf(detailLabelRect.size.height));
    
    self.followButton.frame = CGRectMake(12, self.descriptionLabel.frame.origin.y + self.descriptionLabel.frame.size.height + 14, self.frame.size.width - 24, 40);
    
    self.statsView.frame = CGRectMake(12, self.followButton.frame.origin.y + self.followButton.frame.size.height, self.frame.size.width - 24, self.statsView.frame.size.height);
    self.statsViewMiddleSeparator.frame = CGRectMake(self.statsView.frame.size.width / 2, self.statsViewMiddleSeparator.frame.origin.y, self.statsViewMiddleSeparator.frame.size.width, self.statsViewMiddleSeparator.frame.size.height);
    
    self.membersLabel.frame = CGRectMake(0, 0, self.statsView.frame.size.width / 2, self.statsView.frame.size.height);
    self.postsCountLabel.frame = CGRectMake(self.statsView.frame.size.width / 2, 0, self.statsView.frame.size.width / 2, self.statsView.frame.size.height);
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.statsView.frame.origin.y + self.statsView.frame.size.height);
}

- (void)styleMemberProfilePictureView:(UIImageView *)imageView  {
    [self continuityRadiusForView:imageView withRadius:imageView.frame.size.height * .25];
    //    imageView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2f];
    imageView.tintColor = [UIColor colorWithWhite:1 alpha:0.75];
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}

@end
