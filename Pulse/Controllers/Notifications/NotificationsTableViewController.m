//
//  NotificationsTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 12/5/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "NotificationsTableViewController.h"

#import "AppDelegate.h"

#import "ActivityCell.h"
#import "StreamPostCell.h"
#import "AddReplyCell.h"

#import "UIColor+Palette.h"
#import "Session.h"
#import "HAWebService.h"
#import "UserActivity.h"
#import "BFVisualErrorView.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "UserActivityStream.h"
#import "TabController.h"
#import "Launcher.h"
#import <PINCache/PINCache.h>
#import "BFTipsManager.h"
#import <Shimmer/FBShimmeringView.h>
#import "BFTipView.h"
@import Firebase;
@import UserNotifications;

@interface NotificationsTableViewController ()

@property (nonatomic, strong) UserActivityStream *stream;
@property (nonatomic, strong) BFVisualErrorView *errorView;
@property (nonatomic, strong) BFTipObject *turnOnNotificationsTipObject;

@property (nonatomic) NSString *loadingPrevCursor;

@property (nonatomic, strong) FBShimmeringView *titleView;

@property (nonatomic, strong) NSTimer *markAsReadTimer;

@end

@implementation NotificationsTableViewController

static NSString * const notificationCellReuseIdentifier = @"NotificationCell";
static NSString * const streamPostReuseIdentifier = @"streamPostCell";
static NSString * const addReplyCellIdentifier = @"addReplyCell";
static NSString * const blankCellReuseIdentifier = @"BlankCell";

- (void)viewDidLoad {
    [super viewDidLoad];
            
    [self setupTableView];
    [self setupErrorView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationReceived:) name:@"RemoteNotificationReceived" object:nil];
    
    [self loadCache];
    
    if (self.stream.activities.count == 0) {
        self.loading = true;
    }
    else {
        self.tableView.alpha = 1;
        self.loading = false;
    }
    
    if (![self announcementTipObject]) {
        [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            
            if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined) {
                NSString *title = @"Receive Instant Updates";
                NSString *text = @"Turn on Push Notifications to get instant updates from Bonfire";
                NSString *ctaDisplayText = @"Turn on Post Notifications";
                
                BFTipObject *tipObject = [BFTipObject tipWithCreatorType:BFTipCreatorTypeBonfireGeneric creator:nil title:title text:text cta:ctaDisplayText imageUrl:nil action:^{
                    self.turnOnNotificationsTipObject = nil;
                    [UIView animateWithDuration:.45f delay:0 usingSpringWithDamping:0.9f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        [self.tableView beginUpdates];
                        self.turnOnNotificationsTipObject = nil;
                        [self.tableView endUpdates];
                    } completion:^(BOOL finished) {

                    }];
                    
                    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert|UNAuthorizationOptionSound|UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
                        // 1. check if permisisons granted
                        if (granted) {
                            // do work here
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSLog(@"inside dispatch async block main thread from main thread");
                                [[UIApplication sharedApplication] registerForRemoteNotifications];
                            });
                        }
                    }];
                }];
                
                self.turnOnNotificationsTipObject = tipObject;
            }
        }];
    }
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Notifications" screenClass:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postUpdated:) name:@"PostUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postDeleted:) name:@"PostDeleted" object:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    self.cellHeightsDictionary = @{}.mutableCopy;
    
    // support dark mode
    [self.stream updateAttributedStrings];
    [self.tableView reloadData];
}

- (void)notificationReceived:(NSNotification *)notification {
    [self getActivitiesWithCursor:StreamPagingCursorTypePrevious];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self clearNotifications];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        if ([self.stream prevCursor].length > 0) {
            [self getActivitiesWithCursor:StreamPagingCursorTypePrevious];
        }
        else {
            [self getActivitiesWithCursor:StreamPagingCursorTypeNone];
        }
        
        // first time
        [self setupTitleView];
        
        if ([self announcementTipObject]) {
            [[Session sharedInstance].defaults.announcement dismissWithCompletion:nil];
        }
    }
    else {
        self.cellHeightsDictionary = @{}.mutableCopy;
        
        [self.stream updateAttributedStrings];
        [self.tableView reloadData];
    }
    
    [self refreshIfNeeded];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self positionErrorView];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self markAllAsRead];
}

