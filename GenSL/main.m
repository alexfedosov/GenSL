//
//  main.m
//  GenSL
//
//  Created by Alexander Fedosov on 17.01.14.
//  Copyright (c) 2014 Alexander Fedosov. All rights reserved.
//

#import <CoreServices/CoreServices.h>
#import <AppKit/AppKit.h>
#import <stdarg.h>

NSArray* findAllMathcesWithPattern(NSString* pattern, NSString* string);
void writeToOutput(NSString* outputFilePath);
    
NSMutableDictionary* dict;

int main (int argc, const char * argv[])
{
    int result = EXIT_SUCCESS;
    NSUserDefaults *args = [NSUserDefaults standardUserDefaults];
    NSString *dir = [args stringForKey:@"dir"];
    NSString *outputPath = [args stringForKey:@"output"];
    NSMutableSet *contents = [[NSMutableSet alloc] init] ;
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir;
    
    dict = [[NSMutableDictionary alloc] init];
    
    if (dir && ([fm fileExistsAtPath:dir isDirectory:&isDir] && isDir))
    {
        if (![dir hasSuffix:@"/"])
        {
            dir = [dir stringByAppendingString:@"/"];
        }
        
        // this walks the |dir| recurisively and adds the paths to the |contents| set
        NSDirectoryEnumerator *de = [fm enumeratorAtPath:dir];
        NSString *f;
        NSString *fqn;
        while ((f = [de nextObject]))
        {
            // make the filename |f| a fully qualifed filename
            fqn = [dir stringByAppendingString:f];
            if ([fm fileExistsAtPath:fqn isDirectory:&isDir] && isDir)
            {
                // append a / to the end of all directory entries
                fqn = [fqn stringByAppendingString:@"/"];
            }
            [contents addObject:fqn];
        }
        
        NSString *fn;
        // here we sort the |contents| before we display them
        for ( fn in [[contents allObjects] sortedArrayUsingSelector:@selector(compare:)] )
        {
            // search for all .h and .m files
            NSArray* matches = findAllMathcesWithPattern(@".*[.](h|H|m|M)", fn);
    
            for (NSTextCheckingResult* match in matches) {
                NSString* matchText = [fn substringWithRange:[match range]];
                
                
                // ok, read the file
                NSData* data = [NSData dataWithContentsOfFile:matchText];
                NSString* fileContent = [[[NSString alloc] initWithBytes:[data bytes]
                                                            length:[data length]
                                                          encoding:NSUTF8StringEncoding]stringByReplacingOccurrencesOfString:@"\n" withString:@""];

                // now we need to find NSLocalizedString(@"Message",@"Message")

                NSArray* matchesLoc = findAllMathcesWithPattern(@"NSLocalizedString.+?\\)", fileContent);
                
                for (NSTextCheckingResult* matchContent in matchesLoc) {
                    NSString* matchTextLoc = [fileContent substringWithRange:[matchContent range]];
                    NSLog(@"%@", matchesLoc);
                    
                    //ok, last iteration - find all key=value @""
                    
                    NSString* kv = [matchTextLoc stringByReplacingOccurrencesOfString:@"NSLocalizedString" withString:@""];
                    kv = [kv stringByReplacingOccurrencesOfString:@"(" withString:@""];
                    kv = [kv stringByReplacingOccurrencesOfString:@")" withString:@""];
                    kv = [kv stringByReplacingOccurrencesOfString:@"@" withString:@""];
                    kv = [kv stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                    
                   NSArray* strings = [kv componentsSeparatedByString:@","];
                    
                    [dict setObject:[[strings objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]] forKey:[[strings objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]]];
      
                    
                }
                
                
        }
            
            //write all to file
            writeToOutput(outputPath);
        }
    }
    else
    {
        printf("%s must be directory and must exist\n", [dir UTF8String]);
        result = EXIT_FAILURE;
    }
    
    return result;
}



NSArray* findAllMathcesWithPattern(NSString* pattern, NSString* string)
{

    NSRange   searchedRange = NSMakeRange(0, [string length]);
    NSError  *error = nil;
    
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern: pattern options:0 error:&error];
    NSArray* matches = [regex matchesInString:string options:0 range: searchedRange];
    if (error != nil) NSLog(@"error %@", [error description]);
    
    return matches;
}

void writeToOutput(NSString* outputFilePath){
    
    NSString* outp = @"";
    
    for(NSString* key in dict) {
        NSString* value = [dict objectForKey:key];
        
        outp = [outp stringByAppendingString:[NSString stringWithFormat:@"/* %@ */\n\"%@\" = \"%@\";\n\n\n", value, key, key]];
    }
    
    NSError* writeError = nil;
    [outp writeToFile:outputFilePath atomically:YES encoding:NSUTF16StringEncoding error:&writeError];

    
}

