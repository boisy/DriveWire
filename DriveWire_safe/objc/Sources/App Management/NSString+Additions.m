//--------------------------------------------------------------------------------------------------
//
//  Copyright (c) 2009-2021 Boisy G. Pitre
//
//  This source code and specific concepts contained herein are Confidential
//  Information and Property of Boisy G. Pitre.
//  Distribution is prohibited without written permission of Boisy G. Pitre.
//
//--------------------------------------------------------------------------------------------------


#import "NSString+Additions.h"


@implementation NSString (Additions)

/*
 Return the range of a substring, inclusively from starting to ending delimeters
 Original Source: <http://cocoa.karelia.com/Foundation_Categories/NSString/Return_the_range_of_20030523145602.m>
 (See copyright notice at <http://cocoa.karelia.com>)
 */

/*"	Find a string from one string to another with the given options inMask; the delimeter strings %are included in the result.  The inMask parameter is the same as is passed to [NSString rangeOfString:options:range:].
 "*/

/*"	Find a string from one string to another with the given options inMask and the given substring range inSearchRange; the delimeter strings %are included in the result.  The inMask parameter is the same as is passed to [NSString rangeOfString:options:range:].
 "*/

- (NSRange) rangeFromString:(NSString *)inString1 toString:(NSString *)inString2
					options:(unsigned)inMask range:(NSRange)inSearchRange;
{
	NSRange result;
	NSRange stringStart = NSMakeRange(inSearchRange.location,0); // if no start string, start here
	NSUInteger foundLocation = inSearchRange.location;	// if no start string, start here
	NSRange stringEnd = NSMakeRange(NSMaxRange(inSearchRange),0); // if no end string, end here
	NSRange endSearchRange;
	if (nil != inString1)
	{
		// Find the range of the list start
		stringStart = [self rangeOfString:inString1 options:inMask range:inSearchRange];
		if (NSNotFound == stringStart.location)
		{
			return stringStart;	// not found
		}
		foundLocation = NSMaxRange(stringStart);
	}
	endSearchRange = NSMakeRange( foundLocation, NSMaxRange(inSearchRange) - foundLocation );
	if (nil != inString2)
	{
		stringEnd = [self rangeOfString:inString2 options:inMask range:endSearchRange];
		if (NSNotFound == stringEnd.location)
		{
			return stringEnd;	// not found
		}
	}
	result = NSMakeRange (stringStart.location, NSMaxRange(stringEnd) - stringStart.location );
	return result;
}

- (NSRange)rangeFromString:(NSString *)inString1 toString:(NSString *)inString2
				   options:(unsigned)inMask;
{
	return [self rangeFromString:inString1 toString:inString2
						 options:inMask
						   range:NSMakeRange(0,[self length])];
}

/*"	Find a string from one string to another with the default options; the delimeter strings are included in the result.
 "*/
- (NSRange)rangeFromString:(NSString *)inString1 toString:(NSString *)inString2;
{
	return [self rangeFromString:inString1 toString:inString2 options:0];
}

/*
 General search and replace, replacing strings found between starting and ending delimeters.
 Original Source: <http://cocoa.karelia.com/Foundation_Categories/NSString/General_search_and_.m>
 (See copyright notice at <http://cocoa.karelia.com>)
 */

/*"	General search-and-replace mechanism to convert text between the given delimeters.  Pass in a dictionary with the keys of "from" strings, and the values of what to convert them to.  If not found in the dictionary,  the text will just be removed.  If the dictionary passed in is nil, then the string between the delimeters will put in the place of the whole range; this could be used to just strip out the delimeters.
 
 Requires -[NSString rangeFromString:toString:options:range:].
 "*/

