//
//  ModifyDefaultsViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ModifyDefaultsViewController.h"
#import "Session.h"

#import "ProfilePictureCell.h"
#import "ThemeSelectorCell.h"
#import "InputCell.h"
#import "ButtonCell.h"
#import "AppDelegate.h"
#import "HAWebService.h"
#import "UIColor+Palette.h"
#import "Launcher.h"

#import <RSKImageCropper/RSKImageCropper.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <JGProgressHUD/JGProgressHUD.h>

@interface ModifyDefaultsViewController () <UITextFieldDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) HAWebService *manager;

@end

@implementation ModifyDefaultsViewController

static NSString * const blankReuseIdentifier = @"BlankCell";

static NSString * const inputReuseIdentifier = @"InputCell";
static NSString * const buttonReuseIdentifier = @"ButtonCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Edit Profile";
    
    self.manager = [HAWebService manager];
    
    self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss:)];
    [self.cancelButton setTintColor:[UIColor whiteColor]];
    [self.cancelButton setTitleTextAttributes:@{
                                         NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium]
                                         } forState:UIControlStateNormal];
    [self.cancelButton setTitleTextAttributes:@{
                                              NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium]
                                              } forState:UIControlStateHighlighted];
    self.navigationItem.leftBarButtonItem = self.cancelButton;
    
    self.saveButton = [[UIBarButtonItem alloc] bk_initWithTitle:@"Save" style:UIBarButtonItemStyleDone handler:^(id sender) {
        [self saveChanges];
    }];
    [self.saveButton setTintColor:[UIColor whiteColor]];
    [self.saveButton setTitleTextAttributes:@{
                                           NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightBold]
                                           } forState:UIControlStateNormal];
    [self.saveButton setTitleTextAttributes:@{
                                              NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightBold]
                                              } forState:UIControlStateHighlighted];
    self.navigationItem.rightBarButtonItem = self.saveButton;
    
    
    self.tableView.backgroundColor = [UIColor headerBackgroundColor];
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.separatorColor = [UIColor separatorColor];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 48, 0);
    
    self.themeColor = [Session sharedInstance].themeColor;
    
    // add background color view
    self.navigationBackgroundView = [[UIView alloc] init];
    self.navigationBackgroundView.layer.masksToBounds = true;
    // remove hairline
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    
    if ([UIColor useWhiteForegroundForColor:self.themeColor]) {
        [self.navigationController.navigationBar setTitleTextAttributes:
         @{NSForegroundColorAttributeName:[UIColor whiteColor],
           NSFontAttributeName:[UIFont systemFontOfSize:18.f weight:UIFontWeightBold]}];
        self.cancelButton.tintColor = [UIColor whiteColor];
        self.saveButton.tintColor = [UIColor whiteColor];
    }
    else {
        [self.navigationController.navigationBar setTitleTextAttributes:
         @{NSForegroundColorAttributeName:[UIColor colorWithWhite:0.07f alpha:1],
           NSFontAttributeName:[UIFont systemFontOfSize:18.f weight:UIFontWeightBold]}];
        
        self.cancelButton.tintColor = [UIColor colorWithWhite:0.07f alpha:1];
        self.saveButton.tintColor = [UIColor colorWithWhite:0.07f alpha:1];
    }
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    
    [self.tableView registerClass:[InputCell class] forCellReuseIdentifier:inputReuseIdentifier];
    [self.tableView registerClass:[ButtonCell class] forCellReuseIdentifier:buttonReuseIdentifier];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationBackgroundView.frame = CGRectMake(0, self.navigationController.navigationBar.frame.size.height - (self.navigationController.navigationBar.frame.size.height + 50), self.view.frame.size.width, self.navigationController.navigationBar.frame.size.height + 50);
    [self.navigationController.navigationBar insertSubview:self.navigationBackgroundView atIndex:1];
}

