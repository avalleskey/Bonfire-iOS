//
//  AddManagerTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 3/5/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "InviteToCampTableViewController.h"
#import "Session.h"
#import "User.h"
#import "HAWebService.h"
#import "UIColor+Palette.h"
#import "SearchResultCell.h"
#import "BFSearchView.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "NSDate+NVTimeAgo.h"
#import <JGProgressHUD/JGProgressHUD.h>
#import "SimpleNavigationController.h"
#import "UserListStream.h"
#import "BFHeaderView.h"
#import <Contacts/Contacts.h>
#import <UIView+WebCache.h>
#import "Launcher.h"
#import <FBSDKShareKit/FBSDKShareKit.h>
#import <NBPhoneNumberUtil.h>

@import Firebase;

@interface InviteToCampTableViewController ()

@property (nonatomic, strong) NSString *searchPhrase;

@property (nonatomic, strong) UserListStream *stream;

@property (nonatomic, strong) NBPhoneNumberUtil *phoneUtil;
@property (nonatomic, strong) NSArray <CNContact *> *contacts;
@property (nonatomic, strong) NSArray <CNContact *> *filteredContacts;

@property (nonatomic) BOOL loadingMoreUsers;

@property (nonatomic, strong) NSMutableArray *selectedMembers;

@property (nonatomic, strong) SimpleNavigationController *simpleNav;

@end

@implementation InviteToCampTableViewController

#define FRIEND_INFO_TEXT @"To protect the privacy of others, some people may not show up."

static NSString * const memberCellIdentifier = @"MemberCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor viewBackgroundColor];
    
    self.title = @"Invite Friends";
    self.view.tintColor = [UIColor fromHex:self.camp.attributes.color];
    self.navigationController.view.tintColor = self.view.tintColor;
    
    self.theme = self.view.tintColor;
    
    [self setupNavigationBar];
    [self setupTableView];
    [self setupErrorView];
    [self setSpinning:true];
    
    self.searchPhrase = @"";
    self.selectedMembers = [NSMutableArray new];
    
    [self getMembersWithCursorType:StreamPagingCursorTypeNone];
    [self getContacts];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Invite Friends" screenClass:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tableView.backgroundColor = [UIColor viewBackgroundColor];
}

- (void)setupNavigationBar {
    self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    [self.cancelButton setTintColor:[UIColor fromHex:[UIColor toHex:self.view.tintColor] adjustForOptimalContrast:true]];
    [self.cancelButton setTitleTextAttributes:@{
                                                NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium]
                                                } forState:UIControlStateNormal];
    [self.cancelButton setTitleTextAttributes:@{
                                                NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium]
                                                } forState:UIControlStateSelected];
    self.navigationItem.leftBarButtonItem = self.cancelButton;
    
    self.saveButton = [[UIBarButtonItem alloc] bk_initWithTitle:@"Invite" style:UIBarButtonItemStyleDone handler:^(id sender) {
        [self save];
    }];
    self.saveButton.enabled = false;
    [self.saveButton setTintColor:[UIColor fromHex:[UIColor toHex:self.view.tintColor] adjustForOptimalContrast:true]];
    [self.saveButton setTitleTextAttributes:@{
                                              NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightBold]
                                              } forState:UIControlStateDisabled];
    [self.saveButton setTitleTextAttributes:@{
                                              NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightBold]
                                              } forState:UIControlStateNormal];
    [self.saveButton setTitleTextAttributes:@{
                                              NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightBold]
                                              } forState:UIControlStateHighlighted];
    self.navigationItem.rightBarButtonItem = self.saveButton;
    
    self.simpleNav = (SimpleNavigationController *)self.navigationController;
}

- (void)setupTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor contentBackgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:memberCellIdentifier];
}

