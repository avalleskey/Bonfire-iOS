//
//  RoomViewController.m
//  
//
//  Created by Austin Valleskey on 9/19/18.
//

#import "RoomViewController.h"
#import "ComplexNavigationController.h"
#import "ErrorView.h"
#import "SearchResultCell.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "RoomHeaderCell.h"
#import "ProfileViewController.h"
#import "EditRoomViewController.h"
#import "UIColor+Palette.h"
#import "Launcher.h"
// #import "UIScrollView+ContentInsetFix.h"
#import "InsightsLogger.h"

@interface RoomViewController () {
    int previousTableViewYOffset;
}

@property (nonatomic) BOOL loading;

@property (strong, nonatomic) ComplexNavigationController *launchNavVC;
@property (strong, nonatomic) ErrorView *errorView;
@property (nonatomic) BOOL userDidRefresh;

@end

@implementation RoomViewController

static NSString * const reuseIdentifier = @"Result";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.launchNavVC = (ComplexNavigationController *)self.navigationController;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] init];
    
    // [self mock];
    // NSLog(@"self.room: %@", self.room);
    
    self.view.backgroundColor = [UIColor headerBackgroundColor];
    
    [self setupTableView];
    [self setupErrorView];
    
    self.manager = [HAWebService manager];
    
    [self setupComposeInputView];
    
    self.view.tintColor = self.theme;
    
    self.loading = true;
    [self loadRoom];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roomUpdated:) name:@"RoomUpdated" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostBegan:) name:@"NewPostBegan" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostCompleted:) name:@"NewPostCompleted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostFailed:) name:@"NewPostFailed" object:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self styleOnAppear];
    
    if (self.view.tag == 1) {
        [InsightsLogger.sharedInstance openAllVisiblePostInsightsInTableView:self.tableView seenIn:InsightSeenInRoomView];
    }
    else {
        self.view.tag = 1;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [InsightsLogger.sharedInstance closeAllVisiblePostInsightsInTableView:self.tableView];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (NSString *)roomIdentifier {
    if (self.room.identifier != nil) return self.room.identifier;
    if (self.room.attributes.details.identifier != nil) return self.room.attributes.details.identifier;
    
    return nil;
}

- (void)dealloc {    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)newPostBegan:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil && [tempPost.attributes.status.postedIn.identifier isEqualToString:self.room.identifier] && tempPost.attributes.details.parent == 0) {
        // TODO: Check for image as well
        self.errorView.hidden = true;
        [self.tableView.stream prependTempPost:tempPost];
        [self.tableView refresh];
        
        [self.tableView setContentOffset:CGPointMake(0, -1 * (self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height)) animated:YES];
    }
}
- (void)newPostCompleted:(NSNotification *)notification {
    NSDictionary *info = notification.object;
    NSString *tempId = info[@"tempId"];
    Post *post = info[@"post"];
    
    if (post != nil && [post.attributes.status.postedIn.identifier isEqualToString:self.room.identifier] && post.attributes.details.parent == 0) {
        // TODO: Check for image as well
        self.errorView.hidden = true;
        [self.tableView.stream updateTempPost:tempId withFinalPost:post];
        
        self.room.attributes.summaries.counts.posts = self.room.attributes.summaries.counts.posts + 1;
        self.tableView.parentObject = self.room;
        
        [self.tableView refresh];
    }
}
// TODO: Allow tap to retry for posts
- (void)newPostFailed:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil && [tempPost.attributes.status.postedIn.identifier isEqualToString:self.room.identifier] && tempPost.attributes.details.parent == 0) {
        // TODO: Check for image as well
        [self.tableView.stream removeTempPost:tempPost.tempId];
        [self.tableView refresh];
        self.errorView.hidden = (self.tableView.stream.posts.count != 0);
    }
}

