//
//  AddManagerTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 3/5/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "AddManagerTableViewController.h"
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
@import Firebase;

@interface AddManagerTableViewController ()

@property (nonatomic, strong) NSString *searchPhrase;
@property (nonatomic, strong) NSMutableArray <User *> *members;

@property (nonatomic, strong) NSMutableArray <NSString *> *selectedMembers;

@end

@implementation AddManagerTableViewController

static NSString * const memberCellIdentifier = @"MemberCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor headerBackgroundColor];
    
    self.title = [NSString stringWithFormat:@"Add %@", ([self.managerType isEqualToString:CAMP_ROLE_ADMIN] ? @"Directors" : @"Managers")];
    self.view.tintColor = [UIColor fromHex:self.camp.attributes.details.color];
    self.navigationController.view.tintColor = self.view.tintColor;
    
    [self setupNavigationBar];
    [self setupTableView];
    [self setupErrorView];
    
    self.members = [[NSMutableArray alloc] init];
    self.selectedMembers = [[NSMutableArray alloc] init];
    [self getMembers];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Add Manager" screenClass:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    self.tableView.backgroundColor = [UIColor headerBackgroundColor];
}

- (void)setupNavigationBar {
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = false;
    self.navigationController.navigationBar.backgroundColor = nil;
    self.navigationController.navigationBar.shadowImage = [self imageWithColor:[UIColor colorWithWhite:0 alpha:0.12f]];
    
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor bonfireBlack],
       NSFontAttributeName:[UIFont systemFontOfSize:18.f weight:UIFontWeightBold]}];
    
    self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    [self.cancelButton setTintColor:self.view.tintColor];
    [self.cancelButton setTitleTextAttributes:@{
                                                NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium]
                                                } forState:UIControlStateNormal];
    [self.cancelButton setTitleTextAttributes:@{
                                                NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium]
                                                } forState:UIControlStateSelected];
    self.navigationItem.leftBarButtonItem = self.cancelButton;
    
    self.saveButton = [[UIBarButtonItem alloc] bk_initWithTitle:@"Add" style:UIBarButtonItemStyleDone handler:^(id sender) {
        [self save];
    }];
    self.saveButton.enabled = false;
    [self.saveButton setTintColor:self.view.tintColor];
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
}

- (void)setupTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorColor = [UIColor separatorColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 70, 0, 0);
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:memberCellIdentifier];
}

