//
//  CombinedHomeViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 7/20/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "CombinedHomeViewController.h"

@interface CombinedHomeViewController () <UIScrollViewDelegate>

@end

@implementation CombinedHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setup];
}

#pragma mark - Setup
- (void)setup {
    self.pages = [NSMutableArray new];

    [self setupScrollView];
    [self setupPageControl];
    
    [self setupCampsViewController];
    [self setupActivityViewController];
}
- (void)setupScrollView {
    self.pagedScrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.pagedScrollView.backgroundColor = [UIColor yellowColor];
    self.pagedScrollView.pagingEnabled = true;
    self.pagedScrollView.showsHorizontalScrollIndicator = false;
    [self.view addSubview:self.pagedScrollView];
}
- (void)setupCampsViewController {
    self.myCampsVC = [[UIViewController alloc] init];
    self.myCampsVC.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3f];
    [self addViewControllerToPages:self.myCampsVC];
}
- (void)setupActivityViewController {
    self.homeVC = [[MyFeedViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self addViewControllerToPages:self.homeVC];
}
- (void)setupPageControl {
    self.pageControl = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular]];
    self.pageControl.frame = CGRectMake(0, 0, 235, 40);
    self.pageControl.backgroundColor = [UIColor colorWithWhite:0.9 alpha:0.8];
    self.pageControl.layer.cornerRadius = self.pageControl.frame.size.height / 2;
    self.pageControl.layer.masksToBounds = true;
    self.navigationController.navigationItem.titleView = self.pageControl;
}

#pragma mark - Paged Scroll View
- (void)addViewControllerToPages:(UIViewController *)viewController {
    [self addChildViewController:viewController];
    [self.pagedScrollView addSubview:viewController.view];
    viewController.view.frame = CGRectMake(self.pages.count * self.pagedScrollView.frame.size.width, viewController.view.frame.origin.y, viewController.view.frame.size.width, viewController.view.frame.size.height);
    [viewController didMoveToParentViewController:self];
    
    // add to self.pages (for later reference)
    [self.pages addObject:viewController];
    
    self.pagedScrollView.contentSize = CGSizeMake(self.pages.count * self.view.frame.size.width, self.pagedScrollView.contentSize.height);
}

#pragma mark - UISrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // page ?
    
}

@end
