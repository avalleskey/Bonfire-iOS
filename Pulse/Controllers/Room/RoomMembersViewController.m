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
#import "ButtonCell.h"
#import "ComplexNavigationController.h"
#import "HAWebService.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>

@interface RoomMembersViewController ()

@property (nonatomic) BOOL loadingRequests;
@property (nonatomic) BOOL loadingMembers;

@property (strong, nonatomic) NSMutableArray *requests;
@property (strong, nonatomic) NSMutableArray *members;

@property (strong, nonatomic) HAWebService *manager;
@property (strong, nonatomic) ComplexNavigationController *launchNavVC;

@end

@implementation RoomMembersViewController

static NSString * const blankReuseIdentifier = @"BlankCell";
static NSString * const emptySectionCellIdentifier = @"EmptyCell";

static NSString * const memberCellIdentifier = @"MemberCell";
static NSString * const requestCellIdentifier = @"RequestCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.launchNavVC = (ComplexNavigationController *)self.navigationController;
    self.navigationItem.hidesBackButton = true;
    
    self.manager = [HAWebService manager];
    
    self.members = [[NSMutableArray alloc] initWithArray:@[@{}]];
    self.requests = [[NSMutableArray alloc] initWithArray:@[@{}]];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.backgroundColor = [UIColor headerBackgroundColor];
    self.tableView.separatorColor = [UIColor separatorColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 66, 0, 0);
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 48, 0);
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:emptySectionCellIdentifier];
    
    [self.tableView registerClass:[MemberRequestCell class] forCellReuseIdentifier:requestCellIdentifier];
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:memberCellIdentifier];
    
    // if admin
    if ([self isMember] && [self isPrivate]) {
        self.loadingRequests = true;
        [self getRequests];
    }
    else {
        self.loadingRequests = false;
    }
    
    self.loadingMembers = true;
    [self getMembers];
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

