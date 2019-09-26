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
#import "CampListStream.h"
#import <PINCache/PINCache.h>
@import Firebase;

@interface PrivacySelectorTableViewController ()

@property (nonatomic, strong) CampListStream *stream;
@property (nonatomic) BOOL loadingCamps;
@property (nonatomic) BOOL loadingMoreCamps;

@end

@implementation PrivacySelectorTableViewController

static NSString * const blankReuseIdentifier = @"BlankCell";
static NSString * const myProfileCellReuseIdentifier = @"MyProfileCell";

static NSString * const campCellIdentifier = @"CampCell";
static NSString * const loadingCellIdentifier = @"LoadingCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Share in...";
    
    [self loadCache];
    
    if (![self.stream nextCursor]) {
        NSLog(@"no cursor yoooooo:: ");
        [self getCampsWithCursor:StreamPagingCursorTypeNone];
    }
    
    self.view.tintColor = [UIColor bonfirePrimaryColor];
    
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
    [self.cancelButton setTintColor:[UIColor bonfirePrimaryColor]];
    [self.cancelButton setTitleTextAttributes:@{
                                                NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium]
                                                } forState:UIControlStateNormal];
    [self.cancelButton setTitleTextAttributes:@{
                                                NSFontAttributeName: [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium]
                                                } forState:UIControlStateHighlighted];
    self.navigationItem.leftBarButtonItem = self.cancelButton;
}
- (void)setupTableView {
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorColor = [UIColor tableViewSeparatorColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 70, 0, 0);
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:loadingCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:myProfileCellReuseIdentifier];
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:campCellIdentifier];
}

- (void)loadCache {
    NSArray *cache = [[PINCache sharedCache] objectForKey:@"my_camps_paged_cache"];
    
    self.stream = [[CampListStream alloc] init];
    if (cache.count > 0) {
        for (NSDictionary *pageDict in cache) {
            CampListStreamPage *page = [[CampListStreamPage alloc] initWithDictionary:pageDict error:nil];
            [self.stream appendPage:page];
        }
        
        NSLog(@"self.stream.camps.count :: %lu", (unsigned long)self.stream.camps.count);
        if (self.stream.camps.count > 0) {
            self.loadingCamps = false;
        }
        
        [self.tableView reloadData];
    }
}

- (void)getCampsWithCursor:(StreamPagingCursorType)cursorType {
    NSString *url = [NSString stringWithFormat:@"users/%@/camps", [Session sharedInstance].currentUser.identifier];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    NSString *nextCursor = [self.stream nextCursor];
    if (cursorType == StreamPagingCursorTypeNext && nextCursor.length > 0) {
        if ([self.stream hasLoadedCursor:nextCursor]) {
            return;
        }
        
        self.loadingMoreCamps = true;
        [self.stream addLoadedCursor:nextCursor];
        [params setObject:nextCursor forKey:@"cursor"];
    }
    else {
        self.loadingCamps = true;
    }
    
    NSLog(@"GET -> %@", url);
    NSLog(@"params: %@", params);
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        CampListStreamPage *page = [[CampListStreamPage alloc] initWithDictionary:responseObject error:nil];
        
        if (page.data.count > 0) {
            if ([params objectForKey:@"cursor"]) {
                self.loadingMoreCamps = false;
            }
            else {
                // clear the stream (we retrieved a full page of notifs and the old ones are out of date)
                self.stream = [[CampListStream alloc] init];
            }
            [self.stream appendPage:page];
        }
        
        self.loadingCamps = false;
        
        [self.tableView reloadData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"CampViewController / getRequests() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        if (nextCursor.length > 0) {
            [self.stream removeLoadedCursor:nextCursor];
        }
        self.loadingCamps = false;
        
        [self.tableView reloadData];
    }];
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
    if (section == 1) return self.stream.camps.count;
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:myProfileCellReuseIdentifier forIndexPath:indexPath];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UILabel *label = [cell viewWithTag:10];
        UIImageView *checkIcon = [cell viewWithTag:11];
        if (!label) {
            cell.contentView.backgroundColor = [UIColor contentBackgroundColor];
            
            label = [[UILabel alloc] initWithFrame:CGRectMake(70, 0, self.view.frame.size.width - 70 - 16 - 32, cell.frame.size.height)];
            label.tag = 10;
            label.textAlignment = NSTextAlignmentLeft;
            label.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightSemibold];
            label.textColor = [UIColor bonfirePrimaryColor];
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
        SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:campCellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[SearchResultCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:campCellIdentifier];
        }
        
        Camp *camp = self.stream.camps[indexPath.row];
        cell.camp = camp;
        
        cell.tintColor = self.view.tintColor;
        cell.checkIcon.hidden = ![camp.identifier isEqualToString:self.currentSelection.identifier];
        cell.checkIcon.tintColor = self.view.tintColor;
        
        return cell;
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
            if (self.loadingCamps || self.stream.camps.count > 0) {
               header.title = @"My Camps";
            }
            else {
                header.title = @"";
            }
        }
        
        return header;
    }
    
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 1) {
        BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
        BOOL showLoadingFooter = self.loadingCamps || ((self.loadingMoreCamps || hasAnotherPage) && ![self.stream hasLoadedCursor:self.stream.nextCursor]);
        
        return showLoadingFooter ? 52 : 0;
    }
    
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 1) {
        // last row
        BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
        BOOL showLoadingFooter = self.loadingCamps || ((self.loadingMoreCamps || hasAnotherPage) && ![self.stream hasLoadedCursor:self.stream.nextCursor]);
        
        if (showLoadingFooter) {
            UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 52)];
            
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            spinner.color = [UIColor bonfireSecondaryColor];
            spinner.frame = CGRectMake(footer.frame.size.width / 2 - 10, footer.frame.size.height / 2 - 10, 20, 20);
            [footer addSubview:spinner];
            
            [spinner startAnimating];
            
            if (!self.loadingMoreCamps && self.stream.pages.count > 0 && self.stream.nextCursor.length > 0) {
                [self getCampsWithCursor:StreamPagingCursorTypeNext];
            }
            
            return footer;
        }
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // my profile
        [self.delegate privacySelectionDidChange:nil];
    }
    else if (indexPath.section == 1) {
        // camp
        Camp *camp = self.stream.camps[indexPath.row];
        [self.delegate privacySelectionDidChange:camp];
    }
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
