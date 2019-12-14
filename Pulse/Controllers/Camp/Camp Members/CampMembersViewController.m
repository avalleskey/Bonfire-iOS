//
//  EditProfileViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "CampMembersViewController.h"
#import "Session.h"
#import "SearchResultCell.h"
#import "MemberRequestCell.h"
#import "AddManagerCell.h"
#import "ButtonCell.h"
#import "ComplexNavigationController.h"
#import "HAWebService.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "SmartList.h"
#import <HapticHelper/HapticHelper.h>
#import "NSDate+NVTimeAgo.h"
#import "AddManagerTableViewController.h"
#import <JGProgressHUD/JGProgressHUD.h>
#import "BFHeaderView.h"
#import "BFAlertController.h"
@import Firebase;

#define section(section) self.tabs[activeTab].sections[section]
#define row(indexPath) section(indexPath.section).rows[indexPath.row]
#define objectExists(index, data) index < data.count

@interface CampMembersViewController () {
    NSInteger activeTab;
}

@property (nonatomic, strong) ComplexNavigationController *launchNavVC;
@property (nonatomic, strong) NSMutableArray <SmartList *> *tabs;

@property (nonatomic, strong) NSString *searchPhrase;
@property (nonatomic, strong) BFSearchView *searchView;

@end

@implementation CampMembersViewController

static NSString * const blankReuseIdentifier = @"BlankCell";
static NSString * const emptySectionCellIdentifier = @"EmptyCell";
static NSString * const loadingSectionCellIdentifier = @"LoadingCell";

static NSString * const memberCellIdentifier = @"MemberCell";
static NSString * const requestCellIdentifier = @"RequestCell";
static NSString * const addManagerCellIdentifier = @"AddManagerCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.tintColor = self.theme;
    
    //self.view.frame = CGRectMake(0, [[UIApplication sharedApplication] delegate].window.safeAreaInsets.top + self.navigationController.navigationBar.frame.size.height, self.view.frame.size.width, [UIScreen mainScreen].bounds.size.height - ([[UIApplication sharedApplication] delegate].window.safeAreaInsets.top + self.navigationController.navigationBar.frame.size.height));
    
    self.launchNavVC = (ComplexNavigationController *)self.navigationController;
    self.navigationItem.hidesBackButton = true;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    [self.view addSubview:self.tableView];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    self.tableView.separatorColor = [UIColor tableViewSeparatorColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 70, 0, 0);
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:emptySectionCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:loadingSectionCellIdentifier];
    
    [self.tableView registerClass:[MemberRequestCell class] forCellReuseIdentifier:requestCellIdentifier];
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:memberCellIdentifier];
    [self.tableView registerClass:[AddManagerCell class] forCellReuseIdentifier:addManagerCellIdentifier];
    
    [self loadJSON];
    [self createSegmentedControl];
    [self createShareView];
    
    activeTab = -1;
    [self tabTappedAtIndex:0];
    
    NSLog(@"self.isAdmin:: %@", [self isAdmin] ? @"YES" : @"NO");
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Camp Members" screenClass:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(campManagersUpdated:) name:@"CampManagersUpdated" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSLog(@"view controller safe area insets:");
    NSLog(@"%f", self.tableView.adjustedContentInset.top);
    
    self.segmentedControl.frame = CGRectMake(0, self.navigationController.navigationBar.frame.size.height + self.navigationController.navigationBar.frame.origin.y, self.view.frame.size.width, 48);
}

- (void)campManagersUpdated:(NSNotification *)notification {
    if (![notification.object objectForKey:@"camp"] || ![notification.object objectForKey:@"type"])
        return;
    
    Camp *camp = [notification.object objectForKey:@"camp"];
    
    NSLog(@"camp managers updated::");
    NSLog(@"%@", camp);
    
    if (camp != nil && [camp.identifier isEqualToString:self.camp.identifier]) {
        [self reloadDataWithTab:@"managers" sectionId:[NSString stringWithFormat:@"members_%@", [notification.object objectForKey:@"type"]]];
    }
}

