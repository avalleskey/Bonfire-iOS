//
//  RSTableView.m
//  Pulse
//
//  Created by Austin Valleskey on 10/4/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "RSTableView.h"
#import "ComplexNavigationController.h"

#import "CampHeaderCell.h"
#import "ProfileHeaderCell.h"

#import "StreamPostCell.h"
#import "ReplyCell.h"
#import "ExpandThreadCell.h"
#import "ExpandedPostCell.h"
#import "AddReplyCell.h"
#import "BFErrorViewCell.h"

#import "LoadingCell.h"
#import "PaginationCell.h"
#import "Launcher.h"
#import "BFHeaderView.h"
#import "UIColor+Palette.h"
#import "CampViewController.h"
#import "ProfileCampsListViewController.h"
#import "InsightsLogger.h"

#import "PostViewController.h"

#import <JGProgressHUD/JGProgressHUD.h>
#import <HapticHelper/HapticHelper.h>
@import Firebase;

#define SHOW_CURSORS false

@interface RSTableView ()

@property (strong, nonatomic) NSMutableDictionary *cellHeightsDictionary;

@end

@implementation RSTableView

@synthesize dataType = _dataType;  //Must do this

static NSString * const expandedPostReuseIdentifier = @"ExpandedPost";
static NSString * const streamPostReuseIdentifier = @"StreamPost";
static NSString * const streamMediaPostReuseIdentifier = @"StreamPost_media";
static NSString * const streamLinkPostReuseIdentifier = @"StreamPost_link";
static NSString * const streamSmartLinkPostReuseIdentifier = @"StreamPost_smart_link";
static NSString * const streamCampPostReuseIdentifier = @"StreamPost_camp";
static NSString * const streamUserPostReuseIdentifier = @"StreamPost_user";
static NSString * const streamPostPostReuseIdentifier = @"StreamPost_post";

static NSString * const postReplyReuseIdentifier = @"ReplyReuseIdentifier";
static NSString * const expandRepliesCellIdentifier = @"ExpandRepliesReuseIdentifier";
static NSString * const addReplyCellIdentifier = @"AddReplyReuseIdentifier";

static NSString * const previewReuseIdentifier = @"PreviewPost";
static NSString * const errorCellReuseIdentifier = @"ErrorCell";
static NSString * const blankCellIdentifier = @"BlankCell";

static NSString * const loadingCellIdentifier = @"LoadingCell";
static NSString * const paginationCellIdentifier = @"PaginationCell";

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:UITableViewStyleGrouped];
    if (self) {
        [self setup];
    }
    
    return self;
}
- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}

//Setter method
- (void)setDataType:(RSTableViewType)dataType {
    if (_dataType != dataType) {
        _dataType = dataType;
        [self refreshAtTop];
    }
}
    
//Getter method
- (RSTableViewType)dataType {
    return _dataType;
}

//Setter method
- (void)setTableViewStyle:(RSTableViewStyle)tableViewStyle {
    if (tableViewStyle != _tableViewStyle) {
        _tableViewStyle = tableViewStyle;
        
        if (tableViewStyle == RSTableViewStyleDefault) {
            self.backgroundColor = [UIColor colorNamed:@"FullContrastColor"];
        }
        else {
            self.backgroundColor = [UIColor clearColor];
        }
        
        [self refreshAtTop];
    }
}

- (void)hardRefresh {
    self.cellHeightsDictionary = @{}.mutableCopy;
    
    [self reloadData];
    [self layoutIfNeeded];
    
    if (!self.loading) {
        [self.refreshControl endRefreshing];
    }
}
- (void)refreshAtTop {
    self.cellHeightsDictionary = @{}.mutableCopy;
    
    [self layoutIfNeeded];
    CGSize beforeContentSize = self.contentSize;
    
    BOOL wasLoading = ([[self.visibleCells firstObject] isKindOfClass:[LoadingCell class]]);
    
    [self reloadData];
    [self layoutIfNeeded];
        
    if (!self.loading) {
        [self.refreshControl performSelector:@selector(endRefreshing) withObject:nil afterDelay:0.0];
        
        if (!wasLoading && self.dataType == RSTableViewTypeFeed) {
            CGSize afterContentSize = self.contentSize;

            CGPoint afterContentOffset = self.contentOffset;
            CGPoint newContentOffset = CGPointMake(afterContentOffset.x, MAX(afterContentOffset.y + afterContentSize.height - beforeContentSize.height, -1 * self.adjustedContentInset.top));
            
            self.contentOffset = newContentOffset;
        }
    }
}
- (void)refreshAtBottom {
    self.cellHeightsDictionary = @{}.mutableCopy;
    
    [self layoutIfNeeded];
    [self reloadData];
    [self layoutIfNeeded];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self && [self.extendedDelegate respondsToSelector:@selector(tableViewDidScroll:)]) {
        [self.extendedDelegate tableViewDidScroll:self];
                
        UINavigationController *navController = UIViewParentController(self).navigationController;
        if (navController) {
            if ([navController isKindOfClass:[ComplexNavigationController class]]) {
                ComplexNavigationController *complexNav = (ComplexNavigationController *)navController;
                [complexNav childTableViewDidScroll:self];
            }
            else if ([navController isKindOfClass:[SimpleNavigationController class]]) {
                SimpleNavigationController *simpleNav = (SimpleNavigationController *)navController;
                [simpleNav childTableViewDidScroll:self];
            }
        }
    }
}

