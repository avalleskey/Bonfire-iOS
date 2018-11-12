//
//  RoomViewController.m
//  
//
//  Created by Austin Valleskey on 9/19/18.
//

#import "RoomViewController.h"
#import "LauncherNavigationViewController.h"
#import "ErrorView.h"
#import <Messages/Messages.h>
#import <MessageUI/MessageUI.h>
#import "SearchResultCell.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "RoomHeaderCell.h"
#import "ProfileViewController.h"

#define envConfig [[[NSUserDefaults standardUserDefaults] objectForKey:@"config"] objectForKey:[[NSUserDefaults standardUserDefaults] stringForKey:@"environment"]]

@interface RoomViewController () {
    int previousTableViewYOffset;
}

@property (nonatomic) BOOL loading;

@property CGFloat minHeaderHeight;
@property CGFloat maxHeaderHeight;
@property BOOL isLoadingMyRooms;

@property (strong, nonatomic) LauncherNavigationViewController *launchNavVC;
@property (strong, nonatomic) UITableView *roomSelectorTableView;
@property (strong, nonatomic) NSMutableArray *roomSearchResults;
@property (strong, nonatomic) NSMutableArray *myRoomsResults;
@property (strong, nonatomic) ErrorView *errorView;

@end

@implementation RoomViewController

static NSString * const reuseIdentifier = @"Result";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.launchNavVC = (LauncherNavigationViewController *)self.navigationController;
    
    [self mock];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];
    
    [self setupTableView];
    [self setupErrorView];
    
    self.manager = [HAWebService manager];
    
    [self setupComposeInputView];
    
    if (self.isCreatingPost) {
        self.tableView.hidden = true;
        [self createRoomSelectorTableView];
        [self getMyRooms];
        
        [self.composeInputView.textView becomeFirstResponder];
    }
    else {
        self.title = self.room.attributes.details.title;
        self.view.tintColor = self.theme;
        
        [self loadRoom];
    }
}

- (void)loadRoom {
    NSError *roomError;
    self.room = [[Room alloc] initWithDictionary:[self.room toDictionary] error:&roomError];
    [self mock];
    
    if (roomError) {
        // Room object is fragmented – get Room to fill in the pieces
        NSLog(@"room error::::");
        NSLog(@"%@", roomError);
        
        // let's fetch info to fill in the gaps
        self.composeInputView.hidden = true;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self getRoomInfo];
        });
    }
    else {
        self.tableView.parentObject = self.room;
        [self loadRoomContent];
    }
}
- (void)loadRoomContent {
    if ([self canViewPosts]) {
        self.composeInputView.hidden = false;
        
        [self getPostsWithSinceId:0];
    }
    else {
        self.composeInputView.hidden = true;
        
        self.errorView.hidden = false;
        
        self.loading = false;
        self.tableView.loading = false;
        self.tableView.loadingMore = false;
        [self.tableView refresh];
        
        if (self.room.attributes.status.isBlocked) { // Room has been blocked
            [self.errorView updateTitle:@"Room Not Available"];
            [self.errorView updateDescription:@"This Room is no longer available"];
            [self.errorView updateType:ErrorViewTypeBlocked];
        }
        else if (self.room.attributes.context.status == STATUS_BLOCKED) { // blocked from Room
            [self.errorView updateTitle:@"Blocked By Room"];
            [self.errorView updateDescription:@"Your account is blocked from creating and viewing posts in this Room"];
            [self.errorView updateType:ErrorViewTypeBlocked];
        }
        else if (self.room.attributes.status.discoverability.isPrivate) { // not blocked, not member
            // private room but not a member yet
            [self.errorView updateTitle:@"Private Room"];
            [self.errorView updateDescription:@"Request access above to get access to this Room’s posts"];
            [self.errorView updateType:ErrorViewTypeLocked];
        }
        else {
            [self.errorView updateTitle:@"Room Not Found"];
            [self.errorView updateDescription:@"We couldn’t find the Room\nyou were looking for"];
            [self.errorView updateType:ErrorViewTypeNotFound];
            
            [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.launchNavVC.infoButton.alpha = 0;
                self.launchNavVC.moreButton.alpha = 0;
            } completion:^(BOOL finished) {
            }];
        }
        
        [self positionErrorView];
    }
}
- (void)updateTheme {
    UIColor *theme = [self colorFromHexString:self.room.attributes.details.color];
    
    [self.launchNavVC updateBarColor:theme withAnimation:1 statusBarUpdateDelay:0];
    [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.composeInputView.textView.tintColor = theme;
        self.composeInputView.addMediaButton.tintColor = theme;
        self.composeInputView.postButton.tintColor = theme;
    } completion:^(BOOL finished) {
    }];
    
    self.theme = theme;
    self.view.tintColor = self.theme;
}

