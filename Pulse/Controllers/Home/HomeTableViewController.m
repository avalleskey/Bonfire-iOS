//
//  FeedViewController.m
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import "HomeTableViewController.h"
#import "ComplexNavigationController.h"
#import "SectionStream.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <Shimmer/FBShimmeringView.h>
#import "SimpleNavigationController.h"
#import "InsightsLogger.h"
#import "UIColor+Palette.h"
#import "TabController.h"
#import "HAWebService.h"
#import "MiniAvatarListCell.h"
#import "Launcher.h"
#import "NSArray+Clean.h"
#import "BFTipsManager.h"
#import "SearchResultCell.h"
#import "ButtonCell.h"
#import "CampCardsListCell.h"
#import "BFVisualErrorView.h"
#import "ComposeViewController.h"
#import "PrivacySelectorTableViewController.h"
#import <PINCache/PINCache.h>
#import "BFAlertController.h"
#import <Lockbox/Lockbox.h>
@import Firebase;

#define HOME_FEED_CACHE_KEY @"home_stream_cache"

@interface HomeTableViewController () <PrivacySelectorDelegate> {
    int previousTableViewYOffset;
}

//@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL userDidRefresh;
@property (nonatomic, strong) NSDate *lastFetch;

@property (nonatomic, strong) BFVisualErrorView *errorView;

@property CGFloat minHeaderHeight;
@property CGFloat maxHeaderHeight;
@property (nonatomic, strong) NSMutableArray *posts;

@property (nonatomic, strong) NSMutableArray <Camp *> *suggestedCamps;

@property (nonatomic, strong) FBShimmeringView *titleView;

@property (nonatomic) CGFloat previousOffset;
@property (nonatomic) CGFloat yTranslation;

@property (nonatomic) BOOL scrollingDownwards;

@end

@implementation HomeTableViewController

static NSString * const recentCardsCellReuseIdentifier = @"RecentCampsCell";

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setup];
    [self loadCache];
    
    self.view.backgroundColor = [UIColor contentBackgroundColor];
    self.navigationController.view.backgroundColor = [UIColor contentBackgroundColor];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"My Feed" screenClass:nil];
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostBegan:) name:@"NewPostBegan" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostCompleted:) name:@"NewPostCompleted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostFailed:) name:@"NewPostFailed" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchNewPosts) name:@"FetchNewTimelinePosts" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        // first time
        [self setupTitleView];
        [self setupMorePostsIndicator];
                
        [self positionErrorView];
        
        if ([BFTipsManager hasSeenTip:@"about_sparks_info"] == false) {
            [self hideComposeInputView];
            
            BFTipObject *tipObject = [BFTipObject tipWithCreatorType:BFTipCreatorTypeBonfireTip creator:nil title:@"Sparks help posts go viral 🚀" text:@"Sparks show a post to more people. Only the creator can see who sparks a post." cta:nil imageUrl:nil action:^{
                NSLog(@"tip tapped");
            }];
            [[BFTipsManager manager] presentTip:tipObject completion:^{
                NSLog(@"presentTip() completion");
            }];
        }
        else {
            [self showComposeInputView];
        }
    }
    else {
        [InsightsLogger.sharedInstance openAllVisiblePostInsightsInTableView:self.sectionTableView seenIn:InsightSeenInHomeView];
        
        if (!self.loading) {
            // fetch new posts after 2mins
            NSTimeInterval secondsSinceLastFetch = [self.lastFetch timeIntervalSinceNow];
            NSLog(@"seconds since last fetch: %f", -secondsSinceLastFetch);
            
            if (self.sectionTableView.stream.sections.count == 0 ||
                secondsSinceLastFetch < -60)  {
                [self fetchNewPosts];
            }
        }
        
        [self showComposeInputView];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        [self setupContent];
        
//        NSLog(@"launches: %ld", (long)[[NSUserDefaults standardUserDefaults] integerForKey:@"launches"]);
//        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"hasSeenAppStoreReviewController"] && [Session sharedInstance].currentUser.attributes.summaries.counts.posts >= 3 && [[NSUserDefaults standardUserDefaults] integerForKey:@"launches"] > 3) {
//            [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"hasSeenAppStoreReviewController"];
//
//            // use BFAlertController
//            BFAlertController *alert = [BFAlertController
//                                        alertControllerWithTitle:@"Hello! 👋"
//                                        message:@"What emoji best describes how you feel about Bonfire?"
//                                        preferredStyle:BFAlertControllerStyleActionSheet];
//
//            BFAlertAction *good = [BFAlertAction actionWithTitle:@"👍" style:BFAlertActionStyleDefault
//                                                       handler:^{
//                // show app store rate dialog
//                [Launcher requestAppStoreRating];
//            }];
//
//            BFAlertAction *neutral = [BFAlertAction actionWithTitle:@"🤷‍♂️"        style:BFAlertActionStyleDefault
//                                                            handler:nil];
//
//            BFAlertAction *bad = [BFAlertAction actionWithTitle:@"👎" style:BFAlertActionStyleDefault
//                                                       handler:^{
//            BFAlertController *badAlert = [BFAlertController
//                                           alertControllerWithTitle:@"Oh no!"
//                                           message:@"Sorry you feel that way.\nLet us know how we can do better!"
//                                           preferredStyle:BFAlertControllerStyleActionSheet];
//
//            BFAlertAction *reportBug = [BFAlertAction actionWithTitle:@"Report a Bug" style:BFAlertActionStyleDefault
//                                                              handler:^{
//                // show app store rate dialog
//                Camp *camp = [[Camp alloc] init];
//                camp.identifier = @"-wWoxVq1VBA6R";
//                [Launcher openCamp:camp];
//                                                           }];
//
//            BFAlertAction *shareFeedback = [BFAlertAction actionWithTitle:@"Share Feedback" style:BFAlertActionStyleDefault
//                                                                  handler:^{
//                Camp *camp = [[Camp alloc] init];
//                camp.identifier = @"-mb4egjBg9vYK";
//                camp.attributes = [[CampAttributes alloc] initWithDictionary:@{@"identifier": @"BonfireFeedback", @"title": @"Bonfire Feedback"} error:nil];
//                [Launcher openCamp:camp];
//            }];
//
//            BFAlertAction *writeEmail = [BFAlertAction actionWithTitle:@"Contact Support" style:BFAlertActionStyleDefault
//                                                           handler:^{
//                NSString *url = @"mailto:support@bonfire.camp";
//                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];
//                                                           }];
//
//            BFAlertAction *cancel = [BFAlertAction actionWithTitle:@"Close" style:BFAlertActionStyleCancel
//                                                               handler:nil];
//
//            [badAlert addAction:reportBug];
//            [badAlert addAction:shareFeedback];
//            [badAlert addAction:writeEmail];
//            [badAlert addAction:cancel];
//
//            [[Launcher topMostViewController] presentViewController:badAlert animated:YES completion:nil];
//                                                       }];
//
//            [alert addAction:good];
//            [alert addAction:neutral];
//            [alert addAction:bad];
//
//            wait(1.5, ^{
//                [[Launcher topMostViewController] presentViewController:alert animated:YES completion:nil];
//            });
//        }
    }
    
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.sectionTableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
    
    // Register Siri intent
    NSString *activityTypeString = @"com.Ingenious.bonfire.open-feed-timeline";
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:activityTypeString];
    activity.title = [NSString stringWithFormat:@"See what's new"];
    activity.eligibleForSearch = true;
    if (@available(iOS 12.0, *)) {
        activity.eligibleForPrediction = true;
        activity.persistentIdentifier = activityTypeString;
    }
    self.view.userActivity = activity;
    [activity becomeCurrent];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [InsightsLogger.sharedInstance closeAllVisiblePostInsightsInTableView:self.sectionTableView];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setup
