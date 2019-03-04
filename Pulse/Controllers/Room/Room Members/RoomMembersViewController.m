//
//  EditProfileViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "RoomMembersViewController.h"
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

#define section(section) self.tabs[activeTab].sections[section]
#define row(indexPath) section(indexPath.section).rows[indexPath.row]
#define objectExists(index, data) index < data.count

@interface RoomMembersViewController () {
    NSInteger activeTab;
}

@property (strong, nonatomic) HAWebService *manager;
@property (strong, nonatomic) ComplexNavigationController *launchNavVC;
@property (strong, nonatomic) NSMutableArray <SmartList *> *tabs;
@property (strong, nonatomic) NSString *searchPhrase;

@end

@implementation RoomMembersViewController

static NSString * const blankReuseIdentifier = @"BlankCell";
static NSString * const emptySectionCellIdentifier = @"EmptyCell";
static NSString * const loadingSectionCellIdentifier = @"LoadingCell";

static NSString * const memberCellIdentifier = @"MemberCell";
static NSString * const requestCellIdentifier = @"RequestCell";
static NSString * const addManagerCellIdentifier = @"AddManagerCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.tintColor = self.theme;
    
    self.launchNavVC = (ComplexNavigationController *)self.navigationController;
    self.navigationItem.hidesBackButton = true;
    
    self.manager = [HAWebService manager];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    [self.view addSubview:self.tableView];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.backgroundColor = [UIColor headerBackgroundColor];
    self.tableView.separatorColor = [UIColor separatorColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
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
}

- (void)loadJSON {
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"RoomMembers" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:bundlePath];
    
    if (data == nil) return;
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    NSLog(@"json: %@", json);
    
    if (json == nil || ![json objectForKey:@"tabs"]) return;
    
    NSLog(@"json tabs: %@", json[@"tabs"]);
    
    self.tabs = [[NSMutableArray alloc] init];
    for (int i = 0; i < ((NSArray *)json[@"tabs"]).count; i++) {
        SmartList *list = [[SmartList alloc] initWithDictionary:((NSArray *)json[@"tabs"])[i] error:nil];
        
        if ([list.identifier isEqualToString:@"pending"]) {
            // don't include the pending tab if the person isn't a member or the camp is public
            if (![self isMember] || ![self isPrivate]) continue;
        }
        
        [self.tabs addObject:list];
    }
}

