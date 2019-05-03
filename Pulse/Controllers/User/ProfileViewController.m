//
//  ProfileViewController.m
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import "ProfileViewController.h"
#import "ComplexNavigationController.h"
#import "SimpleNavigationController.h"
#import "ErrorView.h"
#import "ProfileHeaderCell.h"
#import "UIColor+Palette.h"
#import "Launcher.h"
#import "SettingsTableViewController.h"
#import "InsightsLogger.h"
#import "ProfileCampsListViewController.h"
#import "HAWebService.h"

#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
@import Firebase;

@interface ProfileViewController () {
    int previousTableViewYOffset;
}

@property (nonatomic) BOOL loading;

@property CGFloat minHeaderHeight;
@property CGFloat maxHeaderHeight;

@property (strong, nonatomic) ErrorView *errorView;
@property (nonatomic) BOOL userDidRefresh;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.tintColor = self.theme;
    
    if ([self isCurrentUser] && [self.navigationController isKindOfClass:[SimpleNavigationController class]]) {

    }
    else {
        self.title = self.user.attributes.details.displayName;
    }
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.hidesBackButton = true;
    
    [self setupTableView];
    [self setupErrorView];
    if ([self isCurrentUser]) {
        //[self setupComposeInputView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostBegan:) name:@"NewPostBegan" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostCompleted:) name:@"NewPostCompleted" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostFailed:) name:@"NewPostFailed" object:nil];
    }
    else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userContextUpdated:) name:@"UserContextUpdated" object:nil];
    }
    
    self.loading = true;
    
    [self loadUser];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Profile" screenClass:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.view.tag == 1) {
        [InsightsLogger.sharedInstance openAllVisiblePostInsightsInTableView:self.tableView seenIn:InsightSeenInProfileView];
    }
    else {
        self.view.tag = 1;
    }
    
    [self styleOnAppear];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [InsightsLogger.sharedInstance closeAllVisiblePostInsightsInTableView:self.tableView];
}

- (void)newPostBegan:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil) {
        // TODO: Check for image as well
        self.errorView.hidden = true;
        [self.tableView.stream addTempPost:tempPost];
        [self.tableView refresh];
    }
}
- (void)newPostCompleted:(NSNotification *)notification {
    NSDictionary *info = notification.object;
    NSString *tempId = info[@"tempId"];
    Post *post = info[@"post"];
    
    if (post != nil) {
        // TODO: Check for image as well
        self.errorView.hidden = true;
        [self.tableView.stream updateTempPost:tempId withFinalPost:post];
        
        [self.tableView refresh];
    }
}
// TODO: Allow tap to retry for posts
- (void)newPostFailed:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil) {
        // TODO: Check for image as well
        [self.tableView.stream removeTempPost:tempPost.tempId];
        [self.tableView refresh];
        self.errorView.hidden = (self.tableView.stream.posts.count != 0);
    }
}

- (void)userUpdated:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[User class]]) {
        User *user = notification.object;
        if ([user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
            self.user = [Session sharedInstance].currentUser;
            self.tableView.parentObject = [Session sharedInstance].currentUser;
            
            [self.tableView.stream updateUserObjects:user];
            
            [self updateTheme];
            
            [self.tableView refresh];
        }
    }
}
- (void)userContextUpdated:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[User class]]) {
        User *user = notification.object;
        self.user = user;
        self.tableView.parentObject = self.user;
        
        [self.tableView.stream updateUserObjects:user];
        
        [self.tableView refresh];
    }
}

- (NSString *)userIdentifier {
    if (self.user.identifier != nil) return self.user.identifier;
    if (self.user.attributes.details.identifier != nil) return self.user.attributes.details.identifier;
    
    return nil;
}
- (NSString *)matchingCurrentUserIdentifier {
    // return matching identifier type for the current user
    if (self.user.identifier != nil) return [Session sharedInstance].currentUser.identifier;
    if (self.user.attributes.details.identifier != nil) return [Session sharedInstance].currentUser.attributes.details.identifier;
    
    return nil;
}

