//
//  ResetPasswordViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 4/9/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ResetPasswordViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic, strong) UILabel *instructionLabel;

@property (nonatomic, strong) UIButton *nextButton;

@property (nonatomic, strong) NSString *prefillLookup;

@end

NS_ASSUME_NONNULL_END
