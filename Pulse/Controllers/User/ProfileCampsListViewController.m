//
//  EditProfileViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ProfileCampsListViewController.h"
#import "Session.h"
#import "SearchResultCell.h"
#import "HAWebService.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import "CampListStream.h"
#import "BFHeaderView.h"
#import <PINCache/PINCache.h>
#import "BFActivityIndicatorView.h"
@import Firebase;

#define MY_CAMPS_CACHE_KEY @"my_camps_paged_cache"

@interface ProfileCampsListViewController () <CampListStreamDelegate>

@property (nonatomic, strong) CampListStream *stream;

@property (nonatomic, strong) BFVisualErrorView *errorView;

@property (nonatomic) BOOL loadingMoreCamps;

@end

@implementation ProfileCampsListViewController

static NSString * const blankReuseIdentifier = @"BlankCell";
static NSString * const emptySectionCellIdentifier = @"EmptyCell";

static NSString * const memberCellIdentifier = @"MemberCell";

- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.navigationItem.hidesBackButton = true;
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
    
    self.animateLoading = true;
    self.loading = true;
    
    [self setupTableView];
    [self setupErrorView];
    
    if (![self.stream nextCursor]) {
        [self getCampsWithCursor:StreamPagingCursorTypeNone];
    }
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Profile / Camps" screenClass:nil];
}

- (void)setupTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    self.tableView.separatorColor = [UIColor tableViewSeparatorColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 70, 0, 0);
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.refreshControl = nil;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:emptySectionCellIdentifier];
    
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:memberCellIdentifier];

    self.stream = [[CampListStream alloc] init];
    self.stream.delegate = self;
    
    // load cache
    if ([self isCurrentUser]) {
        [self loadCache];
    }
}

- (void)campListStreamDidUpdate:(CampListStream *)stream {
    [self.tableView reloadData];
}

- (void)setupErrorView {
    BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNotFound title:@"Error loading" description:@"Check your network settings and tap below to try again" actionTitle:nil actionBlock:nil];
    
    self.errorView = [[BFVisualErrorView alloc] initWithVisualError:visualError];
    [self positionErrorView];
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
}

