//
//  SearchTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 11/30/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "SearchTableViewController.h"
#import "Session.h"
#import "HAWebService.h"
#import "SearchResultCell.h"
#import "ButtonCell.h"
#import "NSDictionary+Clean.h"
#import "NSArray+Clean.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "UIColor+Palette.h"
#import "Launcher.h"
#import "ProfileViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "SearchNavigationController.h"
#import "ComplexNavigationController.h"
#import "NSString+Validation.h"
#import "BFVisualErrorView.h"
#import "PaginationCell.h"
@import Firebase;

@interface SearchTableViewController () {
    NSInteger activeTab;
}

@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) NSMutableArray *recentSearchResults;
@property (nonatomic, strong) BFVisualErrorView *errorView;

@property (nonatomic, strong) UIView *segmentedControl;

@end

@implementation SearchTableViewController

static NSString * const reuseIdentifier = @"Result";
static NSString * const buttonCellReuseIdentifier = @"ButtonCell";
static NSString * const paginationCellReuseIdentifier = @"PaginationCell";

- (id)init {
    self = [super init];
    if (self) {
        self.resultsType = BFSearchResultsTypeTop;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] init];
    
    [self setupSearch];
    [self setupErrorView];
    [self createSegmentedControl];
    [self positionErrorView];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Search" screenClass:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tableView.frame = self.view.bounds;
    [self positionErrorView];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if ([UIColor useWhiteForegroundForColor:self.navigationController.navigationBar.barTintColor]) {
        return UIStatusBarStyleLightContent;
    }
    else {
        if (@available(iOS 13.0, *)) {
            return UIStatusBarStyleDarkContent;
        } else {
            // Fallback on earlier versions
            return UIStatusBarStyleDefault;
        }
    }
}

- (void)setupErrorView {
    BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNotFound title:@"No Results Found" description:nil actionTitle:nil actionBlock:nil];
    
    self.errorView = [[BFVisualErrorView alloc] initWithVisualError:visualError];
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, (self.tableView.frame.size.height - self.tableView.adjustedContentInset.top - self.tableView.adjustedContentInset.bottom) / 2);
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
}

- (void)setupSearch {
    [self emptySearchResults];
    [self initRecentSearchResults];
    
    self.animateLoading = false;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    //self.tableView.contentInset = UIEdgeInsetsMake(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height, 0, 0, 0);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:reuseIdentifier];
    [self.tableView registerClass:[ButtonCell class] forCellReuseIdentifier:buttonCellReuseIdentifier];
    [self.tableView registerClass:[PaginationCell class] forCellReuseIdentifier:paginationCellReuseIdentifier];
    [self.view addSubview:self.tableView];
    
    [self determineErrorViewVisibility];
}

- (void)emptySearchResults {
    self.searchResults = [[NSMutableArray alloc] init];
}
- (void)initRecentSearchResults {
    self.recentSearchResults = [[NSMutableArray alloc] init];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults arrayForKey:@"recents_search"]) {
        NSArray *searchRecents = [defaults arrayForKey:@"recents_search"];
        if (searchRecents.count > 0) {
            if (searchRecents.count > 8) {
                searchRecents = [searchRecents subarrayWithRange:NSMakeRange(0, 8)];
            }
            
            self.recentSearchResults = [[NSMutableArray alloc] initWithArray:searchRecents];
            [self objectifyRsultsArray:self.recentSearchResults];
            
            return;
        }
    }
}

- (NSString *)currentSearchText {
    if ([self.navigationController isKindOfClass:[SearchNavigationController class]]) {
        return ((SearchNavigationController *)self.navigationController).searchView.textField.text;
    }
    else if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
        return ((ComplexNavigationController *)self.navigationController).searchView.textField.text;
    }
    
    return @"";
}