- (BOOL)isCurrentUser {
    return [self userIdentifier] != nil && [[self userIdentifier] isEqualToString:[self matchingCurrentUserIdentifier]];
}
- (BOOL)canViewPosts {
    return true;
}

- (void)openProfileActions {
    BOOL userIsBlocked = [self isCurrentUser] ? false : [self.user.attributes.context.status isEqualToString:USER_STATUS_BLOCKS];
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"\n\n\n\n\n\n" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    CGFloat margin = 8.0f;
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(margin, 0, actionSheet.view.bounds.size.width - margin * 4, 140.f)];
    BFAvatarView *roomAvatar = [[BFAvatarView alloc] initWithFrame:CGRectMake(customView.frame.size.width / 2 - 32, 24, 64, 64)];
    roomAvatar.user = self.user;
    [customView addSubview:roomAvatar];
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 96, customView.frame.size.width - 32, 20)];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    nameLabel.font = [UIFont systemFontOfSize:17.f weight:UIFontWeightSemibold];
    nameLabel.textColor = [UIColor blackColor];
    nameLabel.text = self.user.attributes.details.displayName;
    [customView addSubview:nameLabel];
    [actionSheet.view addSubview:customView];
    
    if (![self isCurrentUser] && ([self.user.attributes.context.status isEqualToString:USER_STATUS_FOLLOWS] || [self.user.attributes.context.status isEqualToString:USER_STATUS_FOLLOW_BOTH])) {
        BOOL userPostNotificationsOn = self.user.attributes.context.follow.me.subscription != nil;
        UIAlertAction *togglePostNotifications = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Turn %@ Post Notifications", userPostNotificationsOn ? @"Off" : @"On"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"toggle post notifications");
            // confirm action
            if ([Session sharedInstance].deviceToken != nil) {
                if (userPostNotificationsOn) {
                    [BFAPI unsubscribeFromUser:self.user completion:^(BOOL success, User *_Nullable user) {
                        if (success && user) {
                            self.user = user;
                            NSLog(@"user updated!");
                        }
                    }];
                }
                else {
                    [BFAPI subscribeToUser:self.user completion:^(BOOL success, User *_Nullable user) {
                        if (success && user) {
                            self.user = user;
                            NSLog(@"user updated! subscribed now....");
                        }
                    }];
                }
            }
            else {
                // confirm action
                UIAlertController *notificationsNotice = [UIAlertController alertControllerWithTitle:@"Notications Not Enabled" message:@"In order to enable Post Notifications, you must turn on notifications for Bonfire in the iOS Settings" preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *alertCancel = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                }];
                [notificationsNotice addAction:alertCancel];
                
                [self.navigationController presentViewController:notificationsNotice animated:YES completion:nil];
            }
        }];
        [actionSheet addAction:togglePostNotifications];
    }
    
    // 1.A.* -- Any user, any page, any following state
    UIAlertAction *shareUser = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Share %@ via...", [self isCurrentUser] ? @"your profile" : [NSString stringWithFormat:@"@%@", self.user.attributes.details.identifier]] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"share user");
        
        [[Launcher sharedInstance] shareUser:self.user];
    }];
    [actionSheet addAction:shareUser];
    
    if (![self isCurrentUser]) {
        UIAlertAction *blockUsername = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@", userIsBlocked ? @"Unblock" : @"Block"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // confirm action
            UIAlertController *alertConfirmController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ %@", userIsBlocked ? @"Unblock" : @"Block" , self.user.attributes.details.displayName] message:[NSString stringWithFormat:@"Are you sure you would like to block @%@?", self.user.attributes.details.identifier] preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *alertConfirm = [UIAlertAction actionWithTitle:userIsBlocked ? @"Unblock" : @"Block" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                if (userIsBlocked) {
                    [BFAPI unblockUser:self.user completion:^(BOOL success, id responseObject) {
                        if (success) {
                            // NSLog(@"success unblocking!");
                        }
                        else {
                            NSLog(@"error unblocking ;(");
                        }
                    }];
                }
                else {
                    [BFAPI blockUser:self.user completion:^(BOOL success, id responseObject) {
                        if (success) {
                            // NSLog(@"success blocking!");
                        }
                        else {
                            NSLog(@"error blocking ;(");
                        }
                    }];
                }
            }];
            [alertConfirmController addAction:alertConfirm];
            
            UIAlertAction *alertCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            [alertConfirmController addAction:alertCancel];
            
            [self.navigationController presentViewController:alertConfirmController animated:YES completion:nil];
        }];
        [actionSheet addAction:blockUsername];
        
        UIAlertAction *reportUsername = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Report"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // confirm action
            UIAlertController *saveAndOpenTwitterConfirm = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Report %@", self.user.attributes.details.displayName] message:[NSString stringWithFormat:@"Are you sure you would like to report @%@?", self.user.attributes.details.identifier] preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *alertConfirm = [UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"report user");
                [BFAPI reportUser:self.user completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // update the state to blocked
                        
                    }
                    else {
                        // error reporting user
                    }
                }];
            }];
            [saveAndOpenTwitterConfirm addAction:alertConfirm];
            
            UIAlertAction *alertCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"cancel report user");
                
                // TODO: Verify this closes both action sheets
            }];
            [saveAndOpenTwitterConfirm addAction:alertCancel];
            
            [self.navigationController presentViewController:saveAndOpenTwitterConfirm animated:YES completion:nil];
        }];
        [actionSheet addAction:reportUsername];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"cancel");
    }];
    [actionSheet addAction:cancel];
    
    [self.navigationController presentViewController:actionSheet animated:YES completion:nil];
}