- (void)loadJSON {
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"CampMembers" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:bundlePath];
    
    if (data == nil) return;
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    NSLog(@"json: %@", json);
    
    if (json == nil || ![json objectForKey:@"tabs"]) return;
    
    NSLog(@"json tabs: %@", json[@"tabs"]);
    
    self.tabs = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < ((NSArray *)json[@"tabs"]).count; i++) {
        SmartList *list = [[SmartList alloc] initWithDictionary:((NSArray *)json[@"tabs"])[i] error:nil];
        
        if ([list.identifier isEqualToString:@"pending"]) {
            // don't include the pending tab if the person isn't a member or the camp is public
            if (![self isMember] || ![self.camp isPrivate]) continue;
        }
        
        [self.tabs addObject:list];
    }
}

- (void)createSegmentedControl {
    self.segmentedControl = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 48)];
    self.segmentedControl.backgroundColor = [UIColor contentBackgroundColor];
    
    UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, self.segmentedControl.frame.size.height, self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
    [self.segmentedControl addSubview:lineSeparator];
    [self.view addSubview:self.segmentedControl];
    
    // add segmented control segments
    CGFloat buttonWidth = (self.tabs.count > 3 ? 0 : self.view.frame.size.width / self.tabs.count); // buttonWidth of 0 denotes a dynamic width button
    CGFloat buttonPadding = 10; // only used if the button has a dynamic width
    CGFloat lastButtonX = 0;
    
    for (NSInteger i = 0; i < self.tabs.count; i++) {
        SmartList *list = self.tabs[i];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = i;
        [button.titleLabel setFont:[UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold]];
        [button setTitle:list.title forState:UIControlStateNormal];
        
        if (buttonWidth == 0) {
            CGFloat buttonTextWidth = ceilf([button.currentTitle boundingRectWithSize:CGSizeMake(self.view.frame.size.width, self.segmentedControl.frame.size.height) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName:button.titleLabel.font} context:nil].size.width);
            button.frame = CGRectMake(lastButtonX, 0, buttonTextWidth + (buttonPadding * 2), self.segmentedControl.frame.size.height);
        }
        else {
            button.frame = CGRectMake(lastButtonX, 0, buttonWidth, self.segmentedControl.frame.size.height);
        }
        
        [button bk_whenTapped:^{
            [HapticHelper generateFeedback:FeedbackType_Selection];
            
            [self.view endEditing:TRUE];
            [self tabTappedAtIndex:button.tag];
        }];
        
        [button bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                button.backgroundColor = [UIColor contentHighlightedColor];
            } completion:nil];
        } forControlEvents:UIControlEventTouchDown];
        [button bk_addEventHandler:^(id sender) {
            [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                button.backgroundColor = [UIColor clearColor];
            } completion:nil];
        } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
        
        if (i < self.tabs.count - 1) {
            // => not the last tab
            UIView *horizontalSeparator = [[UIView alloc] initWithFrame:CGRectMake(button.frame.size.width - (1 / [UIScreen mainScreen].scale), 14, (1 / [UIScreen mainScreen].scale), 24)];
            horizontalSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
            [button addSubview:horizontalSeparator];
        }
        
        [self.segmentedControl addSubview:button];
        
        lastButtonX = button.frame.origin.x + button.frame.size.width;
    }
    
    self.tableView.contentInset = UIEdgeInsetsMake(self.segmentedControl.frame.size.height, 0, self.tableView.contentInset.bottom, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
}
- (void)createShareView {
    CGFloat baseHeight = 56;
    CGFloat height = baseHeight + [[[UIApplication sharedApplication] delegate] window].safeAreaInsets.bottom;
    self.shareView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - height, self.view.frame.size.width, height)];
    self.shareView.backgroundColor = [UIColor contentBackgroundColor];
    self.shareView.clipsToBounds = false;
    [self.view addSubview:self.shareView];
    
    UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, -(1 / [UIScreen mainScreen].scale), self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
    [self.shareView addSubview:lineSeparator];
    [self.view addSubview:self.segmentedControl];
    
    self.shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.shareButton.frame = CGRectMake(12, 8, self.view.frame.size.width - (12 * 2), baseHeight - (8 * 2));
    self.shareButton.layer.cornerRadius = 12.f;
    self.shareButton.layer.masksToBounds = true;
    self.shareButton.backgroundColor = [UIColor fromHex:[UIColor toHex:self.view.tintColor]];
    self.shareButton.adjustsImageWhenHighlighted = false;
    if ([UIColor useWhiteForegroundForColor:self.shareButton.backgroundColor]) {
        self.shareButton.tintColor = [UIColor whiteColor];
        [self.shareButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    else {
        self.shareButton.tintColor = [UIColor blackColor];
        [self.shareButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    [self.shareButton.titleLabel setFont:[UIFont systemFontOfSize:16.f weight:UIFontWeightBold]];
    [self.shareButton setTitle:@"Invite Friends" forState:UIControlStateNormal];
    [self.shareButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 0)];
    [self.shareButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 8)];
    [self.shareButton setImage:[[UIImage imageNamed:@"inviteFriendIcon_small"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.shareButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.shareButton.transform = CGAffineTransformMakeScale(0.92, 0.92);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    [self.shareButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.shareButton.transform = CGAffineTransformIdentity;
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    [self.shareButton bk_whenTapped:^{
        [Launcher shareCamp:self.camp];
    }];
    [self.shareView addSubview:self.shareButton];
    
    self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, self.tableView.contentInset.left, baseHeight, self.tableView.contentInset.right);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
}

- (void)tabTappedAtIndex:(NSInteger)tabIndex {
    if (tabIndex != activeTab) {
        activeTab = tabIndex;
        self.searchPhrase = @""; // reset search phrase
        
        for (UIButton *button in self.segmentedControl.subviews) {
            if (![button isKindOfClass:[UIButton class]]) continue;
            
            if (button.tag == tabIndex) {
                [button setTitleColor:[UIColor fromHex:[UIColor toHex:self.view.tintColor] adjustForOptimalContrast:true] forState:UIControlStateNormal];
                button.titleLabel.font = [UIFont systemFontOfSize:button.titleLabel.font.pointSize weight:UIFontWeightBold];
            }
            else {
                [button setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateNormal];
                button.titleLabel.font = [UIFont systemFontOfSize:button.titleLabel.font.pointSize weight:UIFontWeightSemibold];
            }
        }
        
        [self loadTabData:false];
    }
}
- (void)loadTabData:(BOOL)forceRefresh {
    for (NSInteger i = 0; i < self.tabs[activeTab].sections.count; i++) {
        // load each section as needed
        SmartListSection *section = self.tabs[activeTab].sections[i];
        if (section.state == SmartListStateEmpty || forceRefresh) {
            // need to load it!
            [self loadDataForSection:section cursorType:StreamPagingCursorTypeNone];
        }
        else if (section.state == SmartListStateLoading ||
                 section.state == SmartListStateLoaded) {
            
        }
    }
    
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    [self.tableView reloadData];
}
- (void)reloadDataWithTab:(NSString *)tabId sectionId:(NSString *)sectionId {
    for (SmartListSection *section in [self tabForIdentifier:tabId].sections) {
        if ([section.identifier isEqualToString:sectionId]) {
            section.state = SmartListStateLoading;
            section.data = [[NSMutableArray alloc] init];
            
            [self.tableView reloadData];
            [self loadDataForSection:section cursorType:StreamPagingCursorTypeNone];
        }
    }
}
- (void)loadMoreDataForSection:(SmartListSection *)section {
    section.state = SmartListStateLoadingMore;
    [self loadDataForSection:section cursorType:StreamPagingCursorTypeNext];
}

- (void)loadDataForSection:(SmartListSection *)section cursorType:(StreamPagingCursorType)cursorType {
    if (cursorType == StreamPagingCursorTypeNone) {
        section.state = SmartListStateLoading;
        [self.tableView reloadData];
    }
    
    NSString *url = [section.url stringByReplacingOccurrencesOfString:@"{camp.id}" withString:self.camp.identifier];
    
    NSLog(@"final url: %@", url);
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (self.searchPhrase && self.searchPhrase.length > 0) {
        [params setObject:self.searchPhrase forKey:@"s"];
    }
    
    NSString *nextCursor = [section.userStream nextCursor];
    if (cursorType == StreamPagingCursorTypeNext && nextCursor.length > 0) {
        if ([section.userStream hasLoadedCursor:nextCursor]) {
            return;
        }
        
        [section.userStream addLoadedCursor:nextCursor];
        [params setObject:nextCursor forKey:@"cursor"];
    }
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (section.cursored) {
            if ([section.type isEqualToString:SmartListSectionDataTypeUser]) {
                if (!section.userStream) {
                    section.userStream = [[UserListStream alloc] init];
                }
                
                UserListStreamPage *page = [[UserListStreamPage alloc] initWithDictionary:responseObject error:nil];
                if (cursorType == StreamPagingCursorTypePrevious) {
                    [section.userStream prependPage:page];
                }
                else {
                    [section.userStream appendPage:page];
                }
            }
            else if ([section.type isEqualToString:SmartListSectionDataTypeCamp]) {
                if (!section.campStream) {
                    section.campStream = [[CampListStream alloc] init];
                }
                
                CampListStreamPage *page = [[CampListStreamPage alloc] initWithDictionary:responseObject error:nil];
                if (cursorType == StreamPagingCursorTypePrevious) {
                    [section.campStream prependPage:page];
                }
                else {
                    [section.campStream appendPage:page];
                }
            }
        }
        else {
            NSArray *responseData = (NSArray *)responseObject[@"data"];
            
            NSLog(@"response object for requests: %@", responseObject);
            if (!section.data || section.state != SmartListStateLoaded) {
                section.data = [[NSMutableArray alloc] init];
            }
            
            [section.data addObjectsFromArray:responseData];
        }

        section.state = SmartListStateLoaded;
        
        [self.tableView reloadData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"CampMembersViewController / loadDataForSection(%@) - error: %@", section.identifier, error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        section.state = SmartListStateLoaded;
        [self.tableView reloadData];
    }];
}

- (BOOL)isMember {
    return [self.camp.attributes.context.camp.status isEqualToString:CAMP_STATUS_MEMBER];
}
- (BOOL)isAdmin {
    return [self.camp.attributes.context.camp.membership.role.type isEqualToString:CAMP_ROLE_ADMIN];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (activeTab >= self.tabs.count) {
        return 0;
    }
    
    return self.tabs[activeTab].sections.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    SmartListSection *s = section(section);
    
    if (s.state == SmartListStateEmpty || s.state == SmartListStateLoading) {
        return 1;
    }
    
    // section loaded
    if (section >= self.tabs[activeTab].sections.count) {
        // prevent trying to load data from a section that doesn't exist
        return 0;
    }
    
    CGFloat dataRows = 0;
    if (s.cursored) {
        if ([s.type isEqualToString:SmartListSectionDataTypeUser]) {
            dataRows = s.userStream.users.count + (s.userStream.nextCursor.length > 0 ? 1 : 0);
        }
        else if ([s.type isEqualToString:SmartListSectionDataTypeCamp]) {
            dataRows = s.campStream.camps.count + (s.campStream.nextCursor.length > 0 ? 1 : 0);
        }
    }
    else {
        dataRows = self.tabs[activeTab].sections[section].data.count;
    }
    
    
    if ([s.identifier isEqualToString:@"members_admin"] || [s.identifier isEqualToString:@"members_moderator"]) {
        // add directors, add managers cells
        if (dataRows == 0) {
            dataRows = 1; // display "This camp has no ____s"
        }
        
        if ([s.identifier isEqualToString:@"members_admin"]) {
            dataRows = dataRows + [self.camp.attributes.context.camp.permissions.assign containsObject:CAMP_ROLE_ADMIN];
        }
        else if ([s.identifier isEqualToString:@"members_moderator"]) {
            dataRows = dataRows + [self.camp.attributes.context.camp.permissions.assign containsObject:CAMP_ROLE_MODERATOR];
        }
    }
    
    return dataRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SmartListSection *s = section(indexPath.section);
    
    if (s.state == SmartListStateEmpty || s.state == SmartListStateLoading || // empty
        (s.cursored && s.userStream.nextCursor.length > 0 && indexPath.row == s.userStream.users.count)) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:loadingSectionCellIdentifier forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.contentView.backgroundColor = [UIColor contentBackgroundColor];
        
        UIActivityIndicatorView *spinner = [cell viewWithTag:10];
        if (!spinner) {
            spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            spinner.color = [UIColor bonfireSecondaryColor];
            spinner.tag = 10;
            [cell.contentView addSubview:spinner];
        }
        
        spinner.center = CGPointMake(cell.frame.size.width / 2, cell.frame.size.height / 2);
        [spinner startAnimating];
        
        return cell;
    }
    else if (s.state == SmartListStateLoaded &&
             (objectExists(indexPath.row, s.data) || objectExists(indexPath.row, s.userStream.users))) {
        if ([s.identifier isEqualToString:@"members_requests"]) {
            MemberRequestCell *cell = [tableView dequeueReusableCellWithIdentifier:requestCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[MemberRequestCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:requestCellIdentifier];
            }
            
            // member request cell
            User *user = [[User alloc] initWithDictionary:s.data[indexPath.row] error:nil];
            cell.tag = [s.data[indexPath.row][@"id"] integerValue];
            cell.profilePicture.user = user;
            
            cell.textLabel.text = user.attributes.displayName;
            cell.textLabel.textColor = [UIColor bonfirePrimaryColor];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@", user.attributes.identifier];
            
            [cell.approveButton setTitle:@"Approve" forState:UIControlStateNormal];
            [cell.declineButton setTitle:@"Decline" forState:UIControlStateNormal];
            
            cell.approveButton.tag = indexPath.row;
            
            UITapGestureRecognizer *approveTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(approveRequest:)];
            [approveTap setNumberOfTapsRequired:1];
            [cell.approveButton addGestureRecognizer:approveTap];
            
            UITapGestureRecognizer *declineTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(declineRequest:)];
            [declineTap setNumberOfTapsRequired:1];
            [cell.declineButton addGestureRecognizer:declineTap];
            
            cell.approveButton.userInteractionEnabled = true;
            cell.declineButton.userInteractionEnabled = true;
            
            return cell;
        }
        else {
            SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:memberCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[SearchResultCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:memberCellIdentifier];
            }
            
            // member cell
            User *user;
            
            if (s.cursored) {
                user = s.userStream.users[indexPath.row];
            }
            else {
                if ([s.data[indexPath.row] isKindOfClass:[User class]]) {
                    user = s.data[indexPath.row];
                }
                else {
                    user = [[User alloc] initWithDictionary:s.data[indexPath.row] error:nil];
                }
            }
            
            cell.profilePicture.user = user;
            
            NSMutableAttributedString *attributedCreatorName = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", user.attributes.displayName] attributes:@{NSForegroundColorAttributeName: [UIColor bonfirePrimaryColor], NSFontAttributeName: [UIFont systemFontOfSize:cell.textLabel.font.pointSize weight:UIFontWeightSemibold]}];
            NSAttributedString *usernameString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" @%@", user.attributes.identifier] attributes:@{NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor], NSFontAttributeName: [UIFont systemFontOfSize:cell.textLabel.font.pointSize weight:UIFontWeightRegular]}];
            [attributedCreatorName appendAttributedString:usernameString];
            
            cell.textLabel.attributedText = attributedCreatorName;
            cell.textLabel.alpha = 1;
            cell.detailTextLabel.text = ([user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier] ? @"You" : [NSString stringWithFormat:@"Joined %@", [NSDate mysqlDatetimeFormattedAsTimeAgo:user.attributes.context.camp.membership.joinedAt withForm:TimeAgoLongForm]]);
            
            cell.checkIcon.hidden = true;
            
            return cell;
        }
    }
    else if (s.state == SmartListStateLoaded &&
             s.data.count == 0 &&
             indexPath.row == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:emptySectionCellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:emptySectionCellIdentifier];
        }
        
        cell.backgroundColor = [UIColor contentBackgroundColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.separatorInset = UIEdgeInsetsZero;
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.frame = cell.bounds;
        cell.textLabel.textColor = [UIColor bonfireSecondaryColor];
        cell.textLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
        
        if ([s.identifier isEqualToString:@"members_admin"]) {
            cell.textLabel.text = @"This Camp has no directors";
        }
        else if ([s.identifier isEqualToString:@"members_moderator"]) {
            cell.textLabel.text = @"This Camp has no managers";
        }
        
        return cell;
    }
    else if (s.state == SmartListStateLoaded && indexPath.row == [self.tableView numberOfRowsInSection:indexPath.section]-1) {
        if ([s.identifier isEqualToString:@"members_admin"] || [s.identifier isEqualToString:@"members_moderator"]) {
            // extra last row
            AddManagerCell *cell = [tableView dequeueReusableCellWithIdentifier:addManagerCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[AddManagerCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:addManagerCellIdentifier];
            }
            
            if ([s.identifier isEqualToString:@"members_admin"]) {
                cell.textLabel.text = @"Add Directors";
            }
            else if ([s.identifier isEqualToString:@"members_moderator"]) {
                cell.textLabel.text = @"Add Managers";
            }
            cell.textLabel.textColor = [UIColor fromHex:[UIColor toHex:self.view.tintColor] adjustForOptimalContrast:true];
            cell.imageView.tintColor = cell.textLabel.textColor;
            
            return cell;
        }
    }
    
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankReuseIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    SmartListSection *s = section(indexPath.section);
    
    if (s.cursored) {
        BOOL hasNextPage = (s.userStream.users.count > 0 && s.userStream.nextCursor.length > 0);
        if (hasNextPage && indexPath.row == s.userStream.users.count) {
            // last row is now visible -> start loading if not already
            if (s.state == SmartListStateLoaded) {
                [self loadMoreDataForSection:s];
            }
        }
    }
}