- (void)scrollToTop {
    [self layoutIfNeeded];
//    [self reloadData];
    [self scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:true];
}

- (void)setup {
    self.stream = [[PostStream alloc] init];
    self.loading = true;
    self.loadingMore = false;
    self.delegate = self;
    self.dataSource = self;
    self.separatorColor = [UIColor tableViewSeparatorColor];
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
    self.cellHeightsDictionary = @{}.mutableCopy;
    self.estimatedRowHeight = 0;
    self.estimatedSectionHeaderHeight = 0;
    self.estimatedSectionFooterHeight = 0;
    self.tableViewStyle = RSTableViewStyleDefault;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self sendSubviewToBack:self.refreshControl];
        
    [self registerClass:[ExpandedPostCell class] forCellReuseIdentifier:expandedPostReuseIdentifier];
    
    [self registerClass:[StreamPostCell class] forCellReuseIdentifier:streamPostReuseIdentifier];
    [self registerClass:[StreamPostCell class] forCellReuseIdentifier:streamMediaPostReuseIdentifier];
    [self registerClass:[StreamPostCell class] forCellReuseIdentifier:streamLinkPostReuseIdentifier];
    [self registerClass:[StreamPostCell class] forCellReuseIdentifier:streamCampPostReuseIdentifier];
    [self registerClass:[StreamPostCell class] forCellReuseIdentifier:streamUserPostReuseIdentifier];
    [self registerClass:[StreamPostCell class] forCellReuseIdentifier:streamPostPostReuseIdentifier];
    [self registerClass:[StreamPostCell class] forCellReuseIdentifier:streamSmartLinkPostReuseIdentifier];
    
    [self registerClass:[ReplyCell class] forCellReuseIdentifier:postReplyReuseIdentifier];
    [self registerClass:[ExpandThreadCell class] forCellReuseIdentifier:expandRepliesCellIdentifier];
    [self registerClass:[AddReplyCell class] forCellReuseIdentifier:addReplyCellIdentifier];
    
    [self registerClass:[BFErrorViewCell class] forCellReuseIdentifier:errorCellReuseIdentifier];
    [self registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellIdentifier];
    
    [self registerClass:[LoadingCell class] forCellReuseIdentifier:loadingCellIdentifier];
    [self registerClass:[PaginationCell class] forCellReuseIdentifier:paginationCellIdentifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postUpdated:) name:@"PostUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postDeleted:) name:@"PostDeleted" object:nil];
}

- (UIViewController *)getParentViewController:(UIView *)view {
  UIResponder *parentResponder = view;

  while (parentResponder) {
    parentResponder = parentResponder.nextResponder;
    if ([parentResponder isKindOfClass:[UIViewController class]]) {
      return (UIViewController *)parentResponder;
    }
  }

  return nil;
}

