//
//  ChangePasswordTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 12/29/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ChangePasswordTableViewController.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "InputCell.h"
#import "NSString+Validation.h"
#import <JGProgressHUD/JGProgressHUD.h>
#import "HAWebService.h"

@interface ChangePasswordTableViewController ()

@property (strong, nonatomic) HAWebService *manager;

@end

@implementation ChangePasswordTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
}

- (void)setup {
    self.title = @"Change Password";
    self.smartListDelegate = self;
    
    [self setupNavigationItems];
    
    [self setJsonFile:@"ChangePassword"];
    
    self.manager = [HAWebService manager];
}

- (void)setupNavigationItems {
    self.saveButton = [[UIBarButtonItem alloc] bk_initWithTitle:@"Save" style:UIBarButtonItemStyleDone handler:^(id sender) {
        [self saveChanges];
    }];
    [self.saveButton setTitleTextAttributes:@{
                                              NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightBold]
                                              } forState:UIControlStateNormal];
    [self.saveButton setTitleTextAttributes:@{
                                              NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightBold]
                                              } forState:UIControlStateHighlighted];
    [self.saveButton setTitleTextAttributes:@{
                                              NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightBold]
                                              } forState:UIControlStateDisabled];
    self.navigationItem.rightBarButtonItem = self.saveButton;
    self.saveButton.enabled = false;
}

- (void)textFieldDidChange:(UITextField *)textField withRowId:(NSString *)rowId {
    BOOL qualifies = [self checkRequirements];
    
    self.saveButton.enabled = qualifies;
}

- (BOOL)checkRequirements {
    InputCell *currentPasswordCell = [self inputCellForRowId:@"current_password"];
    InputCell *newPasswordCell = [self inputCellForRowId:@"new_password"];
    InputCell *confirmPasswordCell = [self inputCellForRowId:@"confirm_password"];
    
    if ([currentPasswordCell.input.text validateBonfirePassword] != BFValidationErrorNone ||
        [newPasswordCell.input.text validateBonfirePassword] != BFValidationErrorNone ||
        [confirmPasswordCell.input.text validateBonfirePassword] != BFValidationErrorNone) {
        return false;
    }
    if (![newPasswordCell.input.text isEqualToString:confirmPasswordCell.input.text]) {
        return false;
    }
    
    return true;
}

- (void)saveChanges {
    InputCell *currentPasswordCell = [self inputCellForRowId:@"current_password"];
    InputCell *newPasswordCell = [self inputCellForRowId:@"new_password"];
    
    JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
    HUD.textLabel.text = @"Saving New Password..";
    HUD.vibrancyEnabled = false;
    HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
    HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
    [HUD showInView:self.navigationController.view animated:YES];
    
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
        
        NSString *url = [NSString stringWithFormat:@"%@/%@/users/me", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
        
        [self.manager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [self.manager PUT:url parameters:@{@"old_password": currentPasswordCell.input.text, @"password": newPasswordCell.input.text} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            HUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
            HUD.textLabel.text = @"Saved!";
            
            [HUD dismissAfterDelay:1.f];
            
            [self.navigationController popViewControllerAnimated:YES];
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"error saving user prefs");
            NSLog(@"error:");
            NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            NSLog(@"%@", ErrorResponse);
            HUD.indicatorView = [[JGProgressHUDErrorIndicatorView alloc] init];
            HUD.textLabel.text = @"Error Saving";
            
            [HUD dismissAfterDelay:1.f];
        }];
    }];
}

@end