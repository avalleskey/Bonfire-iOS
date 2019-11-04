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
#import "BFVisualErrorView.h"
#import "BFTipsManager.h"
#import "CampsList.h"
@import Firebase;

@interface CampStoreTableViewController ()

@property (nonatomic, strong) SimpleNavigationController *simpleNav;

@property (nonatomic, strong) NSMutableArray <CampsList *> <CampsList> *lists;
@property (nonatomic) BOOL errorLoadingLists;

@property (nonatomic) BOOL userDidRefresh;
@property (nonatomic) BOOL showAllCamps;

@property (nonatomic, strong) BFVisualErrorView *errorView;

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
        
    [self initDefaults];
    
    [self setupTableView];
    
    [self getAll];
    [self setSpinning:true];
        
    // Google Analytics
    [FIRAnalytics setScreenName:@"Discover" screenClass:nil];
}

- (void)initDefaults {
    self.lists = [[NSMutableArray <CampsList *> <CampsList> alloc] initWithArray:[[[NSUserDefaults standardUserDefaults] arrayForKey:@"camps_lists_cache"] toCampsListArray]];
    
    self.loading = true;
    
    self.errorLoadingLists = false;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
//    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
//        CGFloat navigationHeight = self.navigationController != nil ? self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height : 0;
//        self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, [UIScreen mainScreen].bounds.size.height - navigationHeight);
//    }
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)setupErrorView {
    self.errorView = [[BFVisualErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100)];
    [self showErrorViewWithType:ErrorViewTypeNotFound title:@"Error Loading" description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
        [self refresh];
    }];
    self.errorView.center = self.tableView.center;
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
}
- (void)getAll {
    [self getLists];
    
    [self.tableView reloadData];
}
- (void)refresh {
    [self getAll];
    
    [self update];
}
- (void)update {
    [self.tableView reloadData];
    
    if (!self.loading && self.lists.count == 0) {
        // empty state
        if (!self.errorView) {
            [self setupErrorView];
        }
        
        self.errorView.hidden = false;
        
        if ([HAWebService hasInternet]) {
            [self showErrorViewWithType:ErrorViewTypeGeneral title:@"Error Loading" description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
                [self refresh];
            }];
        }
        else {
            [self showErrorViewWithType:ErrorViewTypeNoInternet title:@"No Internet" description:@"Check your network settings and tap below to try again" actionTitle:@"Refresh" actionBlock:^{
                [self refresh];
            }];
        }
        
        [self positionErrorView];
    }
    else {
        self.errorView.hidden = true;
    }
}

