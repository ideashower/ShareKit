//
//  SHKPlurk.h
//  ShareKit
//
//  Created by Yehnan Chiang on 5/19/11.
//  Copyright 2011 Yehnan Chiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHKSharer.h"

#define PLURK_DATA_MAX 140

@class SHKPlurkForm;

@interface SHKPlurk : SHKSharer {
}

- (void)showPlurkForm;

- (void)sendForm:(SHKPlurkForm *)form;

@end
