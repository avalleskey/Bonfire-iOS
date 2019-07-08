//
//  EditProfileViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "EditProfileViewController.h"
#import "Session.h"
#import "SimpleNavigationController.h"

#import "Launcher.h"
#import "ProfilePictureCell.h"
#import "ThemeSelectorCell.h"
#import "InputCell.h"
#import "ButtonCell.h"
#import "AppDelegate.h"
#import "HAWebService.h"
#import "UIColor+Palette.h"
#import "NSString+Validation.h"
#import "BFHeaderView.h"

#import "ErrorCodes.h"
#import <NSString+EMOEmoji.h>

#import <RSKImageCropper/RSKImageCropper.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "UIImage+WithColor.h"
#import <JGProgressHUD/JGProgressHUD.h>
@import Firebase;

@interface EditProfileViewController () <UITextFieldDelegate, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, RSKImageCropViewControllerDelegate, RSKImageCropViewControllerDataSource> {
    UIImage *newAvatar;
    NSString *userBio;
}

@end

@implementation EditProfileViewController

static NSString * const blankReuseIdentifier = @"BlankCell";

static NSString * const profilePictureReuseIdentifier = @"ProfilePictureCell";
static NSString * const themeSelectorReuseIdentifier = @"ThemeSelectorCell";
static NSString * const inputReuseIdentifier = @"InputCell";
static NSString * const buttonReuseIdentifier = @"ButtonCell";

static int const DISPLAY_NAME_FIELD = 201;
static int const USERNAME_FIELD = 202;
static int const BIO_FIELD = 203;
static int const LOCATION_FIELD = 204;
static int const WEBSITE_FIELD = 205;
static int const EMAIL_FIELD = 206;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Edit Profile";
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    self.user = [Session sharedInstance].currentUser;
    
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
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 0);
    self.tableView.separatorColor = [UIColor separatorColor];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 48, 0);
    
    self.themeColor = [UIColor fromHex:[[Session sharedInstance] currentUser].attributes.details.color];
    [(SimpleNavigationController *)self.navigationController updateBarColor:self.themeColor animated:false];
    
    // remove hairline
    self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
    // [self.navigationController.navigationBar setBackgroundImage:[UIImage imageWithColor:[UIColor clearColor]] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    
    [self.tableView registerClass:[ProfilePictureCell class] forCellReuseIdentifier:profilePictureReuseIdentifier];
    [self.tableView registerClass:[ThemeSelectorCell class] forCellReuseIdentifier:themeSelectorReuseIdentifier];
    [self.tableView registerClass:[InputCell class] forCellReuseIdentifier:inputReuseIdentifier];
    [self.tableView registerClass:[ButtonCell class] forCellReuseIdentifier:buttonReuseIdentifier];
    
    userBio = [[Session sharedInstance] currentUser].attributes.details.bio;
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Edit Profile" screenClass:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.view.tag != 1) {
        self.view.tag = 1;
        
        [(SimpleNavigationController *)self.navigationController updateBarColor:self.themeColor animated:false];
        
        self.view.tintColor = self.themeColor;
        
        [self.tableView reloadData];
    }
}

- (void)themeSelectionDidChange:(NSString *)newHex {
    self.themeColor = [UIColor fromHex:newHex];
    [(SimpleNavigationController *)self.navigationController updateBarColor:self.themeColor animated:true];
    
    self.view.tintColor = self.themeColor;
    
    [self.tableView reloadData];
}

