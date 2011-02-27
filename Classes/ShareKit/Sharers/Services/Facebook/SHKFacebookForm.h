//
//  SHKFacebookForm.h
//  ShareKitCommit
//
//  Created by David Porter on 12/04/10.
//  Copyright 2010 David Porter Apps. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SHKFacebookForm : UIViewController <UITextViewDelegate>
{
	id delegate;
	UITextView *textView;
	UILabel *counter;
	BOOL hasAttachment;
}
@property (nonatomic, retain) id delegate;
@property (nonatomic, retain) UITextView *textView;
@property (nonatomic, retain) UILabel *counter;
@property BOOL hasAttachment;
- (void)layoutCounter;


@end
