//
//  DiscoverViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 9/29/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "CampStoreTableViewController.h"
#import "Session.h"
#import "SimpleNavigationController.h"
#import "Launcher.h"
#import "CampCardsListCell.h"
#import "SearchResultCell.h"
#import "ButtonCell.h"
#import "TabController.h"
#import "UIColor+Palette.h"
#import "NSArray+Clean.h"
#import "HAWebService.h"
#import "ErrorView.h"
#import "BFTipsManager.h"
#import "CampsList.h"
@import Firebase;

@interface CampStoreTableViewController ()

@property (nonatomic, strong) SimpleNavigationController *simpleNav;

@property (nonatomic, strong) NSMutableArray <Camp *> *featuredCamps;
@property (nonatomic) BOOL loadingFeaturedCamps;
@property (nonatomic) BOOL errorLoadingFeaturedCamps;

@property (nonatomic, strong) NSMutableArray <CampsList *> <CampsList> *lists;
@property (nonatomic) BOOL loadingLists;
@property (nonatomic) BOOL errorLoadingLists;

@property (nonatomic) BOOL userDidRefresh;
@property (nonatomic) BOOL showAllCamps;

@property (nonatomic, strong) ErrorView *errorView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end


@implementation CampStoreTableViewController

static NSString * const reuseIdentifier = @"CampCell";
static NSString * const emptyCampCellReuseIdentifier = @"EmptyCampCell";
static NSString * const errorCampCellReuseIdentifier = @"ErrorCampCell";

static NSString * const cardsListCellReuseIdentifier = @"CardsListCell";
static NSString * const miniCampCellReuseIdentifier = @"MiniCell";

static NSString * const blankReuseIdentifier = @"BlankCell";

static NSString * const buttonCellReuseIdentifier = @"ButtonCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.simpleNav = (SimpleNavigationController *)self.navigationController;
    
    self.view.backgroundColor = [UIColor contentBackgroundColor];
    
    [self initDefaults];
    
    [self setupTableView];
    
    [self getAll];
        
    // Google Analytics
    [FIRAnalytics setScreenName:@"Discover" screenClass:nil];
}

- (void)initDefaults {
    self.featuredCamps = [[NSMutableArray <Camp *> alloc] initWithArray:[[[NSUserDefaults standardUserDefaults] arrayForKey:@"featured_camps_cache"] toCampArray]];
    self.lists = [[NSMutableArray <CampsList *> <CampsList> alloc] initWithArray:[[[NSUserDefaults standardUserDefaults] arrayForKey:@"camps_lists_cache"] toCampsListArray]];
    
    //[Launcher openDebugView:self.featuredCamps];
    
    self.loadingFeaturedCamps = true;
    self.loadingLists = true;
    
    self.errorLoadingFeaturedCamps = false;
    self.errorLoadingLists = false;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.createCampButton.alpha == 0) {
        [self.navigationController.view addSubview:self.createCampButton];
        
        self.createCampButton.frame = CGRectMake((self.view.frame.size.width / 2)  - (self.createCampButton.frame.size.width / 2), self.tabBarController.tabBar.frame.origin.y - self.createCampButton.frame.size.height - 12, self.createCampButton.frame.size.width, self.createCampButton.frame.size.height);
        self.createCampButton.transform = CGAffineTransformMakeScale(0.5, 0.5);
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.createCampButton.transform = CGAffineTransformMakeScale(1, 1);
            self.createCampButton.alpha = 1;
        } completion:nil];
    }
    
    CGFloat navigationHeight = self.navigationController != nil ? self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height : 0;
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, [UIScreen mainScreen].bounds.size.height - navigationHeight);
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)setupErrorView {
    self.errorView = [[ErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100)];
    [self.errorView updateType:ErrorViewTypeNotFound title:@"Error Loading" description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
        [self refresh];
    }];
    self.errorView.center = self.tableView.center;
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
}
- (void)getAll {
    [self getFeaturedCamps];
    [self getLists];
    
    [self.tableView reloadData];
}
- (void)refresh {
    [self getAll];
    
    [self update];
}
- (void)update {
    [self.tableView reloadData];
    
    if ((!self.loadingFeaturedCamps && self.featuredCamps.count == 0) && (!self.loadingLists && self.lists.count == 0)) {
        // empty state
        if (!self.errorView) {
            [self setupErrorView];
        }
        
        self.errorView.hidden = false;
        
        if ([HAWebService hasInternet]) {
            [self.errorView updateType:ErrorViewTypeGeneral title:@"Error Loading" description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
                [self refresh];
            }];
        }
        else {
            [self.errorView updateType:ErrorViewTypeNoInternet title:@"No Internet" description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
                [self refresh];
            }];
        }
        
        [self positionErrorView];
    }
    else {
        self.errorView.hidden = true;
    }
}