- (void)saveChanges {
    // first verify requirements have been met
    [self.view endEditing:TRUE];
    
    NSDictionary *changes = [self changes];
    NSLog(@"changes: %@", changes);
    
    if ([changes objectForKey:@"error"])
        return;
    
    if (changes && [changes allKeys].count > 0) {
        // requirements have been met and there's more than one change to save
        
        JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
        HUD.textLabel.text = @"Saving...";
        HUD.vibrancyEnabled = false;
        HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
        HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
        [HUD showInView:self.navigationController.view animated:YES];
        
        // new
        void (^errorSaving)(void) = ^() {
            HUD.indicatorView = [[JGProgressHUDErrorIndicatorView alloc] init];
            HUD.textLabel.text = @"Error Saving";
            [HUD dismissAfterDelay:1.f];
        };
        
        void (^saveUser)(NSString *uploadedImage) = ^(NSString *uploadedImage) {
            NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:changes];
            if ([params objectForKey:@"user_avatar"]) {
                if (uploadedImage) {
                    [params setObject:uploadedImage forKey:@"user_avatar"];
                }
                else {
                    [params removeObjectForKey:@"user_avatar"];
                }
            }
            
            NSLog(@"params: %@", params);
            
            [[HAWebService authenticatedManager] PUT:@"users/me" parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"response object: %@", responseObject);
                
                // success
                HUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
                HUD.textLabel.text = @"Success!";
                
                [HUD dismissAfterDelay:1.f];
                
                // save user
                User *user = [[User alloc] initWithDictionary:responseObject[@"data"] error:nil];
                [[Session sharedInstance] updateUser:user]; // TODO: Swap out for new user object
                
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"error saving user prefs");
                NSLog(@"error:");
                
                NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
                NSInteger httpCode = httpResponse.statusCode;
                NSInteger code = 0;
                
                NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                NSLog(@"erorr repsonse: %@", ErrorResponse);
                NSData *errorData = [ErrorResponse dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *errorDict = [NSJSONSerialization JSONObjectWithData:errorData options:0 error:nil];
                if ([errorDict objectForKey:@"error"]) {
                    if (errorDict[@"error"][@"code"]) {
                        code = [errorDict[@"error"][@"code"] integerValue];
                    }
                }
                
                if (code == NO_CHANGE_OCCURRED || httpCode == 304) {
                    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                }
                else if (code == USER_EMAIL_TAKEN) {
                    HUD.indicatorView = [[JGProgressHUDErrorIndicatorView alloc] init];
                    HUD.textLabel.text = @"Email Already Taken";
                }
                else if (code == USER_USERNAME_TAKEN) {
                    HUD.indicatorView = [[JGProgressHUDErrorIndicatorView alloc] init];
                    HUD.textLabel.text = @"Username Already Taken";
                }
                else {
                    HUD.indicatorView = [[JGProgressHUDErrorIndicatorView alloc] init];
                    HUD.textLabel.text = @"Error Saving";
                }
                NSLog(@"%@", ErrorResponse);
                
                [HUD dismissAfterDelay:1.f];
            }];
        };
        
        if ([changes objectForKey:@"user_avatar"]) {
            // upload avatar
            BFMediaObject *avatarObject = [[BFMediaObject alloc] initWithImage:newAvatar];
            [BFAPI uploadImage:avatarObject copmletion:^(BOOL success, NSString * _Nonnull uploadedImageURL) {
                if (success && uploadedImageURL && uploadedImageURL.length > 0) {
                    saveUser(uploadedImageURL);
                }
                else {
                    errorSaving();
                }
            }];
        }
        else {
            saveUser(nil);
        }
    }
    else {
        [self dismiss:nil];
    }
}
- (NSDictionary *)changes {
    NSMutableDictionary *changes = [[NSMutableDictionary alloc] init];
    
    if (newAvatar) {
        [changes setObject:newAvatar forKey:@"user_avatar"];
    }
    
    InputCell *displayNameCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    NSString *displayName = displayNameCell.input.text;
    
    if (![displayName isEqualToString:self.user.attributes.details.displayName]) {
        BFValidationError error = [displayName validateBonfireDisplayName];
        if (error == BFValidationErrorNone) {
            // good to go!
            [changes setObject:displayName forKey:@"display_name"];
        }
        else {
            NSString *title = @"";
            NSString *message = @"";
            switch (error) {
                case BFValidationErrorTooShort:
                    title = @"Display Name Too Short";
                    message = @"Your display name must at least 1 character long";
                    break;
                case BFValidationErrorTooLong:
                    title = @"Display Name Too Long";
                    message = [NSString stringWithFormat:@"Your display name cannot be longer than 40 characters"];
                    break;
                case BFValidationErrorContainsInvalidWords:
                    title = @"Display Name Cannot Contain Certain Words";
                    message = [NSString stringWithFormat:@"To protect our community, your display name cannot contain the words Bonfire, Admin, or Moderator as indivudal words"];
                    break;
                    
                default:
                    title = @"Requirements Not Met";
                    message = [NSString stringWithFormat:@"Please ensure that your display name is between 1 and 40 characters long"];
                    break;
            }
            
            [self alertWithTitle:title message:message];
            
            return @{@"error": @"display_name"};
        }
    }
    
    InputCell *usernameCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    NSString *username = [usernameCell.input.text stringByReplacingOccurrencesOfString:@"@" withString:@""];
    
    if (![username isEqualToString:self.user.attributes.details.identifier]) {
        BFValidationError error = [username validateBonfireUsername];
        if (error == BFValidationErrorNone) {
            // good to go!
            [changes setObject:username forKey:@"username"];
        }
        else {
            NSString *title = @"";
            NSString *message = @"";
            switch (error) {
                case BFValidationErrorTooShort:
                    title = @"Username Too Short";
                    message = @"Your username must at least 3 characters long";
                    break;
                case BFValidationErrorTooLong:
                    title = @"Username Too Long";
                    message = [NSString stringWithFormat:@"Your username cannot be longer than 15 characters"];
                    break;
                case BFValidationErrorContainsInvalidCharacters:
                    title = @"Username Cannot Contain Special Characters";
                    message = [NSString stringWithFormat:@"Your username can only contain alphanumeric characters (letters A-Z, numbers 0-9) with the exception of underscores"];
                    break;
                case BFValidationErrorContainsInvalidWords:
                    title = @"Username Cannot Contain Certain Words";
                    message = [NSString stringWithFormat:@"To protect our community, your username cannot contain the words Bonfire, Admin, or Moderator"];
                    break;
                    
                default:
                    title = @"Unexpected Username Error";
                    message = [NSString stringWithFormat:@"Please ensure that your display name is between 1 and 40 characters long"];
                    break;
            }
            
            [self alertWithTitle:title message:message];
            
            return @{@"error": @"username"};
        }
    }
    
    // bio
    InputCell *bioCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    NSString *bio = bioCell.textView.text;
    
    if (![bio isEqualToString:self.user.attributes.details.bio]) {
        BFValidationError error = [displayName validateBonfireBio];
        if (error == BFValidationErrorNone) {
            // good to go!
            [changes setObject:bio forKey:@"bio"];
        }
        else {
            NSString *title = @"";
            NSString *message = @"";
            switch (error) {
                case BFValidationErrorTooLong:
                    title = @"Bio Too Long";
                    message = [NSString stringWithFormat:@"Your bio cannot be longer than 150 characters"];
                    break;
                    
                default:
                    title = @"Requirements Not Met";
                    message = [NSString stringWithFormat:@"Please ensure that your bio is no longer than 150 characters and contains no unusual characters"];
                    break;
            }
            
            [self alertWithTitle:title message:message];
            
            return @{@"error": @"bio"};
        }
    }
    
    // location
    InputCell *locationCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
    NSString *location = locationCell.input.text;
    
    NSString *currentLocation = self.user.attributes.details.location.value;
    if (!currentLocation) currentLocation = @"";
    
    if (![location isEqualToString:currentLocation]) {
        BFValidationError error = [location validateBonfireLocation];
        if (error == BFValidationErrorNone) {
            // good to go!
            [changes setObject:location forKey:@"location"];
        }
        else {
            NSString *title = @"";
            NSString *message = @"";
            switch (error) {
                case BFValidationErrorTooLong:
                    title = @"Location Too Long";
                    message = [NSString stringWithFormat:@"Your location cannot be longer than 30 characters"];
                    break;
                    
                default:
                    title = @"Requirements Not Met";
                    message = [NSString stringWithFormat:@"Please ensure that your location is no longer than 30 characters and contains no unusual characters"];
                    break;
            }
            
            [self alertWithTitle:title message:message];
            
            return @{@"error": @"location"};
        }
    }
    
    // website
    InputCell *websiteCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:0]];
    NSString *website = websiteCell.input.text;
    
    NSString *currentWebsite = self.user.attributes.details.website.value;
    if (!currentWebsite) currentWebsite = @"";
    
    if (![website isEqualToString:currentWebsite]) {
        BFValidationError error = [website validateBonfireWebsite];
        if (error == BFValidationErrorNone || website.length == 0) {
            if (website.length > 0) {
                // if setting a new website, prepend http:// to the beginning if it doesn't exist already
                if ([website rangeOfString:@"http://"].length == 0 && [website rangeOfString:@"https://"].length == 0) {
                    // prepend http:// if needed
                    website = [@"http://" stringByAppendingString:website];
                }
            }
            
            [changes setObject:website forKey:@"website"];
        }
        else {
            NSString *title = @"";
            NSString *message = @"";
            switch (error) {
                case BFValidationErrorTooLong:
                    title = @"Location Too Long";
                    message = [NSString stringWithFormat:@"Your location cannot be longer than 30 characters"];
                    break;
                case BFValidationErrorInvalidURL:
                    title = @"Invalid URL";
                    message = [NSString stringWithFormat:@"Please ensure that the URL provided is valid"];
                    break;
                    
                default:
                    title = @"Requirements Not Met";
                    message = [NSString stringWithFormat:@"Please ensure that your location is no longer than 30 characters and contains no unusual characters"];
                    break;
            }
            
            [self alertWithTitle:title message:message];
            
            return @{@"error": @"website"};
        }
    }
    
    ThemeSelectorCell *themeColorCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:6 inSection:0]];
    NSString *themeColor = themeColorCell.selectedColor;
    
    if (![[themeColor lowercaseString] isEqualToString:[self.user.attributes.details.color lowercaseString]]) {
        if (themeColor.length != 6) {
            [self alertWithTitle:@"Couldn't Save Color" message:@"Please ensure you've selected a theme color from the list and try again."];
            
            return @{@"error": @"color"};
        }
        else {
            // good to go!
            [changes setObject:themeColor forKey:@"color"];
        }
    }
    
    InputCell *emailCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    NSString *email = emailCell.input.text;
    
    if (![email isEqualToString:self.user.attributes.details.email]) {
        BFValidationError error = [email validateBonfireEmail];
        if (error == BFValidationErrorNone) {
            // good to go!
            [changes setObject:email forKey:@"email"];
        }
        else {
            NSString *title = @"";
            NSString *message = @"";
            switch (error) {
                case BFValidationErrorTooLong:
                    title = @"Email Too Long";
                    message = [NSString stringWithFormat:@"Your email cannot be longer than 255 characters"];
                    break;
                case BFValidationErrorInvalidEmail:
                    title = @"Invalid Email";
                    message = [NSString stringWithFormat:@"Please make sure you entered a valid email address"];
                    break;
                    
                default:
                    title = @"Unexpected Email Error";
                    message = [NSString stringWithFormat:@"Please make sure you entered a valid email"];
                    break;
            }
            
            [self alertWithTitle:title message:message];
            
            return @{@"error": @"email"};
        }
    }
    
    return changes;
}
- (void)alertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:okAction];
    
    [self.navigationController presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 7 : 1;
}