- (void)markAllAsRead {
    if (self.markAsReadTimer) {
        [self.markAsReadTimer invalidate];
        self.markAsReadTimer = nil;
    }
    
    if ([self.stream unreadCount] > 0) {
        [self.stream markAllAsRead];
        [self saveCache];
        [self.tableView reloadData];
    }
}

- (void)setupTitleView {
    UIButton *titleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [titleButton setTitleColor:[UIColor bonfirePrimaryColor] forState:UIControlStateNormal];
    titleButton.titleLabel.font = ([self.navigationController.navigationBar.titleTextAttributes objectForKey:NSFontAttributeName] ? self.navigationController.navigationBar.titleTextAttributes[NSFontAttributeName] : [UIFont systemFontOfSize:18.f weight:UIFontWeightBold]);
    [titleButton setTitle:self.title forState:UIControlStateNormal];
    titleButton.frame = CGRectMake(0, 0, [titleButton intrinsicContentSize].width, self.navigationController.navigationBar.frame.size.height);
    [titleButton bk_whenTapped:^{
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
        
        if (!self.loading) {
            [self refreshIfNeeded];
        }
    }];
    
    self.titleView = [[FBShimmeringView alloc] initWithFrame:titleButton.frame];
    [self.titleView addSubview:titleButton];
    self.titleView.contentView = titleButton;
    
    self.navigationItem.titleView = titleButton;
}

- (void)clearNotifications {
    self.navigationController.tabBarItem.badgeValue = nil;
    [(TabController *)self.tabBarController setBadgeValue:nil forItem:self.navigationController.tabBarItem];
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)setupTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 40 + 16 + 16, 0);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    self.cellHeightsDictionary = @{}.mutableCopy;
    
    [self.tableView registerClass:[ActivityCell class] forCellReuseIdentifier:notificationCellReuseIdentifier];
    [self.tableView registerClass:[StreamPostCell class] forCellReuseIdentifier:streamPostReuseIdentifier];
    [self.tableView registerClass:[AddReplyCell class] forCellReuseIdentifier:addReplyCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellReuseIdentifier];
}

- (void)setupErrorView {
    BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNotFound title:@"Error loading replies" description:@"Check your network settings and tap below to try again" actionTitle:nil actionBlock:nil];
    
    self.errorView = [[BFVisualErrorView alloc] initWithVisualError:visualError];
    [self positionErrorView];
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
}

- (void)loadCache {
    NSArray *cache = [[PINCache sharedCache] objectForKey:@"user_activities_cache"];
    
    self.stream = [[UserActivityStream alloc] init];
    if (cache.count > 0) {
        for (NSDictionary *pageDict in cache) {
            UserActivityStreamPage *page = [[UserActivityStreamPage alloc] initWithDictionary:pageDict error:nil];
            [self.stream appendPage:page];
            
            self.cellHeightsDictionary = @{}.mutableCopy;
        }
        
        if (self.stream.activities.count > 0) {
            self.loading = false;
        }
        
        [self.tableView reloadData];
    }
}
- (void)saveCache {
    NSMutableArray *newCache = [[NSMutableArray alloc] init];
    
    for (NSInteger i = 0; i < self.stream.pages.count; i++) {
        [newCache addObject:[self.stream.pages[i] toDictionary]];
    }
    
    [[PINCache sharedCache] setObject:[newCache copy] forKey:@"user_activities_cache"];
}

