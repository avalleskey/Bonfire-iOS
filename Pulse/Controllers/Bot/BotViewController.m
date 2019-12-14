//
//  BotViewController.m
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import "BotViewController.h"
#import "ComplexNavigationController.h"
#import "SimpleNavigationController.h"
#import "BFVisualErrorView.h"
#import "BotHeaderCell.h"
#import "UIColor+Palette.h"
#import "Launcher.h"
#import "HAWebService.h"
#import <UIImageView+WebCache.h>
#import "ButtonCell.h"
#import "BFHeaderView.h"
#import "SpacerCell.h"
#import "LoadingCell.h"
#import "BFAlertController.h"

#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
@import Firebase;

@interface BotViewController () {
    int previousTableViewYOffset;
}

@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL loadingMore;

@property (nonatomic, strong) ComplexNavigationController *launchNavVC;

@property (strong, nonatomic) NSMutableDictionary *cellHeightsDictionary;

@property (nonatomic, strong) BFVisualError * _Nullable  visualError;

@end

@implementation BotViewController

static NSString * const botHeaderCellIdentifier = @"BotHeaderCell";
static NSString * const campCellIdentifier = @"CampCell";
static NSString * const buttonCellReuseIdentifier = @"ButtonCell";
static NSString * const spacerCellReuseIdentifier = @"SpacerCell";
static NSString * const blankCellReuseIdentifier = @"BlankCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.tintColor = self.theme;
    
    self.launchNavVC = (ComplexNavigationController *)self.navigationController;
    if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] init];
    }
    
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
    
    [self setupTableView];
    
    [self setupCoverPhotoView];
    self.tableView.contentOffset = CGPointMake(0, -1 * self.tableView.contentInset.top);
    
    self.loading = true;
    [self loadBot];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Bot" screenClass:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self styleOnAppear];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)setupCoverPhotoView {
    self.coverPhotoView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 120)];
    self.coverPhotoView.backgroundColor = self.theme;
    self.coverPhotoView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverPhotoView.clipsToBounds = true;
    [self.coverPhotoView bk_whenTapped:^{
        [Launcher expandImageView:self.coverPhotoView];
    }];
    [self.view insertSubview:self.coverPhotoView belowSubview:self.tableView];
    UIView *overlayView = [[UIView alloc] initWithFrame:self.coverPhotoView.bounds];
    overlayView.backgroundColor = self.theme;
    overlayView.alpha = 0;
    overlayView.tag = 10;
    //[self.imagePreviewView addSubview:overlayView];
    [self updateCoverPhotoView];
}
- (void)updateCoverPhotoView {
//    if (self.bot.attributes.media.coverPhoto.suggested.url.length > 0) {
//        self.tableView.contentInset = UIEdgeInsetsMake(152, 0, self.tableView.contentInset.bottom, 0);
//        [self.coverPhotoView sd_setImageWithURL:[NSURL URLWithString:self.bot.attributes.media.coverPhoto.suggested.url]];
//
//        // add gradient overlay
//        UIColor *topColor = [UIColor colorWithWhite:0 alpha:0.5];
//        UIColor *bottomColor = [UIColor colorWithWhite:0 alpha:0];
//
//        NSArray *gradientColors = [NSArray arrayWithObjects:(id)topColor.CGColor, (id)bottomColor.CGColor, nil];
//        NSArray *gradientLocations = [NSArray arrayWithObjects:[NSNumber numberWithInt:0.0],[NSNumber numberWithInt:1.0], nil];
//
//        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
//        gradientLayer.colors = gradientColors;
//        gradientLayer.locations = gradientLocations;
//        gradientLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.tableView.contentInset.top);
//        [self.coverPhotoView.layer addSublayer:gradientLayer];
//    }
//    else {
        self.tableView.contentInset = UIEdgeInsetsMake(120, 0, self.tableView.contentInset.bottom, 0);
        self.coverPhotoView.image = nil;
//    }
    
    // updat the scroll distance
    if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
        ((ComplexNavigationController *)self.navigationController).onScrollLowerBound = self.tableView.contentInset.top * .3;
    }
    else if ([self.navigationController isKindOfClass:[SimpleNavigationController class]]) {
        ((SimpleNavigationController *)self.navigationController).onScrollLowerBound = self.tableView.contentInset.top * .3;
    }
    
    [self.tableView.refreshControl setBounds:CGRectMake(self.tableView.refreshControl.bounds.origin.x, self.tableView.contentInset.top, self.tableView.refreshControl.bounds.size.width, self.tableView.refreshControl.bounds.size.height)];
    self.coverPhotoView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.tableView.contentInset.top + (-1 * self.tableView.contentOffset.y));
    UIVisualEffectView *overlayView = [self.coverPhotoView viewWithTag:10];
    overlayView.frame = self.coverPhotoView.bounds;
}