- (void)dismiss:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            ProfilePictureCell *cell = [tableView dequeueReusableCellWithIdentifier:profilePictureReuseIdentifier forIndexPath:indexPath];
            
            if (newAvatar) {
                cell.profilePicture.imageView.image = newAvatar;
            }
            else {
                cell.profilePicture.user = self.user;
                
                if ([UIColor fromHex:self.user.attributes.details.color] != cell.profilePicture.imageView.backgroundColor) {
                    [UIView animateWithDuration:0.5f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        cell.profilePicture.imageView.backgroundColor = [UIColor fromHex:self.user.attributes.details.color];
                    } completion:nil];
                }
            }
            
            return cell;
        }
        else if (indexPath.row == 1 || indexPath.row == 2 || indexPath.row == 3 || indexPath.row == 4 || indexPath.row == 5) {
            InputCell *cell = [tableView dequeueReusableCellWithIdentifier:inputReuseIdentifier forIndexPath:indexPath];
            
            // Configure the cell...
            if (indexPath.row == 1) {
                cell.type = InputCellTypeTextField;
                cell.inputLabel.text = @"Name";
                cell.input.text = self.user.attributes.details.displayName;
                cell.input.placeholder = @"Name";
                cell.input.tag = DISPLAY_NAME_FIELD;
                cell.input.autocapitalizationType = UITextAutocapitalizationTypeWords;
                cell.input.autocorrectionType = UITextAutocorrectionTypeDefault;
                cell.input.keyboardType = UIKeyboardTypeDefault;
                cell.input.textContentType = UITextContentTypeName;
            }
            else if (indexPath.row == 2) {
                cell.type = InputCellTypeTextField;
                cell.inputLabel.text = @"Username";
                cell.input.text = [NSString stringWithFormat:@"@%@", self.user.attributes.details.identifier];
                cell.input.placeholder = @"@username";
                cell.input.tag = USERNAME_FIELD;
                cell.input.autocapitalizationType = UITextAutocapitalizationTypeNone;
                cell.input.autocorrectionType = UITextAutocorrectionTypeNo;
                cell.input.keyboardType = UIKeyboardTypeDefault;
                cell.input.textContentType = UITextContentTypeUsername;
            }
            else if (indexPath.row == 3) {
                cell.type = InputCellTypeTextView;
                cell.inputLabel.text = @"Bio";
                cell.textView.text = self.user.attributes.details.bio;
                cell.textView.placeholder = @"A little bit about me...";
                cell.textView.tag = BIO_FIELD;
                cell.textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
                cell.textView.autocorrectionType = UITextAutocorrectionTypeDefault;
                cell.textView.keyboardType = UIKeyboardTypeDefault;
                cell.charactersRemainingLabel.text = [NSString stringWithFormat:@"%i", (int)(MAX_USER_BIO_LENGTH - cell.textView.text.length)];
            }
            else if (indexPath.row == 4) {
                cell.type = InputCellTypeTextField;
                cell.inputLabel.text = @"Location";
                cell.input.text = self.user.attributes.details.location.value;
                cell.input.placeholder = @"Location";
                cell.input.tag = LOCATION_FIELD;
                cell.input.autocapitalizationType = UITextAutocapitalizationTypeWords;
                cell.input.autocorrectionType = UITextAutocorrectionTypeNo;
                cell.input.keyboardType = UIKeyboardTypeDefault;
                cell.input.textContentType = UITextContentTypeAddressCityAndState;
            }
            else if (indexPath.row == 5) {
                cell.type = InputCellTypeTextField;
                cell.inputLabel.text = @"Website";
                cell.input.text = self.user.attributes.details.website.value;
                cell.input.placeholder = @"Website";
                cell.input.tag = WEBSITE_FIELD;
                cell.input.autocapitalizationType = UITextAutocapitalizationTypeNone;
                cell.input.autocorrectionType = UITextAutocorrectionTypeNo;
                cell.input.keyboardType = UIKeyboardTypeURL;
                cell.input.textContentType = UITextContentTypeURL;
            }
            
            cell.charactersRemainingLabel.hidden = (cell.type != InputCellTypeTextView);
            
            cell.input.delegate = self;
            cell.textView.delegate = self;
            
            return cell;
        }
        else if (indexPath.row == 6) {
            ThemeSelectorCell *cell = [tableView dequeueReusableCellWithIdentifier:themeSelectorReuseIdentifier forIndexPath:indexPath];
            
            // Configure the cell...
            cell.delegate = self;
            
            return cell;
        }
    }
    else if (indexPath.section == 1) {
        InputCell *cell = [tableView dequeueReusableCellWithIdentifier:inputReuseIdentifier forIndexPath:indexPath];
        
        cell.inputLabel.text = @"Email";
        cell.input.text = self.user.attributes.details.email;
        cell.input.placeholder = @"Email";
        cell.input.tag = 201;
        cell.input.autocapitalizationType = UITextAutocapitalizationTypeNone;
        cell.input.autocorrectionType = UITextAutocorrectionTypeNo;
        cell.input.keyboardType = UIKeyboardTypeEmailAddress;
        
        cell.input.delegate = self;
        
        return cell;
    }
    
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankReuseIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newStr = [textField.text stringByReplacingCharactersInRange:range withString:string];

    if (textField.tag == EMAIL_FIELD) {
        // prevent spaces
        if ([newStr rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound) {
            return NO;
        }
        
        return newStr.length <= MAX_EMAIL_LENGTH ? YES : NO;
    }
    if (textField.tag == DISPLAY_NAME_FIELD) {
        return newStr.length <= MAX_USER_DISPLAY_NAME_LENGTH ? YES : NO;
    }
    if (textField.tag == USERNAME_FIELD) {
        if (newStr.length == 0) return NO;
        
        if ([newStr hasPrefix:@"@"]) {
            newStr = [newStr substringFromIndex:1];
        }
        
        // prevent spaces
        if ([newStr rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound) {
            return NO;
        }
        
        // prevent emojis
        if ([newStr emo_containsEmoji]) {
            return NO;
        }
        
        NSLog(@"newStr.length <= %d", MAX_USER_USERNAME_LENGTH);
        return newStr.length <= MAX_USER_USERNAME_LENGTH ? YES : NO;
    }
    if (textField.tag == LOCATION_FIELD) {
        return newStr.length <= MAX_USER_LOCATION_LENGTH ? YES : NO;
    }
    if (textField.tag == WEBSITE_FIELD) {
        return newStr.length <= MAX_USER_WEBSITE_LENGTH ? YES : NO;
    }
    
    return YES;
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *newStr = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    if (textView.tag == BIO_FIELD) {
        // bio
        BOOL shouldChange = newStr.length <= MAX_USER_BIO_LENGTH;
        
        return shouldChange ? YES : NO;
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    if (textView.tag == BIO_FIELD) {
        // bio
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
        
        InputCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
        cell.charactersRemainingLabel.text = [NSString stringWithFormat:@"%i", (int)(MAX_USER_BIO_LENGTH - textView.text.length)];
        
        userBio = cell.textView.text;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            return 148;
        }
        else if (indexPath.row == 1 || indexPath.row == 2 || indexPath.row == 4 || indexPath.row == 5) {
            return 48;
        }
        else if (indexPath.row == 3) {
            // profile bio -- auto resizing
            NSString *text = userBio ? userBio : self.user.attributes.details.bio;
            if (text.length == 0) text = @" ";
            
            CGSize boundingSize = CGSizeMake(self.view.frame.size.width - (INPUT_CELL_LABEL_LEFT_PADDING + INPUT_CELL_TEXTVIEW_INSETS.left + INPUT_CELL_TEXTVIEW_INSETS.right) - INPUT_CELL_LABEL_WIDTH, CGFLOAT_MAX);
            
            CGSize prfoileBioSize = [text boundingRectWithSize:boundingSize options:(NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: INPUT_CELL_FONT} context:nil].size;
            
            CGFloat cellHeight = INPUT_CELL_TEXTVIEW_INSETS.top + ceilf(prfoileBioSize.height) + 24 + INPUT_CELL_TEXTVIEW_INSETS.bottom;
            
            return cellHeight;
        }
        else if (indexPath.row == 6) {
            return 98;
        }
    }
    else if (indexPath.section == 1) {
        return 48;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return [BFHeaderView height];
    }
    
    return 0;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section != 1) return nil;
    
    BFHeaderView *header = [[BFHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [BFHeaderView height])];
    header.title = @"Private Information";
    header.separator = false;
    
    return header;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            // change profile photo
            [self showImagePicker];
        }
    }
}

