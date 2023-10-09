//
//  StatisticsController.h
//  DriveWire
//
//  Created by Boisy Pitre on Thu Feb 13 2003.
//  Copyright (c) 2003 AES. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface StatisticsController : NSObject
{
    NSString *lastOpCode;
    unsigned int lastLSN;
    unsigned int sectorReadCount;
    unsigned int sectorWriteCount;
    unsigned int readRetries;
    unsigned int writeRetries;
    NSString *lastGetStat;
    NSString *lastSetStat;
}

- (void)setLastOpCode: (NSString *)opCode;
- (NSString *)lastOpCode;
- (void)resetLastOpCode;

- (unsigned int)lastLSN;
- (void)setLastLSN:(int)count;
- (void)resetLastLSN;

- (unsigned int)sectorReadCount;
- (void)setSectorReadCount:(int)count;
- (void)incrementSectorReadCount;
- (void)decrementSectorReadCount;
- (void)resetSectorReadCount;

- (unsigned int)sectorWriteCount;
- (void)incrementSectorWriteCount;
- (void)decrementSectorWriteCount;
- (void)resetSectorWriteCount;

- (unsigned int)readRetries;
- (void)incrementReadRetries;
- (void)decrementReadRetries;
- (void)resetReadRetries;

- (unsigned int)writeRetries;
- (void)incrementWriteRetries;
- (void)decrementWriteRetries;
- (void)resetWriteRetries;

- (NSString *)lastGetStat;
- (void)setLastGetStat:(int)code;
- (void)resetLastGetStat;

- (NSString *)lastSetStat;
- (void)setLastSetStat:(int)code;
- (void)resetLastSetStat;

// Reset all stats
- (void)resetAll;

// Get/SetStat Strings
- (NSString *)statCodeToString:(int)code;

@end