- (void)postUpdated:(NSNotification *)notification {
    Post *post = notification.object;
    // NSLog(@"post that's updated: %@", post);
    
    if (post != nil) {
        // new post appears valid
        BOOL changes = [self.stream updatePost:post removeDuplicates:true];
        
        if (changes) {
            // 💫 changes made
            _cellHeightsDictionary = [NSMutableDictionary new];
            
            // NSLog(@"parent controller: %@", UIViewParentController(self));
            if (![[Launcher activeViewController] isEqual:UIViewParentController(self)]) {
                [self refreshAtTop];
            }
        }
    }
}
- (void)postDeleted:(NSNotification *)notification {
    if (![notification.object isKindOfClass:[Post class]]) return;
    
    Post *post = notification.object;
    BOOL isReply = post.attributes.parent;
    BOOL postedInCamp = post.attributes.postedIn != nil;
    
    BOOL removePost = false;
    BOOL refresh = false;
    
    Post *postInStream = [self.stream postWithId:post.identifier];
    if (postInStream) {
        removePost = true;
        refresh = true;
    }
    
    if ([self.parentObject isKindOfClass:[Camp class]] && postedInCamp) {
        Camp *parentCamp = self.parentObject;
        
        // determine type of post (post or reply)
        if ([parentCamp.identifier isEqualToString:post.attributes.postedIn.identifier]) {
            removePost = true;
            refresh = true;
            // Camp that contains post
            if (isReply) {
                // Decrement Post replies count
                Post *updatedPost = [self.stream postWithId:post.attributes.parent.identifier];
                if (updatedPost) {
                    updatedPost.attributes.summaries.counts.replies = updatedPost.attributes.summaries.counts.replies - 1;
        
                    // update replies
                    NSMutableArray <Post *><Post> *mutableReplies = [[NSMutableArray<Post *><Post> alloc] initWithArray:updatedPost.attributes.summaries.replies];
                    NSMutableArray *repliesToDelete = [[NSMutableArray alloc] init];
                    for (NSInteger i = 0; i < mutableReplies.count; i++) {
                        Post *reply = mutableReplies[i];
                        if (reply.identifier == post.identifier) {
                            [repliesToDelete addObject:reply];
                        }
                    }
                    if (repliesToDelete.count > 0) {
                        [mutableReplies removeObjectsInArray:repliesToDelete];
                        updatedPost.attributes.summaries.replies = mutableReplies;
                    }
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUpdated" object:updatedPost];
                    
                    NSLog(@"✅ Decrement Post replies count inside Camp");
                }
            }
            else {
                // Decrement Camp posts count
                parentCamp.attributes.summaries.counts.posts = parentCamp.attributes.summaries.counts.posts - 1;
                
                NSLog(@"✅ Decrement Camp posts count");
            }
        }
    }
    
    if (removePost) [self.stream removePost:post];
    if (refresh) [self hardRefresh];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(cellForRowInFirstSection:)]) {
            id cell = [self.extendedDelegate cellForRowInFirstSection:indexPath.row];
            if (cell != nil) {
                return cell;
            }
        }
    }
    else if (self.stream.posts.count == 0) {
        if (self.loading) {
            // loading cell
            LoadingCell *cell = [tableView dequeueReusableCellWithIdentifier:loadingCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[LoadingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:loadingCellIdentifier];
            }
            
            NSInteger postType = (indexPath.section - 1 % 3);
            cell.type = postType;
            
            cell.userInteractionEnabled = false;
            
            return cell;
        }
        else if (self.visualError) {
            // loading cell
            BFErrorViewCell *cell = [tableView dequeueReusableCellWithIdentifier:errorCellReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[BFErrorViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:errorCellReuseIdentifier];
            }
            
            cell.tintColor = self.tintColor;
            cell.visualError = self.visualError;
            
            return cell;
        }
    }
    else if (self.stream.posts.count > indexPath.section - 1) {
        // Content
        NSInteger adjustedIndex = indexPath.section - 1;
        
        // determine if it's a reply or sub-reply
        Post *post = self.stream.posts[adjustedIndex];
        CGFloat replies = post.attributes.summaries.replies.count;
        // 0       : actual reply
        // 1       : --- "hide replies"
        // 2-(x+1) : --- replies
        // (x+1)+1 : --- "view more replies"
        // (x+1)+2 : --- "add a reply..."
        
        BOOL showViewMore = post.attributes.summaries.replies.count > 0 && (replies < post.attributes.summaries.counts.replies);
        BOOL showAddReply = [post.attributes.context.post.permissions canReply] &&  post.attributes.summaries.replies.count > 0;
        //BOOL lastCell = (indexPath.section == [tableView numberOfSections] - 1);
        
        NSInteger firstReplyIndex = 1;
        
        if (indexPath.row == 0) {
            NSString *reuseIdentifier = streamPostReuseIdentifier;
            if (post.attributes.attachments.media) {
                reuseIdentifier = streamMediaPostReuseIdentifier;
            }
            else if (post.attributes.attachments.link) {
                if ([post.attributes.attachments.link isSmartLink]) {
                    reuseIdentifier = streamSmartLinkPostReuseIdentifier;
                }
                else {
                    reuseIdentifier = streamLinkPostReuseIdentifier;
                }
            }
            else if (post.attributes.attachments.user) {
                reuseIdentifier = streamUserPostReuseIdentifier;
            }
            else if (post.attributes.attachments.camp) {
                reuseIdentifier = streamCampPostReuseIdentifier;
            }
            else if (post.attributes.attachments.post) {
                reuseIdentifier = streamPostPostReuseIdentifier;
            }

            StreamPostCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];

            if (cell == nil) {
                cell = [[StreamPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
            }

            NSString *identifierBefore = cell.post.identifier;

            cell.showContext = true;
            cell.showCamptag = true;
            cell.post = post;

            if (cell.post.identifier != 0 && [identifierBefore isEqualToString:cell.post.identifier]) {
                [self didBeginDisplayingCell:cell];
            }

            if (cell.actionsView.replyButton.gestureRecognizers.count == 0) {
                [cell.actionsView.replyButton bk_whenTapped:^{
                    [Launcher openComposePost:cell.post.attributes.postedIn inReplyTo:cell.post withMessage:nil media:nil quotedObject:nil];
                }];
            }
            
            cell.lineSeparator.hidden = post.attributes.summaries.replies.count > 0 || showViewMore || showAddReply;
            cell.bottomLine.hidden = true;//!([cell.lineSeparator isHidden]);

            return cell;
        }
        else if ((indexPath.row - firstReplyIndex) <  post.attributes.summaries.replies.count) {
            NSInteger replyIndex = indexPath.row - firstReplyIndex;
            
            // reply
            ReplyCell *cell = [self dequeueReusableCellWithIdentifier:postReplyReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[ReplyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:postReplyReuseIdentifier];
            }
            
            cell.contentView.backgroundColor = [UIColor contentBackgroundColor];
            
            cell.levelsDeep = -1; // must set this BEFORE the 'post' setter
            
            NSString *identifierBefore = cell.post.identifier;
            
            Post *subReply = post.attributes.summaries.replies[replyIndex];
            cell.post = subReply;
            
            if (cell.post.identifier != 0 && [identifierBefore isEqualToString:cell.post.identifier]) {
                [self didBeginDisplayingCell:cell];
            }
            
            cell.lineSeparator.hidden = !((indexPath.row == post.attributes.summaries.replies.count + firstReplyIndex - 1) && !showViewMore && !showAddReply);
            
            cell.selectable = YES;
            
            return cell;
        }
        else if (showViewMore && indexPath.row == post.attributes.summaries.replies.count + firstReplyIndex) {
            // "view more replies"
            ExpandThreadCell *cell = [tableView dequeueReusableCellWithIdentifier:expandRepliesCellIdentifier forIndexPath:indexPath];
            
            if (!cell) {
                cell = [[ExpandThreadCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:expandRepliesCellIdentifier];
            }
            
            BOOL hasExistingReplies = post.attributes.summaries.replies.count != 0;
            cell.textLabel.text = [NSString stringWithFormat:@"View%@ replies (%ld)", (hasExistingReplies ? @" more" : @""), (long)post.attributes.summaries.counts.replies - post.attributes.summaries.replies.count];
            
            if (hasExistingReplies) {
                // view more replies
                cell.tag = 2;
            }
            else {
                // start replies chain
                cell.tag = 3;
            }
            
            cell.lineSeparator.hidden = showAddReply;
            cell.levelsDeep = -1;
            
            return cell;
        }
        else if (showAddReply && indexPath.row == post.attributes.summaries.replies.count + firstReplyIndex + (showViewMore ? 1 : 0)) {
            // "add a reply"
            AddReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:addReplyCellIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[AddReplyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:addReplyCellIdentifier];
            }
            
            NSString *username = post.attributes.creator.attributes.identifier;
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Reply to @%@...", username] attributes:@{NSFontAttributeName: cell.addReplyButton.titleLabel.font, NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
            [attributedString setAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:cell.addReplyButton.titleLabel.font.pointSize weight:UIFontWeightSemibold]} range:[attributedString.string rangeOfString:[NSString stringWithFormat:@"@%@", username]]];
            [cell.addReplyButton setAttributedTitle:attributedString forState:UIControlStateNormal];
            
            cell.levelsDeep = -1;
            
            return cell;
        }
    }

    // if all else fails, return a blank cell
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankCellIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point  API_AVAILABLE(ios(13.0)){
    if ([[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[PostCell class]]) {
        Post *post = ((PostCell *)[tableView cellForRowAtIndexPath:indexPath]).post;
        
        if (post) {
            NSMutableArray *actions = [NSMutableArray new];
            if ([post.attributes.context.post.permissions canReply]) {
                UIAction *replyAction = [UIAction actionWithTitle:@"Reply" image:[UIImage systemImageNamed:@"arrowshape.turn.up.left"] identifier:@"reply" handler:^(__kindof UIAction * _Nonnull action) {
                    wait(0, ^{
                        [Launcher openComposePost:post.attributes.postedIn inReplyTo:post withMessage:nil media:nil  quotedObject:nil];
                    });
                }];
                [actions addObject:replyAction];
            }
            
//            UIAction *quoteAction = [UIAction actionWithTitle:@"Quote" image:[UIImage systemImageNamed:@"quote.bubble"] identifier:@"quote" handler:^(__kindof UIAction * _Nonnull action) {
//                wait(0, ^{
//                    [Launcher openComposePost:nil inReplyTo:nil withMessage:nil media:nil  quotedObject:post];
//                });
//            }];
//            [actions addObject:quoteAction];
            
            if (post.attributes.postedIn) {
                UIAction *openCamp = [UIAction actionWithTitle:@"Open Camp" image:[UIImage systemImageNamed:@"number"] identifier:@"open_camp" handler:^(__kindof UIAction * _Nonnull action) {
                    wait(0, ^{
                        Camp *camp = [[Camp alloc] initWithDictionary:[post.attributes.postedIn toDictionary] error:nil];
                        
                        [Launcher openCamp:camp];
                    });
                }];
                [actions addObject:openCamp];
            }
            
            UIAction *shareViaAction = [UIAction actionWithTitle:@"Share via..." image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:@"share_via" handler:^(__kindof UIAction * _Nonnull action) {
                [Launcher sharePost:post];
            }];
            [actions addObject:shareViaAction];
            
            UIMenu *menu = [UIMenu menuWithTitle:@"" children:actions];
            
            PostViewController *postVC = [Launcher postViewControllerForPost:post];
            postVC.isPreview = true;
            
            UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:indexPath previewProvider:^(){return postVC;} actionProvider:^(NSArray* suggestedAction){return menu;}];
            return configuration;
        }
    }
    
    return nil;
}
- (void)tableView:(UITableView *)tableView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator  API_AVAILABLE(ios(13.0)){
    NSIndexPath *indexPath = (NSIndexPath *)configuration.identifier;
    
    [animator addCompletion:^{
        wait(0, ^{
            if ([[tableView cellForRowAtIndexPath:indexPath] isKindOfClass:[PostCell class]]) {
                Post *post = ((PostCell *)[tableView cellForRowAtIndexPath:indexPath]).post;
                
                [Launcher openPost:post withKeyboard:false];
            }
        });
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 0;
    
    if ([_cellHeightsDictionary objectForKey:indexPath] && !self.loading) {
        return [_cellHeightsDictionary[indexPath] doubleValue];
    }
    
    if (indexPath.section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(heightForRowInFirstSection:)]) {
            height = [self.extendedDelegate heightForRowInFirstSection:indexPath.row];
        }
    }
    else if (self.stream.posts.count == 0) {
        if (self.loading) {
            switch ((indexPath.section - 1) % 3) {
                case 0:
                    height = 102;
                    break;
                case 1:
                    height = 123;
                    break;
                case 2:
                    height = 310 + 56;
                    break;
                    
                default:
                    height = 102;
                    break;
            }
        }
        else if (self.visualError) {
            return [BFErrorViewCell heightForVisualError:self.visualError];
        }
    }
    else if (indexPath.section - 1 < self.stream.posts.count && [self.stream.posts[indexPath.section-1].type isEqualToString:@"post"]) {
        Post *post = self.stream.posts[indexPath.section-1];
        CGFloat replies = post.attributes.summaries.replies.count;
        
        BOOL showViewMore = (replies < post.attributes.summaries.counts.replies);
        BOOL showAddReply = [post.attributes.context.post.permissions canReply] &&  post.attributes.summaries.replies.count > 0;
        
        NSInteger firstReplyIndex = 1;
        
        if (indexPath.row == 0) {
            // BOOL showActions = (reply.attributes.summaries.replies.count == 0);
            return [StreamPostCell heightForPost:post showContext:true showActions:true minimizeLinks:false];
        }
        else if ((indexPath.row - firstReplyIndex) < replies) {
            NSInteger replyIndex = indexPath.row - firstReplyIndex;
            Post *reply = post.attributes.summaries.replies[replyIndex];
            height = [ReplyCell heightForPost:reply levelsDeep:-1];
            
            if ((replyIndex == replies - 1) && !showViewMore && showAddReply) {
                // remove the bottom padding of the cell, since the add reply cell includes that padding
                height -= replyContentOffset.bottom;
            }
        }
        else if (showViewMore && indexPath.row == post.attributes.summaries.replies.count + firstReplyIndex) {
            // "view more replies"
            height = [ExpandThreadCell height];
        }
        else if (showAddReply && indexPath.row == post.attributes.summaries.replies.count + firstReplyIndex + (showViewMore ? 1 : 0)) {
            // "add a reply"
            height = [AddReplyCell height];
        }
    }
    else if (indexPath.section - 1 == self.stream.posts.count) {
        // pagination cell
        height = 52;
    }
    
    if (!self.loading) {
        [self.cellHeightsDictionary setObject:@(height) forKey:indexPath];
    }
    
    return height;
}

