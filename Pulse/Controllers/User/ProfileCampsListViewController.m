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

@interface ProfileCampsListViewController ()

@property (nonatomic) BOOL loadingCamps;

@property (strong, nonatomic) NSMutableArray *camps;

@property (strong, nonatomic) HAWebService *manager;

@end

@implementation ProfileCampsListViewController

static NSString * const blankReuseIdentifier = @"BlankCell";
static NSString * const emptySectionCellIdentifier = @"EmptyCell";

static NSString * const memberCellIdentifier = @"MemberCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton = true;
    
    self.manager = [HAWebService manager];
    
    self.camps = [[NSMutableArray alloc] initWithArray:@[@{}]];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.backgroundColor = [UIColor headerBackgroundColor];
    self.tableView.separatorColor = [UIColor separatorColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 66, 0, 0);
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 48, 0);
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:emptySectionCellIdentifier];
    
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:memberCellIdentifier];
    
    // if admin
    self.loadingCamps = true;
    [self getCampsList];
}

- (void)getCampsList {
    NSString *url = [NSString stringWithFormat:@"%@/%@/users/%@/rooms", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], self.user.identifier];
    
    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            [self.manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSArray *responseData = (NSArray *)responseObject[@"data"];
                
                NSLog(@"response data for requests: %@", responseData);
                
                self.camps = [[NSMutableArray alloc] initWithArray:responseData];
                
                self.loadingCamps = false;
                
                [self.tableView reloadData];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"RoomViewController / getRequests() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            }];
        }
    }];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if (self.loadingCamps)
            return (self.user.attributes.summaries.counts.rooms == 0 ? 1 : self.user.attributes.summaries.counts.rooms);
        
        return self.camps.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:memberCellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[SearchResultCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:memberCellIdentifier];
        }
        
        // Configure the cell...
        cell.type = SearchResultCellTypeRoom;
        
        if (self.loadingCamps) {
            cell.profilePicture.imageView.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1];
            cell.textLabel.text = @"Loading...";
            cell.textLabel.alpha = 0.5;
            cell.detailTextLabel.text = @"";
        }
        else {
            NSError *error;
            Room *room = [[Room alloc] initWithDictionary:self.camps[indexPath.row] error:&error];
            if (error) { NSLog(@"room error: %@", error); };
            
            // 1 = Room
            cell.profilePicture.room = room;
            cell.textLabel.text = room.attributes.details.title;
            cell.textLabel.alpha = 1;
            
            NSString *detailText = [NSString stringWithFormat:@"%ld %@", (long)room.attributes.summaries.counts.members, (room.attributes.summaries.counts.members == 1 ? [Session sharedInstance].defaults.room.membersTitle.singular : [Session sharedInstance].defaults.room.membersTitle.plural)];
            BOOL useLiveCount = room.attributes.summaries.counts.live > [Session sharedInstance].defaults.room.liveThreshold;
            if (useLiveCount) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %li LIVE", detailText, (long)room.attributes.summaries.counts.live];
            }
            cell.detailTextLabel.text = detailText;
        }
        
        return cell;
    }
    
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankReuseIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat headerHeight = 0; // 64;
    
    if (section == 0 && !self.loadingCamps && self.camps.count == 0)
        return 0;
    
    if (section == 0)
        return headerHeight;
    
    return 0;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
    
    /*
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 32, self.view.frame.size.width - 32, 21)];
    title.textAlignment = NSTextAlignmentLeft;
    title.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightBold];
    title.textColor = [UIColor colorWithWhite:0.47f alpha:1];
    if (section == 0) {
        title.text = @"Camps Joined";
    }
    [header addSubview:title];
    
    return header;*/
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row < self.camps.count) {
            NSError *error;
            Room *room = [[Room alloc] initWithDictionary:self.camps[indexPath.row] error:&error];
            
             if (!error) {
                 [[Launcher sharedInstance] openRoom:room];
             }
        }
    }
}

@end
