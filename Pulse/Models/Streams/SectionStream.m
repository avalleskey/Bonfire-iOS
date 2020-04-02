//
//  SectionStream.m
//  Pulse
//
//  Created by Austin Valleskey on 12/6/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "SectionStream.h"
#import "Session.h"
#import "PostCell.h"
#import "Launcher.h"

@implementation SectionStream

// insert an empty SectionStreamPage if
- (id)init {
    self = [super init];
    if (self) {
        [self flush];
        self.detailLevel = BFComponentDetailLevelAll;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.pages];
    [encoder encodeObject:data forKey:@"pages"];
}

-(id)initWithCoder:(NSCoder *)decoder
{
    if(self = [self init]) {
        self.pages = [NSKeyedUnarchiver unarchiveObjectWithData:[decoder decodeObjectForKey:@"pages"]];
    }
    return self;
}

- (void)flush {
    self.pages = [NSMutableArray new];
    self.sections = [NSMutableArray new];
    self.cursorsLoaded = [NSMutableDictionary new];
}

- (void)streamUpdated {
    if ([self.delegate respondsToSelector:@selector(sectionStreamDidUpdate:)]) {
        [self.delegate sectionStreamDidUpdate:self];
    }
}

- (void)refreshComponentsInPage:(SectionStreamPage *)page {
    // create components
    for (Section *section in page.data) {
        [section refreshComponents];
    }
}

- (void)prependPage:(SectionStreamPage *)page {
    if (self.pages.count > 0 && [self.pages firstObject].meta.paging.prevCursor.length > 0 && [[self.pages firstObject].meta.paging.prevCursor isEqualToString:page.meta.paging.prevCursor]) {
        return;
    }
        
    if (page.data.count > 0 && [[page.data firstObject] isKindOfClass:[Section class]]) {
        [self refreshComponentsInPage:page];
        [self.pages insertObject:page atIndex:0];
        
        [self prependSectionsFromPage:page];
        
        [self streamUpdated];
    }
}
- (void)prependSectionsFromPage:(SectionStreamPage *)page {
    [self.sections insertObjects:page.data atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, page.data.count)]];
}

- (void)appendPage:(SectionStreamPage *)page {
    if (self.pages.count > 0 && [self.pages lastObject].meta.paging.nextCursor.length > 0 && [[self.pages lastObject].meta.paging.nextCursor isEqualToString:page.meta.paging.nextCursor]) {
        return;
    }
        
    if ([page.data isKindOfClass:[NSArray class]] && page.data.count > 0 && [[page.data firstObject] isKindOfClass:[Section class]]) {
        [self refreshComponentsInPage:page];
        [self.pages addObject:page];
        
        [self appendSectionsFromPage:page];
        
        [self streamUpdated];
    }
}
- (void)appendSectionsFromPage:(SectionStreamPage *)page {
    [self.sections addObjectsFromArray:page.data];
    
    NSLog(@"# of sections: %lu", (unsigned long)self.sections.count);
}

#pragma mark - Section Stream Events (Update, Remove)
- (BOOL)performEventType:(SectionStreamEventType)eventType object:(id)object {
    BOOL changes = false;
    
    if (SectionStreamEventTypeUnknown) return changes;

    if ([object isKindOfClass:[Section class]]) {
        Section *section = (Section *)object;
        if (eventType == SectionStreamEventTypeSectionUpdated) {
            changes = [self updateSection:section];
        }
        else if (eventType == SectionStreamEventTypeSectionRemoved) {
            changes = [self removeSection:section];
        }
    }
    else if ([object isKindOfClass:[Post class]]) {
        Post *post = (Post *)object;
        if (eventType == SectionStreamEventTypePostUpdated) {
            changes = [self updatePost:post];
        }
        else if (eventType == SectionStreamEventTypePostRemoved) {
            changes = [self removePost:post];
        }
    }
    else if ([object isKindOfClass:[Camp class]]) {
        Camp *camp = (Camp *)object;
        if (eventType == SectionStreamEventTypeCampUpdated) {
            changes = [self updateCamp:camp];
        }
    }
    else if ([object isKindOfClass:[User class]]) {
        User *user = (User *)object;
        if (eventType == SectionStreamEventTypeUserUpdated) {
            changes = [self updateUser:user];
        }
    }
    
    return changes;
}

