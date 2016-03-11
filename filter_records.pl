#!/usr/bin/env perl

use strict ;

use warnings ;

use Term::ReadKey ;
ReadMode(4) ;

use MARC::Batch ;

use MARCUtils qw( number_of_records ) ;

use File::Slurp ;

use List::Util qw(  sum ) ;

use Log::Log4perl qw(get_logger :levels);

Log::Log4perl::init('log.config') ;
my $logger = Log::Log4perl->get_logger() ;


####################
# Some setup options
##########

use Getopt::Long ;

my $pull_list = '';
my %pull_bib_ids ;

my $pull_mode = 0 ;
my $verbose = 0 ;

GetOptions (
    "pull-file=s" => \$pull_list, # string
    "verbose" => \$verbose, # more verbose than normal mode
) or die( help_message() );

if( $pull_list ne '' ) {

    $logger->info("Pull list provided") ;
    unless(-e $pull_list) {
        die "$pull_list does not exist!" ;
    }
        
    %pull_bib_ids =
        map { $_ =~ s/^\s*// ;
              $_ =~ s/\s*$// ;
              $_ => 1 }

            read_file( $pull_list,  {chomped => 1} ) ;
    $pull_mode = 1 ;
}


open my $accept_reject_record_fh, '>>', "accept_reject.csv" or die "Couldn't open accept_reject.csv" ;


# 1 - accepted automatically
my $AUTO_ACCEPTED = 1 ;
my $AUTO_DENIED   = 2 ;
my $MANUALLY_ACCEPTED = 3 ;
my $MANUALLY_DENIED = 4 ;

# 2 - denied auotmatically
# 3 - manually accepted
# 4 - manually rejected
#
# for now since we want to record this 
# to play with training this value will NOT 
# be reflected in pull list

# so rough flow
# go through a set of rules
# create a score
# if score not 0 or 100%
# summarize record & scores (perhaps have toggle for important
# fields and ask to categorize (among possible categories)
# ie
#
# essays, short stories,
# (could do some fancy binary math but for now keeping simple)


# in long run, some sort of engine would be useful

# criteria to lead to a 0
# no 500 or 505 field
# no 245 field
# leader 0607 not 'am'


# criteria of maybe?
# 500 or 505


# high likelyhood (or at least good enough) for 100%
# 655 contains 'short stories',  (do we want to deal with poems and other stuff?)
# 008 33  
# from Shawne D. Miksa, Ph.D.
# What about 008/33 Literary form = 'e' (essays) and
# 'j' (short stories) and 'p' (poems) or 'm' (mixed forms)?

# so let's just get a set to play around w/


my @marc_files = @ARGV ;

if(@marc_files == 0) {
    die "You didn't supply any files to be procssed \n " ;
}

our $total_records =
    sum(
        map
            { number_of_records( $_ ) }
            @marc_files
        ) ; 

my $batch = MARC::Batch->new( 'USMARC', @marc_files );

my $last_record_place_filepath =  'last_record_place' ;

my $last_record_place = -1 ;
if( -e $last_record_place_filepath ) {
    $last_record_place = read_file( $last_record_place_filepath ) ;
}
    

# this is pretty space-heavy
open my $auto_accepted_records_fh, '>>', 'auto_accepted.marc' or die "Couldn't open auto_accepted.marc" ;
#open my $maybe_records_h, '>>', 'maybe.marc' or die "Couldn't open maybe.marc" ;

binmode $auto_accepted_records_fh ;

# need to do a report on how many records...

my $id = -1 ;
my $record_pos = 0 ;

