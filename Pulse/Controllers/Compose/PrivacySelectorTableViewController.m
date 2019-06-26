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
#import "Camp.h"
#import "Session.h"
#import "NSArray+Clean.h"
#import "BFAvatarView.h"
#import "UIColor+Palette.h"
#import "BFHeaderView.h"
@import Firebase;

@interface PrivacySelectorTableViewController ()

@property (nonatomic, strong) NSMutableArray *camps;
@property (nonatomic) BOOL loading;

@end

@implementation PrivacySelectorTableViewController

static NSString * const blankReuseIdentifier = @"BlankCell";
static NSString * const myProfileCellReuseIdentifier = @"MyProfileCell";

static NSString * const campCellIdentifier = @"CampCell";
static NSString * const loadingCellIdentifier = @"LoadingCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Share in...";
    
    self.camps = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"my_camps_cache"]];
    for (NSInteger i = 0; i < self.camps.count; i++) {
        if ([self.camps[i] isKindOfClass:[Camp class]]) {
            [self.camps replaceObjectAtIndex:i withObject:[((Camp *)self.camps[i]) toDictionary]];
        }
    }
    
    self.view.tintColor = [UIColor bonfireBlack];

    if (self.camps.count == 0) {
        self.loading = true;
        [self getCamps];
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
                                                NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium]
                                                } forState:UIControlStateNormal];
    [self.cancelButton setTitleTextAttributes:@{
                                                NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium]
                                                } forState:UIControlStateHighlighted];
    self.navigationItem.leftBarButtonItem = self.cancelButton;
}
- (void)setupTableView {
    self.tableView.backgroundColor = [UIColor headerBackgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = [UIColor separatorColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 70, 0, 0);
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:loadingCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:myProfileCellReuseIdentifier];
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:campCellIdentifier];
}

- (void)getCamps {
    [[HAWebService authenticatedManager] GET:@"users/me/camps" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSArray *responseData = responseObject[@"data"];
        
        if (responseData.count > 0) {
            self.camps = [[NSMutableArray alloc] initWithArray:responseData];
            if (self.camps.count > 1) [self sortCamps];
        }
        else {
            self.camps = [[NSMutableArray alloc] init];
        }
        
        self.loading = false;
        
        [self.tableView reloadData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"MyCampsViewController / getCamps() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        [self.tableView reloadData];
    }];
}
- (void)sortCamps {
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
        
        return self.camps.count;
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
            cell.contentView.backgroundColor = [UIColor whiteColor];
            
            label = [[UILabel alloc] initWithFrame:CGRectMake(70, 0, self.view.frame.size.width - 70 - 16 - 32, cell.frame.size.height)];
            label.tag = 10;
            label.textAlignment = NSTextAlignmentLeft;
            label.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightSemibold];
            label.textColor = [UIColor bonfireBlack];
            label.text = @"My Profile";
            [cell.contentView addSubview:label];
            
            // image view
            BFAvatarView *imageView = [[BFAvatarView alloc] init];
            imageView.frame = CGRectMake(12, cell.frame.size.height / 2 - 24, 48, 48);
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
            SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:campCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[SearchResultCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:campCellIdentifier];
            }
            
            // Configure the cell...
            cell.type = 1;
            
            Camp *camp = [[Camp alloc] initWithDictionary:self.camps[indexPath.row] error:nil];
            
            cell.textLabel.text = camp.attributes.details.title;
            cell.profilePicture.camp = camp;
            
            NSString *detailText = [NSString stringWithFormat:@"%ld %@", (long)camp.attributes.summaries.counts.members, (camp.attributes.summaries.counts.members == 1 ? [Session sharedInstance].defaults.camp.membersTitle.singular : [Session sharedInstance].defaults.camp.membersTitle.plural)];
            /*BOOL useLiveCount = camp.attributes.summaries.counts.live > [Session sharedInstance].defaults.camp.liveThreshold;
            if (useLiveCount) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %li LIVE", detailText, (long)camp.attributes.summaries.counts.live];
            }*/
            cell.detailTextLabel.text = detailText;
            
            cell.tintColor = self.view.tintColor;
            cell.checkIcon.hidden = ![camp.identifier isEqualToString:self.currentSelection.identifier];
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
            cell.contentView.backgroundColor = [[UIColor contentBackgroundColor] colorWithAlphaComponent:0.97];
        } completion:nil];
    }
}
- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            cell.contentView.backgroundColor = [UIColor contentBackgroundColor];
        } completion:nil];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 68;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) return 0;
    
    if (section == 1) return [BFHeaderView height];
    
    return 0;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) return nil;
    
    if (section == 1) {
        BFHeaderView *header = [[BFHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [BFHeaderView height])];
        
        header.separator = false;
        
        if (section == 1) {
            if (self.loading || self.camps.count > 0) header.title = @"My Camps";
            else header.title = @"";
        }
        
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
        // camp
        Camp *camp = [[Camp alloc] initWithDictionary:self.camps[indexPath.row] error:nil];
        [self.delegate privacySelectionDidChange:camp];
    }
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