#pragma mark - Section Events
// Sections update the page first, then self.sections
- (BOOL)updateSection:(Section *)section {
    __block BOOL changes = false;
    
    if (section.attributes.posts.count == 0) {
        // remove the section instead
        [self removeSection:section];
        return changes;
    }
     
    // Refresh section components and update self.pages
    [self sectionUpdated:section];
    
    // Update section isntances in the quick access self.sections array
    
    for (Section __strong *s in self.sections) {
        if ([s.identifier isEqualToString:section.identifier]) {
            // Found a match
            changes = true;
            
            s = section;
        }
    }
    
    if (changes) {
        [self streamUpdated];
    }
    
    return changes;
}
- (BOOL)sectionUpdated:(Section *)section {
    __block BOOL changes = false;
    
//    if (section.attributes.posts.count == 0) {
//        return [self removeSection:section];
//    }
    
    [section refreshComponents];
    
    // Update matching section instances in self.pages
    [self.pages enumerateObjectsUsingBlock:^(SectionStreamPage * _Nonnull page, NSUInteger idx, BOOL * _Nonnull stop) {
        __block BOOL sectionChanges = false;
        
        // Cycle through page.data sections
        NSMutableArray <Section *> *mutablePageData = [[NSMutableArray<Section *> alloc] initWithArray:page.data];
        [mutablePageData enumerateObjectsUsingBlock:^(Section * _Nonnull s, NSUInteger i2, BOOL * _Nonnull stop2) {
            if ([s.identifier isEqualToString:section.identifier]) {
                sectionChanges = true;
                
                [mutablePageData replaceObjectAtIndex:i2 withObject:section];
            }
        }];
        
        if (sectionChanges) {
            changes = true;
            
            page.data = [mutablePageData copy];
        }
    }];
    
    return changes;
}
- (BOOL)removeSection:(Section *)section {
    __block BOOL changes = false;
    
    // Loop through and remove from self.pages
    NSMutableArray <Section *> *sectionsToRemove = [NSMutableArray<Section  *> new];
    [self.pages enumerateObjectsUsingBlock:^(SectionStreamPage *p, NSUInteger i1, BOOL *stop) {
        NSMutableArray <Section *> *mutableData = [[NSMutableArray<Section  *> alloc] initWithArray:p.data];
        NSMutableArray <Section *> *pageSectionsToRemove = [NSMutableArray<Section  *> new];
        [mutableData enumerateObjectsUsingBlock:^(Section *s, NSUInteger i2, BOOL *stop) {
            if ([section.identifier isEqualToString:s.identifier]) {
                // Found a match
                [pageSectionsToRemove addObject:s];
            }
        }];
        
        if (pageSectionsToRemove.count > 0) {
            [mutableData removeObjectsInArray:pageSectionsToRemove];
            [sectionsToRemove addObjectsFromArray:pageSectionsToRemove];
            
            p.data = [mutableData copy];
        }
    }];
    
    // Remove from self.sections
    if (sectionsToRemove.count > 0) {
        changes = true;
        // Update self.sections
        
        NSInteger sectionsBefore = self.sections.count;
        [self.sections removeObjectsInArray:sectionsToRemove];
        NSInteger sectionsAfter = self.sections.count;
        
        DSpacer();
        DSimpleLog(@"Removed %lu section(s)", sectionsBefore - sectionsAfter);
        DSpacer();
    }
    
    if (changes) {
        [self streamUpdated];
    }
    
    return changes;
}

