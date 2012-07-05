//
//  SHKPinboard.h
//  ShareKit
//
//  Created by Arik Devens on 4/8/11.

#import <Foundation/Foundation.h>
#import "SHKSharer.h"

@interface SHKPosterous : SHKSharer {
	NSMutableData *photoData;
    NSHTTPURLResponse *URLResponse;
}

- (void)finish;

@end