- (void)postUpdated:(NSNotification *)notification {
    Post *post = notification.object;
    // NSLog(@"post that's updated: %@", post);
    
    if (post != nil) {
        // new post appears valid
        BOOL changes = [self.stream updatePost:post removeDuplicates:true];
        
        if (changes) {
            // 💫 changes made
            if (![[Launcher activeViewController] isEqual:UIViewParentController(self)]) {
                [self.tableView reloadData];
            }
        }
    }
}
- (void)postDeleted:(NSNotification *)notification {
    if (![notification.object isKindOfClass:[Post class]]) return;
    
    Post *post = notification.object;

    BOOL removedPost = [self.stream removePost:post];
    if (removedPost) [self refresh];
}

- (void)refreshIfNeeded {
    NSTimeInterval secondsSinceLastFetch = [self.lastFetch timeIntervalSinceNow];
    if (secondsSinceLastFetch < -(2 * 60)) {
        [self refresh];
    }
}
- (void)refresh {
    if (self.loading) {
        return;
    }
    
    self.lastFetch = [NSDate new];
    [self getActivitiesWithCursor:StreamPagingCursorTypePrevious];
}

- (void)setLoading:(BOOL)loading {
    [super setLoading:loading];
    
    if (!self.loading) {
        self.titleView.shimmering = false;
        
        [self.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
    }
}

- (void)getActivitiesWithCursor:(StreamPagingCursorType)cursorType {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (self.stream.prevCursor.length > 0) {
        if ([self.stream.prevCursor isEqualToString:_loadingPrevCursor]) {
            return;
        }
        
        [params setObject:self.stream.prevCursor forKey:@"cursor"];
        _loadingPrevCursor = self.stream.prevCursor;
    }
    
    if (cursorType == StreamPagingCursorTypeNone && self.stream.activities.count == 0) {
        self.loading = true;
    }
    else if (cursorType == StreamPagingCursorTypePrevious) {
        self.titleView.shimmering = true;
    }
        
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:@"users/me/notifications" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // NSLog(@"response object for notifications: %@", responseObject[@"data"]);
        
        if (self.loadingPrevCursor.length > 0) {
            self.loadingPrevCursor = nil;
        }
        
        UserActivityStreamPage *page = [[UserActivityStreamPage alloc] initWithDictionary:responseObject error:nil];
                
        if (page.data.count > 0) {
            if (page.meta.paging.replaceCache || ![params objectForKey:@"cursor"]) {
                // clear the stream (we retrieved a full page of notifs and the old ones are out of date)
                self.stream = [[UserActivityStream alloc] init];
            }
            
            self.cellHeightsDictionary = @{}.mutableCopy;
            
            // always prepend with cursor since we don't allow the frontend to use next cursors
            [self.stream prependPage:page];
                        
            [self saveCache];
        }
        
        self.loading = false;
        [self.tableView reloadData];
        [self.tableView layoutIfNeeded];
        
        // pop up the red dot above the notifications tab
        NSInteger unread = [self.stream unreadCount];
        if (unread > 0) {
            if (self.viewIfLoaded.window != nil) {
                // view is visible and unread count > 0
                // unread timer
                [self.markAsReadTimer invalidate];
                self.markAsReadTimer = nil;
                self.markAsReadTimer = [NSTimer bk_scheduledTimerWithTimeInterval:5.0 block:^(NSTimer *timer) {
                    [self markAllAsRead];
                } repeats:false];
            }
            else {
                // view not visible and unread count > 0
                [(TabController *)self.tabBarController setBadgeValue:[NSString stringWithFormat:@"%lu", (long)unread] forItem:self.navigationController.tabBarItem];
                [self.tableView layoutIfNeeded];
                [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:true];
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Notificaitons  / getMembers() - error: %@", error);
        
        if (self.stream.activities.count == 0) {
            // Error: No posts yet!
            self.errorView.hidden = false;
            
            BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNoNotifications title:@"No Notifications" description:nil actionTitle:nil actionBlock:nil];
            self.errorView.visualError = visualError;
            
            [self positionErrorView];
        }
        
        self.cellHeightsDictionary = @{}.mutableCopy;
                        
        self.loading = false;
        [self.tableView reloadData];
        [self.tableView layoutIfNeeded];
    }];
}