- (void)getMembersWithCursorType:(StreamPagingCursorType)cursorType {
    NSString *url = [NSString stringWithFormat:@"camps/%@/members", self.camp.identifier];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    NSString *filterQuery = @"";
    if (self.searchPhrase && self.searchPhrase.length > 0) {
        filterQuery = self.searchPhrase;
        [params setObject:filterQuery forKey:@"filter_query"];
    }
    
    NSString *nextCursor = [self.stream nextCursor];
    if (cursorType == StreamPagingCursorTypeNext && nextCursor.length > 0) {
        if ([self.stream hasLoadedCursor:nextCursor]) {
            return;
        }
        
        self.loadingMoreUsers = true;
        [self.stream addLoadedCursor:nextCursor];
        [params setObject:nextCursor forKey:@"next_cursor"];
    }
    else if (![self.searchView.textField isFirstResponder]) {
        self.loading = true;
    }
    
    // types of members to show
    NSString *filterTypes = @"suggested";
    [params setObject:filterTypes forKey:@"filter_types"];
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (![self.searchPhrase isEqualToString:filterQuery]) {
            return;
        }
        
        UserListStreamPage *page = [[UserListStreamPage alloc] initWithDictionary:responseObject error:nil];
        
        if (page.data.count > 0) {
            if ([params objectForKey:@"next_cursor"]) {
                self.loadingMoreUsers = false;
            }
            else {
                // clear the stream (we retrieved a full page of notifs and the old ones are out of date)
                self.stream = [[UserListStream alloc] init];
            }
            [self.stream appendPage:page];
        }
        else if (cursorType == StreamPagingCursorTypeNone) {
            self.stream = [[UserListStream alloc] init];
        }
        
        self.loading = false;
        
        if (self.stream.users.count == 0) {
            [self showNoMembersView];
        }
        else {
            [self hideNoMembersView];
        }
                
        [self.tableView reloadData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"AddManagerTableViewController / getMembers() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        if (nextCursor.length > 0) {
            [self.stream removeLoadedCursor:nextCursor];
        }
        self.loading = false;
        
        [self.tableView reloadData];
    }];
}
- (NSArray *)convertToUserObjects:(NSArray *)array {
    NSMutableArray *mutable = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < array.count; i++) {
        if (![array[i] objectForKey:@"type"] && [[array[i] objectForKey:@"type"] isEqualToString:@"user"]) continue;
        
        [mutable addObject:[[User alloc] initWithDictionary:array[i] error:nil]];
    }
    
    return [mutable copy];
}

- (void)getContacts {
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if( status == CNAuthorizationStatusDenied || status == CNAuthorizationStatusRestricted)
    {
        NSLog(@"access denied");
    }
    else
    {
        //Create repository objects contacts
        CNContactStore *contactStore = [[CNContactStore alloc] init];

        NSArray *keys = [[NSArray alloc]initWithObjects:CNContactIdentifierKey, CNContactEmailAddressesKey, CNContactImageDataKey, CNContactPhoneNumbersKey, CNContactGivenNameKey, CNContactFamilyNameKey, nil];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSArray <CNContact *> *contacts = [contactStore unifiedContactsMatchingPredicate:[CNContact predicateForContactsInContainerWithIdentifier:[contactStore defaultContainerIdentifier]] keysToFetch:keys error:nil];
            NSMutableArray *mutableContacts = [NSMutableArray new];
            for (CNContact *contact in contacts) {
                if (contact.phoneNumbers.count == 0) {
                    continue;
                }
                else if (!contact.givenName && !contact.familyName) {
                    continue;
                }
                
                [mutableContacts addObject:contact];
            }
            self.contacts = mutableContacts;
            
            self.filteredContacts = self.contacts;
            [self.tableView reloadData];
            
            NSLog(@"self.contacts: %@", self.contacts);
        });
    }
}



- (void)updateFilteredContacts {
    NSMutableArray *newArray = [NSMutableArray new];
    
    NSArray *matchingContacts_Name = [self.contacts filteredArrayUsingPredicate:[CNContact predicateForContactsMatchingName:self.searchPhrase]];
    
    NSArray *matchingContacts_Email = [self.contacts filteredArrayUsingPredicate:[CNContact predicateForContactsMatchingEmailAddress:self.searchPhrase]];
    
    CNPhoneNumber *phoneNumber = [[CNPhoneNumber alloc] initWithStringValue:self.searchPhrase];
    NSArray *matchingContacts_Phone = [self.contacts filteredArrayUsingPredicate:[CNContact predicateForContactsMatchingPhoneNumber:phoneNumber]];
    
    [newArray addObjectsFromArray:matchingContacts_Name];
    [newArray addObjectsFromArray:matchingContacts_Email];
    [newArray addObjectsFromArray:matchingContacts_Phone];
    
    self.contacts = newArray;
}

