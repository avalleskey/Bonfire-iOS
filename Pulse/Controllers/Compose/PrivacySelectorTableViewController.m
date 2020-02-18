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
#import "BFSearchView.h"
#import "SpacerCell.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
@import Firebase;

#define AVAILABLE_CAMPS_DESCRIPTION @"Only Camps which you are allowed to start conversations in are shown above."

@interface PrivacySelectorTableViewController () <UITextFieldDelegate>

@property (nonatomic, strong) CampListStream *stream;
@property (nonatomic) BOOL loadingCamps;
@property (nonatomic) BOOL loadingMoreCamps;

@property (nonatomic, strong) NSString *searchPhrase;
@property (nonatomic, strong) BFSearchView *searchView;

@end

@implementation PrivacySelectorTableViewController

static NSString * const blankReuseIdentifier = @"BlankCell";
static NSString * const myProfileCellReuseIdentifier = @"MyProfileCell";
static NSString * const spacerCellReuseIdentifier = @"SpacerCell";

static NSString * const campCellIdentifier = @"CampCell";
static NSString * const loadingCellIdentifier = @"LoadingCell";

- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.searchPhrase = @"";
    self.title = _postOnSelection ? @"Post in..." : @"Select a Camp";
    
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
    self.tableView.backgroundColor = [UIColor contentBackgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:loadingCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:myProfileCellReuseIdentifier];
    [self.tableView registerClass:[SpacerCell class] forCellReuseIdentifier:spacerCellReuseIdentifier];
    [self.tableView registerClass:[SearchResultCell class] forCellReuseIdentifier:campCellIdentifier];
}