- (void)getSearchResults {    
    NSString *searchText = [self currentSearchText];
    
    if (searchText.length == 0) {
        self.loading = false;
        self.searchResults = [[NSMutableArray alloc] init];
        [self.tableView reloadData];
    }
    else {
        self.loading = true;
        
        NSString *url = @"search";
        NSString *originalSearchText = searchText;
        
        if (searchText.length > 0 &&
            ([[searchText substringToIndex:1] isEqualToString:@"@"] || activeTab == 2)) {
            url = [url stringByAppendingString:@"/users"];
            searchText = [searchText stringByReplacingOccurrencesOfString:@"@" withString:@""];
        }
        else if (searchText.length > 0 &&
                 ([[searchText substringToIndex:1] isEqualToString:@"#"] || activeTab == 1)) {
            url = [url stringByAppendingString:@"/camps"];
            searchText = [searchText stringByReplacingOccurrencesOfString:@"#" withString:@""];
        }
        
        [[HAWebService authenticatedManager] GET:url parameters:@{@"q": searchText} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if ([originalSearchText isEqualToString:[self currentSearchText]]) {
                self.loading = false;
                NSDictionary *responseData = (NSDictionary *)responseObject[@"data"];
                
                self.searchResults = [[NSMutableArray alloc] init];
                [self populateSearchResults:responseData];
                
                NSLog(@"self.searchResults: %@", self.searchResults);
                if (self.searchResults.count == 0) {
                    self.tableView.separatorInset = UIEdgeInsetsMake(0, 12, 0, 0);
                }
                else {
                    self.tableView.separatorInset = UIEdgeInsetsMake(0, 70, 0, 0);
                }
                
                [self.tableView reloadData];
                [self determineErrorViewVisibility];
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if ([originalSearchText isEqualToString:[self currentSearchText]]) {
                self.loading = false;
                
                NSLog(@"SearchTableViewController / getPosts() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                [self.tableView reloadData];
                [self determineErrorViewVisibility];
            }
        }];
    }
}
- (void)populateSearchResults:(NSDictionary *)responseData {
    if (responseData[@"results"] && [responseData[@"results"] isKindOfClass:[NSDictionary class]]) {
        if (responseData[@"results"][@"camps"]) {
            [self.searchResults addObjectsFromArray:responseData[@"results"][@"camps"]];
        }
        if (responseData[@"results"][@"users"]) {
            [self.searchResults addObjectsFromArray:responseData[@"results"][@"users"]];
        }
    }
    
    [self objectifyRsultsArray:self.searchResults];
}

-  (void)objectifyRsultsArray:(NSMutableArray *)array {
    if (![array isKindOfClass:[NSMutableArray class]]) {
        return;
    }
    
    for (NSInteger i = 0; i < array.count; i++) {
        if ([array[i] isKindOfClass:[NSDictionary class]]) {
            NSDictionary *object = array[i];
            
            if ([object objectForKey:@"type"] && [[object objectForKey:@"type"] isKindOfClass:[NSString class]]) {
                if ([object[@"type"] isEqualToString:@"camp"]) {
                    [array replaceObjectAtIndex:i withObject:[[Camp alloc] initWithDictionary:object error:nil]];
                }
                else if ([object[@"type"] isEqualToString:@"user"]) {
                    [array replaceObjectAtIndex:i withObject:[[User alloc] initWithDictionary:object error:nil]];
                }
                else if ([object[@"type"] isEqualToString:@"bot"]) {
                    [array replaceObjectAtIndex:i withObject:[[Bot alloc] initWithDictionary:object error:nil]];
                }
            }
        }
    }
}

- (void)determineErrorViewVisibility {
    NSString *searchText;
    if ([self.navigationController isKindOfClass:[SearchNavigationController class]]) {
        searchText = ((SearchNavigationController *)self.navigationController).searchView.textField.text;
    }
    else if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
        searchText = ((ComplexNavigationController *)self.navigationController).searchView.textField.text;
    }
    
    if (searchText.length > 0 && self.searchResults.count == 0 && !([self showRecents] &&  self.recentSearchResults.count == 0) && [searchText validateBonfireUsername] != BFValidationErrorNone && [searchText validateBonfireCampTag] != BFValidationErrorNone) {
        // Error: No posts yet!
        BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNotFound title:@"No Results Found" description:nil actionTitle:nil actionBlock:nil];
        self.errorView.visualError = visualError;
        self.errorView.hidden = false;
    }
    else if (searchText.length == 0 && [self tableView:self.tableView numberOfRowsInSection:0] == 0) {
        BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeSearch title:@"Start typing..." description:nil actionTitle:nil actionBlock:nil];
        self.errorView.visualError = visualError;
        self.errorView.hidden = false;
    }
    else {
        self.errorView.hidden = true;
    }
    
    if (![self.errorView isHidden]) {
        [self positionErrorView];
    }
}