- (NSString *)replaceAllTextBetweenString:(NSString *)inString1 andString:(NSString *)inString2
						   fromDictionary:(NSDictionary *)inDict
								  options:(unsigned)inMask range:(NSRange)inSearchRange;
{
	NSRange range = inSearchRange;	// We'll increment this
	NSInteger startLength = [inString1 length];
	NSInteger delimLength = startLength + [inString2 length];
	NSMutableString *buf = [NSMutableString string];
	
	NSRange beforeSearchRange = NSMakeRange(0,inSearchRange.location);
	[buf appendString:[self substringWithRange:beforeSearchRange]];
	
	// Now loop through; looking.
	while (range.length != 0)
	{
		NSRange foundRange = [self rangeFromString:inString1 toString:inString2 options:inMask range:range];
		if (foundRange.location != NSNotFound)
		{
			// First, append what was the search range and the found range -- before match -- to output
			{
				NSRange beforeRange = NSMakeRange(range.location, foundRange.location - range.location);
				NSString *before = [self substringWithRange:beforeRange];
				[buf appendString:before];
			}
			// Now, figure out what was between those two strings
			{
				NSRange betweenRange = NSMakeRange(foundRange.location + startLength, foundRange.length - delimLength);
				NSString *between = [self substringWithRange:betweenRange];
				if (nil != inDict)
				{
					between = [inDict objectForKey:between];	// replace string
				}
				// Now append the between value if not nil
				if (nil != between)
				{
					[buf appendString:[between description]];
				}
			}
			// Now, update things and move on.
			range.length = NSMaxRange(range) - NSMaxRange(foundRange);
			range.location = NSMaxRange(foundRange);
		}
		else
		{
			NSString *after = [self substringWithRange:range];
			[buf appendString:after];
			// Now, update to be past the range, to finish up.
			range.location = NSMaxRange(range);
			range.length = 0;
		}
	}
	// Finally, append stuff after the search range
	{
		NSRange afterSearchRange = NSMakeRange(range.location, [self length] - range.location);
		[buf appendString:[self substringWithRange:afterSearchRange]];
	}
	return [NSString stringWithString:buf];
}


/*"	Replace between the two given strings with the given options inMask; the delimeter strings are not included in the result.  The inMask parameter is the same as is passed to [NSString rangeOfString:options:range:].
 "*/

- (NSString *)replaceAllTextBetweenString:(NSString *)inString1 andString:(NSString *)inString2
							fromDictionary:(NSDictionary *)inDict
								  options:(unsigned)inMask;
{
	return [self replaceAllTextBetweenString:inString1 andString:inString2
							  fromDictionary:inDict 
									 options:inMask
									   range:NSMakeRange(0,[self length])];
}

/*"	Replace between the two given strings with the default options; the delimeter strings are not included in the result.
 "*/

- (NSString *)replaceAllTextBetweenString:(NSString *)inString1 andString:(NSString *)inString2
						   fromDictionary:(NSDictionary *)inDict;
{
	return [self replaceAllTextBetweenString:inString1 andString:inString2 fromDictionary:inDict options:0];
}

+(NSString *)stringWithBytes:(const void *)bytes length:(NSUInteger)length encoding:(NSStringEncoding)encoding;
{
	return [[NSString alloc] initWithBytes:bytes length:length encoding:encoding];
}

-(BOOL)hasCaseInsensitivePrefix:(NSString *)prefix;
{
    return [self rangeOfString:prefix options:(NSCaseInsensitiveSearch | NSAnchoredSearch) range:NSMakeRange(0, [prefix length])].location != NSNotFound;
}

-(BOOL)hasCaseInsensitiveSuffix:(NSString *)suffix;
{
    return [self rangeOfString:suffix options:(NSCaseInsensitiveSearch | NSBackwardsSearch) range:NSMakeRange(0, [suffix length])].location != NSNotFound;
}

-(NSString *)stringByReplacingSpaceWithUnderscore;
{
    NSMutableString *ms = [NSMutableString stringWithString:self];

    [ms replaceOccurrencesOfString:@" " withString:@"_" options:0 range:NSMakeRange(0, [self length])];

    return ms;
}

-(NSString *)stringByAddingURLEscapesUsingEncoding:(CFStringEncodings)enc;
{
    NSString *str2 = [self stringByAddingURLEscapesUsingEncoding:NSUTF8StringEncoding];
//    NSString *str2 = (id)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self, nil, nil, enc));

    return str2;
}

- (BOOL)stringEndsWithString:(NSString *)s;
{
	BOOL result = FALSE;
	
	NSRange r = [self rangeOfString:s];
	
	if (r.location != NSNotFound)
	{
		if (r.location + r.length == [self length])
		{
			result = TRUE;
		}
	}
	
	return result;
}

-(BOOL)stringContainsString:(NSString *)s;
{
    NSRange	aRange;
    
    aRange = [self rangeOfString:s];
    
    return (aRange.location != NSNotFound);
}

-(BOOL)stringContainsCaseInsensitiveString:(NSString *)s;
{
    NSRange	aRange;
    
    aRange = [self rangeOfString:s options:NSCaseInsensitiveSearch range:NSMakeRange(0, [self length])];
    
    return (aRange.location != NSNotFound);
}