- (BOOL)isCurrentUser {
    return self.user.identifier != nil && [self.user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier];
}
- (void)loadCache {
    NSArray *cache = [[PINCache sharedCache] objectForKey:MY_CAMPS_CACHE_KEY];
    
    self.stream = [[CampListStream alloc] init];
    self.stream.delegate = self;
    if (cache.count > 0) {
        for (NSDictionary *pageDict in cache) {
            CampListStreamPage *page = [[CampListStreamPage alloc] initWithDictionary:pageDict error:nil];
            [self.stream appendPage:page];
        }
        
        NSLog(@"self.stream.camps.count :: %lu", (unsigned long)self.stream.camps.count);
        if (self.stream.camps.count > 0) {
            self.loading = false;
        }
        
        [self.tableView reloadData];
    }
}
- (void)saveCacheIfNeeded {
    if (![self isCurrentUser]) return;
    
    NSMutableArray *newCache = [[NSMutableArray alloc] init];
    
    for (NSInteger i = 0; i < self.stream.pages.count; i++) {
        [newCache addObject:[self.stream.pages[i] toDictionary]];
    }
    
    [[PINCache sharedCache] setObject:[newCache copy] forKey:MY_CAMPS_CACHE_KEY];
}
- (void)getCampsWithCursor:(StreamPagingCursorType)cursorType {
    NSString *url = [NSString stringWithFormat:@"users/%@/camps", (self.user.identifier ? self.user.identifier : self.user.attributes.identifier)];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    NSString *nextCursor = [self.stream nextCursor];
    if (cursorType == StreamPagingCursorTypeNext && nextCursor.length > 0) {
        if ([self.stream hasLoadedCursor:nextCursor]) {
            return;
        }
        
        self.loading = false;
        self.loadingMoreCamps = true;
        [self.stream addLoadedCursor:nextCursor];
        [params setObject:nextCursor forKey:@"next_cursor"];
    }
    else {
        self.loading = true;
    }
    
    [[[HAWebService manager] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        CampListStreamPage *page = [[CampListStreamPage alloc] initWithDictionary:responseObject error:nil];
        
        if (page.data.count > 0) {
            if ([params objectForKey:@"next_cursor"]) {
                self.loadingMoreCamps = false;
            }
            else {
                // clear the stream (we retrieved a full page of notifs and the old ones are out of date)
                self.stream = [[CampListStream alloc] init];
            }
            [self.stream appendPage:page];
            
            [self saveCacheIfNeeded];
        }
        else if (cursorType == StreamPagingCursorTypeNone) {
            self.stream = [[CampListStream alloc] init];
            
            [self saveCacheIfNeeded];
        }
        self.stream.delegate = self;
        
        if (self.stream.camps.count == 0) {
            self.errorView.hidden = false;
           
            BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNoPosts title:@"No Camps to Show" description:[NSString stringWithFormat:@"@%@ hasn't joined any Camps", self.user.attributes.identifier] actionTitle:nil actionBlock:nil];
            self.errorView.visualError = visualError;
            
            [self positionErrorView];
        }
        else {
            self.errorView.hidden = true;
        }
        
        self.loading = false;
        
        [self.tableView reloadData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"CampViewController / getRequests() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        if (nextCursor.length > 0) {
            [self.stream removeLoadedCursor:nextCursor];
        }
        
        if (self.stream.camps.count == 0) {
            // Error: No posts yet!
            self.errorView.hidden = false;
            
            BFVisualError *visualError = [BFVisualError visualErrorOfType:([HAWebService hasInternet] ? ErrorViewTypeGeneral : ErrorViewTypeNoInternet) title:([HAWebService hasInternet] ? @"Error Loading" : @"No Internet") description:@"Check your network settings and tap below to try again" actionTitle:@"Try Again" actionBlock:^{
                self.loading = true;
                self.errorView.hidden = true;
                [self getCampsWithCursor:StreamPagingCursorTypeNone];
            }];
            self.errorView.visualError = visualError;
            
            [self positionErrorView];
        }
        
        self.loading = false;
        
        [self.tableView reloadData];
    }];
}

- (void)positionErrorView {
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.tableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && !self.loading) {
        return self.stream.camps.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row < self.stream.camps.count) {
        SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:memberCellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[SearchResultCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:memberCellIdentifier];
        }
        
        cell.showActionButton = true;
        
        Camp *camp = self.stream.camps[indexPath.row];
        cell.camp = camp;
        
        return cell;
    }
    
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankReuseIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [SearchResultCell height];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
        BOOL showLoadingFooter = self.loading || ((self.loadingMoreCamps || hasAnotherPage) && ![self.stream hasLoadedCursor:self.stream.nextCursor]);
        
        return showLoadingFooter ? 52 : 0;
    }
    
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        // last row
        BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
        BOOL showLoadingFooter = self.loading || ((self.loadingMoreCamps || hasAnotherPage) && ![self.stream hasLoadedCursor:self.stream.nextCursor]);
        
        if (showLoadingFooter) {
            UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 52)];
            
            BFActivityIndicatorView *spinner = [[BFActivityIndicatorView alloc] init];
            spinner.color = [[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0.5];
            spinner.frame = CGRectMake(footer.frame.size.width / 2 - 12, footer.frame.size.height / 2 - 12, 24, 24);
            [footer addSubview:spinner];
            
            [spinner startAnimating];
            
            if (!self.loadingMoreCamps && self.stream.pages.count > 0 && self.stream.nextCursor.length > 0) {
                [self getCampsWithCursor:StreamPagingCursorTypeNext];
            }
            
            return footer;
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        Camp *camp = self.stream.camps[indexPath.row];
        
        if (camp) {
            [Launcher openCamp:camp];
        }
    }
}

@end