- (void)positionErrorView {
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, (self.tableView.frame.size.height - _currentKeyboardHeight) / 2 - (self.segmentedControl.frame.size.height / 2));
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *searchText;
    if ([self.navigationController isKindOfClass:[SearchNavigationController class]]) {
        searchText = ((SearchNavigationController *)self.navigationController).searchView.textField.text;
    }
    else if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
        searchText = ((ComplexNavigationController *)self.navigationController).searchView.textField.text;
    }
    
    if (self.loading && indexPath.row == 0) {
        // loading cell
        PaginationCell *cell = [tableView dequeueReusableCellWithIdentifier:paginationCellReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[PaginationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:paginationCellReuseIdentifier];
        }
        
        cell.backgroundColor = [UIColor contentBackgroundColor];
        [cell.spinner startAnimating];
        
        return cell;
    }
    
    if (searchText.length > 0 &&
        self.searchResults.count == 0) {
        ButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:buttonCellReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[ButtonCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:buttonCellReuseIdentifier];
        }
        
        // Configure the cell...
        NSString *searchText;
        if ([self.navigationController isKindOfClass:[SearchNavigationController class]]) {
            searchText = ((SearchNavigationController *)self.navigationController).searchView.textField.text;
        }
        else if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
            searchText = ((ComplexNavigationController *)self.navigationController).searchView.textField.text;
        }
        
        if (indexPath.row == 0 && [searchText validateBonfireCampTag] == BFValidationErrorNone) {
            // camp
            cell.buttonLabel.text = [NSString stringWithFormat:@"Go to #%@", [searchText stringByReplacingOccurrencesOfString:@"#" withString:@""]];
        }
        else {
            // user
            cell.buttonLabel.text = [NSString stringWithFormat:@"Go to @%@", [searchText stringByReplacingOccurrencesOfString:@"@" withString:@""]];
        }
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.gutterPadding = 12;
        UIView *separator = [cell viewWithTag:10];
        if (!separator) {
            separator = [[UIView alloc] initWithFrame:CGRectMake(cell.gutterPadding, 52 - (1 / [UIScreen mainScreen].scale), self.view.frame.size.width - (cell.gutterPadding * 2), (1 / [UIScreen mainScreen].scale))];
            separator.backgroundColor = [UIColor tableViewSeparatorColor];
            separator.tag = 10;
            [cell addSubview:separator];
        }
        
        separator.hidden = !(indexPath.row == 0 && [searchText validateBonfireCampTag] == BFValidationErrorNone);
        
        cell.buttonLabel.textColor = [UIColor linkColor];
        cell.buttonLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium];
        
        return cell;
    }
    else {
        SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[SearchResultCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
        }
                
        NSObject *object;
        // mix of types
        if ([self showRecents]) {
            object = self.recentSearchResults[indexPath.row];
            cell.lineSeparator.hidden = (indexPath.row == self.recentSearchResults.count - 1);
        }
        else {
            object = self.searchResults[indexPath.row];
            cell.lineSeparator.hidden = (indexPath.row == self.searchResults.count - 1);
        }
        
        if ([object isKindOfClass:[Camp class]]) {
            cell.camp = (Camp *)object;
        }
        else if ([object isKindOfClass:[User class]]) {
            cell.user = (User *)object;
        }
        else if ([object isKindOfClass:[Bot class]]) {
            cell.bot = (Bot *)object;
        }
        else {
            cell.camp = nil;
            cell.user = nil;
            cell.bot = nil;
            
            cell.textLabel.text = @"";
            cell.imageView.image = nil;
            cell.imageView.backgroundColor = [UIColor bonfireSecondaryColor];
        }
        
        return cell;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.loading && indexPath.row == 0) {
        return 68;
    }
        
    NSString *searchText;
    if ([self.navigationController isKindOfClass:[SearchNavigationController class]]) {
        searchText = ((SearchNavigationController *)self.navigationController).searchView.textField.text;
    }
    else if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
        searchText = ((ComplexNavigationController *)self.navigationController).searchView.textField.text;
    }
    
    if (searchText.length > 0 &&
        self.searchResults.count == 0) {
        return 52;
    }
    
    return 68;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // mix of types
    BFSearchView *searchView;
    if ([self.navigationController isKindOfClass:[SearchNavigationController class]]) {
        searchView = ((SearchNavigationController *)self.navigationController).searchView;
    }
    else if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
        searchView = ((ComplexNavigationController *)self.navigationController).searchView;
    }
    NSString *searchText = searchView.textField.text;
    
    if (searchText.length > 0 &&
        self.searchResults.count == 0) {
        if (indexPath.row == 0 && [searchText validateBonfireCampTag] == BFValidationErrorNone) {
            // Go to #{camptag}
            Camp *camp = [[Camp alloc] init];
            camp.type = @"camp";
            CampAttributes *attributes = [[CampAttributes alloc] init];
            attributes.identifier = [searchText stringByReplacingOccurrencesOfString:@"#" withString:@""];
            camp.attributes = attributes;
            
            [Launcher openCamp:camp];
        }
        else {
            // user
            // Go to @{username}
            User *user = [[User alloc] init];
            user.type = @"user";
            IdentityAttributes *attributes = [[IdentityAttributes alloc] init];
            attributes.identifier = [searchText stringByReplacingOccurrencesOfString:@"@" withString:@""];
            user.attributes = attributes;
            
            [Launcher openProfile:user];
        }
    }
    else {
        NSObject *object;
        
        if ([self showRecents]) {
            object = self.recentSearchResults[indexPath.row];
        }
        else {
            object = self.searchResults[indexPath.row];
        }
        
        if ([object isKindOfClass:[Camp class]]) {
            [Launcher openCamp:(Camp *)object];
        }
        else if ([object isKindOfClass:[User class]]) {
            [Launcher openProfile:(User *)object];
        }
        else if ([object isKindOfClass:[Bot class]]) {
            [Launcher openBot:(Bot *)object];
        }
    }
    
    [searchView.textField resignFirstResponder];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section != 0) return 0;
    
    if (self.loading) {
        return 1;
    }
    else if ([self showRecents]) {
        return self.recentSearchResults.count;
    }
    else {
        NSString *searchText;
        if ([self.navigationController isKindOfClass:[SearchNavigationController class]]) {
            searchText = ((SearchNavigationController *)self.navigationController).searchView.textField.text;
        }
        else if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
            searchText = ((ComplexNavigationController *)self.navigationController).searchView.textField.text;
        }
        
        if (searchText.length > 0) {
            if (self.searchResults.count == 0) {
                CGFloat rows = 0;
                if ([searchText validateBonfireCampTag] == BFValidationErrorNone) {
                    rows++;
                }
                if ([searchText validateBonfireUsername] == BFValidationErrorNone) {
                    rows++;
                }
                
                return rows;
            }
            else {
                return self.searchResults.count;
            }
        }
    }
    
    return 0;
}