- (void)createSegmentedControl {
    self.segmentedControl = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height, self.view.frame.size.width, 48)];
    self.segmentedControl.backgroundColor = [UIColor whiteColor];
    
    UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, self.segmentedControl.frame.size.height, self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    lineSeparator.backgroundColor = [UIColor separatorColor];
    [self.segmentedControl addSubview:lineSeparator];
    [self.view addSubview:self.segmentedControl];
    
    // add segmented control segments
    CGFloat buttonWidth = (self.tabs.count > 3 ? 0 : self.view.frame.size.width / self.tabs.count); // buttonWidth of 0 denotes a dynamic width button
    CGFloat buttonPadding = 10; // only used if the button has a dynamic width
    CGFloat lastButtonX = 0;
    
    for (int i = 0; i < self.tabs.count; i++) {
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
        
        if (i < self.tabs.count - 1) {
            // => not the last tab
            UIView *horizontalSeparator = [[UIView alloc] initWithFrame:CGRectMake(button.frame.size.width - (1 / [UIScreen mainScreen].scale), 14, (1 / [UIScreen mainScreen].scale), 24)];
            horizontalSeparator.backgroundColor = [UIColor separatorColor];
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
    self.shareView.backgroundColor = [UIColor whiteColor];
    self.shareView.clipsToBounds = false;
    [self.view addSubview:self.shareView];
    
    UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, -(1 / [UIScreen mainScreen].scale), self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    lineSeparator.backgroundColor = [UIColor separatorColor];
    [self.shareView addSubview:lineSeparator];
    [self.view addSubview:self.segmentedControl];
    
    self.shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.shareButton.frame = CGRectMake(12, 8, self.view.frame.size.width - (12 * 2), baseHeight - (8 * 2));
    self.shareButton.layer.cornerRadius = 10.f;
    self.shareButton.layer.masksToBounds = true;
    self.shareButton.backgroundColor = self.view.tintColor;
    self.shareButton.adjustsImageWhenHighlighted = false;
    [self.shareButton.titleLabel setFont:[UIFont systemFontOfSize:16.f weight:UIFontWeightBold]];
    [self.shareButton setTitle:@"Share Camp" forState:UIControlStateNormal];
    [self.shareButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.shareButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 0)];
    [self.shareButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 8)];
    [self.shareButton setImage:[UIImage imageNamed:@"shareIcon_small"] forState:UIControlStateNormal];
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
        NSString *url = [NSString stringWithFormat:@"https://joinbonfire.com/camps/%@", self.room.attributes.details.identifier];
        NSString *message = [NSString stringWithFormat:@"Join my Camp on Bonfire! 🔥 %@", url];
        
        // and present it
        UIActivityViewController *controller = [[UIActivityViewController alloc]initWithActivityItems:@[message] applicationActivities:nil];
        controller.modalPresentationStyle = UIModalPresentationPopover;
        [self.navigationController presentViewController:controller animated:YES completion:nil];
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
                [button setTitleColor:self.theme forState:UIControlStateNormal];
            }
            else {
                [button setTitleColor:[UIColor colorWithWhite:0.6 alpha:1] forState:UIControlStateNormal];
            }
        }
        
        [self loadTabData];
    }
}
- (void)loadTabData {
    for (int i = 0; i < self.tabs[activeTab].sections.count; i++) {
        // load each section as needed
        SmartListSection *section = self.tabs[activeTab].sections[i];
        if (section.state == SmartListStateEmpty) {
            // need to load it!
            [self loadDataForSection:section];
        }
        else if (section.state == SmartListStateLoading ||
                 section.state == SmartListStateLoaded) {
            
        }
    }
    
    [self.tableView reloadData];
}

- (void)loadDataForSection:(SmartListSection *)section {
    section.state = SmartListStateLoading;
    
    NSString *baseURL = [section.url stringByReplacingOccurrencesOfString:@"{room.id}" withString:self.room.identifier];
    NSString *url = [NSString stringWithFormat:@"%@/%@%@", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], baseURL];
    
    NSLog(@"final url: %@", url);
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:[NSNumber numberWithInt:10] forKey:@"limit"];
    if (self.searchPhrase && self.searchPhrase.length > 0) {
        [params setObject:self.searchPhrase forKey:@"s"];
    }
    if (section.data.count > 0) {
        // add cursor ish so it pages
        if (section.next_cursor.length > 0) {
            [params setObject:section.next_cursor forKey:@"cursor"];
        }
    }
    
    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            [self.manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSArray *responseData = (NSArray *)responseObject[@"data"];
                
                NSLog(@"response object for requests: %@", responseObject);
                if (!section.data || section.state != SmartListStateLoaded) {
                    section.data = [[NSMutableArray alloc] init];
                    
                    if ([section.identifier isEqualToString:@"members_current"] && [self isMember]) {
                        [section.data addObject:[Session sharedInstance].currentUser];
                    }
                }
                
                section.next_cursor = [NSString stringWithFormat:@"%@", responseObject[@"meta"][@"paging"][@"next_cursor"]];
                NSLog(@"section next cursor ::: %@", section.next_cursor);
                
                [section.data addObjectsFromArray:responseData];
                section.state = SmartListStateLoaded;
                
                [self.tableView reloadData];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"RoomMembersViewController / loadDataForSection(%@) - error: %@", section.identifier, error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                section.state = SmartListStateLoaded;
                [self.tableView reloadData];
            }];
        }
    }];
}