- (NSString *)botIdentifier {
    if (self.bot.identifier != nil) return self.bot.identifier;
    if (self.bot.attributes.identifier != nil) return self.bot.attributes.identifier;
    
    return nil;
}


- (BOOL)botIsBlocked {
    return ([self.bot.attributes.context.me.status isEqualToString:USER_STATUS_BLOCKS] || [self.bot.attributes.context.me.status isEqualToString:USER_STATUS_BLOCKS_BOTH]);
}

- (void)openBotActions {
    BOOL botIsBlocked = [self botIsBlocked];
    
    // @"\n\n\n\n\n\n"
    BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:nil message:nil preferredStyle:BFAlertControllerStyleActionSheet];

    BFAlertAction *blockUsername = [BFAlertAction actionWithTitle:[NSString stringWithFormat:@"%@", botIsBlocked ? @"Unblock" : @"Block"] style:BFAlertActionStyleDefault handler:^{
        // confirm action
        BFAlertController *alertConfirmController = [BFAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ %@", botIsBlocked ? @"Unblock" : @"Block" , self.bot.attributes.displayName] message:[NSString stringWithFormat:@"Are you sure you would like to block @%@?", self.bot.attributes.identifier] preferredStyle:BFAlertControllerStyleAlert];
        
        BFAlertAction *alertConfirm = [BFAlertAction actionWithTitle:botIsBlocked ? @"Unblock" : @"Block" style:BFAlertActionStyleDestructive handler:^{
            if (botIsBlocked) {
                [BFAPI unblockIdentity:self.bot completion:^(BOOL success, id responseObject) {
                    if (success) {
                        // NSLog(@"success unblocking!");
                    }
                    else {
                        NSLog(@"error unblocking ;(");
                    }
                }];
            }
            else {
                [BFAPI blockIdentity:self.bot completion:^(BOOL success, id responseObject) {
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
        
        BFAlertAction *alertCancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
        [alertConfirmController addAction:alertCancel];
        
        [[Launcher topMostViewController] presentViewController:alertConfirmController animated:true completion:nil];
    }];
    [actionSheet addAction:blockUsername];
    
    // 1.A.* -- Any user, any page, any following state
    BFAlertAction *shareUser = [BFAlertAction actionWithTitle:[NSString stringWithFormat:@"Share %@ via...", [NSString stringWithFormat:@"@%@", self.bot.attributes.identifier]] style:BFAlertActionStyleDefault handler:^{
        NSLog(@"share bot");
        
        [Launcher shareIdentity:self.bot];
    }];
    [actionSheet addAction:shareUser];
    
    BFAlertAction *cancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:^{
        NSLog(@"cancel");
    }];
    [actionSheet addAction:cancel];
    
    [[Launcher topMostViewController] presentViewController:actionSheet animated:true completion:nil];
}

- (void)showErrorViewWithType:(ErrorViewType)type title:(NSString *)title description:(NSString *)description actionTitle:(nullable NSString *)actionTitle actionBlock:(void (^ __nullable)(void))actionBlock {
    self.visualError = [BFVisualError visualErrorOfType:type title:title description:description actionTitle:actionTitle actionBlock:actionBlock];
    [self.tableView reloadData];
}

- (void)styleOnAppear {
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}

- (void)loadBot {
    if (self.bot.identifier.length > 0 || self.bot.attributes.identifier.length > 0) {
        [self refreshAtTop];
        
        // load camp info before loading posts
        [self getBotInfo];
    }
    else {
        // camp not found
        self.tableView.hidden = true;
                
        [self showErrorViewWithType:ErrorViewTypeNotFound title:@"Bot Not Found" description:@"We couldn’t find the Bot\nyou were looking for" actionTitle:nil actionBlock:nil];
        
        [self hideMoreButton];
    }
}

- (void)getBotInfo {
    NSString *url = [NSString stringWithFormat:@"users/%@", [self botIdentifier]]; // sample data
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:@{} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *responseData = (NSDictionary *)responseObject[@"data"];
        
        NSLog(@"response data:: user:: %@", responseData);
        
        // first page
        Bot *bot = [[Bot alloc] initWithDictionary:responseData error:nil];
        self.bot = bot;
        
        [self updateTheme];
        
        self.title = self.bot.attributes.displayName;
        if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
            [((ComplexNavigationController *)self.navigationController).searchView updateSearchText:self.title];
        }
                
        [self refreshAtTop];
        
        // Now that the VC's Camp object is complete,
        // Go on to load the camp content
        [self loadBotContent];
        
        [self showMoreButton];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"ProfileViewController / getUserInfo() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
        NSInteger statusCode = httpResponse.statusCode;
        if (statusCode == 404) {
            [self showErrorViewWithType:ErrorViewTypeNotFound title:@"User Not Found" description:@"We couldn’t find the User\nyou were looking for" actionTitle:nil actionBlock:nil];
            
            [self hideMoreButton];
        }
        else {
            [self showErrorViewWithType:([HAWebService hasInternet] ? ErrorViewTypeGeneral : ErrorViewTypeNoInternet) title:([HAWebService hasInternet] ? @"Error Loading" : @"No Internet") description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
                [self refresh];
            }];
        }
        
        self.loading = false;
        [self refreshAtTop];
    }];
}

