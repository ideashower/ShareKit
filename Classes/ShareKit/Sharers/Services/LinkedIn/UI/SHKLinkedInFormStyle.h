//
//  SHKLinkedInFormStyle.h
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



@interface SHKLinkedInFormStyle : NSObject {
 
	UIColor *backgroundColor;
	UIColor *fieldBackgroundColor;	
	UIColor *labelTextColor;
	UIColor *textColor;
	UIColor *placeholderTextColor;
	UIColor *counterTextColor;
	      
}

@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, retain) UIColor *fieldBackgroundColor;
@property (nonatomic, retain) UIColor *labelTextColor;
@property (nonatomic, retain) UIColor *textColor;
@property (nonatomic, retain) UIColor *placeholderTextColor;
@property (nonatomic, retain) UIColor *counterTextColor;


+(SHKLinkedInFormStyle*)style;


@end
