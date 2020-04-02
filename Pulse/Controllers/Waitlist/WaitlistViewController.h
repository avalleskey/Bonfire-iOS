//
//  WaitlistViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 8/12/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFAvatarView.h"
#import <MarqueeLabel/MarqueeLabel.h>

NS_ASSUME_NONNULL_BEGIN

@class InviteStatusModel;

@interface WaitlistViewController : UIViewController

@property (nonatomic, strong) InviteStatusModel *inviteStatus;

@property (nonatomic, strong) UILabel *instructionLabel;

@property (nonatomic, strong) UILabel *redeemButtonHelperLabel;
@property (nonatomic, strong) UIButton *redeemButton;

@property (nonatomic, strong) UIView *centerView;
@property (nonatomic, strong) UIImageView *bigSpinner;

@property (nonatomic, strong) UILabel *rankLabel;
@property (nonatomic, strong) UILabel *peopleInFrontLabel;
@property (nonatomic, strong) MarqueeLabel *invitesNeededLabel;
@property (nonatomic, strong) UIView *shareActionsView;

@property (nonatomic, strong) UIView *invitedProgressView;
@property (nonatomic, strong) CAGradientLayer *invitedProgressGradientLayer;

@property (nonatomic, strong) NSMutableArray <BFAvatarView *> *invitedAvatarViews;

- (void)useFriendCode:(NSString *)friendCode;

@end

@interface InviteStatusModel : JSONModel

@property (nonatomic) NSInteger totalInvitesRequired;
@property (nonatomic) NSArray <User *><User, Optional> *invitees;
@property (nonatomic) NSInteger rank;

@end

NS_ASSUME_NONNULL_END
