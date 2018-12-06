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

#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>

#define envConfig [[[NSUserDefaults standardUserDefaults] objectForKey:@"config"] objectForKey:[[NSUserDefaults standardUserDefaults] stringForKey:@"environment"]]

@interface ProfileViewController () {
    int previousTableViewYOffset;
}

@property (nonatomic) BOOL loading;

@property CGFloat minHeaderHeight;
@property CGFloat maxHeaderHeight;

@property (strong, nonatomic) ErrorView *errorView;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.tintColor = self.theme;
    
    if ([self isCurrentUser] && [self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
        self.title = @"My Profile";
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userProfileUpdated:) name:@"UserUpdated" object:nil];
    }
    
    self.manager = [HAWebService manager];
    self.loading = true;
    
    [self loadUser];
}

- (BOOL)isCurrentUser {
    return [self.user.identifier isKindOfClass:[NSString class]] && [self.user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier];
}
- (BOOL)canViewPosts {
    return true;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self styleOnAppear];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)userProfileUpdated:(NSNotificationCenter *)sender {
    self.theme = [Session sharedInstance].themeColor;
    self.view.tintColor = self.theme;
    self.tableView.parentObject = [Session sharedInstance].currentUser;
    self.user = [Session sharedInstance].currentUser;
    
    [self.tableView refresh];
    [self updateTheme];
}

- (void)openProfileActions {
    BOOL userIsBlocked   = false;
    
    // Share to...
    // Turn on/off post notifications
    // Share on Instagram
    // Share on Twitter
    // Share on iMessage
    // Report Room
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"@%@", self.user.attributes.details.identifier] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    actionSheet.view.tintColor = [UIColor colorWithWhite:0.2f alpha:1];
    
    // 1.A.* -- Any user, any page, any following state
    UIAlertAction *shareUser = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Share %@ via...", [self isCurrentUser] ? @"your profile" : [NSString stringWithFormat:@"@%@", self.user.attributes.details.identifier]] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"share user");
        
        //[self showShareUserSheet];
    }];
    [actionSheet addAction:shareUser];
    
    if (![self isCurrentUser]) {
        UIAlertAction *blockUsername = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@", userIsBlocked ? @"Unblock" : @"Block"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // confirm action
            UIAlertController *alertConfirmController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ %@", userIsBlocked ? @"Unblock" : @"Block" , self.user.attributes.details.displayName] message:[NSString stringWithFormat:@"Are you sure you would like to block @%@?", self.user.attributes.details.identifier] preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *alertConfirm = [UIAlertAction actionWithTitle:userIsBlocked ? @"Unblock" : @"Block" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"switch user block state");
                if (userIsBlocked) {
                    [[Session sharedInstance] unblockUser:self.user completion:^(BOOL success, id responseObject) {
                        if (success) {
                            NSLog(@"success unblocking!");
                        }
                        else {
                            NSLog(@"error unblocking ;(");
                        }
                    }];
                }
                else {
                    [[Session sharedInstance] blockUser:self.user completion:^(BOOL success, id responseObject) {
                        if (success) {
                            NSLog(@"success blocking!");
                        }
                        else {
                            NSLog(@"error blocking ;(");
                        }
                    }];
                }
            }];
            [alertConfirmController addAction:alertConfirm];
            
            UIAlertAction *alertCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"cancel");
            }];
            [alertConfirmController addAction:alertCancel];
            
            [self.navigationController presentViewController:alertConfirmController animated:YES completion:nil];
        }];
        [actionSheet addAction:blockUsername];
        
        UIAlertAction *reportUsername = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Report"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // confirm action
            UIAlertController *saveAndOpenTwitterConfirm = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Report %@", self.user.attributes.details.displayName] message:[NSString stringWithFormat:@"Are you sure you would like to report @%@?", self.user.attributes.details.identifier] preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *alertConfirm = [UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"report user");
                [[Session sharedInstance] reportUser:self.user completion:^(BOOL success, id responseObject) {
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
            }];
            [saveAndOpenTwitterConfirm addAction:alertCancel];
            
            [self.navigationController presentViewController:saveAndOpenTwitterConfirm animated:YES completion:nil];
        }];
        [actionSheet addAction:reportUsername];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"cancel");
    }];
    [cancel setValue:self.theme forKey:@"titleTextColor"];
    [actionSheet addAction:cancel];
    
    [self.navigationController presentViewController:actionSheet animated:YES completion:nil];
}

