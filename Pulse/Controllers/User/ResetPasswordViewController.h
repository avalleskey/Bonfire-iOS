//
//  ResetPasswordViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 4/9/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ResetPasswordViewControllerDelegate <NSObject>

@optional;
- (void)passwordDidChange:(NSString *)newPassword;

@end

@interface ResetPasswordViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, weak) id <ResetPasswordViewControllerDelegate> delegate;

@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic, strong) UILabel *instructionLabel;

@property (nonatomic, strong) UIButton *nextButton;

typedef enum {
    ResetPasswordContextTypeOptional,
    ResetPasswordContextTypeRequired
} ResetPasswordContextType;
@property (nonatomic) ResetPasswordContextType contextType;
@property (nonatomic, strong) NSString *prefillLookup;
@property (nonatomic, strong) NSString *prefillCode;

@end

NS_ASSUME_NONNULL_END