- (void)showImagePicker {
    UIAlertController *imagePickerOptions = [UIAlertController alertControllerWithTitle:@"Set Profile Photo" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *takePhoto = [UIAlertAction actionWithTitle:@"Take Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self takePhotoForProfilePicture:nil];
    }];
    [imagePickerOptions addAction:takePhoto];
    
    UIAlertAction *chooseFromLibrary = [UIAlertAction actionWithTitle:@"Choose from Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self chooseFromLibraryForProfilePicture:nil];
    }];
    [imagePickerOptions addAction:chooseFromLibrary];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [imagePickerOptions addAction:cancel];
    
    [self presentViewController:imagePickerOptions animated:YES completion:nil];
}


- (void)takePhotoForProfilePicture:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:picker animated:YES completion:nil];
}
- (void)chooseFromLibraryForProfilePicture:(id)sender {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        switch (status) {
            case PHAuthorizationStatusAuthorized: {
                NSLog(@"PHAuthorizationStatusAuthorized");
                
                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                picker.delegate = self;
                picker.allowsEditing = NO;
                picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[Launcher topMostViewController] presentViewController:picker animated:YES completion:nil];
                });
                
                break;
            }
            case PHAuthorizationStatusDenied:
            case PHAuthorizationStatusNotDetermined:
            {
                NSLog(@"PHAuthorizationStatusDenied");
                // confirm action
                UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Allow Bonfire to access your phtoos" message:@"To allow Bonfire to access your photos, go to Settings > Privacy > Set Bonfire to ON" preferredStyle:UIAlertControllerStyleAlert];

                UIAlertAction *openSettingsAction = [UIAlertAction actionWithTitle:@"Open Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                }];
                [actionSheet addAction:openSettingsAction];
                
                UIAlertAction *closeAction = [UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:nil];
                [actionSheet addAction:closeAction];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[Launcher topMostViewController] presentViewController:actionSheet animated:YES completion:nil];
                });
                
                break;
            }
            case PHAuthorizationStatusRestricted: {
                NSLog(@"PHAuthorizationStatusRestricted");
                break;
            }
        }
    }];
}