// give exact height value
//- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSNumber *height = [self.cellHeightsDictionary objectForKey:indexPath];
//    if (height) return height.doubleValue;
//    return 0;
//}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {    
    if (self.loading && self.stream.posts.count == 0) {
        self.scrollEnabled = false;
    }
    else {
        self.scrollEnabled = true;
    }
    
    if (self.stream.posts.count == 0) {
        if (self.loading) {
            return 10;
        }
        else if (self.visualError) {
            return 1 + 1;
        }
    }
    
    return 1 + self.stream.posts.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(numberOfRowsInFirstSection)]) {
            return [self.extendedDelegate numberOfRowsInFirstSection];
        }
    }
    else if (self.stream.posts.count == 0) {
        if (self.loading) {
            return 1;
        }
        else if (self.visualError) {
            return 1;
        }
    }
    else if (section <= self.stream.posts.count) {
        // content
        NSInteger adjustedIndex = section - 1;
        
        Post *reply = self.stream.posts[adjustedIndex];
        CGFloat replies = reply.attributes.summaries.replies.count;
        
        // 0   : "hide replies"
        // 1-x : replies
        // x+1 : "view more replies"
        // x+2 : "add a reply..."
        
        BOOL showViewMore = reply.attributes.summaries.replies.count > 0 && (replies < reply.attributes.summaries.counts.replies);
        BOOL showAddReply = [reply.attributes.context.post.permissions canReply] &&  reply.attributes.summaries.replies.count > 0;
        
        NSInteger rows = 1 + replies + (showViewMore ? 1 : 0) + (showAddReply ? 1 : 0);
        
        return rows;
    }
    
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(didSelectRowInFirstSection:)]) {
            return [self.extendedDelegate didSelectRowInFirstSection:indexPath.row];
        }
    }
    
    Post *post;
    
    UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
    
    if ([cell isKindOfClass:[StreamPostCell class]] || [cell isKindOfClass:[ReplyCell class]]) {
        if (!((PostCell *)cell).post) return;
        
        post = ((PostCell *)cell).post;
    }
    if ([cell isKindOfClass:[ExpandThreadCell class]]) {
        post = self.stream.posts[indexPath.section-1];
    }
    if ([cell isKindOfClass:[AddReplyCell class]]) {
        Post *postReplyingTo = self.stream.posts[indexPath.section-1];
        
        [Launcher openComposePost:postReplyingTo.attributes.postedIn inReplyTo:postReplyingTo withMessage:nil media:nil quotedObject:nil];
    }
    
    if (post) {
        [InsightsLogger.sharedInstance closePostInsight:post.identifier action:InsightActionTypeDetailExpand];
        [FIRAnalytics logEventWithName:@"conversation_expand"
                            parameters:@{
                                         @"post_id": post.identifier
                                         }];
        
        [Launcher openPost:post withKeyboard:false];
    }
}
//@property (nonatomic) NSInteger lastSinceId;
//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//    [self.cellHeightsDictionary setObject:@(cell.frame.size.height) forKey:indexPath];
//}
- (void)didBeginDisplayingCell:(UITableViewCell *)cell {
    Post *post;
    if ([cell isKindOfClass:[PostCell class]]) {
        post = ((PostCell *)cell).post;
    }
    else {
        return;
    }
    
    // skip logging if invalid post identifier (most likely due to a loading cell)
    if (post.identifier == 0) return;
            
    NSString *seenIn = InsightSeenInHomeView;
    switch (self.dataType) {
        case RSTableViewTypeFeed:
            if (self.dataSubType == RSTableViewSubTypeHome) {
                seenIn = InsightSeenInHomeView;
            }
            if (self.dataSubType == RSTableViewSubTypeTrending) {
                seenIn = InsightSeenInTrendingView;
            }
            break;
        case RSTableViewTypeCamp:
            seenIn = InsightSeenInCampView;
            break;
        case RSTableViewTypeProfile:
            seenIn = InsightSeenInProfileView;
            break;
    }
    
    //
    [InsightsLogger.sharedInstance openPostInsight:post.identifier seenIn:seenIn];
}
- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
    if ([tableView.indexPathsForVisibleRows indexOfObject:indexPath] == NSNotFound) {
        Post *post;
        if ([cell isKindOfClass:[PostCell class]]) {
            post = ((PostCell *)cell).post;
        }
        else {
            return;
        }
        
        // skip logging if invalid post identifier (most likely due to a loading cell)
        if (post.identifier == 0) return;
        
        [InsightsLogger.sharedInstance closePostInsight:post.identifier action:nil];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(heightForFirstSectionHeader)]) {
            return [self.extendedDelegate heightForFirstSectionHeader];
        }
    }
    