- (void)showErrorViewWithType:(ErrorViewType)type title:(NSString *)title description:(NSString *)description {
    self.errorView.hidden = false;
    [self.errorView updateType:type title:title description:description actionTitle:nil actionBlock:nil];
    [self positionErrorView];
}
- (void)positionErrorView {
    self.errorView.center = CGPointMake(self.tableView.frame.size.width / 2, self.tableView.frame.size.height / 2 - (self.tableView.adjustedContentInset.bottom / 2));
}

- (void)setupTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 40 + (12 * 2), 0);
    //self.tableView.contentInset = UIEdgeInsetsZero;
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    self.tableView.refreshControl = [[UIRefreshControl alloc] init];
    [self.tableView.refreshControl addTarget:self action:@selector(getAll) forControlEvents:UIControlEventValueChanged];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    [self.tableView registerClass:[CampCardsListCell class] forCellReuseIdentifier:cardsListCellReuseIdentifier];
    [self.tableView registerClass:[ButtonCell class] forCellReuseIdentifier:buttonCellReuseIdentifier];
    
    [self setupSpinner];
}

- (void)setupSpinner {
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.color = [UIColor bonfireSecondaryColor];
    self.spinner.center = CGPointMake(self.tableView.frame.size.width / 2, [self tableView:self.tableView heightForHeaderInSection:0] + 26);
    [self stopSpinner];
    [self.tableView addSubview:self.spinner];
}
- (void)startSpinner {
    if (!self.spinner.isAnimating) {
        [self.spinner startAnimating];
        self.spinner.hidden = false;
    }
}
- (void)stopSpinner {
    if (self.spinner.isAnimating) {
        [self.spinner stopAnimating];
        self.spinner.hidden = true;
    }
}