- (void)getRoomInfo {
    NSString *url = [NSString stringWithFormat:@"%@/%@/rooms/%@", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], self.room.identifier];
    
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
                BOOL requiresColorUpdate = (self.room.attributes.details.color == nil);
                
                // first page
                self.room = [[Room alloc] initWithDictionary:responseData error:nil];
                
                // update the theme color (in case we didn't know the room's color before
                if (requiresColorUpdate) {
                    [self updateTheme];
                }
                
                // update the title (in case we didn't know the room's title before)
                [self.launchNavVC updateSearchText:self.room.attributes.details.title];
                
                // update the compose input placeholder (in case we didn't know the room's title before)
                [self.composeInputView updatePlaceholders];
                
                self.tableView.parentObject = self.room;
                [self.tableView refresh];
                
                // Now that the VC's Room object is complete,
                // Go on to load the room content
                [self loadRoomContent];
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
                [self.tableView refresh];
            }];
        }
    }];
}

- (void)mock {
    /* mimic being invited
    RoomContext *context = [[RoomContext alloc] initWithDictionary:[self.room.attributes.context toDictionary] error:nil];
    context.status = STATUS_BLOCKED;
    self.room.attributes.context = context;*/
    
    /* mimic private room
    RoomDiscoverability *discoverability = [[RoomDiscoverability alloc] initWithDictionary:[self.room.attributes.status.discoverability toDictionary] error:nil];
    discoverability.isPrivate = true;
    self.room.attributes.status.discoverability = discoverability;*/
    
    // mimic Room being blocked
    /*RoomStatus *status = [[RoomStatus alloc] initWithDictionary:[self.room.attributes.status toDictionary] error:nil];
    status.isBlocked = true;
    self.room.attributes.status = status;*/
    
    /* mimic opening Room with Room hash identifier only
    Room *room = [[Room alloc] init];
    room.identifier = @"-OJkNgx4gZoGB";
    
    self.room = room;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.launchNavVC updateBarColor:@"707479" withAnimation:0 statusBarUpdateDelay:0];
        [self.launchNavVC updateSearchText:@"Loading..."];
    });
    self.theme = [self colorFromHexString:@"707479"];*/
    
    /* mimic opening Room with Room identifier only
    Room *room = [[Room alloc] init];
    room.attributes.details.identifier = @"NewRoom";

    self.room = room;*/
}
    
