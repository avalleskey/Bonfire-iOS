//
//  ProfileFollowingListViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ProfileFollowingListViewController.h"
#import "Session.h"
#import "SearchResultCell.h"
#import "HAWebService.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import "UserListStream.h"
#import "BFVisualErrorView.h"
@import Firebase;

@interface ProfileFollowingListViewController ()

@property (nonatomic, strong) UserListStream *stream;

@property (nonatomic, strong) BFVisualErrorView *errorView;

@property (nonatomic) BOOL loadingMoreUsers;

@end

@implementation ProfileFollowingListViewController

static NSString * const blankReuseIdentifier = @"BlankCell";
static NSString * const emptySectionCellIdentifier = @"EmptyCell";

static NSString * const memberCellIdentifier = @"MemberCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton = true;
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
    
    [self setupTableView];
    [self setupErrorView];
    
    [self setSpinning:true];
    
    [self getUsersWithCursor:StreamPagingCursorTypeNone];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Profile / Following" screenClass:nil];
}

- (void)setupTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    self.tableView.separatorColor = [UIColor tableViewSeparatorColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 70, 0, 0);
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.tintColor = self.theme;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:emptySectionCellIdentifier];
    
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:memberCellIdentifier];
}

- (void)setupErrorView {
    BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNotFound title:@"Error loading" description:@"Check your network settings and tap below to try again" actionTitle:nil actionBlock:nil];
    
    self.errorView = [[BFVisualErrorView alloc] initWithVisualError:visualError];
    [self positionErrorView];
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
}

- (void)getUsersWithCursor:(StreamPagingCursorType)cursorType {
    NSString *url = [NSString stringWithFormat:@"users/%@/following", self.user.identifier];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
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
        self.loading = true;
    }
    
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
                
        if (self.stream.users.count == 0) {
            self.errorView.hidden = false;
            
            BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNoPosts title:@"No Users to Show" description:[NSString stringWithFormat:@"@%@ doesn't follow anyone", self.user.attributes.identifier] actionTitle:nil actionBlock:nil];
            self.errorView.visualError = visualError;
            
            [self positionErrorView];
        }
        else {
            self.errorView.hidden = true;
        }
        
        self.loading = false;
        
        [self.tableView reloadData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"ProfileFollowingListViewController / getUsersWithCursor() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        if (nextCursor.length > 0) {
            [self.stream removeLoadedCursor:nextCursor];
        }
        
        if (self.stream.users.count == 0) {
            // Error: No posts yet!
            self.errorView.hidden = false;
            
            BFVisualError *visualError = [BFVisualError visualErrorOfType:([HAWebService hasInternet] ? ErrorViewTypeGeneral : ErrorViewTypeNoInternet) title:([HAWebService hasInternet] ? @"Error Loading" : @"No Internet") description:@"Check your network settings and tap below to try again" actionTitle:@"Try Again" actionBlock:^{
                self.loading = true;
                self.errorView.hidden = true;
                [self getUsersWithCursor:StreamPagingCursorTypeNone];
            }];
            self.errorView.visualError = visualError;
            
            [self positionErrorView];
        }
        
        self.loading = false;
        
        [self.tableView reloadData];
    }];
}

- (void)positionErrorView {
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.tableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && !self.loading) {
        return self.stream.users.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row < self.stream.users.count) {
        SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:memberCellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[SearchResultCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:memberCellIdentifier];
        }
        
        User *user = self.stream.users[indexPath.row];
        cell.user = user;
        
        return cell;
    }
    
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankReuseIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 68;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
        BOOL showLoadingFooter = self.loading || ((self.loadingMoreUsers || hasAnotherPage) && ![self.stream hasLoadedCursor:self.stream.nextCursor]);
        
        return showLoadingFooter ? 52 : 0;
    }
    
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        // last row
        BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
        BOOL showLoadingFooter = self.loading || ((self.loadingMoreUsers || hasAnotherPage) && ![self.stream hasLoadedCursor:self.stream.nextCursor]);
        
        if (showLoadingFooter) {
            UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 52)];
            
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            spinner.color = [UIColor bonfireSecondaryColor];
            spinner.frame = CGRectMake(footer.frame.size.width / 2 - 10, footer.frame.size.height / 2 - 10, 20, 20);
            [footer addSubview:spinner];
            
            [spinner startAnimating];
            
            if (!self.loadingMoreUsers && self.stream.pages.count > 0 && self.stream.nextCursor.length > 0) {
                [self getUsersWithCursor:StreamPagingCursorTypeNext];
            }
            
            return footer;
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row < self.stream.users.count) {
        User *user = self.stream.users[indexPath.row];
        
        if (user) {
            [Launcher openProfile:user];
        }
    }
}

@end