-(BOOL)stringContainsCharactersFromString:(NSString *)s;
{
	NSCharacterSet*set = [NSCharacterSet characterSetWithCharactersInString:s];

	return [self stringContainsCharactersFromSet:set];
}

-(BOOL)stringContainsCharactersFromSet:(NSCharacterSet *)set;
{
	return ([self rangeOfCharacterFromSet:set].location != NSNotFound);
}

-(BOOL)stringBeginsWithTwoNumbers;
{
	NSScanner *scanner = [NSScanner scannerWithString:self];
        
	if ([scanner scanInt:nil])
	{
		if ([scanner scanInt:nil])
			return YES;
		else
			return NO;
	}
	else
		return NO;
}

-(NSMutableArray *)splitLines;
{
    NSMutableArray	*arrayOfLines = [[NSMutableArray alloc] init];

/* 
        unsigned	start;
        unsigned	stringLength = [self length];
    NSRange		lineRange = NSMakeRange(0, 0);
    NSRange		searchRange = NSMakeRange(0, 0);
    
    while ( searchRange.location < stringLength )
    {
                [self getLineStart:&start end: &searchRange.location contentsEnd: &end forRange: searchRange];
                lineRange.length = searchRange.location - lineRange.location;

                [arrayOfLines addObject:[self substringWithRange: lineRange]];
                lineRange.location = searchRange.location;
    }
*/

	NSUInteger start; 
	NSUInteger end; 
	NSUInteger next; 
	NSUInteger stringLength; 
	NSRange range; 

	stringLength = [self length]; 
	range.location = 0; 
	range.length = 1; 

	do
	{ 
		[self getLineStart:&start end:&next contentsEnd:&end forRange:range]; 

		range.location = start; 
		range.length = end-start; 

		[arrayOfLines addObject:[self substringWithRange:range]]; 

		range.location = next; 
		range.length = 1; 
	}
	while (next < stringLength); 

	return arrayOfLines;
}

- (NSString *)stringByRemovingWhitespaceCharacters;
{
    return [self stringByRemovingCharactersFromSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSString *)stringByRemovingNewline;
{
    return [self stringByRemovingCharactersFromSet:[NSCharacterSet newlineCharacterSet]];
}

- (NSString *)stringByRemovingWhitespaceCharactersAndNewline;
{
    return [self stringByRemovingCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)stringByRemovingCharactersFromSet:(NSCharacterSet *)set;
{
    NSMutableString	*temp;

    if ([self rangeOfCharacterFromSet:set options:NSLiteralSearch].length == 0)
        return self;
    
    temp = [self mutableCopy];
    [temp removeCharactersInSet:set];

    return temp;
}

//- (NSString *) stringByRemovingRichTextFromString: (NSString *) inputString
//{
//	if ([inputString hasCaseInsensitivePrefix: @"{\\rtf1"])
//	{
//		NSAttributedString *rtfstring = [[NSAttributedString alloc]initWithRTF: inputString documentAttributes: nil];
//		inputString = [rtfstring string];
//		[rtfstring release];
//	}
//	
//	return inputString;
//}

- (NSString *)bracketedStringWithLeftBracket:(NSString *)leftBracket rightBracket:(NSString *)rightBracket caseSensitive:(BOOL)caseSensitive;
{
    if (caseSensitive)
	{
        NSRange startRange = [self rangeOfString: leftBracket];

        if (startRange.location == NSNotFound)
			return nil;

        NSInteger  startPosition = startRange.location + startRange.length;
        
        NSRange endRange = [self rangeOfString:rightBracket options:0 range:NSMakeRange(startPosition, ([self length] - startPosition))];

        if (endRange.location == NSNotFound)
			return nil;
        
        if (startPosition >= endRange.location)
			return @"";
        
        return [self substringWithRange:NSMakeRange( startPosition, endRange.location - startPosition)];
    }
	else
	{
        NSRange startRange = [self rangeOfString:leftBracket options:NSCaseInsensitiveSearch];

        if (startRange.location == NSNotFound)
			return nil;

        NSInteger  startPosition = startRange.location + startRange.length;
        
        NSRange endRange = [self rangeOfString:rightBracket options:NSCaseInsensitiveSearch range:NSMakeRange(startPosition, ([self length] - startPosition))];

        if (endRange.location == NSNotFound)
			return nil;
        
        if (startPosition >= endRange.location)
			return @"";
        
        return [self substringWithRange:NSMakeRange(startPosition, endRange.location - startPosition)];
    }
    
    return nil;
}

- (NSString *)addSpacesToStringWithInterval:(int)interval;
{
        return [self addSpacesToStringWithInterval:interval removeOldWhitespaces:NO];
}

- (NSString *)addSpacesToStringWithInterval:(int)interval removeOldWhitespaces:(BOOL)remove;
{
    NSMutableString	*newString;
    NSInteger				i;
        
    if (remove)
        newString = [[self stringByRemovingWhitespaceCharacters] mutableCopy];
    else
        newString = [self mutableCopy];
        
    i = [newString length] - 1;
    
    while (i > 0)
    {
        if (i % interval == 0)
        {
            [newString insertString: @" " atIndex:i];
            i -= interval;
        }
        else
			i--;
    }
        
    return newString;
}

- (NSMutableString *)convertLineBreaksToMac;
{
    // \r\n (Windows) becomes \r\r - \n (Unix) becomes \r
    NSMutableString *theString = [[NSMutableString alloc] initWithString:self];
        
    [theString replaceOccurrencesOfString:@"\r\n" withString:@"\r" options:0 range:NSMakeRange(0, [theString length])];
    [theString replaceOccurrencesOfString:@"\n" withString:@"\r" options:0 range:NSMakeRange(0, [theString length])];
    
	return theString;
}

- (NSString *)capitalizedStringFirstWordOnly;
{
	return [self stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[self substringToIndex:1] capitalizedString]];
}

- (NSString *)lowercaseStringFirstWordOnly;
{
	int i;
	
	for (i = 0; i < [self length]; i++)
	{
		if ([self characterAtIndex:i] == ' ' || [self characterAtIndex:i] >= 'a')
		{
			break;
		}
	}
	
	return [self stringByReplacingCharactersInRange:NSMakeRange(0, i) withString:[[self substringToIndex:i] lowercaseString]];
}

- (NSString *)camelCaseString;
{
    NSString *cleansedString = [self stringByRemovingCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@",/()"]];
    NSArray *words = [cleansedString componentsSeparatedByString:@" "];
    
    NSString *result = @"";
    
    for (int i = 0; i < [words count]; i++)
    {
        NSString *word = [words objectAtIndex:i];
    
        if (i == 0)
        {
            result = [result stringByAppendingString:[word lowercaseString]];
        }
        else
        {
            result = [result stringByAppendingString:[word capitalizedString]];
        }
    }

	return result;
}