- (void)createRoomSelectorTableView {
    self.roomSelectorTableView = [[UITableView alloc] initWithFrame:self.tableView.bounds style:UITableViewStylePlain];
    self.roomSelectorTableView.delegate = self;
    self.roomSelectorTableView.dataSource = self;
    self.roomSelectorTableView.backgroundColor = [UIColor whiteColor];
    self.roomSelectorTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.roomSelectorTableView.separatorInset = UIEdgeInsetsMake(0, self.view.frame.size.width, 0, 0);
    self.roomSelectorTableView.separatorColor = [UIColor colorWithWhite:0.85 alpha:1];
    self.roomSelectorTableView.alpha = 1;
    self.roomSelectorTableView.hidden = false;
    [self.roomSelectorTableView registerClass:[SearchResultCell class] forCellReuseIdentifier:reuseIdentifier];
    [self.view insertSubview:self.roomSelectorTableView belowSubview:self.composeInputView];
    
    [self.launchNavVC.textField bk_addEventHandler:^(id sender) {
        if (self.isCreatingPost) {
            if (self.launchNavVC.textField.text.length == 0) {
                [self.roomSelectorTableView reloadData];
            }
            else {
                [self getSearchResults];
            }
        }
    } forControlEvents:UIControlEventEditingChanged];
    [self.launchNavVC.textField bk_addEventHandler:^(id sender) {
        if (self.isCreatingPost && self.roomSelectorTableView.alpha == 0) {
            self.room = nil;
            self.tableView.data = [[NSMutableArray alloc] init];
            self.loading = true;
            
            self.composeInputView.addMediaButton.tintColor = [Session sharedInstance].themeColor;
            self.composeInputView.postButton.tintColor = [Session sharedInstance].themeColor;
            self.composeInputView.textView.tintColor  = [Session sharedInstance].themeColor;
            [self.composeInputView updatePlaceholders];
            
            self.tableView.loading = true;
            [self.tableView refresh];

            self.launchNavVC.textField.text = @"";
            self.launchNavVC.textField.textAlignment = NSTextAlignmentCenter;
            
            [self.launchNavVC updateBarColor:[UIColor whiteColor] withAnimation:1 statusBarUpdateDelay:NO];
            self.launchNavVC.moreButton.alpha = 0;
            self.launchNavVC.backButton.tintColor = [Session sharedInstance].themeColor;
            
            [self.roomSelectorTableView reloadData];
            
            [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.roomSelectorTableView.transform = CGAffineTransformMakeScale(1, 1);
                self.roomSelectorTableView.alpha = 1;
                
                self.tableView.alpha = 0;
                self.tableView.transform = CGAffineTransformMakeScale(0.9, 0.9);
            } completion:^(BOOL finished) {
            }];
        }
        
    } forControlEvents:UIControlEventEditingDidBegin];
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"viewWillAppear::::::");
    [self styleOnAppear];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)setupErrorView {
    self.errorView = [[ErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100) title:@"Room Not Found" description:@"We couldn’t find the Room you were looking for" type:ErrorViewTypeNotFound];
    self.errorView.center = self.tableView.center;
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
    
    [self.errorView bk_whenTapped:^{
        NSError *roomError;
        self.room = [[Room alloc] initWithDictionary:[self.room toDictionary] error:&roomError];
        
        if (roomError || // room has error OR
            [self canViewPosts]) { // no error and can view posts
            self.errorView.hidden = true;
            
            self.tableView.loading = true;
            self.tableView.loadingMore = false;
            [self.tableView refresh];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self getPostsWithSinceId:0];
            });
        }
    }];
}


- (void)setupComposeInputView {
    self.composeInputView = [[ComposeInputView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    self.composeInputView.frame = CGRectMake(0, self.view.frame.size.height - 52, self.view.frame.size.width, 190);
    self.composeInputView.parentViewController = self;
    self.composeInputView.postButton.tintColor = [self.theme isEqual:[UIColor whiteColor]] ? [UIColor colorWithWhite:0.2f alpha:1] : self.theme;
    self.composeInputView.addMediaButton.tintColor = self.composeInputView.postButton.tintColor;
    self.composeInputView.textView.tintColor = self.composeInputView.postButton.tintColor;
    
    [self.composeInputView bk_whenTapped:^{
        if (![self.composeInputView isActive]) {
            [self.composeInputView setActive:true];
        }
    }];
    [self.composeInputView.postButton bk_whenTapped:^{
        [self postMessage];
    }];
    
    [self.view addSubview:self.composeInputView];
    
    self.composeInputView.textView.delegate = self;
    self.composeInputView.tintColor = self.view.tintColor;
}
- (void)textViewDidChange:(UITextView *)textView {
    if ([textView isEqual:self.composeInputView.textView]) {
        NSLog(@"text view did change");
        [self.composeInputView resize:false];
        
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        CGFloat bottomPadding = window.safeAreaInsets.bottom;
        
        self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, self.view.frame.size.height - self.currentKeyboardHeight - self.composeInputView.frame.size.height + bottomPadding, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
        
        if (textView.text.length > 0) {
            [self.composeInputView showPostButton];
        }
        else {
            [self.composeInputView hidePostButton];
        }
    }
}

- (void)postMessage {
    NSString *url = [NSString stringWithFormat:@"%@/%@/rooms/%@/posts", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], self.room.identifier];
    
    NSLog(@"url: %@", url);
    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (self.composeInputView.textView.text.length > 0) {
        [params setObject:self.composeInputView.textView.text forKey:@"message"];
        self.composeInputView.textView.text = @"";
        [self.composeInputView.textView resignFirstResponder];
        self.composeInputView.media = [[NSMutableArray alloc] init];
        [self.composeInputView hideMediaTray];
    }
    
    if ([params objectForKey:@"message"]) {
        [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
            if (success) {
                NSLog(@"token::: %@", token);
                [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
                [self.manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    NSLog(@"CommonTableViewController / getPosts() success! ✅");
                    
                    NSArray *responseData = (NSArray *)responseObject[@"data"];
                    
                    NSLog(@"responsedata: %@", responseData);
                    
                    // scroll to top if neccessary
                    RoomHeaderCell *headerCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                    CGFloat heightOfHeader = headerCell.frame.size.height;
                    if (self.tableView.contentOffset.y > heightOfHeader) {
                        // we need to scroll to the top!
                        [self.tableView setContentOffset:CGPointMake(0, heightOfHeader) animated:YES];
                    }
                    
                    self.room.attributes.summaries.counts.posts = self.room.attributes.summaries.counts.posts + 1;
                    self.tableView.parentObject = self.room;
                    
                    [self.tableView refresh];
                    [self getPostsWithSinceId:0];
                    [self.view endEditing:true];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    NSLog(@"FeedViewController / getPosts() - error: %@", error);
                    //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                    
                    self.loading = false;
                    self.tableView.userInteractionEnabled = true;
                    [self.tableView reloadData];
                }];
            }
        }];
        
        // reset isCreatingPost (if neccessary)
        if (self.isCreatingPost) {
            [self turnOffComposeMode];
            
            if (!self.room.identifier) {
                // share with everyone...
                
                ProfileViewController *p = [[ProfileViewController alloc] init];
                // NSLog(@"channel: %@", room);
                // p.room = [[Room alloc] initWithObject:room];
                User *myUser = [Session sharedInstance].currentUser;
                
                p.theme = [self colorFromHexString:myUser.attributes.details.color.length == 6 ? myUser.attributes.details.color : @"0076ff"]; //[self colorFromHexString:user.attributes.details.color];
                // r.tableView.delegate = self;
                p.user = myUser;
                
                self.launchNavVC.textField.text = p.user.attributes.details.displayName;
                
                [self.launchNavVC updateBarColor:p.theme withAnimation:2 statusBarUpdateDelay:NO];
                
                [self.launchNavVC setViewControllers:[NSArray arrayWithObject:p]
                                            animated:NO];
                
                [self.launchNavVC updateNavigationBarItemsWithAnimation:YES];
            }
        }
    }
}

