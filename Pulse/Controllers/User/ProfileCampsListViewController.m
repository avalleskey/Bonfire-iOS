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
@import Firebase;

@interface ProfileCampsListViewController ()

@property (nonatomic) BOOL loadingCamps;

@property (strong, nonatomic) NSMutableArray *camps;

@end

@implementation ProfileCampsListViewController

static NSString * const blankReuseIdentifier = @"BlankCell";
static NSString * const emptySectionCellIdentifier = @"EmptyCell";

static NSString * const memberCellIdentifier = @"MemberCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton = true;
        
    self.camps = [[NSMutableArray alloc] init];
    
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
    self.loadingCamps = true;
    
    // load in cache
    if ([[Session sharedInstance].currentUser.identifier isEqualToString:self.user.identifier]) {
        self.camps = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"my_camps_cache"]];
        [self sortCamps];
        if (self.camps.count > 0) {
            self.loadingCamps = false;
            [self.tableView reloadData];
        }
    }
    [self getCampsList];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Profile / Camps" screenClass:nil];
}

- (void)getCampsList {
    NSString *url = [NSString stringWithFormat:@"users/%@/camps", self.user.identifier];
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSArray *responseData = (NSArray *)responseObject[@"data"];
        
        NSLog(@"response data for requests: %@", responseData);
        
        self.camps = [[NSMutableArray alloc] initWithArray:responseData];
        if ([self.user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
            [self sortCamps];
        }
        
        self.loadingCamps = false;
        
        [self.tableView reloadData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"CampViewController / getRequests() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
    }];
}
- (void)sortCamps {
    NSLog(@"sort that ish");
    if (!self.camps || self.camps.count == 0) return;
    
    NSDictionary *opens = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"camp_opens"];
    
    for (NSInteger i = 0; i < self.camps.count; i++) {
        if ([self.camps[i] isKindOfClass:[NSDictionary class]] && [self.camps[i] objectForKey:@"id"]) {
            NSMutableDictionary *mutableCamp = [[NSMutableDictionary alloc] initWithDictionary:self.camps[i]];
            NSString *campId = mutableCamp[@"id"];
            NSInteger campOpens = [opens objectForKey:campId] ? [opens[campId] integerValue] : 0;
            [mutableCamp setObject:[NSNumber numberWithInteger:campOpens] forKey:@"opens"];
            [self.camps replaceObjectAtIndex:i withObject:mutableCamp];
        }
    }
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"opens"
                                                                 ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
    NSArray *sortedArray = [self.camps sortedArrayUsingDescriptors:sortDescriptors];
    
    self.camps = [[NSMutableArray alloc] initWithArray:sortedArray];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && !self.loadingCamps) {
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
        cell.type = SearchResultCellTypeCamp;
        
        if (self.loadingCamps) {
            cell.profilePicture.imageView.backgroundColor = [UIColor colorWithWhite:0.9f alpha:1];
            cell.textLabel.text = @"Loading...";
            cell.textLabel.alpha = 0.5;
            cell.detailTextLabel.text = @"";
        }
        else {
            NSError *error;
            Camp *camp = [[Camp alloc] initWithDictionary:self.camps[indexPath.row] error:&error];
            if (error) { NSLog(@"camp error: %@", error); };
            
            // 1 = Camp
            cell.profilePicture.camp = camp;
            cell.textLabel.text = camp.attributes.details.title;
            cell.textLabel.alpha = 1;
            
            NSString *detailText = [NSString stringWithFormat:@"%ld %@", (long)camp.attributes.summaries.counts.members, (camp.attributes.summaries.counts.members == 1 ? [Session sharedInstance].defaults.camp.membersTitle.singular : [Session sharedInstance].defaults.camp.membersTitle.plural)];
            /*BOOL useLiveCount = camp.attributes.summaries.counts.live > [Session sharedInstance].defaults.camp.liveThreshold;
            if (useLiveCount) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %li LIVE", detailText, (long)camp.attributes.summaries.counts.live];
            }*/
            cell.detailTextLabel.text = detailText;
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
    
    if (section == 0 && !self.loadingCamps && self.camps.count == 0)
        return 0;
    
    if (section == 0)
        return headerHeight;
    
    return 0;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        // BOOL hasAnotherPage = self.stream.pages.count > 0 && [self.stream.pages lastObject].meta.paging.next_cursor != nil && [self.stream.pages lastObject].meta.paging.next_cursor.length > 0;
        // BOOL showLoadingFooter = (self.loadingMore || hasAnotherPage);
        
        return self.loadingCamps;
    }
    
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        //BOOL hasAnotherPage = self.stream.pages.count > 0 && [self.stream.pages lastObject].meta.paging.next_cursor != nil && [self.stream.pages lastObject].meta.paging.next_cursor.length > 0;
        //BOOL showLoadingFooter = (self.loadingMore || hasAnotherPage);
        
        if (self.loadingCamps) {
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
        if (indexPath.row < self.camps.count) {
            NSError *error;
            Camp *camp = [[Camp alloc] initWithDictionary:self.camps[indexPath.row] error:&error];
            
             if (!error) {
                 [Launcher openCamp:camp];
             }
        }
    }
}

@end
