//
//  NotificationsTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 12/5/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "NotificationsTableViewController.h"

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

@interface NotificationsTableViewController ()

@property (nonatomic, strong) UserActivityStream *stream;
@property (nonatomic, strong) BFVisualErrorView *errorView;

@property (nonatomic) BOOL showUpsell;
@property (nonatomic) NSString *loadingPrevCursor;

@property (nonatomic, strong) FBShimmeringView *titleView;

@property (nonatomic, strong) NSDate *lastFetch;

@end

@implementation NotificationsTableViewController

static NSString * const notificationCellReuseIdentifier = @"NotificationCell";
static NSString * const streamPostReuseIdentifier = @"streamPostCell";
static NSString * const addReplyCellIdentifier = @"addReplyCell";
static NSString * const blankCellReuseIdentifier = @"BlankCell";

- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.loading = true;
    self.showUpsell = true;
    
    [self setupTableView];
    [self setupErrorView];
    
    [self setSpinning:true];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationReceived:) name:@"RemoteNotificationReceived" object:nil];
    
    [self loadCache];
    if ([self.stream prevCursor].length > 0) {
        [self getActivitiesWithCursor:StreamPagingCursorTypePrevious];
    }
    else {
        [self getActivitiesWithCursor:StreamPagingCursorTypeNone];
    }
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Notifications" screenClass:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postUpdated:) name:@"PostUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postDeleted:) name:@"PostDeleted" object:nil];
}

- (void)notificationReceived:(NSNotification *)notification {
    [self getActivitiesWithCursor:StreamPagingCursorTypePrevious];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self clearNotifications];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self positionErrorView];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        // first time
        [self setupTitleView];
        
        // fetch new posts after 2mins
        NSTimeInterval secondsSinceLastFetch = [self.lastFetch timeIntervalSinceNow];
        // NSLog(@"seconds since last fetch: %f", -secondsSinceLastFetch);
        if (secondsSinceLastFetch < -(2 * 60)) {
            [self refresh];
        }
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
            // fetch new posts after 2mins
            NSTimeInterval secondsSinceLastFetch = [self.lastFetch timeIntervalSinceNow];
            // NSLog(@"seconds since last fetch: %f", -secondsSinceLastFetch);
            if (secondsSinceLastFetch < -(2 * 60)) {
                [self refresh];
            }
        }
    }];
    
    self.titleView = [[FBShimmeringView alloc] initWithFrame:titleButton.frame];
    [self.titleView addSubview:titleButton];
    self.titleView.contentView = titleButton;
    
    self.navigationItem.titleView = titleButton;
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
    [self.tableView.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
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
    NSArray *cache = [[PINCache sharedCache] objectForKey:@"activities_cache"];
    
    self.stream = [[UserActivityStream alloc] init];
    if (cache.count > 0) {
        for (NSDictionary *pageDict in cache) {
            UserActivityStreamPage *page = [[UserActivityStreamPage alloc] initWithDictionary:pageDict error:nil];
            [self.stream appendPage:page];
        }
        
        NSLog(@"self.stream.activities.count :: %lu", (unsigned long)self.stream.activities.count);
        
        [self refresh];
    }
}
- (void)saveCache {
    NSMutableArray *newCache = [[NSMutableArray alloc] init];
    
    NSInteger postsCount = 0;
    for (NSInteger i = 0; i < self.stream.pages.count && postsCount < MAX_CACHED_ACTIVITIES; i++) {
        postsCount += self.stream.pages[i].data.count;
        
        if (postsCount > 40) {
            // TODO: Clip posts over 40
        }
        [newCache addObject:[self.stream.pages[i] toDictionary]];
    }
    
    [[PINCache sharedCache] setObject:[newCache copy] forKey:@"activities_cache"];
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
                [self refresh];
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

- (void)refresh {
    if (self.loading) return;
    
    self.lastFetch = [NSDate new];
    if ([self.stream prevCursor].length > 0) {
        [self getActivitiesWithCursor:StreamPagingCursorTypePrevious];
    }
    else {
        [self getActivitiesWithCursor:StreamPagingCursorTypeNone];
    }
}

- (void)setLoading:(BOOL)loading {
    [super setLoading:loading];
    
    if (!self.loading) {
        self.titleView.shimmering = false;
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
    
    if (cursorType == StreamPagingCursorTypeNone || cursorType == StreamPagingCursorTypePrevious) {
        self.titleView.shimmering = true;
    }
    
    self.loading = true;
    
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
            // always prepend with cursor since we don't allow the frontend to use next cursors
            [self.stream prependPage:page];
                        
            [self saveCache];
        }
                
        if (self.stream.activities.count == 0 && ![self messageOfTheDayNotificationObject]) {
            self.errorView.hidden = false;
            
            BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNoNotifications title:@"No Notifications" description:nil actionTitle:nil actionBlock:nil];
            self.errorView.visualError = visualError;
            
            [self positionErrorView];
        }
        else {
            self.errorView.hidden = true;
        }
        
        [self.tableView reloadData];
        [self.tableView layoutIfNeeded];
        
        self.loading = false;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Notificaitons  / getMembers() - error: %@", error);
        
        if (self.stream.activities.count == 0) {
            // Error: No posts yet!
            self.errorView.hidden = false;
            
            BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNoNotifications title:@"No Notifications" description:nil actionTitle:nil actionBlock:nil];
            self.errorView.visualError = visualError;
            
            [self positionErrorView];
        }
                
        [self.tableView reloadData];
        
        self.loading = false;
    }];
}

