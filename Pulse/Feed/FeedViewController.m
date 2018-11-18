//
//  FeedViewController.m
//
//
//  Created by Austin Valleskey on 9/19/18.
//

#import "FeedViewController.h"
#import "LauncherNavigationViewController.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>

#define envConfig [[[NSUserDefaults standardUserDefaults] objectForKey:@"config"] objectForKey:[[NSUserDefaults standardUserDefaults] stringForKey:@"environment"]]

@interface FeedViewController () {
    int previousTableViewYOffset;
}

@property (nonatomic) BOOL loading;

@property CGFloat minHeaderHeight;
@property CGFloat maxHeaderHeight;
@property (nonatomic, strong) NSMutableArray *posts;

@property (strong, nonatomic) LauncherNavigationViewController *launchNavVC;

@end

@implementation FeedViewController

static NSString * const reuseIdentifier = @"Post";
static NSString * const suggestionsCellIdentifier = @"ChannelSuggestionsCell";

- (id)initWithFeedId:(NSString *)feedId {
    self = [super init];
    if (self) {
        self.feedId = feedId;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
    // self.navigationItem.hidesBackButton = true;
    
    [self setupTableView];
    [self setupErrorView];
    [self setupNavigationBar];
    
    self.manager = [HAWebService manager];
    [self setupContent];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self styleOnAppear];
}

- (void)styleOnAppear {
    CGFloat navigationHeight = self.navigationController != nil ? self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height : 0;
    CGFloat tabBarHeight = self.navigationController.tabBarController != nil ? self.navigationController.tabBarController.tabBar.frame.size.height : 0;
    self.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, [UIScreen mainScreen].bounds.size.height - navigationHeight);
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, tabBarHeight + 24, 0);
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, tabBarHeight, 0);
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.tableView.center.y - bottomPadding);
}

- (void)setupErrorView {
    self.errorView = [[ErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100) title:@"Room Not Found" description:@"We couldn’t find the Room you were looking for" type:ErrorViewTypeNotFound];
    self.errorView.center = self.tableView.center;
    self.errorView.hidden = true;
    [self.view addSubview:self.errorView];
    
    [self.errorView bk_whenTapped:^{
        self.errorView.hidden = true;
        
        self.tableView.loading = true;
        self.tableView.loadingMore = false;
        [self.tableView reloadData];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self getPostsWithSinceId:0];
        });
    }];
}

- (void)setupContent {
    self.content = [[NSMutableArray alloc] init];
    
    [self getPostsWithSinceId:0];
}

- (void)setupNavigationBar {
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)getPostsWithSinceId:(NSInteger)sinceId {
    NSString *url;
    if ([self.feedId isEqualToString:@"trending"]) {
        url = [NSString stringWithFormat:@"%@/%@/streams/trending", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
    }
    else if ([self.feedId isEqualToString:@"timeline"]) {
        url = [NSString stringWithFormat:@"%@/%@/streams/me", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
    }
    
    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            [self.manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSArray *responseData = (NSArray *)responseObject[@"data"];
                
                if (sinceId == 0) {
                    // first page
                    self.tableView.data = [[NSMutableArray alloc] initWithArray:responseData];
                    
                    if (self.tableView.data.count == 0) {
                        // Error: No posts yet!
                        self.errorView.hidden = false;
                        
                        [self.errorView updateType:ErrorViewTypeHeart];
                        [self.errorView updateTitle:@"For You"];
                        [self.errorView updateDescription:@"The posts you care about from the Rooms and people you care about."];
                    }
                    else {
                        self.errorView.hidden = true;
                    }
                }
                else {
                    // appended posts
                    self.tableView.data = [[NSMutableArray alloc] initWithArray:[self.tableView.data arrayByAddingObjectsFromArray:responseData]];
                }
                
                self.loading = false;
                
                self.tableView.loading = false;
                self.tableView.loadingMore = false;
                
                [self.tableView refresh];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"FeedViewController / getPosts() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                if (self.tableView.data.count == 0) {
                    self.errorView.hidden = false;
                    [self.errorView updateType:ErrorViewTypeGeneral];
                    [self.errorView updateTitle:@"Error Loading"];
                    [self.errorView updateDescription:@"Check your network settings and tap here to try again"];
                }
                
                self.loading = false;
                self.tableView.loading = false;
                self.tableView.loadingMore = false;
                self.tableView.userInteractionEnabled = true;
                [self.tableView refresh];
            }];
        }
    }];
}
- (void)setupTableView {
    self.tableView = [[RSTableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.frame = self.view.bounds;
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 60, 0);
    self.tableView.dataType = tableCategoryFeed;
    self.tableView.loading = true;
    [self.view addSubview:self.tableView];
}

- (void)tableView:(id)tableView didRequestNextPageWithSinceId:(NSInteger)sinceId {
    // NSLog(@"FeedViewController:: didRequestNextPageWithSinceID: %ld", (long)sinceId);
    [self getPostsWithSinceId:sinceId];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