#if defined(DEBUG) && SHOW_CURSORS
    if (self.dataType == RSTableViewTypeFeed && section != 0 && self.stream.posts.count > section) {
        Post *post = self.stream.posts[section-1];

        if (post.prevCursor.length > 0) {
            return 24;
        }
    }
#endif
    
    if (section == 1 && (self.dataType == RSTableViewTypeProfile || self.dataType == RSTableViewTypeCamp) && (self.stream.posts.count > 0 || self.loading)) {
        return CGFLOAT_MIN;
        return [BFHeaderView height];
    }
    
    return CGFLOAT_MIN;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(viewForFirstSectionHeader)]) {
            return [self.extendedDelegate viewForFirstSectionHeader];
        }
    }
    
#if defined(DEBUG) && SHOW_CURSORS
    if (self.dataType == RSTableViewTypeFeed && section != 0 && self.stream.posts.count > section) {
        Post *post = self.stream.posts[section-1];

        if (post.prevCursor.length > 0) {
            UIView *derp = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 24)];
            derp.backgroundColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.08];

            UILabel *derpLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, derp.frame.size.width - 24, derp.frame.size.height)];
            NSString *string = @"";
            derpLabel.font = [UIFont systemFontOfSize:10.f weight:UIFontWeightRegular];
            derpLabel.textColor = [UIColor bonfireSecondaryColor];
            if (post.prevCursor.length > 0) {
                string = [@"prev: " stringByAppendingString:post.prevCursor];
            }
            derpLabel.text = string;
            [derp addSubview:derpLabel];

            [derp bk_whenTapped:^{
                [Launcher shareOniMessage:[NSString stringWithFormat:@"post id: %@\n\nprev cursor: %@", post.identifier, post.prevCursor] image:nil];
            }];

            return derp;
        }
    }
