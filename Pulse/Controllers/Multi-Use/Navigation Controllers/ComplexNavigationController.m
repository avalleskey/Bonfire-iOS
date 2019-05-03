//
//  LauncherNavigationViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 9/27/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ComplexNavigationController.h"
#import "HAWebService.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <HapticHelper/HapticHelper.h>
#import "SearchResultCell.h"
#import "CreateRoomViewController.h"
#import "NSArray+Clean.h"
#import "Launcher.h"

// Views it can open
#import "RoomViewController.h"
#import "RoomMembersViewController.h"
#import "ProfileViewController.h"
#import "PostViewController.h"
#import "SearchTableViewController.h"
#import "OnboardingViewController.h"
#import "EditProfileViewController.h"
#import "MyRoomsViewController.h"
#import "FeedViewController.h"
#import <UIImageView+WebCache.h>
#import "UIColor+Palette.h"
#import "UINavigationItem+Margin.h"
#import "ProfileCampsListViewController.h"
#import "ProfileFollowingListViewController.h"

#define barColorUpdateDuration 0.6

@interface ComplexNavigationController ()

@end

@implementation ComplexNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.swiper = [[SloppySwiper alloc] initWithNavigationController:self];
    self.swiper.delegate = self;
    self.delegate = self.swiper;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    // remove hairline
    [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setShadowImage:[UIImage new]];
    
    // set background color
    [self.navigationBar setTranslucent:true];
    [self.navigationBar setBarTintColor:[UIColor clearColor]];
    self.navigationItem.titleView = nil;
    self.navigationItem.title = nil;
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor clearColor]};
    
    // add background color view
    self.navigationBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.top + self.navigationBar.frame.size.height)];
    self.navigationBackgroundView.backgroundColor = [UIColor whiteColor];
    self.navigationBackgroundView.layer.masksToBounds = true;
    self.navigationBackgroundView.layer.shadowRadius = 0;
    self.navigationBackgroundView.layer.shadowOffset = CGSizeMake(0, (1 / [UIScreen mainScreen].scale));
    self.navigationBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.navigationBackgroundView.layer.shadowOpacity = 0;
    [self.view insertSubview:self.navigationBackgroundView belowSubview:self.navigationBar];
    
    [self setupNavigationBarItems];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    // ugly: responsibilities aren't separated well (proof of concept, only!)
    NSLog(@"self.presentedViewController: %@", self.presentedViewController);
    if (self.presentedViewController && (!self.presentedViewController.isBeingDismissed)) {
        NSLog(@"BOOOOOOOOOOOOOM : %ld", (long)self.presentedViewController.preferredStatusBarStyle);
        NSLog(@"verdict: %@", self.presentedViewController.preferredStatusBarStyle == UIStatusBarStyleDefault ? @"DEFAULT BLEH" : @"LIIIIGHT");
        return self.presentedViewController.preferredStatusBarStyle;
    }
    
    
    return [super preferredStatusBarStyle];
}

- (UIViewController*)childViewControllerForStatusBarStyle {
    if (self.presentedViewController) {
        return self.presentedViewController.childViewControllerForStatusBarStyle;
    }
    
    return [super childViewControllerForStatusBarStyle];
}

- (void)didFinishSwiping {
    NSLog(@"didFinishSwiping!!!");
    [self goBack];
}

