//
//  DiscoverViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 9/29/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "DiscoverViewController.h"
#import "Session.h"
#import "SimpleNavigationController.h"
#import "Launcher.h"
#import "CampCardsListCell.h"
#import "SearchResultCell.h"
#import "ButtonCell.h"
#import "MiniAvatarListCell.h"
#import "TabController.h"
#import "UIColor+Palette.h"
#import "NSArray+Clean.h"
#import "HAWebService.h"
#import "ErrorView.h"
#import "BFTipsManager.h"
@import Firebase;

@interface DiscoverViewController ()

@property (nonatomic, strong) SimpleNavigationController *simpleNav;

@property (nonatomic, strong) NSMutableArray *featuredCamps;
@property (nonatomic) BOOL loadingFeaturedCamps;
@property (nonatomic) BOOL errorLoadingFeaturedCamps;

@property (nonatomic, strong) NSMutableArray *myCamps;
@property (nonatomic) BOOL loadingMyCamps;
@property (nonatomic) BOOL errorLoadingMyCamps;

@property (nonatomic, strong) NSMutableArray *lists;
@property (nonatomic) BOOL loadingLists;
@property (nonatomic) BOOL errorLoadingLists;

@property (nonatomic) BOOL userDidRefresh;
@property (nonatomic) BOOL showAllCamps;

@property (nonatomic, strong) ErrorView *errorView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end


@implementation DiscoverViewController

static NSString * const reuseIdentifier = @"CampCell";
static NSString * const emptyCampCellReuseIdentifier = @"EmptyCampCell";
static NSString * const errorCampCellReuseIdentifier = @"ErrorCampCell";

static NSString * const cardsListCellReuseIdentifier = @"CardsListCell";
static NSString * const miniCampCellReuseIdentifier = @"MiniCell";

static NSString * const myCampsListCellReuseIdentifier = @"MyCampsListCell";

static NSString * const blankReuseIdentifier = @"BlankCell";

static NSString * const buttonCellReuseIdentifier = @"ButtonCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.simpleNav = (SimpleNavigationController *)self.navigationController;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self initDefaults];
    
    [self setupTableView];
    
    [self getAll];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(campUpdated:) name:@"CampUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMyCamps:) name:@"refreshMyCamps" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Discover" screenClass:nil];
}

- (void)initDefaults {
    self.featuredCamps = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"featured_camps_cache"]];
    self.lists = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"camps_lists_cache"]];
    self.myCamps = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"my_camps_cache"]];
    for (NSInteger i = 0; i < self.myCamps.count; i++) {
        if ([self.myCamps[i] isKindOfClass:[Camp class]]) {
            [self.myCamps replaceObjectAtIndex:i withObject:[((Camp *)self.myCamps[i]) toDictionary]];
        }
    }
    if (self.myCamps.count > 1) [self sortCamps];
    
    self.loadingFeaturedCamps = true;
    self.loadingMyCamps = true;
    self.loadingLists = true;
    
    self.errorLoadingFeaturedCamps = false;
    self.errorLoadingMyCamps = false;
    self.errorLoadingLists = false;
}

- (void)refreshMyCamps:(NSNotification *)notification {
    [self getCamps];
}

