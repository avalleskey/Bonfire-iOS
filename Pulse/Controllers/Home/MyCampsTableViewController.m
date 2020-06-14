//
//  EditProfileViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "MyCampsTableViewController.h"
#import "Session.h"
#import "SearchResultCell.h"
#import "HAWebService.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import "CampListStream.h"
#import "BFHeaderView.h"
#import <PINCache/PINCache.h>
#import "CampCardsListCell.h"
#import "CampsList.h"
#import <Shimmer/FBShimmeringView.h>
#import "BFTipsManager.h"
#import "BFActivityIndicatorView.h"
@import Firebase;

#define MY_CAMPS_CACHE_KEY @"my_camps_paged_cache"

@interface MyCampsTableViewController () <UITextFieldDelegate>

@property (nonatomic, strong) FBShimmeringView *titleView;

@property (nonatomic, strong) BFSearchView *searchView;
@property (nonatomic, strong) NSString *searchPhrase;
@property (nonatomic) BOOL isSearching;

@property (nonatomic, strong) CampListStream *stream;

@property (nonatomic, strong) NSMutableArray <Camp *> *suggestedCamps;

@property (nonatomic) BOOL loadingMoreCamps;

@property (nonatomic, strong) BFVisualErrorView *errorView;
@property (nonatomic, strong) BFActivityIndicatorView *spinner;

@end

@implementation MyCampsTableViewController

static NSString * const blankReuseIdentifier = @"BlankCell";
static NSString * const emptySectionCellIdentifier = @"EmptyCell";

static NSString * const listCellIdentifier = @"ListCellItem";
static NSString * const memberCellIdentifier = @"MemberCell";
static NSString * const cardsListCellReuseIdentifier = @"CardsListCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton = true;
    
    [self setupTableView];
    
    self.searchPhrase = @"";

    self.stream = [[CampListStream alloc] init];
    // load cache
    [self loadCache];
    [self loadSuggestedCamps];
    
    [self getCampsWithCursor:StreamPagingCursorTypeNone];
    if (self.stream.camps.count == 0) {
        [self setSpinning:true];
    }
    else {
        self.tableView.alpha = 1;
        [self setSpinning:false];
    }
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Home" screenClass:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recentsUpdated:) name:@"RecentsUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMyCamps:) name:@"refreshMyCamps" object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        [self setupTitleView];
    }
}

- (void)recentsUpdated:(NSNotification *)sender {
    [self loadSuggestedCamps];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    
//    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}
- (void)refreshMyCamps:(NSNotification *)sender {
    [self getCampsWithCursor:StreamPagingCursorTypeNone];
}

- (void)showErrorViewWithType:(ErrorViewType)type title:(NSString *)title description:(NSString *)description actionTitle:(nullable NSString *)actionTitle actionBlock:(void (^ __nullable)(void))actionBlock {
    BFVisualError *visualError = [BFVisualError visualErrorOfType:type title:title description:description actionTitle:actionTitle actionBlock:actionBlock];
    [self.errorView.actionButton bk_removeAllAssociatedObjects];
    self.errorView.visualError = visualError;
    
    self.errorView.hidden = false;
    [self positionErrorView];
}
- (void)positionErrorView {
    self.errorView.center = CGPointMake((self.tableView.frame.size.width - self.tableView.contentInset.left - self.tableView.contentInset.right) / 2, self.tableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.tableView.contentInset.top - self.tableView.contentInset.bottom);
}

- (void)setupTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    //self.tableView.backgroundColor = [UIColor contentBackgroundColor];
    self.tableView.separatorColor = [UIColor tableViewSeparatorColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, ([Session sharedInstance].currentUser.attributes.summaries.counts.camps < 5 ? 40 + 16 : 0), 0);
    self.tableView.estimatedRowHeight = 0;
    [self.refreshControl addTarget:self action:@selector(refreshMyCamps:) forControlEvents:UIControlEventValueChanged];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:emptySectionCellIdentifier];
    
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:listCellIdentifier];
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:memberCellIdentifier];
    [self.tableView registerClass:[CampCardsListCell class] forCellReuseIdentifier:cardsListCellReuseIdentifier];
}
- (void)setupTitleView {
    self.title = @"My Camps";
    UIButton *titleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [titleButton setTitleColor:[UIColor bonfirePrimaryColor] forState:UIControlStateNormal];
    titleButton.titleLabel.font = ([self.navigationController.navigationBar.titleTextAttributes objectForKey:NSFontAttributeName] ? self.navigationController.navigationBar.titleTextAttributes[NSFontAttributeName] : [UIFont systemFontOfSize:18.f weight:UIFontWeightBold]);
    [titleButton setTitle:self.title forState:UIControlStateNormal];
    titleButton.frame = CGRectMake(0, 0, [titleButton intrinsicContentSize].width, self.navigationController.navigationBar.frame.size.height);
    [titleButton bk_whenTapped:^{
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    }];
    
    self.titleView = [[FBShimmeringView alloc] initWithFrame:titleButton.frame];
    [self.titleView addSubview:titleButton];
    self.titleView.contentView = titleButton;
    
    self.navigationItem.titleView = titleButton;
}
- (void)setLoading:(BOOL)loading {
    [super setLoading:loading];
    
    if (!self.loading) {
        self.titleView.shimmering = false;
    }
}