- (void)roomUpdated:(NSNotification *)notification {
    Room *room = notification.object;
    
    if (room != nil &&
        [room.identifier isEqualToString:self.room.identifier]) {
        // if new Room has no context, use existing context
        if (room.attributes.context == nil) {
            room.attributes.context = self.room.attributes.context;
        }
        
        BOOL canViewPosts_Before = [self canViewPosts];
        
        // new post appears valid and same room
        self.room = room;
        self.tableView.parentObject = room;
        
        if ([self.room.attributes.context.status isEqualToString:ROOM_STATUS_MEMBER]) {
            [self showComposeInputView];
            [self.composeInputView updatePlaceholders];
        }
        else {
            [self hideComposeInputView];
        }
        
        // Update Room
        UIColor *themeColor = [UIColor fromHex:[[self.room.attributes.details.color lowercaseString] isEqualToString:@"ffffff"]?@"222222":self.room.attributes.details.color];
        self.theme = themeColor;
        self.view.tintColor = themeColor;
        self.composeInputView.addMediaButton.tintColor = themeColor;
        self.composeInputView.postButton.backgroundColor = themeColor;
        // if top view controller -> update launch nav vc
        if ([self isEqual:self.navigationController.topViewController]) {
            [self.launchNavVC.searchView updateSearchText:room.attributes.details.title];
            self.title = room.attributes.details.title;
            [self.launchNavVC updateBarColor:themeColor withAnimation:2 statusBarUpdateDelay:0];
        }
        
        // update table view state based on new Room object
        // if and only if [self canViewPosts] changes values after setting the new room, should we update the table view
        BOOL canViewPosts_After = [self canViewPosts];
        if (canViewPosts_Before == false && canViewPosts_After == true) {
            [self loadRoomContent];
        }
        else {
            // loop through content and replace any occurences of this Room with the new object
            [self.tableView.stream updateRoomObjects:room];
        }
        
        NSLog(@"canViewPosts_Before: %@", (canViewPosts_Before ? @"YES" : @"NO"));
        NSLog(@"isPrivate? %@", (self.room.attributes.status.visibility.isPrivate ? @"YES" : @"NO"));
        NSLog(@"Camp Status: %@", self.room.attributes.context.status);
        
        if (self.room.attributes.status.visibility.isPrivate && self.tableView.stream.posts.count > 0 && ([self.room.attributes.context.status isEqualToString:ROOM_STATUS_LEFT] || [self.room.attributes.context.status isEqualToString:ROOM_STATUS_NO_RELATION])) {
            self.tableView.stream.pages = [[NSMutableArray alloc] init];
            self.tableView.stream.posts = @[];
            [self showErrorViewWithType:ErrorViewTypeLocked title:@"Private Camp" description:@"Request access above to get access to this Camp’s posts"];
        }
        
        [self.tableView refresh];
    }
}

