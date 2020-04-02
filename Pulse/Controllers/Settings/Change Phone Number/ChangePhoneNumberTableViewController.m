//
//  ChangePhoneNumberTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 12/29/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ChangePhoneNumberTableViewController.h"
#import "InputCell.h"
#import "NSString+Validation.h"
#import "HAWebService.h"
#import "ResetPasswordViewController.h"
#import "BFMiniNotificationManager.h"
#import "BFAlertController.h"

#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <JGProgressHUD/JGProgressHUD.h>
#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>

@import Firebase;

@interface ChangePhoneNumberTableViewController ()

@end

@implementation ChangePhoneNumberTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Settings / Change Phone Number" screenClass:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        if ([self.tableView numberOfRowsInSection:0] > 0 &&
            [self inputCellForRowId:@"new_phone_number"]) {
            InputCell *phoneNumberCell = [self inputCellForRowId:@"new_phone_number"];
            [phoneNumberCell.input becomeFirstResponder];
        }
    }
}

- (void)setup {
    self.title = @"Phone Number";
    self.smartListDelegate = self;
    
    [self setupNavigationItems];
    
    [self setJsonFile:@"ChangePhoneNumber"];
}

- (void)setupNavigationItems {
    self.saveButton = [[UIBarButtonItem alloc] bk_initWithTitle:@"Save" style:UIBarButtonItemStyleDone handler:^(id sender) {
        [self saveChanges];
    }];
    [self.saveButton setTitleTextAttributes:@{
                                              NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightBold],
                                              NSForegroundColorAttributeName: [UIColor bonfirePrimaryColor]
                                              } forState:UIControlStateNormal];
    [self.saveButton setTitleTextAttributes:@{
                                              NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightBold],
                                              NSForegroundColorAttributeName: [UIColor bonfirePrimaryColor]
                                              } forState:UIControlStateHighlighted];
    [self.saveButton setTitleTextAttributes:@{
                                              NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightBold],
                                              NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]
                                              } forState:UIControlStateDisabled];
    self.navigationItem.rightBarButtonItem = self.saveButton;
    self.saveButton.enabled = false;
}

- (void)textFieldDidChange:(UITextField *)textField withRowId:(NSString *)rowId {
    BOOL qualifies = [self checkRequirements];
    
    self.saveButton.enabled = qualifies;
}

- (BOOL)checkRequirements {
    InputCell *newPhoneNumberCell = [self inputCellForRowId:@"new_phone_number"];
    
    if ([newPhoneNumberCell.input.text validateBonfirePhoneNumber] != BFValidationErrorNone) {
        return false;
    }
    
    return true;
}