- (void)loadCache {
    NSArray *cache = [[PINCache sharedCache] objectForKey:MY_CAMPS_CACHE_KEY];
    
    self.stream = [[CampListStream alloc] init];
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
    NSMutableArray *newCache = [NSMutableArray new];
    
    for (NSInteger i = 0; i < self.stream.pages.count; i++) {
        [newCache addObject:[self.stream.pages[i] toDictionary]];
    }
    
    [[PINCache sharedCache] setObject:[newCache copy] forKey:MY_CAMPS_CACHE_KEY];
}
// If current user -> load suggested camps based on:
// 1) camps in the cache
// 2) up to 4 top most opened camps
- (void)loadSuggestedCamps {
    NSDictionary *opens = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"camp_opens"];
    NSDictionary *lastOpens = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"camp_last_opens"];
    NSArray *recentsCamps = [[NSUserDefaults standardUserDefaults] arrayForKey:@"recents_camps"];
    
    if (!self.stream.camps && recentsCamps.count == 0) return;
    
    // combine the arrays!
    NSMutableArray <Camp *> *campsArray = [[NSMutableArray <Camp *> alloc] initWithArray:self.stream.camps];
    if (recentsCamps.count > 0) {
        NSMutableArray *arrayOfCampIDs = [NSMutableArray new];
        for (Camp *camp in self.stream.camps) {
            [arrayOfCampIDs addObject:camp.identifier];
        }
        // add in the recents
        for (id camp in recentsCamps) {
            if ([camp isKindOfClass:[NSDictionary class]]) {
                Camp *c = [[Camp alloc] initWithDictionary:((NSDictionary *)camp) error:nil];
                if (![arrayOfCampIDs containsObject:c.identifier]) {
                    [campsArray addObject:c];
                    [arrayOfCampIDs addObject:c.identifier];
                }
            }
            else if ([camp isKindOfClass:[Camp class]]) {
                if (![arrayOfCampIDs containsObject:((Camp *)camp).identifier]) {
                    [campsArray addObject:camp];
                    [arrayOfCampIDs addObject:((Camp *)camp).identifier];
                }
            }
        }
    }
            
    for (NSInteger i = 0; i < campsArray.count; i++) {
        Camp *camp = campsArray[i];
        
        if ([opens objectForKey:camp.identifier]) {
            campsArray[i].opens = [opens[camp.identifier] integerValue];
        }
        else {
            campsArray[i].opens = 0;
        }
        
        if ([lastOpens objectForKey:camp.identifier]) {
            campsArray[i].lastOpened = lastOpens[camp.identifier];
        }
    }

    NSArray *sortedSuggestedCamps = [campsArray sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"lastOpened" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"opens" ascending:NO]]];
    if (sortedSuggestedCamps.count > 5) {
        sortedSuggestedCamps = [sortedSuggestedCamps subarrayWithRange:NSMakeRange(0, 5)];
    }
    
    self.suggestedCamps = [[NSMutableArray alloc] initWithArray:sortedSuggestedCamps];
}

