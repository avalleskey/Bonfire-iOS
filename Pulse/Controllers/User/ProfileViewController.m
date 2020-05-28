//
//  ProfileViewController.m
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import "ProfileViewController.h"
#import "ComplexNavigationController.h"
#import "SimpleNavigationController.h"
#import "BFVisualErrorView.h"
#import "ProfileHeaderCell.h"
#import "BotHeaderCell.h"
#import "UIColor+Palette.h"
#import "Launcher.h"
#import "SettingsTableViewController.h"
#import "InsightsLogger.h"
#import "ProfileCampsListViewController.h"
#import "HAWebService.h"
#import <UIImageView+WebCache.h>
#import "ButtonCell.h"
#import "BFHeaderView.h"
#import "SpacerCell.h"
#import "BFAlertController.h"
#import "UIView+BFEffects.h"

#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
@import Firebase;

@interface ProfileViewController () {
    int previousTableViewYOffset;
    CGFloat coverPhotoHeight;
}

@property (nonatomic) BOOL shimmering;

@property CGFloat minHeaderHeight;
@property CGFloat maxHeaderHeight;

@property (nonatomic, strong) ComplexNavigationController *launchNavVC;

@end

@implementation ProfileViewController

static NSString * const profileHeaderCellIdentifier = @"ProfileHeaderCell";
static NSString * const botHeaderCellIdentifier = @"BotHeaderCell";
static NSString * const buttonCellReuseIdentifier = @"ButtonCell";
static NSString * const spacerCellReuseIdentifier = @"SpacerCell";
static NSString * const blankCellReuseIdentifier = @"BlankCell";

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.tintColor = self.theme;
    
    self.launchNavVC = (ComplexNavigationController *)self.navigationController;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] init];
    
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
    
    [self setupTableView];
    [self setupCoverPhotoView];
    
    self.loading = true;
    [self loadUser];
    
    // Add Observers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
    if ([self isCurrentUser]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostBegan:) name:@"NewPostBegan" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostCompleted:) name:@"NewPostCompleted" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostFailed:) name:@"NewPostFailed" object:nil];
    }
    else {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userContextUpdated:) name:@"UserContextUpdated" object:nil];
    }
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Profile" screenClass:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self styleOnAppear];
    
    if (!([self isBeingPresented] || [self isMovingToParentViewController])) {
        [InsightsLogger.sharedInstance openAllVisiblePostInsightsInTableView:self.tableView seenIn:InsightSeenInProfileView];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [InsightsLogger.sharedInstance closeAllVisiblePostInsightsInTableView:self.tableView];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupCoverPhotoView {
    self.coverPhotoView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 140)];
    self.coverPhotoView.backgroundColor = self.theme;
    self.coverPhotoView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverPhotoView.clipsToBounds = true;
    [self.view insertSubview:self.coverPhotoView belowSubview:self.tableView];
    UIView *overlayView = [[UIView alloc] initWithFrame:self.coverPhotoView.bounds];
    overlayView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2f];
    overlayView.alpha = 0;
    overlayView.tag = 10;
    [self.coverPhotoView addSubview:overlayView];
    [self updateCoverPhotoView];
    
    CABasicAnimation *opacityAnimation;
    opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.autoreverses = true;
    opacityAnimation.fromValue = [NSNumber numberWithFloat:0];
    opacityAnimation.toValue = [NSNumber numberWithFloat:1];
    opacityAnimation.duration = 1.f;
    opacityAnimation.fillMode = kCAFillModeBoth;
    opacityAnimation.repeatCount = HUGE_VALF;
    opacityAnimation.removedOnCompletion = false;
    [overlayView.layer addAnimation:opacityAnimation forKey:@"opacityAnimation"];
}
- (void)updateCoverPhotoView {
    coverPhotoHeight = PROFILE_HEADER_EDGE_INSETS.top + PROFILE_HEADER_AVATAR_BORDER_WIDTH + ceilf(PROFILE_HEADER_AVATAR_SIZE * 0.65);
    
    NSLog(@"profile cover photo height: %f", coverPhotoHeight);
    if (self.user.attributes.media.cover.suggested.url.length > 0) {
        [self.coverPhotoView sd_setImageWithURL:[NSURL URLWithString:self.user.attributes.media.cover.suggested.url]];
    
        // add gradient overlay
        UIColor *topColor = [UIColor colorWithWhite:0 alpha:0.5];
        UIColor *bottomColor = [UIColor colorWithWhite:0 alpha:0];

        NSArray *gradientColors = [NSArray arrayWithObjects:(id)topColor.CGColor, (id)bottomColor.CGColor, nil];
        NSArray *gradientLocations = [NSArray arrayWithObjects:[NSNumber numberWithInt:0.0],[NSNumber numberWithInt:1.0], nil];

        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.colors = gradientColors;
        gradientLayer.locations = gradientLocations;
        gradientLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, coverPhotoHeight);
        [self.coverPhotoView.layer addSublayer:gradientLayer];
    }
    else {
        self.coverPhotoView.image = nil;
        for (CALayer *layer in self.coverPhotoView.layer.sublayers) {
            if ([layer isKindOfClass:[CAGradientLayer class]]) {
                [layer removeFromSuperlayer];
            }
        }
    }
    
    // updat the scroll distance
    if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
        ((ComplexNavigationController *)self.navigationController).onScrollLowerBound = coverPhotoHeight * .3;
    }
    else if ([self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
        ((SimpleNavigationController *)self.navigationController).onScrollLowerBound = coverPhotoHeight * .3;
    }
    
    self.coverPhotoView.frame = CGRectMake(0, 0, self.view.frame.size.width, coverPhotoHeight);
}

