//
//  SHKLinkedInMultilineTextView.m
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
#import "SHKLinkedInMultilineTextField.h"

#import <QuartzCore/QuartzCore.h>


#define MTV_MARGIN_LEFT				(8)
#define MTV_MARGIN_RIGHT			(8)
#define MTV_MARGIN_BOTTOM			(4)
#define MTV_FOOTER_HEIGHT			(16)
#define MTV_LABEL_WIDTH				(190)
#define MTV_COUNTER_WIDTH			(60)
#define MTV_PLACEHOLDER_MARGIN_TOP	(6)
#define MTV_PLACEHOLDER_WIDTH		(280)
#define MTV_PLACEHOLDER_HEIGHT		(24)

#define MTV_TEXT_SIZE				(15.0f)
#define MTV_LABEL_SIZE				(15.0f)


@interface SHKLinkedInMultilineTextField ()

- (void)updateDisplay;
- (void)updateCounter:(UITextView*)tv;
- (void)updateLabelVisibility;
- (void)frameContent;

@end



@implementation SHKLinkedInMultilineTextField

@synthesize charLimit;
@synthesize placeholder;
@synthesize required;


-(void)loadViewWithFrame:(CGRect)frame style:(SHKLinkedInFormStyle*)style
{

	UITextView *tv = [[[UITextView alloc] initWithFrame:frame] autorelease];
	
	tv.textColor = style.textColor;		
	tv.backgroundColor = style.fieldBackgroundColor;	
	tv.font = [UIFont systemFontOfSize:MTV_TEXT_SIZE];
	tv.autoresizesSubviews = YES;
	tv.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	tv.layer.masksToBounds = true;
	tv.opaque = false;
	tv.layer.cornerRadius = 8;
	tv.scrollEnabled = false;
	tv.scrollsToTop = false;
	tv.bounces = false;		
	
	tv.delegate = self;
			
	counterTextColor = [style.counterTextColor copy];
	

	fieldLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	fieldLabel.backgroundColor = [UIColor clearColor];
	fieldLabel.opaque = NO;
	fieldLabel.font = [UIFont boldSystemFontOfSize:MTV_LABEL_SIZE];
	fieldLabel.textAlignment = UITextAlignmentLeft;
	fieldLabel.autoresizesSubviews = YES;
	fieldLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
	fieldLabel.textColor = style.labelTextColor;
				
	fieldLabel.frame = CGRectMake(MTV_MARGIN_LEFT,
						   frame.size.height - MTV_FOOTER_HEIGHT - MTV_MARGIN_BOTTOM,
						   MTV_LABEL_WIDTH,
						   MTV_FOOTER_HEIGHT);	
						   
						   
	fieldLabel.text = self.label;
						   
	[tv addSubview:fieldLabel];
	
	
	counterLabel = [[UILabel alloc] initWithFrame: CGRectMake(frame.size.width - MTV_COUNTER_WIDTH - MTV_MARGIN_RIGHT,
						   frame.size.height - MTV_FOOTER_HEIGHT - MTV_MARGIN_BOTTOM,
						   MTV_COUNTER_WIDTH,
						   MTV_FOOTER_HEIGHT)];
						   
	counterLabel.backgroundColor = [UIColor clearColor];
	counterLabel.opaque = NO;
	counterLabel.font = [UIFont boldSystemFontOfSize:MTV_LABEL_SIZE];
	counterLabel.textAlignment = UITextAlignmentRight;
	counterLabel.autoresizesSubviews = YES;
	counterLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
		
	[tv addSubview:counterLabel];

	
	placeholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(MTV_MARGIN_LEFT,
													MTV_PLACEHOLDER_MARGIN_TOP,
													MTV_PLACEHOLDER_WIDTH,
													MTV_PLACEHOLDER_HEIGHT)	];
			
	placeholderLabel.backgroundColor = [UIColor clearColor];
	placeholderLabel.opaque = NO;
	placeholderLabel.font = [UIFont systemFontOfSize:MTV_TEXT_SIZE];
	placeholderLabel.textColor = style.placeholderTextColor; //[UIColor lightGrayColor];
	placeholderLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
	placeholderLabel.textAlignment = UITextAlignmentLeft;
	
	placeholderLabel.text = placeholder;
	
	[tv addSubview:placeholderLabel];

	// initialize the state of subviews (JRS)
	[self updateLabelVisibility];
	[self updateCounter:nil];
	
	[textView release];		
	textView = [tv retain];

	// Set the field view
	self.view = tv;
	
}


- (id)init
{
	if((self = [super init]))
	{
		charLimit = -1;
		required = false;

		textView = nil;

		counterLabel = nil;
		placeholderLabel = nil;
		fieldLabel = nil;
		
		counterTextColor = nil;
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:nil];

	}
	
	return self;
	
}



- (void)dealloc
{

	[textView release];
	[fieldLabel release];
	[counterLabel release];
	[placeholderLabel release];

	[counterTextColor release];
	
	self.placeholder = nil;
	
	//[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];

}


