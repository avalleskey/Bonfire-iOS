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
#import "NSDictionary+Clean.h"
#import "NSArray+Clean.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "UIColor+Palette.h"
#import "Launcher.h"
#import "ProfileViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>

#define envConfig [[[NSUserDefaults standardUserDefaults] objectForKey:@"config"] objectForKey:[[NSUserDefaults standardUserDefaults] stringForKey:@"environment"]]

@interface SearchTableViewController ()

@property (strong, nonatomic) NSMutableArray *searchResults;
@property (strong, nonatomic) NSMutableArray *recentSearchResults;
@property (strong, nonatomic) HAWebService *manager;

@end

@implementation SearchTableViewController

static NSString * const reuseIdentifier = @"Result";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.manager = [HAWebService manager];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] init];
    
    self.searchController = (SearchNavigationController *)self.navigationController;
    self.searchController.searchFieldDelegate = self;
    [self setupSearch];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
        
    if (self.navigationController.viewControllers.count > 2) {
        NSMutableArray *navigationArray = [[NSMutableArray alloc] initWithArray: self.navigationController.viewControllers];
        
        for (NSInteger i = navigationArray.count-2; i >= 0; i--) {
            if ([navigationArray[i] isKindOfClass:[SearchTableViewController class]]) {
                [navigationArray removeObjectAtIndex:i];
            }
        }
    
        self.navigationController.viewControllers = navigationArray;
    }
}

- (void)setupSearch {
    [self emptySearchResults];
    [self initRecentSearchResults];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor whiteColor];
    //self.tableView.contentInset = UIEdgeInsetsMake(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height, 0, 0, 0);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
    self.tableView.separatorColor = [UIColor colorWithWhite:0.92 alpha:1];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:reuseIdentifier];
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
- (void)addToRecents:(id)object {
    if ([object isKindOfClass:[Room class]] ||
        [object isKindOfClass:[User class]]) {
        NSMutableArray *searchRecents = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"recents_search"]];
        
        NSDictionary *objJSON = [object toDictionary];
        
        // add object or push to front if in recents
        BOOL existingMatch = false;
        for (NSInteger i = 0; i < [searchRecents count]; i++) {
            NSDictionary *result = searchRecents[i];
            if (objJSON[@"type"] && objJSON[@"id"] &&
                result[@"type"] && result[@"id"]) {
                if ([objJSON[@"type"] isEqualToString:result[@"type"]] && [[self convertToString:objJSON[@"id"]] isEqualToString:[self convertToString:result[@"id"]]]) {
                    existingMatch = true;
                    
                    [searchRecents removeObjectAtIndex:i];
                    [searchRecents insertObject:result atIndex:0];
                    break;
                }
            }
        }
        if (!existingMatch) {
            // remove context first
            if ([object isKindOfClass:[Room class]]) {
                Room *room = (Room *)object;
                room.attributes.context = nil;
                
                [searchRecents insertObject:[room toDictionary] atIndex:0];
            }
            else if ([object isKindOfClass:[User class]]) {
                User *user = (User *)object;
                //user.attributes.context = nil;
                
                [searchRecents insertObject:[user toDictionary] atIndex:0];
            }
            
            
            if (searchRecents.count > 8) {
                searchRecents = [[NSMutableArray alloc] initWithArray:[searchRecents subarrayWithRange:NSMakeRange(0, 8)]];
            }
        }
        
        // update NSUserDefaults
        [[NSUserDefaults standardUserDefaults] setObject:[searchRecents clean] forKey:@"recents_search"];
        [self initRecentSearchResults];
        [self.tableView reloadData];
    }
}
- (void)addToRecentlyOpened:(id)object {
    if ([object isKindOfClass:[Room class]] ||
        [object isKindOfClass:[User class]]) {
        NSMutableArray *openedRecents = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"recents_opened"]];
        
        NSDictionary *objJSON = [object toDictionary];
        
        // add object or push to front if in recents
        BOOL existingMatch = false;
        for (NSInteger i = 0; i < [openedRecents count]; i++) {
            NSDictionary *result = openedRecents[i];
            if (objJSON[@"type"] && objJSON[@"id"] &&
                result[@"type"] && result[@"id"]) {
                if ([objJSON[@"type"] isEqualToString:result[@"type"]] && [[self convertToString:objJSON[@"id"]] isEqualToString:[self convertToString:result[@"id"]]]) {
                    existingMatch = true;
                    
                    [openedRecents removeObjectAtIndex:i];
                    [openedRecents insertObject:result atIndex:0];
                    break;
                }
            }
        }
        if (!existingMatch) {
            // remove context first
            if ([object isKindOfClass:[Room class]]) {
                Room *room = (Room *)object;
                room.attributes.context = nil;
                
                [openedRecents insertObject:[room toDictionary] atIndex:0];
            }
            else if ([object isKindOfClass:[User class]]) {
                User *user = (User *)object;
                //user.attributes.context = nil;
                
                [openedRecents insertObject:[user toDictionary] atIndex:0];
            }
            
            if (openedRecents.count > 8) {
                openedRecents = [[NSMutableArray alloc] initWithArray:[openedRecents subarrayWithRange:NSMakeRange(0, 8)]];
            }
        }
        
        // update NSUserDefaults
        [[NSUserDefaults standardUserDefaults] setObject:[openedRecents clean] forKey:@"recents_opened"];
        [self initRecentSearchResults];
        [self.tableView reloadData];
    }
}