- (void)setup {
    [self setupTableView];
    [self setupErrorView];
    [self setupComposeInputView];
}
- (void)setupTableView {
    self.sectionTableView = [[BFComponentSectionTableView alloc] initWithFrame:CGRectMake(100, self.view.bounds.origin.y, self.view.frame.size.width - 200, self.view.bounds.size.height) style:UITableViewStylePlain];
    self.sectionTableView.stream.delegate = self;
    self.sectionTableView.insightSeenInLabel = InsightSeenInHomeView;
    self.sectionTableView.separatorColor = [UIColor tableViewSeparatorColor];
    self.sectionTableView.loadingMore = false;
    self.sectionTableView.extendedDelegate = self;
    self.sectionTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.sectionTableView.refreshControl = [[UIRefreshControl alloc] init];
    [self.sectionTableView sendSubviewToBack:self.sectionTableView.refreshControl];
    [self.sectionTableView.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    
    self.sectionTableView.scrollIndicatorInsets = UIEdgeInsetsZero;
}
- (void)setupContent {
    // load most up to date content
    self.lastFetch = [NSDate new];
    if (self.sectionTableView.stream.prevCursor.length > 0) {
        [self getPostsWithCursor:StreamPagingCursorTypePrevious];
    }
    else {
        [self getPostsWithCursor:StreamPagingCursorTypeNone];
    }
}
- (void)setupErrorView {
    BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNotFound title:@"Error Loading" description:@"Check your network settings and tap here to try again" actionTitle:@"Reload" actionBlock:^{
        [self refresh];
    }];
    
    self.errorView = [[BFVisualErrorView alloc] initWithVisualError:visualError];
    self.errorView.center = self.sectionTableView.center;
    self.errorView.hidden = true;
    [self.sectionTableView addSubview:self.errorView];
}
- (void)setupTitleView {
    UIButton *titleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [titleButton setImage:[[UIImage imageNamed:@"navBonfireLogo"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [titleButton setImageEdgeInsets:UIEdgeInsetsMake(-1, 0, 0, 0)];
    titleButton.tintColor = [UIColor bonfirePrimaryColor];
    titleButton.frame = CGRectMake(0, 0, [titleButton intrinsicContentSize].width, self.navigationController.navigationBar.frame.size.height);
    [titleButton bk_whenTapped:^{
        [self.sectionTableView scrollToTopWithCompletion:^{
            if (!self.loading) {
                // fetch new posts after 2mins
                NSTimeInterval secondsSinceLastFetch = [self.lastFetch timeIntervalSinceNow];
                // NSLog(@"seconds since last fetch: %f", -secondsSinceLastFetch);
                if (secondsSinceLastFetch < -60) {
                    [self fetchNewPosts];
                }
            }
        }];
    }];
    
    self.titleView = [[FBShimmeringView alloc] initWithFrame:titleButton.frame];
    [self.titleView addSubview:titleButton];
    self.titleView.contentView = titleButton;
    
    self.navigationItem.titleView = titleButton;
}
- (void)setupMorePostsIndicator {
    self.morePostsIndicator = [UIButton buttonWithType:UIButtonTypeCustom];
    self.morePostsIndicator.frame = CGRectMake(self.view.frame.size.width / 2 - (116 / 2), - 50, 116, 40);
    self.morePostsIndicator.layer.masksToBounds = false;
    self.morePostsIndicator.layer.shadowOffset = CGSizeMake(0, 1);
    self.morePostsIndicator.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.16].CGColor;
    self.morePostsIndicator.layer.shadowOpacity = 2.f;
    self.morePostsIndicator.layer.shadowRadius = 3.f;
    self.morePostsIndicator.tag = 0; // inactive
    self.morePostsIndicator.hidden = true;
    self.morePostsIndicator.layer.cornerRadius = self.morePostsIndicator.frame.size.height / 2;
    self.morePostsIndicator.backgroundColor = [UIColor colorNamed:@"PillBackgroundColor"];
    [self.morePostsIndicator setTitle:@"New Posts" forState:UIControlStateNormal];
    [self.morePostsIndicator setTitleColor:[UIColor bonfirePrimaryColor] forState:UIControlStateNormal];
    self.morePostsIndicator.titleLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightBold];
    self.morePostsIndicator.layer.shouldRasterize = true;
    self.morePostsIndicator.layer.rasterizationScale = [UIScreen mainScreen].scale;
    CGFloat intrinsticWidth = self.morePostsIndicator.intrinsicContentSize.width + (18*2);
    self.morePostsIndicator.frame = CGRectMake(self.view.frame.size.width / 2 - intrinsticWidth / 2, self.morePostsIndicator.frame.origin.y, intrinsticWidth, self.morePostsIndicator.frame.size.height);
    self.morePostsIndicator.center = CGPointMake(self.morePostsIndicator.center.x, self.morePostsIndicator.frame.size.height * -.6);
    
    [self.navigationController.view insertSubview:self.morePostsIndicator aboveSubview:self.view];
    
    [self.morePostsIndicator bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.4f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.morePostsIndicator.transform = CGAffineTransformMakeScale(0.9, 0.9);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    
    [self.morePostsIndicator bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.9f initialSpringVelocity:0.4f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.morePostsIndicator.transform = CGAffineTransformMakeScale(1, 1);
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [self.morePostsIndicator bk_whenTapped:^{
        [self.composeInputView.textView resignFirstResponder];
        [self hideMorePostsIndicator:true];
        [self.sectionTableView scrollToTop];
    }];
}

- (void)setupComposeInputView {
    CGFloat collapsed_inputViewHeight = ((self.composeInputView.textView.frame.origin.y * 2) + self.composeInputView.textView.frame.size.height);
    
    self.composeInputView = [[ComposeInputView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - collapsed_inputViewHeight - self.view.safeAreaInsets.bottom - 50, self.view.frame.size.width, collapsed_inputViewHeight)];
    self.composeInputView.defaultPlaceholder = ([UIScreen mainScreen].bounds.size.width > 320 ? @"Start a conversation..." : @"Say something...");
    [self.composeInputView setMediaTypes:@[BFMediaTypeGIF, BFMediaTypeText, BFMediaTypeImage]];
    [self.composeInputView updatePlaceholders];
    [self.composeInputView bk_whenTapped:^{
        if (![self.composeInputView isActive]) {
            [self.composeInputView setActive:true];
        }
    }];
    self.composeInputView.postTitle = @"Share";
    [self.composeInputView.postButton bk_whenTapped:^{
        [self openPrivacySelector];
    }];
    [self.composeInputView.expandButton bk_whenTapped:^{
        [Launcher openComposePost:nil inReplyTo:nil withMessage:self.composeInputView.textView.text media:nil  quotedObject:nil];
    }];
    
    [self.view addSubview:self.composeInputView];
    
    self.composeInputView.contentView.backgroundColor = [UIColor colorNamed:@"TabBarBackgroundColor"];
    self.composeInputView.textView.backgroundColor = [UIColor contentBackgroundColor];
    self.composeInputView.tintColor = [UIColor bonfireBrand];
}
- (void)privacySelectionDidSelectToPost:(Camp *)selection {
    [self postMessageInCamp:selection];
}

- (void)openPrivacySelector {
    PrivacySelectorTableViewController *sitvc = [[PrivacySelectorTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    sitvc.delegate = self;
    sitvc.postOnSelection = true;
    sitvc.shareOnProfile = false;
    
    SimpleNavigationController *simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:sitvc];
    simpleNav.transitioningDelegate = [Launcher sharedInstance];
    simpleNav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.navigationController presentViewController:simpleNav animated:YES completion:nil];
}
- (void)postMessageInCamp:(Camp *)camp {
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
        [BFAPI createPost:params postingIn:camp replyingTo:nil attachments:nil];
        
        [self.composeInputView reset];
        
        [self.view endEditing:true];
    }
}

#pragma mark - NSNotification Handlers
- (void)newPostBegan:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil && !tempPost.attributes.parent) {
        //        self.errorView.hidden = true;
        //
        //        [self.bf_tableView.stream addTempPost:tempPost];
        //        [self.bf_tableView refreshAtTop];
        if (self.navigationController && [self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
            [(SimpleNavigationController *)self.navigationController setProgress:0.7 animated:YES];
        }
    }
}
- (void)newPostCompleted:(NSNotification *)notification {
    NSDictionary *info = notification.object;
    Post *post = info[@"post"];
    
    if (post != nil) {
        self.errorView.hidden = true;
                
        wait(3.5f, ^{
            [self.sectionTableView.stream removeLoadedCursor:self.sectionTableView.stream.prevCursor];
            [self fetchNewPosts];
        });
        
        if (self.navigationController && [self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
            [(SimpleNavigationController *)self.navigationController setProgress:1 animated:YES hideOnCompletion:true];
        }
    }
}
- (void)newPostFailed:(NSNotification *)notification {
    Post *tempPost = notification.object;
    
    if (tempPost != nil) {
        if (self.navigationController && [self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
            [(SimpleNavigationController *)self.navigationController setProgress:0 animated:YES hideOnCompletion:true];
        }
    }
}

#pragma mark - Error View
- (void)showErrorViewWithType:(ErrorViewType)type title:(NSString *)title description:(NSString *)description actionTitle:(nullable NSString *)actionTitle actionBlock:(void (^ __nullable)(void))actionBlock {
    self.errorView.hidden = false;
    self.errorView.visualError = [BFVisualError visualErrorOfType:type title:title description:description actionTitle:actionTitle actionBlock:actionBlock];
    [self.sectionTableView reloadData];
}
- (void)positionErrorView {
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.sectionTableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
}

#pragma mark - More Posts Indicator
- (void)hideMorePostsIndicator:(BOOL)animated {
    if ([self.tabBarController isKindOfClass:[TabController class]]) {
        // remove dot from home tab
        [(TabController *)self.tabBarController setBadgeValue:nil forItem:self.navigationController.tabBarItem];
    }
    
    if (self.morePostsIndicator.tag != 0) {
        self.morePostsIndicator.tag = 0;
        
        [UIView animateWithDuration:(animated?0.8f:0) delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.morePostsIndicator.center = CGPointMake(self.morePostsIndicator.center.x, self.morePostsIndicator.frame.size.height * -.6);
            self.morePostsIndicator.alpha = 0;
        } completion:^(BOOL finished) {
            self.morePostsIndicator.hidden = true;
        }];
    }
}
- (void)showMorePostsIndicator:(BOOL)animated {
    if ([self.tabBarController isKindOfClass:[TabController class]]) {
        // remove dot from home tab
        [(TabController *)self.tabBarController setBadgeValue:@" " forItem:self.navigationController.tabBarItem];
    }
    
    if (self.morePostsIndicator.tag != 1) {
        self.morePostsIndicator.tag = 1;
        
        // reset state to ensure it's correct
        self.morePostsIndicator.hidden = false;
        self.morePostsIndicator.alpha = 1;
        self.morePostsIndicator.center = CGPointMake(self.morePostsIndicator.center.x, self.morePostsIndicator.frame.size.height * -.6);
        [UIView animateWithDuration:(animated?1.2f:0) delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            self.morePostsIndicator.center = CGPointMake(self.morePostsIndicator.center.x, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height + 12 + (self.morePostsIndicator.frame.size.height * 0.5));
        } completion:nil];
    }
}

#pragma mark - Cache Management
- (void)loadCache {
    [self.sectionTableView.stream flush];
    
    // load feed cache
    NSArray *cache = [self feedCache];

    if ([cache isKindOfClass:[NSArray class]] && cache && cache.count > 0) {
        for (SectionStreamPage *page in cache) {
            [self.sectionTableView.stream appendPage:page];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.sectionTableView.loading = (self.sectionTableView.stream.sections.count == 0);
            [self.sectionTableView hardRefresh:true];
        });
    }
}
- (void)saveCache {
    if (![Session sharedInstance].currentUser) return;
    
    NSMutableArray *array = [NSMutableArray new];
    
    const NSInteger maxSections = 10;
    NSInteger sectionsAdded = 0;
    for (NSInteger i = 0; i < self.sectionTableView.stream.pages.count && sectionsAdded < maxSections; i++) {
        SectionStreamPage *page = self.sectionTableView.stream.pages[i];
        
        [array addObject:page];
        
        sectionsAdded += page.data.count;
    }
    [[PINCache sharedCache] setObject:array forKey:HOME_FEED_CACHE_KEY];
}