- (void)loadRoom {
    NSError *roomError;
    //self.room = [[Room alloc] initWithDictionary:[self.room toDictionary] error:&roomError];
    // [self mock];
    
    if (self.room.identifier || self.room.attributes.details.identifier) {
        self.tableView.parentObject = self.room;
        [self.tableView refresh];
        if (roomError || self.room.attributes.context == nil) {
            // Room requires context, even though it's Optional on the object
            
            // Room object is fragmented
            if (roomError) {
                NSLog(@"room error::::");
                NSLog(@"%@", roomError);
            }
            
            // let's fetch info to fill in the gaps
            self.composeInputView.hidden = true;
        }
        
        // load room info before loading posts
        [self getRoomInfo];
    }
    else {
        NSLog(@"room nto found");
        // room not found
        self.tableView.hidden = true;
        self.errorView.hidden = false;
        
        [self.errorView updateTitle:@"Room Not Found"];
        [self.errorView updateDescription:@"We couldn’t find the Room\nyou were looking for"];
        [self.errorView updateType:ErrorViewTypeNotFound];
        
        [self.launchNavVC.searchView updateSearchText:@""];
        
        [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.launchNavVC.rightActionButton.alpha = 0;
        } completion:^(BOOL finished) {
        }];
    }
}
- (void)getRoomInfo {
    NSString *url = [NSString stringWithFormat:@"%@/%@/rooms/%@", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], [self roomIdentifier]];
    
    NSLog(@"self.room identifier: %@", [self roomIdentifier]);
    NSLog(@"%@", self.room.attributes.details.identifier);
    
    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            NSDictionary *params = @{};
            
            [self.manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSDictionary *responseData = (NSDictionary *)responseObject[@"data"];
                
                // NSLog(@"::::: getRoomInfo() :::::");
                
                // this must go before we set self.room to the new Room object
                BOOL requiresColorUpdate = (self.room.attributes.details.color == nil);
                
                // first page
                
                NSError *contextError;
                RoomContext *context = [[RoomContext alloc] initWithDictionary:responseData[@"attributes"][@"context"] error:&contextError];
                
                NSError *roomError;
                self.room = [[Room alloc] initWithDictionary:responseData error:&roomError];
                self.room.attributes.context = context;
                if (roomError) {
                    NSLog(@"room error: %@", roomError);
                }
                [[Session sharedInstance] addToRecents:self.room];
                
                // update the theme color (in case we didn't know the room's color before
                if (requiresColorUpdate) {
                    [self updateTheme];
                }
                
                // update the title (in case we didn't know the room's title before)
                self.title = self.room.attributes.details.title;
                [self.launchNavVC.searchView updateSearchText:self.title];
                
                // update the compose input placeholder (in case we didn't know the room's title before)
                [self.composeInputView updatePlaceholders];
                
                self.tableView.parentObject = self.room;
                
                // Now that the VC's Room object is complete,
                // Go on to load the room content
                [self loadRoomContent];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"RoomViewController / getRoom() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                self.errorView.hidden = false;
                
                NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
                NSInteger statusCode = httpResponse.statusCode;
                if (statusCode == 404) {
                    [self.errorView updateTitle:@"Camp Not Found"];
                    [self.errorView updateDescription:@"We couldn’t find the Camp\nyou were looking for"];
                    [self.errorView updateType:ErrorViewTypeNotFound];
                }
                else {
                    [self.errorView updateType:ErrorViewTypeGeneral];
                    [self.errorView updateTitle:@"Error Loading"];
                    [self.errorView updateDescription:@"Check your network settings and tap here to try again"];
                }
                
                [self positionErrorView];
                
                self.loading = false;
                self.tableView.loading = false;
                self.tableView.error = true;
                [self.tableView refresh];
            }];
        }
    }];
}

