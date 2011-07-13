//
//  SHKItem+KVC.m
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

#import "SHKItem+KVC.h"


@interface SHKItem ()
-(NSArray*)propertyList;
@end


@implementation SHKItem (KVC)


- (NSArray*)propertyList
{
	NSArray *array = [NSArray arrayWithObjects:@"text", @"tags", @"image", @"title", @"URL", @"data", @"mimeType", @"filename" , nil];
	return array;
}


- (BOOL)isProperty:(NSString*)key
{
	for(NSString *property in [self propertyList])
	{
		if([property isEqualToString:key])
			return true;
	}
	
	return false;

}


- (id)propertyForKey:(NSString*)key
{
	if([self isProperty:key])
		return [self valueForKey:key];
	else
		return [self customValueForKey:key];
}

- (void)setProperty:(id)property forKey:(NSString*)key
{

	if([self isProperty:key])
		[self setValue:property forKey:key];
	else
		[self setCustomValue:property forKey:key];

}

/*
- (id)valueForUndefinedKey:(NSString *)key
{	

	return [self customValueForKey:key];

}


- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
	
	[self setCustomValue:value forKey:key];
	
}
*/

@end
