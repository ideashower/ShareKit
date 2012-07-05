//
//  SHKLinkedInField.m
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
#import "SHKLinkedInField.h"
#import "SHKLinkedInMultilineTextField.h"
#import "SHKLinkedInTextField.h"
#import "SHKLinkedInURLField.h"


@interface SHKLinkedInField()

@end


// SHKLinkedInField
// 
// Abstract base class for creating form fields
//

@implementation SHKLinkedInField

@synthesize view;
@synthesize fieldDelegate;
@synthesize newGroup;
@synthesize topMargin, bottomMargin;
@synthesize label, key;


// loadViewWithFrame:style
//
// All Subclasses should override this to set the field's view object hierarchy
//

-(void)loadViewWithFrame:(CGRect)frame style:(SHKLinkedInFormStyle*)style
{
	self.view = nil;	
}


- (id)init
{
	if((self = [super init]))
	{
		topMargin = 0.0f;
		bottomMargin = 0.0f;
		
		self.fieldDelegate = nil;
		self.view = nil;
		self.key = nil;
	
	}
	
	return self;

}


- (void)dealloc
{
	self.fieldDelegate = nil;

	self.label = nil;
	self.key = nil;
	self.view = nil;

	[super dealloc];
}




-(void)fieldWillAppear:(SHKLinkedInForm*)form 
{
	// Override this if your field controls need to be adjusted prior to display
	// This is provided as form view frame isn't size correctly until it's pushed
	// onto the view controller stack
}




-(BOOL)validate
{
	// Override to perform general validation for a field type

		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"No Field Defined")
									 message:SHKLocalizedString(@"You must define a valid field subclass to use")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] autorelease] show];

	return false;
}


-(void)setAsFirstResponder
{
	// Override to perform set the relevant input control as the first responder
}


-(id)value
{
	// Override to get the value of the input control

	return nil;
}

-(void)setValue:(id)value
{
	// Override to set the value of the input control
	
	return;
}


// Class factory methods, provided as a convenience to create fields in sharer classes

+(SHKLinkedInMultilineTextField*) multilineTextField:(NSString*)label key:(NSString*)key placeholder:(NSString*)placeholder charLimit:(int)charLimit newGroup:(BOOL)newGroup required:(BOOL)required
{

	SHKLinkedInMultilineTextField* mtf = [[SHKLinkedInMultilineTextField alloc] init];

	mtf.label = label;
	mtf.key = key;
	mtf.placeholder = placeholder;
	mtf.charLimit = charLimit;
	mtf.newGroup = newGroup;
	mtf.required = required;

	return [mtf autorelease];

}


+(SHKLinkedInTextField*) textField:(NSString*)label key:(NSString*)key placeholder:(NSString*)placeholder type:(SHKLinkedInTextFieldType)type newGroup:(BOOL)newGroup
{
	SHKLinkedInTextField* tf = [[SHKLinkedInTextField alloc] init];
	
	tf.label = label;
	tf.key = key;
	tf.placeholder = placeholder;
	tf.type = type;
	tf.newGroup = newGroup;

	return [tf autorelease];

}


+(SHKLinkedInURLField*) urlField:(NSString*)label key:(NSString*)key placeholder:(NSString*)placeholder newGroup:(BOOL)newGroup
{

	SHKLinkedInURLField* uf = [[SHKLinkedInURLField alloc] init];
	
	uf.label = label;
	uf.key = key;
	uf.placeholder = placeholder;
	uf.newGroup = newGroup;

	return [uf autorelease];
}



@end

