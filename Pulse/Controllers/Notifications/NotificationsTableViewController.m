//
//  NotificationsTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 12/5/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "NotificationsTableViewController.h"
#import "ActivityCell.h"
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
#import <PINCache/PINCache.h>
#import "BFTipsManager.h"
@import Firebase;

@interface NotificationsTableViewController () {
    NSDate *lastFetch;
}

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
    
    //((SimpleNavigationController *)self.navigationController).navigationBar.prefersLargeTitles = true;
    
    [self setupTableView];
    [self setupErrorView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationReceived:) name:@"RemoteNotificationReceived" object:nil];
    
    self.loading = true;
    
    [self loadCache];
    if ([self.stream prevCursor].length > 0) {
        [self getActivitiesWithCursor:UserActivityStreamPagingCursorTypePrevious];
    }
    else {
        [self getActivitiesWithCursor:UserActivityStreamPagingCursorTypeNone];
    }
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Notifications" screenClass:nil];
}

- (void)notificationReceived:(NSNotification *)notification {
    [self getActivitiesWithCursor:UserActivityStreamPagingCursorTypePrevious];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self clearNotifications];
    
    // self.tableView.backgroundColor = [UIColor headerBackgroundColor];
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.tableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
    
    if ([BFTipsManager hasSeenTip:@"how_to_share_beta"] == false && [Launcher activeTabController]) {
        BFTipObject *tipObject = [BFTipObject tipWithCreatorType:BFTipCreatorTypeBonfireTip creator:nil title:@"Share the Bonfire Beta 📢" text:@"Inviting your friends to the Beta is easy! Tap the invite button on the top right to invite friends via iMessage" action:^{
            NSLog(@"tip tapped");
            [Launcher openInviteFriends:self];
        }];
        [[BFTipsManager manager] presentTip:tipObject completion:^{
            NSLog(@"presentTip() completion");
        }];
    }
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.tableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
    
    if (self.view.tag == 1) {
        // fetch new posts after 2mins
        NSTimeInterval secondsSinceLastFetch = [lastFetch timeIntervalSinceNow];
        NSLog(@"seconds since last fetch: %f", -secondsSinceLastFetch);
        if (secondsSinceLastFetch < -(2 * 60)) {
            [self refresh];
        }
    }
    else {
        self.view.tag = 1;
    }
}

- (void)clearNotifications {
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    self.navigationController.tabBarItem.badgeValue = nil;
    [(TabController *)self.tabBarController setBadgeValue:nil forItem:self.navigationController.tabBarItem];
}

- (void)setupTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    // self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    // self.tableView.separatorColor = [UIColor separatorColor];
    
    self.tableView.refreshControl = [[UIRefreshControl alloc] init];
    [self.tableView.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    [self.tableView registerClass:[ActivityCell class] forCellReuseIdentifier:notificationCellReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellReuseIdentifier];
}

- (void)setupErrorView {
    self.errorView = [[ErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100) title:@"Error loading notifications" description:@"To to try again" type:ErrorViewTypeNotFound];
    self.errorView.center = self.tableView.center;
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
    
    [self.errorView bk_whenTapped:^{
        self.loading = true;
        self.errorView.hidden = true;
        [self.tableView reloadData];
        
        [self getActivitiesWithCursor:UserActivityStreamPagingCursorTypeNone];
    }];
}

- (void)loadCache {
    NSArray *cache = [[PINCache sharedCache] objectForKey:@"activities_cache"];
    
    if (cache.count > 0) {        
        self.stream = [[UserActivityStream alloc] init];
        
        UserActivityStreamPage *page = [[UserActivityStreamPage alloc] initWithDictionary:@{@"data": cache} error:nil];
        [self.stream appendPage:page];
        
        [self refresh];
    }
    else {
        self.stream = [[UserActivityStream alloc] init];
    }
}
- (void)saveCache {
    NSMutableArray *newCache = [[NSMutableArray alloc] init];
    
    NSInteger postsCount = 0;
    for (NSInteger i = 0; i < self.stream.pages.count && postsCount < MAX_CACHED_ACTIVITIES; i++) {
        postsCount += self.stream.pages[i].data.count;
        [newCache addObject:[self.stream.pages[i] toDictionary]];
    }
    
    [[PINCache sharedCache] setObject:[newCache copy] forKey:@"activities_cache"];
}

- (void)refresh {
    if (self.loading) return;
    
    lastFetch = [NSDate new];
    if ([self.stream prevCursor].length > 0) {
        [self getActivitiesWithCursor:UserActivityStreamPagingCursorTypePrevious];
    }
    else {
        [self getActivitiesWithCursor:UserActivityStreamPagingCursorTypeNone];
    }
}