- (void)newPostBegan:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil) {
        // TODO: Check for image as well
//        [self.tableView.stream addTempPost:tempPost];
        [self.tableView refreshAtTop];
    }
}
- (void)newPostCompleted:(NSNotification *)notification {
    NSDictionary *info = notification.object;
    Post *post = info[@"post"];
    
    if (post != nil) {
        [self getPostsWithCursor:StreamPagingCursorTypePrevious];
    }
}
// TODO: Allow tap to retry for posts
- (void)newPostFailed:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil) {
        // TODO: Check for image as well
//        [self.tableView.stream removeTempPost:tempPost.tempId];
        [self.tableView refreshAtTop];
    }
}

- (void)userUpdated:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[User class]]) {
        User *user = notification.object;
        if ([user.identifier isEqualToString:self.user.identifier]) {
            self.user = user;
            
            [self updateTheme];
            
            [self reloadHeaderCell];
        }
    }
}
- (void)userContextUpdated:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[User class]]) {
        User *user = notification.object;
        self.user = user;
        
        [self reloadHeaderCell];
    }
}

- (void)reloadHeaderCell {
    // TODO: Test this
    [UIView setAnimationsEnabled:false];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    [UIView setAnimationsEnabled:true];
}

- (NSString *)userIdentifier {
    if (self.user.identifier != nil) return self.user.identifier;
    if (self.user.attributes.identifier != nil) return self.user.attributes.identifier;
    
    if (self.bot.identifier != nil) return self.bot.identifier;
    if (self.bot.attributes.identifier != nil) return self.bot.attributes.identifier;
    
    return nil;
}
- (NSString *)matchingCurrentUserIdentifier {
    // return matching identifier type for the current user
    if (self.user.identifier != nil) return [Session sharedInstance].currentUser.identifier;
    if (self.user.attributes.identifier != nil) return [Session sharedInstance].currentUser.attributes.identifier;
    
    return nil;
}

- (BOOL)isCurrentUser {
    return [self userIdentifier] != nil && [[self userIdentifier] isEqualToString:[self matchingCurrentUserIdentifier]];
}
- (BOOL)canViewPosts {
    if ([self currentUserIsBlocked] || [self identityIsBlocked]) {
        return false;
    }
    
    return true;
}
- (BOOL)isBot {
    return self.bot;
}

- (BOOL)identityIsBlocked {
    Identity *identity;
    if (self.user) {
        if ([self isCurrentUser]) return false;
        
        identity = self.user;
    }
    else if (self.bot) {
        identity = self.bot;
    }
    else {
        return false;
    }
    
    return [identity.attributes.context.me.status isEqualToString:USER_STATUS_BLOCKS] || [identity.attributes.context.me.status isEqualToString:USER_STATUS_BLOCKS_BOTH];
}
- (BOOL)currentUserIsBlocked {
    Identity *identity;
    if (self.user) {
        if ([self isCurrentUser]) return false;
        
        identity = self.user;
    }
    else if (self.bot) {
        identity = self.bot;
    }
    else {
        return false;
    }
    
    return [identity.attributes.context.me.status isEqualToString:USER_STATUS_BLOCKED] || [identity.attributes.context.me.status isEqualToString:USER_STATUS_BLOCKS_BOTH];
}