- (void)getSearchResults {
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            NSLog(@"successfully authenticated: %@", self.searchController.searchView.textField.text);
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            NSString *url = [NSString stringWithFormat:@"%@/%@/search", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
            [self.manager GET:url parameters:@{@"q": self.searchController.searchView.textField.text} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSDictionary *responseData = (NSDictionary *)responseObject[@"data"];
                
                self.searchResults = [[NSMutableArray alloc] init];
                [self populateSearchResults:responseData];
                
                NSLog(@"self.searchResults: %@", self.searchResults);
                
                [self.tableView reloadData];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"FeedViewController / getPosts() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                [self.tableView reloadData];
            }];
        }
    }];
}
- (void)populateSearchResults:(NSDictionary *)responseData {
    [self.searchResults addObjectsFromArray:responseData[@"results"][@"rooms"]];
    [self.searchResults addObjectsFromArray:responseData[@"results"][@"users"]];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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
    }
    else {
        json = self.searchResults[indexPath.row];
    }
    if (json[@"type"]) {
        if ([json[@"type"] isEqualToString:@"room"]) {
            type = 1;
        }
        else if ([json[@"type"] isEqualToString:@"user"]) {
            type = 2;
        }
    }
    cell.type = type;
    
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
        cell.imageView.tintColor = [UIColor fromHex:room.attributes.details.color];
        cell.imageView.backgroundColor = [UIColor whiteColor];
        
        NSString *detailText = [NSString stringWithFormat:@"%ld %@", (long)room.attributes.summaries.counts.members, (room.attributes.summaries.counts.members == 1 ? @"member" : @"members")];
        BOOL useLiveCount = room.attributes.summaries.counts.live > [Session sharedInstance].defaults.room.liveThreshold;
        if (useLiveCount) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %li live", detailText, (long)room.attributes.summaries.counts.live];
        }
        cell.detailTextLabel.text = detailText;
    }
    else {
        NSError *error;
        User *user = [[User alloc] initWithDictionary:json error:&error];
        
        // 2 = User
        cell.textLabel.text = user.attributes.details.displayName;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@", user.attributes.details.identifier];
        if (user.attributes.details.media.profilePicture != nil && user.attributes.details.media.profilePicture.length > 0) {
            [cell.imageView sd_setImageWithURL:[NSURL URLWithString:user.attributes.details.media.profilePicture] placeholderImage:[[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] options:SDWebImageRefreshCached];
        }
        else {
            cell.imageView.image = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
        
        // 2 = User
        cell.imageView.tintColor = [[user.attributes.details.color lowercaseString] isEqualToString:@"ffffff"] ? [UIColor colorWithWhite:0.2f alpha:1] : [UIColor fromHex:user.attributes.details.color];
        cell.imageView.backgroundColor = [UIColor whiteColor];
    }
    
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
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
    NSDictionary *json;
    
    // mix of types
    if (indexPath.section == 0) {
        json = self.recentSearchResults[indexPath.row];
    }
    else {
        json = self.searchResults[indexPath.row];
    }
    if (json[@"type"]) {
        if ([json[@"type"] isEqualToString:@"room"]) {
            Room *room = [[Room alloc] initWithDictionary:json error:nil];
            
            [self addToRecents:room];
            
            [[Launcher sharedInstance] openRoom:room];
        }
        else if ([json[@"type"] isEqualToString:@"user"]) {
            User *user = [[User alloc] initWithDictionary:json error:nil];
            
            [self addToRecents:user];
            
            [[Launcher sharedInstance] openProfile:user];
        }
    }
    
    if (self.navigationController.tabBarController != nil) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.searchController.searchView updateSearchText:@""];
            [self emptySearchResults];
            [self.tableView reloadData];
        });
    }
    else {
        
    }
    
    [self.searchController.searchView resignFirstResponder];
}
- (BOOL)isOverlay {
    return self.navigationController.tabBarController == nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && [self showRecents]) {
        return self.recentSearchResults.count;
    }
    else if (section == 1) {
        NSLog(@"how many rows: %lu", (unsigned long)self.searchResults.count);
        return self.searchResults.count;
    }
    
    return 0;
}

