//
//  MemoryKeyController.m
//  EliKeysC2
//
//  Created by Dror Kessler on 21/10/2021.
//

#import <Foundation/Foundation.h>
#import "MemoryKeyController.h"
#import "ViewController.h"
#import "NSMutableArray_Shuffling.h"
#import "DBConnection.h"

typedef enum {
    Number,
    Card,
    Word
} ChipType;

@interface MemoryKeyController ()
@property (weak) ViewController* vc;
@property NSMutableArray<NSString*>* chips;
@property NSUInteger lastChipIndex;
@property NSUInteger chipCount;
@property ChipType chipType;
@property NSUInteger selectionCount;
@end

@implementation MemoryKeyController

// initilize instance
-(MemoryKeyController*)initWith:(ViewController*)vc
{
    self = [super init];
    if (self) {
        [self setVc:vc];
        _chipCount = 8;
        _chipType = Card;
    }
    return self;
}

-(NSArray<KeyFilterExpr*>*)filtersForKey:(NSUInteger)keyTag {
    
    KeyFilterExpr*        f1 = [[KeyFilterExpr alloc] initWithPattern:KEYFILTER_P_IMMEDIATE];
    [f1 setEmits:FALSE];

    KeyFilterExpr*        f2 = [[KeyFilterExpr alloc] initWithPattern:KEYFILTER_P_LONG];

    // hardcoded for now
    return [NSArray arrayWithObjects: f1, f2, nil];
}

-(void)reset {
    [self allDone:nil];
}

-(void)allDone:(id)obj {
    _lastChipIndex = -1;
    [self dealChips];
    
    [[_vc speech] flushSpeechQueue];
    if ( obj != nil )
        [[_vc speech] speak:[NSString stringWithFormat:@"%ld מהלכים", _selectionCount]];
    [[_vc speech] speak:[NSString stringWithFormat:@"%ld קלפים חדשים", [self chipsLeft]]];
    _selectionCount = 0;
}


-(void)keyPress:(NSUInteger)keyTag keyFilterIndex:(NSUInteger)filterIndex {
    
    if ( filterIndex == 1 )
        [[_vc tones] keyLongPressed];
    
    if ( keyTag == 0 ) {
        // reset or change number of chips
        if ( filterIndex == 0 )
            [self reset];
        else {
            _chipCount += 4;
            if ( _chipCount > 16 )
                _chipCount = 4;
            [self reset];
        }
    } else if ( filterIndex == 0 ){
        _selectionCount++;
        NSUInteger         index = keyTag - 1;
        if ( index >= [_chips count] ) {
            [_vc beepError];
            _lastChipIndex = -1;
        } else {
            NSString*      chip = [_chips objectAtIndex:index];
            if ( ![chip length] ) {
                [_vc beepError];
                _lastChipIndex = -1;
            } else {
                [[_vc speech] flushSpeechQueue];
                [[_vc speech] speak:chip];
                if ( _lastChipIndex == -1 ) {
                    _lastChipIndex = index;
                } else if ( _lastChipIndex == index ) {
                    ;
                } else {
                    NSString* otherChip = [_chips objectAtIndex:_lastChipIndex];
                    if ( [otherChip isEqualToString:chip] ) {
                        [_chips setObject:@"" atIndexedSubscript:_lastChipIndex];
                        [_chips setObject:@"" atIndexedSubscript:index];
                        [[_vc tones] keyLongPressed];
                        if ( ![self chipsLeft] ) {
                            [self performSelector:@selector(allDone:) withObject:self afterDelay:1.0];
                        }
                    } else {
                        _lastChipIndex = index;
                    }
                }
            }
        }
    } else if ( filterIndex == 1 && (keyTag >=1 && keyTag <= 3) ) {
        [[_vc tones] keyLongPressed];
        if ( keyTag == 1 )
            _chipType = Number;
        else if ( keyTag == 2 )
            _chipType = Card;
        else if ( keyTag == 3 )
            _chipType = Word;
        
        [self reset];
    }
}

-(void)dealChips {
    // setup chips
    [self setChips:[NSMutableArray array]];
    for ( int n = 0 ; n < _chipCount ; n += 2 ) {
        NSString*       chip;
        do {
            chip = [self randomChipValue];
        } while ( [_chips containsObject:chip] );
        [_chips addObject:chip];
        [_chips addObject:chip];
    }

    // randomize
    [_chips shuffle];
    
    // nothing selected
    _lastChipIndex = -1;
}

-(NSUInteger)chipsLeft {
    NSUInteger          c = 0;
    
    for ( NSString* s in _chips )
        if ( [s length] )
            c++;
    
    return c;
}

-(NSString*)randomChipValue {
    
    if ( _chipType == Number ) {
        // for now, this is a nunber between 1 and 24
        return [NSString stringWithFormat:@"%d", rand() % 24 + 1];
    } else if ( _chipType == Card ) {
        
        NSArray<NSString*>*   cards = [@"2,3,4,5,6,7,8,9,10,נסיך,מלכה,מלך,אס" componentsSeparatedByString:@","];
        NSUInteger r = rand() % [cards count];
        return [cards objectAtIndex:r];
    } else if ( _chipType == Word ) {
        NSString*   query = [NSString stringWithFormat:@"select word as w \
                                    from words \
                                    where freq > 100 \
                                    order by random() limit 1"];
        //NSLog(@"query: %@", query);
        NSMutableArray*    results = [DBConnection fetchResults:query];
        for ( NSDictionary* obj in results ) {
            NSString*       w = [obj objectForKey:@"w"];
            return w;
        }
    }
    
    // fail safe
    return [NSString stringWithFormat:@"%d", rand()];
}


@end
