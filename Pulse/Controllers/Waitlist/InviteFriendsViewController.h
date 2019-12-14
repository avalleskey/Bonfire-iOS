//
//  InviteFriendsViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 8/12/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface InviteFriendsViewController : UIViewController

@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *nextButton;

@property (nonatomic, strong) UIButton *shareField;

@property (nonatomic, strong) UIView *infoView;
@property (nonatomic, strong) UILabel *invitesLeftLabel;
@property (nonatomic, strong) UILabel *inviteTitleLabel;
@property (nonatomic, strong) UILabel *inviteDescriptionLabel;

@end

NS_ASSUME_NONNULL_END
