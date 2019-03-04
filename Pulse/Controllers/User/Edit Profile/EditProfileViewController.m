//
//  EditProfileViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "EditProfileViewController.h"
#import "Session.h"

#import "Launcher.h"
#import "ProfilePictureCell.h"
#import "ThemeSelectorCell.h"
#import "InputCell.h"
#import "ButtonCell.h"
#import "AppDelegate.h"
#import "HAWebService.h"
#import "UIColor+Palette.h"
#import "NSString+Validation.h"
#import "ErrorCodes.h"

#import <RSKImageCropper/RSKImageCropper.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <JGProgressHUD/JGProgressHUD.h>
#import <Tweaks/FBTweakInline.h>

@interface EditProfileViewController () <UITextFieldDelegate, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, RSKImageCropViewControllerDelegate, RSKImageCropViewControllerDataSource>

@property (strong, nonatomic) HAWebService *manager;

@end

@implementation EditProfileViewController

static NSString * const blankReuseIdentifier = @"BlankCell";

static NSString * const profilePictureReuseIdentifier = @"ProfilePictureCell";
static NSString * const themeSelectorReuseIdentifier = @"ThemeSelectorCell";
static NSString * const inputReuseIdentifier = @"InputCell";
static NSString * const buttonReuseIdentifier = @"ButtonCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Edit Profile";
    
    self.manager = [HAWebService manager];
    
    self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss:)];
    [self.cancelButton setTintColor:[UIColor whiteColor]];
    [self.cancelButton setTitleTextAttributes:@{
                                         NSFontAttributeName: [UIFont systemFontOfSize:17.f weight:UIFontWeightMedium]
                                         } forState:UIControlStateNormal];
    [self.cancelButton setTitleTextAttributes:@{
                                              NSFontAttributeName: [UIFont systemFontOfSize:17.f weight:UIFontWeightMedium]
                                              } forState:UIControlStateHighlighted];
    self.navigationItem.leftBarButtonItem = self.cancelButton;
    
    self.saveButton = [[UIBarButtonItem alloc] bk_initWithTitle:@"Save" style:UIBarButtonItemStyleDone handler:^(id sender) {
        [self saveChanges];
    }];
    [self.saveButton setTintColor:[UIColor whiteColor]];
    [self.saveButton setTitleTextAttributes:@{
                                           NSFontAttributeName: [UIFont systemFontOfSize:17.f weight:UIFontWeightBold]
                                           } forState:UIControlStateNormal];
    [self.saveButton setTitleTextAttributes:@{
                                              NSFontAttributeName: [UIFont systemFontOfSize:17.f weight:UIFontWeightBold]
                                              } forState:UIControlStateHighlighted];
    self.navigationItem.rightBarButtonItem = self.saveButton;
    
    
    self.tableView.backgroundColor = [UIColor headerBackgroundColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 0);
    self.tableView.separatorColor = [UIColor separatorColor];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 48, 0);
    
    self.themeColor = [Session sharedInstance].themeColor;
    
    // add background color view
    self.navigationBackgroundView = [[UIView alloc] init];
    self.navigationBackgroundView.backgroundColor = self.themeColor;
    self.navigationBackgroundView.layer.masksToBounds = true;
    // remove hairline
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    
    [self.tableView registerClass:[ProfilePictureCell class] forCellReuseIdentifier:profilePictureReuseIdentifier];
    [self.tableView registerClass:[ThemeSelectorCell class] forCellReuseIdentifier:themeSelectorReuseIdentifier];
    [self.tableView registerClass:[InputCell class] forCellReuseIdentifier:inputReuseIdentifier];
    [self.tableView registerClass:[ButtonCell class] forCellReuseIdentifier:buttonReuseIdentifier];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationBackgroundView.frame = CGRectMake(0, self.navigationController.navigationBar.frame.size.height - (self.navigationController.navigationBar.frame.size.height + 50), self.view.frame.size.width, self.navigationController.navigationBar.frame.size.height + 50);
    [self.navigationController.navigationBar insertSubview:self.navigationBackgroundView atIndex:1];
    
    [self updateBarColor:self.themeColor withAnimation:0 statusBarUpdateDelay:0];
}

