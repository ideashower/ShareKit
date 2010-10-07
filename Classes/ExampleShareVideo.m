    //
//  ExampleShareVideo.m
//  ShareKit
//
//  Created by cbarrie on October 6 .
//  Copyright 2010 Snepo Research. All rights reserved.
//

#import "ExampleShareVideo.h"
#import "SHKItem.h"
#import "SHKActionSheet.h"

@implementation ExampleShareVideo
@synthesize video;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
	{
		self.toolbarItems = [NSArray arrayWithObjects:
							 [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
							 [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share)] autorelease],
							 [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
							 nil
							 ];
	}
	
	return self;
}


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    [super loadView];
    self.video = [NSMutableData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"img_0058" ofType:@"mov"]];
}


- (void)share
{
	SHKItem *item = [SHKItem video:self.video title:@"A video of a laptop"];
	SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
	
	[actionSheet showFromToolbar:self.navigationController.toolbar];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}


- (void)dealloc {
    [super dealloc];
}


@end
