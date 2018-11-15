//
//  HomeViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "HomeViewController.h"
#import "Session.h"
#import <HapticHelper/HapticHelper.h>
#import <QuartzCore/QuartzCore.h>

#define IS_IPHONE        (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_5 ([[UIScreen mainScreen] bounds].size.height == 568.0)
#define IS_IPHONE_X (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 812.0)
#define IS_TINY ([[UIScreen mainScreen] bounds].size.height == 480)
#define STATUS_BAR_HEIGHT (IS_IPHONE_X ? 44 : 20)
#define BOTTOM_BAR_HEIGHT (IS_IPHONE_X ? 34 : 0)


@interface HomeViewController ()

@property (nonatomic) BOOL roomPresented;
@property (strong, nonatomic) NSArray *pages;
@property (nonatomic) BOOL scrolling;
@property (strong, nonatomic) LauncherNavigationViewController *launchNavVC;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    self.page = 1;
    Session *session = [Session sharedInstance];
    self.pages = @[session.defaults.home.feedPageTitle, session.defaults.home.myRoomsPageTitle, session.defaults.home.discoverPageTitle];
    
    self.view.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
    
    [self setupBottomBar];
    [self setupMyRoomsViewController];
    [self setupTimelineViewController];
    [self setupTrendingViewController];
    
    [self setupScrollView];
    [self style];
    
    self.launchNavVC = (LauncherNavigationViewController *)self.navigationController;
    self.launchNavVC.textField.text = @"";
    [self.launchNavVC setShadowVisibility:false withAnimation:false];
    
    [self.launchNavVC.composePostButton bk_whenTapped:^{
        [self.launchNavVC openComposePost];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
}

- (void)userUpdated:(NSNotification *)notification {
    self.launchNavVC.profilePicture.tintColor = [Session sharedInstance].themeColor;
    if ([Session sharedInstance].currentUser.attributes.details.media.profilePicture.length > 0) {
        [self.launchNavVC.profilePicture sd_setImageWithURL:[NSURL URLWithString:[Session sharedInstance].currentUser.attributes.details.media.profilePicture] placeholderImage:[[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    }
    else {
        [self.launchNavVC.profilePicture setImage:[[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    }
    self.launchNavVC.composePostButton.tintColor = [Session sharedInstance].themeColor;
    self.launchNavVC.textField.tintColor = [Session sharedInstance].themeColor;
    
    UIButton *bottomBarButton = self.bottomBarButtons[self.page];
    bottomBarButton.tintColor = [Session sharedInstance].themeColor;
}

- (void)viewWillAppear:(BOOL)animated {
    [self updateScrollView];
}

- (void)setupMyRoomsViewController {
    self.myRoomsViewController = [[MyRoomsViewController alloc] init];
    [self addChildViewController:self.myRoomsViewController];
    self.myRoomsViewController.view.frame = CGRectMake(self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self.myRoomsViewController didMoveToParentViewController:self];
    
    [self styleViewController:self.myRoomsViewController];
}
- (void)setupTimelineViewController {
    self.timelineViewController = [[FeedViewController alloc] initWithFeedId:@"timeline"];
    [self addChildViewController:self.timelineViewController];
    self.timelineViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.timelineViewController.tableView.frame = self.timelineViewController.view.bounds;
    [self.timelineViewController.tableView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
    [self.timelineViewController didMoveToParentViewController:self];
    
    [self styleViewController:self.timelineViewController];
}
- (void)setupTrendingViewController {
    self.trendingFeedViewController = [[FeedViewController alloc] initWithFeedId:@"trending"];
    [self addChildViewController:self.trendingFeedViewController];
    self.trendingFeedViewController.view.frame = CGRectMake(self.view.frame.size.width * 2, 0, self.view.frame.size.width, self.view.frame.size.height);
    self.trendingFeedViewController.tableView.frame = self.trendingFeedViewController.view.bounds;
    [self.trendingFeedViewController.tableView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
    [self.trendingFeedViewController didMoveToParentViewController:self];
    
    [self styleViewController:self.trendingFeedViewController];
}

- (void)styleViewController:(UIViewController *)viewController {
    // border radius
    [viewController.view.layer setCornerRadius:0];
    
    // border
    [viewController.view.layer setBorderColor:[UIColor clearColor].CGColor];
    [viewController.view.layer setBorderWidth:1];
}

- (void)setupBottomBar {
    self.bottomBarContainer = [[TabBarView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    self.bottomBarContainer.backgroundColor = [UIColor colorWithWhite:0.92 alpha:0.5f];
    /*self.bottomBarContainer.layer.shadowOffset = CGSizeMake(0, -1);
    self.bottomBarContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.bottomBarContainer.layer.shadowOpacity = 0.04f;
    self.bottomBarContainer.layer.shadowRadius = 0;*/
    self.bottomBarContainer.layer.masksToBounds = false;
    
    self.bottomBarButtons = [[NSMutableArray alloc] init];
    self.bottomBarIndicator = [[UIView alloc] init];
    self.bottomBarIndicator.layer.cornerRadius = 2.f;
    self.bottomBarIndicator.alpha = 1;
    self.bottomBarIndicator.backgroundColor = [UIColor whiteColor];
    self.bottomBarIndicator.layer.shadowOffset = CGSizeMake(0, 1);
    self.bottomBarIndicator.layer.shadowRadius = 2.f;
    self.bottomBarIndicator.layer.shadowOpacity = 0.08f;
    self.bottomBarIndicator.layer.shadowColor = [UIColor blackColor].CGColor;
    self.bottomBarIndicator.layer.cornerRadius = 20.f;
    
    [self.bottomBarContainer.contentView addSubview:self.bottomBarIndicator];
}
- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

- (void)setupScrollView {
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.scrollView.showsHorizontalScrollIndicator = false;
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * self.pages.count, self.view.frame.size.height);
    self.scrollView.pagingEnabled = true;
    self.scrollView.contentOffset = CGPointMake(self.scrollView.frame.size.width * self.page, 0);
    self.scrollView.delegate = self;
    [self.scrollView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
    // allow touches to pass through
    [self allowTouchesToPassThrough:self.scrollView];
    
    [self.view insertSubview:self.scrollView atIndex:0];
    
    float padding = 16;
    float buttonWidth = (self.view.frame.size.width - (padding * 2)) / self.pages.count;
    for (int i = 0; i < self.pages.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = i;
        // [button setTitle:self.pages[i] forState:UIControlStateNormal];
        switch (i) {
            case 0:
                [button setImage:[[UIImage imageNamed:@"myFeedPageIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
                break;
            case 1:
                [button setImage:[[UIImage imageNamed:@"roomsPageIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
                break;
            case 2:
                [button setImage:[[UIImage imageNamed:@"trendingPageIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
                break;
                
            default:
                break;
        }
        [button.titleLabel setFont:[UIFont systemFontOfSize:18.f weight:UIFontWeightBold]];
        [button setTitleColor:[UIColor colorWithRed:0.19 green:0.20 blue:0.20 alpha:1.0] forState:UIControlStateNormal];
        
        button.frame = CGRectMake(padding + (i * buttonWidth), 0, buttonWidth, 52);
        
        if ((int)self.page == i) {
            // CGRect rect = [button.currentTitle boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 72) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:button.titleLabel.font} context:nil];
            
            // self.bottomBarIndicator.frame = CGRectMake(button.frame.origin.x + ((button.frame.size.width - rect.size.width) / 2) - 16, 6, rect.size.width + 32, 40);
            self.bottomBarIndicator.frame = CGRectMake(button.frame.origin.x, 6, buttonWidth, 40);
            button.tintColor = [Session sharedInstance].themeColor;
        }
        else {
            button.tintColor = [UIColor colorWithWhite:0 alpha:0.3f];
        }
        
        [self.bottomBarContainer.contentView addSubview:button];
        [self.bottomBarButtons addObject:button];
    }
    
    [self.view addSubview:self.bottomBarContainer];
    
    // add child elements
    [self.scrollView addSubview:self.myRoomsViewController.view];
    [self.scrollView addSubview:self.timelineViewController.view];
    [self.scrollView addSubview:self.trendingFeedViewController.view];
}

- (void)updateScrollView {
    UIEdgeInsets safeAreaInsets = [UIApplication sharedApplication].keyWindow.safeAreaInsets;
    
    self.scrollView.frame = CGRectMake(0, 0, self.scrollView.frame.size.width, self.view.frame.size.height);
    self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, self.scrollView.frame.size.height);
    
    self.bottomBarContainer.frame = CGRectMake(0, self.scrollView.frame.origin.y + self.scrollView.frame.size.height - 52 - safeAreaInsets.bottom, self.view.frame.size.width, 52 + safeAreaInsets.bottom + 24);
    [self continuityRadiusForView:self.bottomBarContainer withRadius:24.f];
    
    self.myRoomsViewController.collectionView.center = CGPointMake(self.myRoomsViewController.collectionView.center.x, self.scrollView.frame.size.height / 2 - self.bottomBarContainer.frame.size.height / 2 - 22);
    
    self.myRoomsViewController.createRoomButton.frame = CGRectMake((self.view.frame.size.width / 2 - (self.myRoomsViewController.createRoomButton.frame.size.width / 2)), self.myRoomsViewController.collectionView.frame.origin.y + self.myRoomsViewController.collectionView.frame.size.height + 12, self.myRoomsViewController.createRoomButton.frame.size.width, self.myRoomsViewController.createRoomButton.frame.size.height);
    
    // set order of views
    self.timelineViewController.view.frame = CGRectMake(0, self.timelineViewController.view.frame.origin.y, self.view.frame.size.width, self.timelineViewController.view.frame.size.height);
    self.myRoomsViewController.view.frame = CGRectMake(self.scrollView.frame.size.width, self.myRoomsViewController.view.frame.origin.y, self.myRoomsViewController.view.frame.size.width, self.myRoomsViewController.view.frame.size.height);
    self.trendingFeedViewController.view.frame = CGRectMake(self.scrollView.frame.size.width * 2, self.trendingFeedViewController.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    
    self.timelineViewController.tableView.contentInset = UIEdgeInsetsMake(4, 0, self.bottomBarContainer.frame.size.height + 16, 0);
    self.timelineViewController.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.bottomBarContainer.frame.size.height, 0);
    self.timelineViewController.tableView.frame = self.timelineViewController.view.bounds;
    
    self.trendingFeedViewController.tableView.contentInset = UIEdgeInsetsMake(4, 0, self.bottomBarContainer.frame.size.height + 16, 0);
    self.trendingFeedViewController.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.bottomBarContainer.frame.size.height, 0);
    self.trendingFeedViewController.tableView.frame = self.trendingFeedViewController.view.bounds;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([scrollView isEqual:self.scrollView]) {
        float indexOfPage = scrollView.contentOffset.x / scrollView.frame.size.width;
        int goingToPage = 0;
        int closestPage = 0;
        UIViewController *goingToVC;
        UIViewController *closestVC;
        float percentageScrolled;
        
        if (self.page != indexOfPage) {
            BOOL goingRight = false;
            if (indexOfPage > self.page) {
                goingRight = true;
                
                goingToPage = ceilf(indexOfPage);
                closestPage = (goingToPage - 1 >= 0) ? goingToPage - 1 : 0;
                percentageScrolled = (indexOfPage - floorf(indexOfPage));
                if (percentageScrolled == 0) percentageScrolled = 1;
            }
            else {
                goingToPage = floorf(indexOfPage);
                closestPage = (goingToPage + 1 < self.pages.count) ? goingToPage + 1 : goingToPage;
                percentageScrolled = 1 - (indexOfPage - floorf(indexOfPage));
                if (percentageScrolled == 0) percentageScrolled = 1;
            }
            
            if (goingToPage == 0) { goingToVC = self.timelineViewController; }
            if (goingToPage == 1) { goingToVC = self.myRoomsViewController; }
            if (goingToPage == 2) { goingToVC = self.trendingFeedViewController; }
            
            if (closestPage == 0) { closestVC = self.timelineViewController; }
            if (closestPage == 1) { closestVC = self.myRoomsViewController; }
            if (closestPage == 2) { closestVC = self.trendingFeedViewController; }
            
            goingToVC.view.layer.masksToBounds = true;
            closestVC.view.layer.masksToBounds = true;
            
            if (goingToPage >= 0 && goingToPage < self.pages.count) {
                UIButton *upcomingButton = self.bottomBarButtons[goingToPage];
                CGRect upcomingButtonRect = [upcomingButton.currentTitle boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 72) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:upcomingButton.titleLabel.font} context:nil];
                
                UIButton *activeButton = self.bottomBarButtons[closestPage];
                CGRect activeButtonRect = [activeButton.currentTitle boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 72) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:activeButton.titleLabel.font} context:nil];
                
                //float upcomingButtonWidth = upcomingButtonRect.size.width + 36; // 18 on each side
                //float activeButtonWidth = activeButtonRect.size.width + 36; // 18 on each side
                //float currentTransitionWidth = activeButtonWidth + ((upcomingButtonWidth - activeButtonWidth) * percentageScrolled);
                
                float upcomingButtonX = upcomingButton.frame.origin.x; // upcomingButton.frame.origin.x + ((upcomingButton.frame.size.width - upcomingButtonRect.size.width) / 2) - 18;
                float activeButtonX = activeButton.frame.origin.x; // + ((activeButton.frame.size.width - activeButtonRect.size.width) / 2) - 18;
                float currentTransitionX = activeButtonX + ((upcomingButtonX - activeButtonX) * percentageScrolled);
                
                self.bottomBarIndicator.frame = CGRectMake(currentTransitionX, self.bottomBarIndicator.frame.origin.y, self.bottomBarIndicator.frame.size.width, self.bottomBarIndicator.frame.size.height);
                
                CGFloat adjustedScrollPosition = (percentageScrolled > 0.5 ? (1 - percentageScrolled) / 0.25 : percentageScrolled / 0.25);
                adjustedScrollPosition = adjustedScrollPosition > 1 ? 1 : adjustedScrollPosition;
                CGFloat borderOpacity = 0.04f * (percentageScrolled > 0.5 ? (1 - percentageScrolled) / 0.25 : percentageScrolled / 0.25);
                UIColor *borderColor = [UIColor colorWithWhite:0 alpha:borderOpacity];
                
                CGFloat goingToVC_scale = 0.96 + (0.04 * percentageScrolled);
                goingToVC.view.transform = CGAffineTransformMakeScale(goingToVC_scale, goingToVC_scale);
                goingToVC.view.layer.cornerRadius = 12.f * (1 - percentageScrolled);
                goingToVC.view.layer.borderColor = borderColor.CGColor;
                
                CGFloat closestVC_scale = 1 - (0.04 * percentageScrolled);
                closestVC.view.transform = CGAffineTransformMakeScale(closestVC_scale, closestVC_scale);
                closestVC.view.layer.cornerRadius = 12.f * percentageScrolled;
                closestVC.view.layer.borderColor = borderColor.CGColor;
                
                /* OLD OLD
                if (self.bottomBarIndicator.alpha == 0) {
                    [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                        self.bottomBarIndicator.alpha = 1;
                    } completion:nil];
                }
                 */
            }
            
            if (!self.scrolling && [scrollView isEqual:self.scrollView]) {
                self.scrolling = true;
                self.myRoomsViewController.collectionView.scrollEnabled = false;
            }
        }
        else {
            NSLog(@"same page homie");
        }
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self scrollViewDidEndDecelerating:scrollView];
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.scrolling && [scrollView isEqual:self.scrollView]) {
        self.scrolling = false;
        self.myRoomsViewController.collectionView.scrollEnabled = true;
        
        int indexOfPage = scrollView.contentOffset.x / scrollView.frame.size.width;
        UIButton *previousButton = self.bottomBarButtons[self.page];
        UIButton *activeButton = self.bottomBarButtons[indexOfPage];
        
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            // OLD OLD self.bottomBarIndicator.alpha = 0;
            
            self.timelineViewController.view.transform = CGAffineTransformMakeScale(1, 1);
            self.timelineViewController.view.layer.cornerRadius = 0;
            self.timelineViewController.view.layer.borderColor = [UIColor clearColor].CGColor;
            
            self.myRoomsViewController.view.transform = CGAffineTransformMakeScale(1, 1);
            self.myRoomsViewController.view.layer.cornerRadius = 0;
            self.myRoomsViewController.view.layer.borderColor = [UIColor clearColor].CGColor;
            
            self.trendingFeedViewController.view.transform = CGAffineTransformMakeScale(1, 1);
            self.trendingFeedViewController.view.layer.cornerRadius = 0;
            self.trendingFeedViewController.view.layer.borderColor = [UIColor clearColor].CGColor;
        } completion:nil];
        
        if (self.page != indexOfPage) {
            self.page = indexOfPage;
            
            // buzz buzz!
            [HapticHelper generateFeedback:FeedbackType_Selection];
            
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                activeButton.tintColor = [Session sharedInstance].themeColor;
                previousButton.tintColor = [UIColor colorWithWhite:0 alpha:0.3f];
            } completion:nil];
            
            // load next view
            if (self.page == 0) {
                // Feed
                // [self.launchNavVC setShadowVisibility:true withAnimation:true];
                [self.launchNavVC setShadowVisibility:false withAnimation:true];
            }
            else if (self.page == 1) {
                // My Rooms
               // launchNavVC.textField.text = @"My Rooms";
                [self.launchNavVC setShadowVisibility:false withAnimation:true];
            }
            else if (self.page == 2) {
                // Trending
                //[self.launchNavVC setShadowVisibility:true withAnimation:true];
                [self.launchNavVC setShadowVisibility:false withAnimation:true];
            }
        }
    }
    else {
        NSLog(@"ugh wht");
    }
}

- (void)style {
    
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)allowTouchesToPassThrough:(UIScrollView *)scrollView {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    
    // To prevent the pan gesture of the UIScrollView from swallowing up the
    // touch event
    tap.cancelsTouchesInView = NO;
    
    [scrollView addGestureRecognizer:tap];
}
- (void)handleTap:(UITapGestureRecognizer *)recognizer {
    
    // First get the tap gesture recognizers's location in the entire
    // view's window
    CGPoint tapPoint = [recognizer locationInView:self.view];
    
    // Then see if it falls within one of your below images' frames
    for (UIButton* button in self.bottomBarButtons) {
        
        // If the image's coordinate system isn't already equivalent to
        // self.view, convert it so it has the same coordinate system
        // as the tap.
        CGRect imageFrameInSuperview = [button.superview convertRect:button.frame toView:self.view];
        
        // If the tap in fact lies inside the image bounds,
        // perform the appropriate action.
        if (CGRectContainsPoint(imageFrameInSuperview, tapPoint)) {
            // Perhaps call a method here to react to the image tap
            if (!self.scrolling) {
                if (button.tag == 1 && self.page == button.tag) {
                    [self.myRoomsViewController.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
                }

                [self scrollToPage:(int)button.tag];
            }
            
            break;
        }
    }
}
- (void)scrollToPage:(int)p {
    [self.scrollView setContentOffset:CGPointMake(p * self.scrollView.frame.size.width, 0) animated:YES];
}

@end
