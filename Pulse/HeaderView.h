//
//  HeaderView.h
//  Pulse
//
//  Created by Austin Valleskey on 9/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FollowButton.h"

@interface HeaderView : UIView

- (id)initWithFrame:(CGRect)frame andTitle:(NSString *)title description:(NSString *)description members:(NSArray *)members buttonTitle:(NSString *)buttonTitle;

@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UILabel *descriptionLabel;

@property (strong, nonatomic) FollowButton *followButton;

@property (strong, nonatomic) UIView *statsView;
@property (strong, nonatomic) UIView *statsViewTopSeparator;
@property (strong, nonatomic) UIView *statsViewMiddleSeparator;
@property (strong, nonatomic) UILabel *membersLabel;
@property (strong, nonatomic) UILabel *postsCountLabel;

@property (strong, nonatomic) UIView *actionsBarView;
@property (strong, nonatomic) UIView *membersContainer;

@property (strong, nonatomic) UIImageView *member1;
@property (strong, nonatomic) UIImageView *member2;
@property (strong, nonatomic) UIImageView *member3;
@property (strong, nonatomic) UIImageView *member4;
@property (strong, nonatomic) UIImageView *member5;
@property (strong, nonatomic) UIImageView *member6;
@property (strong, nonatomic) UIImageView *member7;

@property (strong, nonatomic) UIView *lineSeparator;

@end
