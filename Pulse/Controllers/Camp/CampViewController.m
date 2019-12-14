//
//  CampViewController.m
//  
//
//  Created by Austin Valleskey on 9/19/18.
//

#import "CampViewController.h"
#import "ComplexNavigationController.h"
#import "BFVisualErrorView.h"
#import "StartCampUpsellView.h"
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
#import "BFTipsManager.h"
#import "BFAlertController.h"
#import <FBSDKShareKit/FBSDKShareKit.h>
//#import "BFUpsellTableViewCell.h"

@interface CampViewController () {
    int previousTableViewYOffset;
}

@property (nonatomic) BOOL loading;

@property (nonatomic, strong) ComplexNavigationController *launchNavVC;
@property (nonatomic, strong) StartCampUpsellView *startCampUpsellView;

@end

@implementation CampViewController

static NSString * const campHeaderCellIdentifier = @"CampHeaderCell";

static NSString * const reuseIdentifier = @"Result";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.launchNavVC = (ComplexNavigationController *)self.navigationController;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] init];
    
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
    
    [self setupTableView];
    [self setupStartCampUpsellView];
        
    if (!self.isPreview)  {
        [self setupComposeInputView];
    }
    
    [self setupCoverPhotoView];
    self.tableView.contentOffset = CGPointMake(0, -1 * self.tableView.contentInset.top);
    
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
        
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        [InsightsLogger.sharedInstance openAllVisiblePostInsightsInTableView:self.tableView seenIn:InsightSeenInCampView];
        
        [self styleOnAppear];
    }
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [InsightsLogger.sharedInstance closeAllVisiblePostInsightsInTableView:self.tableView];
    
    [self.view endEditing:true];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)setupCoverPhotoView {
    self.coverPhotoView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 140)];
    self.coverPhotoView.backgroundColor = self.theme;
    self.coverPhotoView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverPhotoView.clipsToBounds = true;
    [self.view insertSubview:self.coverPhotoView belowSubview:self.tableView];
    UIView *overlayView = [[UIView alloc] initWithFrame:self.coverPhotoView.bounds];
    overlayView.backgroundColor = self.theme;
    overlayView.alpha = 0;
    overlayView.tag = 10;
    //[self.imagePreviewView addSubview:overlayView];
    [self updateCoverPhotoView];
}
- (void)updateCoverPhotoView {
//    if (1 == 2) {
//        self.tableView.contentInset = UIEdgeInsetsMake(152, 0, self.tableView.contentInset.bottom, 0);
//        //[self.coverPhotoView sd_setImageWithURL:[NSURL URLWithString:self.link.attributes.images[0]]];
//    }
//    else {
        self.tableView.contentInset = UIEdgeInsetsMake(120, 0, self.tableView.contentInset.bottom, 0);
        self.coverPhotoView.image = nil;
//    }
    [self.tableView.refreshControl setBounds:CGRectMake(self.tableView.refreshControl.bounds.origin.x, self.tableView.contentInset.top, self.tableView.refreshControl.bounds.size.width, self.tableView.refreshControl.bounds.size.height)];
    self.coverPhotoView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.tableView.contentInset.top + (-1 * self.tableView.contentOffset.y));
    UIVisualEffectView *overlayView = [self.coverPhotoView viewWithTag:10];
    overlayView.frame = self.coverPhotoView.bounds;
}

- (NSString *)campIdentifier {
    if (self.camp.identifier != nil) return self.camp.identifier;
    if (self.camp.attributes.identifier != nil) return self.camp.attributes.identifier;
    
    return nil;
}

- (void)dealloc {    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)newPostBegan:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil && [tempPost.attributes.postedIn.identifier isEqualToString:self.camp.identifier] && !tempPost.attributes.parent) {
        // TODO: Check for image as well
        [self.tableView.stream addTempPost:tempPost];
        
        [self determineEmptyStateVisibility];
        
        [self.tableView refreshAtTop];
    }
}
- (void)newPostCompleted:(NSNotification *)notification {
    NSDictionary *info = notification.object;
    NSString *tempId = info[@"tempId"];
    Post *post = info[@"post"];
    
    if (post != nil && [post.attributes.postedIn.identifier isEqualToString:self.camp.identifier] && !post.attributes.parent) {
        // TODO: Check for image as well
        [self.tableView.stream removeLoadedCursor:self.tableView.stream.prevCursor];
        
        [self.tableView.stream removeTempPost:tempId];
        
        [self determineEmptyStateVisibility];
        
        [self getPostsWithCursor:StreamPagingCursorTypePrevious];
    }
}
// TODO: Allow tap to retry for posts
- (void)newPostFailed:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil && [tempPost.attributes.postedIn.identifier isEqualToString:self.camp.identifier] && !tempPost.attributes.parent) {
        [self.tableView.stream removeTempPost:tempPost.tempId];
        [self.tableView refreshAtTop];
        
        [self determineEmptyStateVisibility];
    }
}

