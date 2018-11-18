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
#import "LauncherNavigationViewController.h"
#import "HAWebService.h"
#import "Launcher.h"

#define envConfig [[[NSUserDefaults standardUserDefaults] objectForKey:@"config"] objectForKey:[[NSUserDefaults standardUserDefaults] stringForKey:@"environment"]]

@interface RoomMembersViewController ()

@property (nonatomic) BOOL loadingRequests;
@property (nonatomic) BOOL loadingMembers;

@property (strong, nonatomic) NSMutableArray *requests;
@property (strong, nonatomic) NSMutableArray *members;

@property (strong, nonatomic) HAWebService *manager;
@property (strong, nonatomic) LauncherNavigationViewController *launchNavVC;

@end

@implementation RoomMembersViewController

static NSString * const blankReuseIdentifier = @"BlankCell";
static NSString * const emptySectionCellIdentifier = @"EmptyCell";

static NSString * const memberCellIdentifier = @"MemberCell";
static NSString * const requestCellIdentifier = @"RequestCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.launchNavVC = (LauncherNavigationViewController *)self.navigationController;
    
    self.manager = [HAWebService manager];
    
    self.members = [[NSMutableArray alloc] initWithArray:@[@{}]];
    self.requests = [[NSMutableArray alloc] initWithArray:@[@{}]];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 48, 0);
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:emptySectionCellIdentifier];
    
    [self.tableView registerClass:[MemberRequestCell class] forCellReuseIdentifier:requestCellIdentifier];
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:memberCellIdentifier];
    
    // if admin
    if ([self isMember]) {
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
    return self.room.attributes.context.status == STATUS_MEMBER;
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
                
                NSLog(@"response dataaaaa: %@", responseData);
                
                self.requests = [[NSMutableArray alloc] initWithArray:responseData];
                
                self.loadingRequests = false;
                
                [self.tableView beginUpdates];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 1)] withRowAnimation:UITableViewRowAnimationNone];
                [self.tableView endUpdates];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"RoomViewController / getMembers() - error: %@", error);
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
            NSLog(@"authenticated now lets go");
            
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            NSDictionary *params = @{};
            
            NSLog(@"url: %@", url);
            
            [self.manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSArray *responseData = (NSArray *)responseObject[@"data"];
                
                NSLog(@"response dataaaaa: %@", responseData);
                
                self.members = [[NSMutableArray alloc] initWithArray:responseData];
                
                self.loadingMembers = false;
                
                [self.tableView beginUpdates];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 1)] withRowAnimation:UITableViewRowAnimationNone];
                [self.tableView endUpdates];
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
        return [self isMember] ? (self.loadingRequests ? 1 : (self.requests.count > 0 ? : 1)) : 0;
    }
    else if (section == 1) {
        return self.members.count + 1;
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
                cell.tag = self.requests[indexPath.row][@"id"];
                
                cell.imageView.backgroundColor = [UIColor whiteColor];
                cell.imageView.image = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.imageView.tintColor = [self colorFromHexString:[[user.attributes.details.color lowercaseString] isEqualToString:@"ffffff"]?@"222222":user.attributes.details.color];
                cell.textLabel.text = user.attributes.details.displayName;
                cell.textLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@", [user.attributes.details.identifier uppercaseString]];
                
                [cell.approveButton setTitle:@"Approve" forState:UIControlStateNormal];
                [cell.declineButton setTitle:@"Decline" forState:UIControlStateNormal];
                
                cell.approveButton.layer.borderColor = [UIColor clearColor].CGColor;
                cell.approveButton.layer.borderWidth = 0;
                cell.approveButton.backgroundColor = [UIColor colorWithDisplayP3Red:0.00 green:0.80 blue:0.03 alpha:1.0];
                
                cell.approveButton.userInteractionEnabled = true;
                cell.declineButton.userInteractionEnabled = true;
            }
            
            if (indexPath.row == 0) {
                // last row
                cell.lineSeparator.hidden = true;
            }
            else {
                cell.lineSeparator.hidden = false;
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
            cell.imageView.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1];
            cell.textLabel.text = @"Loading...";
            cell.textLabel.textColor = [UIColor colorWithWhite:0.8f alpha:1];
            cell.detailTextLabel.text = @"";
        }
        else {
            if (indexPath.row == self.room.attributes.summaries.counts.members) {
                // invite others
                cell.textLabel.textColor = self.theme;
                cell.textLabel.text = @"Invite Others";
                cell.imageView.image = [[UIImage imageNamed:@"inviteFriendPlaceholder"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.imageView.backgroundColor = [UIColor clearColor];
                cell.imageView.tintColor = cell.textLabel.textColor;
                cell.detailTextLabel.text = @"";
            }
            else {
                // member cell
                User *user = [[User alloc] initWithDictionary:self.members[indexPath.row] error:nil];
                
                cell.imageView.backgroundColor = [UIColor whiteColor];
                cell.imageView.image = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.imageView.tintColor = [self colorFromHexString:[[user.attributes.details.color lowercaseString] isEqualToString:@"ffffff"]?@"222222":user.attributes.details.color];
                cell.textLabel.text = user.attributes.details.displayName != nil ? user.attributes.details.displayName : @"Unkown User";
                cell.textLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@", [user.attributes.details.identifier uppercaseString]];
            }
        }
        
        if (indexPath.row == (self.room.attributes.summaries.counts.members)) {
            // last row
            cell.lineSeparator.hidden = true;
        }
        else {
            cell.lineSeparator.hidden = false;
        }
        
        return cell;
    }
    
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankReuseIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0 ? 98 : 56;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0 && [self isMember]) return 64;
    if (section == 1) return 64;
    
    return 0;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0 && ![self isMember]) return nil;
    
    UIView *headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
    [headerContainer addSubview:header];
    
    header.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 28, self.view.frame.size.width - 62 - 200, 24)];
    if (section == 0) { title.text = @"Requests"; }
    else if (section == 1) {
        NSInteger members = self.room.attributes.summaries.counts.members;
        title.text = [NSString stringWithFormat:@"%ld %@", (long)members, (members == 1) ? [Session sharedInstance].defaults.room.membersTitle.singular : [Session sharedInstance].defaults.room.membersTitle.plural];
    }
    title.textAlignment = NSTextAlignmentLeft;
    title.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold];
    title.textColor = [UIColor colorWithWhite:0.6f alpha:1];
    
    [header addSubview:title];
    
    UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, header.frame.size.height - (1 / [UIScreen mainScreen].scale), self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    lineSeparator.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    [header addSubview:lineSeparator];
    
    return headerContainer;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return (1 / [UIScreen mainScreen].scale);
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    separator.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    return separator;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row < self.requests.count) {
            NSError *error;
            User *user = [[User alloc] initWithDictionary:self.requests[indexPath.row] error:&error];
            
            /*
             if (!error) {
             [self.launchNavVC openProfile:user];
             }*/
            [[Launcher sharedInstance] openProfile:user];
        }
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == self.members.count) {
            // invite others
            
        }
        else {
            // view user profile
            if (indexPath.row < self.members.count) {
                NSError *error;
                User *user = [[User alloc] initWithDictionary:self.members[indexPath.row] error:&error];
                
                /*
                if (!error) {
                    [self.launchNavVC openProfile:user];
                }*/
                [[Launcher sharedInstance] openProfile:user];
            }
        }
    }
}

- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    if (hexString != nil && hexString.length == 6) {
        NSScanner *scanner = [NSScanner scannerWithString:hexString];
        [scanner setScanLocation:0]; // bypass '#' character
        [scanner scanHexInt:&rgbValue];
        return [UIColor colorWithDisplayP3Red:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
    }
    else {
        return [UIColor blackColor];
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
