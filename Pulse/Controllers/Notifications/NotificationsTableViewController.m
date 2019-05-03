//
//  NotificationsTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 12/5/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "NotificationsTableViewController.h"
#import "NotificationCell.h"
#import "UIColor+Palette.h"
#import "Session.h"
#import "HAWebService.h"
#import "UserActivity.h"
#import "ErrorView.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "UserActivityStream.h"
#import "TabController.h"
#import "Launcher.h"
@import Firebase;

@interface NotificationsTableViewController ()

@property (nonatomic, strong) UserActivityStream *stream;
@property (nonatomic, strong) ErrorView *errorView;

@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL loadingMore;

@end

@implementation NotificationsTableViewController

static NSString * const notificationCellReuseIdentifier = @"NotificationCell";
static NSString * const blankCellReuseIdentifier = @"BlankCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor headerBackgroundColor];
    
    [self setupTableView];
    [self setupErrorView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationReceived:) name:@"RemoteNotificationReceived" object:nil];
    
    self.loading = true;
    
    [self getNotificationsWithNextCursor:false];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Notifications" screenClass:nil];
}

- (void)notificationReceived:(NSNotification *)notification {
    [self getNotificationsWithNextCursor:false];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    self.navigationController.tabBarItem.badgeValue = nil;
    [(TabController *)self.tabBarController setBadgeValue:nil forItem:self.navigationController.tabBarItem];
    
    self.tableView.backgroundColor = [UIColor headerBackgroundColor];
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.tableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
}

- (void)setupTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor headerBackgroundColor];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 48, 0);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0/*72*/, 0, 0);
    self.tableView.separatorColor = [UIColor separatorColor];
    
    self.tableView.refreshControl = [[UIRefreshControl alloc] init];
    [self.tableView.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    [self.tableView registerClass:[NotificationCell class] forCellReuseIdentifier:notificationCellReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellReuseIdentifier];
}

- (void)setupErrorView {
    self.errorView = [[ErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100) title:@"Error loading notifications" description:@"To to try again" type:ErrorViewTypeNotFound];
    self.errorView.center = self.tableView.center;
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
    
    [self.errorView bk_whenTapped:^{
        self.loading = true;
        [self.tableView reloadData];
        [self getNotificationsWithNextCursor:false];
    }];
}