- (void)setupErrorView {
    self.errorView = [[BFVisualErrorView alloc] initWithFrame:CGRectMake(16, 0, (self.tableView.frame.size.width - self.tableView.contentInset.left - self.tableView.contentInset.right) - 32, 100)];
    [self showErrorViewWithType:ErrorViewTypeNotFound title:@"Error Loading" description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
        [self refreshMyCamps:nil];
    }];
    self.errorView.center = self.tableView.center;
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
}

- (void)getCampsWithCursor:(StreamPagingCursorType)cursorType {
    NSString *url = [NSString stringWithFormat:@"users/me/camps"];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    NSString *filterQuery = @"";
    BOOL isSearch = _isSearching;
    if (isSearch) {
        filterQuery = self.searchPhrase;
        [params setObject:filterQuery forKey:@"filter_query"];
    }
    
    __block CampListStream *stream = self.stream;
    
    NSString *nextCursor = [stream nextCursor];
    if (cursorType == StreamPagingCursorTypeNext && nextCursor.length > 0) {
        if ([stream hasLoadedCursor:nextCursor]) {
            return;
        }
        
        self.loadingMoreCamps = true;
        [stream addLoadedCursor:nextCursor];
        [params setObject:nextCursor forKey:@"next_cursor"];
    }
    else if (_isSearching || [self.searchView.textField isFirstResponder] || (cursorType == StreamPagingCursorTypeNone && stream.camps.count > 0)) {
        self.titleView.shimmering = true;
    }
    else {
        self.loading = true;
    }
    
    [[[HAWebService manager] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        CampListStreamPage *page = [[CampListStreamPage alloc] initWithDictionary:responseObject error:nil];
        
        if (!isSearch || (isSearch && [filterQuery isEqualToString:self.searchPhrase])) {
            if (cursorType == StreamPagingCursorTypeNone || !stream) {
                stream = [[CampListStream alloc] init];
            }
            
            if (page.data.count > 0) {
                if ([params objectForKey:@"next_cursor"]) {
                    self.loadingMoreCamps = false;
                }
                
                [stream appendPage:page];
            }
            
            self.stream = stream;
            
            if (page.data.count > 0) {
                [self saveCacheIfNeeded];
            }
            // update the suggested camps
            [self loadSuggestedCamps];
        }
                        
        self.loading = false;
        
        [self update];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"CampViewController / getRequests() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        if (nextCursor.length > 0) {
            [stream removeLoadedCursor:nextCursor];
        }
        self.loading = false;
        
        [self update];
    }];
}

- (void)setSearchPhrase:(NSString *)searchPhrase {
    if (![searchPhrase isEqualToString:_searchPhrase]) {
        _searchPhrase = searchPhrase;
        
        _isSearching = (searchPhrase && searchPhrase.length > 0);
        
        [self.tableView reloadData];
    }
}