- (void)getMembers {
    NSString *url = [NSString stringWithFormat:@"camps/%@/members", self.camp.identifier];
    
    NSLog(@"final url: %@", url);
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (self.searchPhrase && self.searchPhrase.length > 0) {
        [params setObject:self.searchPhrase forKey:@"filter_query"];
    }
    
    if (self.members.count > 0) {
        // add cursor ish so it pages
        NSString *nextCursor = [self.members lastObject].identifier;
        if (nextCursor && nextCursor.length > 0) {
            [params setObject:nextCursor forKey:@"cursor"];
        }
    }
    
    // types of members to show
    NSString *filterTypes = [NSString stringWithFormat:@"member,%@", [self.managerType isEqualToString:CAMP_ROLE_ADMIN] ? @"moderator" : @"admin"];
    [params setObject:filterTypes forKey:@"filter_types"];
    
    NSLog(@"params: %@", params);
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSArray *responseData = (NSArray *)responseObject[@"data"];
        
        if (![params objectForKey:@"cursor"]) {
            self.members = [[NSMutableArray alloc] init];
        }
        [self.members addObjectsFromArray:[self convertToUserObjects:responseData]];
        
        if (self.members.count == 0) {
            [self showNoMembersView];
        }
        else {
            [self hideNoMembersView];
        }
        
        [self.tableView reloadData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"AddManagerTableViewController / getMembers() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
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
    self.errorView = [[ErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100) title:@"No Members Available" description:[NSString stringWithFormat:@"Have others join the Camp before assigning them %@", [self.managerType isEqualToString:CAMP_ROLE_ADMIN] ? @"Directors" : @"Managers"] type:ErrorViewTypeGeneral];
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
    return self.members.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section != 0 || ![self.errorView isHidden]) return CGFLOAT_MIN;
    
    return 52;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section != 0 || ![self.errorView isHidden]) return nil;
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 52)];
    header.backgroundColor = [UIColor whiteColor];
    
    // search view
    self.searchView = [[BFSearchView alloc] initWithFrame:CGRectMake(12, 8, self.view.frame.size.width - (12 * 2), 36)];
    self.searchView.textField.placeholder = @"Search Members";
    [self.searchView updateSearchText:self.searchPhrase];
    self.searchView.textField.tintColor = self.view.tintColor;
    self.searchView.textField.delegate = self;
    [self.searchView.textField bk_addEventHandler:^(id sender) {
        self.searchPhrase = self.searchView.textField.text;
        [self.tableView setContentOffset:CGPointMake(0, 0)];
        [self getMembers];
    } forControlEvents:UIControlEventEditingChanged];
    [header addSubview:self.searchView];
    
    return header;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:memberCellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[SearchResultCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:memberCellIdentifier];
    }
    
    // Configure the cell...
    cell.type = 2;
    
    // member cell
    User *user = self.members[indexPath.row];
    cell.profilePicture.user = user;
    
    NSMutableAttributedString *attributedCreatorName = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", user.attributes.details.displayName] attributes:@{NSForegroundColorAttributeName: [UIColor bonfireBlack], NSFontAttributeName: [UIFont systemFontOfSize:cell.textLabel.font.pointSize weight:UIFontWeightSemibold]}];
    NSAttributedString *usernameString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" @%@", user.attributes.details.identifier] attributes:@{NSForegroundColorAttributeName: [UIColor bonfireGray], NSFontAttributeName: [UIFont systemFontOfSize:cell.textLabel.font.pointSize weight:UIFontWeightRegular]}];
    [attributedCreatorName appendAttributedString:usernameString];
    cell.textLabel.attributedText = attributedCreatorName;
    
    cell.detailTextLabel.text = ([user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier] ? @"You" : [@"Joined " stringByAppendingString:[NSDate mysqlDatetimeFormattedAsTimeAgo:user.attributes.context.camp.membership.joinedAt withForm:TimeAgoLongForm]]);
    
    cell.checkIcon.hidden = ![self.selectedMembers containsObject:user.identifier];
    cell.checkIcon.tintColor = self.view.tintColor;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 68;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    User *user = self.members[indexPath.row];
    
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
    NSString *url = [NSString stringWithFormat:@"camps/%@/members/roles", self.camp.identifier];
    
    // create the group
    JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
    HUD.textLabel.text = [NSString stringWithFormat:@"Adding %@%@...", ([self.managerType isEqualToString:CAMP_ROLE_ADMIN] ? @"Director" : @"Manager"), self.selectedMembers.count > 1 ? @"s" : @""];
    HUD.vibrancyEnabled = false;
    HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
    HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
    [HUD showInView:self.navigationController.view animated:YES];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // code here
        
        dispatch_group_t group = dispatch_group_create();
        
        for (NSString *identifier in self.selectedMembers) {
            NSDictionary *params = @{@"user_id": identifier, @"role": self.managerType};
            
            // before calling each request
            dispatch_group_enter(group);
            
            [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // on the completion of each request
                NSLog(@"success");
                dispatch_group_leave(group);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"AddManagerTableViewController / save() - error: %@", error);
                NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                NSLog(@"errorResponse: %@", ErrorResponse);
                
                NSLog(@"fail");
                
                // on the completion of each request
                dispatch_group_leave(group);
            }];
        }
        
        // to use it as a completion handler
        dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"all requests finished!");
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CampManagersUpdated" object:@{@"camp": self.camp, @"type": self.managerType}];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            });
        });
    });
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