- (void)openProfileActions {
    BOOL identityIsBlocked = [self identityIsBlocked];
        
    Identity *identity;
    BFAlertController *actionSheet;
    
    if (self.user)  {
        identity = self.user;
        actionSheet = [BFAlertController alertControllerWithTitle:self.user.attributes.displayName message:[@"@" stringByAppendingString:self.user.attributes.identifier] preferredStyle:BFAlertControllerStyleActionSheet];
    }
    else if (self.bot) {
        identity = self.bot;
        actionSheet = [BFAlertController alertControllerWithTitle:self.bot.attributes.displayName message:[@"@" stringByAppendingString:self.bot.attributes.identifier] preferredStyle:BFAlertControllerStyleActionSheet];
    }
    else {
        return;
    }
    
    if ([self isCurrentUser]) {
        BFAlertAction *openEditProfile = [BFAlertAction actionWithTitle:@"Edit Profile" style:BFAlertActionStyleDefault handler:^{
            [Launcher openEditProfile];
        }];
        [actionSheet addAction:openEditProfile];
    }
    else {
        BFAlertAction *blockUsername = [BFAlertAction actionWithTitle:[NSString stringWithFormat:@"%@", identityIsBlocked ? @"Unblock" : @"Block"] style:BFAlertActionStyleDestructive handler:^ {
            // confirm action
            BFAlertController *alertConfirmController = [BFAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ %@", identityIsBlocked ? @"Unblock" : @"Block" , identity.attributes.displayName] message:[NSString stringWithFormat:@"Are you sure you would like to block @%@?", identity.attributes.identifier] preferredStyle:BFAlertControllerStyleAlert];
            
            BFAlertAction *alertConfirm = [BFAlertAction actionWithTitle:identityIsBlocked ? @"Unblock" : @"Block" style:BFAlertActionStyleDestructive handler:^{
                if (identityIsBlocked) {
                    [BFAPI unblockIdentity:identity completion:^(BOOL success, id responseObject) {
                        if (success) {
                            // NSLog(@"success unblocking!");
                            [self loadUser];
                        }
                        else {
                            NSLog(@"error unblocking ;(");
                        }
                    }];
                }
                else {
                    [BFAPI blockIdentity:identity completion:^(BOOL success, id responseObject) {
                        if (success) {
                            // NSLog(@"success blocking!");
                            [self loadUser];
                        }
                        else {
                            NSLog(@"error blocking ;(");
                        }
                    }];
                }
            }];
            [alertConfirmController addAction:alertConfirm];
            
            BFAlertAction *alertCancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
            [alertConfirmController addAction:alertCancel];
            
            [alertConfirmController show];
        }];
        [actionSheet addAction:blockUsername];
    }
    
    if (![self isBot] && ![self isCurrentUser] && ([self.user.attributes.context.me.status isEqualToString:USER_STATUS_FOLLOWS] || [self.user.attributes.context.me.status isEqualToString:USER_STATUS_FOLLOW_BOTH])) {
        BOOL userPostNotificationsOn = self.user.attributes.context.me.follow.me.subscription != nil;
        BFAlertAction *togglePostNotifications = [BFAlertAction actionWithTitle:[NSString stringWithFormat:@"Turn Post Notifications %@", userPostNotificationsOn ? @"Off" : @"On"] style:BFAlertActionStyleDefault handler:^{
            NSLog(@"toggle post notifications");
            // confirm action
            if ([Session sharedInstance].deviceToken.length > 0) {
                if (userPostNotificationsOn) {
                    [self.user unsubscribeFromPostNotifications];
                }
                else {
                    [self.user subscribeToPostNotifications];
                }
            }
            else {
                // confirm action
                BFAlertController *notificationsNotice = [BFAlertController alertControllerWithTitle:@"Notifications Not Enabled" message:@"In order to enable Post Notifications, you must turn on notifications for Bonfire in the iOS Settings" preferredStyle:BFAlertControllerStyleAlert];

                BFAlertAction *alertCancel = [BFAlertAction actionWithTitle:@"Okay" style:BFAlertActionStyleCancel handler:nil];
                [notificationsNotice addAction:alertCancel];

                [notificationsNotice show];
            }
        }];
        [actionSheet addAction:togglePostNotifications];
    }
    
    // 1.A.* -- Any user, any page, any following state
    BFAlertAction *shareUser = [BFAlertAction actionWithTitle:[NSString stringWithFormat:@"Share %@ via...", [self isCurrentUser] ? @"your profile" : [NSString stringWithFormat:@"@%@", identity.attributes.identifier]] style:BFAlertActionStyleDefault handler:^{
        NSLog(@"share profile");
        
        if (self.user) {
            [Launcher shareIdentity:self.user];
        }
        else if (self.bot) {
            [Launcher shareIdentity:self.bot];
        }
    }];
    [actionSheet addAction:shareUser];
    
    if ([self isCurrentUser]) {
        BFAlertAction *openSettings = [BFAlertAction actionWithTitle:@"Settings" style:BFAlertActionStyleDefault handler:^{
            [Launcher openSettings];
        }];
        [actionSheet addAction:openSettings];
    }
    
    BFAlertAction *cancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
    [actionSheet addAction:cancel];
    
    [actionSheet show];
}

- (void)showErrorViewWithType:(ErrorViewType)type title:(NSString *)title description:(NSString *)description actionTitle:(nullable NSString *)actionTitle actionBlock:(void (^ __nullable)(void))actionBlock {
    self.tableView.visualError = [BFVisualError visualErrorOfType:type title:title description:description actionTitle:actionTitle actionBlock:actionBlock];
    [self.tableView reloadData];
}

- (void)styleOnAppear {
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}

- (void)loadUser {
    if (self.user.identifier.length > 0 ||
        self.user.attributes.identifier.length > 0 ||
        self.bot.identifier.length > 0 ||
        self.bot.attributes.identifier.length > 0) {
        [self.tableView refreshAtTop];
        
        // load camp info before loading posts
        [self getUserInfo];
    }
    else {
        // camp not found
        self.tableView.hidden = true;
                
        [self showErrorViewWithType:ErrorViewTypeNotFound title:@"User Not Found" description:@"We couldn’t find the User\nyou were looking for" actionTitle:nil actionBlock:nil];
        
        [self hideMoreButton];
    }
}

- (void)setUser:(User *)user {
    if (user != _user) {
        _user = user;
    }
}
- (void)setBot:(Bot *)bot {
    if (bot != _bot) {
        _bot = bot;
    }
}

- (void)setLoading:(BOOL)loading {
    [super setLoading:loading];
    
    self.tableView.loading = loading;
}

- (void)getUserInfo {
    NSString *url = [NSString stringWithFormat:@"users/%@", [self isCurrentUser] ? @"me" : [self userIdentifier]]; // sample data
    
    self.shimmering = true;
    
    [[[HAWebService manager] authenticate] GET:url parameters:@{} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *responseData = (NSDictionary *)responseObject[@"data"];
        
        NSLog(@"response data:: user:: %@", responseData);
        
        // first page
        if ([responseData objectForKey:@"type"] && [[responseData objectForKey:@"type"] isEqualToString:@"user"]) {
            User *user = [[User alloc] initWithDictionary:responseData error:nil];
            self.user = user;
            self.bot = nil;
            
            // blast some confetti!
            if ([self.user isBirthday]) {
                [self.navigationController.view showEffect:BFEffectTypeBalloons completion:nil];
            }
            
            if (![self isCurrentUser]) [[Session sharedInstance] addToRecents:self.user];
            
            if ([self isCurrentUser]) {
                // if current user -> update Session current user object
                [[Session sharedInstance] updateUser:self.user];
            }
        }
        else if ([responseData objectForKey:@"type"] && [[responseData objectForKey:@"type"] isEqualToString:@"bot"]) {
            Bot *bot = [[Bot alloc] initWithDictionary:responseData error:nil];
            self.bot = bot;
            self.user = nil;
            
            [[Session sharedInstance] addToRecents:self.bot];
        }
        
        [self updateTheme];
        
        if (!([self isCurrentUser] && [self.navigationController isKindOfClass:[SimpleNavigationController class]])) {
            self.title = self.user.attributes.displayName;
        }
        
        if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
            if (self.user) {
                [((ComplexNavigationController *)self.navigationController).searchView updateSearchText:self.user.attributes.displayName];
            }
            else if (self.bot) {
                [((ComplexNavigationController *)self.navigationController).searchView updateSearchText:self.bot.attributes.displayName];
            }
        }
                
        [self.tableView refreshAtTop];
        
        // Now that the VC's Camp object is complete,
        // Go on to load the camp content
        [self loadUserContent];
        
        [self showMoreButton];
        
        self.shimmering = false;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"ProfileViewController / getUserInfo() - error: %@", error);
        
        NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
        NSInteger statusCode = httpResponse.statusCode;
        NSInteger errorCode = [error bonfireErrorCode];
        if (errorCode == USER_USERNAME_SUSPENDED) {
            [self displayUserAsSuspended];
        }
        else if (statusCode == 404) {
            [self showErrorViewWithType:ErrorViewTypeNotFound title:@"User Not Found" description:@"We couldn’t find the User\nyou were looking for" actionTitle:nil actionBlock:nil];
            
            [self hideMoreButton];
        }
        else {
            [self showErrorViewWithType:([HAWebService hasInternet] ? ErrorViewTypeGeneral : ErrorViewTypeNoInternet) title:([HAWebService hasInternet] ? @"Error Loading" : @"No Internet") description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
                self.loading = true;
                [self refresh];
            }];
        }
        
        self.loading = false;
        [self.tableView refreshAtTop];
        
        self.shimmering = false;
    }];
}

