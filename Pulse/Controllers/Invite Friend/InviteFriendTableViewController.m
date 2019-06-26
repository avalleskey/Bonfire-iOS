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
#import "ErrorView.h"
#import "InviteFriendHeaderCell.h"
#import "Launcher.h"
#import <HapticHelper/HapticHelper.h>

#import <JGProgressHUD/JGProgressHUD.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <APAddressBook.h>
#import <APAddressBook/APContact.h>
#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>
#import <libPhoneNumber-iOS/NBPhoneNumber.h>
@import Firebase;

@interface InviteFriendTableViewController ()

@property (strong, nonatomic) APAddressBook *addressBook;
@property (strong, nonatomic) NSMutableArray <APContact *> *contacts;
@property (strong, nonatomic) NSMutableArray <APContact *> *searchResults;
@property (strong, nonatomic) NSMutableArray *featuredProfilePictures;
@property (strong, nonatomic) NBPhoneNumberUtil *phoneUtil;

@property (strong, nonatomic) NSMutableArray <APContact *> *selectedContacts;
@property (nonatomic) BOOL isSearching;
@property (strong, nonatomic) ErrorView *errorView;

@end

@implementation InviteFriendTableViewController

static NSString * const headerCellIdentifier = @"HeaderCell";
static NSString * const contactCellIdentifier = @"ContactCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Invite Friends";
    
    if ([self.sender isKindOfClass:[Camp class]] && ((Camp *)self.sender).attributes.details.color != nil) {
        self.view.tintColor = [UIColor fromHex:((Camp *)self.sender).attributes.details.color];
    }
    else {
        self.view.tintColor = [UIColor bonfireBrand];
    }
    
    [self setupNavigationBar];
    [self setupSearchBar];
    [self setupTableView];
    [self setupErrorView];
    
    [self setupContacts];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Invite Friends" screenClass:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.searchBar.frame = CGRectMake(0, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height, self.view.frame.size.width, self.searchBar.frame.size.height);
}

- (void)setupErrorView {
    self.errorView = [[ErrorView alloc] initWithFrame:CGRectMake(12, 206 + 72, self.view.frame.size.width - 24, 100) title:@"Please allow Contacts" description:@"Open Settings, find Bonfire and allow Bonfire to view your Contacts" type:ErrorViewTypeContactsDenied];
    self.errorView.frame = CGRectMake(self.errorView.frame.origin.x, 206 + 72, self.errorView.frame.size.width, self.errorView.frame.size.height);
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
    
    [self.errorView bk_whenTapped:^{
        [self checkAccess];
    }];
}

- (void)setupSearchBar {
    self.searchBar = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    self.searchBar.frame = CGRectMake(0, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height, self.view.frame.size.width, 54);
    self.searchBar.backgroundColor = [UIColor colorWithWhite:1 alpha:0.7];
    self.searchBar.layer.masksToBounds = false;
    self.searchBar.userInteractionEnabled = true;
    [self.navigationController.view addSubview:self.searchBar];
    
    self.searchView = [[BFSearchView alloc] initWithFrame:CGRectMake(12, 10, self.view.frame.size.width - (12 * 2), 34)];
    self.searchView.textField.placeholder = @"Search Contacts";
    [self.searchView updateSearchText:@""];
    self.searchView.textField.delegate = self;
    self.searchView.textField.tintColor = self.view.tintColor;
    [self.searchBar.contentView addSubview:self.searchView];
    
    [self.searchView.textField bk_addEventHandler:^(id sender) {
        self.isSearching = self.searchView.textField.text.length > 0;
        [self loadContacts];
        [self.tableView setContentOffset:CGPointMake(0, -1 * self.tableView.contentInset.top)];
    } forControlEvents:UIControlEventEditingChanged];
    
    UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, self.searchBar.frame.size.height - (1 / [UIScreen mainScreen].scale), self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    lineSeparator.backgroundColor = [UIColor separatorColor];
    [self.searchBar.contentView addSubview:lineSeparator];
}

- (void)setupNavigationBar {
    // remove hairline
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    self.navigationController.navigationBar.barTintColor = self.view.tintColor;
    
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
    self.tableView.backgroundColor = [UIColor headerBackgroundColor];
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
    if (self.errorView.isHidden) {
        self.errorView.hidden = false;
    }
    [self.tableView reloadData];
}
- (void)hideError {
    self.errorView.hidden = true;
}

- (void)setupContacts {
    self.phoneUtil = [[NBPhoneNumberUtil alloc] init];
    
    self.selectedContacts = [[NSMutableArray alloc] init];
    
    self.addressBook = [[APAddressBook alloc] init];
    self.addressBook.fieldsMask = APContactFieldName | APContactFieldPhonesWithLabels | APContactFieldThumbnail;
    self.addressBook.sortDescriptors = @[
                                    [NSSortDescriptor sortDescriptorWithKey:@"name.compositeName" ascending:YES]
                                    ];
    
    [self checkAccess];
}
- (void)checkAccess {
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
         // good to go now - reload contacts
         [self checkAccess];
         
         if ([APAddressBook access]) {
             // stop observing
             [self.addressBook stopObserveChanges];
         }
    }];
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
                 
                 [self hideError];
                 [self.tableView reloadData];
                 
                 if ((self.searchView.textField.text.length == 0 && !self.isSearching) && self.featuredProfilePictures.count == 0) {
                     for (NSInteger i = 0; i < self.contacts.count; i++) {
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
            NSString *searchText = self.searchView.textField.text;
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
        
        [self hideError];
        
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
                // NSLog(@"isValidPhoneNumber ? [%@]", [self.phoneUtil isValidNumber:myNumber] ? @"YES":@"NO");
                [discardeditems addObject:contact];
            }
        } else {
            [discardeditems addObject:contact];
        }
    }
    [self.contacts removeObjectsInArray:discardeditems];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.searchView setPosition:BFSearchTextPositionLeft];
    } completion:nil];
}
- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.searchView.textField.userInteractionEnabled = false;
    
    [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.searchView setPosition:BFSearchTextPositionCenter];
    } completion:^(BOOL finished) {
        
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.searchView.textField resignFirstResponder];
    
    return FALSE;
}