- (void)styleOnAppear {
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    CGFloat collapsed_inputViewHeight = ((self.composeInputView.textView.frame.origin.y * 2) + self.composeInputView.textView.frame.size.height) + bottomPadding;
    
    self.composeInputView.frame = CGRectMake(0, self.view.bounds.size.height - collapsed_inputViewHeight, self.view.bounds.size.width, collapsed_inputViewHeight);
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.composeInputView.frame.size.height, 0);
}

- (BOOL)canViewPosts {
    return self.room.identifier != nil && // has an ID
           !self.room.attributes.status.isBlocked && // Room not blocked
           self.room.attributes.context.status != STATUS_BLOCKED && // User blocked by Room
           (!self.room.attributes.status.discoverability.isPrivate || // (public room OR
            self.room.attributes.context.status == STATUS_MEMBER);    //  private and member)
}

- (void)getPostsWithSinceId:(NSInteger)sinceId {
    self.errorView.hidden = true;
    self.tableView.hidden = false;
    
    NSString *url = [NSString stringWithFormat:@"%@/%@/rooms/%@/stream", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], self.room.identifier];
    
    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            NSDictionary *params = sinceId != 0 ? @{@"since_id": [NSNumber numberWithInteger:sinceId]} : nil;
            NSLog(@"params to getPostsWith:::: %@", params);
            
            [self.manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSArray *responseData = (NSArray *)responseObject[@"data"];
                
                self.tableView.scrollEnabled = true;
                
                if (sinceId == 0) {
                    // first page
                    self.tableView.data = [[NSMutableArray alloc] initWithArray:responseData];
                    
                    if (self.tableView.data.count == 0) {
                        // Error: No posts yet!
                        self.errorView.hidden = false;
                        
                        RoomHeaderCell *headerCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
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
- (void)positionErrorView {
    RoomHeaderCell *headerCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    CGFloat heightOfHeader = headerCell.frame.size.height;
    self.errorView.frame = CGRectMake(self.errorView.frame.origin.x, heightOfHeader + 64, self.errorView.frame.size.width, self.errorView.frame.size.height);
}
- (void)setupTableView {
    self.tableView = [[RSTableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.navigationController.navigationBar.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView.dataType = tableCategoryRoom;
    self.tableView.parentObject = self.room;
    self.tableView.loading = true;
    self.tableView.paginationDelegate = self;
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 60, 0);
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 60, 0);
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:self.tableView];
    
    UIView *headerHack = [[UIView alloc] initWithFrame:CGRectMake(0, -1 * self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    headerHack.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
    [self.tableView addSubview:headerHack];
}

- (void)tableView:(id)tableView didRequestNextPageWithSinceId:(NSInteger)sinceId {
    NSLog(@"RoomViewController:: didRequestNextPageWithSinceID: %ld", (long)sinceId);
    [self getPostsWithSinceId:sinceId];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    UIView *tapToDismissView = [self.view viewWithTag:888];
    if (!tapToDismissView) {
        tapToDismissView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, self.tableView.frame.size.height)];
        tapToDismissView.tag = 888;
        tapToDismissView.alpha = 0;
        tapToDismissView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.75];
        
        [self.view insertSubview:tapToDismissView aboveSubview:self.tableView];
    }
    
    self.tableView.scrollEnabled = false;
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        tapToDismissView.alpha = 1;
    } completion:nil];
    
    
    [tapToDismissView bk_whenTapped:^{
        [textView resignFirstResponder];
    }];
    UISwipeGestureRecognizer *swipeDownGesture = [[UISwipeGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        [textView resignFirstResponder];
    }];
    swipeDownGesture.direction = UISwipeGestureRecognizerDirectionDown;
    [tapToDismissView addGestureRecognizer:swipeDownGesture];
    
    return true;
}
- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    if (!self.isCreatingPost) {
        UIView *tapToDismissView = [self.view viewWithTag:888];
        
        if (self.loading) {
            self.tableView.scrollEnabled = false;
        }
        else {
            self.tableView.scrollEnabled = true;
        }

        [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            tapToDismissView.alpha = 0;
        } completion:^(BOOL finished) {
            [tapToDismissView removeFromSuperview];
        }];
    }
    
    return true;
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    _currentKeyboardHeight = keyboardFrameBeginRect.size.height;
    
    NSLog(@"keyboard will change frame");
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, self.view.frame.size.height - self.currentKeyboardHeight - self.composeInputView.frame.size.height + bottomPadding, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.composeInputView.frame.size.height - bottomPadding, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
}

- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        [self.composeInputView resize:false];
        
        self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, self.view.frame.size.height - self.composeInputView.frame.size.height, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
        
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.composeInputView.frame.size.height - bottomPadding, 0);
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    } completion:nil];
}

- (void)getMyRooms {
    self.isLoadingMyRooms = true;
    
    NSString *url = [NSString stringWithFormat:@"%@/%@/users/me/rooms", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
    
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            [self.manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"RoomViewController / getMyRooms() success! ✅");
                
                NSLog(@"response: %@", responseObject[@"data"]);
                
                NSArray *responseData = (NSArray *)responseObject[@"data"];
                
                self.isLoadingMyRooms = false;
                
                self.roomSearchResults = [[NSMutableArray alloc] init];
                self.myRoomsResults = [[NSMutableArray alloc] initWithArray:responseData];
                
                [self.roomSelectorTableView reloadData];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"MyRoomsViewController / getRooms() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                self.isLoadingMyRooms = false;
                
                [self.roomSelectorTableView reloadData];
            }];
        }
    }];
}
- (void)getSearchResults {
    NSLog(@"getSearchResults()");
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            NSString *url = [NSString stringWithFormat:@"%@/%@/search/rooms", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
            [self.manager GET:url parameters:@{@"q": self.launchNavVC.textField.text} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"LauncherNavigationViewController / getSearchResults() success! ✅");
                
                NSLog(@"response: %@", responseObject[@"data"][@"results"][@"rooms"]);

                NSArray *responseData = (NSArray *)responseObject[@"data"][@"results"][@"rooms"];
                
                self.roomSearchResults = [[NSMutableArray alloc] initWithArray:responseData];
                
                [self.roomSelectorTableView reloadData];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"FeedViewController / getPosts() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                [self.roomSelectorTableView reloadData];
            }];
        }
    }];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[SearchResultCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    }
    
    BOOL highlighted = false;
    /*
    if ([self showRecents] && indexPath.section == 0 && indexPath.row == 0) {
        highlighted = true;
    }
    else {
        if (roomsResults && indexPath.section == 1 && indexPath.row == 0) {
            // has at least one room
            highlighted = true;
        }
        else if (!roomsResults && userResults && indexPath.section == 2 && indexPath.row == 0) {
            highlighted = true;
        }
    }*/
    
    if (highlighted) {
        cell.selectionBackground.hidden = false;
        cell.lineSeparator.hidden = true;
    }
    else {
        cell.selectionBackground.hidden = true;
        cell.lineSeparator.hidden = false;
    }
    
    NSDictionary *json = self.launchNavVC.textField.text.length == 0 ? self.myRoomsResults[indexPath.row] : self.roomSearchResults[indexPath.row];
    
    Room *room = [[Room alloc] initWithDictionary:json error:nil];
    // 1 = Room
    cell.textLabel.text = room.attributes.details.title;
    cell.imageView.backgroundColor = [self colorFromHexString:room.attributes.details.color];
    
    BOOL useLiveCount = false;
    if (useLiveCount) {
        cell.detailTextLabel.textColor = [UIColor colorWithDisplayP3Red:0.87 green:0.09 blue:0.09 alpha:1];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%li LIVE", (long)room.attributes.summaries.counts.live];
    }
    else {
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld %@", (long)room.attributes.summaries.counts.members, (room.attributes.summaries.counts.members == 1 ? @"MEMBER" : @"MEMBERS")];
    }
    
    cell.type = 1;
    
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *roomJSON = self.launchNavVC.textField.text.length == 0 ? self.myRoomsResults[indexPath.row] : self.roomSearchResults[indexPath.row];
    Room *room = [[Room alloc] initWithDictionary:roomJSON error:nil];
    self.room = room;
    
    self.tableView.hidden = false;
    self.tableView.alpha = 0;
    self.tableView.transform = CGAffineTransformMakeScale(0.9, 0.9);
    self.tableView.parentObject = self.room;
    [self.tableView refresh];
    
    self.title = self.room.attributes.details.title;
    self.theme = [self colorFromHexString:self.room.attributes.details.color.length == 6 ? self.room.attributes.details.color : @"0076ff"];
    self.view.tintColor = self.theme;
    
    [self getPostsWithSinceId:0];
    
    // fancy text field text
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"To: %@", self.room.attributes.details.title]];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:1 alpha:0.5] range:NSMakeRange(0,4)];
    [string addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:self.launchNavVC.textField.font.pointSize weight:UIFontWeightRegular] range:NSMakeRange(0,4)];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(4,self.room.attributes.details.title.length)];
    self.launchNavVC.textField.attributedText = string;
    
    [self.launchNavVC textFieldDidEndEditing:self.launchNavVC.textField];
    [self.composeInputView.textView becomeFirstResponder];
    
    UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40, self.launchNavVC.textField.frame.size.height)];
    UIImageView *clearButton = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 14, 14)];
    clearButton.center = CGPointMake(rightView.frame.size.width / 2, rightView.frame.size.height / 2);
    clearButton.image = [[UIImage imageNamed:@"navCloseIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    clearButton.tintColor = [UIColor whiteColor];
    [rightView addSubview:clearButton];
    self.launchNavVC.textField.rightView = rightView;
    
    self.composeInputView.postButton.tintColor = self.theme;
    self.composeInputView.tintColor = self.theme;
    self.composeInputView.textView.tintColor  = self.theme;
    self.composeInputView.addMediaButton.tintColor = self.theme;
    [self.composeInputView updatePlaceholders];
    
    [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.roomSelectorTableView.transform = CGAffineTransformMakeScale(0.9, 0.9);
        self.roomSelectorTableView.alpha = 0;
        
        self.tableView.alpha = 1;
        self.tableView.transform = CGAffineTransformMakeScale(1, 1);
    } completion:^(BOOL finished) {
    }];
    [self.roomSelectorTableView reloadData];
    
    [self.launchNavVC updateBarColor:self.view.tintColor withAnimation:YES statusBarUpdateDelay:NO];
    [self.launchNavVC updateNavigationBarItemsWithAnimation:YES];
}
- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    if (hexString != nil && hexString.length == 6) {
        NSScanner *scanner = [NSScanner scannerWithString:hexString];
        [scanner setScanLocation:0]; // bypass '#' character
        [scanner scanHexInt:&rgbValue];
        return [UIColor colorWithDisplayP3Red:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
    }
    else {
        return [UIColor colorWithWhite:0.2f alpha:1];
    }
}

