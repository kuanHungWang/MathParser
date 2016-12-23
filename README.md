# MathParser

Math parser is a objective-c class that can parse a string of mathmetical expression into a infix notation, converting to revsersed-polish notation(postfix notation), and calculate its value. It can also use custom-defined function.

## Installation

Just add BTMathParser.h and BTMathParser.m to your project.

## Usage
import head file

```obj-c
#import "BTMathParser.h" 
```

Create a BTMathParser instance and calculate a result of a mathematical expression string.

```obj-c
BTMathParser *mathParser = [[BTMathParser alloc] init];
float result = [mathParser valueForExpression:@"1+1" error:nil];

```
You can create you own functions to expand its functionality. BTMathParser has built-in functions for AND, OR, MAX, MIN

```obj-c
NSArray *functionMaps=[BTMathParser basicFunctions];
mathParser.functions=functionMaps;
result = [mathParser valueForExpression:@"MAX(1,2)" error:nil];

```
To use your own function, create FunctionMap instance and add into an NSArray and assign to mathParser.functions property.<br/>
The class "FunctionMap" have 3 requried property:

(1) Function: The function itself in the form of a block: float (^)(float *a).<br/>
(2) argumentNumber: The number of argument of the function.<br/>
(3) name: the Name of function. (capital-sensitive)<br/><br/>
After you have the three things above ready, use FunctionMap's " initWithBlock:name:argNumber" method to create the FunctionMap.

###Built-in operators:
- Arithmetic operators: +, -, *, /, ^ <br/>
- Logical operators: &&, &, ||, |. <br/>There is no bitwise operstors, both "&&" and "&" stand for 'AND', and both "|" and "||" stand for 'OR'. Alternatively, you can use functions "AND" and "OR" provided by [BTMathParser basicFunctions] class methods. <br/>
- Relational operators: >, >=, =, <=, <, != <br/>

###Keys of UserInfo in Error.

- ErrorKeyStage: the stage which error occur.
- ErrorKeyRange: the NSRange in the original string where error occur.
- ErrorKeyFunctionName: the name of function, only available if error is related to function.
- ErrorKeyArgumentNumber: the number of argument required, only available if error is related to function.
- ErrorKeyErroChar: the char that cause the error.
- If error occurs, the method will return FLT_MAX.

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## History


## Credits


## License

MIT License

Copyright (c) [2016] [KuanHung Wang]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.