#pragma mark - Post Events
- (BOOL)updatePost:(Post *)post {
    __block BOOL changes = false;
    
    // Create new instance of object
    post = [[Post alloc] initWithDictionary:[post toDictionary] error:nil];
    
    [self.sections enumerateObjectsUsingBlock:^(Section *s, NSUInteger i1, BOOL *stop) {
        __block BOOL sectionChanges = false;
        
        NSMutableArray <Post *> *mutablePosts = [[NSMutableArray<Post *> alloc] initWithArray:s.attributes.posts];
        [mutablePosts enumerateObjectsUsingBlock:^(Post *p, NSUInteger i2, BOOL *stop) {
            if ([post.identifier isEqualToString:p.identifier]) {
                // Found a match
                sectionChanges = true;
                
                [mutablePosts replaceObjectAtIndex:i2 withObject:post];
            }
            else if (p.attributes.summaries.replies.count > 0) {
                __block BOOL replyChanges = false;
                
                // Sort through replies to check for matches
                NSMutableArray <Post *> *mutableReplies = [[NSMutableArray<Post *> alloc] initWithArray:p.attributes.summaries.replies];
                [mutableReplies enumerateObjectsUsingBlock:^(Post *r, NSUInteger i3, BOOL *stop3) {
                    if ([post.identifier isEqualToString:r.identifier]) {
                        // Found a match
                        sectionChanges = true;
                        replyChanges = true;
                        
                        [mutableReplies replaceObjectAtIndex:i3 withObject:post];
                    }
                }];
                
                if (replyChanges) {
                    p.attributes.summaries.replies = [mutableReplies copy];
                }
            }
        }];
        
        if (sectionChanges) {
            changes = true;
            
            s.attributes.posts = [mutablePosts copy];
                        
            [self sectionUpdated:s];
        }
    }];
    
    if (changes) {
        [self streamUpdated];
    }
    
    return changes;
}
- (BOOL)removePost:(Post *)post {
    __block BOOL changes = false;
    
    [self.sections enumerateObjectsUsingBlock:^(Section *s, NSUInteger i1, BOOL *stop1) {
        __block BOOL sectionChanges = false;
        
        NSMutableArray <Post *> *mutableData = [[NSMutableArray<Post  *> alloc] initWithArray:s.attributes.posts];
        NSMutableArray <Post *> *postsToRemove = [NSMutableArray<Post  *> new];
        [mutableData enumerateObjectsUsingBlock:^(Post *p, NSUInteger i2, BOOL *stop2) {
            if ([post.identifier isEqualToString:p.identifier]) {
                // Found a match
                sectionChanges = true;
                [postsToRemove addObject:p];
            }
            else if (p.attributes.summaries.replies.count > 0) {
                // Sort through replies to check for matches
                NSMutableArray <Post *> *mutableReplies = [[NSMutableArray<Post  *> alloc] initWithArray:p.attributes.summaries.replies];
                NSMutableArray <Post *> *repliesToRemove = [NSMutableArray<Post  *> new];
                [mutableReplies enumerateObjectsUsingBlock:^(Post *r, NSUInteger i3, BOOL *stop3) {
                    if ([post.identifier isEqualToString:r.identifier]) {
                        // Found a match
                        [repliesToRemove addObject:r];
                    }
                }];
                
                if (repliesToRemove.count > 0) {
                    sectionChanges = true;
                    
                    [mutableReplies removeObjectsInArray:repliesToRemove];
                    
                    p.attributes.summaries.counts.replies = MAX(0, p.attributes.summaries.counts.replies - repliesToRemove.count);
                    p.attributes.summaries.replies = [mutableReplies copy];
                }
            }
        }];
        
        if (sectionChanges) {
            changes = true;
            
            if (postsToRemove.count > 0) {
                [mutableData removeObjectsInArray:postsToRemove];
            }
            s.attributes.posts = [mutableData copy];
            
            [self sectionUpdated:s];
        }
    }];
    
    if (changes) {
        [self streamUpdated];
    }
    
    return changes;
}

#pragma mark - User Events
- (BOOL)updateUser:(User *)user {
    __block BOOL changes = false;
    
    // Create new instance of object
    user = [user copy];
    
    [self.sections enumerateObjectsUsingBlock:^(Section * _Nonnull s, NSUInteger idx, BOOL * _Nonnull stop) {
        __block BOOL sectionChanges = false;
        
        NSMutableArray <Post *> *mutablePosts = [[NSMutableArray<Post *> alloc] initWithArray:s.attributes.posts];
        [mutablePosts enumerateObjectsUsingBlock:^(Post *post, NSUInteger i3, BOOL *stop) {
            __block BOOL postChanges = false;
            
            // update post creator
            if ([post.attributes.creator.identifier isEqualToString:user.identifier]) {
                sectionChanges = true;
                postChanges = true;
                
                post.attributes.creator = user;
            }
            
            // update replies
            __block BOOL replyChanges = false;
            
            NSMutableArray <Post *> *mutableReplies = [[NSMutableArray<Post *> alloc] initWithArray:post.attributes.summaries.replies];
            [mutableReplies enumerateObjectsUsingBlock:^(Post *reply, NSUInteger i4, BOOL *stop) {
                if ([reply.attributes.creator.identifier isEqualToString:user.identifier]) {
                    sectionChanges = true;
                    postChanges = true;
                    replyChanges = true;
                    
                    reply.attributes.creator = user;
                    
                    [mutableReplies replaceObjectAtIndex:i4 withObject:reply];
                }
            }];
            
            if (postChanges) {
                if (replyChanges) {
                    post.attributes.summaries.replies = [mutableReplies copy];
                }
                
                post = [post copy];
                
                [mutablePosts replaceObjectAtIndex:i3 withObject:post];
            }
        }];
        
        if (sectionChanges) {
            changes = true;
            
            s.attributes.posts = [mutablePosts copy];
            
            [self sectionUpdated:s];
        }
    }];
    
    if (changes) {
        [self streamUpdated];
    }
    
    return changes;
}