- (BOOL)showRecents  {
    BOOL showRecents = self.searchController.searchView.textField.text.length == 0;
    
    return showRecents;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0 && (self.recentSearchResults.count == 0 ||
                         self.searchController.searchView.textField.text.length != 0)) return CGFLOAT_MIN;
    if (section == 1 && (self.searchResults.count > 0 ||
                         self.searchController.searchView.textField.text.length == 0)) return CGFLOAT_MIN;
    
    return 48;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0 && (self.recentSearchResults.count == 0 ||
                         self.searchController.searchView.textField.text.length > 0)) return nil;
    if (section == 1 && self.searchResults.count > 0) return nil;
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 48)];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 21, self.view.frame.size.width - 32, 19)];
    title.textAlignment = NSTextAlignmentLeft;
    title.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightBold];
    title.textColor = [UIColor colorWithWhite:0.07f alpha:1];
    if (section == 1 &&
        self.searchController.searchView.textField.text.length > 0 &&
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
    
    return header;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0 && self.recentSearchResults.count == 0) return CGFLOAT_MIN;
    if (section == 1 && self.searchResults.count == 0) return CGFLOAT_MIN;
    
    return (1 / [UIScreen mainScreen].scale);
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0 && self.recentSearchResults.count == 0) return nil;
    if (section == 1 && self.searchResults.count == 0) return nil;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    view.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
    
    return view;
}

- (void)searchFieldDidBeginEditing {
    /*self.searchController.searchView.textField.selectedTextRange = [self.searchController.searchView.textField textRangeFromPosition:self.searchController.searchView.textField.beginningOfDocument toPosition:self.searchController.searchView.textField.endOfDocument];
    [UIMenuController sharedMenuController].menuVisible = NO;*/
}
- (void)searchFieldDidChange {
    NSString *searchText = self.searchController.searchView.textField.text;
    
    NSLog(@"searchText: %@", searchText);
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if (searchText.length > 0) {
        float delay = 0.1;
        
        [self performSelector:@selector(getSearchResults) withObject:nil afterDelay:delay];
    }
    else {
        [self.tableView reloadData];
    }
}
- (void)searchFieldDidEndEditing {
    [self.tableView reloadData];
}
- (void)searchFieldDidReturn {
    /*
    if ([self showRecents]) {
        [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
    else {
        if (self.searchResults && [self.searchResults objectForKey:@"results"] && [[self.searchResults objectForKey:@"results"] objectForKey:@"rooms"] && [self.searchResults[@"results"][@"rooms"] count] > 0) {
            // has at least one room
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
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    NSLog(@"bottom padding: %f", bottomPadding);
    NSLog(@"current keyboard height: %f", _currentKeyboardHeight);
    
    self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, _currentKeyboardHeight - bottomPadding + 24, 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, _currentKeyboardHeight - bottomPadding, 0);
}

- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, 0, 0);
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    } completion:nil];
}



@end
