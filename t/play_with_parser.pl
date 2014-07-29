#!/usr/bin/env perl

use strict ;
use warnings ;

use ParseTwoFSM qw( parse ) ;
#use Marpa::XS ;

# State transition table
#
#      Current   Inputs      Next    Action
# $next{'lastname'}{'left' } = ['red',  sub { print "Red \n"} ];
# $next{'initial'}{'right'} = ['blue', sub { print "Blue\n"} ];
# $next{'red'}    {'left' } = ['blue', sub { print "Blue\n"} ];
# $next{'red'}    {'right'} = ['end',  sub { print "End \n"} ];
# $next{'blue'}   {'left' } = ['blue', sub { print "Blue\n"} ];
# $next{'blue'}   {'right'} = ['red',  sub { print "Red \n"} ];
# $next{'end'}    {'left' } = ['end',  sub { print "End \n"} ];
# $next{'end'}    {'right'} = ['end',  sub { print "End \n"} ];

# @arbitrary_inputs = qw/left left right left left right right left/;

# $state = 'initial';
# for (@arbitrary_inputs)
# {
#     $action = $next{$state}{$_}->[1];
#     $action->();
#     $state  = $next{$state}{$_}->[0];
# }

# cheating a little bit here, probably shouldn't "explode"
# but have -- as a state, but taking shortcut for now..



my $input_string =  q{Haggard, H. R. Only a dream.--Lewis, L. A. The meerschaum pipe.--Ellis, A. E. the life-buoy.--Jackson, T. G., Sir. The lady of Rosemount.--Gawsworth, J. How it happened.--Bryusov, V. In the mirror.--Burnett, J. "Calling Miss Marker."--Donovan, D. A night of horror.--Rolt, L. T. C. The shouting.--Birkin, C. The happy dancers.--Hodgson, W. H. The weed men. Cowles, F. Eyes for the blind.--Wakefield, H. R. Mr. Ash’s studio.--Haining, R. Montage of death. Allen, G. Pallinghurst Barrow.--Scott, E. Randalls round.--Visiak, E. H. The skeleton at the feast. Medusan madness.--Benson, A. C. Out of the sea. Gilchrist, R. M. Witch in-grain.--Munby, A. N. L. The Tudor chimney.--James, M. R. The experiment.}  ;

foreach my $entry (split(/--/,$input_string) ) {

    parse( $entry ) ;
}