- (void)update {
    CGFloat numberBefore_0 = [self.tableView numberOfRowsInSection:0];
    CGFloat numberAfter_0 = [self tableView:self.tableView numberOfRowsInSection:0];
    
    CGFloat numberBefore_1 = [self.tableView numberOfRowsInSection:1];
    CGFloat numberAfter_1 = [self tableView:self.tableView numberOfRowsInSection:1];
        
    if (numberBefore_0 == numberAfter_0 && numberBefore_1 > 0 && numberBefore_1 == numberAfter_1) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 1)] withRowAnimation:UITableViewRowAnimationNone];
    }
    else {
        [self.tableView reloadData];
    }
    
    CampListStream *stream = self.stream;
    if (!self.loading && stream.camps.count == 0) {
        // empty state
        if (!self.errorView) {
            [self setupErrorView];
        }
        
        self.errorView.hidden = false;
        
        if ([HAWebService hasInternet]) {
            if (_isSearching) {
                [self showErrorViewWithType:ErrorViewTypeNotFound title:@"No Camps Found" description:@"You aren't in any Camps that match your search" actionTitle:@"Discover Camps" actionBlock:^{
                    TabController *tabVC = (TabController *)[Launcher activeTabController];
                    if (tabVC) {
                        tabVC.selectedIndex = [tabVC.viewControllers indexOfObject:tabVC.storeNavVC];
                        [tabVC tabBar:tabVC.tabBar didSelectItem:tabVC.storeNavVC.tabBarItem];
                    }
                    else {
                        [Launcher openDiscover];
                    }
                }];
            }
            else {
                [self showErrorViewWithType:ErrorViewTypeHeart title:@"My Camps" description:@"The Camps you join or subscribe to will show up here" actionTitle:@"Discover Camps" actionBlock:^{
                    TabController *tabVC = (TabController *)[Launcher activeTabController];
                    if (tabVC) {
                        tabVC.selectedIndex = [tabVC.viewControllers indexOfObject:tabVC.storeNavVC];
                        [tabVC tabBar:tabVC.tabBar didSelectItem:tabVC.storeNavVC.tabBarItem];
                    }
                    else {
                        [Launcher openDiscover];
                    }
                }];
            }
        }
        else {
            [self showErrorViewWithType:ErrorViewTypeNoInternet title:@"No Internet" description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
                [self refreshMyCamps:nil];
            }];
        }
        
        [self positionErrorView];
    }
    else {
        self.errorView.hidden = true;
    }
}