- (NSArray *)feedCache {
    if (![[PINCache sharedCache] objectForKey:HOME_FEED_CACHE_KEY]) return @[];
    
    NSArray *cache = [[PINCache sharedCache] objectForKey:HOME_FEED_CACHE_KEY];
    return cache;
}

- (void)sectionStreamDidUpdate:(SectionStream *)stream {
    [self saveCache];
}

#pragma mark - Stream Requests & Management
// Get suggested camps (if any)
- (void)loadSuggestedCamps {
    NSArray *recentCamps = [[NSUserDefaults standardUserDefaults] arrayForKey:@"recents_camps"];
    
    if (recentCamps.count == 0) {
        return;
    }
    else if (recentCamps.count > 5) {
        recentCamps = [recentCamps subarrayWithRange:NSMakeRange(0, 8)];
    }
    
    self.suggestedCamps = [NSMutableArray new];
    for (id object in recentCamps) {
        if ([object isKindOfClass:[NSDictionary class]]) {
            NSError *error;
            Camp *camp = [[Camp alloc] initWithDictionary:(NSDictionary *)object error:&error];
            if (!error) {
                [self.suggestedCamps addObject:camp];
                return;
            }
        }
        else if ([object isKindOfClass:[Camp class]]) {
            [self.suggestedCamps addObject:(Camp *)object];
            return;
        }
    }
    
    [self.sectionTableView reloadData];
}
- (void)recentsUpdated:(NSNotification *)sender {
    [self loadSuggestedCamps];
    
    [self.sectionTableView reloadData];
}
// Fetch posts
- (void)getPostsWithCursor:(StreamPagingCursorType)cursorType {
    NSString *url = @"streams/me";
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (cursorType == StreamPagingCursorTypeNext) {
        [params setObject:self.sectionTableView.stream.nextCursor forKey:@"next_cursor"];
        NSLog(@"⬇️ load next cursor (%@)", self.sectionTableView.stream.nextCursor);
    }
    else if (self.sectionTableView.stream.prevCursor.length > 0) {
        [params setObject:self.sectionTableView.stream.prevCursor forKey:@"prev_cursor"];
        NSLog(@"🔼 load previous cursor (%@)", self.sectionTableView.stream.prevCursor);
    }
    
    if ([params objectForKey:@"prev_cursor"] ||
        [params objectForKey:@"next_cursor"]) {
        NSString *cursor = [params objectForKey:@"prev_cursor"] ? params[@"prev_cursor"] : params[@"next_cursor"];
        
        if ([self.sectionTableView.stream hasLoadedCursor:cursor]) {
            return;
        }
        else {
            [self.sectionTableView.stream addLoadedCursor:cursor];
        }
    }
    else if (cursorType == StreamPagingCursorTypePrevious) {
        cursorType = StreamPagingCursorTypeNone;
    }
    
    self.sectionTableView.loading = (self.sectionTableView.stream.sections.count == 0);
    if (self.sectionTableView.loading) {
        self.errorView.hidden = true;
        [self.sectionTableView hardRefresh:false];
    }
    
    if (cursorType == StreamPagingCursorTypePrevious && self.sectionTableView.stream.sections.count > 0) {
        self.titleView.shimmering = true;
    }
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        self.loading = false;
        self.sectionTableView.loading = false;
        self.userDidRefresh = false;
        
        NSInteger sectionsBefore = self.sectionTableView.stream.sections.count;
        CGFloat normalizedScrollViewContentOffsetY = self.sectionTableView.contentOffset.y + self.sectionTableView.adjustedContentInset.top;
        self.previousOffset = normalizedScrollViewContentOffsetY;
                
        SectionStreamPage *page = [[SectionStreamPage alloc] initWithDictionary:responseObject error:nil];
        
        BOOL newPosts = false;
        if (page.data.count > 0) {
            if (page.meta.paging.replaceCache &&
                cursorType != StreamPagingCursorTypeNext) {
                [self.sectionTableView scrollToTop];
                sectionsBefore = 0;
                [self.sectionTableView.stream flush];
            }
            
            if (cursorType == StreamPagingCursorTypeNext) {
                [self.sectionTableView.stream appendPage:page];
            }
            else {
                newPosts = (self.sectionTableView.stream.sections > 0 && page.data.count > 0);
                [self.sectionTableView.stream prependPage:page];
            }
                        
            if (self.userDidRefresh || sectionsBefore == 0 || cursorType == StreamPagingCursorTypeNone) {
                [self.sectionTableView hardRefresh:true];
                
                [self hideMorePostsIndicator:true];
            }
            else if (cursorType == StreamPagingCursorTypeNext) {
                self.sectionTableView.loadingMore = false;
                
                [self.sectionTableView refreshAtBottom];
            }
            else {
                // previous currsor
                [self.sectionTableView refreshAtTop];
                
                normalizedScrollViewContentOffsetY = self.sectionTableView.contentOffset.y + self.sectionTableView.adjustedContentInset.top;
                
                if (newPosts && normalizedScrollViewContentOffsetY > 0) {
                    [self showMorePostsIndicator:YES];
                }
            }
        }
        else {
            [self.sectionTableView hardRefresh:false];
        }
        
        if (self.sectionTableView.stream.sections.count == 0) {
            // Error: No posts yet!
            self.errorView.hidden = false;
            [self.sectionTableView hardRefresh:true];
            
            BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeHeart title:@"For You" description:@"The posts you care about from the Camps and people you care about" actionTitle:@"Discover Camps" actionBlock:^{
                TabController *tabVC = (TabController *)[Launcher activeTabController];
                if (tabVC) {
                    tabVC.selectedIndex = [tabVC.viewControllers indexOfObject:tabVC.storeNavVC];
                    [tabVC tabBar:tabVC.tabBar didSelectItem:tabVC.storeNavVC.tabBarItem];
                }
                else {
                    [Launcher openDiscover];
                }
            }];
            self.errorView.visualError = visualError;
            
            [self positionErrorView];
        }
        else {
            self.errorView.hidden = true;
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (self.sectionTableView.stream.sections.count == 0) {
            self.errorView.hidden = false;
            
            [self showErrorViewWithType:([HAWebService hasInternet] ? ErrorViewTypeGeneral : ErrorViewTypeNoInternet) title:([HAWebService hasInternet] ? @"Error Loading" : @"No Internet") description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
                [self refresh];
            }];
            
            [self positionErrorView];
        }
        
        self.loading = false;
        self.sectionTableView.loading = false;
        if (cursorType == StreamPagingCursorTypeNext) {
            self.sectionTableView.loadingMore = false;
        }
        else if (self.userDidRefresh) {
            self.userDidRefresh = false;
        }
        self.sectionTableView.userInteractionEnabled = true;
        [self.sectionTableView refreshAtTop];
    }];
}
// Management
- (void)refresh {
    [self.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
    [self.sectionTableView.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
    
    if (!self.userDidRefresh) {
        [self.sectionTableView.stream removeLoadedCursor:self.sectionTableView.stream.prevCursor];
        
        self.userDidRefresh = true;
        [self fetchNewPosts];
    }
}
- (void)fetchNewPosts {
    self.lastFetch = [NSDate new];
    [self getPostsWithCursor:StreamPagingCursorTypePrevious];
}
- (void)setLoading:(BOOL)loading {
    [super setLoading:loading];
    
    if (!self.loading) {
        self.titleView.shimmering = false;
    }
}

#pragma mark - BFComponentSectionTableViewDelegate
- (UIView *)viewForFirstSectionHeader {
    return nil;
    
//    UIView *buttons = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 80)];
//
//    UIButton *updateSection = [UIButton buttonWithType:UIButtonTypeSystem];
//    [updateSection setTitle:@"Update Section" forState:UIControlStateNormal];
//    updateSection.frame = CGRectMake(0, 0, buttons.frame.size.width, 40);
//    [updateSection bk_whenTapped:^{
//        Section *firstSection = [self.sectionTableView.stream.sections firstObject];
//        firstSection.attributes.title = @"Updated Section!";
//        [self.sectionTableView.stream performEventType:SectionStreamEventTypeSectionUpdated object:firstSection];
//
//        [self.sectionTableView reloadData];
//    }];
//    [buttons addSubview:updateSection];
//
//    UIButton *updateTopPost = [UIButton buttonWithType:UIButtonTypeSystem];
//    [updateTopPost setTitle:@"Update Top Post" forState:UIControlStateNormal];
//    updateTopPost.frame = CGRectMake(0, updateSection.frame.origin.y + updateSection.frame.size.height, buttons.frame.size.width, 40);
//    [updateTopPost bk_whenTapped:^{
//        Section *firstSection;
//        for (Section *section in self.sectionTableView.stream.sections) {
//            if (section.attributes.posts.count > 0) {
//                firstSection = section;
//                break;
//            }
//        }
//
//        if (firstSection) {
//            Post *firstPostInFirstSection = [firstSection.attributes.posts objectAtIndex:0];
//
//            firstPostInFirstSection.attributes.message = @"Updated post!";
//
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUpdated" object:firstPostInFirstSection];
//        }
//    }];
//    [buttons addSubview:updateTopPost];
//
//    UIButton *removeTopPost = [UIButton buttonWithType:UIButtonTypeSystem];
//    [removeTopPost setTitle:@"Remove Top Post" forState:UIControlStateNormal];
//    removeTopPost.frame = CGRectMake(0, updateTopPost.frame.origin.y + updateTopPost.frame.size.height, buttons.frame.size.width, 40);
//    [removeTopPost bk_whenTapped:^{
//        Section *firstSection;
//        for (Section *section in self.sectionTableView.stream.sections) {
//            if (section.attributes.posts.count > 0) {
//                firstSection = section;
//                break;
//            }
//        }
//
//        if (firstSection) {
//            Post *firstPostInFirstSection = [firstSection.attributes.posts objectAtIndex:0];
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"PostDeleted" object:firstPostInFirstSection];
//        }
//    }];
//    [buttons addSubview:removeTopPost];
//
//    UIButton *updateUser = [UIButton buttonWithType:UIButtonTypeSystem];
//    [updateUser setTitle:@"Update Top Post User" forState:UIControlStateNormal];
//    updateUser.frame = CGRectMake(0, removeTopPost.frame.origin.y + removeTopPost.frame.size.height, buttons.frame.size.width, 40);
//    [updateUser bk_whenTapped:^{
//        Section *firstSection;
//        for (Section *section in self.sectionTableView.stream.sections) {
//            if (section.attributes.posts.count > 0) {
//                firstSection = section;
//                break;
//            }
//        }
//
//        if (firstSection) {
//            Post *firstPostInFirstSection = [firstSection.attributes.posts objectAtIndex:0];
//
//            User *creator = [[User alloc] initWithDictionary:[firstPostInFirstSection.attributes.creator toDictionary] error:nil];
//            creator.attributes.identifier = @"jackieboy";
//
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"UserUpdated" object:creator];
//        }
//    }];
//    [buttons addSubview:updateUser];
//
//    UIButton *updateCamp = [UIButton buttonWithType:UIButtonTypeSystem];
//    [updateCamp setTitle:@"Update Top Post Camp" forState:UIControlStateNormal];
//    updateCamp.frame = CGRectMake(0, updateUser.frame.origin.y + updateUser.frame.size.height, buttons.frame.size.width, 40);
//    [updateCamp bk_whenTapped:^{
//        Section *firstSection;
//        for (Section *section in self.sectionTableView.stream.sections) {
//            if (section.attributes.posts.count > 0) {
//                firstSection = section;
//                break;
//            }
//        }
//
//        if (firstSection) {
//            Post *firstPostInFirstSection = [firstSection.attributes.posts objectAtIndex:0];
//
//            Camp *postedIn = [[Camp alloc] initWithDictionary:[firstPostInFirstSection.attributes.postedIn toDictionary] error:nil];
//            postedIn.attributes.identifier = @"suhdudes";
//
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"CampUpdated" object:postedIn];
//        }
//    }];
//    [buttons addSubview:updateCamp];
//
//    return buttons;
}
- (CGFloat)heightForFirstSectionHeader {
    return CGFLOAT_MIN;
    
//    return 200;
}
- (void)tableView:(nonnull id)tableView didRequestNextPageWithMaxId:(NSInteger)maxId {
    if (self.sectionTableView.stream.nextCursor.length > 0 && ![self.sectionTableView.stream hasLoadedCursor:self.sectionTableView.stream.nextCursor]) {
        [self getPostsWithCursor:StreamPagingCursorTypeNext];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)tableViewDidScroll:(UITableView *)tableView {
    CGFloat normalizedScrollViewContentOffsetY = tableView.contentOffset.y + tableView.adjustedContentInset.top;
    CGFloat bottom = tableView.contentSize.height - tableView.frame.size.height + self.sectionTableView.adjustedContentInset.bottom;
    
    if (![self.composeInputView.textView isFirstResponder] && normalizedScrollViewContentOffsetY > 80) {
        CGFloat diff = self.previousOffset - normalizedScrollViewContentOffsetY;
        
        self.previousOffset = normalizedScrollViewContentOffsetY;
        
        BOOL scrollingDownwards = diff < 0;
        if (scrollingDownwards != self.scrollingDownwards) {
            self.scrollingDownwards = scrollingDownwards;
            
            // scroll direction changed -- set the ytranslation back to 0
            self.yTranslation = 0;
        }
        else if (self.composeInputView.postButton.alpha == 0) {
            self.yTranslation += diff;
        }
        else {
            self.yTranslation = 0;
        }
        
        if (self.composeInputView.tag != 1) {
            if (self.yTranslation > 0 || (bottom - tableView.contentOffset.y) < self.composeInputView.frame.size.height) {
                [self showComposeInputView];
            }
            else if (self.yTranslation < -80) {
                [self hideComposeInputView];
            }
        }
    }
    else {
        self.scrollingDownwards = false;
        self.previousOffset = normalizedScrollViewContentOffsetY;
        self.yTranslation = 0;
        
        if (self.composeInputView.tag != 1 && [self.composeInputView isHidden]) {
            [self showComposeInputView];
        }
    }
    
    if (self.yTranslation > 10 || normalizedScrollViewContentOffsetY < 80) {
        // hide the scroll indicator
        [self hideMorePostsIndicator:true];
    }
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    UIView *tapToDismissView = [self.view viewWithTag:888];
    if (!tapToDismissView) {
        tapToDismissView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.sectionTableView.frame.size.width, self.sectionTableView.frame.size.height)];
        tapToDismissView.tag = 888;
        tapToDismissView.alpha = 0;
        tapToDismissView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.75];
        
        [self.view insertSubview:tapToDismissView aboveSubview:self.sectionTableView];
    }
    
    self.sectionTableView.scrollEnabled = false;
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
        self.sectionTableView.scrollEnabled = false;
    }
    else {
        self.sectionTableView.scrollEnabled = true;
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
    _yTranslation = 0;
    self.composeInputView.transform = CGAffineTransformIdentity;
    
    UIEdgeInsets safeAreaInsets = [[[UIApplication sharedApplication] delegate] window].safeAreaInsets;
    
    CGFloat newComposeInputViewY = self.view.frame.size.height - self.currentKeyboardHeight - self.composeInputView.frame.size.height + safeAreaInsets.bottom;
    
    self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, newComposeInputViewY, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
}

- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    _yTranslation = 0;
    self.composeInputView.transform = CGAffineTransformIdentity;
    
    UIEdgeInsets safeAreaInsets = [[[UIApplication sharedApplication] delegate] window].safeAreaInsets;
    
    NSNumber *duration = notification.userInfo ? [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] : @(0);
    [UIView animateWithDuration:[duration floatValue] delay:0 options:(notification.userInfo?[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16:UIViewAnimationOptionCurveEaseOut) animations:^{
        [self.composeInputView resize:false];
        
        self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, self.view.frame.size.height - self.composeInputView.frame.size.height - self.tabBarController.tabBar.frame.size.height + safeAreaInsets.bottom, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
    } completion:nil];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return textView.text.length + (text.length - range.length) <= [Session sharedInstance].defaults.post.maxLength;
}
- (void)showComposeInputView {
    _yTranslation = 0;
    self.composeInputView.transform = CGAffineTransformIdentity;
    
    UIEdgeInsets safeAreaInsets = [[[UIApplication sharedApplication] delegate] window].safeAreaInsets;
    
    CGFloat newComposeInputViewY = self.view.frame.size.height - self.currentKeyboardHeight - self.composeInputView.frame.size.height - self.tabBarController.tabBar.frame.size.height + safeAreaInsets.bottom;
    self.composeInputView.frame = CGRectMake(self.composeInputView.frame.origin.x, newComposeInputViewY, self.composeInputView.frame.size.width, self.composeInputView.frame.size.height);
    
    self.sectionTableView.contentInset = UIEdgeInsetsMake(self.sectionTableView.contentInset.top, 0, self.composeInputView.frame.size.height - safeAreaInsets.bottom, 0);
    self.sectionTableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, self.sectionTableView.contentInset.left, self.sectionTableView.contentInset.bottom, self.sectionTableView.contentInset.right);
    
    if ([self.composeInputView isHidden]) {
        self.composeInputView.tag = 1;
        self.composeInputView.transform = CGAffineTransformMakeTranslation(0, self.composeInputView.frame.size.height);
        self.composeInputView.hidden = false;
        [UIView animateWithDuration:0.4f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.composeInputView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            self.composeInputView.tag = 0;
        }];
    }
}
- (void)hideComposeInputView {
    _yTranslation = 0;
    _scrollingDownwards = false;
    self.composeInputView.transform = CGAffineTransformIdentity;
    
    self.sectionTableView.contentInset = UIEdgeInsetsMake(self.sectionTableView.contentInset.top, self.sectionTableView.contentInset.left, 0, self.sectionTableView.contentInset.right);
    self.sectionTableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, self.sectionTableView.contentInset.left, self.sectionTableView.contentInset.bottom, self.sectionTableView.contentInset.right);
    
    if (![self.composeInputView isHidden]) {
        self.composeInputView.tag = 1;
        [UIView animateWithDuration:0.5f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.composeInputView.transform = CGAffineTransformMakeTranslation(0, self.composeInputView.frame.size.height);
        } completion:^(BOOL finished) {
            self.composeInputView.tag = 0;
            self.composeInputView.hidden = true;
        }];
    }
}

@end