- (SmartList *)tabForIdentifier:(NSString *)identifier {
    for (NSInteger i = 0; i < self.tabs.count; i++) {
        SmartList *tab = self.tabs[i];
        if ([tab.identifier isEqualToString:identifier]) {
            return tab;
        }
    }
    
    return nil;
}

- (SmartListSection *)sectionForIdentifier:(NSString *)identifier {
    for (NSInteger i = 0; i < self.tabs.count; i++) {
        SmartList *tab = self.tabs[i];
        for (int x = 0; x < tab.sections.count; x++) {
            SmartListSection *section = tab.sections[x];
            if ([section.identifier isEqualToString:identifier]) {
                return section;
            }
        }
    }
    
    return nil;
}

- (void)approveRequest:(id)sender {
    NSInteger row = ((UITapGestureRecognizer *)sender).view.tag;
    NSLog(@"row: %li", (long)row);
    
    NSString *url = [NSString stringWithFormat:@"camps/%@/members/requests", self.camp.identifier];
    
    NSDictionary *request = nil;
    SmartListSection *requestsSection = [self sectionForIdentifier:@"members_requests"];
    if (requestsSection == nil) return;
    
    if (objectExists(row, requestsSection.data)) {
        request = requestsSection.data[row];
        [requestsSection.data removeObjectAtIndex:row];
    }
    
    NSLog(@"request to approve: %@", request);
    
    if (request != nil) {
        [self.tableView reloadData];
        
        [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] POST:url parameters:@{@"user_id": request[@"id"]} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"approved request!");
            
            // TODO: set members list back to empty
            // [self getMembers];
            SmartListSection *membersSection = [self sectionForIdentifier:@"members_current"];
            if (membersSection != nil) {
                membersSection.data = [[NSMutableArray alloc] init]; // reset back to empty
                membersSection.state = SmartListStateEmpty;
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        }];
    }
}
- (void)declineRequest:(id)sender {
    NSInteger row = ((UITapGestureRecognizer *)sender).view.tag;
    NSLog(@"row: %li", (long)row);
    
    NSString *url = [NSString stringWithFormat:@"camps/%@/members/requests", self.camp.identifier];
    
    NSDictionary *request = nil;
    SmartListSection *requestsSection = [self sectionForIdentifier:@"members_requests"];
    if (requestsSection == nil) return;
    
    if (objectExists(row, requestsSection.data)) {
        request = requestsSection.data[row];
        [requestsSection.data removeObjectAtIndex:row];
    }
    
    NSLog(@"request to decline: %@", request);
    
    if (request != nil) {
        [self.tableView reloadData];
        
        [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] DELETE:url parameters:@{@"user_id": request[@"id"]} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"declined request!");
            
            // TODO: set members list back to empty
            // [self getMembers];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        }];
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    SmartListSection *s = section(indexPath.section);
    if (s.state == SmartListStateLoaded) {
        if ([s.identifier isEqualToString:@"members_requests"]) {
            // member request cell
            return 106;
        }
        else if (([s.identifier isEqualToString:@"members_admin"] || [s.identifier isEqualToString:@"members_moderator"]) && s.data.count == 0 && indexPath.row == 0) {
            return 96;
        }
    }
    
    return 68;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    // reminder: 110 is height of the empty requests header
    
    SmartListSection *s = section(section);
    
    if ([s.identifier isEqualToString:@"members_requests"] &&
        s.state == SmartListStateLoaded &&
        s.data.count == 0) {
        return 110;
    }
    else if ([s.identifier isEqualToString:@"members_current"] && (self.searchPhrase.length > 0 || [self.tableView numberOfRowsInSection:0] > 100000)) {
        return 56;
    }
    
    if (s.title) return [BFHeaderView height];
    
    return 0;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    SmartListSection *s = section(section);
    
    if ([s.identifier isEqualToString:@"members_requests"] &&
        s.state == SmartListStateLoaded &&
        s.data.count == 0) {
        // no member requests upsell
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 110)];
        
        UIView *upsell = [[UIView alloc] initWithFrame:CGRectMake(12, 16, header.frame.size.width - 24, 94)];
        upsell.layer.cornerRadius = 10.f;
        upsell.backgroundColor = [UIColor cardBackgroundColor];
        upsell.layer.shadowOpacity = 1.f;
        upsell.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
        upsell.layer.shadowRadius = 2.f;
        upsell.layer.shadowOffset = CGSizeMake(0, 1);
        upsell.layer.masksToBounds = false;
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(8, 24, upsell.frame.size.width - 16, 21)];
        title.text = @"No Member Requests";
        title.textColor = [UIColor bonfirePrimaryColor];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightSemibold];
        [upsell addSubview:title];
        
        UIButton *shareWithFriends = [UIButton buttonWithType:UIButtonTypeSystem];
        [shareWithFriends setTitle:[NSString stringWithFormat:@"Share %@", self.camp.attributes.title] forState:UIControlStateNormal];
        [shareWithFriends setTitleColor:[UIColor fromHex:[UIColor toHex:self.view.tintColor] adjustForOptimalContrast:true] forState:UIControlStateNormal];
        shareWithFriends.frame = CGRectMake(8, title.frame.origin.y + title.frame.size.height + 6, upsell.frame.size.width - 16, 19);
        shareWithFriends.titleLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightMedium];
        [shareWithFriends bk_whenTapped:^{
            [Launcher shareCamp:self.camp];
            //[Launcher openInviteFriends:self.camp];
        }];
        [upsell addSubview:shareWithFriends];
        
        [header addSubview:upsell];
        
        return header;
    }
    else if ([s.identifier isEqualToString:@"members_current"] && (self.searchPhrase.length > 0 || [self.tableView numberOfRowsInSection:0] > 100000)) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 56)];
        header.backgroundColor = [UIColor whiteColor];
        
        // search view
        self.searchView = [[BFSearchView alloc] initWithFrame:CGRectMake(12, 10, self.view.frame.size.width - (12 * 2), 36)];
        self.searchView.placeholder = @"Search Members";
        [self.searchView updateSearchText:self.searchPhrase];
        self.searchView.textField.tintColor = self.view.tintColor;
        self.searchView.textField.delegate = self;
        [self.searchView.textField bk_addEventHandler:^(id sender) {
            self.searchPhrase = self.searchView.textField.text;
            
            [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
            [self loadTabData:true];
            [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
        } forControlEvents:UIControlEventEditingChanged];
        [header addSubview:self.searchView];
        
        UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, header.frame.size.width, HALF_PIXEL)];
        separator.backgroundColor = [UIColor tableViewSeparatorColor];
        [header addSubview:separator];
        
        return header;
    }
    
    if (!s.title) return nil;
    
    BFHeaderView *header = [[BFHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [BFHeaderView height])];
    
    header.title = (s.title ? [s.title stringByReplacingOccurrencesOfString:@"{members_count}" withString:[NSString stringWithFormat:@"%ld", self.camp.attributes.summaries.counts.members]] : @"");
    header.bottomLineSeparator.hidden = true;
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    SmartListSection *s = section(section);
    
    if (s.footer) {
        CGSize labelSize = [s.footer boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 24, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.f weight:UIFontWeightRegular]} context:nil].size;
        
        return labelSize.height + (12 * 2); // 24 padding on top and bottom
    }
    
    return CGFLOAT_MIN;
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

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    SmartListSection *s = section(section);
    
    if (s.footer) {
        UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 90)];
        
        UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, footer.frame.size.width - 24, 42)];
        descriptionLabel.text = s.footer;
        descriptionLabel.textColor = [UIColor bonfireSecondaryColor];
        descriptionLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightRegular];
        descriptionLabel.textAlignment = NSTextAlignmentLeft;
        descriptionLabel.numberOfLines = 0;
        descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        CGSize labelSize = [descriptionLabel.text boundingRectWithSize:CGSizeMake(descriptionLabel.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:descriptionLabel.font} context:nil].size;
        descriptionLabel.frame = CGRectMake(descriptionLabel.frame.origin.x, descriptionLabel.frame.origin.y, descriptionLabel.frame.size.width, labelSize.height);
        [footer addSubview:descriptionLabel];
        
        footer.frame = CGRectMake(0, 0, footer.frame.size.width, descriptionLabel.frame.size.height + (descriptionLabel.frame.origin.y*2));
        
        return footer;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[SearchResultCell class]] ||
        [[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[MemberRequestCell class]]) {
        SmartListSection *s = section(indexPath.section);
        
        if (!(objectExists(indexPath.row, s.data) || objectExists(indexPath.row, s.userStream.users))) {
            return;
        }
        
        User *user;
        if (s.cursored) {
            if ([s.type isEqualToString:SmartListSectionDataTypeUser]) {
                user = s.userStream.users[indexPath.row];
            }
        }
        else {
            if ([s.data[indexPath.row] isKindOfClass:[User class]]) {
                user = s.data[indexPath.row];
            }
            else {
                user = [[User alloc] initWithDictionary:s.data[indexPath.row] error:nil];
            }
        }
        
        if (user) {
            if ([self isAdmin]) {
                BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:user.attributes.displayName message:[@"@" stringByAppendingString:user.attributes.identifier] preferredStyle:BFAlertControllerStyleActionSheet];
                
                BFAlertAction *viewProfile = [BFAlertAction actionWithTitle:@"View Profile" style:BFAlertActionStyleDefault handler:^{
                    [Launcher openProfile:user];
                }];
                [actionSheet addAction:viewProfile];
      
                if ([s.identifier isEqualToString:@"members_admin"] || [s.identifier isEqualToString:@"members_moderator"]) {
                    BFAlertAction *removeRole = [BFAlertAction actionWithTitle:[NSString stringWithFormat:@"Remove as %@", [s.identifier isEqualToString:@"members_admin"] ? @"Director" : @"Manager"] style:BFAlertActionStyleDefault handler:^{
                        if ([s.identifier isEqualToString:@"members_admin"]) {
                            [self removeManagerRole:CAMP_ROLE_ADMIN user:user];
                        }
                        else {
                            [self removeManagerRole:CAMP_ROLE_MODERATOR user:user];
                        }
                    }];
                    [actionSheet addAction:removeRole];
                }
                
                BFAlertAction *cancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
                [actionSheet addAction:cancel];
                
                [[Launcher topMostViewController] presentViewController:actionSheet animated:true completion:nil];
            }
            else {
                [Launcher openProfile:user];
            }
        }
    }
    else if ([[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[AddManagerCell class]]) {
        AddManagerTableViewController *addManagerTableVC = [[AddManagerTableViewController alloc] init];
        addManagerTableVC.camp = self.camp;
        addManagerTableVC.managerType = ([section(indexPath.section).identifier isEqualToString:@"members_admin"] ? @"admin" : @"moderator");
        
        SimpleNavigationController *navController = [[SimpleNavigationController alloc] initWithRootViewController:addManagerTableVC];
        navController.transitioningDelegate = [Launcher sharedInstance];
        navController.modalPresentationStyle = UIModalPresentationFullScreen;
        navController.currentTheme = [UIColor clearColor];
        
        [[Launcher topMostViewController] presentViewController:navController animated:YES completion:nil];
    }
}