- (void) safeCellUpdate: (NSUInteger) section withRow : (NSUInteger) row {
    // It's important to invoke reloadRowsAtIndexPaths implementation on main thread, as it wont work on non-UI thread
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUInteger lastSection = [self.tableView numberOfSections];
        if (lastSection == 0) {
            return;
        }
        lastSection -= 1;
        if (section > lastSection) {
            return;
        }
        NSUInteger lastRowNumber = [self.tableView numberOfRowsInSection:section];
        if (lastRowNumber == 0) {
            return;
        }
        lastRowNumber -= 1;
        if (row > lastRowNumber) {
            return;
        }
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
        @try {
            if ([[self.tableView indexPathsForVisibleRows] indexOfObject:indexPath] == NSNotFound) {
                // Cells not visible can be ignored
                return;
            }
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }

        @catch ( NSException *e ) {
            // Don't really care if it doesn't work.
            // It's just to refresh the view and if an exception occurs it's most likely that that is what's happening in parallel.
            // Nothing needs done
            return;
        }
    });
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    CampListStream *stream = self.stream;
    if (stream.camps.count > 0) {
        if (section == 0 && self.suggestedCamps.count > 0) {
            return _isSearching ? 0 : 1;
        }
        else if (section == 1) {
            return stream.camps.count;
        }
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CampListStream *stream = self.stream;
    
    if (indexPath.section == 0 && self.suggestedCamps.count > 0) {
        CampCardsListCell *cell = [tableView dequeueReusableCellWithIdentifier:cardsListCellReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[CampCardsListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cardsListCellReuseIdentifier];
        }
        
        cell.size = CAMP_CARD_SIZE_SMALL_MEDIUM;
        
        cell.loading = false;
        cell.camps = [[NSMutableArray alloc] initWithArray:self.suggestedCamps];
        
        return cell;
    }
    
    if (indexPath.section == 1 && indexPath.row < stream.camps.count) {
        SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:memberCellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[SearchResultCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:memberCellIdentifier];
        }
        
        Camp *camp = stream.camps[indexPath.row];
        cell.hideCampMemberCount = true;
        cell.camp = camp;
        
        cell.lineSeparator.hidden = (indexPath.row == stream.camps.count - 1);
        
        return cell;
    }
    
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankReuseIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point  API_AVAILABLE(ios(13.0)){
    if ([[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[SearchResultCell class]]) {
        SearchResultCell *cell = (SearchResultCell *)[tableView cellForRowAtIndexPath:indexPath];
        
        if (cell.camp) {
            NSMutableArray *actions = [NSMutableArray new];
            
            UIAction *shareViaAction = [UIAction actionWithTitle:@"Share Camp via..." image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:@"share_via" handler:^(__kindof UIAction * _Nonnull action) {
                [Launcher shareCamp:cell.camp];
            }];
            [actions addObject:shareViaAction];
            
            #ifdef DEBUG
            UIAction *debug = [UIAction actionWithTitle:@"Debug Camp" image:[UIImage systemImageNamed:@"gear"] identifier:@"debug_camp" handler:^(__kindof UIAction * _Nonnull action) {
                [Launcher openDebugView:cell.camp];
            }];
            [actions addObject:debug];
            #endif
            
            UIMenu *menu = [UIMenu menuWithTitle:@"" children:actions];
            
            CampViewController *campVC = [Launcher campViewControllerForCamp:cell.camp];
            
            UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:indexPath previewProvider:^(){return campVC;} actionProvider:^(NSArray* suggestedAction){return menu;}];
            return configuration;
        }
    }
    
    return nil;
}
- (void)tableView:(UITableView *)tableView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator  API_AVAILABLE(ios(13.0)){
    void(^completionAction)(void);
    
    if ([animator.previewViewController isKindOfClass:[CampViewController class]]) {
        CampViewController *c = (CampViewController *)animator.previewViewController;
        completionAction = ^{
            [Launcher openCamp:c.camp controller:c];
        };
    }

    [animator addCompletion:^{
        wait(0, ^{
            if (completionAction) {
                completionAction();
            }
        });
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CampListStream *stream = self.stream;
    if (stream.camps.count > 0) {
        if (!_isSearching && indexPath.section == 0) {
            if (indexPath.row == 0) {
                return self.suggestedCamps.count > 0 ? SMALL_MEDIUM_CARD_HEIGHT - 12 : 0;
            }
        }
        else if (indexPath.section == 1 && stream.camps.count > 0) {
            return [SearchResultCell height];
        }
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CampListStream *stream = self.stream;
    if (!self.loading && stream.camps.count == 0) return CGFLOAT_MIN;
    
    if (!_isSearching && section == 0 && self.suggestedCamps.count > 0) {
        return 56;
    }
    
    return 0;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CampListStream *stream = self.stream;
    
    if (!self.loading && stream.camps.count == 0) return nil;
    
    if (stream.camps.count > 0) {
        if (!_isSearching && section == 0) {
            UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 56)];

            NSString *bigTitle;
            NSString *title;
            
            if (section == 0) {
                title = @"Recents";
            }
            else if (section == 1) {
                title = @"My Camps";
            }
            
            UIView *bigTitleView;
            if (bigTitle) {
                bigTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 48)];

                header.frame = CGRectMake(header.frame.origin.x, header.frame.origin.y, header.frame.size.width, 104);
                UILabel *bigTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, header.frame.size.width - 32, 40)];
                bigTitleLabel.text = bigTitle;
                bigTitleLabel.textAlignment = NSTextAlignmentLeft;
                bigTitleLabel.font = [UIFont systemFontOfSize:34.f weight:UIFontWeightHeavy];
                bigTitleLabel.textColor = [UIColor colorWithWhite:0.07f alpha:1];
                [bigTitleView addSubview:bigTitleLabel];

                UIView *headerSeparator = [[UIView alloc] initWithFrame:CGRectMake(16, bigTitleView.frame.size.height - HALF_PIXEL, self.view.frame.size.width - 32, 1 / [UIScreen mainScreen].scale)];
                headerSeparator.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08f];
                [bigTitleView addSubview:headerSeparator];

                [header addSubview:bigTitleView];
            }

            UIView *titleLabelView = [[UIView alloc] initWithFrame:CGRectMake(0, bigTitleView.frame.size.height, self.view.frame.size.width, 56)];

            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, titleLabelView.frame.size.height - 24 - 11, self.view.frame.size.width - 24, 24)];
            titleLabel.text = title;
            titleLabel.textAlignment = NSTextAlignmentLeft;
            titleLabel.font = [UIFont systemFontOfSize:22.f weight:UIFontWeightBold];
            titleLabel.textColor = [UIColor bonfirePrimaryColor];
            [titleLabelView addSubview:titleLabel];
            [header addSubview:titleLabelView];

            header.frame = CGRectMake(0, 0, header.frame.size.width, titleLabelView.frame.origin.y + titleLabelView.frame.size.height);

            if (section == 0) {
                UIImageView *featuredIcon = [[UIImageView alloc] initWithFrame:CGRectMake(titleLabel.frame.origin.x, header.frame.size.height - 11 - 24, 24, 24)];
                featuredIcon.image = [UIImage imageNamed:@"HeaderIcon_clock"];
                [header addSubview:featuredIcon];

                CGFloat newTitleLabelX = featuredIcon.frame.origin.x + featuredIcon.frame.size.width + 8;
                titleLabel.frame = CGRectMake(featuredIcon.frame.origin.x + featuredIcon.frame.size.width + 8, titleLabel.frame.origin.y, header.frame.size.width - featuredIcon.frame.origin.x - newTitleLabelX, titleLabel.frame.size.height);
            }

            return header;
        }
    }
    
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    CampListStream *stream = self.stream;
    
    if (section == 0 && (_isSearching || self.suggestedCamps.count == 0)) return CGFLOAT_MIN;
    
    if (section == 1) {
        BOOL hasAnotherPage = stream.pages.count > 0 && stream.nextCursor.length > 0;
        BOOL showLoadingFooter = self.loading || ((self.loadingMoreCamps || hasAnotherPage) && ![stream hasLoadedCursor:stream.nextCursor]);
        
        if (showLoadingFooter) {
            return 52;
        }
        else if (stream.camps.count == 0) {
            return CGFLOAT_MIN;
        }
    }
    
    if (section == [self numberOfSectionsInTableView:tableView] - 1) return CGFLOAT_MIN;
            
    return (section == 1 ? 16 : 24);
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    CampListStream *stream = self.stream;
    
    if (section == 0) return nil;
    
    if (section == 1) {
        // last row
        BOOL hasAnotherPage = stream.pages.count > 0 && stream.nextCursor.length > 0;
        BOOL showLoadingFooter = self.loading || ((self.loadingMoreCamps || hasAnotherPage) && ![stream hasLoadedCursor:stream.nextCursor]);
        
        if (showLoadingFooter) {
            UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 52)];
            
            BFActivityIndicatorView *spinner = [[BFActivityIndicatorView alloc] init];
            spinner.color = [[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0.5];
            spinner.frame = CGRectMake(footer.frame.size.width / 2 - 12, footer.frame.size.height / 2 - 12, 24, 24);
            [footer addSubview:spinner];
            
            [spinner startAnimating];
            
            if (!self.loadingMoreCamps && stream.pages.count > 0 && stream.nextCursor.length > 0) {
                [self getCampsWithCursor:StreamPagingCursorTypeNext];
            }
            
            return footer;
        }
        else if (stream.camps.count == 0) {
            return nil;
        }
    }
    
    // last second -> no line separator
    if (section == [self numberOfSectionsInTableView:tableView] - 1) return nil;
    
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, (section == 2 ? 16 : 24))];
    
    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = [UIColor tableViewSeparatorColor];
    separator.frame = CGRectMake(12, footer.frame.size.height - HALF_PIXEL, self.view.frame.size.width - 24, 1 / [UIScreen mainScreen].scale);
    [footer addSubview:separator];
    
    return footer;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CampListStream *stream = self.stream;
    
    if (indexPath.section == 1) {
        Camp *camp;
        
        if (indexPath.row < stream.camps.count) {
            camp = stream.camps[indexPath.row];
        }
        
        if (camp) {
            [Launcher openCamp:camp];
        }
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.searchView setPosition:BFSearchTextPositionLeft];
    } completion:nil];
}
- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.searchView.textField.userInteractionEnabled = false;
    
    [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.searchView setPosition:BFSearchTextPositionCenter];
    } completion:^(BOOL finished) {
        
    }];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.searchView.textField resignFirstResponder];
    
    return FALSE;
}

@end
