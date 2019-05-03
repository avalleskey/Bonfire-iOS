//
//  EditRoomViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "EditRoomViewController.h"
#import "Session.h"

#import "ProfilePictureCell.h"
#import "ThemeSelectorCell.h"
#import "InputCell.h"
#import "ToggleCell.h"
#import "AppDelegate.h"
#import "HAWebService.h"
#import "UIColor+Palette.h"
#import "Launcher.h"
#import "NSString+Validation.h"
#import "EmojiUtilities.h"

#import <RSKImageCropper/RSKImageCropper.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <JGProgressHUD/JGProgressHUD.h>

@import Firebase;

#define ROOM_PRIVATE_DESCRIPTION @"When your Camp is private, only people you approve can see content posted inside your Camp. Your existing members won’t be affected."

@interface EditRoomViewController () <UITextFieldDelegate, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, RSKImageCropViewControllerDelegate, RSKImageCropViewControllerDataSource> {
    UIImage *newAvatar;
}

@end

@implementation EditRoomViewController

static NSString * const blankReuseIdentifier = @"BlankCell";

static NSString * const profilePictureReuseIdentifier = @"ProfilePictureCell";
static NSString * const themeSelectorReuseIdentifier = @"ThemeSelectorCell";
static NSString * const inputReuseIdentifier = @"InputCell";
static NSString * const toggleReuseIdentifier = @"ToggleCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Edit Camp";
    
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
    [self.tableView registerClass:[ToggleCell class] forCellReuseIdentifier:toggleReuseIdentifier];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Edit Room" screenClass:nil];
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
        
        void (^errorSaving)(void) = ^() {
            HUD.indicatorView = [[JGProgressHUDErrorIndicatorView alloc] init];
            HUD.textLabel.text = @"Error Saving";
            
            [HUD dismissAfterDelay:1.f];
        };
        
        void (^saveRoom)(NSString *uploadedImage) = ^(NSString *uploadedImage) {
            NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:changes];
            if ([params objectForKey:@"avatar"]) {
                if (uploadedImage) {
                    [params setObject:uploadedImage forKey:@"avatar"];
                }
                else {
                    [params removeObjectForKey:@"avatar"];
                }
            }
            
            NSString *url = [NSString stringWithFormat:@"rooms/%@", self.room.identifier];
            
            NSLog(@"222 url: %@", url);
            NSLog(@"222 params: %@", params);
            
            [[HAWebService authenticatedManager] PUT:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // success
                HUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
                HUD.textLabel.text = @"Success!";
                
                [HUD dismissAfterDelay:0.3f];
                
                // save user
                Room *room = [[Room alloc] initWithDictionary:responseObject[@"data"] error:nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"RoomUpdated" object:room];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMyRooms" object:nil];
                
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"error saving room");
                NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                NSLog(@"error response: %@", ErrorResponse);
                
                errorSaving();
            }];
        };
        
        if ([changes objectForKey:@"avatar"]) {
            // upload avatar
            BFMediaObject *avatarObject = [[BFMediaObject alloc] initWithImage:newAvatar];
            [BFAPI uploadImage:avatarObject copmletion:^(BOOL success, NSString * _Nonnull uploadedImageURL) {
                if (success && uploadedImageURL && uploadedImageURL.length > 0) {
                    saveRoom(uploadedImageURL);
                }
                else {
                    errorSaving();
                }
            }];
        }
        else {
            saveRoom(nil);
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
    
    InputCell *roomNameCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    NSString *roomName = roomNameCell.input.text;
    
    if (![roomName isEqualToString:self.room.attributes.details.title]) {
        BFValidationError error = [roomName validateBonfireRoomTitle];
        if (error == BFValidationErrorNone) {
            // good to go!
            [changes setObject:roomName forKey:@"title"];
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
            
            return false;
        }
    }
    
    InputCell *roomDisplayIdCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    NSString *camptag = [roomDisplayIdCell.input.text stringByReplacingOccurrencesOfString:@"#" withString:@""];
    
    if (![camptag isEqualToString:self.room.attributes.details.identifier]) {
        BFValidationError error = [camptag validateBonfireRoomTag];
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
                    message = [NSString stringWithFormat:@"Your #Camptag cannot be longer than %d characters", MAX_ROOM_TAG_LENGTH];
                    break;
                    
                default:
                    title = @"Requirements Not Met";
                    message = [NSString stringWithFormat:@"Please ensure that your Camptag is between 1 and %d characters long", MAX_ROOM_TAG_LENGTH];
                    break;
            }
            
            [self alertWithTitle:title message:message];
            
            return false;
        }
    }
    
    InputCell *descriptionCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    NSString *description = descriptionCell.textView.text;
    
    if (![description isEqualToString:self.room.attributes.details.theDescription]) {
        // good to go!
        [changes setObject:description forKey:@"description"];
    }
    
    ThemeSelectorCell *themeColorCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
    NSString *themeColor = themeColorCell.selectedColor;
    
    if (![[themeColor lowercaseString] isEqualToString:[self.room.attributes.details.color lowercaseString]]) {
        if (themeColor.length != 6) {
            [self alertWithTitle:@"Invalid Favorite Color" message:@"Well... this is awkward! Try closing out and trying again!"];
            
            return false;
        }
        else {
            // good to go!
            [changes setObject:themeColor forKey:@"color"];
        }
    }
    
    ToggleCell *visibilityCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    BOOL isPrivate = visibilityCell.toggle.on;
    
    if (isPrivate != self.room.attributes.status.visibility.isPrivate) {
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
    
    [self.navigationController presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 5 : 1;
}

- (void)dismiss:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            ProfilePictureCell *cell = [tableView dequeueReusableCellWithIdentifier:profilePictureReuseIdentifier forIndexPath:indexPath];
            
            // Configure the cell...
            cell.editPictureImageView.tintColor = self.themeColor;
            
            if (newAvatar) {
                cell.profilePicture.imageView.image = newAvatar;
            }
            
            return cell;
        }
        else if (indexPath.row == 1 || indexPath.row == 2 || indexPath.row == 3) {
            InputCell *cell = [tableView dequeueReusableCellWithIdentifier:inputReuseIdentifier forIndexPath:indexPath];
            
            // Configure the cell...
            if (indexPath.row == 1) {
                cell.type = InputCellTypeTextField;
                cell.inputLabel.text = @"Name";
                cell.input.text = self.room.attributes.details.title;
                cell.input.placeholder = @"Name";
                cell.input.tag = 1;
                cell.input.keyboardType = UIKeyboardTypeDefault;
            }
            else if (indexPath.row == 2) {
                cell.type = InputCellTypeTextField;
                cell.inputLabel.text = @"Camptag";
                cell.input.text = [NSString stringWithFormat:@"#%@", self.room.attributes.details.identifier];
                cell.input.placeholder = @"#Camptag";
                cell.input.tag = 2;
                cell.input.keyboardType = UIKeyboardTypeASCIICapable;
            }
            else if (indexPath.row == 3) {
                cell.type = InputCellTypeTextView;
                cell.inputLabel.text = @"Description";
                cell.textView.text = self.room.attributes.details.theDescription;
                cell.textView.placeholder = @"A little bit about the Camp...";
                cell.textView.tag = 3;
                cell.charactersRemainingLabel.text = [NSString stringWithFormat:@"%i", (int)(MAX_ROOM_DESC_LENGTH - cell.textView.text.length)];
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
            cell.selectedColor = self.room.attributes.details.color;
            cell.selectorLabel.text = @"Camp Color";
            
            return cell;
        }
    }
    else if (indexPath.section == 1) {
        ToggleCell *cell = [tableView dequeueReusableCellWithIdentifier:toggleReuseIdentifier forIndexPath:indexPath];
        
        // Configure the cell...
        cell.textLabel.text = @"Private Camp";
        cell.toggle.on = self.room.attributes.status.visibility.isPrivate;
        
        if (cell.toggle.tag == 0) {
            cell.toggle.tag = 1;
            [cell.toggle bk_addEventHandler:^(id sender) {
                if (!cell.toggle.isOn && self.room.attributes.status.visibility.isPrivate) {
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
    
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankReuseIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (textField.tag == 1) {
        return newStr.length <= MAX_ROOM_TITLE_LENGTH ? YES : NO;
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
        if ([EmojiUtilities containsEmoji:newStr]) {
            return NO;
        }
        
        return newStr.length <= MAX_ROOM_TAG_LENGTH ? YES : NO;
    }
    
    return YES;
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *newStr = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    if (textView.tag == 3) {
        return newStr.length <= MAX_ROOM_DESC_LENGTH ? YES : NO;
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    if (textView.tag == 3) {
        // description
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
        
        InputCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
        cell.charactersRemainingLabel.text = [NSString stringWithFormat:@"%i", (int)(MAX_ROOM_DESC_LENGTH - textView.text.length)];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            return 148;
        }
        else if (indexPath.row == 1 || indexPath.row == 2) {
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
                text = self.room.attributes.details.theDescription;
                if (text.length == 0) text = @" ";
            }
            
            CGSize boundingSize = CGSizeMake(self.view.frame.size.width - (INPUT_CELL_LABEL_LEFT_PADDING + INPUT_CELL_TEXTVIEW_INSETS.left + INPUT_CELL_TEXTVIEW_INSETS.right) - INPUT_CELL_LABEL_WIDTH, CGFLOAT_MAX);
            
            CGSize prfoileBioSize = [text boundingRectWithSize:boundingSize options:(NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: INPUT_CELL_FONT} context:nil].size;
            
            CGFloat cellHeight = INPUT_CELL_TEXTVIEW_INSETS.top + ceilf(prfoileBioSize.height) + 24 + INPUT_CELL_TEXTVIEW_INSETS.bottom;
            
            cell.textView.frame = CGRectMake(cell.textView.frame.origin.x, cell.textView.frame.origin.y, cell.textView.frame.size.width, cellHeight);
            cell.charactersRemainingLabel.frame = CGRectMake(cell.textView.frame.origin.x + INPUT_CELL_TEXTVIEW_INSETS.left, cell.frame.size.height - INPUT_CELL_TEXTVIEW_INSETS.bottom - 12, cell.textView.frame.size.width - (INPUT_CELL_TEXTVIEW_INSETS.left + INPUT_CELL_TEXTVIEW_INSETS.right), 12);
            
            return cellHeight;
        }
        else if (indexPath.row == 4) {
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
        return 32;
    }
    
    return 0;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 1) {
        CGSize labelSize = [ROOM_PRIVATE_DESCRIPTION boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 24, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.f weight:UIFontWeightRegular]} context:nil].size;
        
        return labelSize.height + (12 * 2); // 24 padding on top and bottom
    }
    
    return CGFLOAT_MIN;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 1) {
        UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 90)];
        
        UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, footer.frame.size.width - 24, 42)];
        descriptionLabel.text = ROOM_PRIVATE_DESCRIPTION;
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

- (void)updateBarColor:(id)newColor withAnimation:(int)animationType statusBarUpdateDelay:(CGFloat)statusBarUpdateDelay {
    if ([newColor isKindOfClass:[NSString class]]) {
        newColor = [UIColor fromHex:newColor];
    }
    self.themeColor = newColor;
    self.view.tintColor = self.themeColor;
    
    Room *modifiedRoom = [[Room alloc] initWithDictionary:[self.room toDictionary] error:nil];
    modifiedRoom.attributes.details.color = [UIColor toHex:newColor];
    
    ProfilePictureCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    cell.profilePicture.room = modifiedRoom;
    if (newAvatar) {
        cell.profilePicture.imageView.image = newAvatar;
    }
    cell.editPictureImageView.tintColor = newColor;
    
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
