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
}

- (void)setupNavigationBar {
    // setup items
    [self.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor clearColor],
       NSFontAttributeName:[UIFont systemFontOfSize:17.f]}];
    
    //
    self.navigationBar.translucent = true;
    self.navigationBar.tintColor = [UIColor colorWithWhite:0.07 alpha:1];
    self.navigationBar.backgroundColor = [UIColor clearColor];
    self.navigationBar.shadowImage = [self imageWithColor:[UIColor colorWithWhite:0 alpha:0.08f]];
    self.navigationBar.barTintColor = [UIColor colorWithRed:0.98 green:0.98 blue:0.99 alpha:1.00];
    
    self.searchView = [[BFSearchView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - (16 * 2), 34)];
    self.searchView.textField.delegate = self;
    self.searchView.center = CGPointMake(self.navigationBar.frame.size.width / 2, self.navigationBar.frame.size.height / 2);
    [self.searchView.textField bk_addEventHandler:^(id sender) {
        SearchTableViewController *topSearchController = (SearchTableViewController *)self.topViewController;
        if ([self.topViewController isKindOfClass:[SearchTableViewController class]]) {
            [topSearchController searchFieldDidChange];
        }
    } forControlEvents:UIControlEventEditingChanged];
    self.searchView.openSearchControllerOntap = true;
    [self.navigationBar addSubview:self.searchView];
    
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.cancelButton.frame = CGRectMake(self.navigationBar.frame.size.width, 0, 58 + (16 * 2), self.navigationBar.frame.size.height);
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:17.f weight:UIFontWeightSemibold];
    [self.cancelButton setTitleColor:[UIColor colorWithWhite:0.07 alpha:1] forState:UIControlStateNormal];
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.cancelButton bk_whenTapped:^{
        self.searchView.textField.text = @"";
        [self.searchView.textField resignFirstResponder];
        
        [self popToRootViewControllerAnimated:NO];
        
        SearchTableViewController *topSearchController = (SearchTableViewController *)self.topViewController;
        if ([self.topViewController isKindOfClass:[SearchTableViewController class]]) {
            [topSearchController searchFieldDidChange];
        }
    }];
    [self.navigationBar addSubview:self.cancelButton];
}

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 0.5);
    const CGFloat alpha = CGColorGetAlpha(color.CGColor);
    const BOOL opaque = alpha == 1;
    UIGraphicsBeginImageContextWithOptions(rect.size, opaque, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
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
    SearchTableViewController *topSearchController = (SearchTableViewController *)self.topViewController;
    if ([self.topViewController isKindOfClass:[SearchTableViewController class]]) {
        [topSearchController searchFieldDidReturn];
    }
    [textField resignFirstResponder];
    
    return false;
}

@end