- (void)displayUserAsSuspended {
    // clean the user object
    User *user = [[User alloc] init];
    user.identifier = self.user.identifier;
    user.attributes = [[IdentityAttributes alloc] initWithDictionary:@{@"identifier": self.user.attributes.identifier, @"suspended": @(1)} error:nil];
    self.user = user;
    
    [self updateTheme];
    
    [self showErrorViewWithType:ErrorViewTypeGeneral title:@"Account Suspended"description:@"Bonfire suspends accounts that violate Bonfire's Community Rules" actionTitle:@"Community Rules" actionBlock:^{
        [Launcher openURL:@"https://bonfire.camp/legal/community"];
    }];
    
    [self hideMoreButton];
}

- (void)updateTheme {
    UIColor *theme;
    if (self.user) {
        theme = [UIColor fromHex:self.user.attributes.color adjustForOptimalContrast:false];
    }
    else if (self.bot) {
        theme = [UIColor fromHex:self.bot.attributes.color adjustForOptimalContrast:false];
    }
    else {
        return;
    }

    self.theme = theme;
    self.view.tintColor = self.theme;
    
    [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        if (self.navigationController.topViewController == self) {
            if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
                [(ComplexNavigationController *)self.navigationController updateBarColor:theme animated:false];
            }
            else if ([self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
                [(SimpleNavigationController *)self.navigationController updateBarColor:theme animated:false];
            }
        }
        
        self.coverPhotoView.backgroundColor = theme;
        
        if ([UIColor useWhiteForegroundForColor:self.coverPhotoView.backgroundColor]) {
            self.tableView.refreshControl.tintColor = [UIColor whiteColor];
        }
        else {
            self.tableView.refreshControl.tintColor = [UIColor blackColor];
        }
    } completion:^(BOOL finished) {
    }];
}

