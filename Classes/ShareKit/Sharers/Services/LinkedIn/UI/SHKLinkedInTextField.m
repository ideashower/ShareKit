//
//  SHKLinkedInTextViewV2.m
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
#import "SHKLinkedInTextField.h"
#import <QuartzCore/QuartzCore.h>

@implementation SHKLinkedInTextField

@synthesize placeholder;
@synthesize type;


- (id)init
{
	if((self = [super init]))
	{
		self.placeholder = nil;
		textField = nil;
		self.type = SHKLinkedInTextFieldPlain;
	
	}
	
	return self;
	
}


- (void)dealloc
{

	self.placeholder = nil;

	[textField release];

	[super dealloc];

}


-(void)loadViewWithFrame:(CGRect)frame style:(SHKLinkedInFormStyle*)style
{
		UITextField *tf = nil;

		UIView *v = nil;

		v = [[[UIView alloc] initWithFrame:frame] autorelease];
		v.backgroundColor = style.fieldBackgroundColor;
		v.opaque = false;
		v.layer.masksToBounds = true;
		v.layer.cornerRadius = 8;
		v.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		v.autoresizesSubviews = true;
		v.clipsToBounds = true;

		float leftInset = 8.0f;
		float rightInset = 8.0f;
		float spacing = 12.0f;
		
		UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(leftInset, 0, 0, v.frame.size.height)];
		l.backgroundColor = [UIColor clearColor];
		l.font = [UIFont boldSystemFontOfSize:18.0f];
		l.textColor = style.labelTextColor;

		l.text = self.label;

		CGSize s = [label sizeWithFont:l.font];
		float labelWidth = s.width;
		l.frame = CGRectMake(l.frame.origin.x, l.frame.origin.y, labelWidth, l.frame.size.height);

		float fieldOffset = leftInset + labelWidth + spacing;
		float fieldWidth = v.frame.size.width - fieldOffset - rightInset;
		
		tf = [[[UITextField alloc] initWithFrame:CGRectMake(fieldOffset, l.frame.size.height * 0.5f - 11.0f, fieldWidth, v.frame.size.height) ] autorelease];
		tf.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		tf.borderStyle = UITextBorderStyleNone;
		tf.placeholder = placeholder;

		tf.textColor = style.textColor;
		tf.font = [UIFont systemFontOfSize:17.0f];


		switch (type)
		{
			case SHKLinkedInTextFieldPassword:
			{
				tf.secureTextEntry = true;	
			}
			break;

			case SHKLinkedInTextFieldPlain:
			{
			}
			break;
			
			default:
				break;
			
		}

		[v addSubview:l];
		[v addSubview:tf];

		[l release];


	[textField release];
	textField = [tf retain];

	// set the field view
	self.view = v;

}



-(BOOL)validate
{

	if([textField.text length] < 1)
	{
	
		NSString *fieldName = SHKLocalizedString(self.label);
		NSString *message = SHKLocalizedString(@"You must provide text for this field in order to post.");
		message = [NSString stringWithFormat:@"\"%@\": %@", fieldName, message];
	
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Required Field")
									 message:message
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] autorelease] show];
						   
		return false;
	
	}

	return true;

}


-(void)setAsFirstResponder
{
	[textField becomeFirstResponder];
}


-(id)value
{
	return textField.text;
}

-(void)setValue:(id)value
{
	textField.text = (NSString*)value;
}



@end
