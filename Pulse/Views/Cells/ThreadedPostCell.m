//
//  ThreadedPostCell.m
//  Pulse
//
//  Created by Austin Valleskey on 2/1/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "ThreadedPostCell.h"
#import "ReplyCell.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import "InsightsLogger.h"
#import "Launcher.h"
#import "ExpandThreadCell.h"

@implementation ThreadedPostCell

static NSString * const replyReuseIdentifier = @"BubblePost";
static NSString * const blankCellIdentifier = @"BlankCell";
static NSString * const addAReplyCellIdentifier = @"addAReplyCell";
static NSString * const expandRepliesCellIdentifier = @"expandRepliesCell";

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        //self.lineSeparator.hidden = true;
        [self setupRepliesTableView];
        
        self.threadLine = [[UIView alloc] initWithFrame:CGRectMake(self.profilePicture.frame.origin.x + (self.profilePicture.frame.size.width / 2) - 1.5, self.profilePicture.frame.origin.y + self.profilePicture.frame.size.height + 4, 3, 0)];
        self.threadLine.backgroundColor = [UIColor fromHex:@"EDEDED"];
        self.threadLine.layer.cornerRadius = self.threadLine.frame.size.width / 2;
        self.threadLine.userInteractionEnabled = false;
        //[self addSubview:self.threadLine];
    }
    
    return self;
}