- (void)loadUserContent {
    if (self.user && [self canViewPosts]) {
        [self getPostsWithCursor:StreamPagingCursorTypeNone];
    }
    else {
        self.loading = false;
        self.tableView.loadingMore = false;
        [self.tableView refreshAtTop];
                
        if (self.bot) {
            [self showErrorViewWithType:ErrorViewTypeNotFound title:@"About Bots" description:@"Bots automate posts,\nmoderation, and more" actionTitle:nil actionBlock:nil];
        }
        else if ([self currentUserIsBlocked]) { // blocked by User
            [self showErrorViewWithType:ErrorViewTypeBlocked title:[NSString stringWithFormat:@"@%@ Blocked You", self.user.attributes.identifier] description:[NSString stringWithFormat:@"You are blocked from viewing and interacting with %@", self.user.attributes.displayName] actionTitle:nil actionBlock:nil];
        }
        else if ([self identityIsBlocked]) { // blocked by User
            [self showErrorViewWithType:ErrorViewTypeBlocked title:[NSString stringWithFormat:@"You Blocked @%@", self.user.attributes.identifier] description:[NSString stringWithFormat:@"Unblock their profile to view and interact with %@", self.user.attributes.displayName] actionTitle:nil actionBlock:nil];
        }
        else {
            [self showErrorViewWithType:ErrorViewTypeNotFound title:@"User Not Found" description:@"We couldn’t find the User\nyou were looking for" actionTitle:nil actionBlock:nil];
            
            [self hideMoreButton];
        }
    }
}

