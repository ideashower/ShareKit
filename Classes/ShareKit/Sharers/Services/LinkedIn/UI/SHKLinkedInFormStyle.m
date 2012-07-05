//
//  SHKLinkedInFormStyle.m
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


#import "SHKLinkedInFormStyle.h"


@implementation SHKLinkedInFormStyle

@synthesize backgroundColor, fieldBackgroundColor, labelTextColor, textColor, placeholderTextColor, counterTextColor;


- (id)init
{
	if((self = [super init]))
	{
		self.backgroundColor = [UIColor colorWithRed:0.86f green:0.88f blue:0.90f alpha:1.0f];
		self.fieldBackgroundColor = [UIColor whiteColor];
		self.labelTextColor = [UIColor colorWithRed:50/255.0f green:79/255.0f blue:133/255.0f alpha:1.0f];
		self.textColor = [UIColor blackColor];
		self.placeholderTextColor = [UIColor lightGrayColor];
		self.counterTextColor = [UIColor lightGrayColor];
	}
	
	return self;

}


- (void)dealloc
{
	self.backgroundColor = nil;
	self.fieldBackgroundColor = nil;
	self.labelTextColor = nil;
	self.textColor = nil;
	self.placeholderTextColor = nil;
	self.counterTextColor = nil;

	[super dealloc];
}


+(SHKLinkedInFormStyle*)style
{
	SHKLinkedInFormStyle *newStyle = [[SHKLinkedInFormStyle alloc] init];
	
	return [newStyle autorelease];
}


@end