- (BOOL)showRecents  {
    NSString *searchText;
    if ([self.navigationController isKindOfClass:[SearchNavigationController class]]) {
        searchText = ((SearchNavigationController *)self.navigationController).searchView.textField.text;
    }
    else if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
        searchText = ((ComplexNavigationController *)self.navigationController).searchView.textField.text;
    }
    
    return (searchText.length == 0);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([self showRecents] && self.recentSearchResults.count == 0) return CGFLOAT_MIN;
    
    return HALF_PIXEL;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([self showRecents] && self.recentSearchResults.count == 0) return nil;
    
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HALF_PIXEL)];
    separator.backgroundColor = [UIColor tableViewSeparatorColor];
    return separator;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if ([self showRecents] && self.recentSearchResults.count == 0) return CGFLOAT_MIN;
    
    return HALF_PIXEL;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    if ([self showRecents] && self.recentSearchResults.count == 0) return nil;
    
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HALF_PIXEL)];
    separator.backgroundColor = [UIColor tableViewSeparatorColor];
    return separator;
}

- (void)searchFieldDidBeginEditing {
    /*self.searchController.searchView.textField.selectedTextRange = [self.searchController.searchView.textField textRangeFromPosition:self.searchController.searchView.textField.beginningOfDocument toPosition:self.searchController.searchView.textField.endOfDocument];
    [UIMenuController sharedMenuController].menuVisible = NO;*/
}
- (void)searchFieldDidChange {
    NSString *searchText;
    if ([self.navigationController isKindOfClass:[SearchNavigationController class]]) {
        searchText = ((SearchNavigationController *)self.navigationController).searchView.textField.text;
    }
    else if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
        searchText = ((ComplexNavigationController *)self.navigationController).searchView.textField.text;
    }
    
    NSLog(@"searchText: %@", searchText);
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if (searchText.length > 0) {
        self.loading = true;
        
        CGFloat delay = (searchText.length == 1) ? 0 : 0.1f;
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
        [self performSelector:@selector(getSearchResults) withObject:nil afterDelay:delay];
    }
    else {
        self.loading = false;
        self.searchResults = [[NSMutableArray alloc] init];
    }
    
    [self.tableView reloadData];
    [self determineErrorViewVisibility];
}
- (void)searchFieldDidEndEditing {
    [self.tableView reloadData];
}
- (void)searchFieldDidReturn {
    BFSearchView *searchView;
    if ([self.navigationController isKindOfClass:[SearchNavigationController class]]) {
        searchView = ((SearchNavigationController *)self.navigationController).searchView;
    }
    else if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
        searchView = ((ComplexNavigationController *)self.navigationController).searchView;
    }
    
    if (!searchView) {
        return;
    }
    
    
    if (searchView.textField.text.length == 0) {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    _currentKeyboardHeight = keyboardFrameBeginRect.size.height;
    
    self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, _currentKeyboardHeight - [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom, self.tableView.contentInset.right);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    
    [self positionErrorView];
}

- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, self.currentKeyboardHeight, self.tableView.contentInset.right);
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
        
        [self positionErrorView];
    } completion:nil];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // pass scroll events up to the navigation controller
    UINavigationController *navController = UIViewParentController(self).navigationController;
    if (navController) {
        if ([navController isKindOfClass:[ComplexNavigationController class]]) {
            ComplexNavigationController *complexNav = (ComplexNavigationController *)navController;
            [complexNav childTableViewDidScroll:self.tableView];
        }
        else if ([navController isKindOfClass:[SimpleNavigationController class]]) {
            SimpleNavigationController *simpleNav = (SimpleNavigationController *)navController;
            [simpleNav childTableViewDidScroll:self.tableView];
        }
    }
}

- (void)createSegmentedControl {
    NSArray *tabs = @[@"All", @"Camps", @"Users"];
    
    self.segmentedControl = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 48)];
    self.segmentedControl.backgroundColor = [UIColor colorNamed:@"Navigation_ClearBackgroundColor"];
    
    UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, self.segmentedControl.frame.size.height, self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
    [self.segmentedControl addSubview:lineSeparator];
    [self.view addSubview:self.segmentedControl];
        
    // add segmented control segments
    CGFloat buttonWidth = (tabs.count > 3 ? 0 : self.view.frame.size.width / tabs.count); // buttonWidth of 0 denotes a dynamic width button
    CGFloat buttonPadding = 0; // only used if the button has a dynamic width
    CGFloat lastButtonX = 0;
    
    UIView *selectedBackground = [[UIView alloc] initWithFrame:CGRectMake(0, self.segmentedControl.frame.size.height - 2, buttonWidth, 2)];
    selectedBackground.layer.cornerRadius = 1;
    selectedBackground.backgroundColor = [UIColor bonfirePrimaryColor];