- (NSArray *)defaultsKeysArray {
    static NSArray *defaultsKeysArray = nil;
    if (!defaultsKeysArray) defaultsKeysArray = [[[[[Session sharedInstance] defaults] toDictionary] allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    return defaultsKeysArray;
}

- (void)saveChanges {
    // first verify requirements have been met
    [self.view endEditing:TRUE];
    
    NSDictionary *changes = [self changes];
    
    NSLog(@"changes: %@", changes);
    
    if (changes != nil && changes.count > 0) {
        // requirements have been met and there's more than one change to save
        
        JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
        HUD.textLabel.text = @"Saving...";
        HUD.vibrancyEnabled = false;
        HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
        HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
        [HUD showInView:self.navigationController.view animated:YES];
        
        [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            NSString *url = [NSString stringWithFormat:@"%@/%@/users/me", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
            
            [self.manager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            [self.manager PUT:url parameters:changes success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // success
                HUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
                HUD.textLabel.text = @"Success!";
                
                [HUD dismissAfterDelay:0.3f];
                
                // save user
                User *user = [[User alloc] initWithDictionary:responseObject[@"data"] error:nil];
                [[Session sharedInstance] updateUser:user]; // TODO: Swap out for new user object
                                
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"error saving user prefs");
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                HUD.indicatorView = [[JGProgressHUDErrorIndicatorView alloc] init];
                HUD.textLabel.text = @"Error Saving";
                
                [HUD dismissAfterDelay:1.f];
            }];
        }];
    }
    else {
        [self dismiss:nil];
    }
}
- (NSDictionary *)changes {
    NSMutableDictionary *changes = [[NSMutableDictionary alloc] init];
    
    InputCell *displayNameCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    NSString *displayName = displayNameCell.input.text;
    
    if (![displayName isEqualToString:[Session sharedInstance].currentUser.attributes.details.displayName]) {
        if (displayName.length == 0) {
            [self alertWithTitle:@"Requirements Not Met" message:@"Uh oh! Your display name must be at least 1 character"];
            
            return nil;
        }
        else {
            // good to go!
            [changes setObject:displayName forKey:@"display_name"];
        }
    }
    
    InputCell *usernameCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    NSString *username = [usernameCell.input.text stringByReplacingOccurrencesOfString:@"@" withString:@""];
    
    if (![username isEqualToString:[Session sharedInstance].currentUser.attributes.details.identifier]) {
        if (username.length < 3) {
            [self alertWithTitle:@"Requirements Not Met" message:@"Uh oh! Your username must be at least 3 characters"];
            
            return nil;
        }
        else {
            // good to go!
            [changes setObject:username forKey:@"username"];
        }
    }
    
    ThemeSelectorCell *themeColorCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    NSString *themeColor = themeColorCell.selectedColor;
    
    if (![[themeColor lowercaseString] isEqualToString:[[Session sharedInstance].currentUser.attributes.details.color lowercaseString]]) {
        if (themeColor.length != 6) {
            [self alertWithTitle:@"Invalid Favorite Color" message:@"Well... this is awkward! Try closing out and trying again!"];
            
            return nil;
        }
        else {
            // good to go!
            [changes setObject:themeColor forKey:@"color"];
        }
    }
    
    return changes;
}
- (void)alertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:okAction];
    
    [self.navigationController presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self defaultsKeysArray] count] + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == [self.defaultsKeysArray count]) return 1;
    
    NSString *key = [self defaultsKeysArray][section];
    
    return [[self objectsInSection:key] count];
}
- (NSArray *)objectsInSection:(NSString *)key {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    NSDictionary *section = [[[Session sharedInstance] defaults] toDictionary][key];
    
    for (NSString* key in section) {
        id value = section[key];
        
        // do stuff
        [array addObject:value];
    }
    
    return array;
}

- (void)dismiss:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 2 || indexPath.row == 3) {
            InputCell *cell = [tableView dequeueReusableCellWithIdentifier:inputReuseIdentifier forIndexPath:indexPath];
            
            // Configure the cell...
            if (indexPath.row == 2) {
                cell.inputLabel.text = @"Name";
                cell.input.text = [Session sharedInstance].currentUser.attributes.details.displayName;
                cell.input.placeholder = @"John Doe";
                cell.input.tag = 1;
            }
            else if (indexPath.row == 3) {
                cell.inputLabel.text = @"Username";
                cell.input.text = [NSString stringWithFormat:@"@%@", [Session sharedInstance].currentUser.attributes.details.identifier];
                cell.input.placeholder = @"@username";
                cell.input.tag = 2;
            }
            
            cell.input.delegate = self;
            
            // cell.input.tintColor = self.themeColor;
            
            return cell;
        }
    }
    else if (indexPath.section == [[[[Session sharedInstance].defaults toDictionary] allKeys] count]) {
        // last row
        ButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:buttonReuseIdentifier forIndexPath:indexPath];
        
        // Configure the cell...
        cell.buttonLabel.text = @"Sign Out";
        cell.buttonLabel.textColor = cell.kButtonColorDestructive;
        
        return cell;
    }
    
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankReuseIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.tableView.frame.size.height / 2, 0);
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    NSLog(@"%@",newStr);
    if (textField.tag == 1) {
        return newStr.length <= 40 ? YES : NO;
    }
    else if (textField.tag == 2) {
        return newStr.length >= 1 && [newStr stringByReplacingOccurrencesOfString:@"@" withString:@""].length <= 15 ? YES : NO;
    }
    
    return YES;
}
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 48, 0);
    return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            return 148;
        }
        else if (indexPath.row == 1) {
            return 106;
        }
        else if (indexPath.row == 2 || indexPath.row == 3) {
            return 86;
        }
    }
    else if (indexPath.section == 1) {
        return 52;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return 64;
    }
    
    return 0;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // become first responder
    }
    else if (indexPath.section == 1) {
        // sign out
        UIAlertController *areYouSure = [UIAlertController alertControllerWithTitle:@"Sign Out?" message:@"Please confirm you would like to sign out" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [areYouSure dismissViewControllerAnimated:YES completion:nil];
        }];
        [areYouSure addAction:cancel];
        
        UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Sign Out" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [[Session sharedInstance] signOut];
            
            [[Launcher sharedInstance] openOnboarding];
            
            [areYouSure dismissViewControllerAnimated:YES completion:nil];
        }];
        [areYouSure addAction:confirm];
        
        [self.navigationController presentViewController:areYouSure animated:YES completion:nil];
    }
}

@end
