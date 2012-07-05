//
//  SHKPlurkForm.h
//  ShareKit
//
//  Created by Yehnan Chiang on 5/20/11.

#import <UIKit/UIKit.h>


@interface SHKPlurkForm : UIViewController <UITextViewDelegate>
{
	id delegate;
	UITextView *textView;
	UILabel *counter;
}

@property (nonatomic, retain) id delegate;
@property (nonatomic, retain) UITextView *textView;
@property (nonatomic, retain) UILabel *counter;

- (void)layoutCounter;

@end