- (void)setupErrorView {
    self.errorView = [[ErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100) title:@"User Not Found" description:@"We couldn’t find the User\nyou were looking for" type:ErrorViewTypeNotFound];
    self.errorView.center = self.tableView.center;
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
    
    [self.errorView bk_whenTapped:^{
        self.errorView.hidden = true;
        
        self.tableView.loading = true;
        self.tableView.loadingMore = false;
        [self.tableView refresh];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.user.identifier != nil && self.user.attributes.context != nil) {
                [self getPostsWithMaxId:0];
            }
            else {
                [self loadUser];
            }
        });
    }];
}

- (void)positionErrorView {
    ProfileHeaderCell *headerCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    CGFloat heightOfHeader = headerCell.frame.size.height;
    self.errorView.frame = CGRectMake(self.errorView.frame.origin.x, heightOfHeader + 64, self.errorView.frame.size.width, self.errorView.frame.size.height);
}

- (void)styleOnAppear {
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}

- (void)loadUser {
    self.tableView.parentObject = self.user;
    [self.tableView refresh];
    
    if (self.user.identifier == nil) {
        [self hideMoreButton];
    }
    else {
        [self showMoreButton];
    }
    
    // always fetch user info
    [self getUserInfo];
}

- (void)getUserInfo {
    NSString *url = [NSString stringWithFormat:@"users/%@", [self userIdentifier]];
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:@{} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *responseData = (NSDictionary *)responseObject[@"data"];
        
        NSLog(@"response data:: user:: %@", responseData);
        
        // this must go before we set self.room to the new Room object
        NSString *colorBefore = self.user.attributes.details.color;
        BOOL requiresColorUpdate = (colorBefore == nil || colorBefore.length == 0);
        
        // first page
        self.user = [[User alloc] initWithDictionary:responseData error:nil];
        if (![self isCurrentUser]) [[Session sharedInstance] addToRecents:self.user];
        [self showMoreButton];
        
        if ([self isCurrentUser]) {
            // if current user -> update Session current user object
            [[Session sharedInstance] updateUser:self.user];
        }
        
        // update the theme color (in case we didn't know the room's color before
        if (!([self isCurrentUser] && [self.navigationController isKindOfClass:[SimpleNavigationController class]])) {
            self.title = self.user.attributes.details.displayName;
            if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
                [((ComplexNavigationController *)self.navigationController).searchView updateSearchText:self.title];
            }
        }
        
        if (![colorBefore isEqualToString:self.user.attributes.details.color]) requiresColorUpdate = true;
        if (requiresColorUpdate) {
            [self updateTheme];
        }
        
        self.tableView.parentObject = self.user;
        [self.tableView refresh];
        
        // Now that the VC's Room object is complete,
        // Go on to load the room content
        [self loadUserContent];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"ProfileViewController / getUserInfo() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        self.errorView.hidden = false;
        
        NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
        NSInteger statusCode = httpResponse.statusCode;
        if (statusCode == 404) {
            [self.errorView updateTitle:@"User Not Found"];
            [self.errorView updateDescription:@"We couldn’t find the User\nyou were looking for"];
            [self.errorView updateType:ErrorViewTypeNotFound];
        }
        else {
            if ([HAWebService hasInternet]) {
                [self.errorView updateType:ErrorViewTypeGeneral];
                [self.errorView updateTitle:@"Error Loading"];
                [self.errorView updateDescription:@"Check your network settings and tap here to try again"];
            }
            else {
                [self.errorView updateType:ErrorViewTypeNoInternet];
                [self.errorView updateTitle:@"No Internet"];
                [self.errorView updateDescription:@"Check your network settings and tap here to try again"];
            }
        }
        
        self.loading = false;
        self.tableView.loading = false;
        self.tableView.error = true;
        [self.tableView refresh];
        
        [self positionErrorView];
    }];
}

