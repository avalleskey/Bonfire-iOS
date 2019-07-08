//
//  CampViewController.m
//  
//
//  Created by Austin Valleskey on 9/19/18.
//

#import "CampViewController.h"
#import "ComplexNavigationController.h"
#import "ErrorView.h"
#import "SearchResultCell.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "CampHeaderCell.h"
#import "ProfileViewController.h"
#import "EditCampViewController.h"
#import "UIColor+Palette.h"
#import "Launcher.h"
#import "InsightsLogger.h"
#import "HAWebService.h"
@import Firebase;
#import "BFNotificationManager.h"
#import "SetAnIcebreakerViewController.h"

@interface CampViewController () {
    int previousTableViewYOffset;
}

@property (nonatomic) BOOL loading;

@property (nonatomic, strong) ComplexNavigationController *launchNavVC;
@property (nonatomic, strong) ErrorView *errorView;
@property (nonatomic) BOOL userDidRefresh;

@end

@implementation CampViewController

static NSString * const campHeaderCellIdentifier = @"CampHeaderCell";

static NSString * const reuseIdentifier = @"Result";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.launchNavVC = (ComplexNavigationController *)self.navigationController;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] init];
    
    self.view.backgroundColor = [UIColor headerBackgroundColor];
    
    [self setupTableView];
    [self setupErrorView];
        
    [self setupComposeInputView];
    
    self.view.tintColor = self.theme;
    
    self.loading = true;
    [self loadCamp];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postDeleted:) name:@"PostDeleted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(campUpdated:) name:@"CampUpdated" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostBegan:) name:@"NewPostBegan" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostCompleted:) name:@"NewPostCompleted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostFailed:) name:@"NewPostFailed" object:nil];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Camp" screenClass:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self styleOnAppear];
    
    if (self.view.tag == 1) {
        [InsightsLogger.sharedInstance openAllVisiblePostInsightsInTableView:self.tableView seenIn:InsightSeenInCampView];
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

- (NSString *)campIdentifier {
    if (self.camp.identifier != nil) return self.camp.identifier;
    if (self.camp.attributes.details.identifier != nil) return self.camp.attributes.details.identifier;
    
    return nil;
}

- (void)dealloc {    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)newPostBegan:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil && [tempPost.attributes.status.postedIn.identifier isEqualToString:self.camp.identifier] && tempPost.attributes.details.parentId == 0) {
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
    
    if (post != nil && [post.attributes.status.postedIn.identifier isEqualToString:self.camp.identifier] && post.attributes.details.parentId == 0) {
        // TODO: Check for image as well
        self.errorView.hidden = true;
        [self.tableView.stream removeTempPost:tempId];
        
        [self getPostsWithCursor:PostStreamPagingCursorTypePrevious];
    }
}
// TODO: Allow tap to retry for posts
- (void)newPostFailed:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil && [tempPost.attributes.status.postedIn.identifier isEqualToString:self.camp.identifier] && tempPost.attributes.details.parentId == 0) {
        [self.tableView.stream removeTempPost:tempPost.tempId];
        [self.tableView refresh];
        self.errorView.hidden = (self.tableView.stream.posts.count != 0);
    }
}

- (void)postDeleted:(NSNotification *)notification {
    Post *post = notification.object;
    
    if ([post.attributes.status.postedIn.identifier isEqualToString:self.camp.identifier]) {
        [self determineErorrViewVisibility];
    }
}
- (void)campUpdated:(NSNotification *)notification {
    Camp *camp = notification.object;
    
    NSLog(@"camp updated::");
    NSLog(@"%@", camp);
    
    if (camp != nil &&
        [camp.identifier isEqualToString:self.camp.identifier]) {
        // if new Camp has no context, use existing context
        if (camp.attributes.context == nil) {
            camp.attributes.context = self.camp.attributes.context;
        }
        
        BOOL canViewPosts_Before = [self canViewPosts];
        
        // new post appears valid and same camp
        self.camp = camp;
        
        [self updateComposeInputView];
        
        // Update Camp
        UIColor *themeColor = [UIColor fromHex:[[self.camp.attributes.details.color lowercaseString] isEqualToString:@"ffffff"]?@"222222":self.camp.attributes.details.color];
        self.theme = themeColor;
        self.view.tintColor = themeColor;
        self.composeInputView.addMediaButton.tintColor = themeColor;
        self.composeInputView.postButton.backgroundColor = themeColor;
        // if top view controller -> update launch nav vc
        if ([self isEqual:self.navigationController.topViewController]) {
            [self.launchNavVC.searchView updateSearchText:camp.attributes.details.title];
            self.title = camp.attributes.details.title;
            [self.launchNavVC updateBarColor:themeColor animated:true];
        }
        
        // update table view state based on new Camp object
        // if and only if [self canViewPosts] changes values after setting the new camp, should we update the table view
        BOOL canViewPosts_After = [self canViewPosts];
        if (canViewPosts_Before == false && canViewPosts_After == true) {
            [self loadCampContent];
        }
        else {
            // loop through content and replace any occurences of this Camp with the new object
            [self.tableView.stream updateCampObjects:camp];
        }
        
        if (self.camp.attributes.status.visibility.isPrivate && self.tableView.stream.posts.count > 0 && ([self.camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_LEFT] || [self.camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_NO_RELATION])) {
            self.tableView.stream.pages = [[NSMutableArray alloc] init];
            self.tableView.stream.posts = @[];
            [self showErrorViewWithType:ErrorViewTypeLocked title:@"Private Camp" description:@"Request access above to get access to this Camp’s posts"];
        }
        
        [self.tableView refresh];
    }
}

