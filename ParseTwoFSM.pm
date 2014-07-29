#!/usr/bin/env perl

package ParseTwoFSM ;


use strict ;
use warnings ;


use Exporter;


# base class of this(Arithmetic) module
our @ISA = qw(Exporter);

# Exporting the add and subtract routine
our @EXPORT_OK = qw( parse );


# weird mental note, wonder if easier to parse if reversed string?


# weirdness happening w/ use strict & the constants...
# for now will try to fix some other stuff and come back
# BEGIN {
#     # special characters
#     use constant {
#         # Inputs
#         PERIOD => '.',
#         COMMA  => ',',
#         OTHER  => 2,
        
#         #States
#         LAST => 1,
#         INITIALS => 2,
#         TITLE => 3,
#     } ;
# }



#use Marpa::XS ;

# Our finite state machine needs to work like this....
# keep parsing till hits a comma, these go into "last name"
#                                 new state Initials

# Initials
#      if see more than one non-period, move into "title" state
#      if see a comma, go into "author address" state
#      Otherwise keep adding to initials

# Author address
#     Add till you see period, on exit write out to address
#                              switch to title

# title
#    go till hit period, then add to title array


    # looked at a couple of the
    # modules and they all seemed overkill
    # also, hashing technique seemed a bit of a pain

    # at some point clean this up with a fsa of some type,
    # particularly as the rules get more complicated, but for now just want something that works...

# see init() routine
my ($state, $last_name, $initials, $person_title, @titles, $buffer );

# feels rough, better way to default actions? Also,
# should I somehow catch uninitialized errors
# and have that -> just skip parsing the segement? (throw warnining/error/excpetion type object in eval... 

###
# LAST state actions
#
# Essentially, add to buffer till a comma  or period is seen, then save that to 
# LAST name
# 
my %actions = () ;
$actions{ LAST }{ COMMA }
    = sub { $last_name = $buffer;
            $buffer = '' ;
            $state = 'INITIALS' ;
        } ;

# not sure how we want to treat periods here, seems then just last name?
$actions{ LAST }{ PERIOD } = $actions{ LAST }{ COMMA } ;

$actions{ LAST }{ OTHER }
    = sub { my $char = shift ;
            $buffer .=  $char ;
        } ;

$actions{ LAST }{ OTHER }
    = sub { my $char = shift ;
            $buffer .=  $char ;
        } ;

###
# INITIALS state actions

$actions{ INITIALS }{ PERIOD } 
    = sub {
        my $char = shift ;
        $buffer .= $char ;
    }; 


$actions{ INITIALS }{ COMMA }
    = sub {
        #$initials .= $buffer ;
        $buffer = '' ;
        $state = 'PERSON_TITLE' ;
    } ;

$actions{ INITIALS }{ OTHER }
    = sub {

        my $char = shift ;

        # doing a look up of the character before
        # and if not space or period


        # is the last character a . or space? (In which case,
        # this is likely the first character in an initial, so keep going
        #
        # however, if it's not, we're already two characters into title
        #
        # might be more efficient to do
        #   length($buffer) > 1 
        #   && ( grep {substr( $buffer,-1,1)} (q{.}, q{ } ) )  ){

        # need to test if no initials, suspect need to make it more complicated

        # if( $buffer =~ /^([^\.]\.s?*.?\s$/) {
        # regex approach was getting funky and weird
        
        if( length($buffer) == 0 ) {
            $buffer .= $char ;
        }
        elsif(   substr($buffer, -1, 1 ) eq q{ }
                 || substr($buffer, -1, 1 ) eq q{.} ) {

            # ok, the string already in buffer is initials,
            # but the character now MIGHT be a title,
            $initials .= $buffer ;
            # note, we are purposefully NOT appending here, this
            # might be the start of the title
            $buffer = $char;

            $state = 'INITIALS' ;
        }
        else {

            # the previous character was not a space OR a period
            # and we'r taking care of commas already, so
            # this means we're likely in a title, add to buffer, switch to title

            $buffer .= $char ;
            $state = 'TITLE' ;
        }
    } ;


$actions{ PERSON_TITLE }{ COMMA }
    = sub {
        # should throw an error
        $state = 'RUNTOEND' ;
    } ;

$actions{ PERSON_TITLE }{ PERIOD }
    = sub {
        $person_title = $buffer ;
        $buffer = q{} ;
        $state = 'TITLE' ;
    } ;

$actions{ PERSON_TITLE }{ OTHER }
    = sub {
        my $char = shift ;
        $buffer .= $char ;

    } ;

$actions{ RUNTOEND }{ COMMA } = sub {

} ;
$actions{ RUNTOEND }{ PERIOD } = sub {

} ;
$actions{ RUNTOEND }{ OTHER } = sub {

} ;



$actions{ TITLE }{ PERIOD }
    = sub {
        push(@titles,
             $buffer ) ;

        $buffer = q{} ;
    } ;



$actions{ TITLE }{ OTHER }
    = sub {
        my $char = shift ;
        $buffer .= $char ;
    } ;



$actions{ TITLE }{ COMMA }
    = sub {
        my $char = shift ;
        $buffer .= $char ;
    } ;

sub parse {

    init() ;
    
    my $string = shift ;

    my $char = '' ;
    my $rest_of_string = $string ;
    
    while ( length($rest_of_string) > 0 ) {
        
        ($char, $rest_of_string)  = _read_char( $rest_of_string ) ; 

        print "Char is $char \n" ;
        if (   $char eq q{.} ) {
            $actions{ $state }{ PERIOD }->( $char ) ;
        }
        elsif( $char eq q{,} ) {
            $actions{ $state }{ COMMA }->( $char ) ;
        } else {
            $actions{ $state }{ OTHER }->( $char ) ;
        }
    }
    print "LAST NAME: " . $last_name . "\n" ;
    print "INITIALS: " . $initials . "\n" ;
    print "TITLE/SALUTATION: " . $person_title . "\n" ;
    print "TITLES: " . join(", ", @titles )  . "\n" ;
    
    my $name = join(q{ }, $person_title,
                    $initials,
                    $last_name ) ;
    
    my @works = map { { responsible => [$name], title => $_ } } @titles ; 
    return @works ;
}



sub _read_char {

    my $string = shift ;

    my $char = substr( $string, 0 , 1 ) ;
    my $remainder = '' ;
        
    if( length($string) > 1 ) {
        $remainder = substr( $string,1 ) ;
    }


    return ($char, $remainder ) ;

}

sub init {

    $state = 'LAST' ;
    $last_name = '' ;
    $initials = '' ;
    $person_title = '';

    @titles = () ;

    $buffer = '' ;
}
1;