- (void)setupRepliesTableView {
    self.repliesTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.frame.size.height, self.frame.size.width, 1000) style:UITableViewStylePlain];
    self.repliesTableView.scrollIndicatorInsets = UIEdgeInsetsZero;
    self.repliesTableView.contentInset = UIEdgeInsetsZero;
    self.repliesTableView.refreshControl = nil;
    self.repliesTableView.backgroundColor = [UIColor clearColor];
    self.repliesTableView.tintColor = self.tintColor;
    self.repliesTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.repliesTableView.delegate = self;
    self.repliesTableView.dataSource = self;
    
    [self insertSubview:self.repliesTableView belowSubview:self.lineSeparator];
    
    [self.repliesTableView registerClass:[ReplyCell class] forCellReuseIdentifier:replyReuseIdentifier];
    [self.repliesTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:addAReplyCellIdentifier];
    [self.repliesTableView registerClass:[ExpandThreadCell class] forCellReuseIdentifier:expandRepliesCellIdentifier];
    [self.repliesTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellIdentifier];
    
    self.replies = [[NSMutableArray alloc] init];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.repliesMode == PostCellRepliesModeNone)
        return 0;
    
    if (section == 0) {
        // "view previous replies (x)" or "hide replies"
        if (self.repliesMode == PostCellRepliesModeThread) {
            return 0;
        }
    }
    else if (section == 1) {
        if (self.repliesMode == PostCellRepliesModeThread) {
            BOOL collapsed = (self.post.attributes.details.replies.count == 0 && self.post.attributes.summaries.counts.replies > 0);
            
            return collapsed ? 1 : self.post.attributes.details.replies.count;
        }
        else if (self.repliesMode == PostCellRepliesModeSnapshot) {
            return self.post.attributes.summaries.replies.count;
        }
    }
    else if (section == 2) {
        // view more replies (x)
        if (self.repliesMode == PostCellRepliesModeThread) {
            return 0;
        }
        else if (self.repliesMode == PostCellRepliesModeSnapshot) {
            if (self.post.attributes.summaries.counts.replies > self.post.attributes.summaries.replies.count) {
                // view all x replies
                return 1;
            }
        }
    }
    else if (section == 3) {
        // add a reply...
        return 0;
    }
    
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 || indexPath.section == 2) {
        return THREADED_POST_EXPAND_CELL_HEIGHT;
    }
    if (indexPath.section == 1) {
        BOOL collapsed = (self.post.attributes.details.replies.count == 0 && self.post.attributes.summaries.counts.replies > 0);
        
        if (collapsed && self.repliesMode == PostCellRepliesModeThread) {
            return 40;
        }
        else if (indexPath.row < self.post.attributes.summaries.replies.count) {
            Post *reply = self.post.attributes.summaries.replies[indexPath.row];
            return reply.rowHeight;
        }
    }
    if (indexPath.section == 3) {
        return THREADED_POST_ADD_REPLY_CELL_HEIGHT;
    }
    
    return 0;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    BOOL collapsed = (self.post.attributes.details.replies.count == 0 && self.post.attributes.summaries.counts.replies > 0);
    
    if (indexPath.section == 0 || indexPath.section == 2 ||
        (indexPath.section == 1 && collapsed && self.repliesMode == PostCellRepliesModeThread))
    {
        // expand cells
        ExpandThreadCell *cell = [tableView dequeueReusableCellWithIdentifier:expandRepliesCellIdentifier forIndexPath:indexPath];
        
        if (!cell) {
            cell = [[ExpandThreadCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:expandRepliesCellIdentifier];
        }
        
        // cell.morePostsIcon.frame = CGRectMake(postContentOffset.left, 0, 36, cell.frame.size.height);
        
        if (indexPath.section == 0) {
            cell.contentView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1];
        }
        else if (indexPath.section == 1 && collapsed && self.repliesMode == PostCellRepliesModeThread) {
            cell.textLabel.text = [NSString stringWithFormat:@"View replies (%ld)", (long)self.post.attributes.summaries.counts.replies];
            cell.contentView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        }
        else if (indexPath.section == 2) {
            if (self.repliesMode == PostCellRepliesModeSnapshot) {
                cell.textLabel.text = [NSString stringWithFormat:@"View All %ld Replies", (long)self.post.attributes.summaries.counts.replies];
            }
            else {
                cell.textLabel.text = [NSString stringWithFormat:@"View more replies (%ld)", (long)self.post.attributes.summaries.counts.replies - self.post.attributes.details.replies.count];
            }
        }
        
        return cell;
    }
    else if (indexPath.section == 1 &&
             indexPath.row < self.post.attributes.summaries.replies.count) {
        ReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:replyReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[ReplyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:replyReuseIdentifier];
        }
        
        cell.tintColor = self.tintColor;
        cell.backgroundColor = [UIColor clearColor];
        cell.contentView.backgroundColor = [UIColor clearColor];
        
        NSInteger identifierBefore = cell.post.identifier;
        
        Post *reply = self.post.attributes.summaries.replies[indexPath.row];
        cell.post = reply;
        
        cell.nameLabel.attributedText = [PostCell attributedCreatorStringForPost:cell.post includeTimestamp:true includePostedIn:false];
        
        if (cell.post.identifier != 0 && identifierBefore == cell.post.identifier) {
            //[self didBeginDisplayingCell:cell];
        }
        
        cell.lineSeparator.hidden = true;
        // cell.detailsType = DetailsViewTypeNone;
        
        cell.dateLabel.hidden = true;
        
        return cell;
    }
    else if (indexPath.section == 3) {
        // add a reply...
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:addAReplyCellIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:addAReplyCellIdentifier];
            
            cell.contentView.backgroundColor = [UIColor redColor];
        }
        
        return cell;
    }
    
    // if all else fails, return a blank cell
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankCellIdentifier forIndexPath:indexPath];
    blankCell.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1*indexPath.row];
    return blankCell;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    //self.repliesTableView.frame = CGRectMake(0, self.detailsView.frame.origin.y + self.detailsView.frame.size.height + 8, self.frame.size.width,  self.repliesTableView.frame.size.height);
    
    [self.repliesTableView reloadData];
    dispatch_async (dispatch_get_main_queue(), ^{
        // self.repliesTableView.frame = CGRectMake(0, self.detailsView.frame.origin.y + self.detailsView.frame.size.height + 8, self.frame.size.width,  self.repliesTableView.contentSize.height);
        
        self.threadLine.hidden = (self.post.attributes.summaries.replies.count == 0);
        
        NSLog(@"self.threadLine: %@", self.threadLine);
        if (self.post.attributes.summaries.replies.count > 0) {
            NSLog(@"change replies frame");
            CGFloat threadLineYtop = self.profilePicture.frame.origin.y + self.profilePicture.frame.size.height + 4;
            self.threadLine.frame = CGRectMake(self.profilePicture.frame.origin.x + (self.profilePicture.frame.size.width / 2) - 1.5, threadLineYtop, 3, self.frame.size.height - threadLineYtop);
        }
    });
    self.repliesTableView.userInteractionEnabled = (self.repliesMode != PostCellRepliesModeSnapshot);
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"did select row at index path");
}

+ (CGFloat)heightOfRepliesForPost:(Post *)post {
    BOOL collapsed = (post.attributes.details.replies.count == 0 && post.attributes.summaries.counts.replies > 0);
    if (collapsed) {
        return 40;
    }
    
    BOOL showPreviousReplies = true;
    BOOL showMoreReplies = true;
    BOOL showAddAReply = true;
    
    float height = 0;
    if (showPreviousReplies)
        height += 40;
    
    for (int i = 0; i < post.attributes.details.replies.count; i++) {
        height = height + post.attributes.details.replies[i].rowHeight;
    }
    
    if (showMoreReplies)
        height += 40;
    
    if (showAddAReply)
        height += 48;
    
    NSLog(@"height of replies for post(%ld): %f", post.identifier, height);
    
    return height;
}

- (void)setRepliesMode:(PostCellRepliesMode)repliesMode {
    if (repliesMode != _repliesMode) {
        _repliesMode = repliesMode;
        
        [self.repliesTableView reloadData];
    }
}

- (BOOL)collapsed {
    return (self.post.attributes.details.replies.count == 0 && self.post.attributes.summaries.counts.replies > 0);
}

@end