- (void)positionErrorView {
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.tableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return MAX(1, self.stream.activities.count);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < self.stream.activities.count && [self.stream.activities[section].type isEqualToString:@"user_activity"]) {
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
                cell.hideActions = false;
                
                cell.post = post;
                
                if (cell.actionsView.replyButton.gestureRecognizers.count == 0) {
                    [cell.actionsView.replyButton bk_whenTapped:^{
                        [Launcher openPost:cell.post withKeyboard:YES];
                    }];
                }
                
                cell.lineSeparator.hidden = (indexPath.section == self.stream.activities.count - 1);
                
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
                
                cell.lineSeparator.hidden = false;
                
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
            
            cell.unread = cell.activity.unread;
            
            cell.lineSeparator.hidden = (indexPath.section == self.stream.activities.count - 1);
            
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
            UIAction *replyAction = [UIAction actionWithTitle:@"Reply" image:[UIImage systemImageNamed:@"arrowshape.turn.up.left"] identifier:@"reply" handler:^(__kindof UIAction * _Nonnull action) {
                [Launcher openComposePost:post.attributes.postedIn inReplyTo:post withMessage:nil media:nil];
            }];
            [actions addObject:replyAction];
            
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
                    return [StreamPostCell heightForPost:post showContext:true showActions:true];
                }
                else if (indexPath.row == 1) {
                    return [AddReplyCell height];
                }
            }
        }
        
        return [ActivityCell heightForUserActivity:activity];
    }
    
    return 0;
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
    
    if (section == 0 && [self messageOfTheDayNotificationObject]) {
        BFTipView *tipView = [[BFTipView alloc] initWithObject:[self messageOfTheDayNotificationObject]];
        return tipView.frame.size.height + (12 * 2);
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
    
    if (section == 0 && [self messageOfTheDayNotificationObject]) {
        UIView *containerView = [[UIView alloc] init];
        containerView.frame = CGRectMake(0, 0, self.view.frame.size.width, 100);
        
        BFTipView *tipView = [[BFTipView alloc] init];
        tipView.frame = CGRectMake(12, 12, self.view.frame.size.width - 24, 200);
        tipView.style = BFTipViewStyleTable;
        tipView.dragToDismiss = false;
        tipView.object = [self messageOfTheDayNotificationObject];
        tipView.blurView.backgroundColor = [UIColor whiteColor];
        tipView.frame = CGRectMake(12, 12, self.view.frame.size.width - 24, tipView.frame.size.height);
        [tipView.closeButton bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
        [tipView.closeButton bk_whenTapped:^{
            [UIView animateWithDuration:.45f delay:0 usingSpringWithDamping:0.9f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                tipView.alpha = 0;
                tipView.transform = CGAffineTransformMakeScale(0.8, 0.8);
                
                [self.tableView beginUpdates];
                self.showUpsell = false;
                [self.tableView endUpdates];
            } completion:nil];
        }];
        containerView.frame = CGRectMake(0, 0, self.view.frame.size.width, tipView.frame.size.height + (12 * 2));
        [containerView addSubview:tipView];
        
        return containerView;
    }
    
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (BFTipObject *)messageOfTheDayNotificationObject {
    if (!self.showUpsell) return nil;
    
    if ([Session sharedInstance].defaults.feed.motd) {
        NSString *title = [Session sharedInstance].defaults.feed.motd.title;
        NSString *text = [Session sharedInstance].defaults.feed.motd.text;
        NSString *ctaDisplayText = [Session sharedInstance].defaults.feed.motd.cta.displayText;
        NSString *imageUrl = [Session sharedInstance].defaults.feed.motd.imageUrl;
        
        BFTipObject *tipObject = [BFTipObject tipWithCreatorType:BFTipCreatorTypeBonfireGeneric creator:nil title:title text:text cta:ctaDisplayText imageUrl:imageUrl action:^{
            NSLog(@"action");
            if ([Session sharedInstance].defaults.feed.motd.cta.actionUrl.length > 0) {
                [Launcher openURL:[Session sharedInstance].defaults.feed.motd.cta.actionUrl];
            }
        }];
        
        return tipObject;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section >= self.stream.activities.count) return;
    
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
            [Launcher openPost:post withKeyboard:NO];
        }
        else if (indexPath.row == 1) {
            // add a reply
            [Launcher openComposePost:post.attributes.postedIn inReplyTo:post withMessage:nil media:nil];
        }
    }
    else {
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
                    [Launcher openPost:activity.attributes.replyPost withKeyboard:NO];
                }
                else if ([notificationFormat.actionObject isEqualToString:ACTIVITY_ACTION_OBJECT_CAMP]) {
                    [Launcher openCamp:activity.attributes.camp];
                }
            }
        }
    }
}

@end
