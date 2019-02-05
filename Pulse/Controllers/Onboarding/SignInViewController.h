//
//  SignInViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 12/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SignInViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic) CGFloat currentKeyboardHeight;

@property (strong, nonatomic) UIView *content;

@property (nonatomic) BOOL fromLaunch;
@property (strong, nonatomic) UIImageView *launchLogo;
@property (strong, nonatomic) UIImageView *logo;

@property (strong, nonatomic) UIImageView *spinner;
@property (strong, nonatomic) UIView *signInView;
@property (strong, nonatomic) UITextField *emailTextField;
@property (strong, nonatomic) UITextField *passwordTextField;
@property (strong, nonatomic) UIButton *signInButton;

@property (strong, nonatomic) UILabel *signUpLabel;
@property (strong, nonatomic) UIButton *signUpButton;

@property (nonatomic) BOOL darkStatusBar;

@end

NS_ASSUME_NONNULL_END