- (void)removeManagerRole:(NSString *)managerType user:(User *)user {
    NSString *url = [NSString stringWithFormat:@"camps/%@/members/roles", self.camp.identifier];
    
    // create the group
    JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
    HUD.textLabel.text = [NSString stringWithFormat:@"Removing as %@...", ([managerType isEqualToString:CAMP_ROLE_ADMIN] ? @"Director" : @"Manager")];
    HUD.vibrancyEnabled = false;
    HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
    HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
    [HUD showInView:self.navigationController.view animated:YES];
    
    NSDictionary *params = @{@"user_id": user.identifier, @"role": @"member"};
    
    NSLog(@"params: %@", params);
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        // on the completion of each request
        NSLog(@"success!");
        HUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
        HUD.textLabel.text = [NSString stringWithFormat:@"Removed"];
        
        [HUD dismissAfterDelay:1.f];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CampManagersUpdated" object:@{@"camp": self.camp, @"type": managerType}];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        // on the completion of each request
        NSLog(@"all requests finished!");
        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"error response: %@", ErrorResponse);
        
        HUD.indicatorView = [[JGProgressHUDErrorIndicatorView alloc] init];
        HUD.textLabel.text = [NSString stringWithFormat:@"Error Removing Role"];
        
        [HUD dismissAfterDelay:1.f];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CampManagersUpdated" object:@{@"camp": self.camp, @"type": managerType}];
    }];
}

@end