- (void)getLists {
    [[HAWebService authenticatedManager] GET:@"users/me/camps/lists" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSArray *responseData = [responseObject[@"data"] toCampsListArray];
        
        if (responseData.count > 0) {
            self.lists = [[NSMutableArray <CampsList *> <CampsList> alloc] initWithArray:responseData];
        }
        else {
            self.lists = [[NSMutableArray <CampsList *> <CampsList> alloc] init];
        }
        [[NSUserDefaults standardUserDefaults] setObject:[self.lists toCampsListDictionaryArray] forKey:@"camps_lists_cache"];
        
        self.loadingLists = false;
        self.errorLoadingLists = false;
        
        [self update];
        
        if (!self.loadingLists && !self.loadingFeaturedCamps) {
            [[self refreshControl] performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"‼️ MyCampsViewController / getLists() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        self.loadingLists = false;
        self.errorLoadingLists = true;
        
        [self update];
        
        if (!self.loadingLists && !self.loadingFeaturedCamps) {
            [[self refreshControl] performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
        }
    }];
}

- (void)getFeaturedCamps {
    [[HAWebService authenticatedManager] GET:@"users/me/camps/lists/featured" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // NSLog(@"MyCampsViewController / getRgetFeaturedCampsooms() success! ✅");
        
        NSArray <Camp *> *responseData = [responseObject[@"data"] toCampArray];
        
        NSLog(@"response data| %@", responseData);
        
        if (responseData.count > 0) {
            self.featuredCamps = [[NSMutableArray <Camp *> alloc] initWithArray:responseData];
        }
        else {
            self.featuredCamps = [[NSMutableArray <Camp *> alloc] init];
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:[self.featuredCamps toCampDictionaryArray] forKey:@"featured_camps_cache"];
        
        self.loadingFeaturedCamps = false;
        self.errorLoadingFeaturedCamps = false;
        
        [self update];
        
        if (!self.loadingLists && !self.loadingFeaturedCamps) {
            [[self refreshControl] performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"MyCampsViewController / getCamps() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        self.loadingFeaturedCamps = false;
        self.errorLoadingFeaturedCamps = true;
        
        [self update];
        
        if (!self.loadingLists && !self.loadingFeaturedCamps) {
            [[self refreshControl] performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
        }
    }];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    BOOL loading = self.loadingFeaturedCamps || self.loadingLists;
    if (loading) {
        [self startSpinner];
    }
    else {
        [self stopSpinner];
    }
    
    return 1 + (loading ? 0 : 1 + self.lists.count + 1);
    // 1. Search
    // 2. My Camps
    // 3. Lists
    // 4. Quick Links
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) {
        if (self.loadingFeaturedCamps || self.featuredCamps.count > 0) {
            return 1;
        }
        else {
            return 0;
        }
    }
    else if (section < 1 + self.lists.count + 1) {
        return 1;
    }
    else if (section == 1 + self.lists.count + 1) {
        // quick links [@"Suggest a Feature", @"Report a Bug"]
        return (self.featuredCamps.count || self.lists.count > 0) ? 2 : 0;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        if (self.loadingFeaturedCamps || self.featuredCamps.count > 0) {
            CampCardsListCell *cell = [tableView dequeueReusableCellWithIdentifier:cardsListCellReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[CampCardsListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cardsListCellReuseIdentifier];
            }
            
            cell.size = CAMP_CARD_SIZE_MEDIUM;
            
            cell.loading = self.loadingFeaturedCamps;
            cell.camps = [[NSMutableArray alloc] initWithArray:self.loadingFeaturedCamps?@[]:self.featuredCamps];
            
            return cell;
        }
    }
    else if (!self.loadingLists && (indexPath.section > 1 && indexPath.section <= self.lists.count + 1)) {
        CampCardsListCell *cell = [tableView dequeueReusableCellWithIdentifier:cardsListCellReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[CampCardsListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cardsListCellReuseIdentifier];
        }
        
        cell.loading = self.loadingLists;
        
        NSArray *campsList = @[];
        if (!self.loadingLists) {
            NSInteger index = indexPath.section - 2;
            if (self.lists.count > index && index >= 0) {
                campsList = self.lists[index].attributes.camps;
            }
        }
        
        if (campsList.count > 3) {
            cell.size = CAMP_CARD_SIZE_SMALL_MEDIUM;
        }
        else {
            cell.size = CAMP_CARD_SIZE_MEDIUM;
        }
        
        cell.camps = [[NSMutableArray alloc] initWithArray:campsList];
        
        return cell;
    }
    else if (indexPath.section == self.lists.count + 2) {
        // quick links [@"Copy Beta Invite Link", @"Suggest a Feature", @"Report Bug"]
        ButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:buttonCellReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[ButtonCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:buttonCellReuseIdentifier];
        }
        
        if (indexPath.row == 0) {
            cell.buttonLabel.text = @"Suggest a Feature";
        }
        else if (indexPath.row == 1) {
            cell.buttonLabel.text = @"Report Bug";
        }
        
        cell.gutterPadding = 16;
        UIView *separator = [cell viewWithTag:10];
        if (!separator) {
            separator = [[UIView alloc] initWithFrame:CGRectMake(cell.gutterPadding, 52 - (1 / [UIScreen mainScreen].scale), self.view.frame.size.width - (cell.gutterPadding * 2), (1 / [UIScreen mainScreen].scale))];
            separator.backgroundColor = [UIColor tableViewSeparatorColor];
            separator.tag = 10;
            [cell addSubview:separator];
        }
        
        separator.hidden = (indexPath.row == 1);
        
        cell.buttonLabel.textColor = [UIColor linkColor];
        cell.buttonLabel.font = [UIFont systemFontOfSize:22.f weight:UIFontWeightMedium];
        
        return cell;
    }
    
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankReuseIdentifier forIndexPath:indexPath];
    
    return blankCell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == self.lists.count + 2) {
        if (indexPath.row == 0) {
            // suggest a feature #BonfireFeedback
            Camp *camp = [[Camp alloc] initWithDictionary:@{@"id": @"-mb4egjBg9vYK", @"attributes": @{@"details": @{@"identifier": @"BonfireFeedback"}}} error:nil];
            [Launcher openCamp:camp];
        }
        else if (indexPath.row == 1) {
            // report bug
            Camp *camp = [[Camp alloc] initWithDictionary:@{@"id": @"-wWoxVq1VBA6R", @"attributes": @{@"details": @{@"identifier": @"BonfireBugs"}}} error:nil];
            [Launcher openCamp:camp];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        // Size: medium
        return MEDIUM_CARD_HEIGHT;
    }
    if (!self.loadingLists && (indexPath.section > 1 && indexPath.section <= self.lists.count + 1)) {
        NSArray *campsList = @[];
        NSInteger index = indexPath.section - 2;
        if (self.lists.count > index && index >= 0) {
            campsList = self.lists[index].attributes.camps;
        }
        
        if (campsList.count > 3) {
            // Size: small
            return SMALL_MEDIUM_CARD_HEIGHT;
        }
        else {
            // Size: medium
            return MEDIUM_CARD_HEIGHT;
        }
    }
    if (indexPath.section == self.lists.count + 2) {
        return 52;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 48;
    }
    if (section == 1 && self.featuredCamps.count == 0 && !self.loadingFeaturedCamps) return CGFLOAT_MIN;
    if (section >= 2 + self.lists.count) return CGFLOAT_MIN;
    
    return 60;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        // search view
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 48)];
        // header.backgroundColor = [UIColor colorNamed:@"Navigation_ClearBackgroundColor"];
        
        BFSearchView *searchView = [[BFSearchView alloc] initWithFrame:CGRectMake(12, 8, self.view.frame.size.width - (12 * 2), 36)];
        searchView.theme = BFTextFieldThemeContent;
        [searchView.textField bk_removeAllBlockObservers];
        searchView.textField.userInteractionEnabled = false;
        for (UIGestureRecognizer *gestureRecognizer in searchView.gestureRecognizers) {
            [searchView removeGestureRecognizer:gestureRecognizer];
        }
        [header bk_whenTapped:^{
            [Launcher openSearch];
        }];
        [header addSubview:searchView];
        
        UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, header.frame.size.height - (1 / [UIScreen mainScreen].scale), self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        separator.backgroundColor = [UIColor tableViewSeparatorColor];
        // [header addSubview:separator];
        
        return header;
    }
    
    if (section == 1 && self.featuredCamps.count == 0 && !self.loadingFeaturedCamps) return nil;
    if (section >= 2 + self.lists.count) return nil;
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
    
    NSString *bigTitle;
    NSString *title;

    if (section == 1) {
        /*UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, (1 / [UIScreen mainScreen].scale))];
        separator.backgroundColor = [UIColor separatorColor];
        [header addSubview:separator];*/
        
        title = @"Featured";
    }
    else if (section < (2 + self.lists.count)) {
        // camp lists
        NSInteger index = section - 2;
        title = self.lists[index].attributes.title;
    }
    else {
        title = @"Quick Links";
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
    
    if (section > 1 && section < (2 + self.lists.count) && [[NSString stringWithFormat:@"%@", self.lists[section-2].identifier] isEqualToString:@"1"]) {
        UIButton *inviteFriends = [UIButton buttonWithType:UIButtonTypeSystem];
        [inviteFriends setTitle:@"Invite Friends" forState:UIControlStateNormal];
        inviteFriends.titleLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium];
        [inviteFriends setTitleColor:[UIColor bonfireBrand] forState:UIControlStateNormal];
        inviteFriends.frame = CGRectMake(0, 0, 400, 24);
        inviteFriends.frame = CGRectMake(header.frame.size.width - inviteFriends.intrinsicContentSize.width - titleLabel.frame.origin.x, titleLabelView.frame.origin.y + titleLabel.frame.origin.y + 2, inviteFriends.intrinsicContentSize.width, inviteFriends.frame.size.height - 2);
        [inviteFriends bk_whenTapped:^{
            [Launcher openInviteFriends:self];
        }];
        [header addSubview:inviteFriends];
    }
    
    if (section == 1) {
        UIImageView *featuredIcon = [[UIImageView alloc] initWithFrame:CGRectMake(titleLabel.frame.origin.x, header.frame.size.height - 11 - 24, 24, 24)];
        featuredIcon.image = [UIImage imageNamed:@"featuredSectionIcon"];
        [header addSubview:featuredIcon];
        
        CGFloat newTitleLabelX = featuredIcon.frame.origin.x + featuredIcon.frame.size.width + 8;
        titleLabel.frame = CGRectMake(featuredIcon.frame.origin.x + featuredIcon.frame.size.width + 8, titleLabel.frame.origin.y, header.frame.size.width - featuredIcon.frame.origin.x - newTitleLabelX, titleLabel.frame.size.height);
    }