- (void)setupErrorView {
    BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeGeneral title:@"No Users Available" description:@"Those you follow and are followed back by will show up here" actionTitle:nil actionBlock:nil];
    
    self.errorView = [[BFVisualErrorView alloc] initWithVisualError:visualError];
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, (self.tableView.frame.size.height - self.tableView.safeAreaInsets.bottom) / 2);
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
}
- (void)hideNoMembersView {
    self.errorView.hidden = true;
}
- (void)showNoMembersView {
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, (self.tableView.frame.size.height - self.tableView.safeAreaInsets.bottom) / 2);
    self.errorView.hidden = false;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        // on bonfire
        return self.stream.users.count;
    }
    else if (section == 1) {
        // in your contacts
        return self.filteredContacts.count;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (![self.errorView isHidden]) return CGFLOAT_MIN;
    
    if (section == 0) {
        return 16 + [self shareButtonDiamter] + 16 + 36 + 16;
    }
    else if (section == 1) {
        return [BFHeaderView height];
    }
    
    return CGFLOAT_MIN;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (![self.errorView isHidden]) return nil;
    
    if (section == 0) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, (16 + [self shareButtonDiamter] + 16 + 36 + 16))];
        
        UIView *shareView = [self shareView];
        shareView.frame = CGRectMake(shareView.frame.origin.x, 16, shareView.frame.size.width, shareView.frame.size.height);
        [header addSubview:shareView];
        
        // search view
        self.searchView = [[BFSearchView alloc] initWithFrame:CGRectMake(12, shareView.frame.origin.y + shareView.frame.size.height + 16, self.view.frame.size.width - (12 * 2), 36)];
        self.searchView.textField.placeholder = @"Name, Phone, Email";
        [self.searchView updateSearchText:self.searchPhrase];
        self.searchView.textField.tintColor = self.view.tintColor;
        self.searchView.textField.delegate = self;
        [self.searchView.textField bk_addEventHandler:^(id sender) {
            self.searchPhrase = self.searchView.textField.text;
        } forControlEvents:UIControlEventEditingChanged];
        [header addSubview:self.searchView];
        
        return header;
    }
    else if (section == 1) {
        BFHeaderView *header = [[BFHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [BFHeaderView height])];
        
        header.backgroundColor = [UIColor clearColor];
        header.title = @"From Contacts";
        header.bottomLineSeparator.hidden = true;
        
        return header;
    }
    
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
//    if (section == 0) {
//        BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
//        BOOL showLoadingFooter = self.loading || ((self.loadingMoreUsers || hasAnotherPage) && ![self.stream hasLoadedCursor:self.stream.nextCursor]);
//
//        return showLoadingFooter ? 52 : 0;
//    }
    if (section == 0) {
        CGSize labelSize = [FRIEND_INFO_TEXT boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 24, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.f weight:UIFontWeightRegular]} context:nil].size;
        
        return labelSize.height + (12 * 2); // 24 padding on top and bottom
    }
    
    return CGFLOAT_MIN;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
//    if (section == 0) {
//        // last row
//        BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
//        BOOL showLoadingFooter = self.loading || ((self.loadingMoreUsers || hasAnotherPage) && ![self.stream hasLoadedCursor:self.stream.nextCursor]);
//
//        if (showLoadingFooter) {
//            UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 52)];
//
//            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
//            spinner.color = [UIColor bonfireSecondaryColor];
//            spinner.frame = CGRectMake(footer.frame.size.width / 2 - 10, footer.frame.size.height / 2 - 10, 20, 20);
//            [footer addSubview:spinner];
//
//            [spinner startAnimating];
//
//            if (!self.loadingMoreUsers && self.stream.pages.count > 0 && self.stream.nextCursor.length > 0) {
//                [self getMembersWithCursorType:StreamPagingCursorTypeNext];
//            }
//
//            return footer;
//        }
//    }
    if (section == 0) {
        UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 90)];
        
        UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, footer.frame.size.width - 24, 42)];
        descriptionLabel.text = FRIEND_INFO_TEXT;
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