- (void)updateTheme {
    UIColor *theme = [UIColor fromHex:self.bot.attributes.color adjustForOptimalContrast:false];
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
//        self.composeInputView.addMediaButton.backgroundColor = theme;
        
        if ([UIColor useWhiteForegroundForColor:self.coverPhotoView.backgroundColor]) {
            self.tableView.refreshControl.tintColor = [UIColor whiteColor];
        }
        else {
            self.tableView.refreshControl.tintColor = [UIColor blackColor];
        }
    } completion:^(BOOL finished) {
    }];
}

- (void)loadBotContent {
    // TODO: Convert this to GET camps the Bot is in
   [self getPostsWithCursor:StreamPagingCursorTypeNone];
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
    if ([self botIdentifier] != nil) {
        self.tableView.hidden = false;
        
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        if (cursorType == StreamPagingCursorTypeNext) {
            [params setObject:self.stream.nextCursor forKey:@"cursor"];
            [self.stream addLoadedCursor:self.stream.nextCursor];
        }
        else if (self.stream.prevCursor) {
            [params setObject:self.stream.prevCursor forKey:@"cursor"];
        }
        if ([params objectForKey:@"cursor"]) {
            [self.stream addLoadedCursor:params[@"cursor"]];
        }
        
        NSString *url = [NSString stringWithFormat:@"users/%@/posts", [self botIdentifier]]; // sample data
        
        [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            self.tableView.scrollEnabled = true;
            
            CampListStreamPage *page = [[CampListStreamPage alloc] initWithDictionary:responseObject error:nil];
            if (page.data.count > 0) {
                if (cursorType == StreamPagingCursorTypeNone) {
                    self.stream.camps = @[];
                    self.stream.pages = [[NSMutableArray alloc] init];
                }
                if (cursorType == StreamPagingCursorTypeNone || cursorType == StreamPagingCursorTypePrevious) {
                    [self.stream prependPage:page];
                }
                else if (cursorType == StreamPagingCursorTypeNext) {
                    [self.stream appendPage:page];
                }
            }
            
            if (self.stream.camps.count == 0) {
                // Error: No sparks yet!
                [self showErrorViewWithType:ErrorViewTypeNoPosts title:@"No Camps Yet" description:nil actionTitle:nil actionBlock:nil];
            }
            else {
                self.visualError = nil;
            }
            
            self.loading = false;
            
            self.loading = false;
            self.loadingMore = false;
            
            if (cursorType == StreamPagingCursorTypeNext) {
                [self refreshAtBottom];
            }
            else {
                [self refreshAtTop];
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"ProfileViewController / getPostsWithMaxId() - error: %@", error);
            //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            
            if (self.stream.camps.count == 0) {
                [self showErrorViewWithType:([HAWebService hasInternet] ? ErrorViewTypeGeneral : ErrorViewTypeNoInternet) title:([HAWebService hasInternet] ? @"Error Loading" : @"No Internet") description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
                    [self refresh];
                }];
            }
            
            self.loading = false;
            self.loadingMore = false;
            self.tableView.userInteractionEnabled = true;
            self.tableView.scrollEnabled = false;
            [self refreshAtTop];
        }];
    }
    else {
        self.loading = false;
        self.loadingMore = false;
        self.tableView.userInteractionEnabled = true;
        self.tableView.scrollEnabled = false;
        [self refreshAtTop];
    }
}

