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
@import Firebase;

@interface SearchTableViewController ()

@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) NSMutableArray *recentSearchResults;
@property (nonatomic, strong) BFVisualErrorView *errorView;

@end

@implementation SearchTableViewController

static NSString * const reuseIdentifier = @"Result";
static NSString * const buttonCellReuseIdentifier = @"ButtonCell";

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
    
    [self setupErrorView];
    [self setupSearch];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Search" screenClass:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor contentBackgroundColor];
    //self.tableView.contentInset = UIEdgeInsetsMake(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height, 0, 0, 0);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:reuseIdentifier];
    [self.tableView registerClass:[ButtonCell class] forCellReuseIdentifier:buttonCellReuseIdentifier];
    
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
        self.searchResults = [[NSMutableArray alloc] init];
        [self.tableView reloadData];
    }
    else {
        NSString *url = @"search";
        NSString *originalSearchText = searchText;
        
        if (searchText.length > 0 && [[searchText substringToIndex:1] isEqualToString:@"@"]) {
            url = [url stringByAppendingString:@"/users"];
            searchText = [searchText stringByReplacingOccurrencesOfString:@"@" withString:@""];
        }
        else if (searchText.length > 0 && [[searchText substringToIndex:1] isEqualToString:@"#"]) {
            url = [url stringByAppendingString:@"/camps"];
            searchText = [searchText stringByReplacingOccurrencesOfString:@"@" withString:@""];
        }
        
        [[HAWebService authenticatedManager] GET:url parameters:@{@"q": searchText} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if ([originalSearchText isEqualToString:[self currentSearchText]]) {
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
            NSLog(@"SearchTableViewController / getPosts() - error: %@", error);
            //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            [self.tableView reloadData];
            [self determineErrorViewVisibility];
        }];
    }
}
- (void)populateSearchResults:(NSDictionary *)responseData {
    [self.searchResults addObjectsFromArray:responseData[@"results"][@"camps"]];
    [self.searchResults addObjectsFromArray:responseData[@"results"][@"users"]];
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
        self.errorView.hidden = false;
        
        BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNotFound title:@"No Results Found" description:nil actionTitle:nil actionBlock:nil];
        self.errorView.visualError = visualError;
    }
    else if (searchText.length == 0 && [self tableView:self.tableView numberOfRowsInSection:0] == 0) {
        self.errorView.hidden = false;
        
        BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeSearch title:@"Start typing..." description:nil actionTitle:nil actionBlock:nil];
        self.errorView.visualError = visualError;
    }
    else {
        self.errorView.hidden = true;
    }
    
    if (![self.errorView isHidden]) {
        [self positionErrorView];
    }
}

- (void)positionErrorView {
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, (self.tableView.frame.size.height - self.tableView.adjustedContentInset.top - _currentKeyboardHeight) / 2);
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
    
    if (indexPath.section == 1 &&
        searchText.length > 0 &&
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
        if (indexPath.section == 0) {
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
    NSString *searchText;
    if ([self.navigationController isKindOfClass:[SearchNavigationController class]]) {
        searchText = ((SearchNavigationController *)self.navigationController).searchView.textField.text;
    }
    else if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
        searchText = ((ComplexNavigationController *)self.navigationController).searchView.textField.text;
    }
    
    if (indexPath.section == 1 &&
        searchText.length > 0 &&
        self.searchResults.count == 0) {
        return 52;
    }
    
    return 68;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isOverlay]) {
        [self handleCellTapForIndexPath:indexPath];
    }
    else {
        [self handleCellTapForIndexPath:indexPath];
    }
}
- (void)handleCellTapForIndexPath:(NSIndexPath *)indexPath {
    // mix of types
    BFSearchView *searchView;
    if ([self.navigationController isKindOfClass:[SearchNavigationController class]]) {
        searchView = ((SearchNavigationController *)self.navigationController).searchView;
    }
    else if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
        searchView = ((ComplexNavigationController *)self.navigationController).searchView;
    }
    NSString *searchText = searchView.textField.text;
    
    if (indexPath.section == 1 &&
        searchText.length > 0 &&
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
        
        if (indexPath.section == 0) {
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
- (BOOL)isOverlay {
    return self.navigationController.tabBarController == nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && [self showRecents]) {
        return self.recentSearchResults.count;
    }
    else if (section == 1) {
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
    return CGFLOAT_MIN;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
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
        CGFloat delay = (searchText.length == 1) ? 0 : 0.1f;
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
        [self performSelector:@selector(getSearchResults) withObject:nil afterDelay:delay];
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    }
    else {
        self.searchResults = [[NSMutableArray alloc] init];
    }
    
    [self.tableView reloadData];
    [self determineErrorViewVisibility];
}
- (void)updateTable {
    
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
    
    [self positionErrorView];
}

- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
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
    
    CGFloat normalizedScrollViewContentOffsetY = scrollView.contentOffset.y + scrollView.adjustedContentInset.top;
    
    if ([self.navigationController isKindOfClass:[SearchNavigationController class]]) {
        if (normalizedScrollViewContentOffsetY > 0) {
            if (((SearchNavigationController *)self.navigationController).bottomHairline.alpha == 0) {
                [(SearchNavigationController *)self.navigationController setShadowVisibility:YES withAnimation:false];
            }
        }
        else {
            if (((SearchNavigationController *)self.navigationController).bottomHairline.alpha == 1) {
                [(SearchNavigationController *)self.navigationController setShadowVisibility:NO withAnimation:false];
            }
        }
    }
}

@end
