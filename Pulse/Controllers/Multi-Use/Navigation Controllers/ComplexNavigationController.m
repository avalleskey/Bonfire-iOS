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
#import "SOLOptionsTransitionAnimator.h"
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

#define envConfig [[[NSUserDefaults standardUserDefaults] objectForKey:@"config"] objectForKey:[[NSUserDefaults standardUserDefaults] stringForKey:@"environment"]]

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTheme:) name:@"UserUpdated" object:nil];
    
    BOOL iPhoneX = NO;
    if (@available(iOS 11.0, *)) {
        UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
        if (mainWindow.safeAreaInsets.top > 24.0) {
            iPhoneX = YES;
        }
    }
    
    NSLog(@"isiPhoneX? %@", iPhoneX ? @"YES" : @"NO");
}
- (void)updateTheme:(id)sender {
    if ([self.visibleViewController isKindOfClass:[ProfileViewController class]]) {
        ProfileViewController *profileVC = (ProfileViewController *)self.visibleViewController;
        if ([profileVC.user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
            [self updateBarColor:[Session sharedInstance].themeColor withAnimation:1 statusBarUpdateDelay:0];
        }
    }
    else if (self.currentTheme == [UIColor whiteColor] || self.currentTheme == [UIColor clearColor]) {
        [self updateBarColor:self.currentTheme withAnimation:0 statusBarUpdateDelay:0];
    }
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSLog(@"viewWillAppear()");
}

- (void)didFinishSwiping {
    [self goBack];
}

- (void)goBack {
    int animationType = (self.rightActionButton.tag == LNActionTypeCancel) ? 1 : 3;
    
    NSLog(@"coming from search view?? %@", self.rightActionButton.tag == LNActionTypeCancel ? @"YES" : @"NO");
    
    if ([[self.viewControllers lastObject] isKindOfClass:[RoomViewController class]]) {
        RoomViewController *previousRoom = [self.viewControllers lastObject];
        [self updateBarColor:previousRoom.theme withAnimation:animationType statusBarUpdateDelay:NO];
        [self.searchView updateSearchText:previousRoom.title];
    }
    else if ([self.viewControllers lastObject].navigationController.tabBarController != nil) {
        [self updateBarColor:[UIColor whiteColor] withAnimation:animationType statusBarUpdateDelay:NO];
        [self.searchView updateSearchText:@""];
    }
    else if ([[self.viewControllers lastObject] isKindOfClass:[ProfileViewController class]]) {
        ProfileViewController *previousProfile = [self.viewControllers lastObject];
        [self updateBarColor:previousProfile.theme withAnimation:animationType statusBarUpdateDelay:NO];
        [self.searchView updateSearchText:previousProfile.title];
    }
    else if ([[self.viewControllers lastObject] isKindOfClass:[PostViewController class]]) {
        PostViewController *previousPost = [self.viewControllers lastObject];
        [self updateBarColor:previousPost.theme withAnimation:animationType statusBarUpdateDelay:NO];
        
        self.searchView.textField.text = previousPost.title;
        [self.searchView hideSearchIcon:false];
    }
    else if ([[self.viewControllers lastObject] isKindOfClass:[RoomMembersViewController class]]) {
        RoomMembersViewController *previousMembersView = [self.viewControllers lastObject];
        [self updateBarColor:previousMembersView.theme withAnimation:animationType statusBarUpdateDelay:NO];
        
        self.searchView.textField.text = previousMembersView.title;
        [self.searchView hideSearchIcon:false];
    }
    
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
    
    CGFloat animationDuration = 0.3f;
    UIView *newColorView = [[UIView alloc] init];
    if (animationType == 0 || animationType == 1) {
        // fade
        newColorView.frame = CGRectMake(0, 0, self.navigationBackgroundView.frame.size.width, self.navigationBackgroundView.frame.size.height);;
        newColorView.layer.cornerRadius = 0;
        newColorView.alpha = animationType == 0 ? 1 : 0;
        newColorView.backgroundColor = newColor;
        if (animationType == 0) animationDuration = 0;
        if (animationType == 1) animationDuration = 0.2f;
    }
    else {
        // bubble burst
        newColorView.frame = CGRectMake(self.navigationBackgroundView.frame.size.width / 2 - 5, self.navigationBackgroundView.frame.size.height + 40, 10, 10);
        newColorView.layer.cornerRadius = 5.f;
        
        if (animationType == 2) {
            newColorView.backgroundColor = newColor;
        }
        else if (animationType == 3) {
            newColorView.backgroundColor = self.navigationBackgroundView.backgroundColor;
            newColorView.transform = CGAffineTransformMakeScale(self.navigationBackgroundView.frame.size.width / 10, self.navigationBackgroundView.frame.size.width / 10);
            self.navigationBackgroundView.backgroundColor = newColor;
        }
    }
    newColorView.layer.masksToBounds = true;
    [self.navigationBackgroundView addSubview:newColorView];
    
    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
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
            newColorView.transform = CGAffineTransformMakeScale(self.navigationBackgroundView.frame.size.width / 8, self.navigationBackgroundView.frame.size.width / 8);
        }
        else if (animationType == 3) {
            // bubble roll back da burst
            newColorView.transform = CGAffineTransformMakeScale(1, 1);
        }
        
        UIImageView *searchIcon = self.searchView.searchIcon;
        
        if ([UIColor useWhiteForegroundForColor:newColor]) {
            self.searchView.theme = BFTextFieldThemeLight;
            
            self.searchView.textField.textColor = [UIColor whiteColor];
            self.searchView.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.searchView.textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.75]}];
            self.searchView.backgroundColor = [UIColor bonfireTextFieldBackgroundOnDark];
            
            self.leftActionButton.tintColor =
            self.rightActionButton.tintColor = [UIColor whiteColor];
            
            searchIcon.alpha = 0.75;
        }
        else if ([newColor isEqual:[UIColor whiteColor]]) {
            self.searchView.theme = BFTextFieldThemeDark;
            
            self.searchView.backgroundColor = [UIColor bonfireTextFieldBackgroundOnWhite];
            self.searchView.textField.textColor = [UIColor colorWithWhite:0.07f alpha:1];
            self.searchView.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.searchView.textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0 alpha:0.25]}];
            
            UIColor *tintColor = (self.searchView.isFirstResponder ? [UIColor colorWithWhite:0.2f alpha:1] : [[Session sharedInstance] themeColor]);
            self.leftActionButton.tintColor =
            self.rightActionButton.tintColor = tintColor;
            
            searchIcon.alpha = 0.25f;
        }
        else {
            self.searchView.theme = BFTextFieldThemeExtraDark;
            
            self.searchView.backgroundColor = [UIColor bonfireTextFieldBackgroundOnLight];
            self.searchView.textField.textColor = [UIColor colorWithWhite:0.07f alpha:1];
            self.searchView.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.searchView.textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0 alpha:0.25]}];
            
            self.shadowView.alpha = 0;
            
            self.leftActionButton.tintColor =
            self.rightActionButton.tintColor = [UIColor colorWithWhite:0.07f alpha:1];
            
            searchIcon.alpha = 0.25f;
        }
        
        searchIcon.tintColor = self.searchView.textField.textColor;
    } completion:^(BOOL finished) {
        if (animationType != 3) {
            self.navigationBackgroundView.backgroundColor = newColor;
        }
        [newColorView removeFromSuperview];
    }];
}