- (void)tableView:(id)tableView didRequestNextPageWithMaxId:(NSInteger)maxId {
    if (self.stream.nextCursor.length > 0 && ![self.stream hasLoadedCursor:self.stream.nextCursor]) {
        NSLog(@"load page using next cursor: %@", self.stream.nextCursor);
        [self getPostsWithCursor:StreamPagingCursorTypeNext];
    }
}

- (void)setupTableView {
    self.tableView = [[RSTableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.navigationController.navigationBar.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.loading = true;
    [self.tableView registerClass:[BotHeaderCell class] forCellReuseIdentifier:botHeaderCellIdentifier];
    [self.tableView registerClass:[ButtonCell class] forCellReuseIdentifier:buttonCellReuseIdentifier];
    [self.tableView registerClass:[SpacerCell class] forCellReuseIdentifier:spacerCellReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellReuseIdentifier];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.tag = 101;
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
    [self loadBot];
    [self getPostsWithCursor:StreamPagingCursorTypePrevious];
}

- (void)hardRefresh {
    self.cellHeightsDictionary = @{}.mutableCopy;
    
    [self.tableView reloadData];
    [self.tableView layoutIfNeeded];
    
    if (!self.loading) {
        [self.tableView.refreshControl endRefreshing];
    }
}
- (void)refreshAtTop {
    self.cellHeightsDictionary = @{}.mutableCopy;
    
    [self.tableView layoutIfNeeded];
    
    BOOL wasLoading = ([[self.tableView.visibleCells firstObject] isKindOfClass:[LoadingCell class]]);
    
    [self.tableView reloadData];
    [self.tableView layoutIfNeeded];
        
    if (!self.loading && !wasLoading) {
        [self.tableView.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
    }
}
- (void)refreshAtBottom {
    self.cellHeightsDictionary = @{}.mutableCopy;
    
    [self.tableView layoutIfNeeded];
    [self.tableView reloadData];
    [self.tableView layoutIfNeeded];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    UINavigationController *navController = UIViewParentController(self).navigationController;
    if (navController) {
        if ([navController isKindOfClass:[ComplexNavigationController class]]) {
            ComplexNavigationController *complexNav = (ComplexNavigationController *)navController;
            [complexNav childTableViewDidScroll:self.tableView];
        }
        else if ([navController isKindOfClass:[SimpleNavigationController class]]) {
            SimpleNavigationController *simpleNav = (SimpleNavigationController *)navController;
            [simpleNav childTableViewDidScroll:self.tableView];
        }
    }
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

#pragma mark - RSTableViewDelegate

- (CGFloat)heightForRowInFirstSection:(NSInteger)row {
    if (row == 0) {
        return [BotHeaderCell heightForBot:self.bot isLoading:self.loading];
    }
    else if (row == 1) {
        return [SpacerCell height];
    }
    
    return 0;
}
- (CGFloat)numberOfRowsInFirstSection {
    return 1;
}

@end