- (void)turnOffComposeMode {
    self.isCreatingPost = false;
    self.launchNavVC.isCreatingPost = false;
    [self.launchNavVC updateNavigationBarItemsWithAnimation:YES];
    self.launchNavVC.textField.textAlignment = NSTextAlignmentCenter;
    self.launchNavVC.textField.rightView = self.launchNavVC.textField.leftView; // remove pencil icon
    if (self.launchNavVC.textField.text.length > 4 && [[self.launchNavVC.textField.text substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"To: "]) {
        self.launchNavVC.textField.text = [self.launchNavVC.textField.text substringWithRange:NSMakeRange(4, self.launchNavVC.textField.text.length-4)];
    }
    
    UIView *tapToDismissView = [self.view viewWithTag:888];
    self.tableView.scrollEnabled = true;
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        tapToDismissView.alpha = 0;
    } completion:^(BOOL finished) {
        [tapToDismissView removeFromSuperview];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.launchNavVC.textField.text.length == 0 ? self.myRoomsResults.count : self.roomSearchResults.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat headerHeight = 50;
    
    return headerHeight;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 24, self.view.frame.size.width - 32, 19)];
    if (self.launchNavVC.textField.text.length == 0) {
        if (self.isLoadingMyRooms) {
            title.text = @"Loading...";
            title.textAlignment = NSTextAlignmentCenter;
        }
        else {
            if (self.myRoomsResults.count == 0) {
                title.text = @"";
                title.textAlignment = NSTextAlignmentCenter;
            }
            else {
                title.text = @"My Rooms";
                title.textAlignment = NSTextAlignmentLeft;
            }
        }
    }
    else {
        title.text = @"Suggestions";
    }
    
    title.textAlignment = NSTextAlignmentLeft;
    title.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold];
    title.textColor = [UIColor colorWithWhite:0.6f alpha:1];
    
    [header addSubview:title];
    
    return header;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
