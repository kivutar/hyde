#!/usr/bin/perl
use 5.10.0;
use IO::All;

my $blog_title = 'Kivutarのブログ';
my $blog_slogan = 'A blog about minimalism.';
my $blog_author = 'Jean-André Santoni';
my $blog_canonical = 'http://kivutar.github.com/';

sub template {
    '
<!DOCTYPE html>
<!--[if IEMobile 7 ]><html class="no-js iem7"><![endif]-->
<!--[if lt IE 9]><html class="no-js lte-ie8"><![endif]-->
<!--[if (gt IE 8)|(gt IEMobile 7)|!(IEMobile)|!(IE)]><!--><html class="no-js" lang="en"><!--<![endif]-->
<head>
    <meta charset="utf-8">
    <title>' . $blog_title . '</title>
    <meta name="author" content="' . $blog_author . '">
    <meta name="description" content="Polka is a small web-app I wrote using Dancer as an exercise in minimalism. It is inspired by werc. Polka recursively reads a directory filled with &hellip;">
    <meta name="HandheldFriendly" content="True">
    <meta name="MobileOptimized" content="320">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="canonical" href="' . $blog_canonical . '">
    <link href="/favicon.png" rel="icon">
    <link href="/stylesheets/screen.css" media="screen, projection" rel="stylesheet" type="text/css">
    <script src="/javascripts/modernizr-2.0.js"></script>
    <script src="/javascripts/ender.js"></script>
    <script src="/javascripts/octopress.js" type="text/javascript"></script>
    <link href="/atom.xml" rel="alternate" title="' . $blog_title . '" type="application/atom+xml">
    <!--Fonts from Google"s Web font directory at http://google.com/webfonts -->
    <link href="http://fonts.googleapis.com/css?family=PT+Serif:regular,italic,bold,bolditalic" rel="stylesheet" type="text/css">
    <link href="http://fonts.googleapis.com/css?family=PT+Sans:regular,italic,bold,bolditalic" rel="stylesheet" type="text/css">
</head>

<body>
    <header role="banner">
        <hgroup>
            <h1><a href="/">' . $blog_title . '</a></h1>
            <h2>' . $blog_slogan . '</h2>
        </hgroup>
    </header>

    <nav role="navigation">
        <ul class="subscription" data-subscription="rss">
            <li><a href="/atom.xml" rel="subscribe-rss" title="subscribe via RSS">RSS</a></li>
        </ul>
  
        <form action="http://google.com/search" method="get">
            <fieldset role="search">
                <input type="hidden" name="q" value="site:kivutar.github.com" />
                <input class="search" type="text" name="q" results="0" placeholder="Search"/>
            </fieldset>
        </form>
  
        <ul class="main-navigation">
            <li><a href="/">Blog</a></li>
            <li><a href="/blog/archives">Archives</a></li>
        </ul>
    </nav>

    <div id="main">
        <div id="content">
            <div class="blog-index">

                <article>
      
                    <header>
                        <h1 class="entry-title"><a href="/blog/2012/10/25/polka-ported-to-perl6/">Polka Ported to Perl6</a></h1>
                        <p class="meta">
                            <time datetime="2012-10-25T14:27:00+02:00" pubdate data-updated="true">Oct 25<span>th</span>, 2012</time>
                        </p>
                    </header>

                    <div class="entry-content">' . shift . '</div>
  
                </article>
  
            <div class="pagination">
                <a href="/blog/archives">Blog Archives</a>
            </div>
        </div>

        <aside class="sidebar">

            <section>
                <h1>Recent Posts</h1>
                <ul id="recent_posts">
                    <li class="post">
                        <a href="/blog/2012/10/25/polka-ported-to-perl6/">Polka ported to Perl6</a>
                    </li>
                </ul>
            </section>

        </aside>

    </div>
</div>

<footer role="contentinfo">
    <p>
        Copyright &copy; 2012 - ' . $name . ' -
        <span class="credit">Powered by <a href="http://octopress.org">Octopress</a></span>
    </p>
</footer>

    <script type="text/javascript">
        (function(){
            var twitterWidgets = document.createElement(\'script\');
            twitterWidgets.type = \'text/javascript\';
            twitterWidgets.async = true;
            twitterWidgets.src = \'http://platform.twitter.com/widgets.js\';
            document.getElementsByTagName(\'head\')[0].appendChild(twitterWidgets);
        })();
    </script>

</body>
</html>'
}

sub markdown {
    io('/tmp/markdown') < shift;
    scalar io('markdown /tmp/markdown |')->slurp
}

sub pygmentize {
    io('/tmp/pygmentize') < shift;
    scalar io('pygmentize -l '.shift.' -f html -O style=colorful /tmp/pygmentize |')->slurp
}

# from octopress
sub tableize {
    my ($str, $lang) = @_;
    $str =~ s/<pre>//;
    $str =~ s/<\/pre>//;
    $str =~ s/<div class="highlight">//;
    $str =~ s/<\/div>//;
    my $table = '<div class="highlight"><table><tr><td class="gutter"><pre class="line-numbers">';
    my $code = '';
    my $i;
    for (split /\n/, $str) {
        $i++;
        $table .= "<span class='line-number'>$i</span>\n";
        $code  .= "<span class='line'>$_</span>\n";
    }
    $table .= "</pre></td><td class='code'><pre><code class='$lang'>$code</code></pre></td></tr></table></div>"
}

sub figurize {
    '<figure class="code"><figcaption><span>' . shift . '</span></figcaption>' . shift . '</figure>'
}

# replace codeblocks by applying pygmentize, tablize and figurize
sub codeblocks {
    shift =~
    s[
        {% \h codeblock \h (?<title>.*?) \h lang:(?<lang>.*?) \h %}
        (?<code>.*?)
        {% \h endcodeblock \h %}
    ]{
        figurize(
            $+{title},
            tableize(
                pygmentize($+{code}, $+{lang})
            , $+{lang}
            )
        )
    }xmsegr
}

# parse header
sub header {
    shift =~ s[^---(?<header>.*?)---\n]{}xmsegr
}

say template markdown codeblocks header scalar io('-')->slurp