- (void)postDeleted:(NSNotification *)notification {
    Post *post = notification.object;
    
    if ([post.attributes.postedIn.identifier isEqualToString:self.camp.identifier]) {
        [self determineEmptyStateVisibility];
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
        [self updateTheme];
        if ([self isEqual:self.navigationController.topViewController]) {
            [self.launchNavVC.searchView updateSearchText:camp.attributes.title];
            self.title = camp.attributes.title;
        }
        
        // update table view state based on new Camp object
        // if and only if [self canViewPosts] changes values after setting the new camp, should we update the table view
        BOOL canViewPosts_After = [self canViewPosts];
        if (canViewPosts_Before == false && canViewPosts_After == true) {
            [self loadCampContent];
        }
        else if (self.tableView.stream.posts.count == 0) {
            [self determineEmptyStateVisibility];
        }
        else {
            // loop through content and replace any occurences of this Camp with the new object
            [self.tableView.stream updateCampObjects:camp];
        }
        
        if ([self.camp isPrivate] && self.tableView.stream.posts.count > 0 && ([self.camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_LEFT] || [self.camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_NO_RELATION])) {
            self.tableView.stream.pages = [[NSMutableArray alloc] init];
            self.tableView.stream.posts = @[];
            
            [self showErrorViewWithType:ErrorViewTypeLocked title:@"Private Camp" description:@"Request access above to get access to this Camp’s posts" actionTitle:nil actionBlock:nil];
        }
        
        [self.tableView hardRefresh];
    }
}
- (void)setCamp:(Camp *)camp {
    if (camp != _camp) {
        _camp = camp;
        
        // update table view parent object
        self.tableView.parentObject = camp;
        self.startCampUpsellView.camp = self.camp;
    }
}

- (void)updateComposeInputView {
    [self.composeInputView setMediaTypes:self.camp.attributes.context.camp.permissions.post];
    if ([self.camp.attributes.context.camp.permissions canPost] && [self isActive]) {
        [self showComposeInputView];
        [self.composeInputView updatePlaceholders];
    }
    else {
        [self hideComposeInputView];
    }
}

- (BOOL)isActive {
    BOOL publicCamp = ![self.camp isPrivate];
    BOOL isChannel = [self.camp.attributes.display.format isEqualToString:@"channel"];
    return isChannel || !(self.camp.attributes.summaries.counts.posts == 0 && publicCamp && self.camp.attributes.summaries.counts.members < [Session sharedInstance].defaults.camp.membersThreshold);
}

- (void)loadCamp {
    if (self.camp.identifier.length > 0 || self.camp.attributes.identifier.length > 0) {
        [self.tableView refreshAtTop];
        if (self.camp.attributes.context == nil) {
            // let's fetch info to fill in the gaps
            self.composeInputView.hidden = true;
        }
        
        if (!self.camp.identifier || self.camp.identifier.length == 0) {
            // no camp identifier yet, don't show the ••• icon just yet
            [self hideMoreButton];
        }
        
        // load camp info before loading posts
        if ([self canViewPosts]) {
            self.tableView.visualError = nil;
        }
        [self getCampInfo];
    }
    else {
        // camp not found
        self.tableView.hidden = true;
        
        [self showErrorViewWithType:ErrorViewTypeNotFound title:@"Camp Not Found"description:@"We couldn’t find the Camp\nyou were looking for" actionTitle:@"Create New Camp" actionBlock:^{
            [Launcher openCreateCamp];
        }];
        
        [self hideMoreButton];
    }
}
- (void)getCampInfo {
    NSString *url = [NSString stringWithFormat:@"camps/%@", [self campIdentifier]];
    
    NSLog(@"self.camp identifier: %@", [self campIdentifier]);
    NSLog(@"%@", self.camp.attributes.identifier);
    
    NSDictionary *params = @{};
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *responseData = (NSDictionary *)responseObject[@"data"];
        
        // this must go before we set self.camp to the new Camp object
        NSString *colorBefore = self.camp.attributes.color;
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
        
        if (![self isPreview]) {
            [[Session sharedInstance] addToRecents:self.camp];
        }
        
        // update the theme color (in case we didn't know the camp's color before
        if (![colorBefore isEqualToString:self.camp.attributes.color]) requiresColorUpdate = true;
        if (requiresColorUpdate) {
            [self updateTheme];
        }
        
        // update the title (in case we didn't know the camp's title before)
        self.title = self.camp.attributes.title;
        [self.launchNavVC.searchView updateSearchText:self.title];

        [self.tableView reloadData];
        
        // update the compose input placeholder (in case we didn't know the camp's title before)
        [self updateComposeInputView];
        
        [self positionErrorView];
        
        // Now that the VC's Camp object is complete,
        // Go on to load the camp content
        [self loadCampContent];
        
        if ([self.camp.attributes.context.camp.permissions canUpdate]) {
            if (!self.loading && self.camp.attributes.summaries.counts != nil && self.camp.attributes.summaries.counts.posts > 0 &&  self.camp.attributes.summaries.counts.icebreakers == 0 && ![[NSUserDefaults standardUserDefaults] boolForKey:@"upsells/icebreaker"]) {
                [self showAddIcebreakerUpsell];
            }
        }
        
        [self showMoreButton];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"CampViewController / getCamp() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
        NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
        NSInteger statusCode = httpResponse.statusCode;
        if (statusCode == 404) {
            [self showErrorViewWithType:ErrorViewTypeNotFound title:@"Camp Not Found"description:@"We couldn’t find the Camp\nyou were looking for" actionTitle:@"Create New Camp" actionBlock:^{
                [Launcher openCreateCamp];
            }];
            
            self.camp = nil;
            
            [self hideMoreButton];
        }
        else if (statusCode == 401) {
            [self showErrorViewWithType:ErrorViewTypeLocked title:@"Private Camp" description:@"Request access above to get access to this Camp’s posts" actionTitle:nil actionBlock:nil];
            
            self.tableView.stream.posts = @[];
            self.tableView.stream.pages = [[NSMutableArray alloc] init];
        }
        else {
            [self showErrorViewWithType:([HAWebService hasInternet] ? ErrorViewTypeGeneral : ErrorViewTypeNoInternet) title:([HAWebService hasInternet] ? @"Error Loading" : @"No Internet") description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
                self.loading = true;
                [self refresh];
            }];
        }
        
        self.loading = false;
        [self.tableView refreshAtTop];
        
        [self positionErrorView];
    }];
}