- (void)updateComposeInputView {
    [self.composeInputView setMediaTypes:self.camp.attributes.context.camp.permissions.post];
    if ([self.camp.attributes.context.camp.permissions canPost]) {
        [self showComposeInputView];
        [self.composeInputView updatePlaceholders];
    }
    else {
        [self hideComposeInputView];
    }
}

- (void)loadCamp {
    if (self.camp.identifier.length > 0 || self.camp.attributes.details.identifier.length > 0) {
        [self.tableView refresh];
        if (self.camp.attributes.context == nil) {
            // let's fetch info to fill in the gaps
            self.composeInputView.hidden = true;
        }
        
        if (!self.camp.identifier || self.camp.identifier.length == 0) {
            // no camp identifier yet, don't show the ••• icon just yet
            [self hideMoreButton];
        }
        
        // load camp info before loading posts
        self.errorView.hidden = true;
        [self getCampInfo];
    }
    else {
        // camp not found
        self.tableView.hidden = true;
        self.errorView.hidden = false;
        
        [self showErrorViewWithType:ErrorViewTypeNotFound title:@"Camp Not Found" description:@"We couldn’t find the Camp\nyou were looking for"];
        
        [self hideMoreButton];
    }
}
- (void)getCampInfo {
    NSString *url = [NSString stringWithFormat:@"camps/%@", [self campIdentifier]];
    
    NSLog(@"self.camp identifier: %@", [self campIdentifier]);
    NSLog(@"%@", self.camp.attributes.details.identifier);
    
    NSDictionary *params = @{};
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *responseData = (NSDictionary *)responseObject[@"data"];
        
        // this must go before we set self.camp to the new Camp object
        NSString *colorBefore = self.camp.attributes.details.color;
        BOOL requiresColorUpdate = (colorBefore == nil || colorBefore.length == 0);
        
        // first page
        NSError *contextError;
        BFContext *context = [[BFContext alloc] initWithDictionary:responseData[@"attributes"][@"context"] error:&contextError];
        
        NSError *campError;
        self.camp = [[Camp alloc] initWithDictionary:responseData error:&campError];
        
        if (self.camp.attributes.context == nil) {
            self.camp.attributes.context = context;
        }
        
        if (campError) {
            NSLog(@"camp error: %@", campError);
        }
        [[Session sharedInstance] addToRecents:self.camp];
        
        // update the theme color (in case we didn't know the camp's color before
        if (![colorBefore isEqualToString:self.camp.attributes.details.color]) requiresColorUpdate = true;
        if (requiresColorUpdate) {
            [self updateTheme];
        }
        
        // update the title (in case we didn't know the camp's title before)
        self.title = self.camp.attributes.details.title;
        [self.launchNavVC.searchView updateSearchText:self.title];
        
        // update the compose input placeholder (in case we didn't know the camp's title before)
        [self updateComposeInputView];
        
        [self positionErrorView];
        
        // Now that the VC's Camp object is complete,
        // Go on to load the camp content
        [self loadCampContent];
        
        [self showMoreButton];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"CampViewController / getCamp() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        self.errorView.hidden = false;
        
        NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
        NSInteger statusCode = httpResponse.statusCode;
        if (statusCode == 404) {
            [self.errorView updateType:ErrorViewTypeNotFound title:@"Camp Not Found" description:@"We couldn’t find the Camp\nyou were looking for" actionTitle:@"Refresh" actionBlock:^{
                [self refresh];
            }];
            
            self.camp = nil;
            
            [self hideMoreButton];
        }
        else {
            if ([HAWebService hasInternet]) {
                [self.errorView updateType:ErrorViewTypeGeneral title:@"Error Loading" description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
                    [self refresh];
                }];
            }
            else {
                [self.errorView updateType:ErrorViewTypeNoInternet title:@"No Internet" description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
                    [self refresh];
                }];
            }
        }
        
        self.loading = false;
        self.tableView.loading = false;
        self.tableView.error = true;
        [self.tableView refresh];
        
        [self positionErrorView];
    }];
}

