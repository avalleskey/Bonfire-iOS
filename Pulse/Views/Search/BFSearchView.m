//
//  BFTextField.m
//  Pulse
//
//  Created by Austin Valleskey on 11/30/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "BFSearchView.h"
#import "UIColor+Palette.h"
#import "Session.h"
#import "TabController.h"
#import "Launcher.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "SearchNavigationController.h"
#import "ComplexNavigationController.h"

@implementation BFSearchView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 12.f;
        self.layer.masksToBounds = true;
        
        self.resultsType = BFSearchResultsTypeTop;
        
        self.textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        self.textField.placeholder = @"Camps & People";
        self.textField.textAlignment = NSTextAlignmentLeft;
        self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        self.textField.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightBold];
        self.textField.returnKeyType = UIReturnKeyGo;
        self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.textField.userInteractionEnabled = false;
        self.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [self addSubview:self.textField];
        
        self.searchIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.textField.frame.size.height / 2 - 7, 14, 14)];
        self.searchIcon.image = [[UIImage imageNamed:@"miniSearchIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        self.theme = BFTextFieldThemeAuto;
        self.originalFrame = frame;
        
        [self showSearchIcon:false];
        [self setPosition:BFSearchTextPositionCenter];
        
        [self bk_whenTapped:^{
            if (self.openSearchControllerOntap && ![[Launcher activeViewController] isKindOfClass:[SearchTableViewController class]]) {
                if ([[Launcher activeNavigationController] isKindOfClass:[ComplexNavigationController class]]) {
                    SearchTableViewController *viewController = [[SearchTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
                    viewController.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeNone;
                    viewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                    viewController.resultsType = self.resultsType;
                    
                    ComplexNavigationController *complexController = (ComplexNavigationController *)[Launcher activeNavigationController];
                    [complexController.searchView updateSearchText:@""];
                    [complexController pushViewController:viewController animated:NO];
                    complexController.opaqueOnScroll = true;
                    complexController.transparentOnLoad = false;
                    [complexController updateBarColor:[UIColor contentBackgroundColor] animated:YES];
                    
                    complexController.searchView.textField.userInteractionEnabled = true;
                    [complexController.searchView.textField becomeFirstResponder];
                    [complexController updateNavigationBarItemsWithAnimation:YES];
                }
                if ([[Launcher activeViewController].navigationController.tabBarController isKindOfClass:[TabController class]] &&
                    [((TabController *)[Launcher tabController]).selectedViewController isKindOfClass:[SearchNavigationController class]]) {
                    if (self.textField.text.length == 0) {
                        SearchTableViewController *viewController = [[SearchTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
                        viewController.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeNone;
                        viewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                        viewController.resultsType = self.resultsType;
                                                
                        SearchNavigationController *searchController = ((TabController *)[Launcher tabController]).selectedViewController;
                        searchController.hideCancelOnBlur = true;
                        [searchController pushViewController:viewController animated:NO];
                        
                        searchController.searchView.textField.userInteractionEnabled = true;
                        [searchController.searchView.textField becomeFirstResponder];
                    }
                    else {
                        self.textField.userInteractionEnabled = true;
                        [self.textField becomeFirstResponder];
                    }
                }
            }
            else {
                self.textField.userInteractionEnabled = true;
                [self.textField becomeFirstResponder];
            }
        }];
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.touchDown = YES;
    
    UIColor *textFieldBackgroundColor;
    if (self.theme == BFTextFieldThemeLight) {
        textFieldBackgroundColor = [UIColor bonfireTextFieldBackgroundOnDark];
    }
    else if (self.theme == BFTextFieldThemeDark) {
        textFieldBackgroundColor = [UIColor bonfireTextFieldBackgroundOnWhite];
    }
    else {
        textFieldBackgroundColor = [UIColor bonfireTextFieldBackgroundOnContent];
    }
    
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
    [textFieldBackgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];
    
    [UIView animateWithDuration:0.2f animations:^{
        self.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha*2];
    }];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Triggered when touch is released
    if (self.touchDown) {
        self.touchDown = NO;
        
        [self touchCancel];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Triggered if touch leaves view
    if (self.touchDown) {
        self.touchDown = NO;
        
        [self touchCancel];
    }
}

- (void)touchCancel {
    UIColor *textFieldBackgroundColor;
    if (self.theme == BFTextFieldThemeLight) {
        textFieldBackgroundColor = [UIColor bonfireTextFieldBackgroundOnDark];
    }
    else if (self.theme == BFTextFieldThemeDark) {
        textFieldBackgroundColor = [UIColor bonfireTextFieldBackgroundOnWhite];
    }
    else {
        textFieldBackgroundColor = [UIColor bonfireTextFieldBackgroundOnContent];
    }
    
    [UIView animateWithDuration:0.2f animations:^{
        self.backgroundColor = textFieldBackgroundColor;
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
}
- (void)hideSearchIcon:(BOOL)animated {
    self.searchIcon.hidden = true;
    self.userInteractionEnabled = false;
    
    UIView *leftPaddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)];
    self.textField.leftView = leftPaddingView;
    
    [self updateTextFieldRect];
    
    self.backgroundColor = [UIColor clearColor];
}
- (void)showSearchIcon:(BOOL)animated {
    self.searchIcon.hidden = false;
    self.userInteractionEnabled = true;
    
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14 + 8, self.frame.size.height)];
    self.searchIcon.tintColor = self.textField.textColor;
    [leftView addSubview:self.searchIcon];
    self.textField.leftView = leftView;
    self.textField.leftViewMode = UITextFieldViewModeAlways;
    
    [self updateTextFieldRect];
}
- (void)updateSearchText:(NSString *)newSearchText {
    if (![self.textField.text isEqualToString:newSearchText]) {
        [self showSearchIcon:false];
        
        self.textField.text = newSearchText;
        
        [self updateTextFieldRect];
        
        [self.textField layoutIfNeeded];
    }
}

- (void)setPlaceholder:(NSString *)placeholder {
    if (![self.textField.placeholder isEqualToString:placeholder]) {        
        self.textField.placeholder = placeholder;
        
        [self updateTextFieldRect];
        
        [self.textField layoutIfNeeded];
    }
}

- (void)updateTextFieldRect {
    CGRect textLabelRect = [self textFieldRect];
    
    self.textField.frame = CGRectMake((self.originalFrame.size.width / 2) - ((textLabelRect.size.width + self.textField.leftView.frame.size.width) / 2), self.textField.frame.origin.y, textLabelRect.size.width + self.textField.leftView.frame.size.width, self.textField.frame.size.height);
}

- (void)setPosition:(BFSearchTextPosition)position {
    if (position != _position) {
        _position = position;
        
        if (position == BFSearchTextPositionCenter) {
            // center align
            CGRect textLabelRect = [self textFieldRect];
            
            self.textField.frame = CGRectMake((self.originalFrame.size.width / 2) - ((textLabelRect.size.width + self.textField.leftView.frame.size.width) / 2), self.textField.frame.origin.y, textLabelRect.size.width + self.textField.leftView.frame.size.width, self.textField.frame.size.height);
        }
        else {
            // left align
           self.textField.frame = CGRectMake(16, self.textField.frame.origin.y, self.frame.size.width - 16, self.textField.frame.size.height);
        }
    }
}
- (CGRect)textFieldRect {
    NSString *text = self.textField.text.length > 0 ? self.textField.text : self.textField.placeholder;
    
    CGRect rect = [text boundingRectWithSize:CGSizeMake((self.originalFrame.size.width - 24) - self.textField.leftView.frame.size.width - self.textField.rightView.frame.size.width, self.textField.frame.size.height) options:(NSStringDrawingTruncatesLastVisibleLine) attributes:@{NSFontAttributeName:self.textField.font} context:nil];
    return CGRectMake(self.originalFrame.size.width / 2 - ceilf(rect.size.width) / 2, self.textField.frame.origin.y, ceilf(rect.size.width), self.textField.frame.size.height);
}

- (void)setTheme:(BFTextFieldTheme)theme {
    _theme = theme;
    
    if (theme == BFTextFieldThemeLight) {
        self.backgroundColor = [UIColor bonfireTextFieldBackgroundOnDark];
        
        self.tintColor =
        self.textField.textColor = [UIColor whiteColor];
        self.searchIcon.alpha = 0.75;
    }
    else if (theme == BFTextFieldThemeDark) {
        self.backgroundColor = [UIColor bonfireTextFieldBackgroundOnWhite];
        
        self.tintColor =
        self.textField.textColor = [UIColor blackColor];
        self.searchIcon.alpha = 0.5;
    }
    else {
        // auto
        self.backgroundColor = [UIColor bonfireTextFieldBackgroundOnContent];
        
        self.tintColor =
        self.textField.textColor = [UIColor bonfirePrimaryColor];
        self.searchIcon.alpha = 0.25;
    }
    self.searchIcon.tintColor = self.textField.textColor;
    self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.textField.placeholder attributes:@{NSForegroundColorAttributeName: [self.textField.textColor colorWithAlphaComponent:self.searchIcon.alpha],
                     NSFontAttributeName: self.textField.font}];
}

@end
