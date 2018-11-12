//
//  LauncherNavigationViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 9/27/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "LauncherNavigationViewController.h"
#import "HAWebService.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <HapticHelper/HapticHelper.h>
#import "SOLOptionsTransitionAnimator.h"
#import "SearchResultCell.h"
#import "HomeViewController.h"
#import "CreateRoomViewController.h"
#import "NSArray+Clean.h"

// Views it can open
#import "RoomViewController.h"
#import "RoomMembersViewController.h"
#import "ProfileViewController.h"
#import "PostViewController.h"
#import "OnboardingViewController.h"
#import "EditProfileViewController.h"

#define envConfig [[[NSUserDefaults standardUserDefaults] objectForKey:@"config"] objectForKey:[[NSUserDefaults standardUserDefaults] stringForKey:@"environment"]]

@interface LauncherNavigationViewController ()

@property (strong, nonatomic) NSMutableDictionary *searchResults;
@property (strong, nonatomic) NSMutableArray *recentSearchResults;
@property (strong, nonatomic) HAWebService *manager;

@end

@implementation LauncherNavigationViewController

static NSString * const reuseIdentifier = @"Result";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.transitioningDelegate = self;
    
    self.swiper = [[SloppySwiper alloc] initWithNavigationController:self];
    self.swiper.delegate = self;
    self.delegate = self.swiper;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    // remove hairline
    [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setShadowImage:[UIImage new]];
    
    // set background color
    [self.navigationBar setTranslucent:false];
    [self.navigationBar setBarTintColor:[UIColor whiteColor]];
    self.navigationItem.titleView = nil;
    self.navigationItem.title = nil;
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor clearColor]};
    
    // add background color view
    self.navigationBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationBar.frame.size.height - (self.navigationBar.frame.size.height + 50), self.view.frame.size.width, self.navigationBar.frame.size.height + 50)];
    self.navigationBackgroundView.backgroundColor = [UIColor whiteColor];
    self.navigationBackgroundView.layer.masksToBounds = true;
    [self.navigationBar insertSubview:self.navigationBackgroundView atIndex:0];
    
    // add shadow to the top
    self.shadowView = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationBar.frame.size.height - 20, self.view.frame.size.width, 20)];
    self.shadowView.layer.shadowRadius = 0;
    self.shadowView.layer.shadowOffset = CGSizeMake(0, 1);
    self.shadowView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.shadowView.layer.shadowOpacity = 0.04f;
    self.shadowView.backgroundColor = [UIColor whiteColor];
    [self.navigationBar insertSubview:self.shadowView atIndex:0];
    
    [self setupNavigationBarItems];
    
    self.manager = [HAWebService manager];
    [self setupSearch];
}

- (void)didFinishSwiping {
    NSLog(@"did finish swiping");
    
    if ([[self.viewControllers lastObject] isKindOfClass:[RoomViewController class]]) {
        RoomViewController *previousRoom = [self.viewControllers lastObject];
        [self updateBarColor:previousRoom.theme withAnimation:3 statusBarUpdateDelay:NO];
        [self updateSearchText:previousRoom.title];
    }
    else if ([[self.viewControllers lastObject] isKindOfClass:[HomeViewController class]]) {
        [self updateBarColor:[UIColor whiteColor] withAnimation:3 statusBarUpdateDelay:NO];
        [self updateSearchText:@""];
    }
    else if ([[self.viewControllers lastObject] isKindOfClass:[ProfileViewController class]]) {
        ProfileViewController *previousProfile = [self.viewControllers lastObject];
        [self updateBarColor:previousProfile.theme withAnimation:3 statusBarUpdateDelay:NO];
        [self updateSearchText:previousProfile.title];
    }
    else if ([[self.viewControllers lastObject] isKindOfClass:[PostViewController class]]) {
        PostViewController *previousPost = [self.viewControllers lastObject];
        [self updateBarColor:previousPost.theme withAnimation:3 statusBarUpdateDelay:NO];
        
        self.textField.text = previousPost.title;
        [self hideSearchIcon];
    }
    else if ([[self.viewControllers lastObject] isKindOfClass:[RoomMembersViewController class]]) {
        RoomMembersViewController *previousMembersView = [self.viewControllers lastObject];
        [self updateBarColor:previousMembersView.theme withAnimation:3 statusBarUpdateDelay:NO];
        
        self.textField.text = previousMembersView.title;
        [self hideSearchIcon];
    }
    
    [self updateNavigationBarItemsWithAnimation:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)setShadowVisibility:(BOOL)visible withAnimation:(BOOL)animation {
    [UIView animateWithDuration:animation?0.25f:0 animations:^{
        self.shadowView.alpha = visible ? 1 : 0;
    } completion:nil];
}
- (void)updateBarColor:(id)newColor withAnimation:(int)animationType statusBarUpdateDelay:(CGFloat)statusBarUpdateDelay {
    if ([newColor isKindOfClass:[NSString class]]) {
        newColor = [self colorFromHexString:newColor];
    }
    self.currentTheme = newColor;
    
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
        newColorView.frame = CGRectMake(self.navigationBackgroundView.frame.size.width / 2, self.navigationBackgroundView.frame.size.height + 40, 10, 10);
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
    
    [UIView animateWithDuration:(animationType != 0 ? 0.25f : 0) delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        // status bar
        if ([self useWhiteForegroundForColor:newColor]) {
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
        
        UIImageView *searchIcon = [self.textField viewWithTag:3];
        
        if ([self useWhiteForegroundForColor:newColor]) {
            self.textField.tintColor = [UIColor whiteColor];
            self.textField.textColor = [UIColor whiteColor];
            self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.75]}];
            self.textField.backgroundColor = [UIColor colorWithWhite:1 alpha:0.16f];
            
            self.shadowView.alpha = 0;
            
            self.backButton.tintColor =
            self.infoButton.tintColor =
            self.composePostButton.tintColor =
            self.moreButton.tintColor = [UIColor whiteColor];
            
            searchIcon.alpha = 0.75;
        }
        else if ([newColor isEqual:[UIColor whiteColor]]) {
            self.textField.tintColor = [Session sharedInstance].themeColor;
            self.textField.backgroundColor = [UIColor colorWithWhite:0 alpha:0.06f];
            self.textField.textColor = [UIColor colorWithWhite:0.07f alpha:1];
            self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0 alpha:0.25]}];
            
            self.shadowView.alpha = 1;
            
            if (self.textField.isFirstResponder) {
                self.backButton.tintColor = [UIColor colorWithWhite:0.2f alpha:1];
            }
            else {
                self.backButton.tintColor =
                self.infoButton.tintColor =
                self.composePostButton.tintColor =
                self.moreButton.tintColor = [[Session sharedInstance] themeColor];
            }
            
            searchIcon.alpha = 0.25f;
        }
        else {
            self.textField.tintColor = [UIColor colorWithWhite:0.07f alpha:1];
            
            self.textField.backgroundColor = [UIColor colorWithWhite:0 alpha:0.06f];
            self.textField.textColor = [UIColor colorWithWhite:0.07f alpha:1];
            self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.textField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0 alpha:0.25]}];
            
            self.shadowView.alpha = 0;
            
            // this is the same as...
            self.backButton.tintColor =
            self.infoButton.tintColor =
            self.composePostButton.tintColor =
            self.moreButton.tintColor = [UIColor colorWithWhite:0.07f alpha:1];
            
            searchIcon.alpha = 0.25f;
        }
        
        searchIcon.tintColor = self.textField.textColor;
    } completion:^(BOOL finished) {
        if (animationType != 3) {
            self.navigationBackgroundView.backgroundColor = newColor;
        }
        [newColorView removeFromSuperview];
    }];
}
- (BOOL)useWhiteForegroundForColor:(UIColor*)backgroundColor {
    size_t count = CGColorGetNumberOfComponents(backgroundColor.CGColor);
    const CGFloat *componentColors = CGColorGetComponents(backgroundColor.CGColor);
    
    CGFloat darknessScore = 0;
    if (count == 2) {
        darknessScore = (((componentColors[0]*255) * 299) + ((componentColors[0]*255) * 587) + ((componentColors[0]*255) * 114)) / 1000;
    } else if (count == 4) {
        darknessScore = (((componentColors[0]*255) * 299) + ((componentColors[1]*255) * 587) + ((componentColors[2]*255) * 114)) / 1000;
    }
    
    if (darknessScore >= 155) {
        return false;
    }
    
    return true;
}
- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    if (hexString != nil && hexString.length == 6) {
        NSScanner *scanner = [NSScanner scannerWithString:hexString];
        [scanner setScanLocation:0]; // bypass '#' character
        [scanner scanHexInt:&rgbValue];
        return [UIColor colorWithDisplayP3Red:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
    }
    else {
        return [UIColor colorWithWhite:0.2f alpha:1];
    }
}

