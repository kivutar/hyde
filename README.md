I'm trying to mimic jekyll

    ./translate.pl < blogpost.md > blogpost.html
    ./serve.pl

TODO:

1 header:
  1 separate header from body
  2 pass yaml parsed header to template processing
2 write tests for .ize functions
3 select tremplate from header
4 traverse the whole source to generate complete site
  1 generate the path for a date
  2 use rsync for static files ?
5 push everything in modules
6 bailador as localhost renderer 
7 bailador as any renderer
