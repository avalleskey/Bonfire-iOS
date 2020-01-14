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
@import Firebase;

#define MY_CAMPS_CACHE_KEY @"my_camps_paged_cache"

@interface MyCampsTableViewController () <UITextFieldDelegate>

@property (nonatomic, strong) FBShimmeringView *titleView;

@property (nonatomic, strong) BFSearchView *searchView;
@property (nonatomic, strong) NSString *searchPhrase;
@property (nonatomic) BOOL isSearching;

@property (nonatomic, strong) CampListStream *stream;
@property (nonatomic, strong) CampListStream *searchStream;

@property (nonatomic, strong) NSMutableArray <Camp *> *suggestedCamps;

@property (nonatomic) BOOL loadingMoreCamps;

@property (nonatomic, strong) BFVisualErrorView *errorView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

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
    [self setupTitleView];
    
    self.searchPhrase = @"";

    self.stream = [[CampListStream alloc] init];
    self.searchStream = [[CampListStream alloc] init];
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        
    }
}

- (void)recentsUpdated:(NSNotification *)sender {
    [self loadSuggestedCamps];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
    
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
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.tableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
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
    NSMutableArray *newCache = [[NSMutableArray alloc] init];
    
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
    self.errorView = [[BFVisualErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100)];
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
    
    __block CampListStream *stream = [self activeStream];
    
    NSString *nextCursor = [stream nextCursor];
    if (cursorType == StreamPagingCursorTypeNext && nextCursor.length > 0) {
        if ([stream hasLoadedCursor:nextCursor]) {
            return;
        }
        
        self.loadingMoreCamps = true;
        [stream addLoadedCursor:nextCursor];
        [params setObject:nextCursor forKey:@"cursor"];
    }
    else if (_isSearching || [self.searchView.textField isFirstResponder] || (cursorType == StreamPagingCursorTypeNone && stream.camps.count > 0)) {
        self.titleView.shimmering = true;
    }
    else {
        self.loading = true;
    }
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        CampListStreamPage *page = [[CampListStreamPage alloc] initWithDictionary:responseObject error:nil];
        
        if (!isSearch || (isSearch && [filterQuery isEqualToString:self.searchPhrase])) {
            if (cursorType == StreamPagingCursorTypeNone || !stream) {
                stream = [[CampListStream alloc] init];
            }
            
            if (page.data.count > 0) {
                if ([params objectForKey:@"cursor"]) {
                    self.loadingMoreCamps = false;
                }
                
                [stream appendPage:page];
            }
            
            if (isSearch) {
                self.searchStream = stream;
            }
            else {
                self.stream = stream;
            }
            
            if (!isSearch) {
                if (page.data.count > 0) {
                    [self saveCacheIfNeeded];
                }
                // update the suggested camps
                [self loadSuggestedCamps];
            }
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
- (CampListStream *)activeStream {
    CampListStream *stream;
    if (_isSearching) {
        stream = self.searchStream;
    }
    else {
        stream = self.stream;
    }
    
    return stream;
}

- (void)update {
    if ([[self.tableView indexPathsForVisibleRows] containsObject:[NSIndexPath indexPathForRow:0 inSection:1]]) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationNone];
    }
    else {
        [self.tableView reloadData];
    }
    
    CampListStream *stream = [self activeStream];
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

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    CampListStream *stream = [self activeStream];
    if (stream.camps.count > 0) {
        if (section == 1 && self.suggestedCamps.count > 0) {
            return _isSearching ? 0 : 1;
        }
        else if (section == 2) {
            return stream.camps.count;
        }
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CampListStream *stream = [self activeStream];
    
    if (indexPath.section == 1 && self.suggestedCamps.count > 0) {
        CampCardsListCell *cell = [tableView dequeueReusableCellWithIdentifier:cardsListCellReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[CampCardsListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cardsListCellReuseIdentifier];
        }
        
        cell.size = CAMP_CARD_SIZE_SMALL_MEDIUM;
        
        cell.loading = false;
        cell.camps = [[NSMutableArray alloc] initWithArray:self.suggestedCamps];
        
        return cell;
    }
    
    if (indexPath.section == 2 && indexPath.row < stream.camps.count) {
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
            campVC.isPreview = true;
            
            UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:indexPath previewProvider:^(){return campVC;} actionProvider:^(NSArray* suggestedAction){return menu;}];
            return configuration;
        }
    }
    
    return nil;
}
- (void)tableView:(UITableView *)tableView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator  API_AVAILABLE(ios(13.0)){
    NSIndexPath *indexPath = (NSIndexPath *)configuration.identifier;
    
    [animator addCompletion:^{
        wait(0, ^{
            if ([[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[SearchResultCell class]]) {
                SearchResultCell *cell = (SearchResultCell *)[tableView cellForRowAtIndexPath:indexPath];
                
                if (cell.camp) {
                    Camp *camp = ((CampCardCell *)[tableView cellForRowAtIndexPath:indexPath]).camp;
                    
                    [Launcher openCamp:camp];
                }
            }
        });
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CampListStream *stream = [self activeStream];
    if (stream.camps.count > 0) {
        if (!_isSearching && indexPath.section == 1) {
            if (indexPath.row == 0) {
                return self.suggestedCamps.count > 0 ? SMALL_MEDIUM_CARD_HEIGHT - 8 : 0;
            }
        }
        else if (indexPath.section == 2 && stream.camps.count > 0) {
            return 68;
        }
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CampListStream *stream = [self activeStream];
    if (!self.loading && stream.camps.count == 0) return CGFLOAT_MIN;
    
    if (section == -1) {
        return 56;
    }
    else if (!_isSearching && section == 1 && self.suggestedCamps.count > 0) {
        return 56; // [BFHeaderView heightWithTopBlock:false];
    }
    
    return 0;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CampListStream *stream = [self activeStream];
    
    if (!self.loading && stream.camps.count == 0) return nil;
    
    if (section == -1) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 56)];
        
        // search view
        self.searchView = [[BFSearchView alloc] initWithFrame:CGRectMake(12, 10, self.view.frame.size.width - (12 * 2), 36)];
//        self.searchView.textField.placeholder = @"Search Camps";
//        [self.searchView updateSearchText:self.searchPhrase];
        [self.searchView setPosition:BFSearchTextPositionCenter];
        self.searchView.textField.tintColor = self.view.tintColor;
        self.searchView.textField.delegate = self;
//        [self.searchView.textField bk_addEventHandler:^(id sender) {
//            self.searchPhrase = self.searchView.textField.text;
//
//            [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
//            [self getCampsWithCursor:StreamPagingCursorTypeNone];
//            [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
//        } forControlEvents:UIControlEventEditingChanged];
        
        self.searchView.textField.userInteractionEnabled = false;
        self.searchView.theme = BFTextFieldThemeAuto;
        [self.searchView.textField bk_removeAllBlockObservers];
        self.searchView.textField.userInteractionEnabled = false;
        for (UIGestureRecognizer *gestureRecognizer in self.searchView.gestureRecognizers) {
            [self.searchView removeGestureRecognizer:gestureRecognizer];
        }
        [self.searchView bk_whenTapped:^{
            [Launcher openSearch];
        }];
        
        [header addSubview:self.searchView];
        
        return header;
    }
    
    if (stream.camps.count > 0) {
        if (!_isSearching && section == 1) {
            UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 56)];

            NSString *bigTitle;
            NSString *title;
            
            if (section == 1) {
                title = @"Recents";
            }
            else if (section == 2) {
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

                UIView *headerSeparator = [[UIView alloc] initWithFrame:CGRectMake(16, bigTitleView.frame.size.height - (1 / [UIScreen mainScreen].scale), self.view.frame.size.width - 32, 1 / [UIScreen mainScreen].scale)];
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

            if (section == 1) {
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
    CampListStream *stream = [self activeStream];
    
    if (section == 0) return CGFLOAT_MIN;
    if (section == 1 && (_isSearching || self.suggestedCamps.count == 0)) return CGFLOAT_MIN;
    
    if (section == 2) {
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
            
    return (section == 2 ? 16 : 24);
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    CampListStream *stream = [self activeStream];
    
    if (section == 0 || section == 1) return nil;
    
    if (section == 2) {
        // last row
        BOOL hasAnotherPage = stream.pages.count > 0 && stream.nextCursor.length > 0;
        BOOL showLoadingFooter = self.loading || ((self.loadingMoreCamps || hasAnotherPage) && ![stream hasLoadedCursor:stream.nextCursor]);
        
        if (showLoadingFooter) {
            UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 52)];
            
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            spinner.color = [UIColor bonfireSecondaryColor];
            spinner.frame = CGRectMake(footer.frame.size.width / 2 - 10, footer.frame.size.height / 2 - 10, 20, 20);
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
    separator.frame = CGRectMake(12, footer.frame.size.height - (1 / [UIScreen mainScreen].scale), self.view.frame.size.width - 24, 1 / [UIScreen mainScreen].scale);
    [footer addSubview:separator];
    
    return footer;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CampListStream *stream = [self activeStream];
    
    if (indexPath.section == 2) {
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
