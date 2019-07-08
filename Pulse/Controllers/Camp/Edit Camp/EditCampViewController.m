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

#import <RSKImageCropper/RSKImageCropper.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <JGProgressHUD/JGProgressHUD.h>

@import Firebase;

#define CAMP_PRIVATE_DESCRIPTION @"When your Camp is private, only people you approve can see content posted inside your Camp. Your existing members won’t be affected."

@interface EditCampViewController () <UITextFieldDelegate, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, RSKImageCropViewControllerDelegate, RSKImageCropViewControllerDataSource> {
    UIImage *newAvatar;
    NSString *campDescription;
}

@property (nonatomic, strong) Camp *updatedCamp;

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
    
    // remove hairline
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    
    [self.tableView registerClass:[ProfilePictureCell class] forCellReuseIdentifier:profilePictureReuseIdentifier];
    [self.tableView registerClass:[ThemeSelectorCell class] forCellReuseIdentifier:themeSelectorReuseIdentifier];
    [self.tableView registerClass:[InputCell class] forCellReuseIdentifier:inputReuseIdentifier];
    [self.tableView registerClass:[ToggleCell class] forCellReuseIdentifier:toggleReuseIdentifier];
    [self.tableView registerClass:[ButtonCell class] forCellReuseIdentifier:buttonReuseIdentifier];
    
    campDescription = self.camp.attributes.details.theDescription;
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Edit Camp" screenClass:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.view.tag != 1) {
        self.view.tag = 1;
        
        self.updatedCamp = [[Camp alloc] initWithDictionary:[self.camp toDictionary] error:nil];
        
        [(SimpleNavigationController *)self.navigationController updateBarColor:self.themeColor animated:false];
        
        self.view.tintColor = self.themeColor;
        
        [self.tableView reloadData];
    }
}