- (void)goBack {
    int animationType = (self.rightActionButton.tag == LNActionTypeCancel) ? 1 : 3;
    UIColor *nextTheme = [UIColor whiteColor];
    
    if ([self.viewControllers lastObject].navigationController.tabBarController != nil) {
        [self.searchView updateSearchText:@""];
        nextTheme = [UIColor whiteColor];
    }
    else {
        UIViewController *previousVC = [self.viewControllers lastObject];
        
        BOOL showSearchIcon = true;
        [self.searchView updateSearchText:previousVC.title];
        
        if ([[self.viewControllers lastObject] isKindOfClass:[RoomViewController class]]) {
            RoomViewController *previousRoom = [self.viewControllers lastObject];
            nextTheme = previousRoom.theme;
        }
        else if ([[self.viewControllers lastObject] isKindOfClass:[ProfileViewController class]]) {
            ProfileViewController *previousProfile = [self.viewControllers lastObject];
            nextTheme = previousProfile.theme;
        }
        else if ([[self.viewControllers lastObject] isKindOfClass:[PostViewController class]]) {
            PostViewController *previousPost = [self.viewControllers lastObject];
            showSearchIcon = false;

            nextTheme = previousPost.theme;
        }
        else if ([[self.viewControllers lastObject] isKindOfClass:[RoomMembersViewController class]]) {
            RoomMembersViewController *previousMembersView = [self.viewControllers lastObject];
            showSearchIcon = false;
            nextTheme = previousMembersView.theme;
        }
        else if ([[self.viewControllers lastObject] isKindOfClass:[ProfileCampsListViewController class]]) {
            ProfileCampsListViewController *previousProfileCampsListView = [self.viewControllers lastObject];
            showSearchIcon = false;
            nextTheme = previousProfileCampsListView.theme;
        }
        else if ([[self.viewControllers lastObject] isKindOfClass:[ProfileFollowingListViewController class]]) {
            ProfileFollowingListViewController *previousProfileFollowingListView = [self.viewControllers lastObject];
            showSearchIcon = false;
            nextTheme = previousProfileFollowingListView.theme;
        }
        
        if (showSearchIcon) {
            [self.searchView updateSearchText:previousVC.title];
        }
        else {
            self.searchView.textField.text = previousVC.title;
            [self.searchView hideSearchIcon:false];
        }
    }
    [self updateBarColor:nextTheme withAnimation:animationType statusBarUpdateDelay:NO];
        
    [self updateNavigationBarItemsWithAnimation:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)setShadowVisibility:(BOOL)visible withAnimation:(BOOL)animation {    
    [UIView animateWithDuration:animation?0.25f:0 animations:^{
        self.navigationBackgroundView.layer.shadowOpacity = visible ? 0.12f : 0;
    } completion:nil];
}
- (void)updateBarColor:(id)newColor withAnimation:(int)animationType statusBarUpdateDelay:(CGFloat)statusBarUpdateDelay {
    if ([newColor isKindOfClass:[NSString class]]) {
        newColor = [UIColor fromHex:newColor];
    }
    self.currentTheme = newColor;
    
    CGFloat diameter = self.navigationBackgroundView.frame.size.width * 1.2;
    CGFloat beforeDiameter = 0.02 * diameter;
    
    UIView *newColorView = [[UIView alloc] init];
    if (animationType == 0 || animationType == 1) {
        // fade
        newColorView.frame = CGRectMake(0, 0, self.navigationBackgroundView.frame.size.width, self.navigationBackgroundView.frame.size.height);;
        newColorView.layer.cornerRadius = 0;
        newColorView.alpha = animationType == 0 ? 1 : 0;
        newColorView.backgroundColor = newColor;
    }
    else {
        // bubble burst
        newColorView.frame = CGRectMake(self.navigationBackgroundView.frame.size.width / 2 - (diameter / 2), self.navigationBackgroundView.frame.size.height + 40, diameter, diameter);
        newColorView.center = CGPointMake(self.navigationBackgroundView.frame.size.width / 2, self.navigationBackgroundView.frame.size.height + (beforeDiameter / 2));
        newColorView.layer.cornerRadius = newColorView.frame.size.width / 2;
        
        if (animationType == 2) {
            newColorView.backgroundColor = newColor;
            newColorView.transform = CGAffineTransformMakeScale(0.02, 0.02);
        }
        else if (animationType == 3) {
            newColorView.backgroundColor = self.navigationBackgroundView.backgroundColor;
            newColorView.transform = CGAffineTransformMakeScale(1, 1);
            self.navigationBackgroundView.backgroundColor = newColor;
        }
    }
    newColorView.layer.masksToBounds = true;
    newColorView.layer.shouldRasterize = true;
    newColorView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    [self.navigationBackgroundView addSubview:newColorView];
    
    [UIView animateWithDuration:(animationType == 0 ? 0 : barColorUpdateDuration) delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // status bar
        if ([UIColor useWhiteForegroundForColor:newColor]) {
            self.navigationBar.barStyle = UIBarStyleBlack;
        }
        else {
            self.navigationBar.barStyle = UIBarStyleDefault;
        }
        
        [self setNeedsStatusBarAppearanceUpdate];
        
        // foreground items
        if (animationType == 1) {
            // fade
            newColorView.alpha = 1;
        }
        else if (animationType == 2) {
            // bubble burst
            // newColorView.center = CGPointMake(self.navigationBackgroundView.frame.size.width / 2, self.navigationBackgroundView.frame.size.height / 2);
            newColorView.transform = CGAffineTransformMakeScale(1, 1);
        }
        else if (animationType == 3) {
            // bubble roll back da burst
            // newColorView.center = CGPointMake(self.navigationBackgroundView.frame.size.width / 2, self.navigationBackgroundView.frame.size.height + (beforeDiameter / 2));
            newColorView.transform = CGAffineTransformMakeScale(0.02, 0.02);
        }
        
        UIImageView *searchIcon = self.searchView.searchIcon;
        
        if ([UIColor useWhiteForegroundForColor:newColor]) {
            self.searchView.textField.textColor = [UIColor whiteColor];
            self.searchView.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.searchView.textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.75]}];
            
            self.searchView.textField.tintColor =
            self.leftActionButton.tintColor =
            self.rightActionButton.tintColor = [UIColor whiteColor];
            
            searchIcon.alpha = 0.75;
        }
        else if ([newColor isEqual:[UIColor whiteColor]]) {
            // searchViewBackgroundColor = [UIColor bonfireTextFieldBackgroundOnWhite];
            self.searchView.textField.textColor = [UIColor colorWithWhite:0.07f alpha:1];
            self.searchView.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.searchView.textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0 alpha:0.25]}];
            
            UIColor *tintColor = [UIColor bonfireBlack];
            self.searchView.textField.tintColor =
            self.leftActionButton.tintColor =
            self.rightActionButton.tintColor = tintColor;
            
            searchIcon.alpha = 0.25f;
        }
        else {
            self.searchView.textField.textColor = [UIColor colorWithWhite:0.07f alpha:1];
            self.searchView.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.searchView.textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0 alpha:0.25]}];
            
            self.shadowView.alpha = 0;
            
            self.searchView.textField.tintColor =
            self.leftActionButton.tintColor =
            self.rightActionButton.tintColor = [UIColor colorWithWhite:0.07f alpha:1];
            
            searchIcon.alpha = 0.25f;
        }
        
        if (self.searchView.searchIcon.isHidden) {
            self.searchView.backgroundColor = [UIColor clearColor];
        }
        else {
            if ([UIColor useWhiteForegroundForColor:self.currentTheme]) {
                self.searchView.theme = BFTextFieldThemeLight;
            }
            else if ([self.currentTheme isEqual:[UIColor whiteColor]] ||
                     [self.topViewController isKindOfClass:[MyRoomsViewController class]]) {
                self.searchView.theme = BFTextFieldThemeDark;
            }
            else {
                self.searchView.theme = BFTextFieldThemeExtraDark;
            }
        }
        
        searchIcon.tintColor = self.searchView.textField.textColor;
    } completion:^(BOOL finished) {
        if (self.currentTheme == newColor && animationType != 3) {
            self.navigationBackgroundView.backgroundColor = newColor;
        }
        
        if (self.currentTheme != newColor) {
            // fade it out
            [UIView animateWithDuration:0.25f animations:^{
                newColorView.alpha = 0;
            } completion:^(BOOL finished) {
                [newColorView removeFromSuperview];
            }];
        }
        else {
            [newColorView removeFromSuperview];
        }
    }];
}