- (void)hideMoreButton {
    [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.launchNavVC.rightActionButton.alpha = 0;
    } completion:^(BOOL finished) {
    }];
}
- (void)showMoreButton {
    [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.launchNavVC.rightActionButton.alpha = 1;
    } completion:^(BOOL finished) {
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
    self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, 0, self.tableView.contentInset.right);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    
    if (!self.composeInputView.isHidden) {
        [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.composeInputView.transform = CGAffineTransformMakeTranslation(0, self.composeInputView.frame.size.height);
        } completion:^(BOOL finished) {
            self.composeInputView.hidden = true;
        }];
    }
}

- (void)loadCampContent {
    if ([self canViewPosts]) {
        if ([self.camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_MEMBER]) {
            [self showComposeInputView];
        }
        
        [self getPostsWithCursor:PostStreamPagingCursorTypeNone];
    }
    else {
        [self hideComposeInputView];
        
        self.loading = false;
        self.tableView.loading = false;
        self.tableView.loadingMore = false;
        
        if (self.camp.attributes.status.isBlocked) { // Camp has been blocked
            [self showErrorViewWithType:ErrorViewTypeBlocked title:@"Camp Not Available" description:@"This Camp is no longer available"];
        }
        else if ([self.camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_BLOCKED]) { // blocked from Camp
            [self showErrorViewWithType:ErrorViewTypeBlocked title:@"Blocked By Camp" description:@"Your account is blocked from creating and viewing posts in this Camp"];
        }
        else if (self.camp.attributes.status.visibility.isPrivate) { // not blocked, not member
            // private camp but not a member yet
            [self showErrorViewWithType:ErrorViewTypeLocked title:@"Private Camp" description:@"Request access above to get access to this Camp’s posts"];
            
            self.tableView.stream.posts = @[];
            self.tableView.stream.pages = [[NSMutableArray alloc] init];
        }
        else {
            [self showErrorViewWithType:ErrorViewTypeNotFound title:@"Camp Not Found" description:@"We couldn’t find the Camp\nyou were looking for"];
            
            [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.launchNavVC.rightActionButton.alpha = 0;
            } completion:^(BOOL finished) {
            }];
        }
        
        [self.tableView refresh];
        
        [self positionErrorView];
    }
}
- (void)updateTheme {
    UIColor *theme = [UIColor fromHex:self.camp.attributes.details.color];
    
    if (self.launchNavVC.topViewController == self) {
        [self.launchNavVC updateBarColor:theme animated:true];
    }
    
    [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.composeInputView.textView.tintColor = theme;
        self.composeInputView.postButton.backgroundColor = theme;
        self.composeInputView.addMediaButton.tintColor = theme;
    } completion:^(BOOL finished) {
    }];
    
    self.theme = theme;
    self.view.tintColor = self.theme;
}

- (void)setupErrorView {
    self.errorView = [[ErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100) title:@"Camp Not Found" description:@"We couldn’t find the Camp you were looking for" type:ErrorViewTypeNotFound];
    self.errorView.center = self.tableView.center;
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
}