#endif
    
//    if (section == 0 && self.tableViewStyle == RSTableViewStyleGrouped) {
//        UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
//        lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
//
//        return lineSeparator;
//    }
    if (section == 1 && (self.stream.posts.count > 0 || self.loading)) {
        if (self.dataType == RSTableViewTypeProfile ||
            self.dataType == RSTableViewTypeCamp) {
            return nil;
            BFHeaderView *header = [[BFHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, [BFHeaderView height])];
            
            if (self.dataType == RSTableViewTypeCamp) {
                header.title = @"Posts";
                
                if ([self.parentObject isKindOfClass:[Camp class]]) {
                    Camp *camp = self.parentObject;
                    
                    if (camp.attributes.summaries.counts.live >= [Session sharedInstance].defaults.camp.scoreThreshold) {
                        header.subTitle = [NSString stringWithFormat:@"%ld 🔥", (long)camp.attributes.summaries.counts.live];
                        header.subTitleLabel.textColor = [UIColor bonfireBrand];
                    }
                    else {
                        header.subTitle = [NSString stringWithFormat:@"%ld", (long)camp.attributes.summaries.counts.posts];
                    }
                }
            }
            else if (self.dataType == RSTableViewTypeProfile) {
                header.title = @"Posts";
                
                NSLog(@"self.parentObject: %@", self.parentObject);
                
                if ([self.parentObject isKindOfClass:[User class]] && ((User *)self.parentObject).attributes.summaries.counts.posts > 0) {
                    User *user = self.parentObject;
                    header.subTitle = [NSString stringWithFormat:@"%ld", (long)user.attributes.summaries.counts.posts];
                }
                else {
                    header.subTitle = @"";
                }
            }
            else {
                header.title = @"Posts";
            }
            
            return header;
        }
    }
    
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(heightForFirstSectionFooter)]) {
            return [self.extendedDelegate heightForFirstSectionFooter];
        }
    }
    
    if (section != 0 && section == self.stream.posts.count) {
        // last row
        BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
        BOOL showLoadingFooter = (self.loadingMore || (hasAnotherPage && ![self.stream hasLoadedCursor:self.stream.nextCursor]));
        
        return showLoadingFooter ? 52 : 0;
    }
    
