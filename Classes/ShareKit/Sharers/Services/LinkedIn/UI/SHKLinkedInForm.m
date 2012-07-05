//
//  SHKLinkedInForm.m
//  ShareKit
//
//  Created by Jim Spoto on 7/11/11.
//  With permission from Dot Matrix, LLC.

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


#import "SHK.h"
#import "SHKLinkedInForm.h"
#import "SHKLinkedIn.h"
#import "SHKLinkedInField.h"
#import "SHKItem+KVC.h"

@interface SHKLinkedInForm ()

- (void)layoutForm;


@end



@implementation SHKLinkedInForm

@synthesize delegate;
@synthesize scrollView;
@synthesize counter;
@synthesize hasAttachment;
@synthesize enableURLFields;
@synthesize formFieldDict;
@synthesize style;
@synthesize item;


- (void)dealloc 
{
	[delegate release];
	[scrollView release];
	
	[item release];
	
	[style release];
	
	[counter release];
    
	[formFieldArray release];
	[formFieldDict release];
	
	[super dealloc];
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) 
	{		
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																							  target:self
																							  action:@selector(cancel)];
		
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:SHKLocalizedString(@"Send to LinkedIn")
																				  style:UIBarButtonItemStyleDone
																				 target:self
																				 action:@selector(save)];



		self.hasAttachment = false;
		self.enableURLFields = false;
		
		style = [[SHKLinkedInFormStyle style] retain];

    }
    


	return self;
}


/////


- (void)layoutForm
{
	float ypos = 0.0f;
	
	for(SHKLinkedInField *field in formFieldArray)
	{			
		ypos += field.topMargin;

		CGRect r = field.view.frame;
		r.origin.y = ypos;
		field.view.frame = r;
		
		ypos += r.size.height + field.bottomMargin;
		
	}
	
	scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 16 + ypos);
	
}


////////

- (void)loadView 
{
	[super loadView];
	
	float leftRightMargins, topMargin, fieldMargin, groupMargin;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		leftRightMargins = 45.0f;
		topMargin = 40.0f;
		fieldMargin = 3.0f;
		groupMargin = 28.0f;
	}
	else
	{
		leftRightMargins = 8.0f;
		topMargin = 8.0f;
		fieldMargin = 2.0f;
		groupMargin = 14.0f;
	}
	
	float fieldHeight = 42.0f;

	self.view.backgroundColor = self.style.backgroundColor;
	
	UIScrollView *sv = [[UIScrollView alloc] initWithFrame:self.view.bounds];
	sv.contentInset = UIEdgeInsetsMake(0, 0, 20, 0);
	sv.backgroundColor = [UIColor clearColor];
	sv.alwaysBounceHorizontal = false;
	sv.alwaysBounceVertical = true;	
	sv.clipsToBounds = false;
		
	formFieldArray = [[NSMutableArray array] retain];
	self.formFieldDict = [NSMutableDictionary dictionary];
	
	NSArray *a = [(SHKLinkedIn*)self.delegate shareFormFieldsForType:item.shareType];
	
	float header = topMargin;
	
	for(SHKLinkedInField *field in a)
	{
		CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, fieldHeight);
		CGPoint inset = CGPointMake(leftRightMargins, 0);
		CGRect i = CGRectInset(frame, inset.x, inset.y) ;

		field.fieldDelegate = self;

		[field loadViewWithFrame:i style:self.style];

		[sv addSubview:field.view];
		
		if(field.newGroup)
			field.topMargin = groupMargin;
		else
			field.topMargin = header;
		
		[formFieldArray addObject:field];
		[self.formFieldDict setObject:field forKey:field.key];
		
		header = fieldMargin;
	
	}
	
	self.scrollView = sv;
	[self.view addSubview:self.scrollView];

	[sv release];
	
	[self layoutForm];

}


- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];	

	scrollView.frame = CGRectMake(0,0,self.view.bounds.size.width,self.view.bounds.size.height);

	for(SHKLinkedInField* field in formFieldArray)
	{
		[field fieldWillAppear:self];
	}
	
	[self layoutForm];

}


- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];	
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(keyboardWillShow:) name: UIKeyboardWillShowNotification object:nil];
	[nc addObserver:self selector:@selector(keyboardWillHide:) name: UIKeyboardWillHideNotification object:nil];
	
			
	if([formFieldArray count])
		[(SHKLinkedInField*)[formFieldArray objectAtIndex:0] setAsFirstResponder];
	
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

//////////


//#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

- (void)keyboardWillHide:(NSNotification *)notification
{
	CGRect sb = scrollView.bounds;
	CGRect sf = self.scrollView.frame;
	sb.size.height = self.view.bounds.size.height;
	sf.size.height = self.view.frame.size.height;
	
	// animate the scrollview content view back to full size
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.4];
	self.scrollView.frame = sf;
	[UIView commitAnimations]; 
	
	
}


- (void)keyboardWillShow:(NSNotification *)notification
{	
	CGRect keyboardFrame;
	CGFloat keyboardHeight;
	
	// 3.2 and above
	/*if (UIKeyboardFrameEndUserInfoKey)
	 {		
	 [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];		
	 if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait || [[UIDevice currentDevice] orientation] == UIDeviceOrientationPortraitUpsideDown) 
	 keyboardHeight = keyboardFrame.size.height;
	 else
	 keyboardHeight = keyboardFrame.size.width;
	 }
	 
	 // < 3.2
	 else 
	 {*/

	[[notification.userInfo valueForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardFrame];
	keyboardHeight = keyboardFrame.size.height;
	//}
	
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
	float maxy = screenHeight - keyboardHeight + 20;
	
	UIView *v = ((SHKLinkedIn*)self.delegate).view.superview;
	CGRect f = v.frame;	
	float vy = f.origin.y + f.size.height;
	
	float delta = (vy > maxy) ? vy - maxy : 0.0f;
	
	if(delta)
	{
		// animate the scrollview content view to frame what's visible behind the keyboard pop-up
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[UIView setAnimationDuration:0.4];
		self.scrollView.frame = CGRectMake(0,0,self.view.bounds.size.width,maxViewHeight);
		[UIView commitAnimations]; 
	}
	

}


#pragma mark -

- (void)cancel
{	
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
	[(SHKLinkedIn *)delegate sendDidCancel];
}


- (void)save
{	

	for(SHKLinkedInField *field in formFieldArray)
	{
		if(!([field validate]))
			return;
	}

	[(SHKLinkedIn *)delegate sendForm:self];
	
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
}


////


- (void)setFieldValuesForItem:(SHKItem*)theItem
{
	if(self.formFieldDict)
	{
		for(NSString* key in self.formFieldDict)
		{
			SHKLinkedInField *field = [self.formFieldDict valueForKey:key];
			id value = [theItem propertyForKey:key];
						
			if(value)
			{
				field.value = value;
			}
			
		}
	}

}



- (void)applyFieldValuesToItem:(SHKItem*)theItem
{
	if(self.formFieldDict)
	{
		for(NSString* key in self.formFieldDict)
		{
			SHKLinkedInField *field = [self.formFieldDict valueForKey:key];
			
			if(field.value)
				[theItem setProperty:field.value forKey:key];
				
		}

	}	

}


- (void)fieldViewFrameDidChange:(SHKLinkedInField*)field
{

	[self layoutForm];
}



@end