@end

@implementation NSMutableString (BGPMutableStringAdditions)

- (void)removeCharactersInSet:(NSCharacterSet *)set;
{
    NSRange		matchRange, searchRange, replaceRange;
    NSUInteger	length;

    length = [self length];
    matchRange = [self rangeOfCharacterFromSet:set options:NSLiteralSearch range:NSMakeRange(0, length)];
    
    while (matchRange.length > 0)
    {
        replaceRange = matchRange;
        searchRange.location = NSMaxRange(replaceRange);
        searchRange.length = length - searchRange.location;
        
        for (;;)
        {
            matchRange = [self rangeOfCharacterFromSet:set options:NSLiteralSearch range:searchRange];
            if ((matchRange.length == 0) || (matchRange.location != searchRange.location))
                break;
            replaceRange.length += matchRange.length;
            searchRange.length -= matchRange.length;
            searchRange.location += matchRange.length;
        }
        
        [self deleteCharactersInRange:replaceRange];
        matchRange.location -= replaceRange.length;
        length -= replaceRange.length;
    }
}

@end

@implementation NSString (BGPRelativePath)

- (NSString *)absolutePathFromBaseDirPath:(NSString *)baseDirPath
{
    if ([self hasPrefix:@"~"]) {
        return [self stringByExpandingTildeInPath];
    }
    
    NSString *theBasePath = [baseDirPath stringByExpandingTildeInPath];
	
    if (![self hasPrefix:@"."]) {
        return [theBasePath stringByAppendingPathComponent:self];
    }
    
    NSMutableArray *pathComponents1 = [NSMutableArray arrayWithArray:[self pathComponents]];
    NSMutableArray *pathComponents2 = [NSMutableArray arrayWithArray:[theBasePath pathComponents]];
	
    while ([pathComponents1 count] > 0) {        
        NSString *topComponent1 = [pathComponents1 objectAtIndex:0];
        [pathComponents1 removeObjectAtIndex:0];
		
        if ([topComponent1 isEqualToString:@".."]) {
            if ([pathComponents2 count] == 1) {
                // Error
                return nil;
            }
            [pathComponents2 removeLastObject];
        } else if ([topComponent1 isEqualToString:@"."]) {
            // Do nothing
        } else {
            [pathComponents2 addObject:topComponent1];
        }
    }
    
    return [NSString pathWithComponents:pathComponents2];
}