- (void)showAddIcebreakerUpsell {
    BFTipObject *tipObject = [BFTipObject tipWithCreatorType:BFTipCreatorTypeCamp creator:self.camp title:[NSString stringWithFormat:@"Tap to Add an Icebreaker ❄️"] text:@"Introduce new members to the Camp with an Icebreaker post when they join" cta:nil imageUrl:nil action:^{
        SetAnIcebreakerViewController *mibvc = [[SetAnIcebreakerViewController alloc] init];
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
    }];
    [[BFTipsManager manager] presentTip:tipObject completion:^{
        NSLog(@"presentTip() completion");
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
    self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, self.composeInputView.frame.size.height - [UIApplication sharedApplication].delegate.window.safeAreaInsets.bottom, 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, self.tableView.contentInset.left, self.tableView.contentInset.bottom, self.tableView.contentInset.right);
    
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
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, self.tableView.contentInset.left, self.tableView.contentInset.bottom, self.tableView.contentInset.right);
    
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
        [self updateComposeInputView];
        
        [self getPostsWithCursor:StreamPagingCursorTypeNone];
    }
    else {
        [self hideComposeInputView];
        
        self.loading = false;
        self.tableView.loadingMore = false;
        
        if ([self.camp.attributes isSuspended] ||
            [self.camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_BLOCKED]) { // Camp has been blocked
            [self showErrorViewWithType:ErrorViewTypeBlocked title:@"Camp Not Available" description:@"This Camp is no longer available" actionTitle:nil actionBlock:nil];
        }
        else if ([self.camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_BLOCKED]) { // blocked from Camp
            [self showErrorViewWithType:ErrorViewTypeBlocked title:@"Blocked By Camp" description:@"Your account is blocked from creating and viewing posts in this Camp" actionTitle:nil actionBlock:nil];
        }
        else if ([self.camp isPrivate]) { // not blocked, not member
            // private camp but not a member yet
            [self showErrorViewWithType:ErrorViewTypeLocked title:@"Private Camp" description:@"Request access above to get access to this Camp’s posts" actionTitle:nil actionBlock:nil];
            
            self.tableView.stream.posts = @[];
            self.tableView.stream.pages = [[NSMutableArray alloc] init];
        }
        else {
            [self showErrorViewWithType:ErrorViewTypeNotFound title:@"Camp Not Found"description:@"We couldn’t find the Camp\nyou were looking for" actionTitle:@"Create New Camp" actionBlock:^{
                [Launcher openCreateCamp];
            }];
            
            [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.launchNavVC.rightActionButton.alpha = 0;
            } completion:^(BOOL finished) {
            }];
        }
        
        [self.tableView refreshAtTop];
        
        [self positionErrorView];
    }
}
- (void)updateTheme {
    UIColor *theme = [UIColor fromHex:self.camp.attributes.color adjustForOptimalContrast:false];
    self.theme = theme;
    self.view.tintColor = self.theme;
    
    UIColor *themeAdjustedForDarkMode = [UIColor fromHex:self.camp.attributes.color adjustForOptimalContrast:true];
    [UIView animateWithDuration:0.35f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        if (self.launchNavVC.topViewController == self) {
            [self.launchNavVC updateBarColor:theme animated:false];
        }
        
        self.composeInputView.textView.tintColor = themeAdjustedForDarkMode;
        self.composeInputView.postButton.backgroundColor = themeAdjustedForDarkMode;
        self.composeInputView.postButton.tintColor = [UIColor highContrastForegroundForBackground:self.composeInputView.postButton.backgroundColor];
        self.coverPhotoView.backgroundColor = theme;
        
        if ([UIColor useWhiteForegroundForColor:theme]) {
            self.tableView.refreshControl.tintColor = [UIColor whiteColor];
        }
        else {
            self.tableView.refreshControl.tintColor = [UIColor blackColor];
        }
    } completion:^(BOOL finished) {
    }];
}