- (void)setupComposeInputView {
    CGFloat bottomPadding = [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.bottom;
    CGFloat collapsed_inputViewHeight = ((self.composeInputView.textView.frame.origin.y * 2) + self.composeInputView.textView.frame.size.height) + bottomPadding;
    
    self.composeInputView = [[ComposeInputView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - collapsed_inputViewHeight, self.view.frame.size.width, collapsed_inputViewHeight)];
    self.composeInputView.hidden = true;
    
    self.composeInputView.parentViewController = self;
    self.composeInputView.postButton.backgroundColor = [self.theme isEqual:[UIColor whiteColor]] ? [UIColor bonfireBlack] : self.theme;
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
        [Launcher openComposePost:self.camp inReplyTo:nil withMessage:self.composeInputView.textView.text media:nil];
    }];
    
    [self.view addSubview:self.composeInputView];
    
    self.composeInputView.textView.delegate = self;
    self.composeInputView.tintColor = self.view.tintColor;
    
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.composeInputView.frame.size.height - [UIApplication sharedApplication].delegate.window.safeAreaInsets.bottom, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    self.tableView.inputView = self.composeInputView;
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
        [params setObject:[Post trimString:message] forKey:@"message"];
    }
    if (self.composeInputView.media.objects.count > 0) {
        [params setObject:self.composeInputView.media forKey:@"media"];
    }
    
    if ([params objectForKey:@"message"] || [params objectForKey:@"media"]) {
        // meets min. requirements
        [BFAPI createPost:params postingIn:self.camp replyingTo:nil];
        
        [self.composeInputView reset];
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
    BOOL canViewPosts = self.camp.identifier != nil && // has an ID
                        !self.camp.attributes.status.isBlocked && // Camp not blocked
                        ![self.camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_BLOCKED] && // User blocked by Camp
                        (!self.camp.attributes.status.visibility.isPrivate || // (public camp OR
                         [self.camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_MEMBER]);
    
    return canViewPosts;
}

