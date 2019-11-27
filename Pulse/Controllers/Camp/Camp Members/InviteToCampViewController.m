//
//  AddManagerTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 3/5/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "InviteToCampViewController.h"
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
@import Firebase;

@interface InviteToCampViewController ()

@property (nonatomic, strong) NSString *searchPhrase;

@property (nonatomic, strong) UserListStream *stream;

@property (nonatomic) BOOL loadingUsers;
@property (nonatomic) BOOL loadingMoreUsers;

@property (nonatomic, strong) NSMutableArray <NSString *> *selectedMembers;

@property (nonatomic, strong) SimpleNavigationController *simpleNav;

@end

@implementation InviteToCampViewController

static NSString * const memberCellIdentifier = @"MemberCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor viewBackgroundColor];
    
    self.title = @"Invite to Join";
    self.view.tintColor = [UIColor fromHex:self.camp.attributes.color];
    self.navigationController.view.tintColor = self.view.tintColor;
    
    [self setupNavigationBar];
    [self setupTableView];
    [self setupErrorView];
    
    self.selectedMembers = [[NSMutableArray alloc] init];
    [self getUsersWithCursorType:StreamPagingCursorTypeNone];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Invite to Join Camp" screenClass:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tableView.backgroundColor = [UIColor viewBackgroundColor];
}

- (void)setupNavigationBar {
    self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    [self.cancelButton setTintColor:self.view.tintColor];
    [self.cancelButton setTitleTextAttributes:@{
                                                NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium]
                                                } forState:UIControlStateNormal];
    [self.cancelButton setTitleTextAttributes:@{
                                                NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium]
                                                } forState:UIControlStateSelected];
    self.navigationItem.leftBarButtonItem = self.cancelButton;
    
    self.inviteButton = [[UIBarButtonItem alloc] bk_initWithTitle:@"Invite" style:UIBarButtonItemStyleDone handler:^(id sender) {
        [self save];
    }];
    self.inviteButton.enabled = false;
    [self.inviteButton setTintColor:self.view.tintColor];
    [self.inviteButton setTitleTextAttributes:@{
                                              NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightBold]
                                              } forState:UIControlStateDisabled];
    [self.inviteButton setTitleTextAttributes:@{
                                              NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightBold]
                                              } forState:UIControlStateNormal];
    [self.inviteButton setTitleTextAttributes:@{
                                              NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightBold]
                                              } forState:UIControlStateHighlighted];
    self.navigationItem.rightBarButtonItem = self.inviteButton;
    
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