+ (SHKLinkedInMultilineTextField*) textViewWithFrame:(CGRect)frame label:(NSString*)label placeholder:(NSString*)placeholder charLimit:(int)charLimit style:(SHKLinkedInFormStyle*)style delegate:(id<UITextViewDelegate>)delegate
{

	SHKLinkedInMultilineTextField* fv = [[SHKLinkedInMultilineTextField alloc] initWithFrame:frame];
	
	UITextView *textView = (UITextView*)fv.view;
	textView.delegate = delegate;

	charLimit = charLimit;

	return [fv autorelease];
}



- (void)updateDisplay
{

	[self updateLabelVisibility];
	[self updateCounter:textView];

	[self frameContent];
	
	[fieldDelegate fieldViewFrameDidChange:self];
		
//	[form layoutForm];
}



- (void)updateLabelVisibility
{

    if ([[textView text] length] == 0)
	{
        placeholderLabel.hidden = false;
		fieldLabel.hidden = true;
    }
	else
	{
        placeholderLabel.hidden = true;
		fieldLabel.hidden = false;
    }
	
}


- (void)updateCounter:(UITextView*)tv
{

	UILabel *ctr = counterLabel;

	if(charLimit > 0)
	{
		BOOL hasAttachment = false; // taken from Twitter form support, should probably be removed (JRS)		
		int count = (hasAttachment?(charLimit-25):charLimit) - tv.text.length;

		ctr.text = [NSString stringWithFormat:@"%@%i", hasAttachment ? @"Image + ":@"" , count];
		ctr.textColor = count >= 0 ? counterTextColor : [UIColor redColor];
		ctr.hidden = false;
		
	}
	else
	{
		ctr.hidden = true;
	}
	
}



- (void)textViewDidChange:(UITextView *)tv
{
	
	[self updateDisplay];
	
}


/*
-(void)textChanged:(NSNotification*)notif
{
	[self updateLabelVisibility];
	[self updateCounter:textView];
}
*/


-(void)fieldWillAppear:(SHKLinkedInForm*)form
{

	[self updateDisplay];

}



- (void)frameContent
{
	UITextView *tv = textView;
	tv.frame = CGRectMake(tv.frame.origin.x, tv.frame.origin.y, tv.contentSize.width, tv.contentSize.height + (MTV_FOOTER_HEIGHT + 2));
}


-(BOOL)validate
{

	NSString *fieldName = SHKLocalizedString(self.label);

	if(self.required)
	{
		if([textView.text length] < 1)
		{
		
			NSString *message = SHKLocalizedString(@"You must provide text for this field in order to post.");
			message = [NSString stringWithFormat:@"\"%@\": %@", fieldName, message];
		
			[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Required Field")
										 message:message
										delegate:nil
							   cancelButtonTitle:SHKLocalizedString(@"Close")
							   otherButtonTitles:nil] autorelease] show];
							   
			return false;
		
		}
	}
	
	if(charLimit > 0)
	{
		if([textView.text length] > charLimit)
		{
			NSString *limit = [NSString stringWithFormat:@"%i", charLimit];
			NSString *message = SHKLocalizedString(@"You must limit input to XXXX characters or less in order to post.");
			message = [message stringByReplacingOccurrencesOfString:@"XXXX" withString:limit];
			message = [NSString stringWithFormat:@"\"%@\": %@", fieldName, message];
		
			[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Limit Exceeded")
										 message:message
										delegate:nil
							   cancelButtonTitle:SHKLocalizedString(@"Close")
							   otherButtonTitles:nil] autorelease] show];
							   
			return false;
				
		}
	}

	return true;
}


-(void)setAsFirstResponder
{
	[textView becomeFirstResponder];
	
	NSRange n;
	n.length = 0;
	n.location = 0;
	
	textView.selectedRange = n;	
}

////

- (void)setPlaceholder:(NSString *)thePlaceholder
{
	[placeholder release];
	placeholder = [thePlaceholder retain];

	placeholderLabel.text = thePlaceholder;
	
	CGSize newsize = [thePlaceholder sizeWithFont:placeholderLabel.font];
	CGRect frame = placeholderLabel.frame;
	frame.size = newsize;
	
	placeholderLabel.frame = frame;
	
}



- (void)setLabel:(NSString *)theLabel
{
	[super setLabel:theLabel];

	fieldLabel.text = theLabel;
}



-(void) setCharLimit:(int)theCharLimit
{
	charLimit = theCharLimit;

	[self updateCounter:textView];
}

/////

-(id)value
{
	return  textView.text;
}


-(void)setValue:(id)value
{

	textView.text = (NSString*)value;
		
	[self updateCounter:textView];
	[self updateLabelVisibility];
	[self frameContent];
	
	[fieldDelegate fieldViewFrameDidChange:self];
	
//	[form layoutForm];
		
}



@end