- (NSArray *)shareButtons {
    NSMutableArray *buttons = [NSMutableArray new];
    
    BOOL hasInstagram = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"instagram-stories://"]];
    BOOL hasSnapchat = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"snapchat://"]];
    BOOL hasTwitter = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]];
    
    if (hasInstagram) {
        [buttons addObject:@{@"id": @"instagram", @"image": [UIImage imageNamed:@"share_instagram"], @"color": [UIColor fromHex:@"DC3075" adjustForOptimalContrast:false]}];
    }

    if (hasTwitter && (![self.camp.attributes isPrivate] || !hasSnapchat)) {
        [buttons addObject:@{@"id": @"twitter", @"image": [UIImage imageNamed:@"share_twitter"], @"color": [UIColor fromHex:@"1DA1F2" adjustForOptimalContrast:false]}];
    }
    
    if (hasSnapchat) {
        [buttons addObject:@{@"id": @"snapchat", @"image": [UIImage imageNamed:@"share_snapchat"], @"color": [UIColor fromHex:@"fffc00" adjustForOptimalContrast:false]}];
    }
    
    if ([self.camp.attributes isPrivate] || !hasTwitter || !hasSnapchat) {
        [buttons addObject:@{@"id": @"imessage", @"image": [UIImage imageNamed:@"share_imessage"], @"color": [UIColor fromHex:@"36DB52" adjustForOptimalContrast:false]}];
    }
    
    if (buttons.count < 4) {
        // add facebook
        [buttons addObject:@{@"id": @"facebook", @"image": [UIImage imageNamed:@"share_facebook"], @"color": [UIColor fromHex:@"3B5998" adjustForOptimalContrast:false]}];
    }
    
    [buttons addObject:@{@"id": @"more", @"image": [[UIImage imageNamed:@"share_more"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate], @"color": [UIColor tableViewSeparatorColor]}];
    
    return buttons;
}
- (CGFloat)shareButtonPadding {
    return 12;
}
- (CGFloat)shareButtonDiamter {
    CGFloat buttonPadding = [self shareButtonPadding];
    
    NSArray *buttons = [self shareButtons];
    return MIN(48, (self.view.frame.size.width - (24 * 2) - ((buttons.count - 1) * buttonPadding)) / buttons.count);
}
- (UIView *)shareView {
    UIView *shareBlock = [[UIView alloc] initWithFrame:CGRectMake(24, 0, self.view.frame.size.width - 24 * 2, 80)];
    NSArray *buttons = [self shareButtons];
      
    CGFloat buttonPadding = [self shareButtonPadding];
    CGFloat buttonDiameter = MIN(48, (self.view.frame.size.width - (24 * 2) - ((buttons.count - 1) * buttonPadding)) / buttons.count);
      
    shareBlock.frame = CGRectMake(shareBlock.frame.origin.x, shareBlock.frame.origin.y, shareBlock.frame.size.width, buttonDiameter);
    for (NSInteger i = 0; i < buttons.count; i++) {
        NSDictionary *buttonDict = buttons[i];
        NSString *identifier = buttonDict[@"id"];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(24 + i * (buttonDiameter + buttonPadding), shareBlock.frame.size.height - buttonDiameter, buttonDiameter, buttonDiameter);
        button.layer.cornerRadius = button.frame.size.width / 2;
        button.backgroundColor = buttonDict[@"color"];
        button.adjustsImageWhenHighlighted = false;
        button.layer.masksToBounds = true;
        button.tintColor = [UIColor bonfirePrimaryColor];
        [button setImage:buttonDict[@"image"] forState:UIControlStateNormal];
        button.contentMode = UIViewContentModeCenter;
        [shareBlock addSubview:button];
        
        [button bk_addEventHandler:^(id sender) {
            [HapticHelper generateFeedback:FeedbackType_Selection];
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                button.transform = CGAffineTransformMakeScale(0.92, 0.92);
            } completion:nil];
        } forControlEvents:UIControlEventTouchDown];
                  
        [button bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                button.transform = CGAffineTransformIdentity;
            } completion:nil];
        } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
        
        [button bk_whenTapped:^{
            NSString *campShareLink = [NSString stringWithFormat:@"https://bonfire.camp/c/%@", self.camp.identifier];
            if ([identifier isEqualToString:@"bonfire"]) {
                [Launcher openComposePost:nil inReplyTo:nil withMessage:nil media:nil quotedObject:self.camp];
            }
            else if ([identifier isEqualToString:@"instagram"]) {
                [Launcher shareCampOnInstagram:self.camp];
            }
            else if ([identifier isEqualToString:@"twitter"]) {
                if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://post"]]) {
                    NSString *message = [[NSString stringWithFormat:@"Help me start a Camp on @yourbonfire! Join %@: %@", self.camp.attributes.title, campShareLink] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?%#[]"]];
                    
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"twitter://post?message=%@", message]] options:@{} completionHandler:nil];
                }
            }
            else if ([identifier isEqualToString:@"snapchat"]) {
                [Launcher shareCampOnSnapchat:self.camp];
            }
            else if ([identifier isEqualToString:@"imessage"]) {
                [Launcher shareOniMessage:[NSString stringWithFormat:@"Help me start a Camp on Bonfire! Join %@: %@", self.camp.attributes.title, campShareLink] image:nil];
            }
            else if ([identifier isEqualToString:@"facebook"]) {
                FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
                content.contentURL = [NSURL URLWithString:campShareLink];
                content.hashtag = [FBSDKHashtag hashtagWithString:@"#Bonfire"];
                [FBSDKShareDialog showFromViewController:[Launcher topMostViewController]
                                               withContent:content
                                                  delegate:nil];
            }
            else if ([identifier isEqualToString:@"more"]) {
                [Launcher shareCamp:self.camp];
            }
        }];
    }
    
    return shareBlock;
}

