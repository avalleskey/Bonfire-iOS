//
//  InviteFriendTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 11/21/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "InviteFriendTableViewController.h"
#import "HAWebService.h"
#import "UIColor+Palette.h"
#import "ContactCell.h"
#import "InviteFriendHeaderCell.h"

#import <JGProgressHUD/JGProgressHUD.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <APAddressBook.h>
#import <APAddressBook/APContact.h>
#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>
#import <libPhoneNumber-iOS/NBPhoneNumber.h>

@interface InviteFriendTableViewController ()

@property (strong, nonatomic) HAWebService *manager;
@property (strong, nonatomic) APAddressBook *addressBook;
@property (strong, nonatomic) NSMutableArray <APContact *> *contacts;
@property (strong, nonatomic) NSMutableArray <APContact *> *searchResults;
@property (strong, nonatomic) NSMutableArray *featuredProfilePictures;
@property (strong, nonatomic) NBPhoneNumberUtil *phoneUtil;

@property (strong, nonatomic) NSMutableArray <APContact *> *selectedContacts;
@property (nonatomic) BOOL isSearching;

@end

@implementation InviteFriendTableViewController

static NSString * const headerCellIdentifier = @"HeaderCell";
static NSString * const contactCellIdentifier = @"ContactCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Invite Friends";
    
    self.manager = [HAWebService manager];
    [self setupNavigationBar];
    [self setupSearchBar];
    [self setupTableView];
    
    [self setupContacts];
}
- (void)viewWillAppear:(BOOL)animated {
    self.searchBar.frame = CGRectMake(0, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height, self.view.frame.size.width, 56);
}

- (void)setupSearchBar {
    self.searchBar = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    self.searchBar.frame = CGRectMake(0, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height, self.view.frame.size.width, 56);
    self.searchBar.backgroundColor = [UIColor colorWithWhite:1 alpha:0.7];
    self.searchBar.layer.masksToBounds = false;
    self.searchBar.userInteractionEnabled = true;
    [self.navigationController.view addSubview:self.searchBar];
    
    self.searchField = [[UITextField alloc] initWithFrame:CGRectMake(16, 10, self.searchBar.frame.size.width - 32, 36)];
    self.searchField.layer.cornerRadius = 12.f;
    self.searchField.layer.masksToBounds = true;
    self.searchField.textAlignment = NSTextAlignmentCenter;
    self.searchField.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightBold];
    self.searchField.delegate = self;
    self.searchField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.searchField.backgroundColor = [UIColor bonfireTextFieldBackgroundOnWhite];
    self.searchField.textColor = [UIColor colorWithWhite:0.07f alpha:1];
    self.searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search Contacts" attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0 alpha:0.25]}];
    UIView *leftPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16 + 26, 1)];
    self.searchField.leftView = leftPaddingView;
    self.searchField.leftViewMode = UITextFieldViewModeAlways;
    
    UIImageView *searchIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.searchField.frame.size.height / 2 - 8, 16, 16)];
    searchIcon.image = [[UIImage imageNamed:@"searchIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    searchIcon.tag = 3;
    searchIcon.tintColor = self.searchField.textColor;
    searchIcon.alpha = 0.25;
    searchIcon.userInteractionEnabled = false;
    [self.searchField addSubview:searchIcon];
    
    [self positionTextFieldSearchIcon];
    
    [self.searchField bk_whenTapped:^{
        [self.searchField becomeFirstResponder];
    }];
    
    [self.searchField bk_addEventHandler:^(id sender) {
        self.isSearching = self.searchField.text.length > 0;
        [self loadContacts];
    } forControlEvents:UIControlEventEditingChanged];
    
    [self.searchField bk_addEventHandler:^(id sender) {
        if (self.searchField.tag == 0) {
            self.searchField.tag = 1;
            
            UIColor *textFieldBackgroundColor = [UIColor bonfireTextFieldBackgroundOnWhite];
            
            CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
            [textFieldBackgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
            
            [UIView animateWithDuration:0.2f animations:^{
                self.searchField.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha*2];
            }];
        }
    } forControlEvents:UIControlEventTouchDown];
    
    [self.searchField bk_addEventHandler:^(id sender) {
        if (self.searchField.tag == 1) {
            self.searchField.tag = 0;
            
            UIColor *textFieldBackgroundColor = [UIColor bonfireTextFieldBackgroundOnWhite];
            
            [UIView animateWithDuration:0.2f animations:^{
                self.searchField.backgroundColor = textFieldBackgroundColor;
            }];
        }
    } forControlEvents:(UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [self.searchBar.contentView addSubview:self.searchField];
    
    UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, self.searchBar.frame.size.height - (1 / [UIScreen mainScreen].scale), self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    lineSeparator.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08f];
    [self.searchBar.contentView addSubview:lineSeparator];
}
- (void)positionTextFieldSearchIcon {
    NSString *textFieldText = self.searchField.text.length > 0 ? self.searchField.text : self.searchField.placeholder;
    
    CGRect rect = [textFieldText boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, self.searchField.frame.size.height) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.searchField.font} context:nil];
    CGFloat textWidth = roundf(rect.size.width);
    
    CGFloat xFinal = 16;
    CGFloat xCentered = self.searchField.frame.size.width / 2 - (textWidth / 2) - 10;
    if (!self.searchField.isFirstResponder && xCentered > xFinal) {
        xFinal = xCentered;
    }
    
    UIImageView *searchIcon = [self.searchField viewWithTag:3];
    CGRect searchIconFrame = searchIcon.frame;
    searchIconFrame.origin.x = xFinal;
    searchIcon.frame = searchIconFrame;
}