- (void)setupNavigationBarItems {
    // create smart text field
    self.searchView = [[BFSearchView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - (54 * 2), 34)];
    self.searchView.textField.delegate = self;
    [self.searchView.textField bk_addEventHandler:^(id sender) {
        if ([self.topViewController isKindOfClass:[SearchTableViewController class]]) {
            SearchTableViewController *topSearchController = (SearchTableViewController *)self.topViewController;
            [topSearchController searchFieldDidChange];
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
    self.searchView.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search" attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0 alpha:0.25]}];
    
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
        [self setRightAction:LNActionTypeCancel];
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
    
    [UIView animateWithDuration:animated?0.25f:0 delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (self.leftActionButton.tag == LNActionTypeBack) {
            NSLog(@"viewcontroller count: %lu", (unsigned long)self.viewControllers.count);
            
            if (self.viewControllers.count == 1) {
                self.leftActionButton.transform = CGAffineTransformMakeRotation(0);
            }
            else if (self.viewControllers.count > 1) {
                self.leftActionButton.transform = CGAffineTransformMakeRotation(M_PI_2);
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
        
        if ([self.topViewController isKindOfClass:[PostViewController class]] ||
            [self.topViewController isKindOfClass:[RoomMembersViewController class]]) {
            self.searchView.userInteractionEnabled = false;
            self.searchView.backgroundColor = [UIColor clearColor];
        }
        else {
            self.searchView.userInteractionEnabled = true;
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
                [[Launcher sharedInstance] openComposePost];
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
                    [activePost openPostActions];
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
