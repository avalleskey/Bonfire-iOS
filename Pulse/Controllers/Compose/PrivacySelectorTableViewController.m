//
//  ShareInTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 12/15/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "PrivacySelectorTableViewController.h"
#import "HAWebService.h"
#import "SearchResultCell.h"
#import "Room.h"
#import "Session.h"
#import "NSArray+Clean.h"
#import "BFAvatarView.h"
#import "UIColor+Palette.h"
@import Firebase;

@interface PrivacySelectorTableViewController ()

@property (nonatomic, strong) NSMutableArray *rooms;
@property (nonatomic) BOOL loading;

@end

@implementation PrivacySelectorTableViewController

static NSString * const blankReuseIdentifier = @"BlankCell";
static NSString * const myProfileCellReuseIdentifier = @"MyProfileCell";

static NSString * const roomCellIdentifier = @"RoomCell";
static NSString * const loadingCellIdentifier = @"LoadingCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Share in...";
    
    self.rooms = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"my_rooms_cache"]];
    for (NSInteger i = 0; i < self.rooms.count; i++) {
        if ([self.rooms[i] isKindOfClass:[Room class]]) {
            [self.rooms replaceObjectAtIndex:i withObject:[((Room *)self.rooms[i]) toDictionary]];
        }
    }
    
    self.view.tintColor = [UIColor bonfireBlack];

    if (self.rooms.count == 0) {
        self.loading = true;
        [self getRooms];
    }
    
    [self setupNavigationBar];
    [self setupTableView];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Privacy Selector" screenClass:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)setupNavigationBar {
    self.cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismiss:)];
    [self.cancelButton setTintColor:[UIColor bonfireBlack]];
    [self.cancelButton setTitleTextAttributes:@{
                                                NSFontAttributeName: [UIFont systemFontOfSize:17.f weight:UIFontWeightMedium]
                                                } forState:UIControlStateNormal];
    [self.cancelButton setTitleTextAttributes:@{
                                                NSFontAttributeName: [UIFont systemFontOfSize:17.f weight:UIFontWeightMedium]
                                                } forState:UIControlStateHighlighted];
    self.navigationItem.leftBarButtonItem = self.cancelButton;
}
- (void)setupTableView {
    self.tableView.backgroundColor = [UIColor headerBackgroundColor];
    self.tableView.separatorColor = [UIColor separatorColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:loadingCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:myProfileCellReuseIdentifier];
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:roomCellIdentifier];
}

- (void)getRooms {
    [[HAWebService authenticatedManager] GET:@"users/me/rooms" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSArray *responseData = responseObject[@"data"];
        
        if (responseData.count > 0) {
            self.rooms = [[NSMutableArray alloc] initWithArray:responseData];
            if (self.rooms.count > 1) [self sortRooms];
        }
        else {
            self.rooms = [[NSMutableArray alloc] init];
        }
        
        self.loading = false;
        
        [self.tableView reloadData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"MyRoomsViewController / getRooms() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        [self.tableView reloadData];
    }];
}
- (void)sortRooms {
    if (!self.rooms || self.rooms.count == 0) return;
    
    NSDictionary *opens = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"room_opens"];
    
    for (NSInteger i = 0; i < self.rooms.count; i++) {
        if ([self.rooms[i] isKindOfClass:[NSDictionary class]] && [self.rooms[i] objectForKey:@"id"]) {
            NSMutableDictionary *mutableRoom = [[NSMutableDictionary alloc] initWithDictionary:self.rooms[i]];
            NSString *roomId = mutableRoom[@"id"];
            NSInteger roomOpens = [opens objectForKey:roomId] ? [opens[roomId] integerValue] : 0;
            [mutableRoom setObject:[NSNumber numberWithInteger:roomOpens] forKey:@"opens"];
            [self.rooms replaceObjectAtIndex:i withObject:mutableRoom];
        }
    }
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"opens"
                                                                 ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
    NSArray *sortedArray = [self.rooms sortedArrayUsingDescriptors:sortDescriptors];
    
    self.rooms = [[NSMutableArray alloc] initWithArray:sortedArray];
}