- (void)showErrorViewWithType:(ErrorViewType)type title:(NSString *)title description:(NSString *)description actionTitle:(nullable NSString *)actionTitle actionBlock:(void (^ __nullable)(void))actionBlock {
    BFVisualError *visualError = [BFVisualError visualErrorOfType:type title:title description:description actionTitle:actionTitle actionBlock:actionBlock];
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
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 40 + 10, 0);
    [self.tableView setSeparatorColor:[UIColor clearColor]];
    [self.tableView.refreshControl addTarget:self action:@selector(getAll) forControlEvents:UIControlEventValueChanged];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    [self.tableView registerClass:[CampCardsListCell class] forCellReuseIdentifier:cardsListCellReuseIdentifier];
    [self.tableView registerClass:[ButtonCell class] forCellReuseIdentifier:buttonCellReuseIdentifier];
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
        
        self.loading = false;
        self.errorLoadingLists = false;
        
        [self update];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"‼️ MyCampsViewController / getLists() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        self.loading = false;
        self.errorLoadingLists = true;
        
        [self update];
    }];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (self.loading ? 0 : 1 + self.lists.count + 1);
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < self.lists.count + 1) {
        return 1;
    }
    else if (section == self.lists.count + 1) {
        // quick links [@"Suggest a Feature", @"Report a Bug"]
        return (self.lists.count > 0) ? 2 : 0;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.loading && (indexPath.section <= self.lists.count)) {
        CampCardsListCell *cell = [tableView dequeueReusableCellWithIdentifier:cardsListCellReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[CampCardsListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cardsListCellReuseIdentifier];
        }
        
        cell.loading = self.loading;
        
        NSArray *campsList = @[];
        if (!self.loading) {
            NSInteger index = indexPath.section - 1;
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
    else if (indexPath.section == self.lists.count + 1) {
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
    if (indexPath.section == self.lists.count + 1) {
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
    if (!self.loading && (indexPath.section > 0 && indexPath.section <= self.lists.count)) {
        NSArray *campsList = @[];
        NSInteger index = indexPath.section - 1;
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
    if (indexPath.section == self.lists.count + 1) {
        return 52;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 56;
    }
    if (section >= 1 + self.lists.count) return CGFLOAT_MIN;
    
    return 60;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        // search view
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 56)];
        // header.backgroundColor = [UIColor colorNamed:@"Navigation_ClearBackgroundColor"];
        
        BFSearchView *searchView = [[BFSearchView alloc] initWithFrame:CGRectMake(12, 12, self.view.frame.size.width - (12 * 2), 36)];
        searchView.theme = BFTextFieldThemeAuto;
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
    
    if (section >= 1 + self.lists.count) return nil;
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
    
    NSString *title;
    UIImage *icon;
    BOOL isNew = false;

    if (section < (1 + self.lists.count)) {
        // camp lists
        NSInteger index = section - 1;
        CampsList *list = self.lists[index];
        
        title = list.attributes.title;
        
        if (list.attributes.icon.length > 0 && [UIImage imageNamed:[NSString stringWithFormat:@"HeaderIcon_%@", list.attributes.icon]]) {
            icon = [UIImage imageNamed:[NSString stringWithFormat:@"HeaderIcon_%@", list.attributes.icon]];
        }
        
        isNew = [list.attributes isNew];
        
        #ifdef DEBUG
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            if (state == UIGestureRecognizerStateBegan) {
                // recognized long press
                [Launcher openDebugView:list];
            }
        }];
        [header addGestureRecognizer:longPress];
        #endif
    }
    else {
        title = @"Quick Links";
    }
    
    UIView *titleLabelView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 56)];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, titleLabelView.frame.size.height - 24 - 11, self.view.frame.size.width - 24, 24)];
    if (title.length > 0) {
        titleLabel.text = title;
        titleLabel.font = [UIFont systemFontOfSize:22.f weight:UIFontWeightBold];
        titleLabel.textColor = [UIColor bonfirePrimaryColor];
        
        UIFont *font = [UIFont systemFontOfSize:22.f weight:UIFontWeightBold];
        NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: [UIColor bonfirePrimaryColor]}];
        
        if (isNew) {
            NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
            [spacer addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, spacer.length)];
            [attributedTitle appendAttributedString:spacer];
            
            // NEW badge icon
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.image = [UIImage imageNamed:@"Header_isNew"];
            [attachment setBounds:CGRectMake(0, roundf(font.capHeight - attachment.image.size.height)/2.f - 2, attachment.image.size.width, attachment.image.size.height)];
            
            NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
            [attributedTitle appendAttributedString:attachmentString];
        }
        
        titleLabel.attributedText = attributedTitle;
    }
    titleLabel.textAlignment = NSTextAlignmentLeft;
    [titleLabelView addSubview:titleLabel];
    [header addSubview:titleLabelView];
    
    header.frame = CGRectMake(0, 0, header.frame.size.width, titleLabelView.frame.origin.y + titleLabelView.frame.size.height);
    
//    if (section > 1 && section < (2 + self.lists.count) && [[NSString stringWithFormat:@"%@", self.lists[section-2].identifier] isEqualToString:@"1"]) {
//        UIButton *inviteFriends = [UIButton buttonWithType:UIButtonTypeSystem];
//        [inviteFriends setTitle:@"Invite Friends" forState:UIControlStateNormal];
//        inviteFriends.titleLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium];
//        [inviteFriends setTitleColor:[UIColor bonfireBrand] forState:UIControlStateNormal];
//        inviteFriends.frame = CGRectMake(0, 0, 400, 24);
//        inviteFriends.frame = CGRectMake(header.frame.size.width - inviteFriends.intrinsicContentSize.width - titleLabel.frame.origin.x, titleLabelView.frame.origin.y + titleLabel.frame.origin.y + 2, inviteFriends.intrinsicContentSize.width, inviteFriends.frame.size.height - 2);
//        [inviteFriends bk_whenTapped:^{
//            [Launcher openInviteFriends:self];
//        }];
//        [header addSubview:inviteFriends];
//    }
    
    if (icon) {
        UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(titleLabel.frame.origin.x, header.frame.size.height - 11 - 24, 24, 24)];
        iconImageView.image = icon;
        [header addSubview:iconImageView];
        
        CGFloat newTitleLabelX = iconImageView.frame.origin.x + iconImageView.frame.size.width + 8;
        titleLabel.frame = CGRectMake(iconImageView.frame.origin.x + iconImageView.frame.size.width + 8, titleLabel.frame.origin.y, header.frame.size.width - iconImageView.frame.origin.x - newTitleLabelX, titleLabel.frame.size.height);
    }
    
    return header;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {    
    if (section == 0) return CGFLOAT_MIN; //&& self.myCamps.count == 0 && !self.loadingMyCamps) return CGFLOAT_MIN;
    
    return self.lists.count == 0 ? CGFLOAT_MIN : 24;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0 || self.lists.count == 0) return nil;
    
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

@end
