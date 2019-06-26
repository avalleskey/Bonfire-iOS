//
//  ProfileFollowingListViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ProfileFollowingListViewController.h"
#import "Session.h"
#import "SearchResultCell.h"
#import "HAWebService.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
@import Firebase;

@interface ProfileFollowingListViewController ()

@property (nonatomic) BOOL loadingUsers;

@property (strong, nonatomic) NSMutableArray *users;

@end

@implementation ProfileFollowingListViewController

static NSString * const blankReuseIdentifier = @"BlankCell";
static NSString * const emptySectionCellIdentifier = @"EmptyCell";

static NSString * const memberCellIdentifier = @"MemberCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton = true;
    
    self.users = [[NSMutableArray alloc] init];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.backgroundColor = [UIColor headerBackgroundColor];
    self.tableView.separatorColor = [UIColor separatorColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 70, 0, 0);
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:emptySectionCellIdentifier];
    
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:memberCellIdentifier];
    
    // if admin
    self.loadingUsers = true;
    [self getCampsList];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Profile / Following" screenClass:nil];
}

- (void)getCampsList {
    NSString *url = [NSString stringWithFormat:@"users/%@/following", self.user.identifier];
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSArray *responseData = (NSArray *)responseObject[@"data"];
        
        NSLog(@"response data for requests: %@", responseData);
        
        self.users = [[NSMutableArray alloc] initWithArray:responseData];
        
        self.loadingUsers = false;
        
        [self.tableView reloadData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"CampViewController / getRequests() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
    }];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && !self.loadingUsers) {
        return self.users.count;
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
        cell.type = SearchResultCellTypeUser;
        
        if (self.loadingUsers) {
            cell.profilePicture.user = nil;
            cell.profilePicture.imageView.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1];
            cell.textLabel.text = @"Loading...";
            cell.textLabel.alpha = 0.5;
            cell.detailTextLabel.text = @"";
        }
        else {
            NSError *error;
            User *user = [[User alloc] initWithDictionary:self.users[indexPath.row] error:&error];
            if (error) { NSLog(@"user error: %@", error); };
            
            cell.profilePicture.user = user;
            cell.textLabel.alpha = 1;
            cell.textLabel.text = user.attributes.details.displayName;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@", user.attributes.details.identifier];
        }
        
        return cell;
    }
    
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankReuseIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 68;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat headerHeight = 0; // 64;
    
    if (section == 0 && !self.loadingUsers && self.users.count == 0)
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
    if (section == 0) {
        // BOOL hasAnotherPage = self.stream.pages.count > 0 && [self.stream.pages lastObject].meta.paging.next_cursor != nil && [self.stream.pages lastObject].meta.paging.next_cursor.length > 0;
        // BOOL showLoadingFooter = (self.loadingMore || hasAnotherPage);
        
        return self.loadingUsers;
    }
    
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        //BOOL hasAnotherPage = self.stream.pages.count > 0 && [self.stream.pages lastObject].meta.paging.next_cursor != nil && [self.stream.pages lastObject].meta.paging.next_cursor.length > 0;
        //BOOL showLoadingFooter = (self.loadingMore || hasAnotherPage);
        
        if (self.loadingUsers) {
            UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 52)];
            
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            spinner.frame = CGRectMake(footer.frame.size.width / 2 - 10, footer.frame.size.height / 2 - 10, 20, 20);
            [footer addSubview:spinner];
            
            [spinner startAnimating];
            
            /*if (!self.loadingMore && self.stream.pages.count > 0 && [self.stream.pages lastObject].meta.paging.next_cursor != nil && [self.stream.pages lastObject].meta.paging.next_cursor.length > 0) {
             self.loadingMore = true;
             NSLog(@"fetch next page");
             [self getNotificationsWithNextCursor:true];
             }*/
            
            return footer;
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row < self.users.count) {
            NSError *error;
            User *user = [[User alloc] initWithDictionary:self.users[indexPath.row] error:&error];
            
             if (!error) {
                 [Launcher openProfile:user];
             }
        }
    }
}

@end
