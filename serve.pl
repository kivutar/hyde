#!/usr/bin/perl
use Dancer;
use IO::All;

get '/' => sub {
    io('blogpost.html')->slurp;
};

dance;