- (void)setupNavigationBarItems {
    // create smart text field
    self.searchView = [[BFSearchView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - (54 * 2), 34)];
    // TODO: Search in groups
    //self.searchView.resultsType = BFSearchResultsTypeTopPosts;
    self.searchView.textField.delegate = self;
    [self.searchView.textField bk_addEventHandler:^(id sender) {
        if ([self.topViewController isKindOfClass:[SearchTableViewController class]]) {
            SearchTableViewController *topSearchController = (SearchTableViewController *)self.topViewController;
            if ([self.topViewController isKindOfClass:[SearchTableViewController class]]) {
                [topSearchController searchFieldDidChange];
            }
        }
    } forControlEvents:UIControlEventEditingChanged];
    self.searchView.openSearchControllerOntap = true;
    self.searchView.center = CGPointMake(self.navigationBar.frame.size.width / 2, self.navigationBar.frame.size.height / 2);
    
    UIColor *textFieldBackgroundColor;
    if ([UIColor useWhiteForegroundForColor:self.currentTheme]) {
        textFieldBackgroundColor = [UIColor bonfireTextFieldBackgroundOnDark];
        self.searchView.theme = BFTextFieldThemeLight;
    }
    else if ([self.currentTheme isEqual:[UIColor whiteColor]] ||
             [self.topViewController isKindOfClass:[MyRoomsViewController class]]) {
        textFieldBackgroundColor = [UIColor bonfireTextFieldBackgroundOnWhite];
        self.searchView.theme = BFTextFieldThemeDark;
    }
    else {
        textFieldBackgroundColor = [UIColor bonfireTextFieldBackgroundOnLight];
        self.searchView.theme = BFTextFieldThemeExtraDark;
    }
    self.searchView.backgroundColor = textFieldBackgroundColor;
    
    self.searchView.textField.textColor = [UIColor colorWithWhite:0.07f alpha:1];
    self.searchView.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search Camps & People" attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0 alpha:0.25]}];
    
    self.searchView.textField.userInteractionEnabled = false;
    
    [self.navigationBar addSubview:self.searchView];
    
    self.navigationItem.backBarButtonItem = nil;
    
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.interactivePopGestureRecognizer.enabled = true;
}