- (void)setupNavigationBar {
    // remove hairline
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor whiteColor],
       NSFontAttributeName:[UIFont systemFontOfSize:18.f weight:UIFontWeightBold]}];
    
    self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss:)];
    [self.cancelButton setTintColor:[UIColor whiteColor]];
    [self.cancelButton setTitleTextAttributes:@{
                                                NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium]
                                                } forState:UIControlStateNormal];
    [self.cancelButton setTitleTextAttributes:@{
                                                NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium]
                                                } forState:UIControlStateHighlighted];
    self.navigationItem.leftBarButtonItem = self.cancelButton;
    
    self.saveButton = [[UIBarButtonItem alloc] bk_initWithTitle:@"Send" style:UIBarButtonItemStyleDone handler:^(id sender) {
        [self sendInvites];
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
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.contentInset = UIEdgeInsetsMake(self.searchBar.frame.size.height, 0, 0, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    
    [self.tableView registerClass:[InviteFriendHeaderCell class] forCellReuseIdentifier:headerCellIdentifier];
    [self.tableView registerClass:[ContactCell class] forCellReuseIdentifier:contactCellIdentifier];
    
    self.featuredProfilePictures = [[NSMutableArray alloc] init];
    
    UIView *headerHack = [[UIView alloc] initWithFrame:CGRectMake(0, -1 * self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    headerHack.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
    [self.tableView addSubview:headerHack];
}

- (void)showError {
    NSLog(@"show error");
}

- (void)setupContacts {
    self.phoneUtil = [[NBPhoneNumberUtil alloc] init];
    
    self.selectedContacts = [[NSMutableArray alloc] init];
    
    self.addressBook = [[APAddressBook alloc] init];
    self.addressBook.fieldsMask = APContactFieldName | APContactFieldPhonesWithLabels | APContactFieldThumbnail;
    self.addressBook.sortDescriptors = @[
                                    [NSSortDescriptor sortDescriptorWithKey:@"name.compositeName" ascending:YES]
                                    ];
    
    switch([APAddressBook access])
    {
        case APAddressBookAccessUnknown: {
            // Application didn't request address book access yet
            
            [self.addressBook requestAccess:^(BOOL granted, NSError *error)
             {
                 // check `granted`
                 if (granted) {
                     [self loadContacts];
                 }
                 else {
                     // start observing
                     [self showError];
                     [self addAddressBookObserver];
                 }
             }];
            
            break;
        }
            
        case APAddressBookAccessGranted: {
            // Access granted
            [self loadContacts];
            
            break;
        }
            
        case APAddressBookAccessDenied: {
            // Access denied or restricted by privacy settings
            [self showError];
            [self addAddressBookObserver];
            
            break;
        }
    }
}
- (void)addAddressBookObserver {
    [self.addressBook startObserveChangesWithCallback:^
     {
         // reload contacts
         NSLog(@"good to go now!");
         [self loadContacts];
     }];
    // stop observing
    [self.addressBook stopObserveChanges];
}
- (void)loadContacts {
    if (self.contacts == nil) {
        self.addressBook.filterBlock = ^BOOL(APContact *contact)
        {
            return contact.phones.count > 0;
        };
        
        // don't forget to show some activity
        [self.addressBook loadContacts:^(NSArray <APContact *> *contacts, NSError *error)
         {
             // hide activity
             if (!error)
             {
                 // do something with contacts array
                 self.contacts = [[NSMutableArray alloc] initWithArray:contacts];
                 [self removeBadPhoneNumbers];
                 
                 [self.tableView reloadData];
                 
                 if ((self.searchField.text.length == 0 && !self.isSearching) && self.featuredProfilePictures.count == 0) {
                     for (int i = 0; i < self.contacts.count; i++) {
                         APContact *contact = self.contacts[i];
                         if (contact.thumbnail != nil) {
                             [self.featuredProfilePictures addObject:contact.thumbnail];
                         }
                         
                         if (self.featuredProfilePictures.count >= 6) {
                             break;
                         }
                     }
                 }
             }
             else
             {
                 // show error
                 [self showError];
                 [self.tableView reloadData];
             }
         }];
    }
    else {
        if (self.isSearching) {
            NSString *searchText = self.searchField.text;
            // return results using self.contacts
            NSArray *filteredArray = [self.contacts filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(APContact *contact, NSDictionary *bindings) {
                BOOL nameContains = [contact.name.compositeName containsString:searchText];
                BOOL phoneContains = [[self cleanPhoneNumber:contact.phones[0].number] containsString:[self cleanPhoneNumber:searchText]];
                
                return (nameContains || phoneContains);
            }]];
            self.searchResults = [[NSMutableArray alloc] initWithArray:filteredArray];
        }
        else {
            self.searchResults = self.contacts;
        }
        
        [self.tableView reloadData];
    }
}
- (NSString *)cleanPhoneNumber:(id)object {
    NSString *number = [NSString stringWithFormat:@"%@", object];
    number = [number stringByReplacingOccurrencesOfString:@"(" withString:@""];
    number = [number stringByReplacingOccurrencesOfString:@")" withString:@""];
    number = [number stringByReplacingOccurrencesOfString:@"+" withString:@""];
    number = [number stringByReplacingOccurrencesOfString:@" " withString:@""];
    number = [number stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    return number;
}
- (void)removeBadPhoneNumbers {
    NSMutableArray *discardeditems = [NSMutableArray array];
    for (APContact *contact in self.contacts) {
        NSError *anError = nil;
        NBPhoneNumber *myNumber = [self.phoneUtil parse:contact.phones[0].number
                                     defaultRegion:@"US" error:&anError];
        if (anError == nil) {
            if ([self.phoneUtil isValidNumber:myNumber]) {
                // INTERNATIONAL : +43 676 6077303
                contact.phones[0].number = [self.phoneUtil format:myNumber
                                                     numberFormat:NBEPhoneNumberFormatINTERNATIONAL
                                                            error:&anError];
            }
            else {
                NSLog(@"isValidPhoneNumber ? [%@]", [self.phoneUtil isValidNumber:myNumber] ? @"YES":@"NO");
                [discardeditems addObject:contact];
            }
        } else {
            NSLog(@"Error : %@", [anError localizedDescription]);
            [discardeditems addObject:contact];
        }
    }
    [self.contacts removeObjectsInArray:discardeditems];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // left aligned search bar
    self.searchField.textAlignment = NSTextAlignmentLeft;
    [self positionTextFieldSearchIcon];
    
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointMake(0, -1 * self.tableView.contentInset.top)];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    // left aligned search bar
    if (self.searchField.text.length == 0) {
        self.searchField.textAlignment = NSTextAlignmentCenter;
        [self positionTextFieldSearchIcon];
    }
    
    [self.tableView reloadData];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.searchField resignFirstResponder];
    
    return FALSE;
}

- (void)dismiss:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}
- (void)sendInvites {
    if (self.selectedContacts.count > 0) {
        JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
        HUD.textLabel.text = @"Sending Invites..";
        HUD.vibrancyEnabled = false;
        HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
        HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
        [HUD showInView:self.navigationController.view animated:YES];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            HUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
            HUD.textLabel.text = @"Invites Sent!";
            
            [HUD dismissAfterDelay:1.f];
            
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        });
    }
    else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Wait a second!" message:@"Choose at least one contact\nto send an invite to" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cool = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
        }];
        [alert addAction:cool];
        
        [self.navigationController presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0 ? (self.isSearching ? 0 : 206) : 56;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? (self.isSearching ? 0 : 1) : (self.isSearching ? self.searchResults.count : self.contacts.count);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        InviteFriendHeaderCell *cell = [tableView dequeueReusableCellWithIdentifier:headerCellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[InviteFriendHeaderCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:headerCellIdentifier];
        }
        
        UIImage *anonymousProfilePic;
        anonymousProfilePic = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        for (int i = 0; i < 7; i++) {
            UIImageView *imageView;
            if (i == 0) { imageView = cell.member2; }
            else if (i == 1) { imageView = cell.member3; }
            else if (i == 2) { imageView = cell.member4; }
            else if (i == 3) { imageView = cell.member5; }
            else if (i == 4) { imageView = cell.member6; }
            else { imageView = cell.member7; }
            
            if (self.featuredProfilePictures.count > i) {
                imageView.hidden = false;
                imageView.image = self.featuredProfilePictures[i];
            }
            else {
                imageView.image = anonymousProfilePic;
            }
        }
        
        return cell;
    }
    else  {
        ContactCell *cell = [tableView dequeueReusableCellWithIdentifier:contactCellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[ContactCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:contactCellIdentifier];
        }
        
        APContact *contact = self.isSearching ? self.searchResults[indexPath.row] : self.contacts[indexPath.row];
        
        cell.isSearching = self.isSearching;
        cell.textLabel.text = contact.name.compositeName.length > 0 ? contact.name.compositeName : [contact.phones[0] number];
        
        NSString *formattedPhoneNumber = contact.phones[0].number;
        NSString *phoneType = contact.phones[0].localizedLabel;
        
        NSMutableAttributedString *combinedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@   %@", formattedPhoneNumber, phoneType]];
        [combinedString addAttribute:NSForegroundColorAttributeName value:cell.detailTextLabel.textColor range:NSMakeRange(0, combinedString.length)];
        [combinedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12 weight:UIFontWeightMedium] range:NSMakeRange(0, formattedPhoneNumber.length)];
        [combinedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12 weight:UIFontWeightSemibold] range:NSMakeRange(formattedPhoneNumber.length + 3, phoneType.length)];
        
        cell.detailTextLabel.attributedText = combinedString;
        
        if (contact.thumbnail) {
            [cell.imageView setImage:contact.thumbnail];
        }
        else {
            [cell.imageView setImage:[[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            cell.imageView.tintColor = [UIColor bonfireGray];
        }
        
        if ([self isSelectedContact:contact.recordID]) {
            cell.textLabel.textColor = [UIColor bonfireBlue];
            cell.checkIcon.hidden = false;
        }
        else {
            cell.textLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
            cell.checkIcon.hidden = true;
        }
        
        if (indexPath.row == self.contacts.count) {
            // last row
            cell.lineSeparator.hidden = true;
        }
        else {
            cell.lineSeparator.hidden = false;
        }
        
        return cell;
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        
    }
    else if (indexPath.section == 1) {
        APContact *selectedContact = (self.isSearching ? self.searchResults[indexPath.row] : self.contacts[indexPath.row]);
        
        ContactCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        
        if ([self isSelectedContact:selectedContact.recordID]) {
            NSLog(@"is selected contact");
            // remove it
            [self removeSelectedContactWithRecordID:selectedContact.recordID];
            
            cell.textLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
            cell.checkIcon.hidden = true;
        }
        else {
            // add it
            [self.selectedContacts addObject:selectedContact];
            
            cell.textLabel.textColor = [UIColor bonfireBlue];
            cell.checkIcon.hidden = false;
        }
        
        self.title = self.selectedContacts.count > 0 ? [NSString stringWithFormat:@"Invite %lu Friend%@", (unsigned long)self.selectedContacts.count, self.selectedContacts.count == 1 ? @"" : @"s"] : @"Invite Friends";
    }
}
- (BOOL)isSelectedContact:(NSNumber *)recordID {
    for (APContact *contact in self.selectedContacts) {
        if ([contact.recordID isEqual:recordID]) return true;
    }
    
    return false;
}
- (void)removeSelectedContactWithRecordID:(NSNumber *)recordID {
    NSLog(@"self.selectedContacts: %@", self.selectedContacts);
    for (int i = 0; i < [self.selectedContacts count]; i++) {
        APContact *contact = self.selectedContacts[i];
        NSLog(@"record id: %@", contact.recordID);
        NSLog(@"record id: %@", recordID);
        
        if ([contact.recordID isEqual:recordID]) {
            [self.selectedContacts removeObjectAtIndex:i];
        }
    }
    NSLog(@"self.selectedContacts: %@", self.selectedContacts);
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return 64;
    }
    
    return 0;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section != 1) return nil;
    
    UIView *headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    [headerContainer addSubview:header];
    
    header.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];
    
    UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, header.frame.size.height - (1 / [UIScreen mainScreen].scale), self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    lineSeparator.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    [header addSubview:lineSeparator];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 28, self.view.frame.size.width - 32, 24)];
    if (section == 1) {
        if (self.isSearching) {
            if (self.contacts.count == 0) {
                title.text = @"No Results";
                title.textAlignment = NSTextAlignmentCenter;
                lineSeparator.hidden = true;
            }
            else {
                title.text = @"Results";
                title.textAlignment = NSTextAlignmentLeft;
                lineSeparator.hidden = false;
            }
        }
        else {
            title.text = @"Contacts";
            title.textAlignment = NSTextAlignmentLeft;
            lineSeparator.hidden = false;
        }
    }
    title.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold];
    title.textColor = [UIColor colorWithWhite:0.6f alpha:1];
    
    [header addSubview:title];
    
    return headerContainer;
}

@end
