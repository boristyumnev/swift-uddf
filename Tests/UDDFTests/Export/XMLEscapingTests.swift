import Foundation
import Testing
@testable import UDDF

struct XMLEscapingTests {

    // MARK: - Text Escaping

    @Test func escapeText_ampersand() {
        #expect(escapeText("a&b") == "a&amp;b")
    }

    @Test func escapeText_lessThan() {
        #expect(escapeText("a<b") == "a&lt;b")
    }

    @Test func escapeText_greaterThan() {
        #expect(escapeText("a>b") == "a&gt;b")
    }

    @Test func escapeText_allThree() {
        #expect(escapeText("<a>&b</a>") == "&lt;a&gt;&amp;b&lt;/a&gt;")
    }

    @Test func escapeText_noDoubleEscape() {
        #expect(escapeText("&amp;") == "&amp;amp;")
    }

    @Test func escapeText_quotesNotEscaped() {
        #expect(escapeText("he said \"hello\"") == "he said \"hello\"")
    }

    @Test func escapeText_plainTextUnchanged() {
        #expect(escapeText("hello world 123") == "hello world 123")
    }

    // MARK: - Attribute Escaping

    @Test func escapeAttribute_quote() {
        #expect(escapeAttribute("a\"b") == "a&quot;b")
    }

    @Test func escapeAttribute_carriageReturn() {
        #expect(escapeAttribute("a\rb") == "a&#xD;b")
    }

    @Test func escapeAttribute_lineFeed() {
        #expect(escapeAttribute("a\nb") == "a&#xA;b")
    }

    @Test func escapeAttribute_tab() {
        #expect(escapeAttribute("a\tb") == "a&#x9;b")
    }

    @Test func escapeAttribute_includesTextEscaping() {
        #expect(escapeAttribute("<&>") == "&lt;&amp;&gt;")
    }

    // MARK: - Invalid XML Characters

    @Test func escapeText_stripsNull() {
        #expect(escapeText("a\0b") == "ab")
    }

    @Test func escapeText_stripsControlChars() {
        // U+0001 through U+0008 are invalid
        let input = "a\u{01}\u{02}\u{08}b"
        #expect(escapeText(input) == "ab")
    }

    @Test func escapeText_preservesTab() {
        #expect(escapeText("a\tb") == "a\tb")
    }

    @Test func escapeText_preservesNewline() {
        #expect(escapeText("a\nb") == "a\nb")
    }

    @Test func escapeText_preservesCR() {
        #expect(escapeText("a\rb") == "a\rb")
    }

    @Test func escapeText_stripsVerticalTab() {
        #expect(escapeText("a\u{0B}b") == "ab")
    }

    @Test func escapeText_stripsFormFeed() {
        #expect(escapeText("a\u{0C}b") == "ab")
    }

    // MARK: - isValidXMLChar Boundaries

    @Test func validXMLChar_tab() { #expect(isValidXMLChar("\t")) }
    @Test func validXMLChar_lf() { #expect(isValidXMLChar("\n")) }
    @Test func validXMLChar_cr() { #expect(isValidXMLChar("\r")) }
    @Test func validXMLChar_space() { #expect(isValidXMLChar(" ")) }
    @Test func validXMLChar_letter() { #expect(isValidXMLChar("A")) }
    @Test func validXMLChar_emoji() { #expect(isValidXMLChar("😀")) }

    @Test func invalidXMLChar_null() { #expect(!isValidXMLChar("\0")) }
    @Test func invalidXMLChar_bel() { #expect(!isValidXMLChar("\u{07}")) }
    @Test func invalidXMLChar_verticalTab() { #expect(!isValidXMLChar("\u{0B}")) }
    @Test func invalidXMLChar_formFeed() { #expect(!isValidXMLChar("\u{0C}")) }
    @Test func invalidXMLChar_fffe() { #expect(!isValidXMLChar(Unicode.Scalar(0xFFFE)!)) }
    @Test func invalidXMLChar_ffff() { #expect(!isValidXMLChar(Unicode.Scalar(0xFFFF)!)) }
}