//    selectedBackground.layer.shadowColor = [UIColor blackColor].CGColor;
//    selectedBackground.layer.shadowOffset = CGSizeMake(0, 1);
//    selectedBackground.layer.shadowRadius = 1.5f;
//    selectedBackground.layer.shadowOpacity = 0.06;
    selectedBackground.tag = 5;
    [self.segmentedControl addSubview:selectedBackground];
    
    for (NSInteger i = 0; i < tabs.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = i;
        [button.titleLabel setFont:[UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold]];
        [button setTitle:tabs[i] forState:UIControlStateNormal];
        
        if (buttonWidth == 0) {
            CGFloat buttonTextWidth = ceilf([button.currentTitle boundingRectWithSize:CGSizeMake(self.view.frame.size.width, self.segmentedControl.frame.size.height) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName:button.titleLabel.font} context:nil].size.width);
            button.frame = CGRectMake(lastButtonX, 0, buttonTextWidth + (buttonPadding * 2), self.segmentedControl.frame.size.height);
        }
        else {
            button.frame = CGRectMake(lastButtonX, 0, buttonWidth, self.segmentedControl.frame.size.height);
        }
        
        [button bk_whenTapped:^{
            [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
            
            [HapticHelper generateFeedback:FeedbackType_Selection];
            
            [self.view endEditing:TRUE];
            [self tabTappedAtIndex:button.tag];
        }];
        
        [button bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
                button.alpha = 0.5;
            } completion:nil];
        } forControlEvents:UIControlEventTouchDown];
        [button bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.5f delay:0.15 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
                button.alpha = 1;
            } completion:nil];
        } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
        
//        if (i < tabs.count - 1) {
//            // => not the last tab
//            UIView *horizontalSeparator = [[UIView alloc] initWithFrame:CGRectMake(button.frame.size.width - (1 / [UIScreen mainScreen].scale), 14, (1 / [UIScreen mainScreen].scale), 24)];
//            horizontalSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
//            [button addSubview:horizontalSeparator];
//        }
        
        [self.segmentedControl addSubview:button];
        
        lastButtonX = button.frame.origin.x + button.frame.size.width;
    }
    
    self.tableView.contentInset = UIEdgeInsetsMake(self.segmentedControl.frame.size.height, 0, self.tableView.contentInset.bottom, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    
    activeTab = -1;
    [self tabTappedAtIndex:0];
}

- (void)tabTappedAtIndex:(NSInteger)tabIndex {
    if (tabIndex != activeTab) {
        activeTab = tabIndex;
    
        UIButton *selectedButton;
        for (UIButton *button in self.segmentedControl.subviews) {
            if (![button isKindOfClass:[UIButton class]]) continue;
            
            if (button.tag == tabIndex) {
                selectedButton = button;
                [button setTitleColor:[UIColor bonfirePrimaryColor] forState:UIControlStateNormal];
                button.titleLabel.font = [UIFont systemFontOfSize:button.titleLabel.font.pointSize weight:UIFontWeightBold];
            }
            else {
                [button setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateNormal];
                button.titleLabel.font = [UIFont systemFontOfSize:button.titleLabel.font.pointSize weight:UIFontWeightSemibold];
            }
        }
        
        if (selectedButton) {
            UIView *selectedBackground = [self.segmentedControl viewWithTag:5];
            CGFloat scale = selectedButton.transform.a;
            [UIView animateWithDuration:0.15f delay:0 usingSpringWithDamping:0.95f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
                SetWidth(selectedBackground, selectedButton.frame.size.width / scale);
                selectedBackground.center = CGPointMake(selectedButton.frame.origin.x + selectedButton.frame.size.width / 2, selectedBackground.center.y);
            } completion:^(BOOL finished) {
            }];
        }
        
        [self loadTabData:false];
    }
}
- (void)loadTabData:(BOOL)forceRefresh {
    [self searchFieldDidChange];
}

@end
