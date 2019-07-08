//
//  SelectAPostViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 7/2/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "SetAnIcebreakerViewController.h"
#import "UIColor+Palette.h"
#import "StreamPostCell.h"
#import "HAWebService.h"
#import "PostStream.h"
#import <JGProgressHUD/JGProgressHUD.h>
#import "Launcher.h"

#define HELP_INFO_DESCRIPTION @"Tap a post below to set it as your Camp icebreaker"

@interface SetAnIcebreakerViewController ()

@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL loadingMore;

@property (nonatomic, strong) ErrorView *errorView;

@property (nonatomic, strong) PostStream *stream;

@end

@implementation SetAnIcebreakerViewController

static NSString * const blankCellIdentifier = @"BlankCell";
static NSString * const postCellReuseIdentifier = @"PostCell";

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupTableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        // Perform an action that will only be done once
        [self getPosts];
    }
}

- (void)setupTableView {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.stream = [[PostStream alloc] init];
    self.loading = true;
    [self.tableView reloadData];
    
    [self.tableView registerClass:[StreamPostCell class] forCellReuseIdentifier:postCellReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellIdentifier];
}

- (void)getPosts {
    self.loading = true;
    [self.tableView reloadData];
    
    NSString *url = [[NSString alloc] initWithFormat:@"camps/%@/stream?filter_types=top,!icebreaker", self.camp.identifier];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (self.stream.posts.count > 0 && self.stream.nextCursor.length > 0) {
        [params setObject:self.stream.nextCursor forKey:@"cursor"];
    }
    
    if ([params objectForKey:@"cursor"]) {
        [self.stream addLoadedCursor:params[@"cursor"]];
    }
    
    NSLog(@"GET -> %@", url);
    NSLog(@"params: %@", params);
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:responseObject error:nil];
        if (page.data.count > 0) {
            [self.stream appendPage:page];
        }
        
        self.loading = false;
        
        [self.tableView reloadData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"ManageIcebreakresViewController / getIcebreakers() - error: %@", error);
        //        kNSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        self.loading = false;
        
        [self.tableView reloadData];
    }];
}

- (void)setupErrorView {
    self.errorView = [[ErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100)];
    self.errorView.center = self.tableView.center;
    self.errorView.hidden = true;
    [self.tableView addSubview:self.errorView];
}
- (void)positionErrorView {
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.stream.posts.count > indexPath.row) {
        StreamPostCell *cell = [tableView dequeueReusableCellWithIdentifier:postCellReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[StreamPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:postCellReuseIdentifier];
        }
        
        Post *post = self.stream.posts[indexPath.row];
        
        cell.showContext = true;
        cell.showCamptag = true;
        cell.hideActions = false;
        cell.post = post;
        
        cell.actionsView.voteButton.alpha =
        cell.actionsView.replyButton.alpha =
        cell.moreButton.alpha = 0.5;
        cell.actionsView.voteButton.userInteractionEnabled =
        cell.actionsView.replyButton.userInteractionEnabled =
        cell.moreButton.userInteractionEnabled =
        cell.primaryAvatarView.userInteractionEnabled = false;
        
        cell.lineSeparator.hidden = false;
        
        return cell;
    }
    
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankCellIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.stream.posts.count > indexPath.row) {
        Post *post = self.stream.posts[indexPath.row];
        
        JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
        HUD.textLabel.text = @"Saving...";
        HUD.vibrancyEnabled = false;
        HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
        HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
        [HUD showInView:[Launcher topMostViewController].view animated:YES];
        
        NSLog(@"post:: %@", [NSString stringWithFormat:@"camps/%@/posts/%@/icebreakers", post.attributes.status.postedIn.identifier, post.identifier]);
        
        [[HAWebService authenticatedManager] POST:[NSString stringWithFormat:@"camps/%@/posts/%@/icebreakers", post.attributes.status.postedIn.identifier, post.identifier] parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
            HUD.textLabel.text = @"Svaed!";
            [HUD dismiss];
            
            if ([self.delegate respondsToSelector:@selector(setAnIcebreakerViewController:didSelectPost:)]) {
                [self.delegate setAnIcebreakerViewController:self didSelectPost:post];
            }
            
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"error setting as icebreaker");
            NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
            NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            NSLog(@"%@",ErrorResponse);
            
            HUD.indicatorView = [[JGProgressHUDErrorIndicatorView alloc] init];
            HUD.textLabel.text = @"Error Saving";
            
            [HUD dismissAfterDelay:1.f];
        }];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.stream.posts.count;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.stream.posts.count > indexPath.row) {
        Post *post = self.stream.posts[indexPath.row];
        return [StreamPostCell heightForPost:post showContext:true showActions:true];
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0 && self.stream.posts.count > 0) {
        CGSize labelSize = [HELP_INFO_DESCRIPTION boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 48, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.f weight:UIFontWeightSemibold]} context:nil].size;
        
        return labelSize.height + (12 * 2); // 24 padding on top and bottom
    }
    
    return CGFLOAT_MIN;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0 && self.stream.posts.count > 0) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 90)];
        
        UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, 12, header.frame.size.width - 48, 42)];
        descriptionLabel.text = HELP_INFO_DESCRIPTION;
        descriptionLabel.textColor = [UIColor bonfireGray];
        descriptionLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightSemibold];
        descriptionLabel.textAlignment = NSTextAlignmentCenter;
        descriptionLabel.numberOfLines = 0;
        descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        CGSize labelSize = [descriptionLabel.text boundingRectWithSize:CGSizeMake(descriptionLabel.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:descriptionLabel.font} context:nil].size;
        descriptionLabel.frame = CGRectMake(descriptionLabel.frame.origin.x, descriptionLabel.frame.origin.y, descriptionLabel.frame.size.width, labelSize.height);
        [header addSubview:descriptionLabel];
        
        header.frame = CGRectMake(0, 0, header.frame.size.width, descriptionLabel.frame.size.height + (descriptionLabel.frame.origin.y*2));
        
        return header;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if ((section == 0 && self.stream.posts.count == 0) || section == self.stream.posts.count - 1) {
        // last row
        BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
        BOOL showLoadingFooter = (self.loading || self.loadingMore || hasAnotherPage) && ![self.stream hasLoadedCursor:self.stream.nextCursor];
        
        return showLoadingFooter ? 52 : 0;
    }
    
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    if ((section == 0 && self.stream.posts.count == 0) || section == self.stream.posts.count - 1) {
        BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
        BOOL showLoadingFooter = (self.loading || self.loadingMore || hasAnotherPage) && ![self.stream hasLoadedCursor:self.stream.nextCursor];
        
        if (showLoadingFooter) {
            UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 52)];
            
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            spinner.frame = CGRectMake(footer.frame.size.width / 2 - 10, footer.frame.size.height / 2 - 10, 20, 20);
            [footer addSubview:spinner];
            
            [spinner startAnimating];
            
            if (!self.loadingMore && self.stream.pages.count > 0 && [self.stream.pages lastObject].meta.paging.nextCursor != nil && [self.stream.pages lastObject].meta.paging.nextCursor.length > 0) {
                self.loadingMore = true;
                [self getPosts];
             }
            
            return footer;
        }
    }
    
    return nil;
}

@end