//
//  PostActionsView.h
//  Pulse
//
//  Created by Austin Valleskey on 9/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PostActionsView : UIView

@property (nonatomic, strong) UIButton *sparkButton;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) UIButton *moreButton;

@property (strong, nonatomic) UIView *middleSeparator;
@property (strong, nonatomic) UIView *topSeparator;
@property (strong, nonatomic) UIView *bottomSeparator;

@end