- (void)setupErrorView {
    self.errorView = [[ErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100) title:@"Room Not Found" description:@"We couldn’t find the Room you were looking for" type:ErrorViewTypeNotFound];
    self.errorView.center = self.tableView.center;
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
    
    [self.errorView bk_whenTapped:^{
        NSError *userError;
        self.user = [[User alloc] initWithDictionary:[self.user toDictionary] error:&userError];
        
        if (userError || // room has error OR
            [self canViewPosts]) { // no error and can view posts
            self.errorView.hidden = true;
            
            self.tableView.loading = true;
            self.tableView.loadingMore = false;
            [self.tableView refresh];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self getPostsWithMaxId:0];
            });
        }
    }];
}

- (void)positionErrorView {
    ProfileHeaderCell *headerCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    CGFloat heightOfHeader = headerCell.frame.size.height;
    self.errorView.frame = CGRectMake(self.errorView.frame.origin.x, heightOfHeader + 64, self.errorView.frame.size.width, self.errorView.frame.size.height);
}

- (void)styleOnAppear {
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.tableView.center.y - bottomPadding);
}

- (void)loadUser {
    NSError *userError;
    self.user = [[User alloc] initWithDictionary:[self.user toDictionary] error:&userError];
    // [self mock];
    
    NSLog(@"loadProfile:");
    NSLog(@"self.user: %@", self.user);
    
    if (userError ||
        (![self isCurrentUser] && self.user.attributes.context == nil)) {
        // User requires context if not current User, even though it's Optional on the object
        
        // User object is fragmented – get User to fill in the pieces
        if (userError) {
            NSLog(@"user error::::");
            NSLog(@"%@", userError);
        }
        else {
            NSLog(@"context == nil");
        }
        
        // let's fetch info to fill in the gaps
        [self getUserInfo];
    }
    else {
        self.tableView.parentObject = self.user;
        [self loadUserContent];
    }
}

- (void)getUserInfo {
    NSString *url = [NSString stringWithFormat:@"%@/%@/users/%@", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], self.user.identifier];
    
    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            NSDictionary *params = @{};
            
            NSLog(@"url: %@", url);
            
            [self.manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSDictionary *responseData = (NSDictionary *)responseObject[@"data"];
                
                NSLog(@"response dataaaaa: %@", responseData);
                
                // this must go before we set self.room to the new Room object
                BOOL requiresColorUpdate = (self.user.attributes.details.color == nil);
                
                // first page
                self.user = [[User alloc] initWithDictionary:responseData error:nil];
                
                // update the theme color (in case we didn't know the room's color before
                if (requiresColorUpdate) {
                    [self updateTheme];
                }
                
                self.tableView.parentObject = self.user;
                [self.tableView refresh];
                
                // Now that the VC's Room object is complete,
                // Go on to load the room content
                [self loadUserContent];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"RoomViewController / getRoom() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                self.errorView.hidden = false;
                
                [self.errorView updateType:ErrorViewTypeGeneral];
                [self.errorView updateTitle:@"Error Loading"];
                [self.errorView updateDescription:@"Check your network settings and tap here to try again"];
                
                [self positionErrorView];
                
                self.loading = false;
                self.tableView.loading = false;
                self.tableView.error = true;
                [self.tableView refresh];
            }];
        }
    }];
}