- (void)getActivitiesWithCursor:(UserActivityStreamPagingCursorType)cursorType {
    self.loading = true;
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    NSLog(@"cursors available:: prev- %@", self.stream.prevCursor);
    if (self.stream.prevCursor.length > 0) {
        [params setObject:self.stream.prevCursor forKey:@"cursor"];
    }
    
    NSLog(@"params: %@", params);
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:@"users/me/notifications" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // NSLog(@"response object for notifications: %@", responseObject[@"data"]);
        
        UserActivityStreamPage *page = [[UserActivityStreamPage alloc] initWithDictionary:responseObject error:nil];
        
        if (page.data.count > 0) {
            if (page.replaceCache || ![params objectForKey:@"cursor"]) {
                // clear the stream (we retrieved a full page of notifs and the old ones are out of date)
                self.stream = [[UserActivityStream alloc] init];
            }
            [self.stream prependPage:page];
                        
            [self saveCache];
        }
        
        
        self.loading = false;
        self.loadingMore = false;
        
        if (self.stream.activities.count == 0) {
            self.errorView.hidden = false;
            
            [self.errorView updateType:ErrorViewTypeNoNotifications];
            [self.errorView updateTitle:@"No Notifications"];
            [self.errorView updateDescription:nil];
        }
        else {
            self.errorView.hidden = true;
        }
        
        [self.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
        
        [self.tableView reloadData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Notificaitons  / getMembers() - error: %@", error);
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
        
        [self.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
        
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
    if (indexPath.row < self.stream.activities.count && [self.stream.activities[indexPath.row].type isEqualToString:@"user_activity"]) {
        ActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:notificationCellReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[ActivityCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:notificationCellReuseIdentifier];
        }
        
        // Configure the cell...
        cell.activity = self.stream.activities[indexPath.row];
        
        cell.unread = cell.activity.unread;
        
        cell.lineSeparator.hidden = (indexPath.row == self.stream.activities.count - 1);
        
        return cell;
    }
    
    // if all else fails, return a blank cell
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankCellReuseIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.stream.activities.count && [self.stream.activities[indexPath.row].type isEqualToString:@"user_activity"]) {
        UserActivity *activity = self.stream.activities[indexPath.row];
        return [ActivityCell heightForUserActivity:activity];
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
#ifdef DEBUG
    if (self.stream.activities.count > section) {
        UserActivity *activity = self.stream.activities[section];
        
        if (activity.prevCursor.length > 0) {
            return 24;
        }
    }
#endif
    
    return CGFLOAT_MIN;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
#ifdef DEBUG
    if (self.stream.activities.count > section) {
        UserActivity *activity = self.stream.activities[section];
        
        NSLog(@"activity prev cursor ish");
        
        if (activity.prevCursor.length > 0) {
            UIView *derp = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 24)];
            derp.backgroundColor = [[UIColor separatorColor] colorWithAlphaComponent:0.5];
            
            UILabel *derpLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, derp.frame.size.width - 24, derp.frame.size.height)];
            NSString *string = @"";
            derpLabel.font = [UIFont systemFontOfSize:10.f weight:UIFontWeightRegular];
            derpLabel.textColor = [UIColor bonfireGray];
            if (activity.prevCursor.length > 0) {
                string = [@"prev: " stringByAppendingString:activity.prevCursor];
            }
            derpLabel.text = string;
            [derp addSubview:derpLabel];
            
            [derp bk_whenTapped:^{
                [Launcher shareOniMessage:[NSString stringWithFormat:@"activity: %@\n\nprev cursor: %@", activity.identifier, activity.prevCursor] image:nil];
            }];
            
            return derp;
        }
    }
#endif
    
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.stream.activities.count) return;
    
    UserActivity *activity = self.stream.activities[indexPath.row];
    
    NSDictionary *formats = [Session sharedInstance].defaults.notifications;
    
    NSString *key = [NSString stringWithFormat:@"%u", activity.attributes.type];
    if ([[formats allKeys] containsObject:key]) {
        NSError *error;
        DefaultsNotificationsFormat *notificationFormat = [[DefaultsNotificationsFormat alloc] initWithDictionary:formats[key] error:&error];
        if (!error) {
            if ([notificationFormat.actionObject isEqualToString:ACTIVITY_ACTION_OBJECT_ACTIONER]) {
                [Launcher openProfile:activity.attributes.actioner];
            }
            else if ([notificationFormat.actionObject isEqualToString:ACTIVITY_ACTION_OBJECT_POST]) {
                [Launcher openPost:activity.attributes.post withKeyboard:NO];
            }
            else if ([notificationFormat.actionObject isEqualToString:ACTIVITY_ACTION_OBJECT_REPLY_POST]) {
                NSLog(@"reply post: %@", activity.attributes.replyPost);
                [Launcher openPost:activity.attributes.replyPost withKeyboard:NO];
            }
            else if ([notificationFormat.actionObject isEqualToString:ACTIVITY_ACTION_OBJECT_CAMP]) {
                [Launcher openCamp:activity.attributes.camp];
            }
        }
    }
}

@end
