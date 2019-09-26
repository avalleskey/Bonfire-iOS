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
#import "ErrorView.h"
@import Firebase;

@interface SearchTableViewController ()

@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) NSMutableArray *recentSearchResults;
@property (nonatomic, strong) ErrorView *errorView;

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
    self.errorView = [[ErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100) title:@"No Results Found" description:@"" type:ErrorViewTypeNotFound];
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
        
        [self.errorView updateType:ErrorViewTypeNotFound title:@"No Results Found" description:nil actionTitle:nil actionBlock:nil];
    }
    else if (searchText.length == 0 && [self tableView:self.tableView numberOfRowsInSection:0] == 0) {
        self.errorView.hidden = false;
        
        [self.errorView updateType:ErrorViewTypeSearch title:@"Start typing..." description:nil actionTitle:nil actionBlock:nil];
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
        
        // -- Type --
        int type = 0;
        
        NSDictionary *json;
        // mix of types
        if (indexPath.section == 0) {
            json = self.recentSearchResults[indexPath.row];
            cell.lineSeparator.hidden = (indexPath.row == self.recentSearchResults.count - 1);
        }
        else {
            json = self.searchResults[indexPath.row];
            cell.lineSeparator.hidden = (indexPath.row == self.searchResults.count - 1);
        }
        if (json[@"type"]) {
            if ([json[@"type"] isEqualToString:@"camp"]) {
                type = 1;
            }
            else if ([json[@"type"] isEqualToString:@"user"]) {
                type = 2;
            }
        }
        
        if (type == 0) {
            // 0 = page inside Home (e.g. Timeline, My Camps, Trending)
            cell.textLabel.text = @"Page";
            cell.imageView.image = [UIImage new];
            cell.imageView.backgroundColor = [UIColor blueColor];
        }
        else if (type == 1) {
            NSError *error;
            Camp *camp = [[Camp alloc] initWithDictionary:json error:&error];
            cell.camp = camp;
        }
        else {
            NSError *error;
            User *user = [[User alloc] initWithDictionary:json error:&error];
            cell.user = user;
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
            CampDetails *details = [[CampDetails alloc] init];
            details.identifier = [searchText stringByReplacingOccurrencesOfString:@"#" withString:@""];
            attributes.details = details;
            camp.attributes = attributes;
            
            [Launcher openCamp:camp];
        }
        else {
            // user
            // Go to @{username}
            User *user = [[User alloc] init];
            user.type = @"user";
            UserAttributes *attributes = [[UserAttributes alloc] init];
            UserDetails *details = [[UserDetails alloc] init];
            details.identifier = [searchText stringByReplacingOccurrencesOfString:@"@" withString:@""];
            attributes.details = details;
            user.attributes = attributes;
            
            [Launcher openProfile:user];
        }
    }
    else {
        NSDictionary *json;
        
        if (indexPath.section == 0) {
            json = self.recentSearchResults[indexPath.row];
        }
        else {
            json = self.searchResults[indexPath.row];
        }
        if (json[@"type"]) {
            if ([json[@"type"] isEqualToString:@"camp"]) {
                Camp *camp = [[Camp alloc] initWithDictionary:json error:nil];
                
                [Launcher openCamp:camp];
            }
            else if ([json[@"type"] isEqualToString:@"user"]) {
                User *user = [[User alloc] initWithDictionary:json error:nil];
                
                [Launcher openProfile:user];
            }
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
    /*
    NSString *searchText;
    if ([self.navigationController isKindOfClass:[SearchNavigationController class]]) {
        searchText = ((SearchNavigationController *)self.navigationController).searchView.textField.text;
    }
    else if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
        searchText = ((ComplexNavigationController *)self.navigationController).searchView.textField.text;
    }
    
    if (section == 0 && (self.recentSearchResults.count == 0 ||
                         searchText.length != 0)) return CGFLOAT_MIN;
    if (section == 1 && (self.searchResults.count > 0 ||
                         searchText.length == 0)) return CGFLOAT_MIN;
    if (section == 1 && searchText.length > 0 &&
        self.searchResults.count == 0 &&
        [searchText componentsSeparatedByString:@" "].count == 1) return CGFLOAT_MIN;
    
    return 48;*/
    return CGFLOAT_MIN;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
    /*
    NSString *searchText;
    if ([self.navigationController isKindOfClass:[SearchNavigationController class]]) {
        searchText = ((SearchNavigationController *)self.navigationController).searchView.textField.text;
    }
    else if ([self.navigationController isKindOfClass:[ComplexNavigationController class]]) {
        searchText = ((ComplexNavigationController *)self.navigationController).searchView.textField.text;
    }
    
    if (section == 0 && (self.recentSearchResults.count == 0 ||
                         searchText.length > 0)) return nil;
    if (section == 1 && self.searchResults.count > 0) return nil;
    if (section == 1 && searchText.length > 0 &&
                        self.searchResults.count == 0 &&
                        [searchText componentsSeparatedByString:@" "].count == 1) return nil;
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 48)];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 21, self.view.frame.size.width - 32, 19)];
    title.textAlignment = NSTextAlignmentLeft;
    title.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightBold];
    title.textColor = [UIColor colorWithWhite:0.07f alpha:1];
    if (section == 1 &&
        searchText.length > 0 &&
        self.searchResults.count == 0)
    {
        title.text = @"No results found";
        title.alpha = 0.5;
    }
    else {
        title.text = section == 0 ? @"Recents" : @"Trending Searches";
        title.alpha = 1;
    }
    [header addSubview:title];
    
    UIView *hairline = [[UIView alloc] initWithFrame:CGRectMake(0, header.frame.size.height - (1 / [UIScreen mainScreen].scale), header.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    hairline.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08f];
    //[header addSubview:hairline];
    
    return header;*/
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    /*
    if (section == 0 && self.recentSearchResults.count == 0) return CGFLOAT_MIN;
    if (section == 1 && self.searchResults.count == 0) return CGFLOAT_MIN;
    
    return (1 / [UIScreen mainScreen].scale);*/
    
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    /*
    if (section == 0 && self.recentSearchResults.count == 0) return nil;
    if (section == 1 && self.searchResults.count == 0) return nil;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    view.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
    
    return view; */
    
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
    /*
    if ([self showRecents]) {
        [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
    else {
        if (self.searchResults && [self.searchResults objectForKey:@"results"] && [[self.searchResults objectForKey:@"results"] objectForKey:@"camps"] && [self.searchResults[@"results"][@"camps"] count] > 0) {
            // has at least one camp
            [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
        }
        else if (self.searchResults && [self.searchResults objectForKey:@"results"] && [[self.searchResults objectForKey:@"results"] objectForKey:@"users"] && [self.searchResults[@"results"][@"users"] count] > 0) {
            [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
        }
    }
     */
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