#pragma mark - Camp Events
- (BOOL)updateCamp:(Camp *)camp {
    __block BOOL changes = false;
    
    // Create new instance of object
    camp = [camp copy];
    
    [self.sections enumerateObjectsUsingBlock:^(Section * _Nonnull s, NSUInteger idx, BOOL * _Nonnull stop) {
        __block BOOL sectionChanges = false;
        
        NSMutableArray <Post *> *mutablePosts = [[NSMutableArray<Post *> alloc] initWithArray:s.attributes.posts];
        [mutablePosts enumerateObjectsUsingBlock:^(Post *post, NSUInteger i3, BOOL *stop) {
            __block BOOL postChanges = false;
            
            // update post creator
            if ([post.attributes.postedIn.identifier isEqualToString:camp.identifier]) {
                sectionChanges = true;
                postChanges = true;
                
                post.attributes.postedIn = camp;
            }
            
            // update replies
            __block BOOL replyChanges = false;
            
            NSMutableArray <Post *> *mutableReplies = [[NSMutableArray<Post *> alloc] initWithArray:post.attributes.summaries.replies];
            [mutableReplies enumerateObjectsUsingBlock:^(Post *reply, NSUInteger i4, BOOL *stop) {
                if ([reply.attributes.postedIn.identifier isEqualToString:camp.identifier]) {
                    sectionChanges = true;
                    postChanges = true;
                    replyChanges = true;
                    
                    reply.attributes.postedIn = camp;
                    
                    [mutableReplies replaceObjectAtIndex:i4 withObject:reply];
                }
            }];
            
            if (postChanges) {
                if (replyChanges) {
                    post.attributes.summaries.replies = [mutableReplies copy];
                }
                
                post = [post copy];
                
                [mutablePosts replaceObjectAtIndex:i3 withObject:post];
            }
        }];
        
        if (sectionChanges) {
            changes = true;
            
            s.attributes.posts = [mutablePosts copy];
            
            [self sectionUpdated:s];
        }
    }];
    
    if (changes) {
        [self streamUpdated];
    }
    
    return changes;
}

- (NSString * _Nullable)prevCursor {
    if (self.pages.count == 0) return nil;
    if ([self.pages firstObject].meta.paging.prevCursor.length == 0) return nil;

    return [self.pages firstObject].meta.paging.prevCursor;
}
- (NSString * _Nullable)nextCursor {
    if (self.pages.count == 0) return nil;
    if ([self.pages lastObject].meta.paging.nextCursor.length == 0) return nil;
    
    return [self.pages lastObject].meta.paging.nextCursor;
}

@end

@implementation SectionStreamPage

+(BOOL)propertyIsOptional:(NSString*)propertyName
{
    return true;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError **)err {
    SectionStreamPage *instance = [super initWithDictionary:dict error:err];
    
    NSArray *originalData = [dict objectForKey:@"data"];
    if (originalData.count > 0) {
        NSMutableArray <Section *><Section> *mutableData = [NSMutableArray<Section *><Section> new];
        
        NSMutableArray *newSectionPosts;
        for (NSDictionary *object in originalData) {
            if ([[object valueForKey:@"type"] isEqualToString:@"section"]) {
                if (newSectionPosts && newSectionPosts.count > 0) {
                    Section *newSection = [self createSectionFromPosts:newSectionPosts];
                    [mutableData addObject:newSection];
                    newSectionPosts = nil;
                }
                
                if ([object isKindOfClass:[NSDictionary class]]) {
                    NSError *error;
                    Section *section = [[Section alloc] initWithDictionary:object error:&error];
                    if (error) {
                        NSLog(@"cannot creation section because: %@", error);
                    }
                    else {
                        [mutableData addObject:section];
                    }
                }
                else if ([object isKindOfClass:[Section class]]) {
                    [mutableData addObject:(Section *)object];
                }
            }
            else if ([[object valueForKey:@"type"] isEqualToString:@"post"]) {
                if (!newSectionPosts) {
                    newSectionPosts = [NSMutableArray new];
                }
                
                [newSectionPosts addObject:object];
            }
        }
        
        if (newSectionPosts) {
            Section *newSection = [self createSectionFromPosts:newSectionPosts];
            [mutableData addObject:newSection];
            newSectionPosts = nil;
        }
        
        instance.data = mutableData;
    }
        
    return instance;
}

//- (void)encodeWithCoder:(NSCoder *)encoder
//{
//    [encoder encodeObject:self.data forKey:@"data"];
//    
//    if (self.meta) {
//        [encoder encodeObject:self.meta forKey:@"meta"];
//    }
//}
//
//-(id)initWithCoder:(NSCoder *)decoder
//{
//    if(self = [super init]) {
//        self.data = [decoder decodeObjectForKey:@"data"];
//        
//        if ([decoder decodeObjectForKey:@"meta"]) {
//            self.meta = [decoder decodeObjectForKey:@"meta"];
//        }
//    }
//    return self;
//}

- (Section *)createSectionFromPosts:(NSArray *)posts {
    Section *newSection = [[Section alloc] init];
    newSection.attributes = [[SectionAttributes alloc] initWithDictionary:@{@"posts": posts} error:nil];
    
    return newSection;
}

@end
