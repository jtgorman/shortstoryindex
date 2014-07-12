#!/usr/bin/env perl

use strict ;

use warnings ;

use Term::ReadKey ;
ReadMode(4) ;

use MARC::Batch ;

use File::Slurp ;

use Log::Log4perl qw(get_logger :levels);

Log::Log4perl::init('log.config') ;
my $logger = Log::Log4perl->get_logger() ;


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

my $batch = MARC::Batch->new( 'USMARC', @ARGV );

my $last_record_id_filepath = 'last_record_id' ;

my $last_record_id = -1 ;
if( -e $last_record_id_filepath ) {
    $last_record_id = read_file( $last_record_id_filepath ) ;
}
    

open my $short_story_records_h, '>>', 'short_story_records.marc' or die "Couldn't open short_story_records.marc" ;

binmode $short_story_records_h ;

# need to do a report on how many records...

my $id = -1 ;
#while ( my $marc = $batch->next(\&marc_filter) ) {
# going to remove the filter temporarily, while we try to get a better
# system for picking records
RECORD: while ( my $marc = $batch->next() ) {

    $id = get_id( $marc ) ;

    # leader 35 to 37 has language of material
    # eng or ..
    
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

    if( reject_record( $marc ) ) {
        next RECORD ;
    }
    if( automatic_accept( $marc ) ) {
        print $short_story_records_h $marc->as_usmarc() ;
        next RECORD ;
       
    }
    print "maybe short stories?\n" ;
    print $marc->title() ."\n" ;
    print $marc->author() ."\n" ;
    my @fields_500s = $marc->field('50.') ;
    foreach my $field (@fields_500s) {
        print $field->as_formatted() . "\n" ;
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
        print $short_story_records_h $marc->as_usmarc() ;
    } elsif (lc($key) eq 's') {
        clean_up( $id ) ;
    } elsif (lc($key) eq 'n') {
        $logger->info("REJECT $id excluding by manual input") ;
    }
} # END OF RECORD loop
    #print "no immediate qualifiers for short stories\n" ;
clean_up( $id ) ;

#
# Check for possible reasons to skip/reject this record
sub reject_record {
    my $marc = shift ;
    my $id = get_id( $marc ) ;
    

    # For this particular batch that's
    # already in order (LoC from Scriblio)
    # probably could have database of lookups
    # in memory for an unordered set
    if(  $id < $last_record_id ) {
        
        return 1 ;
    }
          if(    defined($marc->field('008')
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
        $logger->info( "$id no 505 or 500, skipping \n" ) ;
        return 1 ;
    }
    
    if ( !defined($marc->field('245') )  ) {
        $logger->info( "REJECT $id no 245, skipping \n" ) ;
        return 1 ;
    }
    
    if ( substr($marc->leader(),6,2) ne 'am') {
        $logger->info( "$id leader 0607 not am" ) ;
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
                $count_works += scalar(@{ $contents_field->subfield('t') } )  ;
            }
            else {
                # count of --, will deal with messier records later
                $count_works
                    += split(/--/, $contents_field->as_formatted()  ) ;
                $logger->debug( $contents_field->as_formatted() ) ;
            }
        }
        
        if( $count_works < 3 ) {      
            $logger->info("REJECT $id table of contents too short, skipping (had $count_works) ") ;
            #$logger->debug( $marc->as_formatted() ) ;
        return 1 ;
        }
    }
    return 0 ;
}

sub automatic_accept {

    my $marc = shift ;
    my $id = $marc->field('001')->data() ;
    if (   defined($marc->field('008') )
        && substr($marc->field('008')->data(),33,1) eq 'j') {
        $logger->info("$id Spotted 008 w/ j, adding to file") ;
        return 1 ;
        
    }
    my @genre_headings = $marc->field('655') ;
    foreach my $genre_heading (@genre_headings) {
      
        # should be checking appropriate subfields...doing quick and dirty
        my $formatted_genre_heading = $genre_heading->as_formatted() ; 
        if ( $formatted_genre_heading=~ /short stories/i
                 || $formatted_genre_heading  =~ /short story/i) {
            $logger->info("ACCEPT $id Spotted 655 w/ short stor(y|ies)") ;
            return 1 ;
        }
    }

    return 0 ;
}


sub clean_up {

    my $id = shift ;
    $logger->debug("Cleaning up, passed in $id") ;
    
    if( defined($id) ) {
        write_file( $last_record_id_filepath, $id ) ;
    }
    
    close $short_story_records_h ;
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

# should always clean up
END {

    clean_up() ;
}
    
