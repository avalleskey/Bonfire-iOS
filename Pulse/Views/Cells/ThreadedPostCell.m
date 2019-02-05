//
//  ThreadedPostCell.m
//  Pulse
//
//  Created by Austin Valleskey on 2/1/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "ThreadedPostCell.h"
#import "ReplyPostCell.h"
#import "Launcher.h"

@implementation ThreadedPostCell

static NSString * const replyReuseIdentifier = @"BubblePost";
static NSString * const blankCellIdentifier = @"BlankCell";

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.repliesSnapshotView.hidden = true;
        self.lineSeparator.hidden = true;
        [self setupRepliesTableView];
    }
    
    return self;
}

- (void)setupRepliesTableView {
    self.repliesTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.frame.size.height, self.frame.size.width, 0) style:UITableViewStylePlain];
    self.repliesTableView.scrollIndicatorInsets = UIEdgeInsetsZero;
    self.repliesTableView.contentInset = UIEdgeInsetsZero;
    self.repliesTableView.refreshControl = nil;
    self.repliesTableView.backgroundColor = [UIColor clearColor];
    self.repliesTableView.tintColor = self.tintColor;
    self.repliesTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.repliesTableView.delegate = self;
    self.repliesTableView.dataSource = self;
    
    [self addSubview:self.repliesTableView];
    
    [self.repliesTableView registerClass:[ReplyPostCell class] forCellReuseIdentifier:replyReuseIdentifier];
    [self.repliesTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellIdentifier];
    
    self.replies = [[NSMutableArray alloc] init];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) {
        return self.post.attributes.summaries.replies.count;
    }
    
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.row < self.post.attributes.summaries.replies.count) {
        Post *reply = self.post.attributes.summaries.replies[indexPath.row];
        return reply.rowHeight;
    }
    
    return 0;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (indexPath.row < self.post.attributes.summaries.replies.count) {
        ReplyPostCell *cell = [tableView dequeueReusableCellWithIdentifier:replyReuseIdentifier forIndexPath:indexPath];
        
        if (cell == nil) {
            cell = [[ReplyPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:replyReuseIdentifier];
        }
        
        cell.tintColor = self.tintColor;
        
        NSInteger identifierBefore = cell.post.identifier;
        
        Post *reply = self.post.attributes.summaries.replies[indexPath.row];
        cell.post = reply;
        
        cell.nameLabel.attributedText = [BubblePostCell attributedCreatorStringForPost:cell.post];
        
        if (cell.post.identifier != 0 && identifierBefore == cell.post.identifier) {
            //[self didBeginDisplayingCell:cell];
        }
        
        cell.lineSeparator.hidden = true;
        
        cell.postedInButton.hidden = true;
        
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
    
    [self.repliesTableView reloadData];
    dispatch_async (dispatch_get_main_queue(), ^{
        self.repliesTableView.frame = CGRectMake(0, self.detailsView.frame.origin.y + self.detailsView.frame.size.height + postContentOffset.bottom, self.frame.size.width, self.repliesTableView.contentSize.height);
    });
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    
}

@end
