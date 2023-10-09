//
//  NSString+DriveWire.m
//  DriveWire
//
//  Created by Boisy Pitre on 10/18/17.
//

#import "NSString+DriveWire.h"

@implementation NSString (DriveWire)

- (NSString *)stringByProcessingBackspaces;
{
    NSString *result = [self copy];
    
    for (int i = 0; i < [result length]; i++)
    {
        if ([result characterAtIndex:i] == '\b')
        {
            if (i > 0)
            {
                NSString *beforeBackspace = [result substringToIndex:i - 1];
                NSString *restOfString = [result substringFromIndex:i + 1];
                result = [NSString stringWithFormat:@"%@%@", beforeBackspace, restOfString];
            }
            else
            {
                NSString *restOfString = [result substringFromIndex:i + 1];
                result = [NSString stringWithFormat:@"%@", restOfString];
            }
            i--;
        }
    }
    
    return result;
}

- (BOOL)isInteger;
{
    NSScanner* scan = [NSScanner scannerWithString:self];
    int val;
    return [scan scanInt:&val] && [scan isAtEnd];
    // Steven Green, from stack overflow
}

@end
