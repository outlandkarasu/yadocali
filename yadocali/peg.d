/**
 *  PEG parser combinator.
 *
 *  Author: outlandkarasu
 *  License: Boost Software License - Version 1.0
 */

module yadocali.peg;

import std.range;
import std.traits;

/**
 *  match any character.
 *
 *  Params:
 *      R = source range type. (input range requirement)
 *      src = a source range.
 *  Returns:
 *      return true if any character existing.
 */
bool matchAny(S)(ref S src)
        if(isInputRange!S) {
    if(!src.empty) {
        src.popFront();
        return true;
    } else {
        return false;
    }
}

unittest {
    // matching one character source.
    auto src = "a";
    assert(matchAny(src));

    // not matching empty source.
    src = "";
    assert(!matchAny(src));

    // multiple match for string source.
    src = "test";
    assert(matchAny(src));  // t
    assert(matchAny(src));  // e
    assert(matchAny(src));  // s
    assert(matchAny(src));  // t
    assert(!matchAny(src)); // end of source.
}

/**
 *  match a character.
 *
 *  Params:
 *      S = source range type. (input range requirement)
 *      e = a matching character. 
 *  Returns:
 *      true if src.front is e.
 */
bool matchChar(alias e, S)(ref S src)
        if(isInputRange!S && __traits(compiles, (src.front == e))) {
    if(!src.empty && src.front == e) {
        src.popFront();
        return true;
    } else {
        return false;
    }
}

unittest {
    // match a same character.
    auto src = "a";
    assert(matchChar!('a')(src));

    // not match a different character.
    src = "a";
    assert(!matchChar!('x')(src));

    // match string source.
    src = "abcd";
    assert(matchChar!('a')(src));
    assert(matchChar!('b')(src));
    assert(matchChar!('c')(src));
    assert(matchChar!('d')(src));
    assert(!matchChar!('d')(src));
}

/**
 *  match string.
 *
 *  Params:
 *      S = source range type. (forwarding range requirement)
 *      str = a matching string. 
 *  Returns:
 *      true if src.front is e.
 */
bool matchString(alias str, S)(ref S src)
        if(isForwardRange!S && isInputRange!(typeof(str)) && is(ElementType!S : ElementType!(typeof(str)))) {
    auto before = src.save;

    // not use foreach because str parameter can be not array types.
    foreach(e; str) {
        if(src.front != e) {
            src = before;
            return false;
        }
        src.popFront();
    }
    return true;
}

unittest {
    // match a same character.
    auto src = "a";
    assert(matchString!("a")(src));

    // not match a different character.
    src = "a";
    assert(!matchString!("x")(src));

    // match string source.
    src = "abcd";
    assert(matchString!("ab")(src));
    assert(!matchString!("ab")(src));
    
    // rest string
    assert(matchString!("cd")(src));
    assert(src.empty);
}

/**
 *  match empty source.
 *
 *  Params:
 *      S = source range type.
 *      src = a source range. (input range requirements)
 *  Returns:
 *      true if src is empty.
 */
bool matchEmpty(S)(ref S src)
        if(isInputRange!S) {
    return src.empty;
}

unittest {
    // match a empty source.
    auto src = "";
    assert(matchEmpty(src));

    // not match a normal source.
    src = "test";
    assert(!matchEmpty(src));
}

/**
 *  match a character in character range.
 *
 *  Params:
 *      e1 = begin of character range.
 *      e2 = end of character range.
 *      S = source range type.
 *      src = a source range. (input range requirements)
 *  Returns:
 *      true if src.front into character range. (e1 <= src.front <= e2)
 */
bool matchRange(alias e1, alias e2, S)(ref S src)
        if(isInputRange!S && __traits(compiles, (e1 <= src.front && src.front <= e2))) {
    if(!src.empty) {
        immutable e = src.front;
        if(e1 <= e && e <= e2) {
            src.popFront();
            return true;
        }
    }
    return false;
}

