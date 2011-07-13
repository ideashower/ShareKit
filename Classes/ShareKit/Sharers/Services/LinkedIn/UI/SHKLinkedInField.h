//
//  SHKLinkedInField.h
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


//#import "SHKLinkedInForm.h"

#import "SHKLinkedInFormStyle.h"

@class SHKLinkedInMultilineTextField;
@class SHKLinkedInTextField;
@class SHKLinkedInURLField;

@class SHKLinkedInForm;
@class SHKLinkedInField;

typedef enum 
{

	SHKLinkedInTextFieldPlain,
	SHKLinkedInTextFieldPassword
		
} SHKLinkedInTextFieldType;


@protocol SHKLinkedInFieldDelegate <NSObject>

@required

- (void)fieldViewFrameDidChange:(SHKLinkedInField*)field;

@end


@interface SHKLinkedInField : NSObject
{
	id<SHKLinkedInFieldDelegate> fieldDelegate;
	
	UIView *view;
	
	NSString *label;
	NSString *key;
	
	float topMargin;
	float bottomMargin;
	BOOL newGroup;
	
}

@property (nonatomic, retain) id<SHKLinkedInFieldDelegate> fieldDelegate;
@property (nonatomic, retain) UIView *view;
@property (readwrite) float topMargin, bottomMargin;
@property (nonatomic, readwrite) BOOL newGroup;
@property (nonatomic, retain) NSString *label;
@property (nonatomic, retain) NSString *key;

@property (nonatomic, assign) id value;

-(void)loadViewWithFrame:(CGRect)frame style:(SHKLinkedInFormStyle*)style;
-(void)fieldWillAppear:(SHKLinkedInForm*)form;
-(BOOL)validate;
-(void)setAsFirstResponder;


+(SHKLinkedInMultilineTextField*) multilineTextField:(NSString*)label key:(NSString*)key placeholder:(NSString*)placeholder charLimit:(int)charLimit newGroup:(BOOL)newGroup required:(BOOL)required;

+(SHKLinkedInTextField*) textField:(NSString*)label key:(NSString*)key placeholder:(NSString*)placeholder type:(SHKLinkedInTextFieldType)type newGroup:(BOOL)newGroup;

+(SHKLinkedInURLField*) urlField:(NSString*)label key:(NSString*)key placeholder:(NSString*)placeholder newGroup:(BOOL)newGroup;

@end