- (void)refresh {
    [self getNotificationsWithNextCursor:false];
    
    [self.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
}

- (void)getNotificationsWithNextCursor:(BOOL)useNextCursor {
    self.loading = true;
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[NSNumber numberWithInt:10] forKey:@"limit"];
    if (useNextCursor && self.stream.pages.count > 0 && [self.stream.pages lastObject].meta.paging.next_cursor != nil) {
        // add cursor ish so it pages
        NSString *nextCursor = [self.stream.pages lastObject].meta.paging.next_cursor;
        if (nextCursor && nextCursor.length > 0) {
            [params setObject:nextCursor forKey:@"cursor"];
        }
    }
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:@"users/me/notifications" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"response object for members: %@", responseObject);
        
        if (![params objectForKey:@"cursor"]) {
            self.stream = [[UserActivityStream alloc] init];
        }
        UserActivityStreamPage *page = [[UserActivityStreamPage alloc] initWithDictionary:responseObject error:nil];
        [self.stream appendPage:page];
        
        self.loading = false;
        self.loadingMore = false;
        
        // [self hideLoadingSpinner];
        
        [self.tableView reloadData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"AddManagerTableViewController / getMembers() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        self.loading = false;
        self.loadingMore = false;
        
        if (self.stream.activities.count == 0) {
            // Error: No posts yet!
            self.errorView.hidden = false;
            
            [self.errorView updateType:ErrorViewTypeNoNotifications];
            [self.errorView updateTitle:@"No Notifications"];
            [self.errorView updateDescription:nil];
        }
        
        [self.tableView reloadData];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.stream.activities.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.stream.activities.count) {
        NotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:notificationCellReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[NotificationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:notificationCellReuseIdentifier];
        }
        
        // Configure the cell...
        cell.activity = self.stream.activities[indexPath.row];
        
        return cell;
    }
    
    // if all else fails, return a blank cell
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankCellReuseIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.stream.activities.count) {
        UserActivity *activity = self.stream.activities[indexPath.row];
        return [NotificationCell heightForUserActivity:activity];
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    if (section == 0 && [self newNotifications].count > 0) return 64;
//    if (section == 1) return 16;
    
    return CGFLOAT_MIN;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    /*
    if (section == 0 && [self newNotifications].count > 0) {
        UIView *headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
        
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
        [headerContainer addSubview:header];
        
        header.backgroundColor = [UIColor headerBackgroundColor];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(12, 32, self.view.frame.size.width - 66 - 100, 21)];
        title.text = @"New";
        title.textAlignment = NSTextAlignmentLeft;
        title.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightBold];
        title.textColor = [UIColor colorWithWhite:0.47f alpha:1];
        
        [header addSubview:title];
        
        return headerContainer;
    }
    if (section == 1) return [[UIView alloc] init];*/
    
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        BOOL hasAnotherPage = self.stream.pages.count > 0 && [self.stream.pages lastObject].meta.paging.next_cursor != nil && [self.stream.pages lastObject].meta.paging.next_cursor.length > 0;
        BOOL showLoadingFooter = ((self.loading && self.stream.activities.count == 0) || self.loadingMore || hasAnotherPage);
        
        return (showLoadingFooter ? 52 : 0);
    }
    
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        BOOL hasAnotherPage = self.stream.pages.count > 0 && [self.stream.pages lastObject].meta.paging.next_cursor != nil && [self.stream.pages lastObject].meta.paging.next_cursor.length > 0;
        BOOL showLoadingFooter = ((self.loading && self.stream.activities.count == 0) ||  self.loadingMore || hasAnotherPage);
        
        if (showLoadingFooter) {
            UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 52)];
            
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            spinner.frame = CGRectMake(footer.frame.size.width / 2 - 10, footer.frame.size.height / 2 - 10, 20, 20);
            [footer addSubview:spinner];

            [spinner startAnimating];
            
            if (!self.loadingMore && self.stream.pages.count > 0 && [self.stream.pages lastObject].meta.paging.next_cursor != nil && [self.stream.pages lastObject].meta.paging.next_cursor.length > 0) {
                self.loadingMore = true;
                NSLog(@"fetch next page");
                [self getNotificationsWithNextCursor:true];
            }
            
            return footer;
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.stream.activities.count) return;
    
    UserActivity *activity = self.stream.activities[indexPath.row];

    if ([activity.type isEqualToString:USER_ACTIVITY_TYPE_USER_FOLLOW]) {
        // open their profile
        [[Launcher sharedInstance] openProfile:activity.attributes.details.actionedBy];
    }
    else if ([activity.type isEqualToString:USER_ACTIVITY_TYPE_USER_ACCEPTED_ACCESS]) {
        // open room
        [[Launcher sharedInstance] openProfile:activity.attributes.details.actionedBy];
    }
    else if ([activity.type isEqualToString:USER_ACTIVITY_TYPE_ROOM_ACCESS_REQUEST]) {
        // open room
        [[Launcher sharedInstance] openRoomMembersForRoom:activity.attributes.details.room];
    }
    else if ([activity.type isEqualToString:USER_ACTIVITY_TYPE_POST_REPLY]) {
        // open the reply
        [[Launcher sharedInstance] openPost:activity.attributes.details.replyPost withKeyboard:NO];
    }
    else if ([activity.type isEqualToString:USER_ACTIVITY_TYPE_POST_SPARKED]) {
        // open the post
        [[Launcher sharedInstance] openPost:activity.attributes.details.post withKeyboard:NO];
    }
    else if ([activity.type isEqualToString:USER_ACTIVITY_TYPE_USER_POSTED]) {
        // open the post
        [[Launcher sharedInstance] openPost:activity.attributes.details.post withKeyboard:NO];
    }
}

@end