unittest {
    // match character into character range.
    auto src = "az";
    assert(matchRange!('a', 'z')(src));
    assert(matchRange!('a', 'z')(src));
    assert(!matchRange!('a', 'z')(src));

    // not match character that out of character range.
    src = "AZ";
    assert(!matchRange!('a', 'z')(src));
    assert(matchRange!('A', 'Z')(src));
    assert(matchRange!('A', 'Z')(src));
    assert(!matchRange!('A', 'Z')(src));
}

/**
 *  match a character member of character set.
 *
 *  Params:
 *      set = character set.
 *      S = source range type. (input range requirements)
 *      src = a source range.
 *  Returns:
 *      true if src.front is member of character set.
 */
bool matchSet(alias set, S)(ref S src)
        if(isForwardRange!S && isInputRange!(typeof(set)) && is(ElementType!S : ElementType!(typeof(set)))) {
    if(!src.empty) {
        immutable front = src.front;
        foreach(e; set) {
            if(e == front) {
                src.popFront();
                return true;
            }
        }
    }
    return false;
}

unittest {
    // match a character that is member of character set.
    auto src = "abc";
    assert(matchSet!"ab"(src));  // a
    assert(matchSet!"ab"(src));  // b
    assert(!matchSet!"ab"(src)); // c
    assert(matchSet!"c"(src));   // c
    assert(!matchSet!"c"(src));  // (empty)
}

/**
 *  returns P can use as parser function.
 *
 *  Params:
 *      func = a tested function.
 *      S = source range type.
 */
template isParser(alias func, S)
        if(isCallable!func) {
    enum isParser = is(ReturnType!func : bool)
        && is(ParameterTypeTuple!func[0] == S)
        && (ParameterStorageClassTuple!func[0] == ParameterStorageClass.ref_);
}

/**
 *  check parser matching and restore source position.
 *
 *  Params:
 *      parser = checking parser.
 *      S = source range type.
 *      src = a source range.
 *  Returns:
 *      true if matched parser.
 */
bool testAnd(alias parser, S)(ref S src)
        if(isForwardRange!S && isParser!(parser, S)) {
    immutable before = src.save;
    immutable result = parser(src);
    src = before;
    return result;
}

unittest {
    auto src = "test";

    assert(testAnd!(matchChar!('t', typeof(src)))(src));
    assert(src.front == 't');

    assert(!testAnd!(matchChar!('e', typeof(src)))(src));
    assert(src.front == 't');

    assert(matchChar!('t')(src));
    assert(src.front == 'e');
}

/**
 *  check parser not matching and restore source position.
 *
 *  Params:
 *      parser = checking parser.
 *      S = source range type.
 *      src = a source range.
 *  Returns:
 *      true if not matched parser.
 */
bool testNot(alias parser, S)(ref S src)
        if(isForwardRange!S && isParser!(parser, S)) {
    immutable before = src.save;
    immutable result = !parser(src);
    src = before;
    return result;
}

unittest {
    auto src = "test";

    assert(!testNot!(matchChar!('t', typeof(src)))(src));
    assert(src.front == 't');

    assert(testNot!(matchChar!('e', typeof(src)))(src));
    assert(src.front == 't');

    assert(matchChar!('t')(src));
    assert(src.front == 'e');
}

/**
 *  check parser matching current position and always return true.
 *
 *  Params:
 *      parser = optional matching parser.
 *      S = source range type.
 *      src = a source range.
 *  Returns:
 *      always true.
 */
bool matchOption(alias parser, S)(ref S src)
        if(isForwardRange!S && isParser!(parser, S)) {
    parser(src);
    return true;
}

unittest {
    auto src = "test";

    assert(matchOption!(matchChar!('t', typeof(src)))(src));
    assert(src.front == 'e');

    assert(matchOption!(matchChar!('t', typeof(src)))(src));
    assert(src.front == 'e');

    assert(!matchChar!('t')(src));
    assert(src.front == 'e');
}

