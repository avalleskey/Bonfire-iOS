//
//  SearchNavigationController.m
//  Pulse
//
//  Created by Austin Valleskey on 11/30/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "SearchNavigationController.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "UIColor+Palette.h"
#import "SearchTableViewController.h"

@interface SearchNavigationController ()

@end

@implementation SearchNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] init];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupNavigationBar];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.navigationBackgroundView.frame = CGRectMake(0, 0, self.navigationBar.frame.size.width, self.navigationBar.frame.origin.y + self.navigationBar.frame.size.height);
    self.blurView.frame = self.navigationBackgroundView.bounds;
}

- (void)setupNavigationBar {
    // setup items
    [self.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor clearColor],
       NSFontAttributeName:[UIFont systemFontOfSize:1.f]}];
    
    //
    self.navigationBar.translucent = true;
    self.navigationBar.tintColor = [UIColor colorWithWhite:0.07 alpha:1];
    
    // add blur view background
    self.navigationBackgroundView = [[UIView alloc] init];
    self.navigationBackgroundView.backgroundColor = [[UIColor headerBackgroundColor] colorWithAlphaComponent:0.9];
    [self.view insertSubview:self.navigationBackgroundView belowSubview:self.navigationBar];
    
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    self.blurView.frame = self.navigationBackgroundView.bounds;
    [self.navigationBackgroundView addSubview:self.blurView];
    
    // remove default hairline
    [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setShadowImage:[UIImage new]];
    // add custom hairline
    self.hairline = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationBar.frame.size.height, self.navigationBar.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    self.hairline.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08f];
    [self.navigationBar addSubview:self.hairline];
    
    self.searchView = [[BFSearchView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - (16 * 2), 34)];
    self.searchView.textField.delegate = self;
    self.searchView.center = CGPointMake(self.navigationBar.frame.size.width / 2, self.navigationBar.frame.size.height / 2);
    [self.searchView.textField bk_addEventHandler:^(id sender) {
        SearchTableViewController *topSearchController = (SearchTableViewController *)self.topViewController;
        if ([self.topViewController isKindOfClass:[SearchTableViewController class]]) {
            [topSearchController searchFieldDidChange];
        }
    } forControlEvents:UIControlEventEditingChanged];
    [self.navigationBar addSubview:self.searchView];
    
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.cancelButton.frame = CGRectMake(self.navigationBar.frame.size.width, 0, 58 + (16 * 2), self.navigationBar.frame.size.height);
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:17.f weight:UIFontWeightSemibold];
    [self.cancelButton setTitleColor:[UIColor colorWithWhite:0.07 alpha:1] forState:UIControlStateNormal];
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.cancelButton bk_whenTapped:^{
        self.searchView.textField.text = @"";
        [self.searchView.textField resignFirstResponder];
        
        SearchTableViewController *topSearchController = (SearchTableViewController *)self.topViewController;
        if ([self.topViewController isKindOfClass:[SearchTableViewController class]]) {
            [topSearchController searchFieldDidChange];
        }
    }];
    [self.navigationBar addSubview:self.cancelButton];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    SearchTableViewController *topSearchController = (SearchTableViewController *)self.topViewController;
    if ([self.topViewController isKindOfClass:[SearchTableViewController class]]) {
        [topSearchController searchFieldDidBeginEditing];
    }
    
    [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.searchView.frame = CGRectMake(self.searchView.frame.origin.x, self.searchView.frame.origin.y, self.view.frame.size.width - self.searchView.frame.origin.x - 90, self.searchView.frame.size.height);
        [self.searchView setPosition:BFSearchTextPositionLeft];
        self.cancelButton.frame = CGRectMake(self.navigationBar.frame.size.width - self.cancelButton.frame.size.width, self.cancelButton.frame.origin.y, self.cancelButton.frame.size.width, self.cancelButton.frame.size.height);
    } completion:nil];
}
- (void)textFieldDidEndEditing:(UITextField *)textField {
    SearchTableViewController *topSearchController = (SearchTableViewController *)self.topViewController;
    if ([self.topViewController isKindOfClass:[SearchTableViewController class]]) {
        [topSearchController searchFieldDidEndEditing];
    }
    self.searchView.textField.userInteractionEnabled = false;
    
    [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.searchView.frame = CGRectMake(self.searchView.frame.origin.x, self.searchView.frame.origin.y, self.view.frame.size.width - (self.searchView.frame.origin.x * 2), self.searchView.frame.size.height);
        [self.searchView setPosition:BFSearchTextPositionCenter];
        self.cancelButton.frame = CGRectMake(self.navigationBar.frame.size.width, self.cancelButton.frame.origin.y, self.cancelButton.frame.size.width, self.cancelButton.frame.size.height);
    } completion:^(BOOL finished) {
        
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return false;
}

@end
