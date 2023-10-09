//
//  StatisticsController.m
//  DriveWire
//
//  Created by Boisy Pitre on Thu Feb 13 2003.
//  Copyright (c) 2003 AES. All rights reserved.
//

#import "StatisticsController.h"


@implementation StatisticsController

- (id)init
{
    if (self = [super init])
    {
        [self resetAll];
    }

    return self;
}


// OpCode
- (void)setLastOpCode: (NSString *)opCode
{
    lastOpCode = opCode;
}


- (void)resetLastOpCode
{
    lastOpCode = @"OP_RESET";
}


- (NSString *)lastOpCode
{
    return(lastOpCode);
}



// Last LSN
- (unsigned int)lastLSN
{
    return(lastLSN);
}
    
    
- (void)setLastLSN:(int)LSN
{
    lastLSN = LSN;
}


- (void)resetLastLSN
{
    lastLSN = 0;
}


// Read Count
- (unsigned int)sectorReadCount
{
    return(sectorReadCount);
}
    
    
- (void)incrementSectorReadCount
{
    sectorReadCount++;
}


- (void)decrementSectorReadCount
{
    sectorReadCount--;
}


- (void)setSectorReadCount:(int)count
{
    sectorReadCount = count;
}


- (void)resetSectorReadCount
{
    sectorReadCount = 0;
}


// Write Count
- (unsigned int)sectorWriteCount
{
    return(sectorWriteCount);
}
    
     
- (void)incrementSectorWriteCount
{
    sectorWriteCount++;
}


- (void)decrementSectorWriteCount
{
    sectorWriteCount--;
}


- (void)resetSectorWriteCount
{
    sectorWriteCount = 0;
}


// Read Retries
- (unsigned int)readRetries
{
    return(readRetries);
}
    
    
- (void)incrementReadRetries
{
    readRetries++;
}


- (void)decrementReadRetries
{
    readRetries--;
}


- (void)resetReadRetries
{
    readRetries = 0;
}


// Write Retries
- (unsigned int)writeRetries
{
    return(writeRetries);
}
    
    
- (void)incrementWriteRetries
{
    writeRetries++;
}


- (void)decrementWriteRetries
{
    writeRetries--;
}


- (void)resetWriteRetries
{
    writeRetries = 0;
}


// GetStat
- (NSString *)lastGetStat
{
    return(lastGetStat);
}


- (void)setLastGetStat:(int)code
{
    lastGetStat = [self statCodeToString:code];
    
    return;
}


- (void)resetLastGetStat
{
    lastGetStat = @"NONE";
    
    return;
}


// SetStat
- (NSString *)lastSetStat
{
    return(lastSetStat);
}


- (void)setLastSetStat:(int)code
{
    lastSetStat = [self statCodeToString:code];
    
    return;
}


- (void)resetLastSetStat
{
    lastSetStat = @"NONE";
    
    return;
}


- (void)resetAll
{
    [self resetLastOpCode];
    [self resetLastLSN];
    [self resetSectorReadCount];
    [self resetSectorWriteCount];
    [self resetReadRetries];
    [self resetWriteRetries];
    [self resetLastGetStat];
    [self resetLastSetStat];
}


- (NSString *)statCodeToString:(int)code
{
    NSString *statString;
    
    switch (code)
    {
        case 0x00:
            statString = @"SS.Opt";
            break;
            
        case 0x02:
            statString = @"SS.Size";
            break;
            
        case 0x03:
            statString = @"SS.Reset";
            break;
            
        case 0x04:
            statString = @"SS.WTrk";
            break;
            
        case 0x05:
            statString = @"SS.Pos";
            break;
            
        case 0x06:
            statString = @"SS.EOF";
            break;
            
        case 0x0A:
            statString = @"SS.Frz";
            break;
            
        case 0x0B:
            statString = @"SS.SPT";
            break;
            
        case 0x0C:
            statString = @"SS.SQD";
            break;
            
        case 0x0D:
            statString = @"SS.DCmd";
            break;
            
        case 0x0E:
            statString = @"SS.DevNm";
            break;
            
        case 0x0F:
            statString = @"SS.FD";
            break;
            
        case 0x10:
            statString = @"SS.Ticks";
            break;
            
        case 0x11:
            statString = @"SS.Lock";
            break;
            
        case 0x12:
            statString = @"SS.VarSect";
            break;

        case 0x14:
            statString = @"SS.BlkRd";
            break;
            
        case 0x15:
            statString = @"SS.BlkWr";
            break;
            
        case 0x16:
            statString = @"SS.Reten";
            break;
            
        case 0x17:
            statString = @"SS.WFM";
            break;
            
        case 0x18:
            statString = @"SS.RFM";
            break;
            
        case 0x1B:
            statString = @"SS.Relea";
            break;
            
        case 0x1C:
            statString = @"SS.Attr";
            break;
            
        case 0x1E:
            statString = @"SS.RsBit";
            break;
            
        case 0x20:
            statString = @"SS.FDInf";
            break;
            
        case 0x26:
            statString = @"SS.DSize";
            break;
            
        default:
            statString = [[NSString alloc] initWithFormat:@"%d", code];
            break;
    }
            
    return(statString);
}

@end