- (void)updateTheme {
    UIColor *theme = [UIColor fromHex:self.user.attributes.details.color];
    
    if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
        [(ComplexNavigationController *)self.navigationController updateBarColor:theme withAnimation:1 statusBarUpdateDelay:0];
    }
    else if ([self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
        [(SimpleNavigationController *)self.navigationController updateBarColor:theme withAnimation:1 statusBarUpdateDelay:0];
    }
    
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
        
        [self positionErrorView];
    }
}

- (void)hideMoreButton {
    if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
        [(ComplexNavigationController *)self.navigationController setRightAction:LNActionTypeNone];
    }
    else if ([self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
        [(SimpleNavigationController *)self.navigationController setRightAction:SNActionTypeNone];
    }
}

- (void)getPostsWithMaxId:(NSInteger)maxId {
    if (self.user.identifier) {
        self.errorView.hidden = true;
        self.tableView.hidden = false;
        
        NSString *url = [NSString stringWithFormat:@"%@/%@/users/%@/posts", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], self.user.attributes.details.identifier]; // sample data
        
        [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
        [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
            if (success) {
                [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
                
                NSDictionary *params = maxId != 0 ? @{@"max_id": [NSNumber numberWithInteger:maxId], @"count": @(10)} : @{@"count": @(10)};
                NSLog(@"params to getPostsWith:::: %@", params);
                
                [self.manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    NSArray *responseData = (NSArray *)responseObject[@"data"];
                    
                    NSLog(@"ProfileViewController / getPosts() responseObject: %@", responseObject);
                    
                    self.tableView.scrollEnabled = true;
                    
                    if (maxId == 0) {
                        // first page
                        self.tableView.data = [[NSMutableArray alloc] initWithArray:responseData];
                        
                        if (self.tableView.data.count == 0) {
                            // Error: No posts yet!
                            self.errorView.hidden = false;
                            
                            ProfileHeaderCell *headerCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                            CGFloat heightOfHeader = headerCell.frame.size.height;
                            
                            NSLog(@"height of height: %f", heightOfHeader);
                            
                            [self.errorView updateType:ErrorViewTypeNoPosts];
                            [self.errorView updateTitle:@"No Posts Yet"];
                            [self.errorView updateDescription:@""];
                            
                            self.errorView.frame = CGRectMake(self.errorView.frame.origin.x, heightOfHeader + 72, self.errorView.frame.size.width, self.errorView.frame.size.height);
                        }
                        else {
                            self.errorView.hidden = true;
                        }
                    }
                    else {
                        self.errorView.hidden = true;
                        // appended posts
                        self.tableView.data = [[NSMutableArray alloc] initWithArray:[self.tableView.data arrayByAddingObjectsFromArray:responseData]];
                    }

                    self.loading = false;
                    
                    self.tableView.loading = false;
                    self.tableView.loadingMore = false;
                    
                    [self.tableView refresh];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    NSLog(@"FeedViewController / getPosts() - error: %@", error);
                    //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                    
                    if (self.tableView.data.count == 0) {
                        self.errorView.hidden = false;
                        
                        [self.errorView updateType:ErrorViewTypeGeneral];
                        [self.errorView updateTitle:@"Error Loading"];
                        [self.errorView updateDescription:@"Check your network settings and tap here to try again"];
                        
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
        }];
    }
    else {
        self.errorView.hidden = false;
        self.tableView.hidden = true;
        
        [self hideMoreButton];
    }
}

- (void)tableView:(id)tableView didRequestNextPageWithMaxId:(NSInteger)maxId {
    [self getPostsWithMaxId:maxId];
}

- (void)setupTableView {
    self.tableView = [[RSTableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.navigationController.navigationBar.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView.dataType = RSTableViewTypeProfile;
    self.tableView.parentObject = self.user;
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 48, 0);
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:self.tableView];
    
    UIView *headerHack = [[UIView alloc] initWithFrame:CGRectMake(0, -1 * self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    headerHack.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
    [self.tableView addSubview:headerHack];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