//    else if (section == 2) {
//        UIImageView *featuredIcon = [[UIImageView alloc] initWithFrame:CGRectMake(titleLabel.frame.origin.x, header.frame.size.height - 11 - 24, 24, 24)];
//        featuredIcon.image = [UIImage imageNamed:@"trendingSectionIcon"];
//        [header addSubview:featuredIcon];
//
//        CGFloat newTitleLabelX = featuredIcon.frame.origin.x + featuredIcon.frame.size.width + 8;
//        titleLabel.frame = CGRectMake(featuredIcon.frame.origin.x + featuredIcon.frame.size.width + 8, titleLabel.frame.origin.y, header.frame.size.width - featuredIcon.frame.origin.x - newTitleLabelX, titleLabel.frame.size.height);
//    }
    
    return header;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {    
    if (section == 0) return CGFLOAT_MIN; //&& self.myCamps.count == 0 && !self.loadingMyCamps) return CGFLOAT_MIN;
    if (section == 1 && self.featuredCamps.count == 0 && !self.loadingFeaturedCamps) return CGFLOAT_MIN;
    
    if (section == 0) {
        return (1 / [UIScreen mainScreen].scale);
    }
    
    return 24;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) return nil; //&& self.myCamps.count == 0 && !self.loadingMyCamps) return nil;
    if (section == 1 && self.featuredCamps.count == 0 && !self.loadingFeaturedCamps) return nil;
    
    // last second -> no line separator
    if (section == [self numberOfSectionsInTableView:tableView] - 1) return nil;
    
    UIView *footer = [[UIView alloc] init];
    if (section == 0) {
        footer.frame = CGRectMake(0, 0, self.view.frame.size.width, (1 / [UIScreen mainScreen].scale));
    }
    else if (section == 1) {
        footer.frame = CGRectMake(0, 0, self.view.frame.size.width, 24);
    }
    else {
        footer.frame = CGRectMake(0, 0, self.view.frame.size.width, 24);
    }
    
    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = [UIColor tableViewSeparatorColor];
    if (section == 0) {
        separator.frame = CGRectMake(0, footer.frame.size.height - (1 / [UIScreen mainScreen].scale), self.view.frame.size.width, 1 / [UIScreen mainScreen].scale);
    }
    else {
        separator.frame = CGRectMake(12, footer.frame.size.height - (1 / [UIScreen mainScreen].scale), self.view.frame.size.width - 24, 1 / [UIScreen mainScreen].scale);
    }
    [footer addSubview:separator];
    
    return footer;
}

//- (void)campUpdated:(NSNotification *)notification {
//    Camp *newCamp = notification.object;
//
//    if (newCamp != nil) {
//        BOOL changes = false;
//
//        NSArray *dataArraysToCheck = @[self.featuredCamps];
//
//        for (NSMutableArray *array in dataArraysToCheck) {
//            for (NSInteger i = 0; i < array.count; i++) {
//                Camp *camp = array[i];
//                if ([camp.identifier isEqualToString:newCamp.identifier]) {
//                    // same camp -> replace it with updated object
//                    if (camp != newCamp) {
//                        changes = true;
//                    }
//                    else {
//                        // NSLog(@"nah no diff");
//                    }
//                    [array replaceObjectAtIndex:i withObject:newCamp];
//                }
//            }
//        }
//
//        if (changes) {
//            [self.tableView reloadData];
//        }
//    }
//}

@end
