//
//  BFTextField.h
//  Pulse
//
//  Created by Austin Valleskey on 11/30/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface BFSearchView : UIView

typedef enum {
    BFTextFieldThemeAuto = 1,
    BFTextFieldThemeLight = 2,
    BFTextFieldThemeDark = 3
} BFTextFieldTheme;

typedef enum {
    BFSearchTextPositionLeft = 0,
    BFSearchTextPositionCenter = 1
} BFSearchTextPosition;

@property (nonatomic, strong) UIImageView *searchIcon;
@property (nonatomic, strong) NSString *placeholder;
@property (nonatomic) BFTextFieldTheme theme;
@property (nonatomic) BFSearchTextPosition position;
@property (nonatomic) UITextField *textField;
@property (nonatomic) CGRect originalFrame;
@property (nonatomic) BOOL openSearchControllerOntap;
@property (nonatomic) BFSearchResultsType resultsType;

- (void)hideSearchIcon:(BOOL)animated;
- (void)showSearchIcon:(BOOL)animated;
- (void)updateSearchText:(NSString *)newSearchText;

@property (nonatomic) BOOL touchDown;

@end

NS_ASSUME_NONNULL_END
