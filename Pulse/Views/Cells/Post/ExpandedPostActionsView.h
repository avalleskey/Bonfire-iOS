//
//  ExpandedPostActionsView.h
//  Pulse
//
//  Created by Austin Valleskey on 9/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExpandedPostActionsView : UIView

@property (nonatomic, strong) UIButton *replyButton;
@property (nonatomic, strong) UIButton *voteButton;
@property (nonatomic, strong) UIButton *shareButton;

@property (nonatomic, strong) UIView *middleSeparator;
@property (nonatomic, strong) UIView *topSeparator;
@property (nonatomic, strong) UIView *bottomSeparator;

@end