- (void)getPostsWithCursor:(PostStreamPagingCursorType)cursorType {
    self.tableView.hidden = false;
    if (self.tableView.stream.posts.count == 0) {
        self.errorView.hidden = true;
        self.tableView.loading = true;
        [self.tableView refresh];
    }
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (cursorType == PostStreamPagingCursorTypeNext) {
        [params setObject:self.tableView.stream.nextCursor forKey:@"cursor"];
    }
    else if (self.tableView.stream.prevCursor) {
        NSLog(@"prevCursor:: %@", self.tableView.stream.prevCursor);
        [params setObject:self.tableView.stream.prevCursor forKey:@"cursor"];
    }
    if ([params objectForKey:@"cursor"]) {
        [self.tableView.stream addLoadedCursor:params[@"cursor"]];
    }
    NSLog(@"params: %@", params);
    
    NSString *url = [NSString stringWithFormat:@"camps/%@/stream", [self campIdentifier]];
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        self.tableView.scrollEnabled = true;
        
        if (self.userDidRefresh) {
            self.userDidRefresh = false;
            self.tableView.stream.posts = @[];
            self.tableView.stream.pages = [[NSMutableArray alloc] init];
        }
        
        PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:responseObject error:nil];
        if (page.data.count > 0) {
            if (cursorType == PostStreamPagingCursorTypeNone || cursorType == PostStreamPagingCursorTypePrevious) {
                [self.tableView.stream prependPage:page];
            }
            else if (cursorType == PostStreamPagingCursorTypeNext) {
                [self.tableView.stream appendPage:page];
            }
        }
        
        [self determineErorrViewVisibility];
        
        self.loading = false;
        
        self.tableView.loading = false;
        self.tableView.loadingMore = false;
        
        [self.tableView refresh];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"CampViewController / getPostsWithMaxId() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        if (self.tableView.stream.posts.count == 0) {
            self.errorView.hidden = false;
            
            if ([HAWebService hasInternet]) {
                [self.errorView updateType:ErrorViewTypeGeneral title:@"Error Loading" description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
                    [self refresh];
                }];
            }
            else {
                [self.errorView updateType:ErrorViewTypeNoInternet title:@"No Internet" description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
                    [self refresh];
                }];
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
- (void)determineErorrViewVisibility {
    if (self.tableView.stream.posts.count == 0) {
        // Error: No posts yet!
        self.errorView.hidden = false;
        
        [self.errorView updateType:ErrorViewTypeNoPosts title:@"No Posts Yet" description:nil actionTitle:nil actionBlock:nil];
        
        [self positionErrorView];
    }
    else {
        self.errorView.hidden = true;
    }
}
- (void)positionErrorView {
    CampHeaderCell *headerCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    CGFloat heightOfHeader = headerCell.frame.size.height;
    self.errorView.frame = CGRectMake(self.errorView.frame.origin.x, heightOfHeader + 48, self.errorView.frame.size.width, self.errorView.frame.size.height);
}
- (void)setupTableView {
    self.tableView = [[RSTableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.navigationController.navigationBar.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView.dataType = RSTableViewTypeCamp;
    self.tableView.tableViewStyle = RSTableViewStyleGrouped;
    self.tableView.loading = true;
    self.tableView.loadingMore = false;
    self.tableView.extendedDelegate = self;
    [self.tableView registerClass:[CampHeaderCell class] forCellReuseIdentifier:campHeaderCellIdentifier];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.tableView.refreshControl addTarget:self
                                action:@selector(refresh)
                      forControlEvents:UIControlEventValueChanged];
    
    [self.view addSubview:self.tableView];
    
    UIView *headerHack = [[UIView alloc] initWithFrame:CGRectMake(0, -1 * self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    headerHack.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
    //[self.tableView insertSubview:headerHack atIndex:0];
}
- (void)refresh {
    self.userDidRefresh = true;
    [self loadCamp];
}

- (void)showErrorViewWithType:(ErrorViewType)type title:(NSString *)title description:(NSString *)description {
    self.errorView.hidden = false;
    [self.errorView updateType:type title:title description:description actionTitle:nil actionBlock:nil];
    [self positionErrorView];
}

- (void)tableView:(id)tableView didRequestNextPageWithMaxId:(NSInteger)maxId {
    if (self.tableView.stream.nextCursor.length > 0 && ![self.tableView.stream hasLoadedCursor:self.tableView.stream.nextCursor]) {
        [self getPostsWithCursor:PostStreamPagingCursorTypeNext];
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
    return textView.text.length + (text.length - range.length) <= [Session sharedInstance].defaults.post.maxLength.soft;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)openCampActions {
    // TODO: check that the user is actually an Admin, not just a member
    BOOL isMember              = [self.camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_MEMBER];
    BOOL canUpdate             = [self.camp.attributes.context.camp.permissions canUpdate];
    BOOL campPostNotifications = self.camp.attributes.context.camp.membership.subscription != nil;
    BOOL hasiMessage           = [MFMessageComposeViewController canSendText];
    
    // Share to...
    // Turn on/off post notifications
    // Share on Instagram
    // Share on Twitter
    // Share on iMessage
    // Report Camp
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"\n\n\n\n\n\n" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    //actionSheet.view.tintColor = [UIColor bonfireBlack];
    
    CGFloat margin = 8.0f;
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(margin, 0, actionSheet.view.bounds.size.width - margin * 4, 140.f)];
    BFAvatarView *campAvatar = [[BFAvatarView alloc] initWithFrame:CGRectMake(customView.frame.size.width / 2 - 32, 24, 64, 64)];
    campAvatar.camp = self.camp;
    [customView addSubview:campAvatar];
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 96, customView.frame.size.width - 32, 20)];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    nameLabel.font = [UIFont systemFontOfSize:17.f weight:UIFontWeightSemibold];
    nameLabel.textColor = [UIColor blackColor];
    nameLabel.text = self.camp.attributes.details.title;
    [customView addSubview:nameLabel];
    [actionSheet.view addSubview:customView];
    
    if ([self.camp.attributes.context.camp.permissions canUpdate]) {
        UIAlertAction *editCamp = [UIAlertAction actionWithTitle:@"Edit Camp" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            EditCampViewController *epvc = [[EditCampViewController alloc] initWithStyle:UITableViewStyleGrouped];
            epvc.themeColor = [UIColor fromHex:self.camp.attributes.details.color];
            epvc.view.tintColor = epvc.themeColor;
            epvc.camp = self.camp;
            
            SimpleNavigationController *newNavController = [[SimpleNavigationController alloc] initWithRootViewController:epvc];
            newNavController.transitioningDelegate = [Launcher sharedInstance];
            newNavController.modalPresentationStyle = UIModalPresentationFullScreen;
            
            [self.launchNavVC presentViewController:newNavController animated:YES completion:nil];
        }];
        [actionSheet addAction:editCamp];
    }
    
    if (isMember) {
        UIAlertAction *togglePostNotifications = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Turn %@ Post Notifications", campPostNotifications ? @"Off" : @"On"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"toggle post notifications");
            // confirm action
            if ([Session sharedInstance].deviceToken != nil) {
                if (campPostNotifications) {
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
    
    if (hasiMessage) {
        UIAlertAction *shareOniMessage = [UIAlertAction actionWithTitle:@"Share on iMessage" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"share on iMessage");
            
            NSString *url = [NSString stringWithFormat:@"https://bonfire.camp/c/%@", self.camp.attributes.details.identifier];
            NSString *message = [NSString stringWithFormat:@"Join the \"%@\" Camp on Bonfire! 🔥 %@", self.camp.attributes.details.title, url];
            
            [Launcher shareOniMessage:message image:nil];
        }];
        [actionSheet addAction:shareOniMessage];
    }
    
    UIAlertAction *shareCamp = [UIAlertAction actionWithTitle:@"Share Camp via..." style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [Launcher shareCamp:self.camp];
    }];
    [actionSheet addAction:shareCamp];
    
    /*
     if (hasTwitter) {
     UIAlertAction *shareOnTwitter = [UIAlertAction actionWithTitle:@"Share on Twitter" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
     NSLog(@"share on twitter");
     // confirm action
     UIImage *shareImage = [self campShareImage];
     
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
     */
    
    if (canUpdate) {
        UIAlertAction *leaveCamp = [UIAlertAction actionWithTitle:@"Leave Camp" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            // confirm action
            BOOL privateCamp = [self.camp.attributes.status.visibility isPrivate];
            BOOL lastMember = self.camp.attributes.summaries.counts.members <= 1;
            
            NSString *message;
            if (privateCamp && lastMember) {
                message = @"All camps must have at least one member. If you leave, this Camp and all of its posts will be deleted after 30 days of inactivity.";
            }
            else if (lastMember) {
                // leaving as the last member in a public camp
                message = @"All camps must have at least one member. If you leave, this Camp will be archived and eligible for anyone to reopen.";
            }
            else {
                // leaving a private camp, but the user isn't the last one
                message = @"You will no longer have access to this Camp's posts";
            }
            
            UIAlertController *confirmDeletePostActionSheet = [UIAlertController alertControllerWithTitle:@"Leave Camp?" message:message preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *confirmLeaveCamp = [UIAlertAction actionWithTitle:@"Leave" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [BFAPI unfollowCamp:self.camp completion:^(BOOL success, id responseObject) {
                    
                }];
                
                BFContext *context = [[BFContext alloc] initWithDictionary:[self.camp.attributes.context toDictionary] error:nil];
                context.camp.status = CAMP_STATUS_LEFT;
                self.camp.attributes.context = context;
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CampUpdated" object:self.camp];
            }];
            [confirmDeletePostActionSheet addAction:confirmLeaveCamp];
            
            UIAlertAction *cancelLeaveCamp = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            [confirmDeletePostActionSheet addAction:cancelLeaveCamp];
            
            [UIViewParentController(self) presentViewController:confirmDeletePostActionSheet animated:YES completion:nil];
        }];
        [actionSheet addAction:leaveCamp];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"cancel");
    }];
    //[cancel setValue:[UIColor bonfireBlack] forKey:@"titleTextColor"];
    [actionSheet addAction:cancel];
    
    [self.navigationController presentViewController:actionSheet animated:YES completion:nil];
}

