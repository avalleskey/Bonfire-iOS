//
//  CampModerateViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 7/2/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "CampModerateViewController.h"
#import "UIColor+Palette.h"
#import "ExpandedPostCell.h"
#import "HAWebService.h"
#import "PostStream.h"
#import <JGProgressHUD/JGProgressHUD.h>
#import "BFMiniNotificationManager.h"
#import "Launcher.h"
#import "BFAlertController.h"
#import "SpacerCell.h"
#import "PostModerationOptionsTableViewCell.h"
#import "PostModerationInsightsTableViewCell.h"

#define CAMP_MODERATE_HELP_INFO @"Tap a post below to view available moderation actions"

@interface CampModerateViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) BFVisualErrorView *errorView;

@property (nonatomic, strong) PostStream *stream;
@property (nonatomic) BOOL loadingMore;

@end

@implementation CampModerateViewController

static NSString * const blankCellIdentifier = @"BlankCell";
static NSString * const expandedPostCellReuseIdentifier = @"PostCell";
static NSString * const moderationInsightsCellReuseIdentifier = @"InsightsCell";
static NSString * const moderationOptionsCellReuseIdentifier = @"OptionsCell";
static NSString * const spacerCellReuseIdentifier = @"SpacerCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
    
    [self setupTableView];
    [self setupErrorView];
    
    self.loading = true;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostCompleted:) name:@"NewPostCompleted" object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)newPostCompleted:(NSNotification *)notification {
    NSDictionary *info = notification.object;
    NSString *tempId = info[@"tempId"];
    Post *post = info[@"post"];
    
    NSLog(@"temp id: %@", tempId);
    NSLog(@"new post:: %@", post.identifier);
    
    if (self.stream.components.count == 0 && [post.attributes.postedIn.identifier isEqualToString:self.camp.identifier]) {
        // TODO: Check for image as well
        self.errorView.hidden = true;
        
        [self getPosts];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        // Perform an action that will only be done once
        [self getPosts];
    }
}

- (void)setupTableView {
    self.stream = [[PostStream alloc] init];
    self.stream.componentSize = BFStreamComponentSizeExpanded;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.navigationController.navigationBar.frame.size.height) style:UITableViewStyleGrouped];
    self.tableView.backgroundColor = [UIColor tableViewBackgroundColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[ExpandedPostCell class] forCellReuseIdentifier:expandedPostCellReuseIdentifier];
    [self.tableView registerClass:[PostModerationInsightsTableViewCell class] forCellReuseIdentifier:moderationInsightsCellReuseIdentifier];
    [self.tableView registerClass:[PostModerationOptionsTableViewCell class] forCellReuseIdentifier:moderationOptionsCellReuseIdentifier];
    [self.tableView registerClass:[SpacerCell class] forCellReuseIdentifier:spacerCellReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellIdentifier];
}

- (void)getPosts {
    NSString *url = [[NSString alloc] initWithFormat:@"camps/%@/posts/icebreakers", self.camp.identifier];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (self.stream.components.count > 0 && self.stream.nextCursor.length > 0) {
        [params setObject:self.stream.nextCursor forKey:@"next_cursor"];
    }
    
    if ([params objectForKey:@"next_cursor"]) {
        if ([self.stream hasLoadedCursor:params[@"next_cursor"]]) {
            return;
        }
        
        [self.stream addLoadedCursor:params[@"next_cursor"]];
    }
    
    self.loading = true;
    
    [[[HAWebService manager] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:responseObject error:nil];
        if (page.data.count > 0 && ![self.stream.nextCursor isEqualToString:page.meta.paging.nextCursor]) {
            [self.stream appendPage:page];
            [self.stream appendPage:page];
            [self.stream appendPage:page];
        }
        
        if (self.stream.components.count == 0) {
            self.errorView.hidden = false;
            
            self.errorView.visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNoPosts title:@"No Posts in Queue" description:@"Posts that require your attention will appear here" actionTitle:nil actionBlock:nil];
            
            [self positionErrorView];
        }
        else {
            self.errorView.visualError = nil;
            self.errorView.hidden = true;
        }
        
        self.loading = false;
        
        if (self.loadingMore && [self.stream.nextCursor isEqualToString:[params objectForKey:@"next_cursor"]]) {
            self.loadingMore = false;
        }
        
        [self.tableView reloadData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"ManageIcebreakresViewController / getIcebreakers() - error: %@", error);
        //        kNSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        self.loading = false;
        
        if (self.loadingMore && [self.stream.nextCursor isEqualToString:[params objectForKey:@"next_cursor"]]) {
            self.loadingMore = false;
        }
        
        if (self.stream.components.count == 0) {
            self.errorView.visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNotFound title:@"Error Loading" description:@"Check your network settings and tap below to try again" actionTitle:@"Try Again" actionBlock:^{
                self.loading = true;
                self.errorView.hidden = true;
                [self getPosts];
            }];
        }
        
        [self.tableView reloadData];
    }];
}

- (void)setupErrorView {
    self.errorView = [[BFVisualErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100)];
    self.errorView.center = self.bfTableView.center;
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
}
- (void)positionErrorView {
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.bfTableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
}