- (void)updateTheme {
    UIColor *theme = [UIColor fromHex:self.user.attributes.details.color];
    
    if (self.navigationController.topViewController == self) {
        if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
            [(ComplexNavigationController *)self.navigationController updateBarColor:theme withAnimation:1 statusBarUpdateDelay:0];
        }
        else if ([self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
            [(SimpleNavigationController *)self.navigationController updateBarColor:theme];
        }
    }
    
    [self.navigationController setNeedsStatusBarAppearanceUpdate];
    
    self.theme = theme;
    self.view.tintColor = self.theme;
}

- (void)loadUserContent {
    if ([self canViewPosts]) {
        [self getPostsWithMaxId:0];
    }
    else {
        self.errorView.hidden = false;
        
        self.loading = false;
        self.tableView.loading = false;
        self.tableView.loadingMore = false;
        [self.tableView refresh];
        
        BOOL isBlocked = false;
        BOOL isPrivate = false;
        
        if (isBlocked) { // blocked by User
            [self.errorView updateTitle:[NSString stringWithFormat:@"@%@ Blocked You", self.user.attributes.details.identifier]];
            [self.errorView updateDescription:[NSString stringWithFormat:@"You are blocked from viewing and interacting with %@", self.user.attributes.details.displayName]];
            [self.errorView updateType:ErrorViewTypeLocked];
        }
        else if (isPrivate) { // not blocked, not follower
            // private room but not a member yet
            [self.errorView updateTitle:@"Private User"];
            [self.errorView updateDescription:[NSString stringWithFormat:@"Only confirmed followers have access to @%@'s posts and complete profile", self.user.attributes.details.identifier]];
            [self.errorView updateType:ErrorViewTypeLocked];
        }
        else {
            [self.errorView updateTitle:@"User Not Found"];
            [self.errorView updateDescription:@"We couldn’t find the User\nyou were looking for"];
            [self.errorView updateType:ErrorViewTypeNotFound];
            
            [self hideMoreButton];
        }
    }
    
    [self positionErrorView];
}

- (void)hideMoreButton {
    self.navigationController.navigationItem.rightBarButtonItem.customView.alpha = 0;
}
- (void)showMoreButton {
    self.navigationController.navigationItem.rightBarButtonItem.customView.alpha = 1;
}