- (void)showComposeInputView {
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.composeInputView.frame.size.height - [UIApplication sharedApplication].delegate.window.safeAreaInsets.bottom, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    
    if (self.composeInputView.isHidden) {
        self.composeInputView.transform = CGAffineTransformMakeTranslation(0, self.composeInputView.frame.size.height);
        self.composeInputView.hidden = false;
        
        [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.composeInputView.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}
- (void)hideComposeInputView {
    self.tableView.contentInset = UIEdgeInsetsZero;
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    
    if (!self.composeInputView.isHidden) {
        [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.composeInputView.transform = CGAffineTransformMakeTranslation(0, self.composeInputView.frame.size.height);
        } completion:^(BOOL finished) {
            self.composeInputView.hidden = true;
        }];
    }
}

- (void)loadRoomContent {
    if ([self canViewPosts]) {
        if ([self.room.attributes.context.status isEqualToString:ROOM_STATUS_MEMBER]) {
            [self showComposeInputView];
        }
        
        [self getPostsWithMaxId:0];
    }
    else {
        [self hideComposeInputView];
        
        self.errorView.hidden = false;
        
        self.loading = false;
        self.tableView.loading = false;
        self.tableView.loadingMore = false;
        [self.tableView refresh];
        
        if (self.room.attributes.status.isBlocked) { // Room has been blocked
            [self.errorView updateTitle:@"Camp Not Available"];
            [self.errorView updateDescription:@"This Room is no longer available"];
            [self.errorView updateType:ErrorViewTypeBlocked];
        }
        else if ([self.room.attributes.context.status isEqualToString:ROOM_STATUS_BLOCKED]) { // blocked from Room
            [self.errorView updateTitle:@"Blocked By Camp"];
            [self.errorView updateDescription:@"Your account is blocked from creating and viewing posts in this Room"];
            [self.errorView updateType:ErrorViewTypeBlocked];
        }
        else if (self.room.attributes.status.visibility.isPrivate) { // not blocked, not member
            // private camp but not a member yet
            [self.errorView updateTitle:@"Private Camp"];
            [self.errorView updateDescription:@"Request access above to get access to this Camp’s posts"];
            [self.errorView updateType:ErrorViewTypeLocked];
        }
        else {
            [self.errorView updateTitle:@"Camp Not Found"];
            [self.errorView updateDescription:@"We couldn’t find the Camp\nyou were looking for"];
            [self.errorView updateType:ErrorViewTypeNotFound];
            
            [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.launchNavVC.rightActionButton.alpha = 0;
            } completion:^(BOOL finished) {
            }];
        }
        
        [self positionErrorView];
    }
}
- (void)updateTheme {
    UIColor *theme = [UIColor fromHex:self.room.attributes.details.color];
    
    [self.launchNavVC updateBarColor:theme withAnimation:1 statusBarUpdateDelay:0];
    [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.composeInputView.textView.tintColor = theme;
        self.composeInputView.postButton.backgroundColor = theme;
        self.composeInputView.addMediaButton.tintColor = theme;
    } completion:^(BOOL finished) {
    }];
    
    self.theme = theme;
    self.view.tintColor = self.theme;
}

- (void)mock {
    /* mimic being invited
    RoomContext *context = [[RoomContext alloc] initWithDictionary:[self.room.attributes.context toDictionary] error:nil];
    context.status = ROOM_STATUS_BLOCKED;
    self.room.attributes.context = context;*/
    
    /* mimic private room
    RoomVisibility *visibility = [[RoomVisibility alloc] initWithDictionary:[self.room.attributes.status.discoverability toDictionary] error:nil];
    visibility = true;
    self.room.attributes.status.visibility = visibility;*/
    
    // mimic Room being blocked
    /*RoomStatus *status = [[RoomStatus alloc] initWithDictionary:[self.room.attributes.status toDictionary] error:nil];
    status.isBlocked = true;
    self.room.attributes.status = status;*/
    
    /* mimic opening Room with Room hash identifier only
    Room *room = [[Room alloc] init];
    room.identifier = @"-OJkNgx4gZoGB";
    
    self.room = room;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.launchNavVC updateBarColor:@"7d8a99" withAnimation:0 statusBarUpdateDelay:0];
        [self.launchNavVC updateSearchText:@"Loading..."];
    });
    self.theme = [UIColor fromHex:@"7d8a99"];*/
    
    /* mimic opening Room with Room identifier only
    Room *room = [[Room alloc] init];
    room.attributes.details.identifier = @"NewRoom";

    self.room = room;*/
}

- (void)setupErrorView {
    self.errorView = [[ErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100) title:@"Camp Not Found" description:@"We couldn’t find the Room you were looking for" type:ErrorViewTypeNotFound];
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
                [self loadRoom];
            });
        }
    }];
}