- (void)positionErrorView {
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.tableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (!self.loading && self.stream.activities.count == 0 && ![self announcementTipObject] && !self.turnOnNotificationsTipObject) {
        self.errorView.hidden = false;
        
        BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNoNotifications title:@"No Notifications" description:nil actionTitle:nil actionBlock:nil];
        self.errorView.visualError = visualError;
        
        [self positionErrorView];
    }
    else {
        self.errorView.hidden = true;
    }
    
    return MAX(1, self.stream.activities.count);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < self.stream.activities.count && [self.stream.activities[section].type isEqualToString:@"user_activity"]) {
        UserActivity *activity = self.stream.activities[section];
        
        Post *post;
        if (activity.attributes.type == USER_ACTIVITY_TYPE_POST_REPLY) {
            post = activity.attributes.replyPost;
        }
        else if (activity.attributes.type == USER_ACTIVITY_TYPE_POST_MENTION) {
            post = activity.attributes.post;
        }
        
        if (post) {
            return 2; // include add reply cell
        }
        
        return 1;
    }
    
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < self.stream.activities.count && [self.stream.activities[indexPath.section].type isEqualToString:@"user_activity"]) {
        UserActivity *activity = self.stream.activities[indexPath.section];
        
        Post *post;
        if (activity.attributes.type == USER_ACTIVITY_TYPE_POST_REPLY) {
            post = activity.attributes.replyPost;
        }
        else if (activity.attributes.type == USER_ACTIVITY_TYPE_POST_MENTION) {
            post = activity.attributes.post;
        }
        
        if (post) {
            if (indexPath.row == 0) {
                StreamPostCell *cell = [tableView dequeueReusableCellWithIdentifier:streamPostReuseIdentifier forIndexPath:indexPath];
                
                if (cell == nil) {
                    cell = [[StreamPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:streamPostReuseIdentifier];
                }
                
                cell.showContext = true;
                cell.showCamptag = true;
                cell.hideActions = true;
                
                cell.post = post;
                
                cell.moreButton.hidden = true;
                cell.lineSeparator.hidden = true;
                
                cell.unread = !activity.attributes.read;
                
                return cell;
            }
            else if (indexPath.row == 1) {
                // "add a reply"
                AddReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:addReplyCellIdentifier forIndexPath:indexPath];
                
                if (cell == nil) {
                    cell = [[AddReplyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:addReplyCellIdentifier];
                }
                
                NSString *username = post.attributes.creator.attributes.identifier;
                NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Reply to @%@...", username] attributes:@{NSFontAttributeName: cell.addReplyButton.titleLabel.font, NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
                [attributedString setAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:cell.addReplyButton.titleLabel.font.pointSize weight:UIFontWeightSemibold]} range:[attributedString.string rangeOfString:[NSString stringWithFormat:@"@%@", username]]];
                [cell.addReplyButton setAttributedTitle:attributedString forState:UIControlStateNormal];
                
                cell.lineSeparator.hidden = (indexPath.section == [self numberOfSectionsInTableView:tableView] - 1);
                cell.levelsDeep = -1;
                
                cell.unread = !activity.attributes.read;
                
                return cell;
            }
        }
        else {
            ActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:notificationCellReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[ActivityCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:notificationCellReuseIdentifier];
            }
            
            // Configure the cell...
            cell.activity = self.stream.activities[indexPath.section];
            
            cell.unread = !cell.activity.attributes.read;
            
            cell.lineSeparator.hidden = (indexPath.section == [self numberOfSectionsInTableView:tableView] - 1);
            
            return cell;
        }
    }
    
    // if all else fails, return a blank cell
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankCellReuseIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point  API_AVAILABLE(ios(13.0)){
    if ([[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[PostCell class]]) {
        Post *post = ((PostCell *)[tableView cellForRowAtIndexPath:indexPath]).post;
        
        if (post) {
            NSMutableArray *actions = [NSMutableArray new];
            if ([post.attributes.context.post.permissions canReply]) {
                NSMutableArray *actions = [NSMutableArray new];
                UIAction *replyAction = [UIAction actionWithTitle:@"Reply" image:[UIImage systemImageNamed:@"arrowshape.turn.up.left"] identifier:@"reply" handler:^(__kindof UIAction * _Nonnull action) {
                    wait(0, ^{
                        [Launcher openComposePost:post.attributes.postedIn inReplyTo:post withMessage:nil media:nil  quotedObject:nil];
                    });
                }];
                [actions addObject:replyAction];
            }
            
            if (post.attributes.postedIn) {
                UIAction *openCamp = [UIAction actionWithTitle:@"Open Camp" image:[UIImage systemImageNamed:@"number"] identifier:@"open_camp" handler:^(__kindof UIAction * _Nonnull action) {
                    Camp *camp = [[Camp alloc] initWithDictionary:[post.attributes.postedIn toDictionary] error:nil];
                    
                    [Launcher openCamp:camp];
                }];
                [actions addObject:openCamp];
            }
            
            UIAction *shareViaAction = [UIAction actionWithTitle:@"Share via..." image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:@"share_via" handler:^(__kindof UIAction * _Nonnull action) {
                [Launcher sharePost:post];
            }];
            [actions addObject:shareViaAction];
            
            UIMenu *menu = [UIMenu menuWithTitle:@"" children:actions];
            
            PostViewController *postVC = [Launcher postViewControllerForPost:post];
            postVC.isPreview = true;
            
            UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:indexPath previewProvider:^(){return postVC;} actionProvider:^(NSArray* suggestedAction){return menu;}];
            return configuration;
        }
    }
    
    return nil;
}
- (void)tableView:(UITableView *)tableView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator  API_AVAILABLE(ios(13.0)){
    NSIndexPath *indexPath = (NSIndexPath *)configuration.identifier;
    
    [animator addCompletion:^{
        wait(0, ^{
            if ([[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[PostCell class]]) {
                Post *post = ((PostCell *)[tableView cellForRowAtIndexPath:indexPath]).post;
                
                [Launcher openPost:post withKeyboard:false];
            }
        });
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 0;
    
    if ([_cellHeightsDictionary objectForKey:indexPath] && !self.loading) {
        return [_cellHeightsDictionary[indexPath] doubleValue];
    }
    
    if (indexPath.section < self.stream.activities.count && [self.stream.activities[indexPath.section].type isEqualToString:@"user_activity"]) {
        UserActivity *activity = self.stream.activities[indexPath.section];
        
        if (activity.attributes.type == USER_ACTIVITY_TYPE_POST_REPLY || activity.attributes.type == USER_ACTIVITY_TYPE_POST_MENTION) {
            // for replies and mentions, use stream post cell with add reply cell underneath
            Post *post;
            if (activity.attributes.type == USER_ACTIVITY_TYPE_POST_REPLY) {
                post = activity.attributes.replyPost;
            }
            else if (activity.attributes.type == USER_ACTIVITY_TYPE_POST_MENTION) {
                post = activity.attributes.post;
            }
            
            if (post) {
                if (indexPath.row == 0) {
                    height = [StreamPostCell heightForPost:post showContext:true showActions:false minimizeLinks:false];
                }
                else if (indexPath.row == 1) {
                    height = [AddReplyCell height];
                }
            }
        }
        else {
            height = [ActivityCell heightForUserActivity:activity];
        }
    }
    
    if (!self.loading) {
        [self.cellHeightsDictionary setObject:@(height) forKey:indexPath];
    }
    
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//#ifdef DEBUG
//    if (self.stream.activities.count > section) {
//        UserActivity *activity = self.stream.activities[section];
//
//        if (activity.prevCursor.length > 0) {
//            return 24;
//        }
//    }
//#endif
    
    if (section == 0 && ([self announcementTipObject] || self.turnOnNotificationsTipObject)) {
        BFTipView *tipView;
        if ([self announcementTipObject]) {
            tipView = [[BFTipView alloc] initWithObject:[self announcementTipObject]];
        }
        else if (self.turnOnNotificationsTipObject) {
            tipView = [[BFTipView alloc] initWithObject:self.turnOnNotificationsTipObject];
        }
        
        if (tipView) {
            return tipView.frame.size.height + (12 * 2);
        }
    }
    
    return CGFLOAT_MIN;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//#ifdef DEBUG
//    if (self.stream.activities.count > section) {
//        UserActivity *activity = self.stream.activities[section];
//
//        if (activity.prevCursor.length > 0) {
//            UIView *derp = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 24)];
//            derp.backgroundColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.08];
//
//            UILabel *derpLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, derp.frame.size.width - 24, derp.frame.size.height)];
//            NSString *string = @"";
//            derpLabel.font = [UIFont systemFontOfSize:10.f weight:UIFontWeightRegular];
//            derpLabel.textColor = [UIColor bonfireSecondaryColor];
//            if (activity.prevCursor.length > 0) {
//                string = [@"prev: " stringByAppendingString:activity.prevCursor];
//            }
//            derpLabel.text = string;
//            [derp addSubview:derpLabel];
//
//            [derp bk_whenTapped:^{
//                [Launcher shareOniMessage:[NSString stringWithFormat:@"activity: %@\n\nprev cursor: %@", activity.identifier, activity.prevCursor] image:nil];
//            }];
//
//            return derp;
//        }
//    }
//#endif
    
    if (section == 0 && ([self announcementTipObject] || self.turnOnNotificationsTipObject)) {
        BFTipObject *tipObject;
        if ([self announcementTipObject]) {
            tipObject = [self announcementTipObject];
        }
        else if (self.turnOnNotificationsTipObject) {
            tipObject = self.turnOnNotificationsTipObject;
        }

        if (tipObject) {
            UIView *containerView = [[UIView alloc] init];
            containerView.frame = CGRectMake(0, 0, self.view.frame.size.width, 100);
            
            BFTipView *tipView = [[BFTipView alloc] init];
            tipView.frame = CGRectMake(12, 12, self.view.frame.size.width - 24, 200);
            tipView.style = BFTipViewStyleTable;
            tipView.dragToDismiss = false;
            tipView.object = tipObject;
            tipView.blurView.backgroundColor = [UIColor whiteColor];
            tipView.frame = CGRectMake(12, 12, self.view.frame.size.width - 24, tipView.frame.size.height);
            [tipView.closeButton bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
            [tipView.closeButton bk_whenTapped:^{
                [UIView animateWithDuration:.45f delay:0 usingSpringWithDamping:0.9f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    tipView.alpha = 0;
                    tipView.transform = CGAffineTransformMakeScale(0.8, 0.8);
                    
                    [self.tableView beginUpdates];
                    if (tipObject == [self announcementTipObject]) {
                        [Session sharedInstance].defaults.announcement = nil;
                    }
                    else if (tipObject == self.turnOnNotificationsTipObject) {
                        self.turnOnNotificationsTipObject = nil;
                    }
                    [self.tableView endUpdates];
                } completion:^(BOOL finished) {

                }];
            }];
            containerView.frame = CGRectMake(0, 0, self.view.frame.size.width, tipView.frame.size.height + (12 * 2));
            [containerView addSubview:tipView];
            
            return containerView;
        }
    }
    
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (BFTipObject *)announcementTipObject {
    if ([Session sharedInstance].defaults.announcement) {
        NSString *title = [Session sharedInstance].defaults.announcement.attributes.title;
        NSString *text = [Session sharedInstance].defaults.announcement.attributes.text;
        NSString *ctaDisplayText = [Session sharedInstance].defaults.announcement.attributes.cta.displayText;
        NSString *imageUrl = [Session sharedInstance].defaults.announcement.attributes.imageUrl;
        
        BFTipObject *tipObject = [BFTipObject tipWithCreatorType:BFTipCreatorTypeBonfireGeneric creator:nil title:title text:text cta:ctaDisplayText imageUrl:imageUrl action:^{
            // register tap with API
            [[Session sharedInstance].defaults.announcement ctaTappedWithCompletion:nil];
            
            // handle tap
            if ([[Session sharedInstance].defaults.announcement.attributes.cta.type isEqualToString:@"client_update"]) {
                NSString *url;
                if ([Configuration isRelease]) {
                    url = @"https://itunes.apple.com/app/1438702812";
                }
                else {
                    url = @"https://beta.itunes.apple.com/v1/app/1438702812";
                }
                
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:^(BOOL success) {
                    NSLog(@"opened url!");
                }];
            }
            else if ([Session sharedInstance].defaults.announcement.attributes.cta.actionUrl.length > 0) {
                [Launcher openURL:[Session sharedInstance].defaults.announcement.attributes.cta.actionUrl];
            }
        }];
        
        return tipObject;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    if ([cell isKindOfClass:[PostCell class]]) {
        Post *post = ((PostCell *)cell).post;
        if (post) {
            [Launcher openPost:post withKeyboard:NO];
        }
    }
    else if ([cell isKindOfClass:[ActivityCell class]]) {
        UserActivity *activity = ((ActivityCell *)cell).activity;
        
        if (!activity) {
            return;
        }
        
        NSObject *object = activity.attributes.target.object;
        if (!object) {
            USER_ACTIVITY_TYPE type = activity.attributes.type;
            if (type == USER_ACTIVITY_TYPE_USER_FOLLOW) {
                object = activity.attributes.actioner;
            }
            else if (type == USER_ACTIVITY_TYPE_USER_ACCEPTED_ACCESS ||
                     type == USER_ACTIVITY_TYPE_CAMP_ACCESS_REQUEST ||
                     type == USER_ACTIVITY_TYPE_CAMP_INVITE) {
                object = activity.attributes.camp;
            }
            else if (type == USER_ACTIVITY_TYPE_POST_REPLY) {
                object = activity.attributes.replyPost;
            }
            else if (type == USER_ACTIVITY_TYPE_POST_VOTED ||
                     type == USER_ACTIVITY_TYPE_USER_POSTED ||
                     type == USER_ACTIVITY_TYPE_POST_MENTION ||
                     type == USER_ACTIVITY_TYPE_USER_POSTED_CAMP) {
                object = activity.attributes.post;
            }
        }
        
        NSString *urlString = activity.attributes.target.url;
        NSURL *url = [NSURL URLWithString:urlString];
        BOOL appCanOpenURL = ([Configuration isExternalBonfireURL:url] || [Configuration isInternalURL:url]);
        
        if (object) {
            // launch object
            if ([object isKindOfClass:[Identity class]]) {
                [Launcher openIdentity:(Identity *)object];
            }
            else if ([object isKindOfClass:[Post class]]) {
                [Launcher openPost:(Post *)object withKeyboard:NO];
            }
            else if ([object isKindOfClass:[Camp class]]) {
                [Launcher openCamp:(Camp *)object];
            }
        }
        else if (appCanOpenURL) {
            AppDelegate *ad = (AppDelegate *)[UIApplication sharedApplication].delegate;
            [ad application:[UIApplication sharedApplication] openURL:url options:@{}];
        }
        else if (activity.attributes.target.url && activity.attributes.target.url.length > 0) {
            // the URL is not a known Bonfire URL, so open it in a Safari VC
            [Launcher openURL:urlString];
        }
    }
    else if ([cell isKindOfClass:[AddReplyCell class]]) {
        PostCell *cell = (PostCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
        if ([cell isKindOfClass:[PostCell class]]) {
            [Launcher openComposePost:cell.post.attributes.postedIn inReplyTo:cell.post withMessage:nil media:nil quotedObject:nil];
        }
    }
}

@end