- (void)turnOnPostNotifications {
    // Update the model
    BFContextCampMembershipSubscription *subscription = [[BFContextCampMembershipSubscription alloc] init];
    NSDate *date = [NSDate new];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    subscription.createdAt = [dateFormatter stringFromDate:date];
    self.camp.attributes.context.camp.membership.subscription = subscription;
    
    NSString *url = [NSString stringWithFormat:@"camps/%@/members/subscriptions", [self campIdentifier]];
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] POST:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"turn on post notifications!");
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"CampViewController / turnOnPostNotifications() - error: %@", error);
        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"errorResponse: %@", ErrorResponse);
    }];
}
- (void)turnOffPostNotifications {
    // Update the model
    self.camp.attributes.context.camp.membership.subscription = nil;
    
    NSString *url = [NSString stringWithFormat:@"camps/%@/members/subscriptions", [self campIdentifier]];

    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] DELETE:url parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"turn off post notifications.");
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"CampViewController / turnOffPostNotifications() - error: %@", error);
        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"errorResponse: %@", ErrorResponse);
    }];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - RSTableViewDelegate
- (UITableViewCell *)cellForRowInFirstSection:(NSInteger)row {
    if (row == 0) {
        CampHeaderCell *cell = [self.tableView dequeueReusableCellWithIdentifier:campHeaderCellIdentifier forIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        
        cell.camp = self.camp;
        
        BOOL emptyCampTitle = cell.camp.attributes.details.title.length == 0;
        BOOL emptyCamptag = cell.camp.attributes.details.identifier.length == 0;
        if (self.loading) {
            if (emptyCampTitle) {
                cell.textLabel.text = @"Loading...";
            }
            if (emptyCamptag) {
                cell.detailTextLabel.text = @"Loading...";
            }
        }
        else {
            if (emptyCamptag) {
                cell.detailTextLabel.text = @"Unknown Camp";
                if (emptyCampTitle) {
                    cell.textLabel.text = @"Unknown Camp";
                }
            }
            else {
                if (emptyCampTitle) {
                    cell.textLabel.text = [NSString stringWithFormat:@"#%@", cell.camp.attributes.details.identifier];
                }
            }
        }
        
        cell.followButton.hidden = (cell.camp.identifier.length == 0);
        
        if ([cell.camp.attributes.context.camp.permissions canUpdate]) {
            [cell.followButton updateStatus:CAMP_STATUS_CAN_EDIT];
        }
        else if ([cell.camp.attributes.status isBlocked]) {
            [cell.followButton updateStatus:CAMP_STATUS_CAMP_BLOCKED];
        }
        else if (self.loading && cell.camp.attributes.context == nil) {
            [cell.followButton updateStatus:CAMP_STATUS_LOADING];
        }
        else {
            [cell.followButton updateStatus:cell.camp.attributes.context.camp.status];
        }
        
        return cell;
    }
    
    return nil;
}
- (CGFloat)heightForRowInFirstSection:(NSInteger)row {
    if (row == 0) {
        return [CampHeaderCell heightForCamp:self.camp isLoading:self.loading];
    }
    
    return 0;
}
- (CGFloat)numberOfRowsInFirstSection {
    return 1;
}
- (UIView *)viewForFirstSectionHeader {
    NSDictionary *upsell = [self availableCampUpsell];
    if (upsell) {
        UIView *upsellView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 172)];
        
        upsellView.backgroundColor = [UIColor whiteColor];
        
        TappableButton *closeButton = [[TappableButton alloc] initWithFrame:CGRectMake(upsellView.frame.size.width - 14 - 16, 16, 14, 14)];
        closeButton.padding = UIEdgeInsetsMake(12, 12, 12, 12);
        [closeButton setImage:[[UIImage imageNamed:@"navCloseIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        closeButton.tintColor = [UIColor bonfireGray];
        closeButton.contentMode = UIViewContentModeScaleAspectFill;
        [closeButton bk_whenTapped:^{
            wait(0.3, ^{
                [self.tableView beginUpdates];
                [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"upsells/icebreaker"];
                [self.tableView reloadData];
                [self.tableView endUpdates];
            })
        }];
        [upsellView addSubview:closeButton];
        
        CGFloat height = 24; // top padding
        
        CGFloat bottomPadding = 0;
        if ([upsell objectForKey:@"image"] && ((NSString *)upsell[@"image"]).length > 0) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:upsell[@"image"]]];
            imageView.frame = CGRectMake(upsellView.frame.size.width / 2 - imageView.frame.size.width / 2, height, imageView.frame.size.width, imageView.frame.size.height);
            [upsellView addSubview:imageView];
            
            height += imageView.frame.size.height;
            bottomPadding = 10;
        }
        
        if ([upsell objectForKey:@"text"] && ((NSString *)upsell[@"text"]).length > 0) {
            UILabel *textLabel = [[UILabel alloc] init];
            textLabel.text = upsell[@"text"];
            textLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightMedium];
            textLabel.textColor = [UIColor bonfireBlack];
            textLabel.textAlignment = NSTextAlignmentCenter;
            textLabel.frame = CGRectMake(24, height + bottomPadding, self.view.frame.size.width - (24 * 2), 0);
            textLabel.numberOfLines = 0;
            textLabel.lineBreakMode = NSLineBreakByWordWrapping;
            [upsellView addSubview:textLabel];
            
            CGFloat textHeight = ceilf([upsell[@"text"] boundingRectWithSize:CGSizeMake(textLabel.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:textLabel.font} context:nil].size.height);
            SetHeight(textLabel, textHeight);
            
            height += (bottomPadding + textLabel.frame.size.height);
            bottomPadding = 12;
        }
        
        if ([upsell objectForKey:@"action_title"] && ((NSString *)upsell[@"action_title"]).length > 0) {
            FollowButton *actionButton = [[FollowButton alloc] initWithFrame:CGRectMake(24, height + bottomPadding, self.view.frame.size.width - (24 * 2), 36)];
            [actionButton setTitle:@"Add Icebreaker" forState:UIControlStateNormal];
            [actionButton setTitleColor:[UIColor colorWithRed:0.14 green:0.64 blue:1.00 alpha:1.0] forState:UIControlStateNormal];
            actionButton.layer.borderWidth = 1;
            actionButton.backgroundColor = [UIColor clearColor];
            [actionButton bk_whenTapped:upsell[@"action"]];
            [upsellView addSubview:actionButton];
            
            CGFloat actionHeight = 36;
            height += (bottomPadding + actionHeight);
        }
        
        height += 24; // bottom padding
        SetHeight(upsellView, height);
        
        UIView *topLineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, upsellView.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        topLineSeparator.backgroundColor = [UIColor separatorColor];
        [upsellView addSubview:topLineSeparator];
        
        UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, upsellView.frame.size.height - (1 / [UIScreen mainScreen].scale), upsellView.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        lineSeparator.backgroundColor = [UIColor separatorColor];
        [upsellView addSubview:lineSeparator];
        
        return upsellView;
    }
    
    UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    lineSeparator.backgroundColor = [UIColor separatorColor];
    return lineSeparator;
}
- (CGFloat)heightForFirstSectionHeader {
    NSDictionary *upsell = [self availableCampUpsell];
    if (upsell) {
        CGFloat height = (24 * 2);
        
        CGFloat bottomPadding = 0;
        if ([upsell objectForKey:@"image"] && ((NSString *)upsell[@"image"]).length > 0) {
            UIImage *image = [UIImage imageNamed:upsell[@"image"]];
            height += image.size.height;
            bottomPadding = 10;
        }
        
        if ([upsell objectForKey:@"text"] && ((NSString *)upsell[@"text"]).length > 0) {
            CGFloat textHeight = ceilf([upsell[@"text"] boundingRectWithSize:CGSizeMake(self.view.frame.size.width - (24 * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.f weight:UIFontWeightMedium]} context:nil].size.height);
            height += (bottomPadding + textHeight);
            bottomPadding = 12;
        }
        
        if ([upsell objectForKey:@"action_title"] && ((NSString *)upsell[@"action_title"]).length > 0) {
            CGFloat actionHeight = 36;
            height += (bottomPadding + actionHeight);
        }
        
        return height;
    }
    
    return (1 / [UIScreen mainScreen].scale);
}
- (NSDictionary *)availableCampUpsell {
    NSMutableDictionary *upsell = [[NSMutableDictionary alloc] initWithDictionary:@{
                                                                                    @"image": @"",
                                                                                    @"text": @"",
                                                                                    @"action_title": @"",
                                                                                    @"action": ^{}
                                                                                    }];
    if ([self.camp.attributes.context.camp.permissions canUpdate]) {
        if (!self.loading && self.camp.attributes.summaries.counts != nil && self.camp.attributes.summaries.counts.icebreakers == 0 && ![[NSUserDefaults standardUserDefaults] boolForKey:@"upsells/icebreaker"]) {
            [upsell setObject:@"icebreakerSnowflake" forKey:@"image"];
            [upsell setObject:@"Introduce new members to the Camp\nwith an Icebreaker post when they join" forKey:@"text"];
            [upsell setObject:@"Add Icebreaker" forKey:@"action_title"];
            [upsell setObject:^{
                SetAnIcebreakerViewController *mibvc = [[SetAnIcebreakerViewController alloc] initWithStyle:UITableViewStyleGrouped];
                mibvc.view.tintColor = self.view.tintColor;
                mibvc.camp = self.camp;
                
                ComplexNavigationController *newLauncher = [[ComplexNavigationController alloc] initWithRootViewController:mibvc];
                newLauncher.searchView.textField.text = @"Icebreaker Post";
                [newLauncher.searchView hideSearchIcon:false];
                newLauncher.transitioningDelegate = [Launcher sharedInstance];
                
                [newLauncher updateBarColor:self.view.tintColor animated:false];
                
                [Launcher push:newLauncher animated:YES];
                
                [newLauncher updateNavigationBarItemsWithAnimation:NO];
                
                wait(0.3, ^{
                    [self.tableView beginUpdates];
                    [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"upsells/icebreaker"];
                    [self.tableView reloadData];
                    [self.tableView endUpdates];
                })
            } forKey:@"action"];
            
            NSLog(@"return upsell");
            NSLog(@"upsell: %@", upsell);
            
            return upsell;
        }
    }
    
    return nil;
}

@end
