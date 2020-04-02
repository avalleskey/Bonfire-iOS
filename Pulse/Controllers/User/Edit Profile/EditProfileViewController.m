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
#import "BFAlertController.h"
#import "ChangePhoneNumberTableViewController.h"

#import "ErrorCodes.h"
#import <NSString+EMOEmoji.h>

#import <RSKImageCropper/RSKImageCropper.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "UIImage+WithColor.h"
#import <JGProgressHUD/JGProgressHUD.h>
#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>
#import "BFMiniNotificationManager.h"
@import Firebase;

@interface EditProfileViewController () <UITextFieldDelegate, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, RSKImageCropViewControllerDelegate, RSKImageCropViewControllerDataSource> {
    UIImage *newAvatar;
    UIImage *newCover;
    NSMutableDictionary *inputValues;
    
    CGFloat coverPhotoHeight;
}

@property (nonatomic) CGFloat currentKeyboardHeight;

@end

@implementation EditProfileViewController

static NSString * const blankReuseIdentifier = @"BlankCell";

static NSString * const profilePictureReuseIdentifier = @"ProfilePictureCell";
static NSString * const themeSelectorReuseIdentifier = @"ThemeSelectorCell";
static NSString * const inputReuseIdentifier = @"InputCell";
static NSString * const buttonReuseIdentifier = @"ButtonCell";

enum {
    DISPLAY_NAME_FIELD = 201,
    USERNAME_FIELD = 202,
    BIO_FIELD = 203,
    LOCATION_FIELD = 204,
    WEBSITE_FIELD = 205,
    EMAIL_FIELD = 206,
    PHONE_FIELD = 207
};

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.user = [Session sharedInstance].currentUser;
    inputValues = [NSMutableDictionary dictionary];
    
    self.title = @"Edit Profile";
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
            
    self.themeColor = [UIColor fromHex:[[Session sharedInstance] currentUser].attributes.color];
    self.view.tintColor = self.themeColor;
    
    [self setupTableView];
    [self setupCoverPhotoView];
    
    [self setupNavigation];
    
    [(SimpleNavigationController *)self.navigationController updateBarColor:self.themeColor animated:false];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
        
    // Google Analytics
    [FIRAnalytics setScreenName:@"Edit Profile" screenClass:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {        
        [(SimpleNavigationController *)self.navigationController updateBarColor:self.themeColor animated:false];
        
        self.view.tintColor = self.themeColor;
        
        [self.tableView reloadData];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)userUpdated:(NSNotification *)notification {
    User *user = notification.object;
    
    if (user && [user isCurrentIdentity] && [user isKindOfClass:[User class]]) {
        self.user = user;
        [self.tableView reloadData];
    }
}

- (void)setupNavigation {
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
}

- (void)setupTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.refreshControl = nil;
    self.tableView.layer.masksToBounds = false;
        
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    
    [self.tableView registerClass:[ProfilePictureCell class] forCellReuseIdentifier:profilePictureReuseIdentifier];
    [self.tableView registerClass:[ThemeSelectorCell class] forCellReuseIdentifier:themeSelectorReuseIdentifier];
    [self.tableView registerClass:[InputCell class] forCellReuseIdentifier:inputReuseIdentifier];
    [self.tableView registerClass:[ButtonCell class] forCellReuseIdentifier:buttonReuseIdentifier];
}

