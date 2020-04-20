//
//  EditCampViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "EditCampViewController.h"
#import "Session.h"

#import "ProfilePictureCell.h"
#import "InputCell.h"
#import "ToggleCell.h"
#import "ButtonCell.h"
#import "AppDelegate.h"
#import "HAWebService.h"
#import "UIColor+Palette.h"
#import "Launcher.h"
#import "NSString+Validation.h"
#import <NSString+EMOEmoji.h>
#import "BFHeaderView.h"
#import "ManageIcebreakersViewController.h"
#import "BFAlertController.h"
#import "BFMiniNotificationManager.h"

#import <RSKImageCropper/RSKImageCropper.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <JGProgressHUD/JGProgressHUD.h>

@import Firebase;

#define CAMP_PRIVATE_DESCRIPTION @"When your Camp is private, only people you approve can see content posted inside your Camp. Your existing members won’t be affected."

@interface EditCampViewController () <UITextFieldDelegate, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, RSKImageCropViewControllerDelegate, RSKImageCropViewControllerDataSource, UITableViewDelegate, UITableViewDataSource	> {
    UIImage *newAvatar;
    
    CGFloat coverPhotoHeight;
}

@property (nonatomic) CGFloat currentKeyboardHeight;

@property (nonatomic, strong) Camp *updatedCamp;
@property (nonatomic, strong) NSMutableDictionary *inputValues;

@end

@implementation EditCampViewController

static NSString * const blankReuseIdentifier = @"BlankCell";

static NSString * const profilePictureReuseIdentifier = @"ProfilePictureCell";
static NSString * const themeSelectorReuseIdentifier = @"ThemeSelectorCell";
static NSString * const inputReuseIdentifier = @"InputCell";
static NSString * const toggleReuseIdentifier = @"ToggleCell";
static NSString * const buttonReuseIdentifier = @"ButtonCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Edit Camp";
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
    
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
    
    [self setupTableView];
        
    // Google Analytics
    [FIRAnalytics setScreenName:@"Edit Camp" screenClass:nil];
    
    self.inputValues = [NSMutableDictionary dictionary];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {        
        self.updatedCamp = [[Camp alloc] initWithDictionary:[self.camp toDictionary] error:nil];
        
        [(SimpleNavigationController *)self.navigationController updateBarColor:self.themeColor animated:false];
        
        self.view.tintColor = self.themeColor;
        self.coverPhotoView.backgroundColor = self.themeColor;
        
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

- (void)themeSelectionDidChange:(NSString *)newHex {
    [self.inputValues setObject:newHex forKey:[NSIndexPath indexPathForRow:4 inSection:0]];
    
    self.updatedCamp.attributes.color = newHex;
    
    self.themeColor = [UIColor fromHex:newHex];
    [(SimpleNavigationController *)self.navigationController updateBarColor:self.themeColor animated:true];
    
    ProfilePictureCell *profilePictureCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    BOOL emptyProfilePic = [profilePictureCell.profilePicture.imageView.image isEqual:[UIImage imageNamed:@"anonymousGroup"]] || [profilePictureCell.profilePicture.imageView.image isEqual:[UIImage imageNamed:@"anonymousGroup_black"]];
    
    [UIView animateWithDuration:0.4f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.view.tintColor = self.themeColor;
        self.coverPhotoView.backgroundColor = self.view.tintColor;
        
    profilePictureCell.profilePicture.imageView.backgroundColor = self.view.tintColor;
        
        if ([UIColor useWhiteForegroundForColor:self.view.tintColor]) {
            // dark enough
            if (emptyProfilePic) {
                profilePictureCell.profilePicture.imageView.image = [UIImage imageNamed:@"anonymousGroup"];
            }
            self.cancelButton.tintColor = [UIColor whiteColor];
            self.saveButton.tintColor = [UIColor whiteColor];
        }
        else {
            if (emptyProfilePic) {
                profilePictureCell.profilePicture.imageView.image = [UIImage imageNamed:@"anonymousGroup_black"];
            }
            self.cancelButton.tintColor = [UIColor blackColor];
            self.saveButton.tintColor = [UIColor blackColor];
        }
        
        profilePictureCell.editPictureImageView.tintColor = [UIColor fromHex:[UIColor toHex:self.view.tintColor] adjustForOptimalContrast:true];
        profilePictureCell.editCoverPhotoImageView.tintColor = [UIColor fromHex:[UIColor toHex:self.view.tintColor] adjustForOptimalContrast:true];
        
        for (UITableViewCell *cell in [self.tableView visibleCells]) {
            if ([cell isKindOfClass:[InputCell class]]) {
                ((InputCell *)cell).textView.tintColor = self.view.tintColor;
                ((InputCell *)cell).input.tintColor = self.view.tintColor;
            }
        }
    } completion:nil];
}