- (void)setupComposeInputView {
    self.composeInputView = [[ComposeInputView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    self.composeInputView.hidden = true;
    
    CGFloat bottomPadding = [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.bottom;
    CGFloat collapsed_inputViewHeight = ((self.composeInputView.textView.frame.origin.y * 2) + self.composeInputView.textView.frame.size.height) + bottomPadding;
    
    self.composeInputView.frame = CGRectMake(0, self.view.bounds.size.height - collapsed_inputViewHeight, self.view.frame.size.width, collapsed_inputViewHeight);
    self.composeInputView.parentViewController = self;
    self.composeInputView.postButton.backgroundColor = [self.theme isEqual:[UIColor whiteColor]] ? [UIColor colorWithWhite:0.2f alpha:1] : self.theme;
    self.composeInputView.addMediaButton.tintColor = self.composeInputView.postButton.backgroundColor;
    self.composeInputView.textView.tintColor = self.composeInputView.postButton.backgroundColor;
    
    [self.composeInputView bk_whenTapped:^{
        if (![self.composeInputView isActive]) {
            [self.composeInputView setActive:true];
        }
    }];
    [self.composeInputView.postButton bk_whenTapped:^{
        [self postMessage];
    }];
    [self.composeInputView.expandButton bk_whenTapped:^{
        [[Launcher sharedInstance] openComposePost:self.room inReplyTo:nil withMessage:self.composeInputView.textView.text media:self.composeInputView.media];
    }];
    
    [self.view addSubview:self.composeInputView];
    
    self.composeInputView.textView.delegate = self;
    self.composeInputView.tintColor = self.view.tintColor;
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.composeInputView.frame.size.height - [UIApplication sharedApplication].delegate.window.safeAreaInsets.bottom, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
}
- (void)textViewDidChange:(UITextView *)textView {
    if ([textView isEqual:self.composeInputView.textView]) {
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
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *message = self.composeInputView.textView.text;
    if (message.length > 0) {
        [params setObject:message forKey:@"message"];
    }
    if (self.composeInputView.media.count > 0) {
        [params setObject:self.composeInputView.media forKey:@"images"];
    }
    
    if ([params objectForKey:@"message"] || [params objectForKey:@"images"]) {
        // meets min. requirements
        [[Session sharedInstance] createPost:params postingIn:self.room replyingTo:nil];
        
        self.composeInputView.textView.text = @"";
        [self.composeInputView hidePostButton];
        [self.composeInputView.textView resignFirstResponder];
        self.composeInputView.media = [[NSMutableArray alloc] init];
        [self.composeInputView hideMediaTray];
    }
}

- (void)styleOnAppear {
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    CGFloat collapsed_inputViewHeight = ((self.composeInputView.textView.frame.origin.y * 2) + self.composeInputView.textView.frame.size.height) + bottomPadding;
    
    self.composeInputView.frame = CGRectMake(0, self.view.bounds.size.height - collapsed_inputViewHeight, self.view.bounds.size.width, collapsed_inputViewHeight);
}

- (BOOL)canViewPosts {
    BOOL canViewPosts = self.room.identifier != nil && // has an ID
                        !self.room.attributes.status.isBlocked && // Room not blocked
                        ![self.room.attributes.context.status isEqualToString:ROOM_STATUS_BLOCKED] && // User blocked by Room
                        (!self.room.attributes.status.visibility.isPrivate || // (public room OR
                         [self.room.attributes.context.status isEqualToString:ROOM_STATUS_MEMBER]);
    
    return canViewPosts;
}

- (void)getPostsWithMaxId:(NSInteger)maxId {
    self.tableView.hidden = false;
    if (self.tableView.stream.posts.count == 0) {
        self.errorView.hidden = true;
        self.tableView.loading = true;
        [self.tableView refresh];
    }
    
    NSString *url = [NSString stringWithFormat:@"%@/%@/rooms/%@/stream", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], [self roomIdentifier]];
    
    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            NSDictionary *params = maxId != 0 ? @{@"max_id": [NSNumber numberWithInteger:maxId-1]} : @{};
            
            [self.manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
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
                    [self showErrorViewWithType:ErrorViewTypeNoPosts title:@"No Posts Yet" description:nil];
                }
                else {
                    self.errorView.hidden = true;
                }
                
                self.loading = false;
                
                self.tableView.loading = false;
                self.tableView.loadingMore = false;
                
                [self.tableView refresh];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"RoomViewController / getPostsWithMaxId() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                if (self.tableView.stream.posts.count == 0) {
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
    self.tableView.dataType = RSTableViewTypeRoom;
    self.tableView.parentObject = self.room;
    self.tableView.loading = true;
    self.tableView.loadingMore = false;
    self.tableView.paginationDelegate = self;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.tableView.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    [self.view addSubview:self.tableView];
    
    UIView *headerHack = [[UIView alloc] initWithFrame:CGRectMake(0, -1 * self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    headerHack.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
    [self.tableView insertSubview:headerHack atIndex:0];
}
- (void)refresh {
    self.tableView.loading = true;
    self.tableView.loadingMore = false;
    [self.tableView refresh];
    
    self.userDidRefresh = true;
    self.tableView.reachedBottom = false;
    [self loadRoom];
}

- (void)showErrorViewWithType:(ErrorViewType)type title:(NSString *)title description:(NSString *)description {
    self.errorView.hidden = false;
    
    RoomHeaderCell *headerCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    CGFloat heightOfHeader = headerCell.frame.size.height;
    
    [self.errorView updateType:type];
    [self.errorView updateTitle:title];
    [self.errorView updateDescription:description];
    
    self.errorView.frame = CGRectMake(self.errorView.frame.origin.x, heightOfHeader + 72, self.errorView.frame.size.width, self.errorView.frame.size.height);
}

- (void)tableView:(id)tableView didRequestNextPageWithMaxId:(NSInteger)maxId {
    if (self.tableView.stream.posts.count > 0) {
        Post *lastPost = [self.tableView.stream.posts lastObject];
        
        [self getPostsWithMaxId:lastPost.identifier];
    }
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
    
    return true;
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    _currentKeyboardHeight = keyboardFrameBeginRect.size.height;
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    CGFloat newComposeInputViewY = self.view.frame.size.height - self.currentKeyboardHeight - self.composeInputView.frame.size.height + bottomPadding;
    
    self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, newComposeInputViewY, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
}

- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        [self.composeInputView resize:false];
        
        self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, self.view.frame.size.height - self.composeInputView.frame.size.height, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
    } completion:nil];
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
    // TODO: check that the user is actually an Admin, not just a member
    BOOL isMember              = [self.room.attributes.context.status isEqualToString:ROOM_STATUS_MEMBER];
    BOOL isRoomAdmin           = self.room.attributes.context.membership.role.identifier == ROOM_ROLE_ADMIN;
    // BOOL insideRoom    = false; // compare ID of post room and active room
    // BOOL followingRoom = true;
    BOOL roomPostNotifications = self.room.attributes.context.membership.subscription != nil;
    BOOL hasTwitter            = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]];
    BOOL hasiMessage           = [MFMessageComposeViewController canSendText];
    
    // Share to...
    // Turn on/off post notifications
    // Share on Instagram
    // Share on Twitter
    // Share on iMessage
    // Report Room
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:self.room.attributes.details.title preferredStyle:UIAlertControllerStyleActionSheet];
    actionSheet.view.tintColor = [UIColor colorWithWhite:0.2 alpha:1];
    
    if (isRoomAdmin) {
        UIAlertAction *editCamp = [UIAlertAction actionWithTitle:@"Edit Camp" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            EditRoomViewController *epvc = [[EditRoomViewController alloc] initWithStyle:UITableViewStyleGrouped];
            epvc.view.tintColor = [Session sharedInstance].themeColor;
            epvc.themeColor = [UIColor fromHex:self.room.attributes.details.color];
            epvc.room = self.room;
            
            UINavigationController *newNavController = [[UINavigationController alloc] initWithRootViewController:epvc];
            newNavController.transitioningDelegate = [Launcher sharedInstance];
            newNavController.navigationBar.barStyle = UIBarStyleBlack;
            newNavController.navigationBar.translucent = false;
            newNavController.navigationBar.barTintColor = [UIColor whiteColor];
            [newNavController setNeedsStatusBarAppearanceUpdate];
            
            [self.launchNavVC presentViewController:newNavController animated:YES completion:nil];
        }];
        [actionSheet addAction:editCamp];
    }
    
    if (isMember) {
        UIAlertAction *togglePostNotifications = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Turn %@ Post Notifications", roomPostNotifications ? @"Off" : @"On"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"toggle post notifications");
            // confirm action
            if ([Session sharedInstance].deviceToken != nil) {
                if (roomPostNotifications) {
                    [self turnOffPostNotifications];
                }
                else {
                    [self turnOnPostNotifications];
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
    
    UIAlertAction *shareRoom = [UIAlertAction actionWithTitle:@"Share Camp via..." style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"share room");
        
        [self showShareRoomSheet];
    }];
    [actionSheet addAction:shareRoom];
    
    if (hasTwitter) {
        UIAlertAction *shareOnTwitter = [UIAlertAction actionWithTitle:@"Share on Twitter" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"share on twitter");
            // confirm action
            UIImage *shareImage = [self roomShareImage];
            
            // confirm action
            UIAlertController *saveAndOpenTwitterConfirm = [UIAlertController alertControllerWithTitle:@"Share on Twitter" message:@"Would you like to save a personalized Camp picture and open Twitter?" preferredStyle:UIAlertControllerStyleAlert];
            
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
            
            NSString *url = [NSString stringWithFormat:@"https://joinbonfire.com/camps/%@", self.room.attributes.details.identifier];
            NSString *message = [NSString stringWithFormat:@"Join my Camp on Bonfire! 🔥 %@", url];
            
            [[Launcher sharedInstance] shareOniMessage:message image:nil];
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
- (void)turnOnPostNotifications {
    // Update the model
    RoomContextMembershipSubscription *subscription = [[RoomContextMembershipSubscription alloc] init];
    NSDate *date = [NSDate new];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    subscription.createdAt = [dateFormatter stringFromDate:date];
    self.room.attributes.context.membership.subscription = subscription;
    
    NSString *url = [NSString stringWithFormat:@"%@/%@/rooms/%@/members/subscriptions", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], [self roomIdentifier]];
    
    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            [self.manager POST:url parameters:@{@"vendor": @"APNS"} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"turn on post notifications!");
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"RoomViewController / turnOnPostNotifications() - error: %@", error);
                NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                NSLog(@"errorResponse: %@", ErrorResponse);
            }];
        }
    }];
}
- (void)turnOffPostNotifications {
    // Update the model
    self.room.attributes.context.membership.subscription = nil;
    
    NSString *url = [NSString stringWithFormat:@"%@/%@/rooms/%@/members/subscriptions", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], [self roomIdentifier]];

    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            [self.manager DELETE:url parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"turn off post notifications.");
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"RoomViewController / turnOffPostNotifications() - error: %@", error);
                NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                NSLog(@"errorResponse: %@", ErrorResponse);
            }];
        }
    }];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [controller dismissViewControllerAnimated:YES completion:nil];
}
    
- (void)showShareRoomSheet {
    UIImage *shareImage = [self roomShareImage];
    NSString *url = [NSString stringWithFormat:@"https://joinbonfire.com/camps/%@", self.room.attributes.details.identifier];
    NSString *message = [NSString stringWithFormat:@"Join my Camp on Bonfire! 🔥 %@", url];
    
    // and present it
    UIActivityViewController *controller = [[UIActivityViewController alloc]initWithActivityItems:@[shareImage, message] applicationActivities:nil];
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