- (void)dismiss:(id)sender {
    [FIRAnalytics logEventWithName:@"abort_invite_friends"
                        parameters:@{@"friends_selected": [NSNumber numberWithInteger:self.selectedContacts.count]}];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}
- (void)sendInvites {
    [FIRAnalytics logEventWithName:@"invite_friends_send"
                        parameters:@{@"friends_selected": [NSNumber numberWithInteger:self.selectedContacts.count]}];
    
    UIAlertController *comingSoon = [UIAlertController alertControllerWithTitle:@"Feature Coming Soon" message:@"Until then, invite your friends to the Beta using the invite link below." preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *copyShareLink = [UIAlertAction actionWithTitle:@"Copy Beta Invite Link" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [Launcher copyBetaInviteLink];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        });
    }];
    [comingSoon addAction:copyShareLink];
    
    UIAlertAction *close = [UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [comingSoon dismissViewControllerAnimated:YES completion:nil];
    }];
    [comingSoon addAction:close];
    
    [self.navigationController presentViewController:comingSoon animated:YES completion:nil];
    
    /* TODO
    if (self.selectedContacts.count > 0) {
        NSMutableArray *arrayOfPhoneNumbers = [[NSMutableArray alloc] init];
        for (NSInteger i = 0; i < [self.selectedContacts count]; i++) {
            [arrayOfPhoneNumbers addObject:[self cleanPhoneNumber:self.selectedContacts[i].phones[0].number]];
        }
        
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
    }*/
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
        
        cell.tintColor = self.view.tintColor;
        if ([self.sender isKindOfClass:[Camp class]]) {
            Camp *camp = (Camp *)self.sender;
            cell.member1.camp = camp;
        }
        
        for (NSInteger i = 0; i < 7; i++) {
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
                imageView.image = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
        }
        
        if ([self.sender isKindOfClass:[Camp class]] && ((Camp *)self.sender).attributes.details.title != nil) {
            cell.descriptionLabel.text = [NSString stringWithFormat:@"To join %@", ((Camp *)self.sender).attributes.details.title];
        }
        else {
            cell.descriptionLabel.text = @"Bonfire is more fun with friends!";
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
            cell.imageView.tintColor = [UIColor whiteColor];
            cell.imageView.backgroundColor = [UIColor bonfireGray];
        }
        
        if ([self isSelectedContact:contact.recordID]) {
            cell.textLabel.textColor = self.view.tintColor;
            cell.checkIcon.hidden = false;
        }
        else {
            cell.textLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
            cell.checkIcon.hidden = true;
        }
        cell.checkIcon.tintColor = self.view.tintColor;
        
        if (indexPath.row == (self.contacts.count - 1)) {
            // last row
            cell.lineSeparator.backgroundColor = [UIColor separatorColor];
            cell.lineSeparator.frame = CGRectMake(0, cell.frame.size.height - cell.lineSeparator.frame.size.height, cell.frame.size.width, cell.lineSeparator.frame.size.height);
        }
        else {
            cell.lineSeparator.backgroundColor = [UIColor separatorColor];
            cell.lineSeparator.frame = CGRectMake(cell.textLabel.frame.origin.x, cell.frame.size.height - cell.lineSeparator.frame.size.height, cell.frame.size.width - cell.textLabel.frame.origin.x, cell.lineSeparator.frame.size.height);
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
            // remove it
            [self removeSelectedContactWithRecordID:selectedContact.recordID];
            
            cell.textLabel.textColor = [UIColor bonfireBlack];
            cell.checkIcon.hidden = true;
        }
        else {
            // add it
            [self.selectedContacts addObject:selectedContact];
            
            cell.textLabel.textColor = self.view.tintColor;
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
    for (NSInteger i = 0; i < [self.selectedContacts count]; i++) {
        APContact *contact = self.selectedContacts[i];
        
        if ([contact.recordID isEqual:recordID]) {
            [self.selectedContacts removeObjectAtIndex:i];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return 56;
    }
    
    return 0;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section != 1 || !self.errorView.isHidden) return nil;
    
    UIView *headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 56)];
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 56)];
    [headerContainer addSubview:header];
    
    header.backgroundColor = [UIColor headerBackgroundColor];
    
    UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, header.frame.size.height - (1 / [UIScreen mainScreen].scale), self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    lineSeparator.backgroundColor = [UIColor separatorColor];
    [header addSubview:lineSeparator];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(12, 28, self.view.frame.size.width - 24, 24)];
    title.font = [UIFont systemFontOfSize:13.f weight:UIFontWeightSemibold];
    if (section == 1) {
        if (self.isSearching) {
            if (self.searchResults.count == 0) {
                title.text = @"No Results";
                title.textAlignment = NSTextAlignmentCenter;
                title.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium];
                lineSeparator.hidden = true;
            }
            else {
                title.text = @"Results";
                lineSeparator.hidden = false;
            }
        }
        else {
            title.text = @"CONTACTS";
            lineSeparator.hidden = false;
        }
    }
    title.textColor = [UIColor bonfireGray];
    
    [header addSubview:title];
    
    return headerContainer;
}

@end