- (void)updateNavigationBarItemsWithAnimation:(BOOL)animated {
    // determine items based on active view controller
    if ([self.topViewController isKindOfClass:[SearchTableViewController class]]) {
        [self setLeftAction:LNActionTypeNone];
    }
    else {
        [self setLeftAction:LNActionTypeBack];
    }
    
    if ([self.topViewController isKindOfClass:[RoomViewController class]]) {
        if (self.isCreatingPost) {
            [self setRightAction:LNActionTypeNone];
        }
        else {
            [self setRightAction:LNActionTypeMore];
        }
    }
    else if ([self.topViewController isKindOfClass:[PostViewController class]]) {
        [self setRightAction:LNActionTypeMore];
    }
    else if ([self.topViewController isKindOfClass:[RoomMembersViewController class]]) {
        [self setRightAction:LNActionTypeNone];
    }
    else if ([self.topViewController isKindOfClass:[ProfileViewController class]]) {
        [self setRightAction:LNActionTypeMore];
    }
    else if ([self.topViewController isKindOfClass:[SearchTableViewController class]]) {
        [self setRightAction:LNActionTypeCancel];
    }
    else {
        [self setRightAction:LNActionTypeNone];
    }
    
    [UIView animateWithDuration:(animated?barColorUpdateDuration:0) delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0.5 options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
        if (self.leftActionButton.tag == LNActionTypeBack) {
            if (self.viewControllers.count == 1) {
                self.leftActionButton.transform = CGAffineTransformMakeRotation(0);
            }
            else if (self.viewControllers.count > 1) {
                self.leftActionButton.transform = CGAffineTransformMakeRotation(0);
            }
        }
        
        if ([self.topViewController isKindOfClass:[SearchTableViewController class]]) {
            self.searchView.frame = CGRectMake(16, self.searchView.frame.origin.y, self.view.frame.size.width - 16 - 90, self.searchView.frame.size.height);
            [self.searchView setPosition:BFSearchTextPositionLeft];
        }
        else {
            self.searchView.frame = CGRectMake(56, self.searchView.frame.origin.y, self.view.frame.size.width - (54 * 2), self.searchView.frame.size.height);
            [self.searchView setPosition:BFSearchTextPositionCenter];
        }
    } completion:^(BOOL finished) {
        
    }];
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