- (void)dismiss:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) return 1;
    if (section == 1) {
        if (self.loading) return 1;
        
        return self.rooms.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:myProfileCellReuseIdentifier forIndexPath:indexPath];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UILabel *label = [cell viewWithTag:10];
        UIImageView *checkIcon = [cell viewWithTag:11];
        if (!label) {
            label = [[UILabel alloc] initWithFrame:CGRectMake(68, 0, self.view.frame.size.width - 68 - 16 - 32, cell.frame.size.height)];
            label.tag = 10;
            label.textAlignment = NSTextAlignmentLeft;
            label.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightBold];
            label.textColor = [UIColor bonfireBlack];
            label.text = @"My Profile";
            [cell.contentView addSubview:label];
            
            // image view
            
            BFAvatarView *imageView = [[BFAvatarView alloc] init];
            imageView.frame = CGRectMake(12, cell.frame.size.height / 2 - 21, 42, 42);
            imageView.user = [Session sharedInstance].currentUser;
            [cell.contentView addSubview:imageView];
            
            checkIcon = [[UIImageView alloc] initWithFrame:CGRectMake(cell.frame.size.width - 16 - 24, cell.frame.size.height / 2 - 12, 24, 24)];
            checkIcon.image = [[UIImage imageNamed:@"tableCellCheckIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            checkIcon.tintColor = self.view.tintColor;
            checkIcon.hidden = true;
            [cell.contentView addSubview:checkIcon];
        }
        checkIcon.hidden = (self.currentSelection != nil);
        
        return cell;
    }
    if (indexPath.section == 1) {
        if (self.loading) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:loadingCellIdentifier forIndexPath:indexPath];
            
            UIActivityIndicatorView *spinner = [cell viewWithTag:20];
            if (!spinner) {
                spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                spinner.center = CGPointMake(cell.frame.size.width / 2, cell.frame.size.height / 2);
                spinner.tag = 20;
                [cell.contentView addSubview:spinner];
            }
            [spinner startAnimating];
            
            return cell;
        }
        else {
            SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:roomCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[SearchResultCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:roomCellIdentifier];
            }
            
            // Configure the cell...
            cell.type = 1;
            
            Room *room = [[Room alloc] initWithDictionary:self.rooms[indexPath.row] error:nil];
            
            cell.textLabel.text = room.attributes.details.title;
            cell.profilePicture.room = room;
            
            NSString *detailText = [NSString stringWithFormat:@"%ld %@", (long)room.attributes.summaries.counts.members, (room.attributes.summaries.counts.members == 1 ? @"member" : @"members")];
            BOOL useLiveCount = room.attributes.summaries.counts.live > [Session sharedInstance].defaults.room.liveThreshold;
            if (useLiveCount) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %li LIVE", detailText, (long)room.attributes.summaries.counts.live];
            }
            cell.detailTextLabel.text = detailText;
            
            cell.tintColor = self.view.tintColor;
            cell.checkIcon.hidden = ![room.identifier isEqualToString:self.currentSelection.identifier];
            cell.checkIcon.tintColor = self.view.tintColor;
            
            return cell;
        }
    }
    
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankReuseIdentifier forIndexPath:indexPath];
    return blankCell;
}
- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            cell.contentView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.04f];
        } completion:nil];
    }
}
- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            cell.contentView.backgroundColor = [UIColor clearColor];
        } completion:nil];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) return 0;
    
    CGFloat headerHeight = 56;
    if (section == 1) return headerHeight;
    
    return 0;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) return nil;
    
    if (section == 1) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(12, 30, self.view.frame.size.width - 24, 18)];
        title.textAlignment = NSTextAlignmentLeft;
        title.font = [UIFont systemFontOfSize:13.f weight:UIFontWeightSemibold];
        title.textColor = [UIColor bonfireGray];
        if (section == 1) {
            if (self.loading || self.rooms.count > 0) title.text = @"MY CAMPS";
            else title.text = @"";
        }
        [header addSubview:title];
        
        return header;
    }
    
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // my profile
        [self.delegate privacySelectionDidChange:nil];
    }
    else if (indexPath.section == 1) {
        // room
        Room *room = [[Room alloc] initWithDictionary:self.rooms[indexPath.row] error:nil];
        [self.delegate privacySelectionDidChange:room];
    }
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