- (void)setupCoverPhotoView {
    self.coverPhotoView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 120)];
    self.coverPhotoView.backgroundColor = self.view.tintColor;
    self.coverPhotoView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverPhotoView.clipsToBounds = true;
    [self.coverPhotoView bk_whenTapped:^{
        // TODO: show options to replace cover photo view
    }];
    [self.view insertSubview:self.coverPhotoView belowSubview:self.tableView];
    
    [self updateCoverPhotoView];
}
- (void)updateCoverPhotoView {
    coverPhotoHeight = 16 + ceilf(128 * 0.65);
    if (self.user.attributes.media.cover.suggested.url.length > 0) {
        [self.coverPhotoView sd_setImageWithURL:[NSURL URLWithString:self.user.attributes.media.cover.suggested.url]];
    
        // add gradient overlay
        UIColor *topColor = [UIColor colorWithWhite:0 alpha:0.5];
        UIColor *bottomColor = [UIColor colorWithWhite:0 alpha:0];

        NSArray *gradientColors = [NSArray arrayWithObjects:(id)topColor.CGColor, (id)bottomColor.CGColor, nil];
        NSArray *gradientLocations = [NSArray arrayWithObjects:[NSNumber numberWithInt:0.0],[NSNumber numberWithInt:1.0], nil];

        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.colors = gradientColors;
        gradientLayer.locations = gradientLocations;
        gradientLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.tableView.contentInset.top);
        [self.coverPhotoView.layer addSublayer:gradientLayer];
    }
    else {
        self.coverPhotoView.image = nil;
        for (CALayer *layer in self.coverPhotoView.layer.sublayers) {
            if ([layer isKindOfClass:[CAGradientLayer class]]) {
                [layer removeFromSuperlayer];
            }
        }
    }
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 24, 0);
    
    // updat the scroll distance
    if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
        ((ComplexNavigationController *)self.navigationController).onScrollLowerBound = self.tableView.contentInset.top * .3;
    }
    else if ([self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
        ((SimpleNavigationController *)self.navigationController).onScrollLowerBound = self.tableView.contentInset.top * .3;
    }
    
    self.coverPhotoView.frame = CGRectMake(0, 0, self.view.frame.size.width, coverPhotoHeight);
}

- (void)themeSelectionDidChange:(NSString *)newHex {
    [inputValues setObject:newHex forKey:[NSIndexPath indexPathForRow:6 inSection:0]];
    self.themeColor = [UIColor fromHex:newHex];
    
    [(SimpleNavigationController *)self.navigationController updateBarColor:self.themeColor animated:true];
        
    ProfilePictureCell *profilePictureCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    BOOL emptyProfilePic = [profilePictureCell.profilePicture.imageView.image isEqual:[UIImage imageNamed:@"anonymous"]] || [profilePictureCell.profilePicture.imageView.image isEqual:[UIImage imageNamed:@"anonymous_black"]];
    
    [UIView animateWithDuration:0.4f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.view.tintColor = self.themeColor;
        self.coverPhotoView.backgroundColor = self.view.tintColor;
        
        profilePictureCell.profilePicture.imageView.backgroundColor = self.view.tintColor;
        
        if ([UIColor useWhiteForegroundForColor:self.view.tintColor]) {
            // dark enough
            if (emptyProfilePic) {
                profilePictureCell.profilePicture.imageView.image = [UIImage imageNamed:@"anonymous"];
            }
            self.cancelButton.tintColor = [UIColor whiteColor];
            self.saveButton.tintColor = [UIColor whiteColor];
        }
        else {
            if (emptyProfilePic) {
                profilePictureCell.profilePicture.imageView.image = [UIImage imageNamed:@"anonymous_black"];
            }
            self.cancelButton.tintColor = [UIColor blackColor];
            self.saveButton.tintColor = [UIColor blackColor];
        }
        
        profilePictureCell.editPictureImageView.tintColor = [UIColor fromHex:[UIColor toHex:self.view.tintColor] adjustForOptimalContrast:true];
        
        for (UITableViewCell *cell in [self.tableView visibleCells]) {
            if ([cell isKindOfClass:[InputCell class]]) {
                ((InputCell *)cell).textView.tintColor = self.view.tintColor;
                ((InputCell *)cell).input.tintColor = self.view.tintColor;
            }
        }
    } completion:nil];
}

