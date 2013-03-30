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
 *  PEG parser combinator template.
 *
 *  Params:
 *      S = source range type.(forward range requirement)
 */
template Peg(S)
        if(isForwardRange!S) {

    /// source range type.
    alias S SourceType;

    /**
     *  match any character.
     *
     *  Params:
     *      R = source range type. (input range requirement)
     *      src = a source range.
     *  Returns:
     *      return true if any character existing.
     */
    bool matchAny(ref S src) {
        if(!src.empty) {
            src.popFront();
            return true;
        } else {
            return false;
        }
    }

    unittest {
        auto src = "a";
        alias Peg!(typeof(src)) P;

        // matching one character source.
        assert(P.matchAny(src));

        // not matching empty source.
        src = "";
        assert(!P.matchAny(src));

        // multiple match for string source.
        src = "test";
        assert(P.matchAny(src));  // t
        assert(P.matchAny(src));  // e
        assert(P.matchAny(src));  // s
        assert(P.matchAny(src));  // t
        assert(!P.matchAny(src)); // end of source.
    }

    /**
     *  match a character.
     *
     *  Params:
     *      e = a matching character. 
     *  Returns:
     *      true if src.front is e.
     */
    bool matchChar(alias e)(ref S src)
            if(__traits(compiles, (src.front == e))) {
        if(!src.empty && src.front == e) {
            src.popFront();
            return true;
        } else {
            return false;
        }
    }

    unittest {
        auto src = "a";
        alias Peg!(typeof(src)) P;

        // match a same character.
        assert(P.matchChar!('a')(src));

        // not match a different character.
        src = "a";
        assert(!P.matchChar!('x')(src));

        // match string source.
        src = "abcd";
        assert(P.matchChar!('a')(src));
        assert(P.matchChar!('b')(src));
        assert(P.matchChar!('c')(src));
        assert(P.matchChar!('d')(src));
        assert(!P.matchChar!('d')(src));
    }

    /**
     *  match string.
     *
     *  Params:
     *      str = a matching string. 
     *  Returns:
     *      true if src.front is e.
     */
    bool matchString(alias str)(ref S src)
            if(isInputRange!(typeof(str)) && is(ElementType!S : ElementType!(typeof(str)))) {
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
        auto src = "a";
        alias Peg!(typeof(src)) P;

        // match a same character.
        assert(P.matchString!("a")(src));

        // not P.match a different character.
        src = "a";
        assert(!P.matchString!("x")(src));

        // P.match string source.
        src = "abcd";
        assert(P.matchString!("ab")(src));
        assert(!P.matchString!("ab")(src));

        // rest string
        assert(P.matchString!("cd")(src));
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
    bool matchEmpty(ref S src) {
        return src.empty;
    }

    unittest {
        auto src = "";
        alias Peg!(typeof(src)) P;

        // match a empty source.
        assert(P.matchEmpty(src));

        // not P.match a normal source.
        src = "test";
        assert(!P.matchEmpty(src));
    }

    /**
     *  match a character in character range.
     *
     *  Params:
     *      e1 = begin of character range.
     *      e2 = end of character range.
     *      src = a source range. (input range requirements)
     *  Returns:
     *      true if src.front into character range. (e1 <= src.front <= e2)
     */
    bool matchRange(alias e1, alias e2)(ref S src)
            if(__traits(compiles, (e1 <= src.front && src.front <= e2))) {
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
        auto src = "az";
        alias Peg!(typeof(src)) P;

        // match character into character range.
        assert(P.matchRange!('a', 'z')(src));
        assert(P.matchRange!('a', 'z')(src));
        assert(!P.matchRange!('a', 'z')(src));

        // not P.match character that out of character range.
        src = "AZ";
        assert(!P.matchRange!('a', 'z')(src));
        assert(P.matchRange!('A', 'Z')(src));
        assert(P.matchRange!('A', 'Z')(src));
        assert(!P.matchRange!('A', 'Z')(src));
    }

    /**
     *  match a character member of character set.
     *
     *  Params:
     *      set = character set.
     *      src = a source range.
     *  Returns:
     *      true if src.front is member of character set.
     */
    bool matchSet(alias set)(ref S src)
            if(isInputRange!(typeof(set)) && is(ElementType!S : ElementType!(typeof(set)))) {
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
        auto src = "abc";
        alias Peg!(typeof(src)) P;

        // match a character that is member of character set.
        assert(P.matchSet!"ab"(src));  // a
        assert(P.matchSet!"ab"(src));  // b
        assert(!P.matchSet!"ab"(src)); // c
        assert(P.matchSet!"c"(src));   // c
        assert(!P.matchSet!"c"(src));  // (empty)
    }

    /**
     *  check parser matching and restore source position.
     *
     *  Params:
     *      parser = checking parser.
     *      src = a source range.
     *  Returns:
     *      true if matched parser.
     */
    bool testAnd(alias parser)(ref S src) {
        immutable before = src.save;
        immutable result = parser(src);
        src = before;
        return result;
    }

    unittest {
        auto src = "test";
        alias Peg!(typeof(src)) P;
        alias P.matchChar!'t' parser;

        assert(P.testAnd!parser(src));
        assert(src.front == 't');

        assert(!P.testAnd!(P.matchChar!'e')(src));
        assert(src.front == 't');

        assert(parser(src));
        assert(src.front == 'e');
    }

    /**
     *  check parser not matching and restore source position.
     *
     *  Params:
     *      parser = checking parser.
     *      src = a source range.
     *  Returns:
     *      true if not matched parser.
     */
    bool testNot(alias parser)(ref S src) {
        immutable before = src.save;
        immutable result = !parser(src);
        src = before;
        return result;
    }

    unittest {
        auto src = "test";
        alias Peg!(typeof(src)) P;

        assert(!P.testNot!(P.matchChar!('t'))(src));
        assert(src.front == 't');

        assert(P.testNot!(P.matchChar!('e'))(src));
        assert(src.front == 't');

        assert(P.matchChar!('t')(src));
        assert(src.front == 'e');
    }

    /**
     *  check parser matching current position and always return true.
     *
     *  Params:
     *      parser = optional matching parser.
     *      src = a source range.
     *  Returns:
     *      always true.
     */
    bool matchOption(alias parser)(ref S src) {
        parser(src);
        return true;
    }

    unittest {
        auto src = "test";
        alias Peg!(typeof(src)) P;
        alias P.matchChar!'t' parser;

        assert(P.matchOption!parser(src));
        assert(src.front == 'e');

        assert(P.matchOption!parser(src));
        assert(src.front == 'e');

        assert(!parser(src));
        assert(src.front == 'e');
    }

    /**
     *  check parser matching current position more than 0 times and always return true.
     *
     *  Params:
     *      parser = matching parser.
     *      src = a source range.
     *  Returns:
     *      always true.
     */
    bool matchRepeat0(alias parser)(ref S src) {
        while(parser(src)) {
            // do nothing.
        }
        return true;
    }

    unittest {
        auto src = "test";
        alias Peg!(typeof(src)) P;
        alias P.matchChar!'t' parser;

        assert(P.matchRepeat0!parser(src));
        assert(src.front == 'e');

        assert(P.matchRepeat0!parser(src));
        assert(src.front == 'e');

        assert(!parser(src));
        assert(src.front == 'e');

        src = "ttttest";

        assert(P.matchRepeat0!parser(src));
        assert(src.front == 'e');

        assert(P.matchRepeat0!parser(src));
        assert(src.front == 'e');
    }

    /**
     *  check parser matching current position more than 1 times and return matching result.
     *
     *  Params:
     *      parser = matching parser.
     *      src = a source range.
     *  Returns:
     *      true if matched parser more than 1 times.
     */
    bool matchRepeat1(alias parser)(ref S src) {
        bool result = false;
        while(parser(src)) {
            result = true;
        }
        return result;
    }

    unittest {
        auto src = "test";
        alias Peg!(typeof(src)) P;
        alias P.matchChar!'t' parser;

        assert(P.matchRepeat1!parser(src));
        assert(src.front == 'e');

        assert(!P.matchRepeat1!parser(src));
        assert(src.front == 'e');

        assert(!parser(src));
        assert(src.front == 'e');

        src = "ttttest";

        assert(P.matchRepeat1!parser(src));
        assert(src.front == 'e');

        assert(!P.matchRepeat1!parser(src));
        assert(src.front == 'e');
    }

    /**
     *  match parser sequence.
     *
     *  Params:
     *      parsers = parser sequence.
     *      src = a source range.
     *  Returns:
     *      true if mathed all parsers.
     */
    bool matchSequence(parsers...)(ref S src) {
        immutable before = src.save;
        foreach(p; parsers) {
            if(!p(src)) {
                src = before;
                return false;
            }
        }
        return true;
    }

    unittest {
        auto src = "test";
        alias Peg!(typeof(src)) P;
        alias P.matchChar!'t' ch_t;
        alias P.matchChar!'e' ch_e;
        alias P.matchChar!'s' ch_s;

        assert(P.matchSequence!(ch_t, ch_e)(src));
        assert(src.front == 's');

        assert(!P.matchSequence!(ch_s, ch_e)(src));
        assert(src.front == 's');

        assert(P.matchSequence!(ch_s, ch_t)(src));
        assert(src.empty);
    }

    /**
     *  choice parser.
     *
     *  Params:
     *      parsers = parsers for choosing.
     *      src = a source range.
     *  Returns:
     *      true if mathed a one of parsers.
     */
    bool matchChoice(parsers...)(ref S src) {
        foreach(p; parsers) {
            if(p(src)) {
                return true;
            }
        }
        return false;
    }

    unittest {
        auto src = "test";
        alias Peg!(typeof(src)) P;
        alias P.matchChar!'t' ch_t;
        alias P.matchChar!'e' ch_e;
        alias P.matchChar!'s' ch_s;

        assert(P.matchChoice!(ch_t, ch_e)(src));
        assert(src.front == 'e');

        assert(P.matchChoice!(ch_t, ch_e)(src));
        assert(src.front == 's');

        assert(!P.matchChoice!(ch_t, ch_e)(src));
        assert(src.front == 's');
    }

} // end of template Peg(S)

unittest {
    // for running unittest
    mixin Peg!(string);
}

// test for recursive calling.
version(unittest) {

    mixin Peg!string;

    // parse 't' parser / $
    bool parser(ref string src) {
        return matchChoice!(matchSequence!(matchChar!'t', parser), matchEmpty)(src);
    }

    unittest {
        auto src = "tttt";
        assert(parser(src));

        src = "ttte";
        assert(!parser(src));
    }
}