- (UIButton *)createActionButtonForType:(LNActionType)actionType {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    
    if (actionType == LNActionTypeCancel) {
        [button setTitle:@"Cancel" forState:UIControlStateNormal];
    }
    if (actionType == LNActionTypeCompose) {
        [button setImage:[[UIImage imageNamed:@"composeIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [button setImageEdgeInsets:UIEdgeInsetsMake(-2, 0, 0, -3)];
    }
    if (actionType == LNActionTypeMore) {
        [button setImage:[[UIImage imageNamed:@"navMoreIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    if (actionType == LNActionTypeInvite) {
        [button setImage:[[UIImage imageNamed:@"inviteFriendIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    if (actionType == LNActionTypeAdd) {
        [button setImage:[[UIImage imageNamed:@"navPlusIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    if (actionType == LNActionTypeBack) {
        [button setImage:[[UIImage imageNamed:@"leftArrowIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
    
    if (button.currentTitle.length > 0) {
        [button.titleLabel setFont:[UIFont systemFontOfSize:17.f weight:UIFontWeightMedium]];
    }
    
    button.tintColor = ([UIColor useWhiteForegroundForColor:self.currentTheme] ? [UIColor whiteColor] : [UIColor colorWithWhite:0.07f alpha:1]);
    
    CGFloat padding = 16;
    button.frame = CGRectMake(0, 0, button.intrinsicContentSize.width + (padding * 2), self.navigationBar.frame.size.height);
    
    [button bk_whenTapped:^{
        switch (actionType) {
            case LNActionTypeCancel:
                if (self.viewControllers.count == 1) {
                    // VC is the top most view controller
                    [self.searchView.textField resignFirstResponder];
                    
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
                else {
                    [self.searchView.textField resignFirstResponder];
                    
                    CATransition* transition = [CATransition animation];
                    transition.duration = 0.25f;
                    transition.type = kCATransitionFade;
                    [self.navigationController.view.layer addAnimation:transition forKey:nil];
                    [self popViewControllerAnimated:NO];
                    
                    [self goBack];
                }
                break;
            case LNActionTypeCompose:
                [[Launcher sharedInstance] openComposePost:nil inReplyTo:nil withMessage:nil media:nil];
                break;
            case LNActionTypeMore: {
                if ([self.viewControllers[self.viewControllers.count-1] isKindOfClass:[RoomViewController class]]) {
                    RoomViewController *activeRoom = self.viewControllers[self.viewControllers.count-1];
                    [activeRoom openRoomActions];
                }
                else if ([self.viewControllers[self.viewControllers.count-1] isKindOfClass:[ProfileViewController class]]) {
                    ProfileViewController *activeProfile = self.viewControllers[self.viewControllers.count-1];
                    [activeProfile openProfileActions];
                }
                else if ([self.viewControllers[self.viewControllers.count-1] isKindOfClass:[PostViewController class]]) {
                    PostViewController *activePost = self.viewControllers[self.viewControllers.count-1];
                    [[Launcher sharedInstance] openActionsForPost:activePost.post];
                }
                break;
            }
            case LNActionTypeInvite:
                [[Launcher sharedInstance] openInviteFriends:self];
                break;
            case LNActionTypeAdd:
                break;
            case LNActionTypeBack: {
                if (self.isCreatingPost || self.searchResultsTableView.alpha != 1 || self.searchResultsTableView.isHidden) {
                    if (self.viewControllers.count == 1) {
                        // VC is the top most view controller
                        [self.view endEditing:YES];
                        
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                    else {
                        [self popViewControllerAnimated:YES];
                        
                        [self goBack];
                    }
                }
                else {
                    [self.searchView.textField resignFirstResponder];
                    
                    self.searchView.textField.placeholder = [NSString stringWithFormat:@"Search in %@", self.topViewController.title];
                    [self.searchView updateSearchText:self.topViewController.title];
                    
                    [self updateNavigationBarItemsWithAnimation:YES];
                }
                break;
            }
                
            default:
                break;
        }
    }];
    
    if (LNActionTypeBack) {
        UILongPressGestureRecognizer *longPressToGoHome = [[UILongPressGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            switch (actionType) {
                case LNActionTypeBack: {
                    if (state == UIGestureRecognizerStateBegan) {
                        [self setEditing:false];
                        
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                    break;
                }
                    
                default:
                    break;
            }
        }];
        [button addGestureRecognizer:longPressToGoHome];
    }
    
    [self.navigationBar addSubview:button];
    
    return button;
}
- (void)setLeftAction:(LNActionType)actionType {
    if ((NSInteger)actionType != self.leftActionButton.tag) {
        [self.leftActionButton removeFromSuperview];
        if (actionType == LNActionTypeNone) {
            self.leftActionButton = nil;
        }
        else {
            self.leftActionButton = [self createActionButtonForType:actionType];
            self.leftActionButton.frame = CGRectMake(0, self.leftActionButton.frame.origin.y, self.leftActionButton.frame.size.width, self.leftActionButton.frame.size.height);
            
            self.leftActionButton.tag = actionType;
        }
    }
}
- (void)setRightAction:(LNActionType)actionType {
    if ((NSInteger)actionType != self.rightActionButton.tag) {
        [self.rightActionButton removeFromSuperview];
        if (actionType == LNActionTypeNone) {
            self.rightActionButton = nil;
        }
        else {
            self.rightActionButton = [self createActionButtonForType:actionType];
            self.rightActionButton.frame = CGRectMake(self.navigationBar.frame.size.width - self.rightActionButton.frame.size.width, self.rightActionButton.frame.origin.y, self.rightActionButton.frame.size.width, self.rightActionButton.frame.size.height);
            
            self.rightActionButton.tag = actionType;
        }
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.searchView.textField) {
        self.searchView.textField.userInteractionEnabled = false;
    }
}

@end