- (void)saveChanges {
    InputCell *phoneNumberCell = [self inputCellForRowId:@"new_phone_number"];
    
    NSString *phoneNumber = [self formatPhoneNumber:phoneNumberCell.input.text];
    if ([phoneNumber isEqualToString:[self formatPhoneNumber:[Session sharedInstance].currentUser.attributes.phone]]) {
        BFAlertController *alert = [BFAlertController alertControllerWithTitle:@"Please Enter a New Number" message:@"The number you entered matches the existing phone number on your account" preferredStyle:BFAlertControllerStyleAlert];
        BFAlertAction *gotItAction = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleCancel handler:nil];
        [alert addAction:gotItAction];
        [[Launcher activeViewController] presentViewController:alert animated:true completion:nil];
        
        return;
    }
    
    [phoneNumberCell.input resignFirstResponder];
    
    JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
    HUD.textLabel.text = @"Texting you a code...";
    HUD.vibrancyEnabled = false;
    HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
    HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
    [HUD showInView:self.navigationController.view animated:YES];
    
    // prevent them from swiping to dismiss while changes are being saved
    self.navigationController.view.userInteractionEnabled = false;
    
    // 1. verify phone number with SMS auth
    [[HAWebService authenticatedManager] PUT:@"users/me" parameters:@{@"phone": phoneNumber} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [HUD dismiss];
        
        self.navigationController.view.userInteractionEnabled = true;
        // show alert asking for code to confirm
        [self promptToVerifyPhoneNumber:phoneNumber];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error saving user prefs");
        NSLog(@"error:");
        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@", ErrorResponse);
        
        self.navigationController.view.userInteractionEnabled = true;
        
        [HUD dismiss];
        
        BFAlertController *alert = [BFAlertController alertControllerWithTitle:@"Uh oh!" message:@"We encountered a network error while looking up your account. Check your network settings and try again." preferredStyle:BFAlertControllerStyleAlert];
        BFAlertAction *gotItAction = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleCancel handler:nil];
        [alert addAction:gotItAction];
        [[Launcher activeViewController] presentViewController:alert animated:true completion:nil];
    }];
}
- (void)promptToVerifyPhoneNumber:(NSString *)phoneNumber {
    // use BFAlertController
    BFAlertController *alert = [BFAlertController
                               alertControllerWithTitle:@"We just texted you a code!"
                               message:@"Please confirm the code below"
                               preferredStyle:BFAlertControllerStyleAlert];
    
    BFAlertAction *confirm = [BFAlertAction actionWithTitle:@"Confirm" style:BFAlertActionStyleDefault
                                               handler:^(){
        UITextField *textField = alert.textField;
                                                   
        if (textField.text.length > 0) {
            [self attemptToSavePhoneNumber:phoneNumber verificationCode:textField.text];
        }
        else {
            [[Launcher topMostViewController] presentViewController:alert animated:true completion:nil];
        }
                                               }];

    BFAlertAction *cancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel
                                                   handler:^() {
                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                   }];
    
    alert.preferredAction = confirm;
    [alert addAction:confirm];
    [alert addAction:cancel];
    
    UITextField *textField = [UITextField new];
    textField.placeholder = @"Code";
    textField.keyboardType = UIKeyboardTypeNumberPad;
    if (@available(iOS 12.0, *)) {
        textField.textContentType = UITextContentTypeOneTimeCode;
    }
    [alert setTextField:textField];
    [textField becomeFirstResponder];
    
    [[Launcher topMostViewController] presentViewController:alert animated:true completion:nil];
}

- (void)attemptToSavePhoneNumber:(NSString *)phoneNumber verificationCode:(NSString *)verificationCode {
    JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
    HUD.textLabel.text = @"Saving..";
    HUD.vibrancyEnabled = false;
    HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
    HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
    [HUD showInView:self.navigationController.view animated:YES];
    
    self.navigationController.view.userInteractionEnabled = false;
    
    [[HAWebService authenticatedManager] PUT:@"users/me" parameters:@{@"phone": phoneNumber, @"phone_code": verificationCode} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        BFMiniNotificationObject *notificationObject = [BFMiniNotificationObject notificationWithText:@"Saved Phone Number!" action:nil];
        [[BFMiniNotificationManager manager] presentNotification:notificationObject completion:^{

        }];
        
        // save user
        User *user = [[User alloc] initWithDictionary:responseObject[@"data"] error:nil];
        [[Session sharedInstance] updateUser:user];
        
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error saving user prefs");
        NSLog(@"error:");
        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@", ErrorResponse);
        HUD.indicatorView = [[JGProgressHUDErrorIndicatorView alloc] init];
        HUD.textLabel.text = @"Error Saving";
        
        self.navigationController.view.userInteractionEnabled = true;
        
        [HUD dismissAfterDelay:1.f];
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowWithId:(NSString *)rowId {
    if ([rowId isEqualToString:@"forgot_password"]) {
        ResetPasswordViewController *resetPasswordVC = [[ResetPasswordViewController alloc] init];
        resetPasswordVC.transitioningDelegate = [Launcher sharedInstance];
        [Launcher present:resetPasswordVC animated:YES];
    }
}

- (NSString *)formatPhoneNumber:(NSString *)string {
    NSLog(@"input string: %@", string);
    
    NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
    NSError *anError = nil;
    
    NSLocale *currentLocale = [NSLocale currentLocale];  // get the current locale.
    NSString *countryCode = [currentLocale objectForKey:NSLocaleCountryCode];
    NBPhoneNumber *myNumber = [phoneUtil parse:string
                                 defaultRegion:countryCode error:&anError];
    
    NSString *formatted = [phoneUtil format:myNumber
         numberFormat:NBEPhoneNumberFormatINTERNATIONAL
                error:&anError];
    
    formatted = [formatted stringByReplacingOccurrencesOfString:@"+" withString:@""];
    formatted = [formatted stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    NSLog(@"output string: %@", formatted);
    
    if (anError) {
        return @"";
    }
    else {
        return formatted;
    }
}

@end