- (void)setupStartCampUpsellView {
    self.startCampUpsellView = [[StartCampUpsellView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100)];
    self.startCampUpsellView.hidden = true;
}

- (void)setupComposeInputView {
    CGFloat bottomPadding = [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.bottom;
    CGFloat collapsed_inputViewHeight = ((self.composeInputView.textView.frame.origin.y * 2) + self.composeInputView.textView.frame.size.height) + bottomPadding;
    
    self.composeInputView = [[ComposeInputView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - collapsed_inputViewHeight, self.view.frame.size.width, collapsed_inputViewHeight)];
    self.composeInputView.delegate = self;
    self.composeInputView.hidden = true;
    
    self.composeInputView.parentViewController = self;
    UIColor *themeAdjustedForDarkMode = [UIColor fromHex:[UIColor toHex:self.theme] adjustForOptimalContrast:true];
    self.composeInputView.postButton.backgroundColor = themeAdjustedForDarkMode;
    self.composeInputView.postButton.tintColor = [UIColor highContrastForegroundForBackground:self.composeInputView.postButton.backgroundColor];
//    self.composeInputView.addMediaButton.backgroundColor = self.composeInputView.postButton.backgroundColor;
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
        [Launcher openComposePost:self.camp inReplyTo:nil withMessage:self.composeInputView.textView.text media:nil  quotedObject:nil];
    }];
    
    [self.view addSubview:self.composeInputView];
    
    self.composeInputView.tintColor = self.view.tintColor;
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
        [BFAPI createPost:params postingIn:self.camp replyingTo:nil attachments:nil];
        
        [self.composeInputView reset];
        
        [self.view endEditing:true];
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
                        ![self.camp.attributes isSuspended] && // Camp not blocked
                        ![self.camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_BLOCKED] && // User blocked by Camp
                        (![self.camp isPrivate] || // (public camp OR
                         [self.camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_MEMBER]);
    
    return canViewPosts;
}

