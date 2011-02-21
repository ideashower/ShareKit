//
//  SHKTwitterForm.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/22/10.

//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//

#import "SHKTwitterForm.h"
#import "SHK.h"
#import "SHKTwitter.h"

static CGFloat UsernameFontSize = 18;
static CGFloat CounterMarginRight = 115;
static CGFloat LogoutButtonWidth = 66;

@interface SHKTwitterForm (private)
- (void)setupToolbar;
- (CGRect)toolbarFrame;
- (void)updateCounter;
@end

@implementation SHKTwitterForm

@synthesize delegate;
@synthesize username;
@synthesize textView;
@synthesize counter;
@synthesize hasAttachment;

- (void)dealloc 
{
	[delegate release];
	[textView release];
	[toolbar release];
	[counter release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) 
	{		
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																							  target:self
																							  action:@selector(cancel)];
		
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Send to Twitter"
																				  style:UIBarButtonItemStyleDone
																				 target:self
																				 action:@selector(save)];
    }
    return self;
}



- (void)loadView 
{
	[super loadView];
	
	self.view.backgroundColor = [UIColor whiteColor];
	
	self.textView = [[UITextView alloc] initWithFrame:self.view.bounds];
	textView.delegate = self;
	textView.font = [UIFont systemFontOfSize:15];
	textView.contentInset = UIEdgeInsetsMake(5,5,0,0);
	textView.backgroundColor = [UIColor whiteColor];	
	textView.autoresizesSubviews = YES;
	textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	
	[self.view addSubview:textView];
    [self setupToolbar];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];	
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(keyboardWillShow:) name: UIKeyboardWillShowNotification object:nil];
	
	[self.textView becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];	
	
	// Remove observers
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name: UIKeyboardWillShowNotification object:nil];
	
	// Remove the SHK view wrapper from the window
	[[SHK currentHelper] viewWasDismissed];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}

- (void)setupToolbar {
    [toolbar removeFromSuperview];
    [toolbar release];
    toolbar = [[UIToolbar alloc] initWithFrame:[self toolbarFrame]];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    toolbar.tintColor = [UIColor blackColor];
    UIBarButtonItem *logout_button = [[UIBarButtonItem alloc] initWithTitle:SHKLocalizedString(@"Log Out")
                                                                      style:UIBarButtonItemStyleBordered
                                                                     target:self
                                                                     action:@selector(logout)];
    UILabel *username_label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds) - LogoutButtonWidth - CounterMarginRight, CGRectGetHeight(toolbar.frame))];
    username_label.text = username;
    username_label.textColor = [UIColor whiteColor];
    username_label.font = [UIFont systemFontOfSize:UsernameFontSize];
    username_label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    username_label.backgroundColor = [UIColor clearColor];
    UIBarButtonItem *username_label_item = [[UIBarButtonItem alloc] initWithCustomView:username_label];
	[self updateCounter];
    UIBarButtonItem *counter_item = [[UIBarButtonItem alloc] initWithCustomView:counter];
    UIBarButtonItem *flexible_space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                                                                                    target:nil 
                                                                                    action:nil];
    NSArray *items = [[NSArray alloc] initWithObjects:logout_button, username_label_item, flexible_space, counter_item, nil];
    toolbar.items = items;
    [self.view addSubview:toolbar];
}

- (CGRect)toolbarFrame {
    CGRect frame = CGRectZero;
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        frame = CGRectMake(0, 158, CGRectGetWidth(self.view.bounds), 44);
    }
    else {
        frame = CGRectMake(0, 72, CGRectGetWidth(self.view.bounds), 34);
    }
    return frame;
}

- (void)keyboardWillShow:(NSNotification *)notification
{	
	CGRect keyboardFrame;
	CGFloat keyboardHeight = 0;
	
	// 3.2 and above
	if (&UIKeyboardFrameEndUserInfoKey) {
    	[[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];
    	if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait 
    	 || [[UIDevice currentDevice] orientation] == UIDeviceOrientationPortraitUpsideDown) {
    		 keyboardHeight = keyboardFrame.size.height;
    	}
    	else {
    		keyboardHeight = keyboardFrame.size.width;
    	}
	}
	 	
	// Find the bottom of the screen (accounting for keyboard overlay)
	// This is pretty much only for pagesheet's on the iPad
	UIInterfaceOrientation orient = [[UIApplication sharedApplication] statusBarOrientation];
	BOOL inLandscape = orient == UIInterfaceOrientationLandscapeLeft || orient == UIInterfaceOrientationLandscapeRight;
	BOOL upsideDown = orient == UIInterfaceOrientationPortraitUpsideDown || orient == UIInterfaceOrientationLandscapeRight;
	
	CGPoint topOfViewPoint = [self.view convertPoint:CGPointZero toView:nil];
	CGFloat topOfView = inLandscape ? topOfViewPoint.x : topOfViewPoint.y;
	
	CGFloat screenHeight = inLandscape ? [[UIScreen mainScreen] applicationFrame].size.width : [[UIScreen mainScreen] applicationFrame].size.height;
	
	CGFloat distFromBottom = screenHeight - ((upsideDown ? screenHeight - topOfView : topOfView ) + self.view.bounds.size.height) + ([UIApplication sharedApplication].statusBarHidden || upsideDown ? 0 : 20);							
	CGFloat maxViewHeight = self.view.bounds.size.height - keyboardHeight + distFromBottom;
	
	textView.frame = CGRectMake(0,0,self.view.bounds.size.width,maxViewHeight);
}

#pragma mark -

- (void)updateCounter
{
	if (counter == nil)
	{
		self.counter = [[UILabel alloc] initWithFrame:CGRectZero];
		counter.backgroundColor = [UIColor clearColor];
		counter.opaque = NO;
		counter.font = [UIFont boldSystemFontOfSize:14];
		counter.textAlignment = UITextAlignmentRight;
		
		counter.autoresizesSubviews = YES;
		counter.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
		
		[counter release];
	}
	
	int count = (hasAttachment?115:140) - textView.text.length;
	counter.text = [NSString stringWithFormat:@"%@%i", hasAttachment ? @"Image + ":@"" , count];
    counter.textColor = [UIColor grayColor];
    [counter sizeToFit];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	[self updateCounter];
}

- (void)textViewDidChange:(UITextView *)textView
{
	[self updateCounter];	
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	[self updateCounter];
}

#pragma mark -

- (void)cancel
{	
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
}

- (void)logout {
    [SHKTwitter logout];
    [(SHKTwitter *)delegate promptAuthorization];
}

- (void)save
{	
	if (textView.text.length > (hasAttachment?115:140))
	{
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Message is too long")
									 message:SHKLocalizedString(@"Twitter posts can only be 140 characters in length.")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] autorelease] show];
		return;
	}
	
	else if (textView.text.length == 0)
	{
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Message is empty")
									 message:SHKLocalizedString(@"You must enter a message in order to post.")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] autorelease] show];
		return;
	}
	
	[(SHKTwitter *)delegate sendForm:self];
	
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Rotation

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
                                         duration:(NSTimeInterval)duration {
    [self setupToolbar];
}

@end