#pragma mark - Table view data source
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < self.stream.components.count) {
        BFStreamComponent *component = [self.stream.components objectAtIndex:indexPath.section];
        Post *post = component.post;
        
        if (indexPath.row == 0) {
            // expanded post
            ExpandedPostCell *cell = [self.tableView dequeueReusableCellWithIdentifier:expandedPostCellReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[ExpandedPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:expandedPostCellReuseIdentifier];
            }
            
            cell.tintColor = [UIColor bonfireBrand];
            
            cell.tintColor = self.theme;
            cell.post = post;
            cell.topLine.hidden = !(post.attributes.parent || post.attributes.thread.prevCursor.length > 0);
            cell.lineSeparator.hidden = false;
            cell.bottomLine.hidden = true;
            cell.actionsView.hidden = true;
            cell.activityView.hidden = true;
            cell.moreButton.hidden = true;
            
            return cell;
        }
        else if (indexPath.row == 1) {
            // add reply upsell cell
            PostModerationInsightsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:moderationInsightsCellReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[PostModerationInsightsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:moderationInsightsCellReuseIdentifier];
            }
            
            cell.post = post;
            
            return cell;
        }
        else if (indexPath.row == 2) {
            // add reply upsell cell
            PostModerationOptionsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:moderationOptionsCellReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[PostModerationOptionsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:moderationOptionsCellReuseIdentifier];
            }
            
            cell.tintColor = self.theme;
            [cell setOptionTappedAction:^(PostModerationOption option) {
                [HapticHelper generateFeedback:FeedbackType_Selection];
                
                switch (option) {
                    case PostModerationOptionIgnore: {
                        break;
                    }
                    case PostModerationOptionSpam: {
                        break;
                    }
                    case PostModerationOptionDelete: {
                        break;
                    }
                    case PostModerationOptionSilenceUser: {
                        break;
                    }
                    case PostModerationOptionBlockUser: {
                        break;
                    }
                        
                    default:
                        break;
                }
                
//                // remove from the stream
//                [self.stream performEventType:PostStreamEventTypePostRemoved object:post];
//                [self.tableView beginUpdates];
//                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationLeft];
//                [self.tableView endUpdates];
            }];
            
            return cell;
        }
        else if (indexPath.row == 3) {
            SpacerCell *cell = [self.tableView dequeueReusableCellWithIdentifier:spacerCellReuseIdentifier forIndexPath:indexPath];

            if (cell == nil) {
                cell = [[SpacerCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:spacerCellReuseIdentifier];
            }

            cell.topSeparator.hidden = true;
            cell.bottomSeparator.hidden = false;

            return cell;
        }
    }
    
    // if all else fails, return a blank cell
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankCellIdentifier forIndexPath:indexPath];
    return blankCell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < self.stream.components.count) {
        BFStreamComponent *component = [self.stream.components objectAtIndex:indexPath.section];
        Post *post = component.post;
        
        if (indexPath.row == 0) {
            return component.cellHeight - expandedActionsViewHeight - expandedActivityViewHeight;
        }
        else if (indexPath.row == 1) {
            return [PostModerationInsightsTableViewCell heightForPost:post];
        }
        else if (indexPath.row == 2) {
            return [PostModerationOptionsTableViewCell height];
        }
        else if (indexPath.row == 3) {
            return [SpacerCell height];
        }
    }
    
    return CGFLOAT_MIN;
}
- (BOOL)includeSpacerCellForSection:(NSInteger)section {
    return (section < self.stream.components.count);
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.stream.components.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3 + ([self includeSpacerCellForSection:section] ? 1 : 0);
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < self.stream.components.count) {
        if (indexPath.row == 0) {
            BFStreamComponent *component = [self.stream.components objectAtIndex:indexPath.section];
            [Launcher openPost:component.post withKeyboard:false];
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == self.stream.components.count && !self.loading) {
        BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
        BOOL showLoadingFooter = (self.loadingMore || (hasAnotherPage && ![self.stream hasLoadedCursor:self.stream.nextCursor]));
        
        if (showLoadingFooter) {
            return 48;
        }
        else {
            return CGFLOAT_MIN;
        }
    }
    
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    if (section == self.stream.components.count && !self.loading) {
        BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
        BOOL showLoadingFooter = (self.loadingMore || (hasAnotherPage && ![self.stream hasLoadedCursor:self.stream.nextCursor]));

        if (showLoadingFooter) {
            UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 48)];
            footer.backgroundColor = [UIColor tableViewBackgroundColor];
            
            BFActivityIndicatorView *spinner = [[BFActivityIndicatorView alloc] init];
            spinner.color = [[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0.5];
            spinner.frame = CGRectMake(footer.frame.size.width / 2 - 10, footer.frame.size.height / 2 - 10, 20, 20);
            [footer addSubview:spinner];

            [spinner startAnimating];

            if (!self.loadingMore && self.stream.pages.count > 0 && self.stream.nextCursor.length > 0) {
                self.loadingMore = true;

                [self getPosts];
            }
            
            return footer;
        }
    }
    
    return nil;
}

@end