- (void)getPostsWithCursor:(StreamPagingCursorType)cursorType {
    self.tableView.hidden = false;
    if (self.tableView.stream.posts.count == 0) {
        self.startCampUpsellView.hidden = true;
        self.loading = true;
        [self.tableView refreshAtTop];
    }
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (cursorType == StreamPagingCursorTypeNext) {
        [params setObject:self.tableView.stream.nextCursor forKey:@"cursor"];
    }
    else if (cursorType == StreamPagingCursorTypePrevious && self.tableView.stream.prevCursor.length > 0) {
        [params setObject:self.tableView.stream.prevCursor forKey:@"cursor"];
    }
    
    if ([params objectForKey:@"cursor"]) {
        [self.tableView.stream addLoadedCursor:params[@"cursor"]];
    }
    
    NSString *url = [NSString stringWithFormat:@"camps/%@/stream", [self campIdentifier]];
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        self.tableView.scrollEnabled = true;
        
        PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:responseObject error:nil];
        if (page.data.count > 0) {
            if (cursorType == StreamPagingCursorTypeNone) {
                if (self.tableView.stream.prevCursor) {
                    [self.tableView.stream removeLoadedCursor:self.tableView.stream.prevCursor];
                }
                if (self.tableView.stream.nextCursor) {
                    [self.tableView.stream removeLoadedCursor:self.tableView.stream.nextCursor];
                }
                
                self.tableView.stream.posts = @[];
                self.tableView.stream.pages = [[NSMutableArray alloc] init];
                [self.tableView.stream appendPage:page];
            }
            if (cursorType == StreamPagingCursorTypePrevious) {
                [self.tableView.stream prependPage:page];
            }
            else if (cursorType == StreamPagingCursorTypeNext) {
                [self.tableView.stream appendPage:page];
            }
        }
    
        self.loading = false;
        
        self.tableView.loadingMore = false;
        
        [self determineEmptyStateVisibility];
        
        if (cursorType == StreamPagingCursorTypeNext) {
            [self.tableView refreshAtBottom];
        }
        else {
            [self.tableView refreshAtTop];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"CampViewController / getPostsWithMaxId() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
        NSInteger statusCode = httpResponse.statusCode;
        if (statusCode == 404) {
            [self showErrorViewWithType:ErrorViewTypeNotFound title:@"Camp Not Found"description:@"We couldn’t find the Camp\nyou were looking for" actionTitle:@"Create New Camp" actionBlock:^{
                [Launcher openCreateCamp];
            }];
            
            self.camp = nil;
            
            [self hideMoreButton];
        }
        else if (statusCode == 401) {
            [self showErrorViewWithType:ErrorViewTypeLocked title:@"Private Camp" description:@"Request access above to get access to this Camp’s posts" actionTitle:nil actionBlock:nil];
            
            self.tableView.stream.posts = @[];
            self.tableView.stream.pages = [[NSMutableArray alloc] init];
        }
        else {
            [self showErrorViewWithType:([HAWebService hasInternet] ? ErrorViewTypeGeneral : ErrorViewTypeNoInternet) title:([HAWebService hasInternet] ? @"Error Loading" : @"No Internet") description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
                self.loading = true;
                [self refresh];
            }];
        }
        
        self.loading = false;
        self.tableView.loadingMore = false;
        [self.tableView refreshAtTop];
        
        [self positionErrorView];
    }];
}
- (void)determineEmptyStateVisibility {
    if (self.tableView.stream.posts.count == 0 && !self.loading) {
        BOOL isMember = [self.camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_MEMBER];
        
        if ([self isActive] && ![self.camp isPrivate]) {
            // it's public and bigger than the minimum
            self.startCampUpsellView.hidden = true;
            
            if ([self canViewPosts]) {
                [self showErrorViewWithType:ErrorViewTypeNoPosts title:@"No Posts Yet" description:nil actionTitle:nil actionBlock:nil];
            }
            
            [self positionErrorView];
        }
        else if (([self.camp isPrivate] && isMember) ||
                  ![self.camp isPrivate]) {
            self.startCampUpsellView.hidden = false;
            
            // 3 is our threshold (for now!)
            self.tableView.visualError = nil;
            
            [self positionErrorView];
        }
        else {
            self.startCampUpsellView.hidden = true;
            
            [self positionErrorView];
        }
    }
    else {
        self.tableView.visualError = nil;
    }
}
- (void)determineErorrViewVisibility {
    [self showErrorViewWithType:([HAWebService hasInternet] ? ErrorViewTypeGeneral : ErrorViewTypeNoInternet) title:([HAWebService hasInternet] ? @"Error Loading" : @"No Internet") description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
        self.loading = true;
        [self refresh];
    }];
}
- (void)setLoading:(BOOL)loading {
    if (loading != _loading) {
        _loading = loading;
        
        self.tableView.loading = _loading;
    }
}
- (void)positionErrorView {
    CGFloat firstSectionHeight = 0;
    
    if ([self respondsToSelector:@selector(heightForFirstSectionHeader)]) {
        firstSectionHeight += [self heightForFirstSectionHeader];
    }
    
    for (NSInteger i = 0; i < [self.tableView numberOfRowsInSection:0]; i++) {
        CGFloat cellHeight = [self.tableView tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        firstSectionHeight += cellHeight;
    }
    
    if ([self respondsToSelector:@selector(heightForFirstSectionFooter)]) {
        firstSectionHeight += [self heightForFirstSectionFooter];
    }

    self.startCampUpsellView.frame = CGRectMake(self.startCampUpsellView.frame.origin.x, 40, self.startCampUpsellView.frame.size.width, self.startCampUpsellView.frame.size.height);
    
    [self.tableView reloadData];
}
- (void)setupTableView {
    self.tableView = [[RSTableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.navigationController.navigationBar.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView.dataType = RSTableViewTypeCamp;
    self.tableView.tableViewStyle = RSTableViewStyleGrouped;
    self.tableView.loadingMore = false;
    self.tableView.extendedDelegate = self;
    [self.tableView registerClass:[CampHeaderCell class] forCellReuseIdentifier:campHeaderCellIdentifier];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.tableView.refreshControl addTarget:self
                                action:@selector(refresh)
                      forControlEvents:UIControlEventValueChanged];
    if ([UIColor useWhiteForegroundForColor:self.theme]) {
        self.tableView.refreshControl.tintColor = [UIColor whiteColor];
    }
    else {
        self.tableView.refreshControl.tintColor = [UIColor blackColor];
    }
    [self.view addSubview:self.tableView];
}
- (void)refresh {
    [self loadCamp];
}

- (void)showErrorViewWithType:(ErrorViewType)type title:(NSString *)title description:(NSString *)description actionTitle:(nullable NSString *)actionTitle actionBlock:(void (^ __nullable)(void))actionBlock {
    self.tableView.visualError = [BFVisualError visualErrorOfType:type title:title description:description actionTitle:actionTitle actionBlock:actionBlock];
    [self.tableView reloadData];
    
    self.startCampUpsellView.hidden = true;
}

- (void)tableView:(id)tableView didRequestNextPageWithMaxId:(NSInteger)maxId {
    if (self.tableView.stream.nextCursor.length > 0 && ![self.tableView.stream hasLoadedCursor:self.tableView.stream.nextCursor]) {
        [self getPostsWithCursor:StreamPagingCursorTypeNext];
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
    return textView.text.length + (text.length - range.length) <= [Session sharedInstance].defaults.post.maxLength;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)tableViewDidScroll:(UITableView *)tableView {
    if (tableView == self.tableView) {
        if (self.tableView.contentOffset.y > (-1 * self.tableView.contentInset.top)) {
            self.coverPhotoView.frame = CGRectMake(0, 0.5 * (-self.tableView.contentOffset.y - self.tableView.contentInset.top), self.view.frame.size.width, self.tableView.contentInset.top);
        }
        else {
            self.coverPhotoView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.tableView.contentInset.top + (-self.tableView.contentOffset.y - self.tableView.contentInset.top));
        }
        
        CGFloat percentageHidden = ((self.tableView.contentOffset.y + self.tableView.contentInset.top) / (self.tableView.contentInset.top * .75));
        UIView *overlayView = [self.coverPhotoView viewWithTag:10];
        overlayView.frame = CGRectMake(0, 0, self.coverPhotoView.frame.size.width, self.coverPhotoView.frame.size.height);
        overlayView.alpha = percentageHidden;
    }
}

- (void)openCampActions {
    // TODO: check that the user is actually an Admin, not just a member
    BOOL isMember              = [self.camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_MEMBER];
    BOOL isAdmin               = [self.camp.attributes.context.camp.membership.role.type isEqualToString:CAMP_ROLE_ADMIN];
    BOOL canUpdate             = [self.camp.attributes.context.camp.permissions canUpdate];
    BOOL campPostNotifications = self.camp.attributes.context.camp.membership.subscription != nil;
    
    BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:(self.camp.attributes.identifier.length > 0 ? self.camp.attributes.title : nil) message:(self.camp.attributes.identifier.length > 0 ? [@"#" stringByAppendingString:self.camp.attributes.identifier] : nil) preferredStyle:BFAlertControllerStyleActionSheet]; // old title: @"\n\n\n\n\n\n"

    if (canUpdate) {
        BFAlertAction *leaveCamp = [BFAlertAction actionWithTitle:([self.camp isChannel] ? @"Unsubscribe" : @"Leave Camp") style:BFAlertActionStyleDestructive handler:^{
            // confirm action
            BOOL privateCamp = [self.camp isPrivate];
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

            BFAlertController *confirmDeletePostActionSheet = [BFAlertController alertControllerWithTitle:([self.camp isChannel] ? @"Unsubscribe?" : @"Leave Camp?") message:message preferredStyle:BFAlertControllerStyleAlert];

            BFAlertAction *confirmLeaveCamp = [BFAlertAction actionWithTitle:([self.camp isChannel] ? @"Unsubscribe" : @"Leave") style:BFAlertActionStyleDestructive handler:^{
                [BFAPI unfollowCamp:self.camp completion:^(BOOL success, id responseObject) {

                }];

                BFContext *context = [[BFContext alloc] initWithDictionary:[self.camp.attributes.context toDictionary] error:nil];
                context.camp.status = CAMP_STATUS_LEFT;
                self.camp.attributes.context = context;

                [[NSNotificationCenter defaultCenter] postNotificationName:@"CampUpdated" object:self.camp];
            }];
            [confirmDeletePostActionSheet addAction:confirmLeaveCamp];

            BFAlertAction *cancelLeaveCamp = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
            [confirmDeletePostActionSheet addAction:cancelLeaveCamp];

            [UIViewParentController(self) presentViewController:confirmDeletePostActionSheet animated:true completion:nil];
        }];
        [actionSheet addAction:leaveCamp];
        
        BFAlertAction *editCamp = [BFAlertAction actionWithTitle:@"Edit Camp" style:BFAlertActionStyleDefault handler:^{
            EditCampViewController *epvc = [[EditCampViewController alloc] init];
            epvc.themeColor = [UIColor fromHex:self.camp.attributes.color];
            epvc.view.tintColor = epvc.themeColor;
            epvc.camp = self.camp;
            
            SimpleNavigationController *newNavController = [[SimpleNavigationController alloc] initWithRootViewController:epvc];
            newNavController.transitioningDelegate = [Launcher sharedInstance];
            newNavController.modalPresentationStyle = UIModalPresentationFullScreen;
            
            [self.launchNavVC presentViewController:newNavController animated:YES completion:nil];
        }];
        [actionSheet addAction:editCamp];
    }
    
    if (!isAdmin) {
        BFAlertAction *reportCamp = [BFAlertAction actionWithTitle:[NSString stringWithFormat:@"Report"] style:BFAlertActionStyleDestructive handler:^ {
            // confirm action
            BFAlertController *saveAndOpenTwitterConfirm = [BFAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Report %@", self.camp.attributes.title] message:[NSString stringWithFormat:@"Are you sure you would like to report this Camp?"] preferredStyle:BFAlertControllerStyleAlert];
            
            BFAlertAction *alertCancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:^{
                NSLog(@"cancel report camp");
            }];
            [saveAndOpenTwitterConfirm addAction:alertCancel];
            
            [[Launcher topMostViewController] presentViewController:saveAndOpenTwitterConfirm animated:true completion:nil];
        }];
        [actionSheet addAction:reportCamp];
    }
    
    NSString *campShareLink = [NSString stringWithFormat:@"https://bonfire.camp/c/%@", self.camp.identifier];
    BOOL hasSnapchat = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"snapchat://"]];
    BOOL hasInstagram = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"instagram-stories://"]];
    BOOL hasTwitter = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]];
    
    BFAlertAction *shareCamp = [BFAlertAction actionWithTitle:@"Share Camp via..." style:BFAlertActionStyleDefault handler:^{
        if (hasSnapchat || hasInstagram || hasTwitter) {
            BFAlertController *moreOptions = [BFAlertController alertControllerWithTitle:@"Share Camp via..." message:nil preferredStyle:BFAlertControllerStyleActionSheet];
            
            if (hasTwitter) {
                BFAlertAction *shareOnTwitter = [BFAlertAction actionWithTitle:@"Twitter" style:BFAlertActionStyleDefault handler:^{
                    NSLog(@"share on snapchat");
                    
                    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://post"]]) {
                        NSString *message = [[NSString stringWithFormat:@"Check out this Camp on @yourbonfire! Join %@: %@", self.camp.attributes.title, campShareLink] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?%#[]"]];
                        
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"twitter://post?message=%@", message]] options:@{} completionHandler:nil];
                    }
                }];
                [moreOptions addAction:shareOnTwitter];
            }
            
            BFAlertAction *shareOnFacebook = [BFAlertAction actionWithTitle:@"Facebook" style:BFAlertActionStyleDefault handler:^{
                FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
                content.contentURL = [NSURL URLWithString:campShareLink];
                content.hashtag = [FBSDKHashtag hashtagWithString:@"#Bonfire"];
                [FBSDKShareDialog showFromViewController:[Launcher topMostViewController]
                                             withContent:content
                                                delegate:nil];
            }];
            [moreOptions addAction:shareOnFacebook];
            
            if (hasSnapchat) {
                BFAlertAction *shareOnSnapchat = [BFAlertAction actionWithTitle:@"Snapchat" style:BFAlertActionStyleDefault handler:^{
                    NSLog(@"share on snapchat");
                    
                    [Launcher shareCampOnSnapchat:self.camp];
                }];
                [moreOptions addAction:shareOnSnapchat];
            }
            if (hasInstagram) {
                BFAlertAction *shareOnInstagram = [BFAlertAction actionWithTitle:@"Instagram Stories" style:BFAlertActionStyleDefault handler:^{
                    NSLog(@"share on snapchat");
                    
                    [Launcher shareCampOnInstagram:self.camp];
                }];
                [moreOptions addAction:shareOnInstagram];
            }
            BFAlertAction *shareOnImessage = [BFAlertAction actionWithTitle:@"iMessage" style:BFAlertActionStyleDefault handler:^{
                NSLog(@"share on imessage");
                
                [Launcher shareOniMessage:[NSString stringWithFormat:@"Join %@ on Bonfire: %@", self.camp.attributes.title, campShareLink] image:nil];
            }];
            [moreOptions addAction:shareOnImessage];
            
            BFAlertAction *moreShareOptions = [BFAlertAction actionWithTitle:@"Other" style:BFAlertActionStyleDefault handler:^{
                [Launcher shareCamp:self.camp];
            }];
            [moreOptions addAction:moreShareOptions];
            
            BFAlertAction *cancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
            [moreOptions addAction:cancel];
            
            [actionSheet dismissViewControllerAnimated:YES completion:^{
                [[Launcher topMostViewController] presentViewController:moreOptions animated:YES completion:nil];
            }];
        }
        else {
            [Launcher shareCamp:self.camp];
        }
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
    
    BFAlertAction *cancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
    [actionSheet addAction:cancel];
    
    [self.navigationController presentViewController:actionSheet animated:true completion:nil];
}

