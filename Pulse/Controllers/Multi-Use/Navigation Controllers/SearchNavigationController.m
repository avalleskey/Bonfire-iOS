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
#import "SearchTableViewController.h"
#import "UIColor+Palette.h"
#import "Session.h"

@interface SearchNavigationController ()

@end

@implementation SearchNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] init];
    
    self.view.tintColor = [UIColor bonfirePrimaryColor]; //[UIColor fromHex:[Session sharedInstance].currentUser.attributes.details.color];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupNavigationBar];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.searchView.textField becomeFirstResponder];
}

- (void)setupNavigationBar {
    // setup items
    [self.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor clearColor],
       NSFontAttributeName:[UIFont systemFontOfSize:18.f]}];
    
    //
    self.navigationBar.translucent = false;
    self.navigationBar.tintColor = self.view.tintColor;
    self.navigationBar.barTintColor = [UIColor contentBackgroundColor];
    self.navigationBar.shadowImage = [self imageWithColor:[UIColor clearColor]];
    
    self.bottomHairline = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationBar.frame.size.height, self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    self.bottomHairline.backgroundColor = [UIColor tableViewSeparatorColor];
    self.bottomHairline.alpha = 0;
    [self.navigationBar addSubview:self.bottomHairline];
    
    self.searchView = [[BFSearchView alloc] initWithFrame:CGRectMake(12, 0, self.view.frame.size.width - (12 * 2), 34)];
    self.searchView.theme = BFTextFieldThemeContent;
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
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightSemibold];
    [self.cancelButton setTitleColor:self.view.tintColor forState:UIControlStateNormal];
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.cancelButton bk_whenTapped:^{
        [self.searchView.textField resignFirstResponder];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [self.navigationBar addSubview:self.cancelButton];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)setShadowVisibility:(BOOL)visible withAnimation:(BOOL)animated {
    [UIView animateWithDuration:animated?(visible?0.2f:0.4f):0 animations:^{
        if (visible) [self showBottomHairline];
        else [self hideBottomHairline];
    }];
}
- (void)hideBottomHairline {
    if (self.bottomHairline.alpha == 1) {
        [self.bottomHairline.layer removeAllAnimations];
    }
    self.bottomHairline.alpha = 0;
}
- (void)showBottomHairline {
    // Show 1px hairline of translucent nav bar
    if (self.bottomHairline.alpha != 1) {
        [self.bottomHairline.layer removeAllAnimations];
    }
    self.bottomHairline.alpha = 1;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    /*
    if (@available(iOS 13.0, *)) {
        return UIStatusBarStyleDarkContent;
    } else {
        // Fallback on earlier versions
        return UIStatusBarStyleDefault;
    }*/
    return UIStatusBarStyleDefault;
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
    if (self.hideCancelOnBlur) {
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