- (void)saveChanges {
    // first verify requirements have been met
    [self.view endEditing:TRUE];
    
    NSDictionary *changes = [self changes];
    NSLog(@"changes: %@", changes);
    
    if (changes != false && changes.count > 0) {
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
                NSLog(@"response object: %@", responseObject);
                
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
                NSLog(@"error:");
                
                NSInteger code = 0;
                
                NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                NSData *errorData = [ErrorResponse dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *errorDict = [NSJSONSerialization JSONObjectWithData:errorData options:0 error:nil];
                if ([errorDict objectForKey:@"error"]) {
                    if (errorDict[@"error"][@"code"]) {
                        code = [errorDict[@"error"][@"code"] integerValue];
                    }
                }
                
                if (code == USER_EMAIL_TAKEN) {
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
        }];
    }
    else if (changes != false) {
        [self dismiss:nil];
    }
}
- (NSDictionary *)changes {
    NSMutableDictionary *changes = [[NSMutableDictionary alloc] init];
    
    InputCell *displayNameCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    NSString *displayName = displayNameCell.input.text;
    
    if (![displayName isEqualToString:[Session sharedInstance].currentUser.attributes.details.displayName]) {
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
            
            return false;
        }
    }
    
    InputCell *usernameCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    NSString *username = [usernameCell.input.text stringByReplacingOccurrencesOfString:@"@" withString:@""];
    
    if (![username isEqualToString:[Session sharedInstance].currentUser.attributes.details.identifier]) {
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
            
            return false;
        }
    }
    
    // bio
    InputCell *bioCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    NSString *bio = bioCell.textView.text;
    
    if (![bio isEqualToString:[Session sharedInstance].currentUser.attributes.details.bio]) {
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
            
            return false;
        }
    }
    
    // location
    InputCell *locationCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
    NSString *location = locationCell.input.text;
    
    NSString *currentLocation = [Session sharedInstance].currentUser.attributes.details.location.value;
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
            
            return false;
        }
    }
    
    // website
    InputCell *websiteCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:0]];
    NSString *website = websiteCell.input.text;
    
    NSString *currentWebsite = [Session sharedInstance].currentUser.attributes.details.website.value;
    if (!currentWebsite) currentWebsite = @"";
    
    if (![website isEqualToString:currentWebsite]) {
        BFValidationError error = [website validateBonfireWebsite];
        if (error == BFValidationErrorNone) {
            // good to go!
            if ([website rangeOfString:@"http://"].length == 0 && [website rangeOfString:@"https://"].length == 0) {
                // prepend http:// if needed
                website = [@"http://" stringByAppendingString:website];
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
            
            return false;
        }
    }
    
    ThemeSelectorCell *themeColorCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:6 inSection:0]];
    NSString *themeColor = themeColorCell.selectedColor;
    
    if (![[themeColor lowercaseString] isEqualToString:[[Session sharedInstance].currentUser.attributes.details.color lowercaseString]]) {
        if (themeColor.length != 6) {
            [self alertWithTitle:@"Couldn't Save Color" message:@"Please ensure you've selected a theme color from the list and try again."];
            
            return false;
        }
        else {
            // good to go!
            [changes setObject:themeColor forKey:@"color"];
        }
    }
    
    InputCell *emailCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    NSString *email = emailCell.input.text;
    
    if (![email isEqualToString:[Session sharedInstance].currentUser.attributes.email]) {
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
            
            return false;
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
            
            cell.changeProfilePictureLabel.textColor = self.themeColor;
            
            return cell;
        }
        else if (indexPath.row == 1 || indexPath.row == 2 || indexPath.row == 3 || indexPath.row == 4 || indexPath.row == 5) {
            InputCell *cell = [tableView dequeueReusableCellWithIdentifier:inputReuseIdentifier forIndexPath:indexPath];
            
            // Configure the cell...
            if (indexPath.row == 1) {
                cell.type = InputCellTypeTextField;
                cell.inputLabel.text = @"Name";
                cell.input.text = [Session sharedInstance].currentUser.attributes.details.displayName;
                cell.input.placeholder = @"Name";
                cell.input.tag = 203;
                cell.input.autocapitalizationType = UITextAutocapitalizationTypeWords;
                cell.input.autocorrectionType = UITextAutocorrectionTypeDefault;
                cell.input.keyboardType = UIKeyboardTypeDefault;
            }
            else if (indexPath.row == 2) {
                cell.type = InputCellTypeTextField;
                cell.inputLabel.text = @"Username";
                cell.input.text = [NSString stringWithFormat:@"@%@", [Session sharedInstance].currentUser.attributes.details.identifier];
                cell.input.placeholder = @"@username";
                cell.input.tag = 204;
                cell.input.autocapitalizationType = UITextAutocapitalizationTypeNone;
                cell.input.autocorrectionType = UITextAutocorrectionTypeNo;
                cell.input.keyboardType = UIKeyboardTypeDefault;
            }
            else if (indexPath.row == 3) {
                cell.type = InputCellTypeTextView;
                cell.inputLabel.text = @"Bio";
                cell.textView.text = [Session sharedInstance].currentUser.attributes.details.bio;
                cell.textView.placeholder = @"A little bit about me...";
                cell.textView.tag = 205;
                cell.textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
                cell.textView.autocorrectionType = UITextAutocorrectionTypeDefault;
                cell.textView.keyboardType = UIKeyboardTypeDefault;
                cell.charactersRemainingLabel.text = [NSString stringWithFormat:@"%i", (int)(MAX_USER_BIO_LENGTH - cell.textView.text.length)];
            }
            else if (indexPath.row == 4) {
                cell.type = InputCellTypeTextField;
                cell.inputLabel.text = @"Location";
                cell.input.text = [Session sharedInstance].currentUser.attributes.details.location.value;
                cell.input.placeholder = @"Location";
                cell.input.tag = 206;
                cell.input.autocapitalizationType = UITextAutocapitalizationTypeWords;
                cell.input.autocorrectionType = UITextAutocorrectionTypeNo;
                cell.input.keyboardType = UIKeyboardTypeDefault;
            }
            else if (indexPath.row == 5) {
                cell.type = InputCellTypeTextField;
                cell.inputLabel.text = @"Website";
                cell.input.text = [Session sharedInstance].currentUser.attributes.details.website.value;
                cell.input.placeholder = @"Website";
                cell.input.tag = 207;
                cell.input.autocapitalizationType = UITextAutocapitalizationTypeNone;
                cell.input.autocorrectionType = UITextAutocorrectionTypeNo;
                cell.input.keyboardType = UIKeyboardTypeURL;
            }
            
            cell.charactersRemainingLabel.hidden = (cell.type != InputCellTypeTextView);
            
            cell.input.delegate = self;
            cell.textView.delegate = self;
            
            return cell;
        }
        else if (indexPath.row == 6) {
            ThemeSelectorCell *cell = [tableView dequeueReusableCellWithIdentifier:themeSelectorReuseIdentifier forIndexPath:indexPath];
            
            // Configure the cell...
            
            return cell;
        }
    }
    else if (indexPath.section == 1) {
        InputCell *cell = [tableView dequeueReusableCellWithIdentifier:inputReuseIdentifier forIndexPath:indexPath];
        
        cell.inputLabel.text = @"Email";
        cell.input.text = [Session sharedInstance].currentUser.attributes.email;
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
    
    /*
     201 - email
     202 - password
     203 - display name
     204 - username
     205 - bio
     206 - location
     207 - website
     */
    
    if (textField.tag == 201) {
        return newStr.length <= MAX_EMAIL_LENGTH ? YES : NO;
    }
    if (textField.tag == 202) {
        return newStr.length <= MAX_PASSWORD_LENGTH ? YES : NO;
    }
    if (textField.tag == 203) {
        return newStr.length <= MAX_USER_DISPLAY_NAME_LENGTH ? YES : NO;
    }
    if (textField.tag == 204) {
        if (newStr.length == 0) return NO;
        
        if ([newStr hasPrefix:@"@"]) {
            newStr = [newStr substringFromIndex:1];
        }
        
        return newStr.length <= MAX_USER_USERNAME_LENGTH ? YES : NO;
    }
    if (textField.tag == 206) {
        return newStr.length <= MAX_USER_LOCATION_LENGTH ? YES : NO;
    }
    if (textField.tag == 207) {
        return newStr.length <= MAX_USER_WEBSITE_LENGTH ? YES : NO;
    }
    
    return YES;
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *newStr = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    if (textView.tag == 205) {
        // bio
        BOOL shouldChange = newStr.length <= MAX_USER_BIO_LENGTH;
        
        return shouldChange ? YES : NO;
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    if (textView.tag == 205) {
        // bio
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
        
        InputCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
        cell.charactersRemainingLabel.text = [NSString stringWithFormat:@"%i", (int)(MAX_USER_BIO_LENGTH - textView.text.length)];
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
            InputCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            
            NSString *text;
            if (cell) {
                text = cell.textView.text;
            }
            else {
                text = [Session sharedInstance].currentUser.attributes.details.bio;
                if (text.length == 0) text = @" ";
            }
            
            CGSize boundingSize = CGSizeMake(self.view.frame.size.width - (INPUT_CELL_LABEL_LEFT_PADDING + INPUT_CELL_TEXTVIEW_INSETS.left + INPUT_CELL_TEXTVIEW_INSETS.right) - INPUT_CELL_LABEL_WIDTH, CGFLOAT_MAX);
            
            CGSize prfoileBioSize = [text boundingRectWithSize:boundingSize options:(NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: INPUT_CELL_FONT} context:nil].size;
            
            CGFloat cellHeight = INPUT_CELL_TEXTVIEW_INSETS.top + ceilf(prfoileBioSize.height) + 24 + INPUT_CELL_TEXTVIEW_INSETS.bottom;
            
            cell.textView.frame = CGRectMake(cell.textView.frame.origin.x, cell.textView.frame.origin.y, cell.textView.frame.size.width, cellHeight);
            cell.charactersRemainingLabel.frame = CGRectMake(cell.textView.frame.origin.x + INPUT_CELL_TEXTVIEW_INSETS.left, cell.frame.size.height - INPUT_CELL_TEXTVIEW_INSETS.bottom - 12, cell.textView.frame.size.width - (INPUT_CELL_TEXTVIEW_INSETS.left + INPUT_CELL_TEXTVIEW_INSETS.right), 12);
            
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
        return 64;
    }
    
    return 0;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section != 1) return nil;
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 32, self.view.frame.size.width - 32, 21)];
    title.textAlignment = NSTextAlignmentLeft;
    title.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightBold];
    title.textColor = [UIColor colorWithWhite:0.47f alpha:1];
    title.text = @"Private Information";
    [header addSubview:title];
    
    return header;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (void)updateBarColor:(id)newColor withAnimation:(int)animationType statusBarUpdateDelay:(CGFloat)statusBarUpdateDelay {
    if ([newColor isKindOfClass:[NSString class]]) {
        newColor = [UIColor fromHex:newColor];
    }
    self.themeColor = newColor;
    self.view.tintColor = self.themeColor;
    
    ProfilePictureCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    cell.profilePicture.imageView.backgroundColor = newColor;
    cell.changeProfilePictureLabel.textColor = newColor;
    if ([UIColor useWhiteForegroundForColor:newColor]) {
        // dark enough
        cell.profilePicture.imageView.tintColor = [UIColor whiteColor];
    }
    else {
        cell.profilePicture.imageView.tintColor = [UIColor blackColor];
    }
    
    UIView *newColorView = [[UIView alloc] init];
    if (animationType == 1) {
        // fade
        newColorView.frame = CGRectMake(0, 0, self.navigationBackgroundView.frame.size.width, self.navigationBackgroundView.frame.size.height);;
        newColorView.layer.cornerRadius = 0;
        newColorView.alpha = 0;
    }
    else {
        // bubble burst
        newColorView.frame = CGRectMake(self.navigationBackgroundView.frame.size.width / 2 - 5, self.navigationBackgroundView.frame.size.height + 40, 10, 10);
        newColorView.layer.cornerRadius = 5.f;
    }
    newColorView.layer.masksToBounds = true;
    newColorView.backgroundColor = newColor;
    [self.navigationBackgroundView addSubview:newColorView];
    
    [UIView animateWithDuration:(animationType != 0 ? 0.25f : 0) delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        if (animationType == 1) {
            // fade
            newColorView.alpha = 1;
        }
        else {
            // bubble burst
            newColorView.transform = CGAffineTransformMakeScale(self.navigationBackgroundView.frame.size.width / 10, self.navigationBackgroundView.frame.size.width / 10);
        }
        
        if ([UIColor useWhiteForegroundForColor:newColor]) {
            [self.navigationController.navigationBar setTitleTextAttributes:
             @{NSForegroundColorAttributeName:[UIColor whiteColor],
               NSFontAttributeName:[UIFont systemFontOfSize:17.f weight:UIFontWeightBold]}];
            self.cancelButton.tintColor = [UIColor whiteColor];
            self.saveButton.tintColor = [UIColor whiteColor];
        }
        else {
            [self.navigationController.navigationBar setTitleTextAttributes:
             @{NSForegroundColorAttributeName:[UIColor colorWithWhite:0.07f alpha:1],
               NSFontAttributeName:[UIFont systemFontOfSize:17.f weight:UIFontWeightBold]}];
            
            self.cancelButton.tintColor = [UIColor colorWithWhite:0.07f alpha:1];
            self.saveButton.tintColor = [UIColor colorWithWhite:0.07f alpha:1];
        }
    } completion:^(BOOL finished) {
        [newColorView removeFromSuperview];
        self.navigationBackgroundView.backgroundColor = newColor;
    }];
    
    // status bar update
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(statusBarUpdateDelay?statusBarUpdateDelay:0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:(animationType != 0 ? 0.4f :0) delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            if ([UIColor useWhiteForegroundForColor:newColor]) {
                self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
            }
            else {
                self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
            }
            
            [self setNeedsStatusBarAppearanceUpdate];
        } completion:nil];
    });
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
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
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
    
    cell.changeProfilePictureLabel.text = @"Looking good!";
    
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
    CGFloat circleRadius;
//    BOOL circleProfilePictures = FBTweakValue(@"Post", @"General", @"Circle Profile Pictures", NO);
//    if (circleProfilePictures) {
//        circleRadius = controller.maskRect.size.width * .5;
//    }
//    else {
//        circleRadius = controller.maskRect.size.width * .25;
//    }
    circleRadius = controller.maskRect.size.width * .5;
    
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