- (void)getUsersWithCursorType:(StreamPagingCursorType)cursorType {
    NSString *url = @"search/users";
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    if (self.searchPhrase && self.searchPhrase.length > 0) {
        [params setObject:self.searchPhrase forKey:@"q"];
    }
    
    NSString *nextCursor = [self.stream nextCursor];
    if (cursorType == StreamPagingCursorTypeNext && nextCursor.length > 0) {
        if ([self.stream hasLoadedCursor:nextCursor]) {
            return;
        }
        
        self.loadingMoreUsers = true;
        [self.stream addLoadedCursor:nextCursor];
        [params setObject:nextCursor forKey:@"cursor"];
    }
    else {
        self.loadingUsers = true;
    }
    
    // types of members to show
    //NSString *filterTypes = [NSString stringWithFormat:@"member,%@", [self.managerType isEqualToString:CAMP_ROLE_ADMIN] ? @"moderator" : @"admin"];
    //[params setObject:filterTypes forKey:@"filter_types"];
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        UserListStreamPage *page = [[UserListStreamPage alloc] initWithDictionary:responseObject error:nil];
        
        if (page.data.count > 0) {
            if ([params objectForKey:@"cursor"]) {
                self.loadingMoreUsers = false;
            }
            else {
                // clear the stream (we retrieved a full page of notifs and the old ones are out of date)
                self.stream = [[UserListStream alloc] init];
            }
            [self.stream appendPage:page];
        }
        
        self.loadingUsers = false;
        
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
        self.loadingUsers = false;
        
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.stream.users.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section != 0 || ![self.errorView isHidden]) return CGFLOAT_MIN;
    
    return 52;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section != 0 || ![self.errorView isHidden]) return nil;
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 52)];
    
    // search view
    self.searchView = [[BFSearchView alloc] initWithFrame:CGRectMake(12, 8, self.view.frame.size.width - (12 * 2), 36)];
    self.searchView.textField.placeholder = @"Search Members";
    [self.searchView updateSearchText:self.searchPhrase];
    self.searchView.textField.tintColor = self.view.tintColor;
    self.searchView.textField.delegate = self;
    [self.searchView.textField bk_addEventHandler:^(id sender) {
        self.searchPhrase = self.searchView.textField.text;
        
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
        [self getUsersWithCursorType:StreamPagingCursorTypeNone];
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    } forControlEvents:UIControlEventEditingChanged];
    [header addSubview:self.searchView];
    
    return header;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
        BOOL showLoadingFooter = self.loadingUsers || ((self.loadingMoreUsers || hasAnotherPage) && ![self.stream hasLoadedCursor:self.stream.nextCursor]);
        
        return showLoadingFooter ? 52 : 0;
    }
    
    return CGFLOAT_MIN;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        // last row
        BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
        BOOL showLoadingFooter = self.loadingUsers || ((self.loadingMoreUsers || hasAnotherPage) && ![self.stream hasLoadedCursor:self.stream.nextCursor]);
        
        if (showLoadingFooter) {
            UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 52)];
            
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            spinner.color = [UIColor bonfireSecondaryColor];
            spinner.frame = CGRectMake(footer.frame.size.width / 2 - 10, footer.frame.size.height / 2 - 10, 20, 20);
            [footer addSubview:spinner];
            
            [spinner startAnimating];
            
            if (!self.loadingMoreUsers && self.stream.pages.count > 0 && self.stream.nextCursor.length > 0) {
                [self getUsersWithCursorType:StreamPagingCursorTypeNext];
            }
            
            return footer;
        }
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:memberCellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[SearchResultCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:memberCellIdentifier];
    }
    
    User *user = self.stream.users[indexPath.row];
    cell.profilePicture.user = user;
    
    NSMutableAttributedString *attributedCreatorName = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", user.attributes.displayName] attributes:@{NSForegroundColorAttributeName: [UIColor bonfirePrimaryColor], NSFontAttributeName: [UIFont systemFontOfSize:cell.textLabel.font.pointSize weight:UIFontWeightSemibold]}];
    NSAttributedString *usernameString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" @%@", user.attributes.identifier] attributes:@{NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor], NSFontAttributeName: [UIFont systemFontOfSize:cell.textLabel.font.pointSize weight:UIFontWeightRegular]}];
    [attributedCreatorName appendAttributedString:usernameString];
    cell.textLabel.attributedText = attributedCreatorName;
    
    cell.detailTextLabel.text = ([user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier] ? @"You" : [@"Joined " stringByAppendingString:[NSDate mysqlDatetimeFormattedAsTimeAgo:user.attributes.context.camp.membership.joinedAt withForm:TimeAgoLongForm]]);
    
    cell.checkIcon.hidden = ![self.selectedMembers containsObject:user.identifier];
    cell.checkIcon.tintColor = self.view.tintColor;
    cell.lineSeparator.hidden = (indexPath.row == self.stream.users.count - 1);
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 68;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    User *user = self.stream.users[indexPath.row];
    
    if ([self.selectedMembers containsObject:user.identifier]) {
        // already checked
        [self.selectedMembers removeObject:user.identifier];
    }
    else {
        // not checked yet
        [self.selectedMembers addObject:user.identifier];
    }
        
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
    
    [self checkRequirements];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)save {
    self.view.userInteractionEnabled = false;
    
    NSString *url = [NSString stringWithFormat:@"camps/%@/members/roles", self.camp.identifier];
    
    // create the group
    JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
    HUD.textLabel.text = [NSString stringWithFormat:@"Adding %@%@...", ([self.managerType isEqualToString:CAMP_ROLE_ADMIN] ? @"Director" : @"Manager"), self.selectedMembers.count > 1 ? @"s" : @""];
    HUD.vibrancyEnabled = false;
    HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
    HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
    [HUD showInView:self.navigationController.view animated:YES];
    
    NSMutableArray *completedMembers = [[NSMutableArray alloc] init];
    
    for (NSString *identifier in self.selectedMembers) {
        NSDictionary *params = @{@"user_id": identifier, @"role": self.managerType};
        
        [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            // on the completion of each request
            NSLog(@"success");
            
            [completedMembers addObject:params[@"user_id"]];
            if (completedMembers.count == self.selectedMembers.count) {
                // all done!
                NSLog(@"all requests finished!");
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CampManagersUpdated" object:@{@"camp": self.camp, @"type": self.managerType}];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                });
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            [completedMembers addObject:params[@"user_id"]];
            if (completedMembers.count == self.selectedMembers.count) {
                // all done!
                NSLog(@"all requests finished!");
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CampManagersUpdated" object:@{@"camp": self.camp, @"type": self.managerType}];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                });
            }
        }];
    }
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
    
    self.inviteButton.enabled = meetsRequirements;
}

// Extra methods
- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 0.5);
    const CGFloat alpha = CGColorGetAlpha(color.CGColor);
    const BOOL opaque = alpha == 1;
    UIGraphicsBeginImageContextWithOptions(rect.size, opaque, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
