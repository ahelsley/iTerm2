//
//  ToolProfiles.m
//  iTerm
//
//  Created by George Nachman on 9/5/11.
//  Copyright 2011 Georgetech. All rights reserved.
//

#import "ToolProfiles.h"
#import "PseudoTerminal.h"
#import "iTermController.h"
#import "BookmarkModel.h"

@implementation ToolProfiles

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        const int kVerticalMargin = 8;
        const int kMargin = 14;
        const int kPopupHeight = 26;
        listView_ = [[BookmarkListView alloc] initWithFrame:NSMakeRect(kMargin, 0, frame.size.width - kMargin * 2, frame.size.height - kPopupHeight - kVerticalMargin)];
        [listView_ setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [self addSubview:listView_];
        popup_ = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(kMargin, frame.size.height - kPopupHeight, frame.size.width - kMargin * 2, kPopupHeight)];
        [[popup_ menu] addItemWithTitle:@"New Tab"
                                 action:@selector(toolProfilesNewTab:)
                          keyEquivalent:@""];
        [[popup_ menu] addItemWithTitle:@"New Window"
                                 action:@selector(toolProfilesNewWindow:)
                          keyEquivalent:@""];
        [[popup_ menu] addItemWithTitle:@"New Horizontal Split"
                                 action:@selector(toolProfilesNewHorizontalSplit:)
                          keyEquivalent:@""];
        [[popup_ menu] addItemWithTitle:@"New Vertical Split"
                                 action:@selector(toolProfilesNewVerticalSplit:)
                          keyEquivalent:@""];
        for (NSMenuItem *i in [[popup_ menu] itemArray]) {
            [i setTarget:self];
        }
        [self addSubview:popup_];
        [popup_ setAutoresizingMask:NSViewMinYMargin | NSViewWidthSizable];
        
        [popup_ bind:@"enabled" toObject:listView_ withKeyPath:@"hasSelection" options:nil];
    }
    return self;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)toolProfilesNewTab:(id)sender
{
    PseudoTerminal* terminal = [[iTermController sharedInstance] currentTerminal];
    for (NSString* guid in [listView_ selectedGuids]) {
        Bookmark* bookmark = [[BookmarkModel sharedInstance] bookmarkWithGuid:guid];
        [[iTermController sharedInstance] launchBookmark:bookmark
                                              inTerminal:terminal];
    }    
}

- (void)toolProfilesNewWindow:(id)sender
{
    for (NSString* guid in [listView_ selectedGuids]) {
        Bookmark* bookmark = [[BookmarkModel sharedInstance] bookmarkWithGuid:guid];
        [[iTermController sharedInstance] launchBookmark:bookmark
                                              inTerminal:nil];
    }    
}

- (void)toolProfilesNewHorizontalSplit:(id)sender
{
    PseudoTerminal* terminal = [[iTermController sharedInstance] currentTerminal];
    for (NSString* guid in [listView_ selectedGuids]) {
        [terminal splitVertically:NO withBookmarkGuid:guid];
    }    
}

- (void)toolProfilesNewVerticalSplit:(id)sender
{
    PseudoTerminal* terminal = [[iTermController sharedInstance] currentTerminal];
    for (NSString* guid in [listView_ selectedGuids]) {
        [terminal splitVertically:YES withBookmarkGuid:guid];
    }    
}

@end
