//
//  StackedOnboardingViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 12/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HelloViewController : UIViewController <UIScrollViewDelegate, UITextFieldDelegate>

@property (nonatomic) CGFloat currentKeyboardHeight;

@property (nonatomic) BOOL fromLaunch;

@property (nonatomic, strong) UIButton *signInButton;
@property (nonatomic, strong) UIButton *signUpButton;

@property (nonatomic, strong) UILabel *welcomeLabel;
@property (nonatomic, strong) UILabel *whereConversationsHappenLabel;

@property (nonatomic, strong) UIImageView *launchLogo;

@property (nonatomic, strong) UIView *leftView;

@property (nonatomic, strong) UIView *middleView;
@property (nonatomic, strong) UIView *middleViewContainer;
@property (nonatomic, strong) UIImageView *middleViewImage;

@property (nonatomic, strong) UIView *rightView;

@end

NS_ASSUME_NONNULL_END