#if defined(DEBUG) && SHOW_CURSORS
    if (section != 0 && self.dataType == RSTableViewTypeFeed && self.stream.posts.count > section) {
        Post *post = self.stream.posts[section-1];

        if (post.nextCursor.length > 0) {
            return 24;
        }
    }
#endif
    
//    if (section > 0 && self.stream.posts.count > section) {
//        // we do (> section) instead of (> section - 1) because we only show a divider if there is content under the post
//        Post *post = self.stream.posts[section-1];
//        Post *nextPost = self.stream.posts[section]; // only show section block if next post isn't sectioned as well
//
//        if (post.attributes.summaries.replies.count > 0 && nextPost.attributes.summaries.replies.count == 0) {
//            return 12;
//        }
//    }
    
    return CGFLOAT_MIN;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        if ([self.extendedDelegate respondsToSelector:@selector(viewForFirstSectionFooter)]) {
            return [self.extendedDelegate viewForFirstSectionFooter];
        }
    }
    
    if (section != 0 && section == self.stream.posts.count) {
        // last row
        BOOL hasAnotherPage = self.stream.pages.count > 0 && self.stream.nextCursor.length > 0;
        BOOL showLoadingFooter = (self.loadingMore || (hasAnotherPage && ![self.stream hasLoadedCursor:self.stream.nextCursor]));
        
        if (showLoadingFooter) {
            UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 52)];
            
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            spinner.color = [UIColor bonfireSecondaryColor];
            spinner.frame = CGRectMake(footer.frame.size.width / 2 - 10, footer.frame.size.height / 2 - 10, 20, 20);
            [footer addSubview:spinner];
            
            [spinner startAnimating];
            
            if (!self.loadingMore && self.stream.pages.count > 0 && self.stream.nextCursor.length > 0) {
                self.loadingMore = true;
                
                if ([self.extendedDelegate respondsToSelector:@selector(tableView:didRequestNextPageWithMaxId:)]) {
                    [self.extendedDelegate tableView:self didRequestNextPageWithMaxId:0];
                }
            }
            
            return footer;
        }
    }
    