- (void)saveChanges {
    // first verify requirements have been met
    [self.view endEditing:TRUE];
    
    NSDictionary *changes = [self changes];
    
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
            if ([params objectForKey:@"avatar"]) {
                if (uploadedImage) {
                    [params setObject:uploadedImage forKey:@"avatar"];
                }
                else {
                    [params removeObjectForKey:@"avatar"];
                }
            }
            
            NSLog(@"params: %@", params);
            
            [[HAWebService authenticatedManager] PUT:@"users/me" parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"response object: %@", responseObject);
                
                [HUD dismiss];
                
                // success
                BFMiniNotificationObject *notificationObject = [BFMiniNotificationObject notificationWithText:@"Saved!" action:nil];
                [[BFMiniNotificationManager manager] presentNotification:notificationObject completion:nil];
                
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
        
        if ([changes objectForKey:@"avatar"]) {
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
        [changes setObject:newAvatar forKey:@"avatar"];
    }
        
    for (NSIndexPath *indexPath in [inputValues allKeys]) {
        NSString *value = [inputValues objectForKey:indexPath];
        
        if (indexPath == [NSIndexPath indexPathForRow:1 inSection:0]) {
            if (![value isEqualToString:self.user.attributes.displayName]) {
                BFValidationError error = [value validateBonfireDisplayName];
                if (error == BFValidationErrorNone) {
                    // good to go!
                    if (value != nil) {
                        [changes setObject:value forKey:@"display_name"];
                    }
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
        }
        else if (indexPath == [NSIndexPath indexPathForRow:2 inSection:0]) {
            NSString *username = [value stringByReplacingOccurrencesOfString:@"@" withString:@""];
            if (![username isEqualToString:self.user.attributes.identifier]) {
                BFValidationError error = [username validateBonfireUsername];
                if (error == BFValidationErrorNone) {
                    // good to go!
                    if (username != nil) {
                        [changes setObject:username forKey:@"username"];
                    }
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
                            message = [NSString stringWithFormat:@"Your username can only contain alphanumeric characters (letters A-Z, numbers 0-9) with the exception of underscores and must include at least one non-number character"];
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
        }
        else if (indexPath == [NSIndexPath indexPathForRow:3 inSection:0]) {
            if (![value isEqualToString:self.user.attributes.bio]) {
                BFValidationError error = [value validateBonfireBio];
                if (error == BFValidationErrorNone) {
                    // good to go!
                    if (value != nil) {
                        [changes setObject:value forKey:@"bio"];
                    }
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
        }
        else if (indexPath == [NSIndexPath indexPathForRow:4 inSection:0]) {
            NSString *currentLocation = self.user.attributes.location.displayText;
            if (!currentLocation) currentLocation = @"";
            
            if (![value isEqualToString:currentLocation]) {
                BFValidationError error = [value validateBonfireLocation];
                if (error == BFValidationErrorNone) {
                    // good to go!
                    if (value != nil) {
                        [changes setObject:value forKey:@"location"];
                    }
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
        }
        else if (indexPath == [NSIndexPath indexPathForRow:5 inSection:0]) {
            NSString *currentWebsite = self.user.attributes.website.displayUrl;
            if (!currentWebsite) currentWebsite = @"";
            
            if (![value isEqualToString:currentWebsite]) {
                BFValidationError error = [value validateBonfireWebsite];
                if (error == BFValidationErrorNone || value.length == 0) {
                    if (value.length > 0) {
                        // if setting a new website, prepend http:// to the beginning if it doesn't exist already
                        if ([value rangeOfString:@"http://"].length == 0 && [value rangeOfString:@"https://"].length == 0) {
                            // prepend http:// if needed
                            value = [@"http://" stringByAppendingString:value];
                        }
                    }
                    
                    if (value != nil) {
                        [changes setObject:value forKey:@"website_url"];
                    }
                }
                else {
                    NSString *title = @"";
                    NSString *message = @"";
                    switch (error) {
                        case BFValidationErrorTooLong:
                            title = @"Website Too Long";
                            message = [NSString stringWithFormat:@"Your website URL cannot be longer than 30 characters"];
                            break;
                        case BFValidationErrorInvalidURL:
                            title = @"Invalid URL";
                            message = [NSString stringWithFormat:@"Please ensure that the website URL provided is valid"];
                            break;
                            
                        default:
                            title = @"Requirements Not Met";
                            message = [NSString stringWithFormat:@"Please ensure that your website URL is no longer than 30 characters and contains no unusual characters"];
                            break;
                    }
                    
                    [self alertWithTitle:title message:message];
                    
                    return @{@"error": @"website_url"};
                }
            }
        }
        else if (indexPath == [NSIndexPath indexPathForRow:6 inSection:0]) {
            // theme color
            if (![[value lowercaseString] isEqualToString:[self.user.attributes.color lowercaseString]]) {
                if (value.length != 6) {
                    [self alertWithTitle:@"Couldn't Save Color" message:@"Please ensure you've selected a theme color from the list and try again."];
                    
                    return @{@"error": @"color"};
                }
                else {
                    // good to go!
                    if (value != nil) {
                        [changes setObject:value forKey:@"color"];
                    }
                }
            }
        }
        else if (indexPath == [NSIndexPath indexPathForRow:0 inSection:1]) {
            if (![value isEqualToString:self.user.attributes.email]) {
                BFValidationError error = [value validateBonfireEmail];
                if (error == BFValidationErrorNone) {
                    // good to go!
                    if (value != nil) {
                        [changes setObject:value forKey:@"email"];
                    }
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
        }
        else if (indexPath == [NSIndexPath indexPathForRow:1 inSection:1]) {
            if (![value isEqualToString:self.user.attributes.phone]) {
                BFValidationError error = [value validateBonfirePhoneNumber];
                if (error == BFValidationErrorNone) {
                    // good to go!
                    if (value != nil) {
                        [changes setObject:value forKey:@"phone"];
                    }
                }
                else {                    
                    NSString *title = @"Invalid Phone Number";
                    NSString *message = [NSString stringWithFormat:@"Please make sure you entered a valid phone number"];
                    
                    [self alertWithTitle:title message:message];
                    
                    return @{@"error": @"phone"};
                }
            }
        }
    }
    
    return changes;
}
- (void)alertWithTitle:(NSString *)title message:(NSString *)message {
    BFAlertController *alert = [BFAlertController alertControllerWithTitle:title message:message preferredStyle:BFAlertControllerStyleAlert];
    
    BFAlertAction *okAction = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    
    [self.navigationController presentViewController:alert animated:true completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 7;
    else if (section == 1) {
        if (self.user.attributes.phone.length > 0) {
            return 2;
        }
        else {
            return 1;
        }
    }
    
    return 0;
}

- (void)dismiss:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            ProfilePictureCell *cell = [tableView dequeueReusableCellWithIdentifier:profilePictureReuseIdentifier forIndexPath:indexPath];
                        
            if (cell.profilePictureContainer.gestureRecognizers.count == 0) {
                [cell.profilePictureContainer bk_whenTapped:^{
                    [self showImagePicker];
                }];
                [cell.editPictureImageViewContainer bk_whenTapped:^{
                    [self showImagePicker];
                }];
            }
            
            if (newAvatar) {
                cell.profilePicture.imageView.image = newAvatar;
            }
            else {
                cell.profilePicture.user = self.user;
                       
                if (self.user.attributes.media.avatar.suggested.url.length == 0) {
                    if ([UIColor useWhiteForegroundForColor:self.view.tintColor]) {
                        // dark enough
                        cell.profilePicture.imageView.image = [UIImage imageNamed:@"anonymous"];
                    }
                    else {
                        cell.profilePicture.imageView.image = [UIImage imageNamed:@"anonymous_black"];
                    }
                }
                
                cell.editPictureImageView.tintColor = [UIColor fromHex:[UIColor toHex:self.view.tintColor] adjustForOptimalContrast:true];
            }
            
            return cell;
        }
        else if (indexPath.row == 1 || indexPath.row == 2 || indexPath.row == 3 || indexPath.row == 4 || indexPath.row == 5) {
            InputCell *cell = [tableView dequeueReusableCellWithIdentifier:inputReuseIdentifier forIndexPath:indexPath];
            
            cell.lineSeparator.frame = CGRectMake(12, cell.frame.size.height - cell.lineSeparator.frame.size.height, self.view.frame.size.width - 12, cell.lineSeparator.frame.size.height);
            cell.lineSeparator.hidden = false;
            // Configure the cell...
            if (indexPath.row == 1) {
                cell.type = InputCellTypeTextField;
                cell.inputLabel.text = @"Name";
                if ([inputValues objectForKey:indexPath]) {
                    cell.input.text = [inputValues objectForKey:indexPath];
                }
                else {
                    cell.input.text = self.user.attributes.displayName;
                }
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
                if ([inputValues objectForKey:indexPath]) {
                    cell.input.text = [inputValues objectForKey:indexPath];
                }
                else {
                    cell.input.text = [NSString stringWithFormat:@"@%@", self.user.attributes.identifier];
                }
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
                if ([inputValues objectForKey:indexPath]) {
                    cell.input.text = [inputValues objectForKey:indexPath];
                }
                else {
                    cell.textView.text = self.user.attributes.bio;
                }
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
                if ([inputValues objectForKey:indexPath]) {
                    cell.input.text = [inputValues objectForKey:indexPath];
                }
                else {
                    cell.input.text = self.user.attributes.location.displayText;
                }
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
                if ([inputValues objectForKey:indexPath]) {
                    cell.input.text = [inputValues objectForKey:indexPath];
                }
                else {
                    cell.input.text = self.user.attributes.website.displayUrl;
                }
                cell.input.placeholder = @"Website";
                cell.input.tag = WEBSITE_FIELD;
                cell.input.autocapitalizationType = UITextAutocapitalizationTypeNone;
                cell.input.autocorrectionType = UITextAutocorrectionTypeNo;
                cell.input.keyboardType = UIKeyboardTypeURL;
                cell.input.textContentType = UITextContentTypeURL;
            }
            
            cell.charactersRemainingLabel.hidden = (cell.type != InputCellTypeTextView);
            
            cell.input.delegate = self;
            [cell.input addTarget:self
                                  action:@selector(textFieldDidChange:)
                        forControlEvents:UIControlEventEditingChanged];
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
        if (indexPath.row == 0 && self.user.attributes.email.length > 0) {
            InputCell *cell = [tableView dequeueReusableCellWithIdentifier:inputReuseIdentifier forIndexPath:indexPath];
                        
            cell.inputLabel.text = @"Email";
            
            cell.input.placeholder = @"Email";
            if ([inputValues objectForKey:indexPath]) {
                cell.input.text = [inputValues objectForKey:indexPath];
            }
            else {
                cell.input.text = self.user.attributes.email;
            }
            
            cell.input.tag = EMAIL_FIELD;
            cell.input.autocapitalizationType = UITextAutocapitalizationTypeNone;
            cell.input.autocorrectionType = UITextAutocorrectionTypeNo;
            cell.input.keyboardType = UIKeyboardTypeEmailAddress;
            
            cell.lineSeparator.frame = CGRectMake(12, cell.frame.size.height - cell.lineSeparator.frame.size.height, self.view.frame.size.width - 12, cell.lineSeparator.frame.size.height);
            cell.lineSeparator.hidden = (self.user.attributes.phone.length == 0);
            
            cell.input.delegate = self;
            [cell.input addTarget:self
                          action:@selector(textFieldDidChange:)
                forControlEvents:UIControlEventEditingChanged];
            
            return cell;
        }
        else if (indexPath.row == 1 && self.user.attributes.phone.length > 0) {
            InputCell *cell = [tableView dequeueReusableCellWithIdentifier:inputReuseIdentifier forIndexPath:indexPath];
                        
            cell.inputLabel.text = @"Phone";

            cell.input.placeholder = @"Add Phone Number";
            cell.input.text = [self formatPhoneNumber:self.user.attributes.phone];
            
            cell.input.tag = PHONE_FIELD;
            cell.input.autocapitalizationType = UITextAutocapitalizationTypeNone;
            cell.input.autocorrectionType = UITextAutocorrectionTypeNo;
            cell.input.keyboardType = UIKeyboardTypePhonePad;
            cell.input.userInteractionEnabled = false;
            cell.input.alpha = 0.75;
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            cell.input.delegate = self;
            [cell.input addTarget:self
                          action:@selector(textFieldDidChange:)
                forControlEvents:UIControlEventEditingChanged];
            
            return cell;
        }
    }
    
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankReuseIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (NSString *)formatPhoneNumber:(NSString *)string {
    NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
    NSError *anError = nil;
    
    NBPhoneNumber *myNumber = [phoneUtil parse:string
                                 defaultRegion:@"US" error:&anError];
    
    NSString *formatted = [phoneUtil format:myNumber
         numberFormat:NBEPhoneNumberFormatNATIONAL
                error:&anError];
        
    if (anError) {
        return @"";
    }
    else {
        return [NSString stringWithFormat:@"+1 %@", formatted];
    }
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
    if (textField.tag == PHONE_FIELD) {
        return newStr.length <= MAX_PHONE_NUMBER_LENGTH ? YES : NO;
    }
    
    return YES;
}
- (void)textFieldDidChange:(UITextField *)sender {
    CGPoint point = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    
    [inputValues setObject:sender.text forKey:indexPath];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath  {
    if (indexPath.row == 1) {
        // set new phone number
        ChangePhoneNumberTableViewController *changePhoneTableVC = [[ChangePhoneNumberTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        SimpleNavigationController *simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:changePhoneTableVC];
        simpleNav.transitioningDelegate = [Launcher sharedInstance];
        simpleNav.modalPresentationStyle = UIModalPresentationFullScreen;
        [simpleNav setLeftAction:SNActionTypeBack];
        [Launcher push:simpleNav animated:true];
    }
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *newStr = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    if (textView.tag == BIO_FIELD) {
        // bio
        BOOL shouldChange = newStr.length <= MAX_USER_BIO_LENGTH;
        
        if (newStr.length > 1 && shouldChange) {
            unichar secondToLast = [newStr characterAtIndex:[newStr length] - 2];
            unichar last = [newStr characterAtIndex:[newStr length] - 1];
            if ([[NSCharacterSet newlineCharacterSet] characterIsMember:secondToLast] &&
                [[NSCharacterSet newlineCharacterSet] characterIsMember:last]) {
                return shouldChange = NO;
            }
        }
        
        return shouldChange;
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    CGPoint point = [textView convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    
    if (textView.tag == BIO_FIELD && indexPath != nil) {
        // bio
        wait(0.01, ^{
            [self.tableView beginUpdates];
            [self.tableView endUpdates];
        });
                
        InputCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if (cell) {
            cell.charactersRemainingLabel.text = [NSString stringWithFormat:@"%i", (int)(MAX_USER_BIO_LENGTH - textView.text.length)];
            [inputValues setObject:textView.text forKey:indexPath];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            return [ProfilePictureCell height];
        }
        else if (indexPath.row == 1 || indexPath.row == 2 || indexPath.row == 4 || indexPath.row == 5) {
            return [InputCell baseHeight];
        }
        else if (indexPath.row == 3) {
            // profile bio -- auto resizing
            NSString *text = [inputValues objectForKey:indexPath] ? [inputValues objectForKey:indexPath] : self.user.attributes.bio;
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
        if (indexPath.row == 0 && self.user.attributes.email.length > 0) {
            return [InputCell baseHeight];
        }
        else if (indexPath.row == 1 && self.user.attributes.phone.length > 0) {
            return [InputCell baseHeight];
        }
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return [BFHeaderView height];
    }
    
    return CGFLOAT_MIN;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        BFHeaderView *header = [[BFHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [BFHeaderView height])];
        header.title = @"Private Information";
        header.bottomLineSeparator.hidden = false;
        
        return header;
    }
    
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return HALF_PIXEL;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HALF_PIXEL)];
    separator.backgroundColor = [UIColor tableViewSeparatorColor];
    return separator;
}

- (void)showImagePicker {
    BFAlertController *imagePickerOptions = [BFAlertController alertControllerWithTitle:@"Set Profile Picture" message:nil preferredStyle:BFAlertControllerStyleActionSheet];
    
    BFAlertAction *takePhoto = [BFAlertAction actionWithTitle:@"Take Photo" style:BFAlertActionStyleDefault handler:^{
        [self takePhotoForProfilePicture:nil];
    }];
    [imagePickerOptions addAction:takePhoto];
    
    BFAlertAction *chooseFromLibrary = [BFAlertAction actionWithTitle:@"Choose from Library" style:BFAlertActionStyleDefault handler:^{
        [self chooseFromLibraryForProfilePicture:nil];
    }];
    [imagePickerOptions addAction:chooseFromLibrary];
    
    BFAlertAction *cancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
    [imagePickerOptions addAction:cancel];
    
    [self presentViewController:imagePickerOptions animated:true completion:nil];
}


- (void)takePhotoForProfilePicture:(id)sender {
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if (authStatus == AVAuthorizationStatusAuthorized) {
        [self openCamera];
    }
    else if (authStatus == AVAuthorizationStatusDenied ||
             authStatus == AVAuthorizationStatusRestricted) {
        // denied
        [self showNoCameraAccess];
    }
    else if (authStatus == AVAuthorizationStatusNotDetermined) {
        // not determined?!
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
            if (granted){
                NSLog(@"Granted access to %@", mediaType);
                [self openCamera];
            }
            else {
                NSLog(@"Not granted access to %@", mediaType);
                [self showNoCameraAccess];
            }
        }];
    }
}
- (void)openCamera {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[Launcher topMostViewController] presentViewController:picker animated:YES completion:nil];
    });
}
- (void)showNoCameraAccess {
    BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:@"Allow Bonfire to access your camera" message:@"To allow Bonfire to access your camera, go to Settings > Privacy > Camera > Set Bonfire to ON" preferredStyle:BFAlertControllerStyleAlert];

    BFAlertAction *openSettingsAction = [BFAlertAction actionWithTitle:@"Open Settings" style:BFAlertActionStyleDefault handler:^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }];
    [actionSheet addAction:openSettingsAction];

    BFAlertAction *closeAction = [BFAlertAction actionWithTitle:@"Close" style:BFAlertActionStyleCancel handler:nil];
    [actionSheet addAction:closeAction];
    [[Launcher topMostViewController] presentViewController:actionSheet animated:true completion:nil];
}

- (void)chooseFromLibraryForProfilePicture:(id)sender {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        switch (status) {
            case PHAuthorizationStatusAuthorized: {
                NSLog(@"PHAuthorizationStatusAuthorized");
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                    picker.delegate = self;
                    picker.allowsEditing = NO;
                    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                    [[Launcher topMostViewController] presentViewController:picker animated:YES completion:nil];
                });
                
                break;
            }
            case PHAuthorizationStatusDenied:
            case PHAuthorizationStatusNotDetermined:
            {
                NSLog(@"PHAuthorizationStatusDenied");
                // confirm action
                dispatch_async(dispatch_get_main_queue(), ^{
                    BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:@"Allow Bonfire to access your phtoos" message:@"To allow Bonfire to access your photos, go to Settings > Privacy > Camera > Set Bonfire to ON" preferredStyle:BFAlertControllerStyleAlert];

                    BFAlertAction *openSettingsAction = [BFAlertAction actionWithTitle:@"Open Settings" style:BFAlertActionStyleDefault handler:^{
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                    }];
                    [actionSheet addAction:openSettingsAction];
                
                    BFAlertAction *closeAction = [BFAlertAction actionWithTitle:@"Close" style:BFAlertActionStyleCancel handler:nil];
                    [actionSheet addAction:closeAction];
                    [[Launcher topMostViewController] presentViewController:actionSheet animated:true completion:nil];
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
    [controller.navigationController dismissViewControllerAnimated:YES completion:nil];
}

// The original image has been cropped. Additionally provides a rotation angle used to produce image.
- (void)imageCropViewController:(RSKImageCropViewController *)controller
                   didCropImage:(UIImage *)croppedImage
                  usingCropRect:(CGRect)cropRect
                  rotationAngle:(CGFloat)rotationAngle
{
    ProfilePictureCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    if (cell) {
        cell.profilePicture.imageView.image = croppedImage;
        cell.profilePicture.imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    
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
    imageCropVC.view.tag = 1;
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.tableView && [self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
        [(SimpleNavigationController *)self.navigationController childTableViewDidScroll:self.tableView];
        CGFloat adjustedCoverPhotoHeight = coverPhotoHeight + self.tableView.adjustedContentInset.top;
                
        self.coverPhotoView.frame = CGRectMake(0, 0, self.view.frame.size.width, adjustedCoverPhotoHeight + -(self.tableView.contentOffset.y + self.tableView.adjustedContentInset.top));
    }
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    _currentKeyboardHeight = keyboardFrameBeginRect.size.height;
    CGFloat bottomPadding = [[UIApplication sharedApplication] keyWindow].safeAreaInsets.bottom;
    
    CGFloat extraBottomPadding = 24;
    self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, _currentKeyboardHeight - bottomPadding + extraBottomPadding, self.tableView.contentInset.right);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.tableView.contentInset.bottom - 24, 0);
}

- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    CGFloat extraBottomPadding = 24;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, self.currentKeyboardHeight + extraBottomPadding, self.tableView.contentInset.right);
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.tableView.contentInset.bottom - extraBottomPadding, 0);
    } completion:nil];
}

@end