#pragma mark - RSTableViewDelegate
- (UITableViewCell * _Nullable)cellForRowInFirstSection:(NSInteger)row {
    if (row == 0) {
        CampHeaderCell *cell = [self.tableView dequeueReusableCellWithIdentifier:campHeaderCellIdentifier forIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        
        cell.camp = self.camp;
        
        BOOL emptyCampTitle = cell.camp.attributes.title.length == 0;
        BOOL emptyCamptag = cell.camp.attributes.identifier.length == 0;
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
                if (emptyCampTitle) {
                    cell.textLabel.text = @"Camp Not Found";
                }
            }
            else {
                if (emptyCampTitle) {
                    cell.textLabel.text = [NSString stringWithFormat:@"#%@", cell.camp.attributes.identifier];
                }
            }
        }
        
        cell.followButton.hidden = (!self.loading && cell.camp.attributes.context == nil);
        
        if ([cell.camp.attributes.context.camp.permissions canUpdate]) {
            [cell.followButton updateStatus:CAMP_STATUS_CAN_EDIT];
        }
        else if (self.loading && cell.camp.attributes.context.camp.membership == nil) {
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
//    NSDictionary *upsell = [self availableCampUpsell];
//    if (upsell) {
//        UIView *upsellView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 172)];
//        upsellView.backgroundColor = [UIColor contentBackgroundColor];
//
//        TappableButton *closeButton = [[TappableButton alloc] initWithFrame:CGRectMake(upsellView.frame.size.width - 14 - 16, 16, 14, 14)];
//        closeButton.padding = UIEdgeInsetsMake(12, 12, 12, 12);
//        [closeButton setImage:[[UIImage imageNamed:@"navCloseIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
//        closeButton.tintColor = [UIColor bonfireSecondaryColor];
//        closeButton.contentMode = UIViewContentModeScaleAspectFill;
//        [closeButton bk_whenTapped:^{
//            wait(0.3, ^{
//                [self.tableView beginUpdates];
//                [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"upsells/icebreaker"];
//                [self.tableView reloadData];
//                [self.tableView endUpdates];
//            })
//        }];
//        [upsellView addSubview:closeButton];
//
//        CGFloat height = 24; // top padding
//
//        CGFloat bottomPadding = 0;
//        if ([upsell objectForKey:@"image"] && ((NSString *)upsell[@"image"]).length > 0) {
//            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:upsell[@"image"]]];
//            imageView.frame = CGRectMake(upsellView.frame.size.width / 2 - imageView.frame.size.width / 2, height, imageView.frame.size.width, imageView.frame.size.height);
//            [upsellView addSubview:imageView];
//
//            height += imageView.frame.size.height;
//            bottomPadding = 10;
//        }
//
//        if ([upsell objectForKey:@"text"] && ((NSString *)upsell[@"text"]).length > 0) {
//            UILabel *textLabel = [[UILabel alloc] init];
//            textLabel.text = upsell[@"text"];
//            textLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightMedium];
//            textLabel.textColor = [UIColor bonfirePrimaryColor];
//            textLabel.textAlignment = NSTextAlignmentCenter;
//            textLabel.frame = CGRectMake(24, height + bottomPadding, self.view.frame.size.width - (24 * 2), 0);
//            textLabel.numberOfLines = 0;
//            textLabel.lineBreakMode = NSLineBreakByWordWrapping;
//            [upsellView addSubview:textLabel];
//
//            CGFloat textHeight = ceilf([upsell[@"text"] boundingRectWithSize:CGSizeMake(textLabel.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:textLabel.font} context:nil].size.height);
//            SetHeight(textLabel, textHeight);
//
//            height += (bottomPadding + textLabel.frame.size.height);
//            bottomPadding = 12;
//        }
//
//        if ([upsell objectForKey:@"action_title"] && ((NSString *)upsell[@"action_title"]).length > 0) {
//            FollowButton *actionButton = [[FollowButton alloc] initWithFrame:CGRectMake(24, height + bottomPadding, self.view.frame.size.width - (24 * 2), 36)];
//            [actionButton setTitle:@"Add Icebreaker" forState:UIControlStateNormal];
//            [actionButton setTitleColor:[UIColor colorWithRed:0.14 green:0.64 blue:1.00 alpha:1.0] forState:UIControlStateNormal];
//            actionButton.layer.borderWidth = 1;
//            actionButton.backgroundColor = [UIColor clearColor];
//            [actionButton bk_whenTapped:upsell[@"action"]];
//            [upsellView addSubview:actionButton];
//
//            CGFloat actionHeight = 36;
//            height += (bottomPadding + actionHeight);
//        }
//
//        height += 24; // bottom padding
//        SetHeight(upsellView, height);
//
//        UIView *topLineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, upsellView.frame.size.width, (1 / [UIScreen mainScreen].scale))];
//        topLineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
//        [upsellView addSubview:topLineSeparator];
//
//        UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, upsellView.frame.size.height - (1 / [UIScreen mainScreen].scale), upsellView.frame.size.width, (1 / [UIScreen mainScreen].scale))];
//        lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
//        [upsellView addSubview:lineSeparator];
//
//        upsellView.alpha = 0;
//        upsellView.transform = CGAffineTransformMakeScale(0.5, 0.5);
//        [UIView animateWithDuration:0.8f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
//            upsellView.transform = CGAffineTransformMakeScale(1, 1);
//            upsellView.alpha = 1;
//        } completion:nil];
//
//        return upsellView;
//    }
    
    return nil;
}
- (CGFloat)heightForFirstSectionHeader {
    return CGFLOAT_MIN;
}

- (CGFloat)heightForFirstSectionFooter {
    if (![self.startCampUpsellView isHidden]) {
        return self.startCampUpsellView.frame.size.height + (40 * 2);
    }
    
    return CGFLOAT_MIN;
}
- (UIView *)viewForFirstSectionFooter
{
    if (![self.startCampUpsellView isHidden]) {
        UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.startCampUpsellView.frame.size.height + (40 * 2))];
        [container addSubview:self.startCampUpsellView];
        self.startCampUpsellView.center = CGPointMake(container.frame.size.width / 2, container.frame.size.height / 2);
        
        return container;
    }
    
    return nil;
}
- (NSDictionary *)availableCampUpsell {
    NSMutableDictionary *upsell = [[NSMutableDictionary alloc] initWithDictionary:@{
                                                                                    @"image": @"",
                                                                                    @"text": @"",
                                                                                    @"action_title": @"",
                                                                                    @"action": ^{}
                                                                                    }];
    if ([self.camp.attributes.context.camp.permissions canUpdate]) {
        if (!self.loading && self.camp.attributes.summaries.counts != nil && self.camp.attributes.summaries.counts.posts > 0 &&  self.camp.attributes.summaries.counts.icebreakers == 0 && ![[NSUserDefaults standardUserDefaults] boolForKey:@"upsells/icebreaker"]) {
            [upsell setObject:@"icebreakerSnowflake" forKey:@"image"];
            [upsell setObject:@"Introduce new members to the Camp\nwith an Icebreaker post when they join" forKey:@"text"];
            [upsell setObject:@"Add Icebreaker" forKey:@"action_title"];
            [upsell setObject:^{
                SetAnIcebreakerViewController *mibvc = [[SetAnIcebreakerViewController alloc] init];
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