- (void)hideMoreButton {
    if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
        [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.launchNavVC.rightActionButton.alpha = 0;
            } completion:^(BOOL finished) {
        }];
    }
}
- (void)showMoreButton {
    if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
        [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.launchNavVC.rightActionButton.alpha = 1;
        } completion:^(BOOL finished) {
        }];
    }
}

- (void)getPostsWithCursor:(StreamPagingCursorType)cursorType {
    if ([self userIdentifier] != nil) {
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        if (cursorType == StreamPagingCursorTypeNext) {
            [params setObject:self.tableView.stream.nextCursor forKey:@"next_cursor"];
        }
        else if (self.tableView.stream.prevCursor.length > 0) {
            [params setObject:self.tableView.stream.prevCursor forKey:@"prev_cursor"];
        }
        
        if ([params objectForKey:@"prev_cursor"] ||
            [params objectForKey:@"next_cursor"]) {
            NSString *cursor = [params objectForKey:@"prev_cursor"] ? params[@"prev_cursor"] : params[@"next_cursor"];
            
            if ([self.tableView.stream hasLoadedCursor:cursor]) {
                return;
            }
            else {
                [self.tableView.stream addLoadedCursor:cursor];
            }
        }
        else if (cursorType == StreamPagingCursorTypePrevious) {
            cursorType = StreamPagingCursorTypeNone;
        }
        
        self.tableView.hidden = false;
        if (self.tableView.stream.sections.count == 0) {
            self.tableView.visualError = nil;
            self.loading = true;
            [self.tableView hardRefresh:false];
        }
        
        NSString *url = [NSString stringWithFormat:@"users/%@/%@", [self userIdentifier], ([self isCurrentUser] ? @"posts" : @"stream")];
        [[[HAWebService manager] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            self.loading = false;
            self.tableView.loadingMore = false;
            
            SectionStreamPage *page = [[SectionStreamPage alloc] initWithDictionary:responseObject error:nil];
            if (page.data.count > 0) {
                NSString *sectionTitle;
                if (page.meta.paging.replaceCache ||
                    cursorType == StreamPagingCursorTypeNone) {
                    [self.tableView scrollToTop];
                    [self.tableView.stream flush];
                }
                
                if (cursorType == StreamPagingCursorTypeNext) {
                    [self.tableView.stream appendPage:page];
                }
                else if (cursorType == StreamPagingCursorTypeNone || cursorType == StreamPagingCursorTypePrevious) {
                    Section *firstSection = ((Section *)page.data[0]);
                    if (self.tableView.stream.sections.count == 0 &&
                        firstSection.attributes.title.length == 0) {
                        firstSection.attributes.title = sectionTitle;
                    }
                    
                    [self.tableView.stream prependPage:page];
                }
            }
            
            if (self.tableView.stream.sections.count == 0) {
                if ([self isCurrentUser]) {
                    NSString *firstMessage = [NSString stringWithFormat:@"#HelloBonfire, I'm %@! Nice to meet you. 👋", [self.user.attributes.displayName componentsSeparatedByString:@" "][0]];
                    [self showErrorViewWithType:ErrorViewTypeFirstPost title:@"Create Your First Post" description:@"Introduce yourself to the Bonfire community" actionTitle:@"Open Compose" actionBlock:^{
                        [Launcher openComposePost:nil inReplyTo:nil withMessage:firstMessage media:nil quotedObject:nil];
                    }];
                }
                else {
                    [self showErrorViewWithType:ErrorViewTypeNoPosts title:@"No Posts Yet" description:nil actionTitle:nil actionBlock:nil];
                }
            }
            else {
                self.tableView.visualError = nil;
            }
            
            if (cursorType == StreamPagingCursorTypePrevious) {
                [self.tableView refreshAtTop];
            }
            else if (cursorType == StreamPagingCursorTypeNext) {
                [self.tableView refreshAtBottom];
            }
            else {
                [self.tableView hardRefresh:false];
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"ProfileViewController / getPostsWithMaxId() - error: %@", error);
            
            NSInteger errorCode = [error bonfireErrorCode];
            if (errorCode == USER_USERNAME_SUSPENDED) {
                [self displayUserAsSuspended];
            }
            else if (self.tableView.stream.sections.count == 0) {
                [self showErrorViewWithType:([HAWebService hasInternet] ? ErrorViewTypeGeneral : ErrorViewTypeNoInternet) title:([HAWebService hasInternet] ? @"Error Loading" : @"No Internet") description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
                    self.loading = true;
                    [self refresh];
                }];
            }
            
            self.loading = false;
            self.tableView.loadingMore = false;
            [self.tableView refreshAtTop];
        }];
    }
    else {
        self.loading = false;
        self.tableView.loadingMore = false;
        [self.tableView refreshAtTop];
    }
}