- (BOOL)isMember {
    return [self.room.attributes.context.status isEqualToString:ROOM_STATUS_MEMBER];
}
- (BOOL)isAdmin {
    return self.room.attributes.context.membership.role.identifier == ROOM_ROLE_ADMIN;
}
- (BOOL)isPrivate {
    return self.room.attributes.status.visibility.isPrivate;
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
    
    CGFloat dataRows = self.tabs[activeTab].sections[section].data.count;
    
    if ([s.identifier isEqualToString:@"members_directors"] || [s.identifier isEqualToString:@"members_managers"]) {
        // add directors, add managers cells
        dataRows = dataRows + 1;
    }
    
    return dataRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SmartListSection *s = section(indexPath.section);
    
    if (s.state == SmartListStateEmpty || s.state == SmartListStateLoading) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:loadingSectionCellIdentifier forIndexPath:indexPath];
        
        UIActivityIndicatorView *spinner = [cell viewWithTag:10];
        if (!spinner) {
            spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            spinner.tag = 10;
            [cell.contentView addSubview:spinner];
        }
        
        spinner.center = CGPointMake(cell.frame.size.width / 2, cell.frame.size.height / 2);
        [spinner startAnimating];
        
        return cell;
    }
    else if (s.state == SmartListStateLoaded &&
             objectExists(indexPath.row, s.data)) {
        NSLog(@"YAY!!!!");
        if ([s.identifier isEqualToString:@"members_requests"]) {
            MemberRequestCell *cell = [tableView dequeueReusableCellWithIdentifier:requestCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[MemberRequestCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:requestCellIdentifier];
            }
            
            // member request cell
            User *user = [[User alloc] initWithDictionary:s.data[indexPath.row] error:nil];
            cell.tag = [s.data[indexPath.row][@"id"] integerValue];
            cell.profilePicture.user = user;
            
            cell.textLabel.text = user.attributes.details.displayName;
            cell.textLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@", user.attributes.details.identifier];
            
            [cell.approveButton setTitle:@"Approve" forState:UIControlStateNormal];
            [cell.declineButton setTitle:@"Decline" forState:UIControlStateNormal];
            
            cell.approveButton.layer.borderColor = [UIColor clearColor].CGColor;
            cell.approveButton.layer.borderWidth = 0;
            cell.approveButton.backgroundColor = [UIColor colorWithDisplayP3Red:0.00 green:0.80 blue:0.03 alpha:1.0];
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
            
            // Configure the cell...
            cell.type = 2;
            
            NSLog(@"s.data[@row]: %@", s.data[indexPath.row]);
            
            // member cell
            User *user;
            if ([s.data[indexPath.row] isKindOfClass:[User class]]) {
                user = s.data[indexPath.row];
            }
            else {
                user = [[User alloc] initWithDictionary:s.data[indexPath.row] error:nil];
            }
            cell.profilePicture.user = user;
            
            UIFont *heavyItalicFont = [UIFont fontWithDescriptor:[[[UIFont systemFontOfSize:cell.textLabel.font.pointSize weight:UIFontWeightHeavy] fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic] size:cell.textLabel.font.pointSize];
            cell.textLabel.font = heavyItalicFont;
            cell.textLabel.textColor = [UIColor fromHex:user.attributes.details.color];
            cell.textLabel.text = [NSString stringWithFormat:@"@%@", user.attributes.details.identifier];
            cell.textLabel.alpha = 1;
            cell.detailTextLabel.text = ([user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier] ? @"You" : [NSDate mysqlDatetimeFormattedAsTimeAgo:user.attributes.status.createdAt withForm:TimeAgoLongForm]);
            
            cell.checkIcon.hidden = true;
            
            return cell;
        }
    }
    else if (s.state == SmartListStateLoaded && indexPath.row == s.data.count) {
        if ([s.identifier isEqualToString:@"members_directors"] || [s.identifier isEqualToString:@"members_managers"]) {
            // extra last row
            AddManagerCell *cell = [tableView dequeueReusableCellWithIdentifier:addManagerCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[AddManagerCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:addManagerCellIdentifier];
            }
            
            if ([s.identifier isEqualToString:@"members_directors"]) {
                cell.textLabel.text = @"Add Directors";
            }
            else if ([s.identifier isEqualToString:@"members_managers"]) {
                cell.textLabel.text = @"Add Managers";
            }
            cell.textLabel.textColor = self.view.tintColor;
            
            return cell;
        }
    }
    
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankReuseIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (SmartListSection *)sectionForIdentifier:(NSString *)identifier {
    for (int i = 0; i < self.tabs.count; i++) {
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
    
    NSString *url = [NSString stringWithFormat:@"%@/%@/rooms/%@/members/requests", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], self.room.identifier];
    
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
        
        [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
        [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
            if (success) {
                [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
                [self.manager POST:url parameters:@{@"user_id": request[@"id"]} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    NSLog(@"approved request!");
                    
                    // TODO: set members list back to empty
                    // [self getMembers];
                    SmartListSection *membersSection = [self sectionForIdentifier:@"members_current"];
                    if (membersSection != nil) {
                        membersSection.data = [[NSMutableArray alloc] init]; // reset back to empty
                        membersSection.state = SmartListStateEmpty;
                        membersSection.next_cursor = @"";
                    }
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    NSLog(@"RoomMembersViewController / acceptRequest() - error: %@", error);
                    NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                    NSLog(@"errorResponse: %@", ErrorResponse);
                }];
            }
        }];
    }
}
- (void)declineRequest:(id)sender {
    NSInteger row = ((UITapGestureRecognizer *)sender).view.tag;
    NSLog(@"row: %li", (long)row);
    
    NSString *url = [NSString stringWithFormat:@"%@/%@/rooms/%@/members/requests", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], self.room.identifier];
    
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
        
        [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
        [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
            if (success) {
                [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
                [self.manager DELETE:url parameters:@{@"user_id": request[@"id"]} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    NSLog(@"approved request!");
                    
                    // TODO: set members list back to empty
                    // [self getMembers];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    NSLog(@"RoomMembersViewController / deleteRequest() - error: %@", error);
                    NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                    NSLog(@"errorResponse: %@", ErrorResponse);
                }];
            }
        }];
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat cellHeight = 64;
    
    SmartListSection *s = section(indexPath.section);
    if (s.state == SmartListStateLoaded) {
        if ([s.identifier isEqualToString:@"members_requests"]) {
            // member request cell
            return 106;
        }
        else if (([s.identifier isEqualToString:@"members_directors"] || [s.identifier isEqualToString:@"members_managers"]) && indexPath.row == s.data.count) {
            return cellHeight;
        }
    }
    
    return cellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    // reminder: 110 is height of the empty requests header
    
    SmartListSection *s = section(section);
    
    if ([s.identifier isEqualToString:@"members_requests"] &&
        s.state == SmartListStateLoaded &&
        s.data.count == 0) {
        return 110;
    }
    /* MEMBERS SEARCH CAPABILITY -- currently blocked by backend
    else if ([s.identifier isEqualToString:@"members_current"]) {
        return 52;
    }*/
    
    CGFloat headerHeight = 64;
    
    if (s.title) return headerHeight;
    
    return 0;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    SmartListSection *s = section(section);
    
    if ([s.identifier isEqualToString:@"members_requests"] &&
        s.state == SmartListStateLoaded &&
        s.data.count == 0) {
        // no member requests upsell
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 110)];
        
        UIView *upsell = [[UIView alloc] initWithFrame:CGRectMake(16, 16, header.frame.size.width - 32, 94)];
        upsell.layer.cornerRadius = 10.f;
        upsell.backgroundColor = [UIColor whiteColor];
        upsell.layer.shadowOpacity = 1.f;
        upsell.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
        upsell.layer.shadowRadius = 3.f;
        upsell.layer.shadowOffset = CGSizeMake(0, 1);
        upsell.layer.masksToBounds = false;
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(8, 24, upsell.frame.size.width - 16, 21)];
        title.text = @"No Member Requests";
        title.textColor = [UIColor colorWithWhite:0.2f alpha:1];
        title.textAlignment = NSTextAlignmentCenter;
        title.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightSemibold];
        [upsell addSubview:title];
        
        UIButton *shareWithFriends = [UIButton buttonWithType:UIButtonTypeSystem];
        [shareWithFriends setTitle:@"Invite Friends to Camp" forState:UIControlStateNormal];
        [shareWithFriends setTitleColor:self.theme forState:UIControlStateNormal];
        shareWithFriends.frame = CGRectMake(8, title.frame.origin.y + title.frame.size.height + 6, upsell.frame.size.width - 16, 19);
        shareWithFriends.titleLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightMedium];
        [shareWithFriends bk_whenTapped:^{
            [[Launcher sharedInstance] openInviteFriends:self.room];
        }];
        [upsell addSubview:shareWithFriends];
        
        [header addSubview:upsell];
        
        return header;
    }
    /* MEMBERS SEARCH CAPABILITY -- currently blocked by backend
    else if ([s.identifier isEqualToString:@"members_current"]) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 52)];
        header.backgroundColor = [UIColor whiteColor];
        
        // search view
        BFSearchView *searchView = [[BFSearchView alloc] initWithFrame:CGRectMake(12, 8, self.view.frame.size.width - (12 * 2), 36)];
        searchView.textField.placeholder = @"Search Members";
        [searchView updateSearchText:@""];
        searchView.textField.tintColor = self.view.tintColor;
        [searchView.textField bk_addEventHandler:^(id sender) {
            self.searchPhrase = searchView.textField.text;
            [self loadTabData];
            [self.tableView setContentOffset:CGPointMake(0, 0)];
        } forControlEvents:UIControlEventEditingChanged];
        [header addSubview:searchView];
        
        return header;
    }*/
    
    if (!s.title) return nil;
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 32, self.view.frame.size.width - 32, 21)];
    title.textAlignment = NSTextAlignmentLeft;
    title.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightBold];
    title.textColor = [UIColor colorWithWhite:0.47f alpha:1];
    title.text = (s.title ? [s.title stringByReplacingOccurrencesOfString:@"{members_count}" withString:[NSString stringWithFormat:@"%ld", self.room.attributes.summaries.counts.members]] : @"");
    [header addSubview:title];
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    SmartListSection *s = section(section);
    
    if (s.footer) {
        CGSize labelSize = [s.footer boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 32, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.f weight:UIFontWeightRegular]} context:nil].size;
        
        return labelSize.height + (12 * 2); // 24 padding on top and bottom
    }
    
    return CGFLOAT_MIN;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    SmartListSection *s = section(section);
    
    if (s.footer) {
        UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 90)];
        
        UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, footer.frame.size.width - 32, 42)];
        descriptionLabel.text = s.footer;
        descriptionLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
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
        if (objectExists(indexPath.row, s.data)) {
            // object exists -> all clear from object out of bounds errors
            if ([s.data[indexPath.row] isKindOfClass:[User class]] || ([s.data[indexPath.row] objectForKey:@"type"] && [s.data[indexPath.row][@"type"] isEqualToString:@"user"])) {
                User *user;
                if ([s.data[indexPath.row] isKindOfClass:[User class]]) {
                    user = s.data[indexPath.row];
                }
                else {
                    user = [[User alloc] initWithDictionary:s.data[indexPath.row] error:nil];
                }
                
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:@"%@ (@%@)", user.attributes.details.displayName, user.attributes.details.identifier] preferredStyle:UIAlertControllerStyleActionSheet];
                
                UIAlertAction *viewProfile = [UIAlertAction actionWithTitle:@"View Profile" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [Launcher.sharedInstance openProfile:user];
                }];
                [alertController addAction:viewProfile];
                
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
                [alertController addAction:cancel];
                
                [[Launcher.sharedInstance activeViewController] presentViewController:alertController animated:YES completion:nil];
            }
        }
    }
}

@end