- (void)setSearchPhrase:(NSString *)searchPhrase {
    if (![searchPhrase isEqualToString:_searchPhrase]) {
        _searchPhrase = searchPhrase;
        
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
        [self getMembersWithCursorType:StreamPagingCursorTypeNone];
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
        
        [self updateFilteredContacts];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:memberCellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[SearchResultCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:memberCellIdentifier];
    }
    
    // member cell
    if (indexPath.section == 0) {
        // bonfire user
        User *user = self.stream.users[indexPath.row];
        cell.user = user;
        
        cell.checkIcon.hidden = ![self.selectedMembers containsObject:user];
        
        cell.lineSeparator.hidden = (indexPath.row == self.stream.users.count - 1);
    }
    else if (indexPath.section == 1) {
        cell.user = nil;
        
        CNContact *contact = self.filteredContacts[indexPath.row];
        [cell.profilePicture sd_cancelCurrentImageLoad];
        if (contact.imageData) {
            cell.profilePicture.imageView.image = [UIImage imageWithData:contact.imageData];
        }
        else {
            cell.profilePicture.user = nil;
        }
        if (contact.givenName && contact.familyName) {
            cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", contact.givenName, contact.familyName];
        }
        else if (contact.givenName) {
            cell.textLabel.text = contact.givenName;
        }
        else if (contact.familyName) {
            cell.textLabel.text = contact.familyName;
        }
        
        cell.detailTextLabel.text = contact.phoneNumbers.firstObject.value.stringValue;
        cell.detailTextLabel.textColor = [UIColor bonfireSecondaryColor];
        cell.tintColor = [UIColor bonfirePrimaryColor];
        cell.checkIcon.tintColor = cell.tintColor;
        
        cell.checkIcon.hidden = ![self.selectedMembers containsObject:contact];
        
        cell.lineSeparator.hidden = (indexPath.row == self.filteredContacts.count - 1);
    }
        
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 68;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id object;
    if (indexPath.section == 0) {
        // bonfire user
        User *user = self.stream.users[indexPath.row];
        object = user;
    }
    else if (indexPath.section == 1) {
        CNContact *contact = self.filteredContacts[indexPath.row];
        object = contact;
    }
    
    if (object) {
        if ([self.selectedMembers containsObject:object]) {
            // already checked
            [self.selectedMembers removeObject:object];
        }
        else {
            // not checked yet
            [self.selectedMembers addObject:object];
        }
            
        SearchResultCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if ([cell isKindOfClass:[SearchResultCell class]]) {
            cell.checkIcon.hidden = ![self.selectedMembers containsObject:object];
            [cell layoutSubviews];
        }
        
        [self checkRequirements];
    }
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)save {
    self.view.userInteractionEnabled = false;
        
    // create the group
    JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
    HUD.textLabel.text = [NSString stringWithFormat:@"Inviting Friend%@...", self.selectedMembers.count > 1 ? @"s" : @""];
    HUD.vibrancyEnabled = false;
    HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
    HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
    [HUD showInView:self.navigationController.view animated:YES];
    
    NSMutableArray *inviteList = [[NSMutableArray alloc] init];
    
    NSString *url = [NSString stringWithFormat:@"camps/%@/members/invite", self.camp.identifier];
    
    for (id object in self.selectedMembers) {
        if ([object isKindOfClass:[Identity class]]) {
            [inviteList addObject:((Identity *)object).identifier];
        }
        else if ([object isKindOfClass:[CNContact class]]) {
            [inviteList addObject:((CNContact *)object).identifier];
        }
    }
    
    NSDictionary *params = @{@"invite_list": inviteList};
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // all done!
        NSLog(@"all requests finished!");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // all done!
        // error
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        });
    }];
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

- (void)checkRequirements {
    BOOL meetsRequirements = (self.selectedMembers.count > 0);
    
    self.saveButton.enabled = meetsRequirements;
}

- (NBPhoneNumberUtil *)phoneUtil {
    if (!_phoneUtil) {
        _phoneUtil = [[NBPhoneNumberUtil alloc] init];
    }
    
    return _phoneUtil;
}

@end