- (void)setupTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.refreshControl = nil;
    
    [self setupCoverPhotoView];
    self.tableView.contentOffset = CGPointMake(0, -1 * self.tableView.contentInset.top);
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    
    [self.tableView registerClass:[ProfilePictureCell class] forCellReuseIdentifier:profilePictureReuseIdentifier];
    [self.tableView registerClass:[ThemeSelectorCell class] forCellReuseIdentifier:themeSelectorReuseIdentifier];
    [self.tableView registerClass:[InputCell class] forCellReuseIdentifier:inputReuseIdentifier];
    [self.tableView registerClass:[ToggleCell class] forCellReuseIdentifier:toggleReuseIdentifier];
    [self.tableView registerClass:[ButtonCell class] forCellReuseIdentifier:buttonReuseIdentifier];
}

- (void)setupCoverPhotoView {
    self.coverPhotoView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 120)];
    self.coverPhotoView.backgroundColor = self.themeColor;
    self.coverPhotoView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverPhotoView.clipsToBounds = true;
    [self.coverPhotoView bk_whenTapped:^{
        // TODO: show options to replace cover photo view
    }];
    [self.view insertSubview:self.coverPhotoView atIndex:0];
    
    [self updateCoverPhotoView];
}
- (void)updateCoverPhotoView {
    coverPhotoHeight = 16 + ceilf(128 * 0.65);
    if (self.camp.attributes.media.cover.suggested.url.length > 0) {
        [self.coverPhotoView sd_setImageWithURL:[NSURL URLWithString:self.camp.attributes.media.cover.suggested.url]];
    
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

- (void)saveChanges {
    // first verify requirements have been met
    [self.view endEditing:TRUE];
    
    NSDictionary *changes = [self changes];
    NSLog(@"changes: %@", changes);
    
    if ([changes objectForKey:@"error"])
        return;
    
    if (changes.count > 0) {
        // requirements have been met and there's more than one change to save
        JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
        HUD.textLabel.text = @"Saving...";
        HUD.vibrancyEnabled = false;
        HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
        HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
        [HUD showInView:self.navigationController.view animated:YES];
        
        void (^errorSaving)(NSError *) = ^(NSError *error) {
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
            else if (code == IDENTIFIER_TAKEN) {
                HUD.indicatorView = [[JGProgressHUDErrorIndicatorView alloc] init];
                HUD.textLabel.text = @"Camptag Already Taken";
            }
            else {
                HUD.indicatorView = [[JGProgressHUDErrorIndicatorView alloc] init];
                HUD.textLabel.text = @"Error Saving";
            }
            NSLog(@"%@", ErrorResponse);
            
            [HUD dismissAfterDelay:1.f];
        };
        
        void (^saveCamp)(NSString *uploadedImage) = ^(NSString *uploadedImage) {
            NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:changes];
            if ([params objectForKey:@"avatar"]) {
                if (uploadedImage) {
                    [params setObject:uploadedImage forKey:@"avatar"];
                }
                else {
                    [params removeObjectForKey:@"avatar"];
                }
            }
            
            NSString *url = [NSString stringWithFormat:@"camps/%@", self.camp.identifier];
            
            [[HAWebService authenticatedManager] PUT:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // success
                BFMiniNotificationObject *notificationObject = [BFMiniNotificationObject notificationWithText:@"Saved Camp!" action:nil];
                [[BFMiniNotificationManager manager] presentNotification:notificationObject completion:nil];
                
                // save user
                Camp *camp = [[Camp alloc] initWithDictionary:responseObject[@"data"] error:nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CampUpdated" object:camp];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMyCamps" object:nil];
                
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"error saving camp");
                NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                NSLog(@"error response: %@", ErrorResponse);
                
                errorSaving(error);
            }];
        };
        
        if ([changes objectForKey:@"avatar"]) {
            // upload avatar
            BFMediaObject *avatarObject = [[BFMediaObject alloc] initWithImage:newAvatar];
            [BFAPI uploadImage:avatarObject copmletion:^(BOOL success, NSString * _Nonnull uploadedImageURL) {
                if (success && uploadedImageURL && uploadedImageURL.length > 0) {
                    saveCamp(uploadedImageURL);
                }
                else {
                    errorSaving(nil);
                }
            }];
        }
        else {
            saveCamp(nil);
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
    
    for (NSIndexPath *indexPath in [self.inputValues allKeys]) {
        NSString *value = [self.inputValues objectForKey:indexPath];
                
        if (indexPath == [NSIndexPath indexPathForRow:1 inSection:0]) {
            // title
            if (![value isEqualToString:self.camp.attributes.title]) {
                BFValidationError error = [value validateBonfireCampTitle];
                if (error == BFValidationErrorNone) {
                    // good to go!
                    [changes setObject:value forKey:@"title"];
                }
                else {
                    NSString *title = @"";
                    NSString *message = @"";
                    switch (error) {
                        case BFValidationErrorTooShort:
                            title = @"Camp Name Too Short";
                            message = @"Your Camp name must at least 1 character long";
                            break;
                        case BFValidationErrorTooLong:
                            title = @"Camp Name Too Long";
                            message = [NSString stringWithFormat:@"Your Camp name cannot be longer than 20 characters"];
                            break;
                            
                        default:
                            title = @"Requirements Not Met";
                            message = [NSString stringWithFormat:@"Please ensure that your Camp name is between 1 and 20 characters long and only contains letters and numbers"];
                            break;
                    }
                    
                    [self alertWithTitle:title message:message];
                    
                    return @{@"error": @"title"};
                }
            }
        }
        else if (indexPath == [NSIndexPath indexPathForRow:2 inSection:0]) {
            // camptag
            NSString *camptag = [value stringByReplacingOccurrencesOfString:@"#" withString:@""];
            
            if (![camptag isEqualToString:self.camp.attributes.identifier]) {
                BFValidationError error = [camptag validateBonfireCampTag];
                NSLog(@"errror:: %u", error);
                if (error == BFValidationErrorNone) {
                    // good to go!
                    [changes setObject:[camptag stringByReplacingOccurrencesOfString:@"#" withString:@""] forKey:@"identifier"];
                }
                else {
                    NSString *title = @"";
                    NSString *message = @"";
                    switch (error) {
                        case BFValidationErrorTooShort:
                            title = @"#Camptag Too Short";
                            message = @"Your Camp name must at least 1 character long";
                            break;
                        case BFValidationErrorTooLong:
                            title = @"#Camptag Too Long";
                            message = [NSString stringWithFormat:@"Your #Camptag cannot be longer than %d characters", MAX_CAMP_TAG_LENGTH];
                            break;
                            
                        default:
                            title = @"Requirements Not Met";
                            message = [NSString stringWithFormat:@"Please ensure that your Camptag is between 1 and %d characters long", MAX_CAMP_TAG_LENGTH];
                            break;
                    }
                    
                    [self alertWithTitle:title message:message];
                    
                    return @{@"error": @"camptag"};
                }
            }
        }
        else if (indexPath == [NSIndexPath indexPathForRow:3 inSection:0]) {
            // description
            NSString *description = value;
            
            if (![description isEqualToString:self.camp.attributes.theDescription]) {
                // good to go!
                [changes setObject:description forKey:@"description"];
            }
        }
        else if (indexPath == [NSIndexPath indexPathForRow:4 inSection:0]) {
            // color
            if (![[value lowercaseString] isEqualToString:[self.camp.attributes.color lowercaseString]]) {
                if (value.length != 6) {
                    [self alertWithTitle:@"Invalid Camp Color" message:@"Well... this is awkward! Try closing out and trying again!"];
                    
                    return @{@"error": @"color"};
                }
                else {
                    // good to go!
                    [changes setObject:value forKey:@"color"];
                }
            }
        }
        else if (indexPath == [NSIndexPath indexPathForRow:5 inSection:0]) {
            // private BOOL
            BOOL isPrivate = [value boolValue];
            
            if (isPrivate != [self.camp.attributes isPrivate]) {
                // good to go!
                [changes setObject:[NSNumber numberWithBool:isPrivate] forKey:@"private"];
            }
        }
    }
    
    return changes;
}
- (void)alertWithTitle:(NSString *)title message:(NSString *)message {
    BFAlertController *alert = [BFAlertController alertControllerWithTitle:title message:message preferredStyle:BFAlertControllerStyleAlert];
    
    BFAlertAction *okAction = [BFAlertAction actionWithTitle:@"Got it" style:BFAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    
    [[Launcher topMostViewController] presentViewController:alert animated:true completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 6;
        case 1:
            return 1;
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
                cell.profilePicture.camp = self.updatedCamp;
                if ([UIColor fromHex:self.updatedCamp.attributes.color] != cell.profilePicture.imageView.backgroundColor) {
                    [UIView animateWithDuration:0.5f delay:0 options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState) animations:^{
                        cell.profilePicture.imageView.backgroundColor = [UIColor fromHex:self.updatedCamp.attributes.color];
                    } completion:nil];
                }
            }
            
            return cell;
        }
        else if (indexPath.row == 1 || (indexPath.row == 2 && self.camp.attributes.identifier.length > 0) || indexPath.row == 3) {
            InputCell *cell = [tableView dequeueReusableCellWithIdentifier:inputReuseIdentifier forIndexPath:indexPath];
            
            cell.lineSeparator.frame = CGRectMake(12, cell.frame.size.height - cell.lineSeparator.frame.size.height, self.view.frame.size.width - 12, cell.lineSeparator.frame.size.height);
            cell.lineSeparator.hidden = false;
            
            // Configure the cell...
            if (indexPath.row == 1) {
                cell.type = InputCellTypeTextField;
                cell.inputLabel.text = @"Name";
                if ([self.inputValues objectForKey:indexPath]) {
                    cell.input.text = [self.inputValues objectForKey:indexPath];
                }
                else {
                    cell.input.text = self.camp.attributes.title;
                }
                cell.input.placeholder = @"Name";
                cell.input.tag = 1;
                cell.input.keyboardType = UIKeyboardTypeDefault;
            }
            else if (indexPath.row == 2) {
                cell.type = InputCellTypeTextField;
                cell.inputLabel.text = @"#Camptag";
                if ([self.inputValues objectForKey:indexPath]) {
                    cell.input.text = [self.inputValues objectForKey:indexPath];
                }
                else {
                    cell.input.text = [NSString stringWithFormat:@"#%@", self.camp.attributes.identifier];
                }
                cell.input.placeholder = @"#Camptag";
                cell.input.tag = 2;
                cell.input.keyboardType = UIKeyboardTypeDefault;
            }
            else if (indexPath.row == 3) {
                cell.type = InputCellTypeTextView;
                cell.inputLabel.text = @"Description";
                if ([self.inputValues objectForKey:indexPath]) {
                    cell.textView.text = [self.inputValues objectForKey:indexPath];
                }
                else {
                    cell.textView.text = self.camp.attributes.theDescription;
                }
                cell.textView.placeholder = @"A little bit about the Camp...";
                cell.textView.tag = 3;
                cell.charactersRemainingLabel.text = [NSString stringWithFormat:@"%i", (int)(MAX_CAMP_DESC_SOFT_LENGTH - cell.textView.text.length)];
                cell.textView.keyboardType = UIKeyboardTypeDefault;
            }
            
            cell.charactersRemainingLabel.hidden = (cell.type != InputCellTypeTextView);
            
            cell.input.delegate = self;
            [cell.input addTarget:self
                        action:@selector(textFieldDidChange:)
                        forControlEvents:UIControlEventEditingChanged];
            cell.textView.delegate = self;
            
            return cell;
        }
        else if (indexPath.row == 4) {
            ThemeSelectorCell *cell = [tableView dequeueReusableCellWithIdentifier:themeSelectorReuseIdentifier forIndexPath:indexPath];
            
            // Configure the cell...
            cell.delegate = self;
            
            cell.selectedColor = self.updatedCamp.attributes.color;
            cell.selectorLabel.text = @"Camp Color";
            
            cell.bottomSeparator.frame = CGRectMake(12, cell.frame.size.height - cell.bottomSeparator.frame.size.height, self.view.frame.size.width - 12, cell.bottomSeparator.frame.size.height);
            cell.bottomSeparator.hidden = false;
                        
            return cell;
        }
        else if (indexPath.row == 5) {
            ToggleCell *cell = [tableView dequeueReusableCellWithIdentifier:toggleReuseIdentifier forIndexPath:indexPath];
            
            // Configure the cell...
            cell.textLabel.text = @"Private Camp";
            cell.textLabel.textColor = [UIColor bonfireSecondaryColor];
            cell.toggle.on = [self.camp isPrivate];
            
            cell.bottomSeparator.hidden = false;
            
            if (cell.toggle.tag == 0) {
                cell.toggle.tag = 1;
                [cell.toggle bk_addEventHandler:^(id sender) {
                    if (!cell.toggle.isOn && [self.camp isPrivate]) {
                        NSLog(@"toggle is now on");
                        // confirm action
                        BFAlertController *confirmActionSheet = [BFAlertController alertControllerWithTitle:@"Change Privacy?" message:@"When your Camp is public, everyone can see content posted inside your Camp. Also, any pending member requests will be automatically approved once you save." preferredStyle:BFAlertControllerStyleAlert];
                        confirmActionSheet.view.tintColor = self.themeColor;
                        
                        BFAlertAction *confirmAction = [BFAlertAction actionWithTitle:@"Confirm" style:BFAlertActionStyleDefault handler:^{
                            [self.inputValues setObject:(cell.toggle.isOn ? @"1" : @"0") forKey:indexPath];
                        }];
                        [confirmActionSheet addAction:confirmAction];
                        
                        BFAlertAction *cancelActionSheet = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:^{
                            [cell.toggle setOn:true animated:YES];
                            [self.inputValues setObject:(cell.toggle.isOn ? @"1" : @"0") forKey:indexPath];
                        }];
                        [confirmActionSheet addAction:cancelActionSheet];
                        
                        [self.navigationController presentViewController:confirmActionSheet animated:true completion:nil];
                    }
                    else {
                        [self.inputValues setObject:(cell.toggle.isOn ? @"1" : @"0") forKey:indexPath];
                    }
                } forControlEvents:UIControlEventValueChanged];
            }
            
            return cell;
        }
    }
    else if (indexPath.section == 1) {
        ButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:buttonReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[ButtonCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:buttonReuseIdentifier];
        }
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        // Configure the cell...
        cell.buttonLabel.text = @"Manage Icebreaker";
        cell.buttonLabel.textColor = cell.kButtonColorDefault;
        
        cell.topSeparator.hidden = false;
        cell.bottomSeparator.hidden = false;
        
        return cell;
    }
    
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankReuseIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (textField.tag == 1) {
        return [newStr validateBonfireCampTitle] != BFValidationErrorTooLong;
    }
    if (textField.tag == 2) {
        if (newStr.length == 0) return NO;
        
        if ([newStr hasPrefix:@"#"]) {
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
        
        return newStr.length <= MAX_CAMP_TAG_LENGTH ? YES : NO;
    }
    
    return YES;
}
- (void)textFieldDidChange:(UITextField *)sender {
    CGPoint point = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    
    NSLog(@"textFieldDidChange: %@", sender);
    NSLog(@"text:: %@", sender.text);
    NSLog(@"indexpath (section: %lu, row: %lu)", indexPath.section, indexPath.row);
    [self.inputValues setObject:sender.text forKey:indexPath];
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *newStr = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    if (textView.tag == 3) {
        BOOL valid = [newStr validateBonfireCampDescription] != BFValidationErrorTooLong;
        
        if (newStr.length > 1 && valid) {
            // prevent consecutive line breaks
            unichar secondToLast = [newStr characterAtIndex:[newStr length] - 2];
            unichar last = [newStr characterAtIndex:[newStr length] - 1];
            if ([[NSCharacterSet newlineCharacterSet] characterIsMember:secondToLast] &&
                [[NSCharacterSet newlineCharacterSet] characterIsMember:last]) {
                valid = NO;
            }
        }
        
        return valid;
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    CGPoint point = [textView convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    
    if (textView.tag == 3) {
        // description
        wait(0.01, ^{
            [self.tableView beginUpdates];
            [self.tableView endUpdates];
        });
        
        InputCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
        if (cell) {
            cell.charactersRemainingLabel.text = [NSString stringWithFormat:@"%i", (int)(MAX_CAMP_DESC_SOFT_LENGTH - textView.text.length)];
            [self.inputValues setObject:textView.text forKey:indexPath];
            
            NSLog(@"indexpath (section: %lu, row: %lu)", indexPath.section, indexPath.row);
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            return [ProfilePictureCell height];
        }
        else if (indexPath.row == 1) {
            return [InputCell baseHeight];
        }
        else if (indexPath.row == 2) {
            return self.camp.attributes.identifier.length > 0 ? [InputCell baseHeight] : 0;
        }
        else if (indexPath.row == 3) {
            // profile bio -- auto resizing
            NSString *text = [self.inputValues objectForKey:indexPath] ? [self.inputValues objectForKey:indexPath] : self.camp.attributes.theDescription;
            
            if (text.length == 0) text = @" ";
            
            CGSize boundingSize = CGSizeMake(self.view.frame.size.width - (INPUT_CELL_LABEL_LEFT_PADDING + INPUT_CELL_TEXTVIEW_INSETS.left + INPUT_CELL_TEXTVIEW_INSETS.right) - INPUT_CELL_LABEL_WIDTH, CGFLOAT_MAX);
            
            CGSize prfoileBioSize = [text boundingRectWithSize:boundingSize options:(NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: INPUT_CELL_FONT} context:nil].size;
            
            CGFloat cellHeight = INPUT_CELL_TEXTVIEW_INSETS.top + ceilf(prfoileBioSize.height) + 24 + INPUT_CELL_TEXTVIEW_INSETS.bottom;
            
            return cellHeight;
        }
        else if (indexPath.row == 4) {
            return 98;
        }
        else if (indexPath.row == 5) {
            return [InputCell baseHeight];
        }
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            // Even though it's a [ButtonCell class], inherit style of the input cell for cell height consistency
            return [InputCell baseHeight];
        }
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return 30;
    }
    
    return 0;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        CGSize labelSize = [CAMP_PRIVATE_DESCRIPTION boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 24, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.f weight:UIFontWeightRegular]} context:nil].size;
        
        return labelSize.height + (12 * 2); // 24 padding on top and bottom
    }
    
    return CGFLOAT_MIN;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 90)];
        
        UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, footer.frame.size.width - 24, 42)];
        descriptionLabel.text = CAMP_PRIVATE_DESCRIPTION;
        descriptionLabel.textColor = [UIColor bonfireSecondaryColor];
        descriptionLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightRegular];
        descriptionLabel.textAlignment = NSTextAlignmentLeft;
        descriptionLabel.numberOfLines = 0;
        descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        CGSize labelSize = [descriptionLabel.text boundingRectWithSize:CGSizeMake(descriptionLabel.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:descriptionLabel.font} context:nil].size;
        descriptionLabel.frame = CGRectMake(descriptionLabel.frame.origin.x, descriptionLabel.frame.origin.y, descriptionLabel.frame.size.width, labelSize.height);
        [footer addSubview:descriptionLabel];
        
        footer.frame = CGRectMake(0, 0, footer.frame.size.width, descriptionLabel.frame.size.height + (descriptionLabel.frame.origin.y*2));
        
        return footer;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            ManageIcebreakersViewController *mibvc = [[ManageIcebreakersViewController alloc] init];
            mibvc.view.tintColor = self.themeColor;
            mibvc.camp = self.camp;

            ComplexNavigationController *newLauncher = [[ComplexNavigationController alloc] initWithRootViewController:mibvc];
            newLauncher.searchView.textField.text = @"Icebreaker";
            [newLauncher.searchView hideSearchIcon:false];
            newLauncher.transitioningDelegate = [Launcher sharedInstance];
            
            [newLauncher updateBarColor:self.themeColor animated:false];
            
            [Launcher push:newLauncher animated:YES];
            
            [newLauncher updateNavigationBarItemsWithAnimation:NO];
        }
    }
}

- (void)showImagePicker {
    BFAlertController *imagePickerOptions = [BFAlertController alertControllerWithTitle:@"Set Camp Picture" message:nil preferredStyle:BFAlertControllerStyleActionSheet];
    
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
    [self takePhotoForProfilePicture:nil];
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
    
    NSLog(@"maskSize(%f, %f)", maskSize.width, maskSize.height);
    
    CGRect maskRect = CGRectMake((viewWidth - maskSize.width) * 0.5f,
                                 (viewHeight - maskSize.height) * 0.5f,
                                 maskSize.width,
                                 maskSize.height);
    
    return maskRect;
}
- (UIBezierPath *)imageCropViewControllerCustomMaskPath:(RSKImageCropViewController *)controller {
    CGFloat circleRadius = controller.maskRect.size.width * 0.5;
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
