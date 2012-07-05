//
//  SHKLinkedInForm.h
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

#import <UIKit/UIKit.h>

#import "SHKLinkedInFormStyle.h"
#import "SHKItem+KVC.h"
#import "SHKLinkedInField.h"

@interface SHKLinkedInForm : UIViewController <SHKLinkedInFieldDelegate>
{
	id delegate;
	UIScrollView *scrollView;
	
	SHKItem *item;
		
	NSMutableArray *formFieldArray;
	NSMutableDictionary *formFieldDict;
	
	SHKLinkedInFormStyle *style;
	
	BOOL hasAttachment;
	BOOL enableURLFields;
}

@property (nonatomic, retain) id delegate;
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UILabel *counter;
@property (nonatomic, retain) NSMutableDictionary *formFieldDict;

@property (nonatomic, retain) SHKItem *item;
@property (readonly) SHKLinkedInFormStyle *style;

@property BOOL hasAttachment;
@property BOOL enableURLFields;

- (void)setFieldValuesForItem:(SHKItem*)item;
- (void)applyFieldValuesToItem:(SHKItem*)item;
- (void)save;
- (void)keyboardWillShow:(NSNotification *)notification;

@end
