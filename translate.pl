#!/usr/bin/perl6

# TODO: one line remaining from pygment output: remoooooove YA! 
# TODO: code cleaning
# TODO: tree building
# TODO: bailador as renderer
# TODO: tons of things (Kivutar said :) )
# TODO: hack again on perl6: so much fun with kivutar ;)

use v6;
use Template6;

my $template = Template6.new;
$template.add-path: 'templates'; 

sub template ( $content ) {
    $template.process( 'layout'
    , :content($content)
    , :blog_title('Kivutarのブログ')
    , :blog_slogan('A blog about minimalism.')
    , :blog_author('Jean-André Santoni')
    , :blog_canonical('http://kivutar.github.com/') ) or die $template.error;
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
    $str ~~ s/'<pre>' \s* \n*//;
    $str ~~ s/'</pre>' \s* \n* //;
    $str ~~ s/'<div class="highlight">' \s* \n* //;
    $str ~~ s/'</div>' \s* \n* //;
    $str ~~ s/\n\n/\n/;
    my $table = '<div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers">';
    my $code = '';
    my $i;
    for (split /\n/, $str) {
        $i++;
        $table ~= "<span class='line-number'>"~$i~"</span>\n";
        $code ~= "<span class='line'>"~$_~"</span>\n";
    }
    $table ~ "</pre></td><td class='code'><pre><code class='"~$lang~"'>"~$code~"</code></pre></td></tr></table></div>"
}

sub misenformize ($match) {
    my ($code, $lang, $title ) = $match< code lang title >;
    figurize( $title, tableize( pygmentize($code, $lang ), $lang ));
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
    ] = misenformize $/;
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