#while ( my $marc = $batch->next(\&marc_filter) ) {
# going to remove the filter temporarily, while we try to get a better
# system for picking records
RECORD: while ( my $marc = $batch->next() ) {

    $record_pos++ ;


    if( $verbose ) {
	print "At record entry $record_pos\n";
    }

    # need ot make sure not one off error
    if($record_pos < $last_record_place) {
	next RECORD ;
    } 


    $id = get_id( $marc ) ;
    my $percent_completed = ($record_pos / $total_records) * 100 ;
    $logger->debug(" processing $record_pos of $total_records "
                   . sprintf("%.1f%%",  $percent_completed) ) ;

    if( %pull_bib_ids && defined($pull_bib_ids{ $id } ) ) {
            $logger->info("ACCEPT Pull mode, $id was in pull list") ; 
            print $auto_accepted_records_fh $marc->as_usmarc() ;

            next RECORD ;
        }
    elsif( %pull_bib_ids ) {

        next RECORD ;            
    }

    # leader 35 to 37 has language of material
    # eng or ..
    
    # criteria to lead to a 0
    # no 500 or 505 field
    # no 245 field
    # leader 0607 not 'am'
    
    
    # criteria of maybe?
    # 500 or 505
    
    
    # high likelyhood (or at least good enough) for 100%
    # 650  or 655 contains 'short stories',  (do we want to deal with poems and other stuff?)
    # 008 33  
    # from Shawne D. Miksa, Ph.D.
    # What about 008/33 Literary form = 'e' (essays) and
    # 'j' (short stories) and 'p' (poems) or 'm' (mixed forms)?

# so let's just get a set to play around w/

    if( reject_record( $marc ) ) {
	record_accept_reject( $accept_reject_record_fh, 
			      $marc, 
			      $AUTO_DENIED ) ;

        next RECORD ;
    }
    if( automatic_accept( $marc ) ) {
        print $auto_accepted_records_fh $marc->as_usmarc() ;
	record_accept_reject( $accept_reject_record_fh,
			      $marc,
			      $AUTO_ACCEPTED ) ;
        next RECORD ;
       
    }
    # TODO: pull out to other script 
    review_record( $marc ) ;


} # END OF RECORD loop
 ;    #print "no immediate qualifiers for short stories\n" ;
#clean_up( $id ) ;
# and stories | and short stories in title probably should be automatic inclusion

sub record_accept_reject {
    my $fh = shift ;
    my $marc = shift ;
    my $status = shift ;

    print $fh $marc->field('001')->data() . ",${status}\n" ;
}


sub review_record {
    my $marc = shift ;

    print "\n\nmaybe short stories?\n" ;



   
    print $marc->title() ."\n" ;
    print $marc->author() ."\n" ;

     my @fields_notes = $marc->field('50.') ;
    foreach my $note_field (@fields_notes) {
         print $note_field->as_formatted() . "\n" ;
     }

  #650, 655
    my @fields_subjects = $marc->field('6..') ;
    foreach my $subject_field (@fields_subjects) {
        print $subject_field->as_formatted() . "\n" ;
    }
    print "(y)es/(n)o/(s)top \n" ;
    my $key ;
    my @key_options = ('y','n','s') ;

    while (not defined ($key = ReadKey(-1))) {
        # No key yet
    }
    
    if (!(grep {lc($key) eq $_} @key_options) ) {
        
        redo RECORD ;
    } elsif (lc($key) eq 'y') {
        $logger->info("ACCEPTED $id putting in file by manual input") ;
        print $auto_accepted_records_fh $marc->as_usmarc() ;
	record_accept_reject( $accept_reject_record_fh,
			      $marc,
			      $MANUALLY_ACCEPTED ) ;

    } elsif (lc($key) eq 's') {
        clean_up( $id, $record_pos ) ;
    } elsif (lc($key) eq 'n') {
        $logger->info("REJECT $id excluding by manual input") ;
	record_accept_reject( $accept_reject_record_fh,
			      $marc,
			      $MANUALLY_DENIED ) ;

    }

}