- (void)getRequests {
    NSString *url = [NSString stringWithFormat:@"%@/%@/rooms/%@/members/requests", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], self.room.identifier];
    
    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            [self.manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSArray *responseData = (NSArray *)responseObject[@"data"];
                
                NSLog(@"response data for requests: %@", responseData);
                
                self.requests = [[NSMutableArray alloc] initWithArray:responseData];
                
                self.loadingRequests = false;
                
                [self.tableView reloadData];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"RoomViewController / getRequests() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            }];
        }
    }];
}
- (void)getMembers {
    NSString *url = [NSString stringWithFormat:@"%@/%@/rooms/%@/members", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], self.room.identifier];
    
    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            NSDictionary *params = @{};
            
            NSLog(@"url: %@", url);
            
            [self.manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSArray *responseData = (NSArray *)responseObject[@"data"];
                
                self.members = [[NSMutableArray alloc] initWithArray:responseData];
                
                self.loadingMembers = false;
                
                [self.tableView reloadData];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"RoomViewController / getMembers() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            }];
        }
    }];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if (![self isMember] || !self.room.attributes.status.visibility.isPrivate || self.loadingRequests) return 0;
        
        return self.requests.count;
    }
    else if (section == 1) {
        return self.loadingMembers ? self.room.attributes.summaries.counts.members : self.members.count + ([self isMember] ? 1 : 0);
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (!self.loadingRequests && indexPath.row >= self.requests.count) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:emptySectionCellIdentifier forIndexPath:indexPath];
            
            UILabel *label = [cell viewWithTag:10];
            if (!label) {
                label = [[UILabel alloc] initWithFrame:cell.bounds];
                label.tag = 10;
                label.textAlignment = NSTextAlignmentCenter;
                label.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightMedium];
                label.textColor = [UIColor colorWithWhite:0.6 alpha:1];
                label.text = @"No Requests";
                [cell.contentView addSubview:label];
            }
            
            return cell;
        }
        else {
            MemberRequestCell *cell = [tableView dequeueReusableCellWithIdentifier:requestCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[MemberRequestCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:requestCellIdentifier];
            }
            
            // Configure the cell...
            if (self.loadingRequests) {
                cell.imageView.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1];
                cell.textLabel.text = @"Loading...";
                cell.textLabel.textColor = [UIColor colorWithWhite:0.8f alpha:1];
                cell.detailTextLabel.text = @"";
                
                [cell.approveButton setTitle:@"" forState:UIControlStateNormal];
                [cell.declineButton setTitle:@"" forState:UIControlStateNormal];
                
                cell.approveButton.backgroundColor = [UIColor clearColor];
                cell.approveButton.layer.borderWidth = 1.f;
                cell.approveButton.layer.borderColor = cell.declineButton.layer.borderColor;
                
                cell.approveButton.userInteractionEnabled = false;
                cell.declineButton.userInteractionEnabled = false;
                
                cell.tag = 0;
            }
            else {
                // member cell
                User *user = [[User alloc] initWithDictionary:self.requests[indexPath.row] error:nil];
                cell.tag = [self.requests[indexPath.row][@"id"] integerValue];
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
            }
            
            return cell;
        }
    }
    else if (indexPath.section == 1) {
        SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:memberCellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[SearchResultCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:memberCellIdentifier];
        }
        
        // Configure the cell...
        cell.type = 2;
        
        if (self.loadingMembers) {
            cell.profilePicture.imageView.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1];
            cell.textLabel.text = @"Loading...";
            cell.textLabel.alpha = 0.5;
            cell.detailTextLabel.text = @"";
        }
        else {
            // member cell
            NSInteger adjustedRowIndex = indexPath.row - ([self isMember] ? 1 : 0);
            
            User *user;
            if (indexPath.row == 0 && [self isMember]) {
                user = [Session sharedInstance].currentUser;
            }
            else {
                user = [[User alloc] initWithDictionary:self.members[adjustedRowIndex] error:nil];
            }
            cell.profilePicture.user = user;
            
            cell.textLabel.text = user.attributes.details.displayName != nil ? user.attributes.details.displayName : @"Unkown User";
            cell.textLabel.alpha = 1;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@", user.attributes.details.identifier];
        }
        
        return cell;
    }
    
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankReuseIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (void)approveRequest:(id)sender {
    NSInteger row = ((UITapGestureRecognizer *)sender).view.tag;
    NSLog(@"row: %li", (long)row);
    NSLog(@"self.requests: %@", self.requests);
    
    NSString *url = [NSString stringWithFormat:@"%@/%@/rooms/%@/members/requests", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], self.room.identifier];
    
    NSDictionary *request = self.requests[row];
    [self.requests removeObjectAtIndex:row];
    [self.tableView reloadData];
    
    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            [self.manager POST:url parameters:@{@"user_id": request[@"id"]} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"approved request!");
                
                // refresh members list to include the newly accepted member
                [self getMembers];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"RoomMembersViewController / acceptRequest() - error: %@", error);
                NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                NSLog(@"errorResponse: %@", ErrorResponse);
            }];
        }
    }];
}
- (void)declineRequest:(id)sender {
    NSInteger row = ((UITapGestureRecognizer *)sender).view.tag;
    
    NSString *url = [NSString stringWithFormat:@"%@/%@/rooms/%@/members/requests", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], self.room.identifier];
    
    NSDictionary *request = self.requests[row];
    [self.requests removeObjectAtIndex:row];
    [self.tableView reloadData];
    
    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            [self.manager DELETE:url parameters:@{@"user_id": request[@"id"]} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // declined request success
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"‼️ RoomMembersViewController / declineRequest() - error: %@", error);
                NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                NSLog(@"errorResponse: %@", ErrorResponse);
            }];
        }
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0 ? 106 : 64;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat headerHeight = 64;
    
    if (section == 0 && !self.loadingRequests && [self isMember] && [self isPrivate]) {
        return self.requests.count == 0 ? 110 : headerHeight;
    }
    if (section == 1) return headerHeight;
    
    return 0;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0 && (![self isMember] || ![self isPrivate] || self.loadingRequests)) return nil;
    
    if (section == 0 && self.requests.count == 0) {
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
    else {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 32, self.view.frame.size.width - 32, 21)];
        title.textAlignment = NSTextAlignmentLeft;
        title.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightBold];
        title.textColor = [UIColor colorWithWhite:0.47f alpha:1];
        if (section == 0) {
            NSInteger requests = self.requests.count;
            title.text = [NSString stringWithFormat:@"%ld %@", (long)requests, (requests == 1) ? @"Request" : @"Requests"];
        }
        else if (section == 1) {
            NSInteger members = self.room.attributes.summaries.counts.members;
            title.text = [NSString stringWithFormat:@"%ld %@", (long)members, (members == 1) ? [Session sharedInstance].defaults.room.membersTitle.singular : [Session sharedInstance].defaults.room.membersTitle.plural];
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
        if (indexPath.row < self.requests.count) {
            NSError *error;
            User *user = [[User alloc] initWithDictionary:self.requests[indexPath.row] error:&error];
            
             if (!error) {
                 [[Launcher sharedInstance] openProfile:user];
             }
        }
    }
    else if (indexPath.section == 1) {
        // view user profile
        NSInteger adjustedRowIndex = indexPath.row - ([self isMember] ? 1 : 0);
        if ([self isMember] && indexPath.row == 0) {
            [[Launcher sharedInstance] openProfile:[Session sharedInstance].currentUser];
        }
        else if (adjustedRowIndex < self.members.count) {
            NSError *error;
            User *user = [[User alloc] initWithDictionary:self.members[adjustedRowIndex] error:&error];
            
            [[Launcher sharedInstance] openProfile:user];
        }
    }
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

@end