- (void)userUpdated:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[User class]]) {
        User *user = notification.object;
        if ([user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
            [self.tableView reloadData];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.simpleNav == nil) {
        self.simpleNav = (SimpleNavigationController *)self.navigationController;
        [self.simpleNav hideBottomHairline];
    }
    
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
    
    /*
    if ([BFTipsManager hasSeenTip:@"how_to_create_camp"] == false) {
        BFTipObject *tipObject = [BFTipObject tipWithCreatorType:BFTipCreatorTypeBonfireTip creator:nil title:@"How to Create a Camp 🏕" text:@"Creating a Camp is quick and easy. Start your own by tapping the + button on the top right of the screen." action:^{
            NSLog(@"tip tapped");
        }];
        [[BFTipsManager manager] presentTip:tipObject completion:^{
            NSLog(@"presentTip() completion");
        }];
    }
     */
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
    [self getCamps];
    [self getLists];
    
    [self.tableView reloadData];
}
- (void)refresh {
    [self getAll];
    
    [self update];
}
- (void)update {
    [self.tableView reloadData];
    
    if ((!self.loadingFeaturedCamps && self.featuredCamps.count == 0) && (!self.loadingMyCamps && self.myCamps.count == 0) && (!self.loadingLists && self.lists.count == 0)) {
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
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    self.tableView.refreshControl = [[UIRefreshControl alloc] init];
    [self.tableView.refreshControl addTarget:self action:@selector(getAll) forControlEvents:UIControlEventValueChanged];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    [self.tableView registerClass:[CampCardsListCell class] forCellReuseIdentifier:cardsListCellReuseIdentifier];
    [self.tableView registerClass:[MiniAvatarListCell class] forCellReuseIdentifier:myCampsListCellReuseIdentifier];
    [self.tableView registerClass:[ButtonCell class] forCellReuseIdentifier:buttonCellReuseIdentifier];
    
    [self setupSpinner];
}

- (void)setupSpinner {
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.center = CGPointMake(self.tableView.frame.size.width / 2, self.tableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
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

- (void)sortCamps {
    if (!self.myCamps || self.myCamps.count == 0) return;
    
    NSDictionary *opens = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"camp_opens"];
    
    for (NSInteger i = 0; i < self.myCamps.count; i++) {
        if ([self.myCamps[i] isKindOfClass:[NSDictionary class]] && [self.myCamps[i] objectForKey:@"id"]) {
            NSMutableDictionary *mutableCamp = [[NSMutableDictionary alloc] initWithDictionary:self.myCamps[i]];
            NSString *campId = mutableCamp[@"id"];
            NSInteger campOpens = [opens objectForKey:campId] ? [opens[campId] integerValue] : 0;
            [mutableCamp setObject:[NSNumber numberWithInteger:campOpens] forKey:@"opens"];
            [self.myCamps replaceObjectAtIndex:i withObject:mutableCamp];
        }
    }
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"opens"
                                                                 ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
    NSArray *sortedArray = [self.myCamps sortedArrayUsingDescriptors:sortDescriptors];
    
    self.myCamps = [[NSMutableArray alloc] initWithArray:sortedArray];
}

- (void)getLists {
    [[HAWebService authenticatedManager] GET:@"users/me/camps/lists" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSArray *responseData = responseObject[@"data"];
        
        if (responseData.count > 0) {
            self.lists = [[NSMutableArray alloc] initWithArray:responseData];
        }
        else {
            self.lists = [[NSMutableArray alloc] init];
        }
        [[NSUserDefaults standardUserDefaults] setObject:[self.lists clean] forKey:@"camps_lists_cache"];
        
        self.loadingLists = false;
        self.errorLoadingLists = false;
        
        [self update];
        
        if (!self.loadingLists && !self.loadingMyCamps) {
            [[self refreshControl] performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"‼️ MyCampsViewController / getLists() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        self.loadingLists = false;
        self.errorLoadingLists = true;
        
        [self update];
        
        if (!self.loadingLists && !self.loadingMyCamps) {
            [[self refreshControl] performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
        }
    }];
}

- (void)getFeaturedCamps {
    [[HAWebService authenticatedManager] GET:@"users/me/camps/lists/featured" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // NSLog(@"MyCampsViewController / getRgetFeaturedCampsooms() success! ✅");
        
        NSArray *responseData = responseObject[@"data"];
        
        if (responseData.count > 0) {
            self.featuredCamps = [[NSMutableArray alloc] initWithArray:responseData];
        }
        else {
            self.featuredCamps = [[NSMutableArray alloc] init];
        }
        [[NSUserDefaults standardUserDefaults] setObject:[self.featuredCamps clean] forKey:@"featured_camps_cache"];
        
        self.loadingFeaturedCamps = false;
        self.errorLoadingFeaturedCamps = false;
        
        [self update];
        
        if (!self.loadingLists && !self.loadingFeaturedCamps && !self.loadingMyCamps) {
            [[self refreshControl] performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"MyCampsViewController / getCamps() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        self.loadingFeaturedCamps = false;
        self.errorLoadingFeaturedCamps = true;
        
        [self update];
        
        if (!self.loadingLists && !self.loadingFeaturedCamps && !self.loadingMyCamps) {
            [[self refreshControl] performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
        }
    }];
}

- (void)getCamps {
    [[HAWebService authenticatedManager] GET:@"users/me/camps" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // NSLog(@"MyCampsViewController / getCamps() success! ✅");
        
        NSArray *responseData = responseObject[@"data"];
        
        if (responseData.count > 0) {
            self.myCamps = [[NSMutableArray alloc] initWithArray:responseData];
        }
        else {
            self.myCamps = [[NSMutableArray alloc] init];
        }
        [[NSUserDefaults standardUserDefaults] setObject:[self.myCamps clean] forKey:@"my_camps_cache"];
        
        if (self.myCamps.count > 1) [self sortCamps];
        
        self.loadingMyCamps = false;
        self.errorLoadingMyCamps = false;
        
        [self update];
        
        if (!self.loadingLists && !self.loadingMyCamps) {
            [[self refreshControl] performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"MyCampsViewController / getCamps() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        self.loadingMyCamps = false;
        self.errorLoadingMyCamps = true;
        
        [self update];
        
        if (!self.loadingLists && !self.loadingMyCamps) {
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
    // 1. Featured
    // 2. My Camps
    // 3. Lists
    // 4. Quick Links
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 0; // return (self.loadingMyCamps || self.myCamps.count > 0) ? 1 : 0;
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
    else if (section == self.lists.count + 2) {
        // quick links [@"Copy Beta Invite Link", @"Get Help", @"Report a Bug"]
        return 3;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        MiniAvatarListCell *cell = [tableView dequeueReusableCellWithIdentifier:myCampsListCellReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[MiniAvatarListCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:myCampsListCellReuseIdentifier];
        }
        
        cell.loading = (self.loadingMyCamps && self.myCamps.count == 0);
        cell.camps = [[NSMutableArray alloc] initWithArray:(cell.loading?@[]:self.myCamps)];
        cell.shiowAllAction = ^{
            [Launcher openProfileCampsJoined:[Session sharedInstance].currentUser];
        };
        
        return cell;
    }
    else if (indexPath.section == 1) {
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
        
        if (indexPath.section == 2) {
            cell.size = CAMP_CARD_SIZE_SMALL;
        }
        else {
            cell.size = CAMP_CARD_SIZE_MEDIUM;
        }
        
        cell.loading = self.loadingLists;
        
        NSArray *campsList = @[];
        if (!self.loadingLists) {
            NSInteger index = indexPath.section - 2;
            if (self.lists.count > index && index >= 0) {
                campsList = self.lists[index][@"attributes"][@"camps"];
            }
        }
        
        cell.camps = [[NSMutableArray alloc] initWithArray:campsList];
        
        return cell;
    }
    else if (indexPath.section == self.lists.count + 2) {
        // quick links [@"Copy Beta Invite Link", @"Get Help", @"Report a Bug"]
        ButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:buttonCellReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[ButtonCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:buttonCellReuseIdentifier];
        }
        
        if (indexPath.row == 0) {
            cell.buttonLabel.text = @"Invite Friends to Bonfire";
        }
        else if (indexPath.row == 1) {
            cell.buttonLabel.text = @"Get Help";
        }
        else if (indexPath.row == 2) {
            cell.buttonLabel.text = @"Report a Bug";
        }
        
        cell.gutterPadding = 16;
        UIView *separator = [cell viewWithTag:10];
        if (!separator) {
            separator = [[UIView alloc] initWithFrame:CGRectMake(cell.gutterPadding, 52 - (1 / [UIScreen mainScreen].scale), self.view.frame.size.width - (cell.gutterPadding * 2), (1 / [UIScreen mainScreen].scale))];
            separator.backgroundColor = [UIColor separatorColor];
            separator.tag = 10;
            [cell addSubview:separator];
        }
        
        separator.hidden = (indexPath.row == 2);
        
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
            // invite friends to bonfire
            [Launcher openInviteFriends:self];
        }
        else if (indexPath.row == 1) {
            // get help
            Camp *camp = [[Camp alloc] initWithDictionary:@{@"id": @"-5Orj2GW2ywG3", @"attributes": @{@"details": @{@"identifier": @"BonfireSupport"}}} error:nil];
            [Launcher openCamp:camp];
        }
        else if (indexPath.row == 2) {
            // report a bug
            Camp *camp = [[Camp alloc] initWithDictionary:@{@"id": @"-wWoxVq1VBA6R", @"attributes": @{@"details": @{@"identifier": @"BonfireBugs"}}} error:nil];
            [Launcher openCamp:camp];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // Size: mini
        return (self.myCamps.count > 0 || self.loadingMyCamps) ? MINI_CARD_HEIGHT : 0;
    }
    if (indexPath.section == 1) {
        // Size: medium
        return MEDIUM_CARD_HEIGHT;
    }
    if (!self.loadingLists && (indexPath.section > 1 && indexPath.section <= self.lists.count + 1)) {
        if (indexPath.section == 2) {
            // Size: small
            return SMALL_CARD_HEIGHT;
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
        if (self.loadingLists || self.loadingFeaturedCamps) {
            return CGFLOAT_MIN;
        }
        
        return 52;
    }
    
    if (section == 0 && self.myCamps.count == 0 && !self.loadingMyCamps) return 0;
    if (section == 1 && self.featuredCamps.count == 0 && !self.loadingFeaturedCamps) return 0;
    
    return 60;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        if (self.loadingLists || self.loadingFeaturedCamps) {
            return nil;
        }
        // search view
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 52)];
        header.backgroundColor = [UIColor whiteColor];
        
        BFSearchView *searchView = [[BFSearchView alloc] initWithFrame:CGRectMake(12, 8, self.view.frame.size.width - (12 * 2), 36)];
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
        separator.backgroundColor = [UIColor separatorColor];
        [header addSubview:separator];
        
        return header;
    }
    
    if (section == 1 && self.featuredCamps.count == 0 && !self.loadingFeaturedCamps) return nil;
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 8, self.view.frame.size.width, 60)];
    
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
        title = self.lists[index][@"attributes"][@"title"];
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

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, titleLabelView.frame.size.height - 24 - 11, self.view.frame.size.width - 32, 24)];
    titleLabel.text = title;
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.font = [UIFont systemFontOfSize:22.f weight:UIFontWeightBold];
    titleLabel.textColor = [UIColor bonfireBlack];
    [titleLabelView addSubview:titleLabel];
    [header addSubview:titleLabelView];
    
    header.frame = CGRectMake(0, 0, header.frame.size.width, titleLabelView.frame.origin.y + titleLabelView.frame.size.height);
    
    if (section == 1) {
        UIImageView *featuredIcon = [[UIImageView alloc] initWithFrame:CGRectMake(titleLabel.frame.origin.x, header.frame.size.height - 11 - 24, 24, 24)];
        featuredIcon.image = [UIImage imageNamed:@"discoverFeaturedStar"];
        [header addSubview:featuredIcon];
        
        CGFloat newTitleLabelX = featuredIcon.frame.origin.x + featuredIcon.frame.size.width + 8;
        titleLabel.frame = CGRectMake(featuredIcon.frame.origin.x + featuredIcon.frame.size.width + 8, titleLabel.frame.origin.y, header.frame.size.width - featuredIcon.frame.origin.x - newTitleLabelX, titleLabel.frame.size.height);
    }
    
    return header;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {    
    if (section == 0) return CGFLOAT_MIN; //&& self.myCamps.count == 0 && !self.loadingMyCamps) return CGFLOAT_MIN;
    if (section == 1 && self.featuredCamps.count == 0 && !self.loadingFeaturedCamps) return CGFLOAT_MIN;
    
    if (section == 0) {
        return (1 / [UIScreen mainScreen].scale);
    }
    
    return 16;
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
        footer.frame = CGRectMake(0, 0, self.view.frame.size.width, 16);
    }
    else {
        footer.frame = CGRectMake(0, 0, self.view.frame.size.width, 16);
    }
    
    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = [UIColor separatorColor];
    if (section == 0) {
        separator.frame = CGRectMake(0, footer.frame.size.height - (1 / [UIScreen mainScreen].scale), self.view.frame.size.width, 1 / [UIScreen mainScreen].scale);
    }
    else {
        separator.frame = CGRectMake(16, footer.frame.size.height - (1 / [UIScreen mainScreen].scale), self.view.frame.size.width - 32, 1 / [UIScreen mainScreen].scale);
    }
    [footer addSubview:separator];
    
    return footer;
}

- (void)campUpdated:(NSNotification *)notification {
    Camp *camp = notification.object;
    
    if (camp != nil) {
        BOOL changes = false;
        
        NSArray *dataArraysToCheck = @[self.myCamps, self.featuredCamps];
        
        for (NSMutableArray *array in dataArraysToCheck) {
            for (NSInteger i = 0; i < array.count; i++) {
                if ([array[i][@"id"] isEqualToString:camp.identifier]) {
                    // same camp -> replace it with updated object
                    if (array[i] != [camp toDictionary]) {
                        changes = true;
                    }
                    else {
                        // NSLog(@"nah no diff");
                    }
                    [array replaceObjectAtIndex:i withObject:[camp toDictionary]];
                }
            }
        }
        
        if (changes) {
            [self.tableView reloadData];
        }
    }
}

@end