- (NSString *)relativePathFromBaseDirPath:(NSString *)baseDirPath
{
    NSString *thePath = [self stringByExpandingTildeInPath];
    NSString *theBasePath = [baseDirPath stringByExpandingTildeInPath];
    
    NSMutableArray *pathComponents1 = [NSMutableArray arrayWithArray:[thePath pathComponents]];
    NSMutableArray *pathComponents2 = [NSMutableArray arrayWithArray:[theBasePath pathComponents]];
	
    // Remove same path components
    while ([pathComponents1 count] > 0 && [pathComponents2 count] > 0) {
        NSString *topComponent1 = [pathComponents1 objectAtIndex:0];
        NSString *topComponent2 = [pathComponents2 objectAtIndex:0];
        if (![topComponent1 isEqualToString:topComponent2]) {
            break;
        }
        [pathComponents1 removeObjectAtIndex:0];
        [pathComponents2 removeObjectAtIndex:0];
    }
    
    // Create result path
    for (int i = 0; i < [pathComponents2 count]; i++) {
        [pathComponents1 insertObject:@".." atIndex:0];
    }
    if ([pathComponents1 count] == 0) {
        return @".";
    }
    return [NSString pathWithComponents:pathComponents1];
}

@end

@implementation NSString (BGPNonPrintable)

- (NSString *)stringByEscapingNonPrintableCharacters;
{
    NSMutableString *result = [@"" mutableCopy];
    for (NSInteger idx = 0; idx < self.length; idx++)
	{
		unichar ch = [self characterAtIndex:idx];
		if (ch < 32 || ch > 127) {
			[result appendFormat:@"<%02x>", ch];
		} else {
			[result appendFormat:@"%C", ch];
		}
    }

    return result;
}

@end

@implementation NSString (BGPStringConversions)

- (NSInteger)valueOfHexString;
{
	NSInteger length = [self length];
	NSInteger accum = 0;

	if (0 == length)
	{
		return accum;
	}

	NSInteger i = 0;

	// skip any legal prefixes ($, 0x/0X)
	unichar c1 = [self characterAtIndex:0];
	if (c1 == '$')
	{
		i = 1;
	}
	else if (c1 == '0' && length > 1)
	{
		unichar c2 = [self characterAtIndex:1];
		if (c2 == 'x' || c2 == 'X')
		{
			i = 2;
		}
		else
		{
			// illegal character
			return 0;
		}
	}
	
	for (; i < length; i++)
	{
		NSInteger w = (NSInteger)pow(16, (length - i - 1));
		unichar c = [self characterAtIndex:i];
		NSInteger v = 0;
		if (c >= '0' && c <= '9')
		{
			v = (c - '0');
		}
		else if (c >= 'A' && c <= 'F')
		{
			v = (c - 'A') + 10;
		}
		else if (c >= 'a' && c <= 'f')
		{
			v = (c - 'a') + 10;
		}
		else
		{
			// non-hex character... return 0 and give up
			return 0;
		}

		
		accum += v * w;
	}

	return accum;
}

- (NSInteger)valueOfBinaryString;
{
	NSInteger length = [self length];
	NSInteger accum = 0;
	
	if (0 == length)
	{
		return accum;
	}
	
	NSInteger i = 0;
	
	// skip any legal prefixes (%, 0b/0B)
	unichar c1 = [self characterAtIndex:0];
	if (c1 == '%')
	{
		i = 1;
	}
	else if (c1 == '0' && length > 1)
	{
		unichar c2 = [self characterAtIndex:1];
		if (c2 == 'b' || c2 == 'B')
		{
			i = 2;
		}
		else
		{
			// illegal character
			return 0;
		}

	}
	
	for (; i < length; i++)
	{
		NSInteger w = (NSInteger)pow(2, (length - i - 1));
		unichar c = [self characterAtIndex:i];
		NSInteger v = 0;
		if (c == '0')
		{
			v = 0;
		}
		else if (c == '1')
		{
			v = 1;
		}
		else
		{
			// non-binary character... return 0 and give up
			return 0;
		}
		
		
		accum += v * w;
	}
	
	return accum;
}

@end