//    if (textView == self.composeInputView.composeTextView){
//        if ([text isEqualToString:@"\n"]) {
//            return NO;
//        }
//    }
//
//    if (self.composeInputView.preventTyping) {
//        NSLog(@"prevent typing");
//
//    }
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)openRoomActions {
    BOOL isRoomAdmin   = false;
    BOOL insideRoom    = false; // compare ID of post room and active room
    BOOL followingRoom = true;
    BOOL roomPostNotifications = false;
    BOOL hasTwitter = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]];
    NSLog(@"hasTwitta? %@", hasTwitter ? @"YES" : @"NO");
    BOOL hasiMessage = [MFMessageComposeViewController canSendText];
    
    // Share to...
    // Turn on/off post notifications
    // Share on Instagram
    // Share on Twitter
    // Share on iMessage
    // Report Room
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:self.room.attributes.details.title preferredStyle:UIAlertControllerStyleActionSheet];
    actionSheet.view.tintColor = [UIColor colorWithWhite:0.2 alpha:1];
    
    // 1.A.* -- Any user, any page, any following state
    UIAlertAction *sharePost = [UIAlertAction actionWithTitle:@"Share Room..." style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"share room");
        
        [self showShareRoomSheet];
    }];
    [actionSheet addAction:sharePost];
    
    UIAlertAction *togglePostNotifications = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Turn %@ Post Notifications", roomPostNotifications ? @"Off" : @"On"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"toggle post notifications");
        // confirm action
    }];
    [actionSheet addAction:togglePostNotifications];
    
    if (hasTwitter) {
        UIAlertAction *shareOnTwitter = [UIAlertAction actionWithTitle:@"Share on Twitter" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"share on twitter");
            // confirm action
            UIImage *shareImage = [self roomShareImage];
            
            // confirm action
            UIAlertController *saveAndOpenTwitterConfirm = [UIAlertController alertControllerWithTitle:@"Share on Twitter" message:@"Would you like to save a personalized Room picture and open Twitter?" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *alertConfirm = [UIAlertAction actionWithTitle:@"Yes!" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                UIImageWriteToSavedPhotosAlbum(shareImage, nil, nil, nil);
                
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://post"] options:@{} completionHandler:nil];
            }];
            [saveAndOpenTwitterConfirm addAction:alertConfirm];
            
            UIAlertAction *alertCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"cancel");
            }];
            [saveAndOpenTwitterConfirm addAction:alertCancel];
            
            [self.navigationController presentViewController:saveAndOpenTwitterConfirm animated:YES completion:nil];
        }];
        [actionSheet addAction:shareOnTwitter];
    }
    
    if (hasiMessage) {
        UIAlertAction *shareOniMessage = [UIAlertAction actionWithTitle:@"Share on iMessage" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"share on iMessage");
            // confirm action
            MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init]; // Create message VC
            messageController.messageComposeDelegate = self; // Set delegate to current instance
            
            messageController.body = @"Join my room! https://rooms.app/room/room-name"; // Set initial text to example message
            
            //NSData *dataImg = UIImagePNGRepresentation([UIImage imageNamed:@"logoApple"]);//Add the image as attachment
            //[messageController addAttachmentData:dataImg typeIdentifier:@"public.data" filename:@"Image.png"];
            
            [self.navigationController presentViewController:messageController animated:YES completion:NULL];
        }];
        [actionSheet addAction:shareOniMessage];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"cancel");
    }];
    [cancel setValue:self.theme forKey:@"titleTextColor"];
    [actionSheet addAction:cancel];
    
    [self.navigationController presentViewController:actionSheet animated:YES completion:nil];
}
    