#if defined(DEBUG) && SHOW_CURSORS
    if (section != 0 && self.dataType == RSTableViewTypeFeed && self.stream.posts.count > section) {
        Post *post = self.stream.posts[section-1];

        if (post.nextCursor.length > 0) {
            UIView *derp = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 24)];
            derp.backgroundColor = [[UIColor separatorColor] colorWithAlphaComponent:0.5];

            UILabel *derpLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, derp.frame.size.width - 24, derp.frame.size.height)];
            NSString *string = @"";
            derpLabel.font = [UIFont systemFontOfSize:10.f weight:UIFontWeightRegular];
            derpLabel.textColor = [UIColor bonfireSecondaryColor];
            if (post.nextCursor.length > 0) {
                string = [@"next: " stringByAppendingString:post.nextCursor];
            }
            derpLabel.text = string;
            [derp addSubview:derpLabel];

            [derp bk_whenTapped:^{
                [Launcher shareOniMessage:[NSString stringWithFormat:@"post id: %@\n\nnext cursor: %@", post.identifier, post.nextCursor] image:nil];
            }];

            return derp;
        }
    }
#endif
    
    //if (section != 0 || self.tableViewStyle != RSTableViewStyleGrouped) return nil;
    
    UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, HALF_PIXEL)];
    lineSeparator.backgroundColor = [UIColor tableViewBackgroundColor];
    
    return nil; //lineSeparator;
}

@end