- (void)tableView:(id)tableView didRequestNextPageWithMaxId:(NSInteger)maxId {
    if (self.tableView.stream.nextCursor.length > 0 && ![self.tableView.stream hasLoadedCursor:self. tableView.stream.nextCursor]) {
        NSLog(@"load page using next cursor: %@", self.tableView.stream.nextCursor);
        [self getPostsWithCursor:StreamPagingCursorTypeNext];
    }
}

- (void)setupTableView {
    self.tableView = [[BFComponentSectionTableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.navigationController.navigationBar.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView.insightSeenInLabel = InsightSeenInProfileView;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.extendedDelegate = self;
    [self.tableView registerClass:[ProfileHeaderCell class] forCellReuseIdentifier:profileHeaderCellIdentifier];
    [self.tableView registerClass:[BotHeaderCell class] forCellReuseIdentifier:botHeaderCellIdentifier];
    [self.tableView registerClass:[ButtonCell class] forCellReuseIdentifier:buttonCellReuseIdentifier];
    [self.tableView registerClass:[SpacerCell class] forCellReuseIdentifier:spacerCellReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellReuseIdentifier];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.tableView.refreshControl addTarget:self
                                action:@selector(refresh)
                      forControlEvents:UIControlEventValueChanged];
    if ([UIColor useWhiteForegroundForColor:self.coverPhotoView.backgroundColor]) {
        self.tableView.refreshControl.tintColor = [UIColor whiteColor];
    }
    else {
        self.tableView.refreshControl.tintColor = [UIColor blackColor];
    }
    [self.view addSubview:self.tableView];
}
- (void)refresh {
    [self loadUser];
    [self getPostsWithCursor:StreamPagingCursorTypePrevious];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)tableViewDidScroll:(UITableView *)tableView {
    if (tableView == self.tableView) {
        CGFloat adjustedCoverPhotoHeight = coverPhotoHeight + self.tableView.adjustedContentInset.top;
                
        self.coverPhotoView.frame = CGRectMake(0, 0, self.view.frame.size.width, adjustedCoverPhotoHeight + -(self.tableView.contentOffset.y + self.tableView.adjustedContentInset.top));
        
        UIView *overlayView = [self.coverPhotoView viewWithTag:10];
        overlayView.frame = CGRectMake(0, 0, self.coverPhotoView.frame.size.width, self.coverPhotoView.frame.size.height);
    }
}

#pragma mark - BFComponentTableViewDelegate
- (UITableViewCell * _Nullable)cellForRowInFirstSection:(NSInteger)row {
    if (row == 0) {
        if (self.user) {
            ProfileHeaderCell *cell = [self.tableView dequeueReusableCellWithIdentifier:profileHeaderCellIdentifier forIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
            
            if (cell == nil) {
                cell = [[ProfileHeaderCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:profileHeaderCellIdentifier];
            }
            
            cell.user = self.user;
                    
            BOOL isCurrentUser = [cell.user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier];
            cell.actionButton.hidden = (!self.loading && cell.user.attributes.context == nil && !isCurrentUser);
            cell.detailsCollectionView.hidden = (!cell.user.identifier && !self.loading);
                
            if (!cell.actionButton.isHidden) {
                if ([cell.user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
                    [cell.actionButton updateStatus:USER_STATUS_ME];
                }
                else if (self.loading && cell.user.attributes.context.me.status.length == 0) {
                    [cell.actionButton updateStatus:USER_STATUS_LOADING];
                }
                else {
                    [cell.actionButton updateStatus:cell.user.attributes.context.me.status];
                }
            }
            
            return cell;
        }
        else if (self.bot) {
            BotHeaderCell *cell = [self.tableView dequeueReusableCellWithIdentifier:botHeaderCellIdentifier forIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
            
            if (cell == nil) {
                cell = [[BotHeaderCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:botHeaderCellIdentifier];
            }
            
            cell.bot = self.bot;
                    
            cell.followButton.hidden = (!self.loading && cell.bot.attributes.context == nil);
            cell.detailsCollectionView.hidden = (!cell.bot.identifier && !self.loading);
                
            if (!cell.followButton.isHidden) {
                if (self.loading && cell.bot.attributes.context == nil) {
                    [cell.followButton updateStatus:USER_STATUS_LOADING];
                }
                else {
                    [cell.followButton updateStatus:cell.bot.attributes.context.me.status];
                }
            }
            
            return cell;
        }
    }
    else if (row == [self numberOfRowsInFirstSection] - 1) { // last row
        SpacerCell *cell = [self.tableView dequeueReusableCellWithIdentifier:spacerCellReuseIdentifier forIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];

        if (cell == nil) {
            cell = [[SpacerCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:spacerCellReuseIdentifier];
        }

        cell.topSeparator.hidden = true;
        cell.bottomSeparator.hidden = true;

        return cell;
    }
    else if (row == 1 || row == 2) {
        ButtonCell *cell = [self.tableView dequeueReusableCellWithIdentifier:buttonCellReuseIdentifier forIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        
        if (cell == nil) {
            cell = [[ButtonCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:buttonCellReuseIdentifier];
        }
        
        // Configure the cell...
        cell.buttonLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:cell.buttonLabel.font.pointSize weight:UIFontWeightMedium];
        if (row == 1) {
            cell.buttonLabel.text = @"Friends";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (long)self.user.attributes.summaries.counts.following];
            cell.bottomSeparator.frame = CGRectMake(12, cell.bottomSeparator.frame.origin.y, self.view.frame.size.width - 12, cell.bottomSeparator.frame.size.height);
        }
        else if (row == 2) {
            cell.buttonLabel.text = @"Camps";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (long)self.user.attributes.summaries.counts.camps];
        }
        cell.buttonLabel.textColor = [UIColor bonfirePrimaryColor];
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        cell.bottomSeparator.hidden = false;
        
        return cell;
    }
    
    UITableViewCell *blankCell = [self.tableView dequeueReusableCellWithIdentifier:blankCellReuseIdentifier forIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    return blankCell;
}

- (void)didSelectRowInFirstSection:(NSInteger)row {
    if (self.user) {
        if (row == 1) {
            [Launcher openProfileUsersFollowing:self.user];
        }
        else if (row == 2) {
            [Launcher openProfileCampsJoined:self.user];
        }
    }
}

- (CGFloat)heightForRowInFirstSection:(NSInteger)row {
    if (row == 0) {
        if (self.user) {
            return [ProfileHeaderCell heightForUser:self.user isLoading:self.loading];
        }
        else if (self.bot) {
            return [BotHeaderCell heightForBot:self.bot isLoading:self.loading];
        }
    }
    else if (row == [self numberOfRowsInFirstSection] - 1) {
        return [SpacerCell height];
    }
    else if (row == 1 || row == 2) {
        return 52;
    }
    
    return 0;
}
- (CGFloat)numberOfRowsInFirstSection {
    NSInteger rows = 2;
    if ([self isCurrentUser] && !(self.tableView.visualError && !(self.tableView.visualError.errorType == ErrorViewTypeNoPosts || self.tableView.visualError.errorType == ErrorViewTypeFirstPost)) && self.user && !([self identityIsBlocked] || [self currentUserIsBlocked])) {
        rows += 2;
    }
    
    return rows;
}

- (void)setShimmering:(BOOL)shimmering {
    if (shimmering != _shimmering) {
        _shimmering = shimmering;
        
        UIView *overlayView = [self.coverPhotoView viewWithTag:10];
        
        if (!shimmering) {
            CGFloat value = [[overlayView.layer.presentationLayer valueForKeyPath:@"opacity"] floatValue];
            
            [overlayView.layer removeAnimationForKey:@"opacityAnimation"];
            
            overlayView.alpha = value;
            [UIView animateWithDuration:0.5f delay:0 options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState animations:^{
                overlayView.alpha = 0;
            } completion:nil];
        }
    }
}

@end