#
# Check for possible reasons to skip/reject this record
sub reject_record {
    my $marc = shift ;
    my $id = get_id( $marc ) ;
    
    if(   defined($marc->field('008')
       && length($marc->field('008')->data()) >= 37 ) ) {
        # due to weirdness...
        my $lang_code = substr($marc->field('008')->data(),35,3)  ; 
        if( $lang_code ne 'eng' && $lang_code ne ' 'x3) {
            $logger->info("REJECT $id For now only dealing with English material - language code was " . substr($marc->field('008')->data(),35,3) )  ;
            
            return 1 ;
            
        }
    }
    
    if (   !defined($marc->field('505')
                        && !defined($marc->field('500') ) ) ) {
        $logger->info( "REJECT $id no 505 or 500, skipping \n" ) ;
        return 1 ;
    }
    
    if ( !defined($marc->field('245') )  ) {
        $logger->info( "REJECT $id no 245, skipping \n" ) ;
        return 1 ;
    }
    
    if ( substr($marc->leader(),6,2) ne 'am') {
        $logger->info( "REJECT $id leader 0607 not am" ) ;
        return 1 ;
    }
    if (  defined($marc->field('008') )
                   && substr($marc->field('008')->data(),33,1) =~ /[0defhimps]/ ) {
        $logger->info("REJECT $id Spotted 008/33 w/ a specified format that is not short story") ;
        return 1 ;
    }

    # ok, so if a 505 exists,
    # does it actually have more than 3 elements?
    # that will rule out some of the "Two novels in one" works

    # (need to also check the 500s)...

    if(defined( $marc->field('505') ) || defined( $marc->field('500') ) ) {

        my $count_works = 0;

        no warnings 'uninitialized' ;
        foreach my $contents_field ( ($marc->field('505'), $marc->field('500') ) ) {

            # a lot of 505 w/ second indicator
            # 0 don't use subfield $t
            if(   $contents_field->tag() eq '505'
               && $contents_field->indicator(2) eq '0'
               &&  defined ($contents_field->subfield('t') ) )  {
                # count of title subfields
                $count_works += ( $contents_field->subfield('t') )    ;
            }
            else {
                # count of --, will deal with messier records later
                $count_works
                    += split(/--/, $contents_field->as_formatted()  ) ;
                #$logger->debug( $contents_field->as_formatted() ) ;
            }
        }
        
        if( $count_works < 3 ) {      
            $logger->info("REJECT $id table of contents too short, skipping (had $count_works) ") ;
            #$logger->debug( $marc->as_formatted() ) ;
            return 1 ;
        }
    }
    my $title = $marc->title() ;
    if($title =~ /three complete novels/i ) {
        $logger->info("REJECT $id title contains 'three complete novels' - $title" ) ;
        return 1 ;
    }
    if($title =~ /western trio/i ) {
        $logger->info("REJECT $id title contains 'western trio' - $title" ) ;
        return 1 ;
   
    }
    
    return 0 ;
}

sub automatic_accept {

    my $marc = shift ;
    my $id = $marc->field('001')->data() ;
    if (   defined($marc->field('008') )
        && substr($marc->field('008')->data(),33,1) eq 'j') {
        $logger->info("ACCEPT $id Spotted 008 w/ j, adding to file") ;
        return 1 ;
        
    }
    my @genre_headings = $marc->field('655') ;
    push( @genre_headings,
          $marc->field('650') );
    
    foreach my $genre_heading (@genre_headings) {
      
        # should be checking appropriate subfields...doing quick and dirty
        my $formatted_genre_heading = $genre_heading->as_formatted() ; 
        if ( $formatted_genre_heading=~ /stories/i
                 || $formatted_genre_heading  =~ /tales/i) {
            $logger->info("ACCEPT $id Spotted 655 or 650 w/ stories or tales") ;
            return 1 ;
        }
    }

    if( $marc->title() =~ /short stories/i ) {
        $logger->info("ACCEPT $id title contains short stories") ;
        return 1 ;
    }

    return 0 ;
}


sub clean_up {

    my $id = shift ;
    my $record_pos = shift ;

    $logger->debug("Cleaning up, passed in $id, position $record_pos") ;

    # seems a little fiddly, may need to refactor if we end up getting
    # more "modes" (maybe just have a save progress/not save progress
    if( $record_pos != $total_records && !$pull_mode ) {
        write_file( $last_record_place_filepath, $record_pos ) ;
    }
    elsif ( $record_pos == $total_records && -e $last_record_place_filepath && !$pull_mode) {
	unlink $last_record_place_filepath or die "Can't remove last_record_place_filepath";
    }
    
    close $auto_accepted_records_fh ;
    ReadMode(0) ;
    exit ;

}

sub get_id {
    my $record = shift ;
    my $raw_data = $record->field('001')->data() ;

    # probably should just trim whitespace and any special
    # characters that creep in, but I know my
    # first few datasets 001 will all be numeric

    $raw_data =~ /(\d+)/ ;
    if( $1 ) {
        return $1 ;
    }

    return $raw_data ;

}


sub help_messsage {

    my $help_message =<<"EOM";
./filter_records.pl marc_records.mrc [marc_records2.mrc, marc_records3...]

Other options

./filter_records.pl --pull-list list_of_ids.txt marc_records.mrc

If you want to pull just particular $id records (say you want to re-pull due to some encoding issues), have a file with a list of the 001 fields, one per line.

* Note, whitespaces at beginning/start of lines in the pull list will be trimmed. 

EOM
    
}

# should always clean up
END {

    
    clean_up( $id, $record_pos ) ;
}
