#!/usr/bin/perl6

use v6;
use Template6;

my %config = ( title => 'Kivutarのブログ'
    , slogan => 'A blog about minimalism.'
    , author => 'Jean-André Santoni'
    , canonical => 'http://kivutar.github.com/'
    , simple_search => 'http://google.com/search'
    , description => ''
    );

my $template = Template6.new;
$template.add-path: 'templates'; 

sub template ( $content ) {
    $template.process( 'layout'
    , :content($content)
    , :config(%config) ) or die $template.error;
}

sub markdown ($content) {
    my $temp = '/tmp/markdownize-me.md';
    spurt $temp, $content, :createonly(False);
    open("pandoc $temp", :p ).slurp
}

sub pygmentize ( $code, $lang ) {
    my $temp = '/tmp/pygmentize-me.md';
    spurt $temp, $code, :createonly(False);
    open("pygmentize -l $lang -f html $temp", :p ).slurp
}

sub figurize ($title, $code) {
    qq[<figure class="code"><figcaption><span>{$title}</span></figcaption>{$code}</figure>]
}

sub tableize ($str is copy , $lang) {
    $str ~~ s/ \n? '<pre>' \n? //;
    $str ~~ s/ \n? '</pre>' \n? //;
    $str ~~ s/ \n? '<div class="highlight">' \n? //;
    $str ~~ s/ \n? '</div>' \n? //;
    my $table = '<div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers">';
    my $code = '';
    my $i;
    for split /\n/, $str {
        $i++;
        $table ~= "<span class='line-number'>" ~ $i ~ "</span>\n";
        $code  ~= "<span class='line'>" ~ $_ ~ "</span>\n";
    }
    $table ~ "</pre></td><td class='code'><pre><code class='" ~ $lang ~ "'>" ~ $code ~ "</code></pre></td></tr></table></div>"
}

sub codeblocks ( $content is copy ) {
    $content ~~ s:g[ 
        '{%' \h+ 'codeblock'
             \h+ $<title>=(\N+?)
             \h+
             'lang:' $<lang>=(.*?)
             \h+
        '%}'
        $<code>=(.*?)
        '{%' \h+ 'endcodeblock' \h+ '%}'
    ] = figurize( $/<title>, tableize( pygmentize($/<code>, $/<lang> ), $/<lang> ));
    $content;
}

my $header;

sub header( $content is copy ) {
    $content ~~ s/
        ^^
        '---'\n
        (.*?) {$header = $0}
        \n'---'\n
    //;
    $content;
}

say template markdown codeblocks header $*IN.slurp;