- (void)loadCache {
    NSArray *cache = [[PINCache sharedCache] objectForKey:MY_CAMPS_CAN_POST_KEY];
    
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

- (void)saveCacheIfNeeded {
    NSMutableArray *newCache = [[NSMutableArray alloc] init];
    
    for (NSInteger i = 0; i < self.stream.pages.count; i++) {
        [newCache addObject:[self.stream.pages[i] toDictionary]];
    }
    
    [[PINCache sharedCache] setObject:[newCache copy] forKey:MY_CAMPS_CAN_POST_KEY];
}

- (void)getCampsWithCursor:(StreamPagingCursorType)cursorType {
    NSString *url = [NSString stringWithFormat:@"users/%@/camps?filter_types=can_post", [Session sharedInstance].currentUser.identifier];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    NSString *nextCursor = [self.stream nextCursor];
    if (cursorType == StreamPagingCursorTypeNext && nextCursor.length > 0) {
        if ([self.stream hasLoadedCursor:nextCursor]) {
            return;
        }
        
        self.loadingMoreCamps = true;
        [self.stream addLoadedCursor:nextCursor];
        [params setObject:nextCursor forKey:@"next_cursor"];
    }
    else {
        self.loadingCamps = true;
        [self.tableView reloadData];
    }
    
    NSString *filterQuery = @"";
    if (self.searchPhrase && self.searchPhrase.length > 0) {
        filterQuery = self.searchPhrase;
        [params setObject:filterQuery forKey:@"filter_query"];
    }
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (![self.searchPhrase isEqualToString:filterQuery]) {
            return;
        }
        
        CampListStreamPage *page = [[CampListStreamPage alloc] initWithDictionary:responseObject error:nil];

        if (page.data.count > 0) {
            if (![params objectForKey:@"next_cursor"]) {
                // clear the stream (we retrieved a full page of notifs and the old ones are out of date)
                self.stream = [[CampListStream alloc] init];
            }
            
            if (cursorType == StreamPagingCursorTypePrevious) {
                [self.stream prependPage:page];
            }
            else {
                [self.stream appendPage:page];
            }
            
            if (filterQuery.length == 0) {
                [self saveCacheIfNeeded];
            }
        }
        else if (cursorType == StreamPagingCursorTypeNone) {
            self.stream = [[CampListStream alloc] init];
            
            [self saveCacheIfNeeded];
        }
        
        self.loadingCamps = false;
        self.loadingMoreCamps = false;
        
        [self.tableView layoutIfNeeded];
        [self.tableView reloadData];
        [self.tableView layoutIfNeeded];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"CampViewController / getRequests() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        if (nextCursor.length > 0) {
            [self.stream removeLoadedCursor:nextCursor];
            self.loadingMoreCamps = false;
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
    if (indexPath.section == 0 && indexPath.row == 0) {
//        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:myProfileCellReuseIdentifier forIndexPath:indexPath];
//
//        cell.selectionStyle = UITableViewCellSelectionStyleNone;
//
//        UILabel *label = [cell viewWithTag:10];
//        UIImageView *checkIcon = [cell viewWithTag:11];
//        UIView *separator = [cell viewWithTag:12];
//        if (!label) {
//            cell.contentView.backgroundColor = [UIColor contentBackgroundColor];
//
//            label = [[UILabel alloc] initWithFrame:CGRectMake(70, 0, self.view.frame.size.width - 70 - 16 - 32, cell.frame.size.height)];
//            label.tag = 10;
//            label.textAlignment = NSTextAlignmentLeft;
//            label.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightSemibold];
//            label.textColor = [UIColor bonfirePrimaryColor];
//            label.text = @"My Profile";
//            [cell.contentView addSubview:label];
//
//            // image view
//            BFAvatarView *imageView = [[BFAvatarView alloc] init];
//            imageView.frame = CGRectMake(12, cell.frame.size.height / 2 - 24, 48, 48);
//            imageView.user = [Session sharedInstance].currentUser;
//            [cell.contentView addSubview:imageView];
//
//            checkIcon = [[UIImageView alloc] initWithFrame:CGRectMake(cell.frame.size.width - 16 - 24, cell.frame.size.height / 2 - 12, 24, 24)];
//            checkIcon.image = [[UIImage imageNamed:@"tableCellCheckIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//            checkIcon.tintColor = self.view.tintColor;
//            checkIcon.hidden = true;
//            [cell.contentView addSubview:checkIcon];
//
//            separator = [[UIView alloc] initWithFrame:CGRectMake(label.frame.origin.x, cell.frame.size.height - HALF_PIXEL, self.view.frame.size.width - label.frame.origin.x, HALF_PIXEL)];
//            separator.backgroundColor = [UIColor tableViewSeparatorColor];
//            separator.tag = 12;
//            [cell.contentView addSubview:separator];
//        }
//        checkIcon.hidden = !(self.shareOnProfile && self.currentSelection == nil);
//        separator.hidden = self.stream.camps.count == 0;
//
//        return cell;
        
        SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:campCellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[SearchResultCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:campCellIdentifier];
        }
        
        cell.user = [Session sharedInstance].currentUser;
        cell.textLabel.text = @"My Profile";
        
        cell.tintColor = self.view.tintColor;
        cell.checkIcon.tintColor = self.view.tintColor;
        
        cell.checkIcon.hidden = !(self.shareOnProfile && self.currentSelection == nil);
        cell.lineSeparator.hidden = self.stream.camps.count == 0;
        
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
        cell.lineSeparator.hidden = (self.stream.camps.count == indexPath.row + 1);
        
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
    if (section == 0 && [self showSearch]) {
        return 56;
    }
    
    return 0;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0 && [self showSearch]) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 56)];
        header.backgroundColor = [UIColor contentBackgroundColor];
        
        if (!self.searchView) {
            // search view
            self.searchView = [[BFSearchView alloc] initWithFrame:CGRectMake(12, 10, self.view.frame.size.width - (12 * 2), 36)];
            self.searchView.placeholder = @"Search Available Camps";
            [self.searchView updateSearchText:self.searchPhrase];
            self.searchView.textField.tintColor = self.view.tintColor;
            self.searchView.textField.delegate = self;
            [self.searchView.textField becomeFirstResponder];
            [self.searchView.textField bk_addEventHandler:^(id sender) {
                self.searchPhrase = self.searchView.textField.text;
                
                [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
                [self getCampsWithCursor:StreamPagingCursorTypeNone];
                [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
            } forControlEvents:UIControlEventEditingChanged];
        }
        self.searchView.frame = CGRectMake(12, 10, self.view.frame.size.width - (12 * 2), 36);
        
        [header addSubview:self.searchView];
        
        return header;
    }
    else {
        self.searchView = nil;
    }
    
    return nil;
}

- (BOOL)showSearch {
    return [Session sharedInstance].currentUser.attributes.summaries.counts.camps >= 8;
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

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 1) {
        BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
        BOOL showLoadingFooter = self.loadingCamps || ((self.loadingMoreCamps || hasAnotherPage) && ![self.stream hasLoadedCursor:self.stream.nextCursor]);
        
        if  (showLoadingFooter) {
            return 52;
        }
        else if (self.stream.camps.count > 0) {
            CGSize labelSize = [AVAILABLE_CAMPS_DESCRIPTION boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 24, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.f weight:UIFontWeightRegular]} context:nil].size;
            
            return labelSize.height + (12 * 2); // 24 padding on top and bottom
        }
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
        else {
            UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 90)];
            
            UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, footer.frame.size.width - 24, 42)];
            descriptionLabel.text = AVAILABLE_CAMPS_DESCRIPTION;
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
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Camp *camp;
    if (indexPath.section == 1) {
        // camp
        camp = self.stream.camps[indexPath.row];
    }
    
    if (self.postOnSelection && [self.delegate respondsToSelector:@selector(privacySelectionDidSelectToPost:)]) {
        [self.delegate privacySelectionDidSelectToPost:camp];
    }
    else if ([self.delegate respondsToSelector:@selector(privacySelectionDidChange:)]) {
        [self.delegate privacySelectionDidChange:camp];
    }
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