- (void)themeSelectionDidChange:(NSString *)newHex {
    CampDetails *details = [[CampDetails alloc] initWithDictionary:[self.updatedCamp.attributes.details toDictionary] error:nil];
    details.color = newHex;
    self.updatedCamp.attributes.details = details;
    
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
            if ([params objectForKey:@"camp_avatar"]) {
                if (uploadedImage) {
                    [params setObject:uploadedImage forKey:@"camp_avatar"];
                }
                else {
                    [params removeObjectForKey:@"camp_avatar"];
                }
            }
            
            NSString *url = [NSString stringWithFormat:@"camps/%@", self.camp.identifier];
            
            [[HAWebService authenticatedManager] PUT:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // success
                HUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
                HUD.textLabel.text = @"Success!";
                
                [HUD dismissAfterDelay:0.3f];
                
                // save user
                Camp *camp = [[Camp alloc] initWithDictionary:responseObject[@"data"] error:nil];
                
                NSLog(@"camp:");
                NSLog(@"%@", camp);
                
                NSLog(@"responseObject::");
                NSLog(@"%@", responseObject);
                
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
        
        if ([changes objectForKey:@"camp_avatar"]) {
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
        [changes setObject:newAvatar forKey:@"camp_avatar"];
    }
    
    InputCell *campNameCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    NSString *campName = campNameCell.input.text;
    
    if (![campName isEqualToString:self.camp.attributes.details.title]) {
        BFValidationError error = [campName validateBonfireCampTitle];
        if (error == BFValidationErrorNone) {
            // good to go!
            [changes setObject:campName forKey:@"title"];
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
                    message = [NSString stringWithFormat:@"Please ensure that your Camp name is between 1 and 20 characters long"];
                    break;
            }
            
            [self alertWithTitle:title message:message];
            
            return @{@"error": @"title"};
        }
    }
    
    InputCell *campDisplayIdCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    NSString *camptag = [campDisplayIdCell.input.text stringByReplacingOccurrencesOfString:@"#" withString:@""];
    
    if (![camptag isEqualToString:self.camp.attributes.details.identifier]) {
        BFValidationError error = [camptag validateBonfireCampTag];
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
    
    InputCell *descriptionCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    NSString *description = descriptionCell.textView.text;
    
    if (![description isEqualToString:self.camp.attributes.details.theDescription]) {
        // good to go!
        [changes setObject:description forKey:@"description"];
    }
    
    NSString *themeColor = [UIColor toHex:self.themeColor];
    
    NSLog(@"self.camp.attributes.details.color:: %@", self.camp.attributes.details.color);
    NSLog(@"themecolor:: %@", themeColor);
    
    if (![[themeColor lowercaseString] isEqualToString:[self.camp.attributes.details.color lowercaseString]]) {
        if (themeColor.length != 6) {
            [self alertWithTitle:@"Invalid Camp Color" message:@"Well... this is awkward! Try closing out and trying again!"];
            
            return @{@"error": @"color"};
        }
        else {
            // good to go!
            [changes setObject:themeColor forKey:@"color"];
        }
    }
    
    ToggleCell *visibilityCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:0]];
    BOOL isPrivate = visibilityCell.toggle.on;
    
    if (isPrivate != self.camp.attributes.status.visibility.isPrivate) {
        // good to go!
        [changes setObject:[NSNumber numberWithBool:!isPrivate] forKey:@"visibility"];
    }
    
    return changes;
}
- (void)alertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Got it" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:okAction];
    
    [[Launcher topMostViewController] presentViewController:alert animated:YES completion:nil];
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
            
            if (newAvatar) {
                cell.profilePicture.imageView.image = newAvatar;
            }
            else {
                cell.profilePicture.camp = self.updatedCamp;
                if ([UIColor fromHex:self.updatedCamp.attributes.details.color] != cell.profilePicture.imageView.backgroundColor) {
                    [UIView animateWithDuration:0.5f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        cell.profilePicture.imageView.backgroundColor = [UIColor fromHex:self.updatedCamp.attributes.details.color];
                    } completion:nil];
                }
            }
            
            return cell;
        }
        else if (indexPath.row == 1 || indexPath.row == 2 || indexPath.row == 3) {
            InputCell *cell = [tableView dequeueReusableCellWithIdentifier:inputReuseIdentifier forIndexPath:indexPath];
            
            // Configure the cell...
            if (indexPath.row == 1) {
                cell.type = InputCellTypeTextField;
                cell.inputLabel.text = @"Name";
                cell.input.text = self.camp.attributes.details.title;
                cell.input.placeholder = @"Name";
                cell.input.tag = 1;
                cell.input.keyboardType = UIKeyboardTypeDefault;
            }
            else if (indexPath.row == 2) {
                cell.type = InputCellTypeTextField;
                cell.inputLabel.text = @"#Camptag";
                cell.input.text = [NSString stringWithFormat:@"#%@", self.camp.attributes.details.identifier];
                cell.input.placeholder = @"#Camptag";
                cell.input.tag = 2;
                cell.input.keyboardType = UIKeyboardTypeDefault;
            }
            else if (indexPath.row == 3) {
                cell.type = InputCellTypeTextView;
                cell.inputLabel.text = @"Description";
                cell.textView.text = self.camp.attributes.details.theDescription;
                cell.textView.placeholder = @"A little bit about the Camp...";
                cell.textView.tag = 3;
                cell.charactersRemainingLabel.text = [NSString stringWithFormat:@"%i", (int)(MAX_CAMP_DESC_SOFT_LENGTH - cell.textView.text.length)];
                cell.textView.keyboardType = UIKeyboardTypeDefault;
            }
            
            cell.charactersRemainingLabel.hidden = (cell.type != InputCellTypeTextView);
            
            cell.input.delegate = self;
            cell.textView.delegate = self;
            
            return cell;
        }
        else if (indexPath.row == 4) {
            ThemeSelectorCell *cell = [tableView dequeueReusableCellWithIdentifier:themeSelectorReuseIdentifier forIndexPath:indexPath];
            
            // Configure the cell...
            cell.delegate = self;
            
            cell.selectedColor = self.updatedCamp.attributes.details.color;
            cell.selectorLabel.text = @"Camp Color";
            
            return cell;
        }
        else if (indexPath.row == 5) {
            ToggleCell *cell = [tableView dequeueReusableCellWithIdentifier:toggleReuseIdentifier forIndexPath:indexPath];
            
            // Configure the cell...
            cell.textLabel.text = @"Private Camp";
            cell.toggle.on = self.camp.attributes.status.visibility.isPrivate;
            
            if (cell.toggle.tag == 0) {
                cell.toggle.tag = 1;
                [cell.toggle bk_addEventHandler:^(id sender) {
                    if (!cell.toggle.isOn && self.camp.attributes.status.visibility.isPrivate) {
                        NSLog(@"toggle is now on");
                        // confirm action
                        UIAlertController *confirmActionSheet = [UIAlertController alertControllerWithTitle:@"Change Privacy?" message:@"When your Camp is public, everyone can see content posted inside your Camp. Also, any pending member requests will be automatically approved once you save." preferredStyle:UIAlertControllerStyleAlert];
                        confirmActionSheet.view.tintColor = self.themeColor;
                        
                        UIAlertAction *cancelActionSheet = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            [cell.toggle setOn:true animated:YES];
                        }];
                        [confirmActionSheet addAction:cancelActionSheet];
                        
                        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            
                        }];
                        [confirmActionSheet addAction:confirmAction];
                        
                        [self.navigationController presentViewController:confirmActionSheet animated:YES completion:nil];
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
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *newStr = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    if (textView.tag == 3) {
        return [newStr validateBonfireCampDescription] != BFValidationErrorTooLong;
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    if (textView.tag == 3) {
        // description
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
        
        InputCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
        cell.charactersRemainingLabel.text = [NSString stringWithFormat:@"%i", (int)(MAX_CAMP_DESC_SOFT_LENGTH - textView.text.length)];
        
        campDescription = cell.textView.text;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            return 148;
        }
        else if (indexPath.row == 1 || indexPath.row == 2) {
            return 52;
        }
        else if (indexPath.row == 3) {
            // profile bio -- auto resizing
            NSString *text = campDescription ? campDescription : self.camp.attributes.details.theDescription;
            if (text.length == 0) text = @" ";
            
            CGSize boundingSize = CGSizeMake(self.view.frame.size.width - (INPUT_CELL_LABEL_LEFT_PADDING + INPUT_CELL_TEXTVIEW_INSETS.left + INPUT_CELL_TEXTVIEW_INSETS.right) - INPUT_CELL_LABEL_WIDTH, CGFLOAT_MAX);
            
            CGSize prfoileBioSize = [text boundingRectWithSize:boundingSize options:(NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: INPUT_CELL_FONT} context:nil].size;
            
            CGFloat cellHeight = INPUT_CELL_TEXTVIEW_INSETS.top + ceilf(prfoileBioSize.height) + 24 + INPUT_CELL_TEXTVIEW_INSETS.bottom;
            
            //cell.textView.frame = CGRectMake(cell.textView.frame.origin.x, cell.textView.frame.origin.y, cell.textView.frame.size.width, cellHeight);
            //cell.charactersRemainingLabel.frame = CGRectMake(cell.textView.frame.origin.x + INPUT_CELL_TEXTVIEW_INSETS.left, cell.frame.size.height - INPUT_CELL_TEXTVIEW_INSETS.bottom - 12, cell.textView.frame.size.width - (INPUT_CELL_TEXTVIEW_INSETS.left + INPUT_CELL_TEXTVIEW_INSETS.right), 12);
            
            return cellHeight;
        }
        else if (indexPath.row == 4) {
            return 98;
        }
        else if (indexPath.row == 5) {
            return 52;
        }
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            return 52;
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
        descriptionLabel.textColor = [UIColor bonfireGray];
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
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            // change profile photo
            [self showImagePicker];
        }
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            ManageIcebreakersViewController *mibvc = [[ManageIcebreakersViewController alloc] initWithStyle:UITableViewStyleGrouped];
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
    UIAlertController *imagePickerOptions = [UIAlertController alertControllerWithTitle:@"Set Camp Photo" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
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
    
    NSLog(@"profilepicture image view: %@", cell.profilePicture.imageView);
    NSLog(@"ugh: %@", croppedImage);
    
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

@end