- (void)getPostsWithMaxId:(NSInteger)maxId {
    if ([self userIdentifier] != nil) { 
        self.errorView.hidden = true;
        self.tableView.hidden = false;
                
        NSString *url = [NSString stringWithFormat:@"users/%@/posts", [self userIdentifier]]; // sample data
        
        NSDictionary *params = maxId != 0 ? @{@"max_id": [NSNumber numberWithInteger:maxId]} : @{};
        // NSLog(@"params to getPostsWith:::: %@", params);
        
        [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            self.tableView.scrollEnabled = true;
            
            if (self.userDidRefresh) {
                self.userDidRefresh = false;
                self.tableView.stream.posts = @[];
                self.tableView.stream.pages = [[NSMutableArray alloc] init];
            }
            
            PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:responseObject error:nil];
            if (page.data.count == 0) {
                self.tableView.reachedBottom = true;
            }
            else {
                [self.tableView.stream appendPage:page];
            }
            
            if (self.tableView.stream.posts.count == 0) {
                // Error: No posts yet!
                self.errorView.hidden = false;
                
                ProfileHeaderCell *headerCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                CGFloat heightOfHeader = headerCell.frame.size.height;
                
                [self.errorView updateType:ErrorViewTypeNoPosts];
                [self.errorView updateTitle:@"No Posts Yet"];
                [self.errorView updateDescription:@""];
                
                self.errorView.frame = CGRectMake(self.errorView.frame.origin.x, heightOfHeader + 72, self.errorView.frame.size.width, self.errorView.frame.size.height);
            }
            else {
                self.errorView.hidden = true;
            }
            
            self.loading = false;
            
            self.tableView.loading = false;
            self.tableView.loadingMore = false;
            
            [self.tableView refresh];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"ProfileViewController / getPostsWithMaxId() - error: %@", error);
            //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            
            if (self.tableView.stream.posts.count == 0) {
                self.errorView.hidden = false;
                
                if ([HAWebService hasInternet]) {
                    [self.errorView updateType:ErrorViewTypeGeneral];
                    [self.errorView updateTitle:@"Error Loading"];
                    [self.errorView updateDescription:@"Check your network settings and tap here to try again"];
                }
                else {
                    [self.errorView updateType:ErrorViewTypeNoInternet];
                    [self.errorView updateTitle:@"No Internet"];
                    [self.errorView updateDescription:@"Check your network settings and tap here to try again"];
                }
                
                [self positionErrorView];
            }
            
            self.loading = false;
            self.tableView.loading = false;
            self.tableView.loadingMore = false;
            self.tableView.userInteractionEnabled = true;
            self.tableView.scrollEnabled = false;
            [self.tableView refresh];
        }];
    }
    else {
        self.loading = false;
        self.tableView.loading = false;
        self.tableView.loadingMore = false;
        self.tableView.userInteractionEnabled = true;
        self.tableView.scrollEnabled = false;
        [self.tableView refresh];
    }
}

- (void)tableView:(id)tableView didRequestNextPageWithMaxId:(NSInteger)maxId {
    [self getPostsWithMaxId:maxId];
}

- (void)setupTableView {
    self.tableView = [[RSTableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.navigationController.navigationBar.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView.dataType = RSTableViewTypeProfile;
    self.tableView.parentObject = self.user;
    self.tableView.loading = true;
    self.tableView.paginationDelegate = self;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.tag = 101;
    [self.tableView.refreshControl addTarget:self
                                action:@selector(refresh)
                      forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.tableView];
    
    UIView *headerHack = [[UIView alloc] initWithFrame:CGRectMake(0, -1 * self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    headerHack.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
    //[self.tableView insertSubview:headerHack atIndex:0];
}
- (void)refresh {
    NSLog(@"refresh profile view controller");
    self.userDidRefresh = true;
    self.tableView.reachedBottom = false;
    [self loadUser];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