// Crop image has been canceled.
- (void)imageCropViewControllerDidCancelCrop:(RSKImageCropViewController *)controller
{
    [controller.navigationController popViewControllerAnimated:YES];
}

// The original image has been cropped. Additionally provides a rotation angle used to produce image.
- (void)imageCropViewController:(RSKImageCropViewController *)controller
                   didCropImage:(UIImage *)croppedImage
                  usingCropRect:(CGRect)cropRect
                  rotationAngle:(CGFloat)rotationAngle
{
    ProfilePictureCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    cell.profilePicture.imageView.image = croppedImage;
    cell.profilePicture.imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    newAvatar = croppedImage;
    
    [controller.navigationController dismissViewControllerAnimated:YES completion:nil];
}

// The original image will be cropped.
- (void)imageCropViewController:(RSKImageCropViewController *)controller
                  willCropImage:(UIImage *)originalImage
{
    // Use when `applyMaskToCroppedImage` set to YES.
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    // output image
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    
    RSKImageCropViewController *imageCropVC = [[RSKImageCropViewController alloc] initWithImage:chosenImage];
    imageCropVC.delegate = self;
    imageCropVC.dataSource = self;
    imageCropVC.cropMode = RSKImageCropModeCustom;
    
    // move the cancel and choose buttons up
    UIEdgeInsets safeAreaInsets = [UIApplication sharedApplication].keyWindow.safeAreaInsets;
    imageCropVC.cancelButton.transform = CGAffineTransformMakeTranslation(0, -1 * safeAreaInsets.bottom);
    imageCropVC.chooseButton.transform = CGAffineTransformMakeTranslation(0, -1 * safeAreaInsets.bottom);
    
    [picker pushViewController:imageCropVC animated:YES];
}
- (CGRect)imageCropViewControllerCustomMaskRect:(RSKImageCropViewController *)controller
{
    CGSize aspectRatio = CGSizeMake(1, 1);
    
    CGFloat viewWidth = CGRectGetWidth(controller.view.frame);
    CGFloat viewHeight = CGRectGetHeight(controller.view.frame);
    
    CGFloat maskWidth;
    if ([controller isPortraitInterfaceOrientation]) {
        maskWidth = viewWidth;
    } else {
        maskWidth = viewHeight;
    }
    
    CGFloat maskHeight;
    do {
        maskHeight = maskWidth * aspectRatio.height / aspectRatio.width;
        maskWidth -= 1.0f;
    } while (maskHeight != floor(maskHeight));
    maskWidth += 1.0f;
    
    CGSize maskSize = CGSizeMake(maskWidth * .75f, maskHeight * .75);
    
    CGRect maskRect = CGRectMake((viewWidth - maskSize.width) * 0.5f,
                                 (viewHeight - maskSize.height) * 0.5f,
                                 maskSize.width,
                                 maskSize.height);
    
    return maskRect;
}
- (UIBezierPath *)imageCropViewControllerCustomMaskPath:(RSKImageCropViewController *)controller {
    CGFloat circleRadius = controller.maskRect.size.width * .5;
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:controller.maskRect
                                               byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                     cornerRadii:CGSizeMake(circleRadius, circleRadius)];
    return path;
}
// Returns a custom rect in which the image can be moved.
- (CGRect)imageCropViewControllerCustomMovementRect:(RSKImageCropViewController *)controller
{
    if (controller.rotationAngle == 0) {
        return controller.maskRect;
    } else {
        CGRect maskRect = controller.maskRect;
        CGFloat rotationAngle = controller.rotationAngle;
        
        CGRect movementRect = CGRectZero;
        
        movementRect.size.width = CGRectGetWidth(maskRect) * fabs(cos(rotationAngle)) + CGRectGetHeight(maskRect) * fabs(sin(rotationAngle));
        movementRect.size.height = CGRectGetHeight(maskRect) * fabs(cos(rotationAngle)) + CGRectGetWidth(maskRect) * fabs(sin(rotationAngle));
        
        movementRect.origin.x = CGRectGetMinX(maskRect) + (CGRectGetWidth(maskRect) - CGRectGetWidth(movementRect)) * 0.5f;
        movementRect.origin.y = CGRectGetMinY(maskRect) + (CGRectGetHeight(maskRect) - CGRectGetHeight(movementRect)) * 0.5f;
        
        movementRect.origin.x = floor(CGRectGetMinX(movementRect));
        movementRect.origin.y = floor(CGRectGetMinY(movementRect));
        movementRect = CGRectIntegral(movementRect);
        
        return movementRect;
    }
}

@end