- (void)showShareRoomSheet {
    UIImage *shareImage = [self roomShareImage];
    
    UIActivityViewController *controller = [[UIActivityViewController alloc]initWithActivityItems:@[shareImage, @"hi insta"] applicationActivities:nil];
    
    // and present it
    controller.modalPresentationStyle = UIModalPresentationPopover;
    [self.navigationController presentViewController:controller animated:YES completion:nil];
}

- (UIImage *)roomShareImage {
    UIView *shareView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1080, 1080)];
    shareView.backgroundColor = self.theme;
    
    UIImageView *roomShareArt = [[UIImageView alloc] initWithFrame:shareView.bounds];
    roomShareArt.image = [UIImage imageNamed:@"roomShareArt"];
    [shareView addSubview:roomShareArt];
    
    UILabel *roomNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(shareView.frame.size.width / 2 - (590 / 2), 178, 590, 400)];
    roomNameLabel.font = [UIFont systemFontOfSize:80.f weight:UIFontWeightHeavy];
    roomNameLabel.textColor = [UIColor whiteColor];
    roomNameLabel.text = self.room.attributes.details.title;
    roomNameLabel.numberOfLines = 0;
    roomNameLabel.lineBreakMode = NSLineBreakByWordWrapping;
    CGRect nameRect = [roomNameLabel.text boundingRectWithSize:CGSizeMake(roomNameLabel.frame.size.width, CGFLOAT_MAX)
                                                                     options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                                                  attributes:@{NSFontAttributeName:roomNameLabel.font}
                                                                     context:nil];
    roomNameLabel.frame = CGRectMake(roomNameLabel.frame.origin.x, roomNameLabel.frame.origin.y, roomNameLabel.frame.size.width, nameRect.size.height);
    [shareView addSubview:roomNameLabel];
    
    UILabel *roomDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(shareView.frame.size.width / 2 - (roomNameLabel.frame.size.width / 2), roomNameLabel.frame.origin.y + roomNameLabel.frame.size.height, roomNameLabel.frame.size.width, 400)];
    roomDescriptionLabel.font = [UIFont systemFontOfSize:42.f weight:UIFontWeightBold];
    roomDescriptionLabel.textColor = [UIColor whiteColor];
    roomDescriptionLabel.text = self.room.attributes.details.theDescription;
    roomDescriptionLabel.alpha = 0.8;
    roomDescriptionLabel.numberOfLines = 0;
    roomDescriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    CGRect descriptionRect = [roomDescriptionLabel.text boundingRectWithSize:CGSizeMake(roomDescriptionLabel.frame.size.width, CGFLOAT_MAX)
                                                 options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                              attributes:@{NSFontAttributeName:roomDescriptionLabel.font}
                                                 context:nil];
    roomDescriptionLabel.frame = CGRectMake(roomDescriptionLabel.frame.origin.x, roomNameLabel.frame.origin.y + roomNameLabel.frame.size.height + 20, roomDescriptionLabel.frame.size.width, descriptionRect.size.height);
    [shareView addSubview:roomDescriptionLabel];
    
    
    UILabel *getRoomsLabel = [[UILabel alloc] initWithFrame:CGRectMake(shareView.frame.size.width / 2 - (roomNameLabel.frame.size.width / 2), 868, roomNameLabel.frame.size.width, 50)];
    getRoomsLabel.font = [UIFont systemFontOfSize:36.f weight:UIFontWeightBold];
    getRoomsLabel.textColor = [UIColor whiteColor];
    getRoomsLabel.text = @"https://getrooms.com";
    getRoomsLabel.alpha = 1;
    [shareView addSubview:getRoomsLabel];
    
    
    UIGraphicsBeginImageContextWithOptions(shareView.bounds.size, NO, [UIScreen mainScreen].scale);
    
    [shareView drawViewHierarchyInRect:shareView.bounds afterScreenUpdates:YES];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
