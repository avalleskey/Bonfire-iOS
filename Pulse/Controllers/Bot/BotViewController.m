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
    CGFloat coverPhotoHeight;
}

@property (nonatomic) BOOL shimmering;

@property (nonatomic, strong) ComplexNavigationController *launchNavVC;
@end

@implementation BotViewController

static NSString * const botHeaderCellIdentifier = @"BotHeaderCell";
static NSString * const campCellIdentifier = @"CampCell";
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
    coverPhotoHeight = BOT_HEADER_EDGE_INSETS.top + BOT_HEADER_AVATAR_BORDER_WIDTH + ceilf(BOT_HEADER_AVATAR_SIZE * 0.65);
    if (self.bot.attributes.media.cover.suggested.url.length > 0) {
        [self.coverPhotoView sd_setImageWithURL:[NSURL URLWithString:self.bot.attributes.media.cover.suggested.url]];
    
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
    self.bfTableView.visualError = [BFVisualError visualErrorOfType:type title:title description:description actionTitle:actionTitle actionBlock:actionBlock];
    [self.bfTableView reloadData];
}

- (void)styleOnAppear {
    self.bfTableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}

- (void)loadBot {
    if (self.bot.identifier.length > 0 || self.bot.attributes.identifier.length > 0) {
        [self.bfTableView refreshAtTop];
        
        // load camp info before loading posts
        [self getBotInfo];
    }
    else {
        // camp not found
        self.bfTableView.hidden = true;
                
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
                
        [self.bfTableView refreshAtTop];
        
        // Now that the VC's Camp object is complete,
        // Go on to load the camp content
        [self showMoreButton];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"ProfileViewController / getUserInfo() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
        NSInteger statusCode = httpResponse.statusCode;
        if (statusCode == 404) {
            [self showErrorViewWithType:ErrorViewTypeNotFound title:@"Bot Not Found" description:@"We couldn’t find the Bot\nyou were looking for" actionTitle:nil actionBlock:nil];
            
            [self hideMoreButton];
        }
        else {
            [self showErrorViewWithType:([HAWebService hasInternet] ? ErrorViewTypeGeneral : ErrorViewTypeNoInternet) title:([HAWebService hasInternet] ? @"Error Loading" : @"No Internet") description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
                [self refresh];
            }];
        }
        
        self.loading = false;
        [self.bfTableView refreshAtTop];
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
            self.bfTableView.refreshControl.tintColor = [UIColor whiteColor];
        }
        else {
            self.bfTableView.refreshControl.tintColor = [UIColor blackColor];
        }
    } completion:^(BOOL finished) {
    }];
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

- (void)setupTableView {
    self.bfTableView = [[BFComponentTableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.navigationController.navigationBar.frame.size.height) style:UITableViewStyleGrouped];
    self.bfTableView.extendedDelegate = self;
    self.bfTableView.backgroundColor = [UIColor clearColor];
    [self.bfTableView registerClass:[BotHeaderCell class] forCellReuseIdentifier:botHeaderCellIdentifier];
    [self.bfTableView registerClass:[SpacerCell class] forCellReuseIdentifier:spacerCellReuseIdentifier];
    [self.bfTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellReuseIdentifier];
    self.bfTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.bfTableView.tag = 101;
    self.bfTableView.visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNotFound title:@"About Bots" description:@"Bots automate posts, moderation, and more" actionTitle:nil actionBlock:nil];
    [self.bfTableView.refreshControl addTarget:self
                                action:@selector(refresh)
                      forControlEvents:UIControlEventValueChanged];
    if ([UIColor useWhiteForegroundForColor:self.coverPhotoView.backgroundColor]) {
        self.bfTableView.refreshControl.tintColor = [UIColor whiteColor];
    }
    else {
        self.bfTableView.refreshControl.tintColor = [UIColor blackColor];
    }
    [self.view addSubview:self.bfTableView];
}

- (void)refresh {
    [self loadBot];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    UINavigationController *navController = UIViewParentController(self).navigationController;
    if (navController) {
        if ([navController isKindOfClass:[ComplexNavigationController class]]) {
            ComplexNavigationController *complexNav = (ComplexNavigationController *)navController;
            [complexNav childTableViewDidScroll:self.bfTableView];
        }
        else if ([navController isKindOfClass:[SimpleNavigationController class]]) {
            SimpleNavigationController *simpleNav = (SimpleNavigationController *)navController;
            [simpleNav childTableViewDidScroll:self.bfTableView];
        }
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)tableViewDidScroll:(UITableView *)tableView {
    if (tableView == self.bfTableView) {
        if (self.bfTableView.contentOffset.y > (-1 * self.bfTableView.contentInset.top)) {
            self.coverPhotoView.frame = CGRectMake(0, 0.5 * (-self.bfTableView.contentOffset.y - self.bfTableView.contentInset.top), self.view.frame.size.width, self.bfTableView.contentInset.top);
        }
        else {
            self.coverPhotoView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.bfTableView.contentInset.top + (-self.bfTableView.contentOffset.y - self.bfTableView.contentInset.top));
        }
        
        CGFloat percentageHidden = ((self.bfTableView.contentOffset.y + self.bfTableView.contentInset.top) / (self.bfTableView.contentInset.top * .75));
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
    
    return 0;
}
- (CGFloat)numberOfRowsInFirstSection {
    return 1;
}

@end