- (void)setupNavigationBarItems {
    // create smart text field
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - (62 * 2), 36)];
    [self continuityRadiusForView:self.textField withRadius:11.f];
    //self.textField.layer.cornerRadius = self.textField.frame.size.height / 2;
    self.textField.center = CGPointMake(self.navigationBar.frame.size.width / 2, self.navigationBar.frame.size.height / 2);
    self.textField.textAlignment = NSTextAlignmentCenter;
    self.textField.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightBold];
    self.textField.returnKeyType = UIReturnKeyGo;
    self.textField.delegate = self;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.backgroundColor = [UIColor colorWithWhite:0 alpha:0.06f];
    self.textField.textColor = [UIColor colorWithWhite:0.07f alpha:1];
    self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search" attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0 alpha:0.25]}];
    
    UIImageView *searchIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.textField.frame.size.height / 2 - 8, 16, 16)];
    searchIcon.image = [[UIImage imageNamed:@"searchIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    searchIcon.tag = 3;
    searchIcon.tintColor = self.textField.textColor;
    searchIcon.alpha = 0.25;
    [self.textField addSubview:searchIcon];
    
    [self positionTextFieldSearchIcon];
    
    UIView *leftPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16 + 26, 1)];
    self.textField.leftView = leftPaddingView;
    self.textField.leftViewMode = UITextFieldViewModeAlways;
    UIView *rightPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 1)];
    self.textField.rightView = rightPaddingView;
    self.textField.rightViewMode = UITextFieldViewModeAlways;
    
    [self.textField bk_whenTapped:^{
        if (!self.isCreatingPost && (self.searchResultsTableView.alpha != 1 || self.searchResultsTableView.isHidden)) {
            [self.textField becomeFirstResponder];
            
            self.textField.selectedTextRange = [self.textField textRangeFromPosition:self.textField.beginningOfDocument toPosition:self.textField.endOfDocument];
            [UIMenuController sharedMenuController].menuVisible = NO;
            
            [self updateBarColor:[UIColor whiteColor] withAnimation:0 statusBarUpdateDelay:NO];
            [self updateNavigationBarItemsWithAnimation:TRUE];
            
            [self.searchResultsTableView reloadData];
        }
        else if (self.isCreatingPost) {
            [self.textField becomeFirstResponder];
        }
    }];
    [self.textField bk_addEventHandler:^(id sender) {
        if (!self.isCreatingPost) {
            if (self.textField.text.length == 0) {
                NSLog(@"empty search results");
                [self emptySearchResults];
                [self.searchResultsTableView reloadData];
            }
            else {
                NSLog(@"getSearchResults");
                [self getSearchResults];
            }
        }
    } forControlEvents:UIControlEventEditingChanged];
     
    [self.textField bk_addEventHandler:^(id sender) {
        if (self.textField.tag == 0) {
            self.textField.tag = 1;
            
            CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
            [self.textField.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
            
            [UIView animateWithDuration:0.2f animations:^{
                self.textField.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha*2];
            }];
        }
    } forControlEvents:UIControlEventTouchDown];
    
     [self.textField bk_addEventHandler:^(id sender) {
         if (self.textField.tag == 1) {
             self.textField.tag = 0;
             
             CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
             [self.textField.backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
             
             [UIView animateWithDuration:0.2f animations:^{
                 self.textField.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha/2];
             }];
         }
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [self.navigationBar addSubview:self.textField];
    
    // create profile picture
    self.profilePicture = [[UIImageView alloc] initWithFrame:CGRectMake(16, 0, 32, 32)];
    self.profilePicture.center = CGPointMake(self.profilePicture.center.x, self.navigationBar.frame.size.height / 2);
    self.profilePicture.layer.borderWidth = 1 / [UIScreen mainScreen].scale;
    self.profilePicture.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
    self.profilePicture.backgroundColor = [UIColor whiteColor];
    self.profilePicture.tintColor = [Session sharedInstance].themeColor;
    if ([Session sharedInstance].currentUser.attributes.details.media.profilePicture.length > 0) {
        [self.profilePicture sd_setImageWithURL:[NSURL URLWithString:[Session sharedInstance].currentUser.attributes.details.media.profilePicture] placeholderImage:[[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    }
    else {
        [self.profilePicture setImage:[[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    }
    self.profilePicture.layer.cornerRadius = self.profilePicture.frame.size.height / 2;
    self.profilePicture.layer.masksToBounds = true;
    self.profilePicture.userInteractionEnabled = true;
    [self.profilePicture bk_whenTapped:^{
        if ([Session sharedInstance].currentUser) {
            [self openProfile:[Session sharedInstance].currentUser];
        }
        else {
            [self openOnboarding];
        }
    }];
    [self.navigationBar addSubview:self.profilePicture];
    
    // create new channel + button
    self.composePostButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.composePostButton setImage:[[UIImage imageNamed:@"composeIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.composePostButton.imageEdgeInsets = UIEdgeInsetsMake(-2, 0, 0, -2);
    self.composePostButton.tintColor = [[Session sharedInstance] themeColor];
    self.composePostButton.frame = CGRectMake(self.navigationBar.frame.size.width - 10 - 44, 0, 44, 44);
    self.composePostButton.center = CGPointMake(self.composePostButton.center.x, self.navigationBar.frame.size.height / 2);
    [self.navigationBar addSubview:self.composePostButton];
    
    // create new  + button
    self.infoButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.infoButton setImage:[[UIImage imageNamed:@"navInfoIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.infoButton.tintColor = [UIColor whiteColor];
    self.infoButton.frame = CGRectMake(self.navigationBar.frame.size.width - 10 - 44, 0, 44, 44);
    self.infoButton.center = CGPointMake(self.infoButton.center.x, self.navigationBar.frame.size.height / 2);
    [self.infoButton bk_whenTapped:^{
        NSLog(@"info button tapped");
        
    }];
    self.infoButton.alpha = 0;
    [self.navigationBar addSubview:self.infoButton];
    
    // more button
    self.moreButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.moreButton setImage:[[UIImage imageNamed:@"navMoreIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.moreButton.tintColor = [UIColor whiteColor];
    self.moreButton.frame = CGRectMake(self.navigationBar.frame.size.width - 10 - 44, 0, 44, 44);
    self.moreButton.center = CGPointMake(self.moreButton.center.x, self.navigationBar.frame.size.height / 2);
    self.moreButton.alpha = 0;
    [self.moreButton bk_whenTapped:^{
        if ([self.viewControllers[self.viewControllers.count-1] isKindOfClass:[RoomViewController class]]) {
            RoomViewController *activeRoom = self.viewControllers[self.viewControllers.count-1];
            [activeRoom openRoomActions];
        }
        else if ([self.viewControllers[self.viewControllers.count-1] isKindOfClass:[ProfileViewController class]]) {
            ProfileViewController *activeProfile = self.viewControllers[self.viewControllers.count-1];
            [activeProfile openProfileActions];
        }
        else if ([self.viewControllers[self.viewControllers.count-1] isKindOfClass:[PostViewController class]]) {
            PostViewController *activeProfile = self.viewControllers[self.viewControllers.count-1];
            [activeProfile openPostActions];
        }
    }];
    [self.navigationBar addSubview:self.moreButton];
    
    // create new  + button
    self.backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.backButton setImage:[[UIImage imageNamed:@"leftArrowIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.backButton.tintColor = [UIColor whiteColor];
    self.backButton.frame = CGRectMake(10, 0, 44, 44);
    self.backButton.center = CGPointMake(self.backButton.center.x, self.navigationBar.frame.size.height / 2);
    [self.backButton bk_whenTapped:^{
        if (self.isCreatingPost || self.searchResultsTableView.alpha != 1 || self.searchResultsTableView.isHidden) {
            if (self.viewControllers.count == 1) {
                // VC is the top most view controller
                [self.view endEditing:YES];
                
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            else{
                if ([self.viewControllers[self.viewControllers.count-2] isKindOfClass:[RoomViewController class]]) {
                    RoomViewController *previousRoom = self.viewControllers[self.viewControllers.count-2];
                    [self updateBarColor:previousRoom.theme withAnimation:3 statusBarUpdateDelay:NO];
                    [self updateSearchText:previousRoom.title];
                }
                else if ([self.viewControllers[self.viewControllers.count-2] isKindOfClass:[HomeViewController class]]) {
                    [self updateBarColor:[UIColor whiteColor] withAnimation:3 statusBarUpdateDelay:NO];
                    [self updateSearchText:@""];
                }
                else if ([self.viewControllers[self.viewControllers.count-2] isKindOfClass:[ProfileViewController class]]) {
                    ProfileViewController *previousProfile = self.viewControllers[self.viewControllers.count-2];
                    [self updateBarColor:previousProfile.theme withAnimation:3 statusBarUpdateDelay:NO];
                    [self updateSearchText:previousProfile.title];
                }
                else if ([self.viewControllers[self.viewControllers.count-2] isKindOfClass:[PostViewController class]]) {
                    PostViewController *previousPost = self.viewControllers[self.viewControllers.count-2];
                    [self updateBarColor:previousPost.theme withAnimation:3 statusBarUpdateDelay:NO];

                    self.textField.text = previousPost.title;
                    [self hideSearchIcon];
                }
                else if ([self.viewControllers[self.viewControllers.count-2] isKindOfClass:[RoomMembersViewController class]]) {
                    RoomMembersViewController *previousMembersView = self.viewControllers[self.viewControllers.count-2];
                    [self updateBarColor:previousMembersView.theme withAnimation:3 statusBarUpdateDelay:NO];

                    self.textField.text = previousMembersView.title;
                    [self hideSearchIcon];
                }
                
                [self popViewControllerAnimated:YES];
                
                [self updateNavigationBarItemsWithAnimation:YES];
            }
        }
        else {
            [self.textField resignFirstResponder];
            
            [self updateSearchText:self.topViewController.title];
            
            [self updateNavigationBarItemsWithAnimation:YES];
        }
    }];
    UILongPressGestureRecognizer *longPressToGoHome = [[UILongPressGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        if (state == UIGestureRecognizerStateBegan) {
            [self setEditing:false];
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    [self.backButton addGestureRecognizer:longPressToGoHome];
    
    self.backButton.alpha = 0;
    [self.navigationBar addSubview:self.backButton];
    
    self.navigationItem.backBarButtonItem = nil;
    
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.interactivePopGestureRecognizer.enabled = true;
}
- (void)positionTextFieldSearchIcon {
    NSString *textFieldText = self.textField.text.length > 0 ? self.textField.text : self.textField.placeholder;
    
    NSLog(@"textFieldText: %@", textFieldText);
    
    CGRect rect = [textFieldText boundingRectWithSize:CGSizeMake(self.textField.frame.size.width - 16 - 16 - 26, 72) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.textField.font} context:nil];
    CGFloat textWidth = roundf(rect.size.width);
    NSLog(@"textWidth: %f", textWidth);
    
    CGFloat xFinal = 16;
    CGFloat xCentered = self.textField.frame.size.width / 2 - (textWidth / 2) - 10;
    if (!self.textField.isFirstResponder && xCentered > xFinal) {
        xFinal = xCentered;
    }
    
    UIImageView *searchIcon = [self.textField viewWithTag:3];
    CGRect searchIconFrame = searchIcon.frame;
    searchIconFrame.origin.x = xFinal;
    searchIcon.frame = searchIconFrame;
}
- (void)hideSearchIcon {
    UIImageView *searchIcon = [self.textField viewWithTag:3];
    searchIcon.hidden = true;
    
    UIView *leftPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 1)];
    self.textField.leftView = leftPaddingView;
}
- (void)showSearchIcon {
    UIImageView *searchIcon = [self.textField viewWithTag:3];
    searchIcon.hidden = false;
    
    UIView *leftPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16 + 26, 1)];
    self.textField.leftView = leftPaddingView;
}
- (void)updateSearchText:(NSString *)newSearchText {
    [self showSearchIcon];
    
    self.textField.text = newSearchText;
    [self positionTextFieldSearchIcon];
}
- (void)updateNavigationBarItemsWithAnimation:(BOOL)animated {
    [UIView animateWithDuration:animated?0.25f:0 delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (self.textField.isFirstResponder) {
            self.backButton.transform = CGAffineTransformMakeRotation(0);
            self.backButton.alpha = 1;
            self.profilePicture.alpha = 0;
            self.composePostButton.alpha = 0;
            self.moreButton.alpha = 0;
        }
        else {
            // determine items based on active view controller
            if ([self.topViewController isKindOfClass:[HomeViewController class]]) {
                self.backButton.transform = CGAffineTransformMakeRotation(-1 * (M_PI / 2));
                self.backButton.alpha = 0;
                self.profilePicture.alpha = 1;
                
                self.infoButton.alpha = 0;
                self.moreButton.alpha = 0;
                self.composePostButton.alpha = 1;
            }
            else {
                self.profilePicture.alpha = 0;
                self.backButton.alpha = 1;

                if (self.viewControllers.count == 1) {
                    self.backButton.transform = CGAffineTransformMakeRotation(-1 * (M_PI / 2));
                }
                else {
                    self.backButton.transform = CGAffineTransformMakeRotation(0);
                }
            }
            
            if ([self.topViewController isKindOfClass:[PostViewController class]] ||
                [self.topViewController isKindOfClass:[RoomMembersViewController class]]) {
                self.textField.userInteractionEnabled = false;
                self.textField.backgroundColor = [UIColor clearColor];
            }
            else {
                self.textField.userInteractionEnabled = true;
            }
            
            if ([self.topViewController isKindOfClass:[RoomViewController class]]) {
                // left side
                
                // right side
                self.composePostButton.alpha = 0;
                self.infoButton.alpha = 0;
                if (self.isCreatingPost) {
                    self.moreButton.alpha = 0;
                }
                else {
                    self.moreButton.alpha = 1;
                }
            }
            else if ([self.topViewController isKindOfClass:[PostViewController class]]) {
                // left side
                
                // right side
                self.infoButton.alpha = 0;
                self.moreButton.alpha = 1;
                self.composePostButton.alpha = 0;
            }
            else if ([self.topViewController isKindOfClass:[RoomMembersViewController class]]) {
                // left side
                
                // right side
                self.infoButton.alpha = 0;
                self.moreButton.alpha = 0;
                self.composePostButton.alpha = 0;
            }
            else if ([self.topViewController isKindOfClass:[ProfileViewController class]]) {
                // left side
                
                // right side
                self.infoButton.alpha = 0;
                self.moreButton.alpha = 1;
                self.composePostButton.alpha = 0;
            }
        }
    } completion:^(BOOL finished) {
    }];
}

- (void)removeGestureRecognizersForView:(UIView *)view {
    for (UIGestureRecognizer *recognizer in view.gestureRecognizers) {
        [view removeGestureRecognizer:recognizer];
    }
}

- (void)setupSearch {
    [self emptySearchResults];
    [self initRecentSearchResults];
    
    self.searchResultsTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.searchResultsTableView.delegate = self;
    self.searchResultsTableView.dataSource = self;
    self.searchResultsTableView.backgroundColor = [UIColor whiteColor];
    self.searchResultsTableView.contentInset = UIEdgeInsetsMake(self.navigationBar.frame.origin.y + self.navigationBar.frame.size.height, 0, 0, 0);
    self.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.searchResultsTableView.separatorInset = UIEdgeInsetsMake(0, self.view.frame.size.width, 0, 0);
    self.searchResultsTableView.separatorColor = [UIColor colorWithWhite:0.85 alpha:1];
    self.searchResultsTableView.transform = CGAffineTransformMakeScale(0.9, 0.9);
    self.searchResultsTableView.alpha = 0;
    self.searchResultsTableView.hidden = true;
    [self.searchResultsTableView registerClass:[SearchResultCell class] forCellReuseIdentifier:reuseIdentifier];
    [self.view insertSubview:self.searchResultsTableView belowSubview:self.navigationBar];
}


- (void)emptySearchResults {
    NSLog(@"emptySearchResults");
    
    self.searchResults = [[NSMutableDictionary alloc] initWithDictionary:@{@"rooms": @[], @"users": @[]}];
}
- (void)initRecentSearchResults {
    self.recentSearchResults = [[NSMutableArray alloc] init];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults arrayForKey:@"recents_search"]) {
        NSArray *searchRecents = [defaults arrayForKey:@"recents_search"];
        
        if (searchRecents.count > 0) {
            self.recentSearchResults = [[NSMutableArray alloc] initWithArray:searchRecents];
            
            return;
        }
    }
    
    if (self.recentSearchResults.count == 0) {
        // use recently opened instead
        NSArray *openedRecents = [defaults arrayForKey:@"recents_opened"];
        self.recentSearchResults = [[NSMutableArray alloc] initWithArray:openedRecents];
    }
}
- (NSString *)convertToString:(id)object {
    return [NSString stringWithFormat:@"%@", object];
}
- (void)addToRecents:(NSDictionary *)json {
    NSMutableArray *searchRecents = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"recents_search"]];
    
    // add object or push to front if in recents
    BOOL existingMatch = false;
    for (NSInteger i = 0; i < [searchRecents count]; i++) {
        NSDictionary *result = searchRecents[i];
        if (json[@"type"] && json[@"id"] &&
            result[@"type"] && result[@"id"]) {
            if ([json[@"type"] isEqualToString:result[@"type"]] && [[self convertToString:json[@"id"]] isEqualToString:[self convertToString:result[@"id"]]]) {
                existingMatch = true;
                
                [searchRecents removeObjectAtIndex:i];
                [searchRecents insertObject:result atIndex:0];
                break;
            }
        }
    }
    if (!existingMatch) {
        [searchRecents insertObject:json atIndex:0];

        if (searchRecents.count > 8) {
            searchRecents = [[NSMutableArray alloc] initWithArray:[searchRecents subarrayWithRange:NSMakeRange(0, 8)]];
        }
    }
    
    // update NSUserDefaults
    [[NSUserDefaults standardUserDefaults] setObject:[searchRecents clean] forKey:@"recents_search"];
    [self initRecentSearchResults];
    [self.searchResultsTableView reloadData];
}
- (void)addToRecentlyOpened:(NSDictionary *)json {
    NSMutableArray *openedRecents = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"recents_opened"]];
    
    // add object or push to front if in recents
    BOOL existingMatch = false;
    for (NSInteger i = 0; i < [openedRecents count]; i++) {
        NSDictionary *result = openedRecents[i];
        if (json[@"type"] && json[@"id"] &&
            result[@"type"] && result[@"id"]) {
            if ([json[@"type"] isEqualToString:result[@"type"]] && [[self convertToString:json[@"id"]] isEqualToString:[self convertToString:result[@"id"]]]) {
                existingMatch = true;
                
                [openedRecents removeObjectAtIndex:i];
                [openedRecents insertObject:result atIndex:0];
                break;
            }
        }
    }
    if (!existingMatch) {
        [openedRecents insertObject:json atIndex:0];
        
        if (openedRecents.count > 8) {
            openedRecents = [[NSMutableArray alloc] initWithArray:[openedRecents subarrayWithRange:NSMakeRange(0, 8)]];
        }
    }
    
    // update NSUserDefaults
    [[NSUserDefaults standardUserDefaults] setObject:[openedRecents clean] forKey:@"recents_opened"];
    [self initRecentSearchResults];
    [self.searchResultsTableView reloadData];
}

- (void)getSearchResults {
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            NSString *url = [NSString stringWithFormat:@"%@/%@/search", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
            [self.manager GET:url parameters:@{@"q": self.textField.text} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSDictionary *responseData = (NSDictionary *)responseObject[@"data"];
                
                self.searchResults = [[NSMutableDictionary alloc] initWithDictionary:responseData];
                
                [self.searchResultsTableView reloadData];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"FeedViewController / getPosts() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                [self.searchResultsTableView reloadData];
            }];
        }
    }];
    [self.searchResultsTableView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[SearchResultCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    }

    BOOL highlighted = false;
    if ([self showRecents] && indexPath.section == 0 && indexPath.row == 0) {
        highlighted = true;
    }
    else {
        BOOL roomsResults = self.searchResults && self.searchResults[@"results"] &&
                            self.searchResults[@"results"][@"rooms"] && [self.searchResults[@"results"][@"rooms"] count] > 0;
        BOOL userResults = self.searchResults && self.searchResults[@"results"] &&
                            self.searchResults[@"results"][@"users"] && [self.searchResults[@"results"][@"users"] count] > 0;

        if (roomsResults && indexPath.section == 1 && indexPath.row == 0) {
            // has at least one room
            highlighted = true;
        }
        else if (!roomsResults && userResults && indexPath.section == 2 && indexPath.row == 0) {
            highlighted = true;
        }
    }

    if (highlighted) {
        cell.selectionBackground.hidden = false;
        cell.lineSeparator.hidden = true;
    }
    else {
        cell.selectionBackground.hidden = true;
        cell.lineSeparator.hidden = false;
    }
    
    // -- Type --
    int type = 0;
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            if ([self.topViewController isKindOfClass:[HomeViewController class]]) {
                type = 0;
                cell.textLabel.text = @"Home";
            }
            else if ([self.topViewController isKindOfClass:[RoomViewController class]]) {
                type = 1;
            }
            else if ([self.topViewController isKindOfClass:[ProfileViewController class]]) {
                type = 2;
            }
        }
        else {
            type = 0;
            cell.textLabel.text = @"Home";
        }
        
        
        if (type == 0) {
            // 0 = page inside Home (e.g. Timeline, My Rooms, Trending)
            cell.imageView.image = [UIImage imageNamed:@"searchHomeIcon"];
        }
        else if (type == 1) {
            RoomViewController *currentRoomVC = (RoomViewController *)self.topViewController;
            Room *room = currentRoomVC.room;
            
            // 1 = Room
            if (room.identifier) {
                cell.textLabel.alpha = 1;
                
                cell.textLabel.text = room.attributes.details.title;
                NSString *roomColor = room.attributes.details.color;
                cell.imageView.backgroundColor = [self colorFromHexString:roomColor?roomColor:@"0076ff"];
                
                BOOL useLiveCount = room.attributes.summaries.counts.live > [Session sharedInstance].defaults.room.liveThreshold;
                if (useLiveCount) {
                    cell.detailTextLabel.textColor = [UIColor colorWithDisplayP3Red:0.87 green:0.09 blue:0.09 alpha:1];
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%li LIVE", (long)room.attributes.summaries.counts.live];
                }
                else {
                    cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld %@", (long)room.attributes.summaries.counts.members, (room.attributes.summaries.counts.members == 1 ? @"MEMBER" : @"MEMBERS")];
                }
            }
            else {
                cell.textLabel.alpha = 0.5;
                
                cell.textLabel.text = @"Unkown Room";
                cell.imageView.backgroundColor = [self colorFromHexString:@"707479"];
                
                cell.detailTextLabel.text = @"";
            }
        }
        else {
            ProfileViewController *currentUserVC = (ProfileViewController *)self.topViewController;
            User *user = currentUserVC.user;
            
            // 2 = User
            if (user.identifier) {
                cell.textLabel.alpha = 1;
                
                cell.textLabel.text = user.attributes.details.displayName;
                cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@", [user.attributes.details.identifier uppercaseString]];
                
                if (user.attributes.details.media.profilePicture && user.attributes.details.media.profilePicture.length > 0) {
                    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:user.attributes.details.media.profilePicture] placeholderImage:[[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
                }
                else {
                    cell.imageView.image = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                }
                
                NSString *userColor = user.attributes.details.color;
                cell.imageView.tintColor = userColor ? [[userColor lowercaseString] isEqualToString:@"ffffff"] ? [UIColor colorWithWhite:0.2f alpha:1] : [self colorFromHexString:userColor] : [self colorFromHexString:@"707479"];
                cell.imageView.backgroundColor = [UIColor whiteColor];
            }
            else {
                cell.textLabel.alpha = 0.5;
                
                cell.textLabel.text = @"Unkown User";
                cell.imageView.backgroundColor = [self colorFromHexString:@"707479"];
                
                cell.detailTextLabel.text = @"";
            }
        }
    }
    else {
        NSDictionary *json;
        if (indexPath.section == 1) {
            type = 1;
            json = self.searchResults[@"results"][@"rooms"][indexPath.row];
        }
        else if (indexPath.section == 2) {
            type = 2;
            json = self.searchResults[@"results"][@"users"][indexPath.row];
        }
        else if (indexPath.section == 3) {
            // mix of types
            json = self.recentSearchResults[indexPath.row];
            if (json[@"type"]) {
                if ([json[@"type"] isEqualToString:@"room"]) {
                    type = 1;
                }
                else if ([json[@"type"] isEqualToString:@"user"]) {
                    type = 2;
                }
            }
        }
        
        if (type == 0) {
            // 0 = page inside Home (e.g. Timeline, My Rooms, Trending)
            cell.textLabel.text = @"Page";
            cell.imageView.image = [UIImage new];
            cell.imageView.backgroundColor = [UIColor blueColor];
        }
        else if (type == 1) {
            NSError *error;
            Room *room = [[Room alloc] initWithDictionary:json error:&error];
            if (error) { NSLog(@"room error: %@", error); };
            
            // 1 = Room
            cell.textLabel.text = room.attributes.details.title;
            cell.imageView.backgroundColor = [self colorFromHexString:room.attributes.details.color];
                        
            BOOL useLiveCount = room.attributes.summaries.counts.live > [Session sharedInstance].defaults.room.liveThreshold;
            if (useLiveCount) {
                cell.detailTextLabel.textColor = [UIColor colorWithDisplayP3Red:0.87 green:0.09 blue:0.09 alpha:1];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%li LIVE", (long)room.attributes.summaries.counts.live];
            }
            else {
                cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld %@", (long)room.attributes.summaries.counts.members, (room.attributes.summaries.counts.members == 1 ? @"MEMBER" : @"MEMBERS")];
            }
        }
        else {
            NSError *error;
            User *user = [[User alloc] initWithDictionary:json error:&error];
            
            NSLog(@"user:::::: %@", user);
            
            // 2 = User
            cell.textLabel.text = user.attributes.details.displayName;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@", [user.attributes.details.identifier uppercaseString]];
            if (user.attributes.details.media.profilePicture != nil && user.attributes.details.media.profilePicture.length > 0) {
                [cell.imageView sd_setImageWithURL:[NSURL URLWithString:user.attributes.details.media.profilePicture] placeholderImage:[[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] options:SDWebImageRefreshCached];
            }
            else {
                cell.imageView.image = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
            
            // 2 = User
            cell.imageView.tintColor = [[user.attributes.details.color lowercaseString] isEqualToString:@"ffffff"] ? [UIColor colorWithWhite:0.2f alpha:1] : [self colorFromHexString:user.attributes.details.color];
            cell.imageView.backgroundColor = [UIColor whiteColor];
        }
    }
    
    if (type == 0) {
        // 0 = page inside Home (e.g. Timeline, My Rooms, Trending)
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
        cell.detailTextLabel.text = @"";
    }
    else if (type == 1) {
        // 1 = Room
    }
    else if (type == 2) {
        // 2 = Usercell.detailTextLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
    }
    
    cell.type = type;
    
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if ([self.topViewController isKindOfClass:[HomeViewController class]]) {
            [self updateSearchText:@""];
        }
        else {
            if (indexPath.row == 0) {
                [self updateSearchText:self.topViewController.title];
            }
            else {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }
    }
    else if (indexPath.section == 1) {
        NSDictionary *roomJSON = self.searchResults[@"results"][@"rooms"][indexPath.row];
        Room *room = [[Room alloc] initWithDictionary:roomJSON error:nil];
        
        [self addToRecents:roomJSON];
        
        [self openRoom:room];
    }
    else if (indexPath.section == 2) {
        NSDictionary *userJSON = self.searchResults[@"results"][@"users"][indexPath.row];
        User *user = [[User alloc] initWithDictionary:userJSON error:nil];
        
        [self addToRecents:userJSON];
        
        [self openProfile:user];
    }
    else if (indexPath.section == 3) {
        NSDictionary *json = self.recentSearchResults[indexPath.row];
        if ([json objectForKey:@"type"]) {
            if ([json[@"type"] isEqualToString:@"user"]) {
                User *user = [[User alloc] initWithDictionary:json error:nil];
                
                [self addToRecents:json];
                
                [self openProfile:user];
            }
            else if ([json[@"type"] isEqualToString:@"room"]) {
                Room *room = [[Room alloc] initWithDictionary:json error:nil];
                
                [self addToRecents:json];
                
                [self openRoom:room];
            }
        }
    }
    
    [self emptySearchResults];
    [self.searchResultsTableView reloadData];
    [self.textField resignFirstResponder];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.isCreatingPost && section == 0 && ([self showRecents])) {
        if ([self.topViewController isKindOfClass:[HomeViewController class]]) {
            return 1;
        }
        else {
            return 2;
        }
    }
    else {
        if ([self showRecents]) {
            NSLog(@"show recentsssss");
            if (self.recentSearchResults && section == 3) {
                return [self.recentSearchResults count];
            }
        }
        else {
            if (section == 1) {
                // rooms
                if (self.searchResults && self.searchResults[@"results"] && self.searchResults[@"results"][@"rooms"]) {
                    NSLog(@"how many rooms we got?? %lu", [self.searchResults[@"results"][@"rooms"] count]);
                    return [self.searchResults[@"results"][@"rooms"] count];
                }
            }
            else if (section == 2) {
                // users
                if (self.searchResults && self.searchResults[@"results"] && self.searchResults[@"results"][@"users"]) {
                    return [self.searchResults[@"results"][@"users"] count];
                }
            }
        }
    }
    
    return 0;
}

- (BOOL)showRecents  {    
    BOOL showRecents = self.textField.text.length == 0 ||
                        ([self.textField.text isEqualToString:self.topViewController.title] &&
                         [self.searchResults[@"results"][@"rooms"] count] == 0 &&
                         [self.searchResults[@"results"][@"users"] count] == 0);
    
    return showRecents;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat headerHeight = 50;
    if ([self showRecents]) {
        if (section == 0) {
            return 16;
        }
        else if (section == 3) {
            return headerHeight;
        }
    }
    else {
        if (section == 0 &&
            self.searchResults &&
            [self.searchResults objectForKey:@"results"] && [[self.searchResults objectForKey:@"results"] objectForKey:@"rooms"] && [self.searchResults[@"results"][@"rooms"] count] == 0 &&
            [self.searchResults objectForKey:@"results"] && [[self.searchResults objectForKey:@"results"] objectForKey:@"rooms"] && [self.searchResults[@"results"][@"users"] count] == 0) {
            return headerHeight;
        }
        else if (section == 1 && self.searchResults && [self.searchResults objectForKey:@"results"] && [[self.searchResults objectForKey:@"results"] objectForKey:@"rooms"] && [self.searchResults[@"results"][@"rooms"] count] > 0) {
            return headerHeight;
        }
        else if (section == 2 && self.searchResults && [self.searchResults objectForKey:@"results"] && [[self.searchResults objectForKey:@"results"] objectForKey:@"users"] && [self.searchResults[@"results"][@"users"] count] > 0) {
            return headerHeight;
        }
    }
    
    return 0;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 24, self.view.frame.size.width - 32, 19)];
    title.textAlignment = NSTextAlignmentLeft;
    
    if ([self showRecents]) {
        if (section == 0) { return nil; }
        
        title.text = self.recentSearchResults.count == 0 ? @"" : @"Recents";
    }
    else {
        if ((section == 1 && self.searchResults && [self.searchResults objectForKey:@"results"] && [[self.searchResults objectForKey:@"results"] objectForKey:@"rooms"] && [self.searchResults[@"results"][@"rooms"] count] > 0) ||
            (section == 2 && self.searchResults && [self.searchResults objectForKey:@"results"] && [[self.searchResults objectForKey:@"results"] objectForKey:@"users"] && [self.searchResults[@"results"][@"users"] count] > 0)) {
            if (section == 1) {
                title.text = @"Rooms";
            }
            else if (section == 2) {
                title.text = @"Users";
            }
        }
        else {
            if (section == 0) {
                title.text = @"No Results";
                title.textAlignment = NSTextAlignmentCenter;
            }
            else {
                return nil;
            }
        }
    }
    
    title.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold];
    title.textColor = [UIColor colorWithWhite:0.6f alpha:1];
    
    [header addSubview:title];
    
    return header;
    
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // left aligned search bar
    self.textField.textAlignment = NSTextAlignmentLeft;
    [self positionTextFieldSearchIcon];
    
    if (!self.isCreatingPost && (self.searchResultsTableView.alpha != 1 || self.searchResultsTableView.isHidden)) {
        self.searchResultsTableView.hidden = false;
        self.searchResultsTableView.transform = CGAffineTransformMakeScale(0.9, 0.9);
        self.searchResultsTableView.alpha = 0;
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.searchResultsTableView.transform = CGAffineTransformMakeScale(1, 1);
            self.searchResultsTableView.alpha = 1;
        } completion:^(BOOL finished) {
        }];
    }
    else if (self.isCreatingPost) {
        // reset the right view
        // remove set room -> back to "Search rooms"
        UIView *rightPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 1)];
        self.textField.rightView = rightPaddingView;
        
        [self showSearchIcon];
        
        if (self.textField.text.length > 4 && [[self.textField.text substringWithRange:NSMakeRange(0, 4)] isEqualToString:@"To: "]) {
            self.textField.text = [self.textField.text substringWithRange:NSMakeRange(4, self.textField.text.length-4)];
        }
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (self.isCreatingPost) {
        if (self.textField.text.length > 0) {
            self.textField.textAlignment = NSTextAlignmentLeft;
            [self hideSearchIcon];
        }
        else {
            self.textField.textAlignment = NSTextAlignmentCenter;
            [self showSearchIcon];
            [self positionTextFieldSearchIcon];
        }
    }
    else {
        // left aligned search bar
        self.textField.textAlignment = NSTextAlignmentCenter;
        [self positionTextFieldSearchIcon];
        
        if ([self.topViewController isKindOfClass:[RoomViewController class]]) {
            RoomViewController *currentRoom = (RoomViewController *)self.topViewController;
            [self updateBarColor:currentRoom.theme withAnimation:1 statusBarUpdateDelay:NO];
        }
        if ([self.topViewController isKindOfClass:[ProfileViewController class]]) {
            ProfileViewController *currentProfile = (ProfileViewController *)self.topViewController;
            [self updateBarColor:currentProfile.theme withAnimation:1 statusBarUpdateDelay:NO];
        }
        if ([self.topViewController isKindOfClass:[HomeViewController class]]) {
            HomeViewController *currentRoom = (HomeViewController *)self.topViewController;
            if (currentRoom.page == 1) {
                [self setShadowVisibility:false withAnimation:true];
            }
        }
        [self updateNavigationBarItemsWithAnimation:YES];
        
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.searchResultsTableView.alpha = 0;
        } completion:^(BOOL finished) {
            self.searchResultsTableView.hidden = true;
        }];
        
        [self.searchResultsTableView reloadData];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([self showRecents]) {
        [self tableView:self.searchResultsTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
    else {
        if (self.searchResults && [self.searchResults objectForKey:@"results"] && [[self.searchResults objectForKey:@"results"] objectForKey:@"rooms"] && [self.searchResults[@"results"][@"rooms"] count] > 0) {
            // has at least one room
            [self tableView:self.searchResultsTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
        }
        else if (self.searchResults && [self.searchResults objectForKey:@"results"] && [[self.searchResults objectForKey:@"results"] objectForKey:@"users"] && [self.searchResults[@"results"][@"users"] count] > 0) {
            [self tableView:self.searchResultsTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
        }
    }
    
    return FALSE;
}

- (void)openRoom:(Room *)room {
    RoomViewController *r = [[RoomViewController alloc] init];

    r.room = room;
    r.theme = [self colorFromHexString:room.attributes.details.color.length == 6 ? room.attributes.details.color : (room.identifier ? @"0076ff" : @"707479")];
    
    r.tableView.delegate = self;
    
    if ([self.topViewController isKindOfClass:[HomeViewController class]]) {
        [self updateSearchText:self.topViewController.title];
        
        LauncherNavigationViewController *newLauncher = [[LauncherNavigationViewController alloc] initWithRootViewController:r];
        [newLauncher updateSearchText:r.room.attributes.details.title];
        newLauncher.transitioningDelegate = self;
        
        [newLauncher updateBarColor:r.theme withAnimation:0 statusBarUpdateDelay:NO];
        
        [self presentViewController:newLauncher animated:YES completion:nil];
        
        [newLauncher updateNavigationBarItemsWithAnimation:NO];
    }
    else {
        if (r.room.identifier) {
            [self updateSearchText:r.room.attributes.details.title];
        }
        else {
            [self updateSearchText:@""];
        }
        
        [self updateBarColor:r.theme withAnimation:2 statusBarUpdateDelay:NO];
        
        [self pushViewController:r animated:YES];
        
        [self updateNavigationBarItemsWithAnimation:YES];;
    }
    
    [self addToRecentlyOpened:[room toDictionary]];
}
- (void)openRoomMembersForRoom:(Room *)room {
    RoomMembersViewController *rm = [[RoomMembersViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    rm.room = room;
    rm.theme = [self colorFromHexString:room.attributes.details.color.length == 6 ? room.attributes.details.color : @"0076ff"];
    
    rm.title = @"Members";
    
    if ([self.topViewController isKindOfClass:[HomeViewController class]]) {
        [self updateSearchText:self.topViewController.title];
        
        LauncherNavigationViewController *newLauncher = [[LauncherNavigationViewController alloc] initWithRootViewController:rm];
        newLauncher.textField.text = rm.title;
        [newLauncher hideSearchIcon];
        newLauncher.transitioningDelegate = self;
        
        [newLauncher updateBarColor:rm.theme withAnimation:0 statusBarUpdateDelay:NO];
        
        [self presentViewController:newLauncher animated:YES completion:nil];
        
        [newLauncher updateNavigationBarItemsWithAnimation:NO];
    }
    else {
        self.textField.text = rm.title;
        [self hideSearchIcon];
        
        [self updateBarColor:rm.theme withAnimation:2 statusBarUpdateDelay:NO];
        
        [self pushViewController:rm animated:YES];
        
        [self updateNavigationBarItemsWithAnimation:YES];;
    }
}
- (void)openProfile:(User *)user {
    ProfileViewController *p = [[ProfileViewController alloc] init];
    
    p.theme = [self colorFromHexString:user.attributes.details.color.length == 6 ? user.attributes.details.color : (user.identifier ? @"0076ff" : @"707479")]; //[self colorFromHexString:user.attributes.details.color];

    p.user = user;
    
    if ([self.topViewController isKindOfClass:[HomeViewController class]]) {
        self.textField.text = self.topViewController.title;
        
        LauncherNavigationViewController *newLauncher = [[LauncherNavigationViewController alloc] initWithRootViewController:p];
        [newLauncher updateSearchText:p.user.attributes.details.displayName];
        newLauncher.transitioningDelegate = self;
        
        [newLauncher updateBarColor:p.theme withAnimation:0 statusBarUpdateDelay:NO];
        
        [self presentViewController:newLauncher animated:YES completion:nil];
        
        [newLauncher updateNavigationBarItemsWithAnimation:NO];
    }
    else {
        [self updateSearchText:p.user.attributes.details.displayName];
        
        [self updateBarColor:p.theme withAnimation:2 statusBarUpdateDelay:NO];
        
        [self pushViewController:p animated:YES];
        
        [self updateNavigationBarItemsWithAnimation:YES];
    }
}
- (void)openPost:(Post *)post {
    PostViewController *p = [[PostViewController alloc] init];
    
    p.post = post;
    p.theme = [self colorFromHexString:post.attributes.status.postedIn.attributes.details.color];
    p.title = @"Conversation";
    
    if ([self.topViewController isKindOfClass:[HomeViewController class]]) {
        [self updateSearchText:self.topViewController.title];
        
        LauncherNavigationViewController *newLauncher = [[LauncherNavigationViewController alloc] initWithRootViewController:p];
        newLauncher.textField.text = p.title;
        [newLauncher hideSearchIcon];
        newLauncher.transitioningDelegate = self;
        
        [newLauncher updateBarColor:p.theme withAnimation:0 statusBarUpdateDelay:NO];
        
        [self presentViewController:newLauncher animated:YES completion:nil];
        
        [newLauncher updateNavigationBarItemsWithAnimation:NO];
    }
    else {
        self.textField.text = p.title;
        [self hideSearchIcon];
        
        [self updateBarColor:p.theme withAnimation:2 statusBarUpdateDelay:NO];
        
        [self pushViewController:p animated:YES];
        
        [self updateNavigationBarItemsWithAnimation:YES];
    }
}
- (void)openCreateRoom {
    CreateRoomViewController *c = [[CreateRoomViewController alloc] init];
    c.transitioningDelegate = self;
    [self presentViewController:c animated:YES completion:nil];
}
- (void)openOnboarding {
    OnboardingViewController *o = [[OnboardingViewController alloc] init];
    o.transitioningDelegate = self;
    [self presentViewController:o animated:YES completion:nil];
}
    
- (void)openComposePost {
    RoomViewController *r = [[RoomViewController alloc] init];
    
    r.room = nil;
    r.theme = [Session sharedInstance].themeColor;
    r.isCreatingPost = true;
    
    r.tableView.delegate = self;
    
    self.textField.text = self.topViewController.title;
    
    LauncherNavigationViewController *newLauncher = [[LauncherNavigationViewController alloc] initWithRootViewController:r];
    newLauncher.textField.text = @"";
    newLauncher.textField.placeholder = @"Search Rooms...";
    newLauncher.isCreatingPost = true;
    newLauncher.transitioningDelegate = self;
    [newLauncher positionTextFieldSearchIcon];
    
    [newLauncher updateBarColor:[UIColor whiteColor] withAnimation:0 statusBarUpdateDelay:NO];
    
    [self presentViewController:newLauncher animated:YES completion:nil];
    
    [newLauncher updateNavigationBarItemsWithAnimation:NO];
}
- (void)openEditProfile {
    EditProfileViewController *epvc = [[EditProfileViewController alloc] initWithStyle:UITableViewStyleGrouped];
    epvc.view.tintColor = [Session sharedInstance].themeColor;
    
    UINavigationController *newNavController = [[UINavigationController alloc] initWithRootViewController:epvc];
    newNavController.transitioningDelegate = self;
    newNavController.navigationBar.barStyle = UIBarStyleBlack;
    newNavController.navigationBar.translucent = false;
    newNavController.navigationBar.barTintColor = [UIColor whiteColor];
    [newNavController setNeedsStatusBarAppearanceUpdate];
    
    [self presentViewController:newNavController animated:YES completion:nil];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    _currentKeyboardHeight = keyboardFrameBeginRect.size.height;
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    self.searchResultsTableView.contentInset = UIEdgeInsetsMake(self.searchResultsTableView.contentInset.top, 0, _currentKeyboardHeight - bottomPadding + 24, 0);
    self.searchResultsTableView.scrollIndicatorInsets = UIEdgeInsetsMake(self.searchResultsTableView.contentInset.top, 0, _currentKeyboardHeight - bottomPadding, 0);
}

- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        self.searchResultsTableView.contentInset = UIEdgeInsetsMake(self.searchResultsTableView.contentInset.top, 0, 0, 0);
        self.searchResultsTableView.scrollIndicatorInsets = self.searchResultsTableView.contentInset;
    } completion:nil];
}
    

#pragma mark - UIViewControllerTransitioningDelegate

// MODAL TRANSITION
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source
{
    id<UIViewControllerAnimatedTransitioning> animationController;
    
    SOLOptionsTransitionAnimator *animator = [[SOLOptionsTransitionAnimator alloc] init];
    animator.appearing = YES;
    animator.duration = 0.3;
    animationController = animator;
    
    return animationController;
}
/*
 Called when dismissing a view controller that has a transitioningDelegate
 */
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    id<UIViewControllerAnimatedTransitioning> animationController;
    
    SOLOptionsTransitionAnimator *animator = [[SOLOptionsTransitionAnimator alloc] init];
    animator.appearing = NO;
    animator.duration = 0.3;
    animationController = animator;
    
    return animationController;
}

// PUSH TRANSITION
- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController*)fromVC
                                                 toViewController:(UIViewController*)toVC
{
    if (operation == UINavigationControllerOperationPush) {
        if ([fromVC isKindOfClass:[HomeViewController class]]) {
            // hide:
            // 1) profile picture
            // 2) plus icon
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.composePostButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
                self.composePostButton.alpha = 0;
                
                self.profilePicture.transform = CGAffineTransformMakeScale(0.1, 0.1);
                self.profilePicture.alpha = 0;
            } completion:^(BOOL finished) {
            }];
        }
        if ([toVC isKindOfClass:[RoomViewController class]]) {
            self.infoButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
            self.backButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.infoButton.alpha = 1;
                self.infoButton.transform = CGAffineTransformIdentity;
                
                self.backButton.alpha = 1;
                self.backButton.transform = CGAffineTransformIdentity;
                
                self.textField.textColor = [UIColor whiteColor];
                self.textField.backgroundColor = [UIColor colorWithWhite:1 alpha:0.16f];
            } completion:^(BOOL finished) {
            }];
        }
        
        return [[PushAnimator alloc] init];
    }
    
    if (operation == UINavigationControllerOperationPop) {
        if ([fromVC isKindOfClass:[RoomViewController class]]) {
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.infoButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
                self.backButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
                
                self.infoButton.alpha = 0;
                self.backButton.alpha = 0;
            } completion:^(BOOL finished) {
            }];
        }
        if ([toVC isKindOfClass:[HomeViewController class]]) {
            self.navigationBar.barStyle = UIBarStyleDefault;
            [self setNeedsStatusBarAppearanceUpdate];
            
            self.infoButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
            self.backButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.navigationBackgroundView.backgroundColor = [UIColor whiteColor];
                // self.textField.text = @"Home";
                self.textField.textColor = [UIColor colorWithWhite:0.06f alpha:1];
                self.textField.backgroundColor = [UIColor colorWithWhite:0 alpha:0.06f];
                
                self.profilePicture.alpha = 1;
                self.profilePicture.transform = CGAffineTransformIdentity;
                
                self.composePostButton.alpha = 1;
                self.composePostButton.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
            }];
        }
        
        return [[PopAnimator alloc] init];
    }
    
    return nil;
}


- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

@end


@implementation PushAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.5f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *fromView = fromVC.view;
    UIView *toView = toVC.view;
    UIView *containerView = [transitionContext containerView];
    containerView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    // Presenting
    [containerView addSubview:toView];
    
    fromView.userInteractionEnabled = NO;
    
    // Round the corners
    fromView.layer.masksToBounds = YES;
    toView.layer.masksToBounds = YES;
    
    CGFloat toViewEndY = toView.frame.origin.y;
    toView.frame = CGRectMake(containerView.frame.size.width, toView.frame.origin.y, toView.frame.size.width, toView.frame.size.height);
    toView.layer.masksToBounds = false;
    
    [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:0.78f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        toView.frame = CGRectMake(toView.frame.origin.x, toViewEndY, toView.frame.size.width, toView.frame.size.height);
        fromView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        fromView.layer.cornerRadius = 12.f;
    } completion:^(BOOL finished) {
        fromView.transform = CGAffineTransformMakeScale(1, 1);
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

@end


@implementation PopAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.5f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *fromView = fromVC.view;
    UIView *toView = toVC.view;
    toView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    UIView *containerView = [transitionContext containerView];
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    [containerView addSubview:toView];
    [containerView bringSubviewToFront:fromView];
    
    [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:0.78f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        fromView.frame = CGRectMake(fromView.frame.origin.x, toVC.navigationController.view.frame.size.height, fromView.frame.size.width, fromView.frame.size.height);
        toView.transform = CGAffineTransformMakeScale(1, 1);
        toView.layer.cornerRadius = 0;
    } completion:^(BOOL finished) {
        [fromView removeFromSuperview];
        toView.userInteractionEnabled = YES;
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

@end
