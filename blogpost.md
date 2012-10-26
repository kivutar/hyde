---
layout: post
title: "Polka ported to Perl6"
date: 2012-10-25 14:27
comments: true
categories: [Perl, Web]
---

Polka is a small web-app I wrote using Dancer as an exercise in minimalism. It is inspired by [werc](http://werc.cat-v.org).
Polka recursively reads a directory filled with markdown files, convert and serve them using HTTP, with a nice design and a navigation menu.

My friend Marc asked me to port it to Rakudo Perl6.

It took me a while to figure out all the new tricks, as it is my first Perl6 script. The code may not be perfect for this reason (and I am open to code reviews) but it gave me a first feeling of the so long awaited language.

I'm trying to give a feedback by comparing small blocs of code in the 2 idioms.

##First, the dependencies.

Polka depends on Dancer (a web framework) and Text::MarkDown (markdown to html converter).

{% codeblock Perl5 lang:perl %}
#!/usr/bin/perl
use Dancer;
use Text::Markdown 'markdown';
use utf8;
{% endcodeblock %}

Rakudo Star bundles a clone of Dancer called Bailador. It is far from complete, but ok for our case.

No need to specify _use utf8_, Perl6 allows utf8 source code by default.

_Text::Markdown_ in Perl6 is not complete either: I found it on Karl Masak github, it makes use of Perl6 Grammars to parse Markdown, but no HTML converter was done. Althrough it may be easy to code, the grammar itself is incomplete. Please contribute to _Text::Markdown_ if you have some free time left.

{% codeblock Perl6 lang:perl %}
#!/usr/bin/perl6
use Bailador;
use Text::Markdown;
{% endcodeblock %}

## My first good surprise

Perl6 has a builting _slurp_ function (slurp means reading a file in a single time), so the following line vanished:

{% codeblock Perl5 lang:perl %}
sub slurp { local $/; open(my $fh, '<:utf8', shift); <$fh> }
{% endcodeblock %}

## Yet another goodie

In Polka, this recursive function walk through subdirectories and build a hash that I use later to generate the menu HTML markup.

{% codeblock Perl5 lang:perl %}
sub dirtree {
    my $dir = shift;
    my %tree;

    opendir(DIR, $dir);
    my @files = grep {!/^\.\.?$/} readdir(DIR);
    closedir(DIR);

    $tree{"$dir/$_"} = -d "$dir/$_" ? dirtree("$dir/$_") : '' for @files;

    \%tree;
}
{% endcodeblock %}

Thanks to Perl6, you don't need to open and close directories no more. There is a _dir()_ function that does this for you. This function also filters the current "." and parent ".." directories. The resulting code is a lot prettier.

{% codeblock Perl6 lang:perl %}
sub dirtree($dir) {
    my %tree;
    %tree{"$dir/$_"} = .IO.d ?? dirtree("$dir/$_") !! '' for dir($dir);
    %tree
}
{% endcodeblock %}

Comments:

* New function signatures
* _?? and !!_ is the new ternary operator wich replaces _? and :_
* _.IO.d_ means _$_.IO.d_
* No need to escape the hash, Perl6 passes references to structures

## The _menu_ sub

This recursive sub takes the preceding hash as argument and build a classic know _ul > li_ menu.

{% codeblock Perl5 lang:perl %}
sub menu {
    my ($tree, $path, $unfolded) = @_;
    my $menu = $unfolded ? "<ul class=\"active\">\n" : "<ul>\n";
    while ( my ($link, $child) = each %$tree ) {
        $link =~ s/^data\///;
        my $label = pop @{[ split '/', $link ]};
        if ( $child ) {
            $menu .= "<li class=\"dir\">$label\n".menu($child, $path, $path =~ /$link/)."</li>\n";
        } else {
            my $class = $link eq $path ? ' class="active"' : '';
            $menu .= "<li$class><a href=\"/$link\">$label</a></li>\n";
        }
    }
    $menu .= "</ul>\n";
}
{% endcodeblock %}

Now the Perl6 code:

{% codeblock Perl6 lang:perl %}
sub menu (%tree, $path = '', $unfolded = False) {
    my $menu = $unfolded ?? "<ul class=\"active\">\n" !! "<ul>\n";
    for ( %tree.kv ) -> $link is copy, $child {
        $link ~~ s/^data\///;
        my $label = $link.split('/').pop;
        if $child {
            $menu ~= "<li class=\"dir\">$label\n" ~ menu($child, $path, $path ~~ /$link/) ~ "</li>\n";
        } else {
            my $class = $link eq $path ?? ' class="active"' !! '';
            $menu ~= "<li$class><a href=\"/$link\"> $label </a></li>\n";
        }
    }
    $menu ~= "</ul>\n";
}
{% endcodeblock %}

Let's look at it in details.

{% codeblock Perl6 lang:perl %}
sub menu (%tree, $path = '', $unfolded = False) {
{% endcodeblock %}

The new function signature forced me to specify a default value for my optionnal argument _$unfolded_.

_%tree_ is not casted to an array here and behave more like an hashref.

*****

Next chunk. One of the ways to loop over keys and values of a hash.

{% codeblock Perl6 lang:perl %}
for ( %tree.kv ) -> $link is copy, $child {
{% endcodeblock %}

I first tried something like this:

{% codeblock Perl6 lang:perl %}
for ( %tree.pairs ) { say .key; say .value; }
{% endcodeblock %}

But _.key_ and _.value_ cannot be interpolated in regexes, so I has to rename them. The _.kv_ method does the trick here. It flattens the hash, and give as much elements as we ask for each loop. In this case 2.

The _is copy_ thing took me a while to understand. It looks like Perl6 _for_ creates read only variables. We have to tell the interpreter that we want copies instead. I don't know the reasons. But for now I dislike this thing...

*****

Another interesing thing is this:

{% codeblock Perl5 lang:perl %}
my $label = pop @{[ split '/', $link ]};
{% endcodeblock %}

In this code, I embeds the result of split (wish is a list) in an arrayref, to cast it to an array so pop can pop it. I always hated this in Perl5.
I was happy to find that Perl6 is smarter than is predecessor in this case, I was able to rewrite it like the following:

{% codeblock Perl6 lang:perl %}
my $label = $pop split '/', $link;
{% endcodeblock %}

And finally in a more idiomatic way:

{% codeblock Perl6 lang:perl %}
my $label = $link.split('/').pop;
{% endcodeblock %}

## The web framework callback

This callback captures the entire path after / in the url.

{% codeblock Perl5 lang:perl %}
get qr{/(?<path>.*)} => sub {
    captures->{path} ||= 'Home';
    "<html>
        <head>
            <link href=\"/style.css\" rel=\"stylesheet\" type=\"text/css\" />
        </head>
        <body>
            <div>
                <h1><a href=\"/\"><span id=\"main-title\">Polka~</a></h1>
                <nav>" . menu( $dirtree, captures->{path} ) . "</nav>
                <div id=\"page\">" . markdown( slurp 'data/'.captures->{path} ) . "</div>
            </div>
            <footer>Powered by <a href=\"#\">Polka</a>.</footer>
        </body>
    </html>";
};

dance;
{% endcodeblock %}

And here is the new code in Perl6 using Bailador :

{% codeblock Perl6 lang:perl %}
get '/(.*)' => sub ($path is copy) {
    $path = "$path" || "Home";
    "<html>
        <head>
        <link href=\"/style.css\" rel=\"stylesheet\" type=\"text/css\" />
        </head>
        <body>
            <div>
                <h1><a href=\"/\"><span id=\"main-title\">Polka~</a></h1>
                <nav>" ~ menu( %dirtree, $path ) ~ "</nav>
                <div id=\"page\">" ~ slurp( "data/$path" ) ~ "</div>
            </div>
            <footer>Powered by <a href=\"#\">Polka</a>.</footer>
        </body>
    </html>";
}

baile;
{% endcodeblock %}

Most of this code is not interesting, however, translating the following line gave me a headacke:

{% codeblock Perl5 lang:perl %}
captures->{path} ||= 'Home';
{% endcodeblock %}

First, I had to understand that the _$path_ created by Bailador is read only. The _is copy_ fixed this first issue.

I thought that the following would work,

{% codeblock Perl6 lang:perl %}
$path ||= 'Home';
{% endcodeblock %}

but it did not, because an empty _$path_ was evaluated to _True_!

To understand why, I had to debug like this:

{% codeblock Perl6 lang:perl %}
$path.perl.say;
{% endcodeblock %}

wich is the new way to dump.

This gave me the reply. _$path_ was an instance of the _Match()_ class wich evaluates to _True_ if the regex matches, wich is always the case, either way we would never have entered the callback.

The fix was to cast _$path_ to a string. An empty string evaluates as _False_ and that allowed me to test it and replace it if empty.

## Conclusions on the resulting Perl6 app

* The code is smaller.
* It is prettier in most cases.
* Perl6 is fast enought to power webapps.
* The error messages are more precise with a nice stacktrace, except when the interpretor gets _confused_.
* Perl6 still lacks mainstream libs.
* Too much types and classes makes the language tricky. This is my opinion.