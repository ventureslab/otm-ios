/*

 NSMutableOrderedSet+Queue.m

 Created by Justin Walgran on 5/2/12.

 License
 =======
 Copyright (c) 2012 Azavea. All rights reserved.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 */

#import "NSMutableOrderedSet+Queue.h"

@implementation NSMutableOrderedSet (Queue)

- (void)enqueue:(id)item
{
    [self insertObject:item atIndex:0];
}

- (id)dequeue
{
    @synchronized (self) {
        id lastObject = [self lastObject];
        [self removeObjectAtIndex:([self count]-1)];
        return lastObject;
    }
}

- (void)requeue:(id)item
{
    @synchronized (self) {
        [self moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:[self indexOfObject:item]]
            toIndex:([self count]-1)];
    }
}

@end
