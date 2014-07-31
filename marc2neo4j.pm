#!/usr/bin/env perl

use strict ;
use warnings ;

package marc2neo4j ;

# ok, so this is just to try out the
# new switch statement, see
# parse_strings_content if we
# need to refactor out due to complaints

use File::Slurp ;

use ParseTwoFSM qw( parse ) ;

use Log::Log4perl qw(get_logger :levels);

Log::Log4perl::init('log.config') ;
my $logger = Log::Log4perl->get_logger() ;

# pretty much taken from the Log4perl FAQ
$SIG{__WARN__} = sub {
    local $Log::Log4perl::caller_depth =
        $Log::Log4perl::caller_depth + 1;
    $logger->warn(  @_ );
};

$SIG{__DIE__} = sub {
    if($^S) {
        # We're in an eval {} and don't want log
        # this message but catch it later
        return;
    }
    $Log::Log4perl::caller_depth++;
    $logger->logdie( @_ ) ;
    
};



use MARCUtils qw( get_bib_id number_of_records) ;





# need to create a template...


# but basically want to
# * get the 245 a & b -> title (and maybe some sort of id?)
# then create author / short story title from 505 (throw out if no 505)
# parse the different common patterns for such
# then do queries
#
# can make more complicated later

use MARC::Batch ;
use MARC::Record ;

use List::Util qw(  sum ) ;

use REST::Neo4p;

use Getopt::Long ;

setup_neo4j() ;


my $fetch_work_q =<<"EOQ";
MATCH (node:work)
WHERE node.title = { value }
RETURN node ;
EOQ

my $fetch_responsible_q =<<"EOQ";
MATCH (node:responsbile)
WHERE node.name = { value }
RETURN node ;
EOQ
    
my $check_book_already_added_q =<<"EOQ" ;
MATCH (book { loc_bib_id:  {bib_id} } ) 
WITH count(*) as count
RETURN count
EOQ
    
my %query_cache = (
    book_exists => REST::Neo4p::Query->new( $check_book_already_added_q ),
    work => REST::Neo4p::Query->new( $fetch_work_q ),
    responsible => REST::Neo4p::Query->new( $fetch_responsible_q ),
) ;

my %type_lookup_key = (
    work => 'title' ,
    responsible => 'name',
) ;


__PACKAGE__->run( @ARGV ) unless caller();

sub run {
    ####################
    # Setup
    ##########
    $logger->info( "starting setup process" ) ;
    
    my $skip_file = '';
    
    GetOptions ("skip-list=s" => \$skip_file ) ;
    
    my %skip_records = () ;
    if($skip_file ne '') {
        
        $logger->debug( "pulling in ids from $skip_file" ) ;
        %skip_records = get_skip_list( $skip_file ) ;
        
        
}
    
    

    $logger->info("Starting import of files " . join(',',@ARGV) ) ;

    # look more into batch mode later...
    
    my $batch = MARC::Batch->new( 'USMARC', @ARGV );
    my $count = 1 ;
    my $total_count
        = sum( map { number_of_records( $_ ) } @ARGV ) ;        
    
    $logger->info("finished setup") ;


    
    ##########
    # End of Setup
    ####################
    
    #while ( my $marc = $batch->next(\&marc_filter) ) {
    # going to remove the filter temporarily, while we try to get a better
    # system for picking records

    $batch->strict_off() ;
    
    
    # bad, I know
  RECORD: while ( my $marc = $batch->next() ) {
        
        my $warnings = $batch->warnings() ;
        if( defined($warnings) && $warnings > 0 ) {
            $logger->warn( "SKIPPING record due to error in MARC " . $batch->warnings() ) ;
            next RECORD ;
        }
        
        
        my $id = get_bib_id( $marc ) ;
        $logger->debug("importing " . $id ) ;
        
        if( $skip_records{ $id } ) {
            $logger->info("SKIP $id in skip list") ;
            next RECORD ;
        }
        
        my $title = $marc->title() ;
        my @note_fields = $marc->field('505') ;
        push(@note_fields,
             $marc->field('500') ) ;
        
        my @contents = () ;
        
        my $pecentage = sprintf("%.1f",$count / $total_count * 100 ) ;
        $logger->debug( "At record $count of $total_count ( $pecentage% )" )  ;
        
        $count++ ;
        $logger->debug("title: " . $marc->title() ) ;
        $logger->debug(  "TOCs: "
                             . join(map
                                        { $_->as_formatted() }
                                            @note_fields ) );
    
        
        # for now, decided to skip if book id already present
        # might want option overwrite/update node
        # at some point should do "source" + 035 
        if( book_node_exists( $id) ) {
            $logger->warn( "Record $id already exists in database" ) ;
            next RECORD ;
        }

    
        # Add a node for the book
        my $book_node = REST::Neo4p::Node->new( {title => $marc->title(),
                                                 loc_bib_id => $id,
                                                 
                                             },
                                            );
        $book_node->set_labels( 'book' ) ;
        if( $marc->author() ) {
            my $book_resp_node
                = fetch_or_create_responsible_node(
                    {name => $marc->author()  } ) ;
            
            $book_resp_node->relate_to( $book_node, 'responsible_for') ; 
        }
        

        
    
        
        foreach my $note_field (@note_fields) {
            #make a content object...eventually
            
        # should see if there's an ISBD parser, if not
        # make one, but for now, being lazystype

            if ( is_extended_content($note_field) ) {
                push(@contents,
                     parse_enhanced_contents( $note_field) );
            } elsif ( contains_toc_in_subfield_a( $note_field ) ) {
                push(@contents,
                     parse_basic_contents( $note_field ) ) ;
            }
        
        }
        use Data::Dumper ;
        $logger->debug( Dumper( \@contents ) );

        
        $logger->debug("Gets past first add_entry \n" ) ;
      WORK: foreach my $work (@contents ) {
        
            $logger->debug( $work ) ;
          
            my @work_resp =  defined($work->{responsible}) 
                        ? @{$work->{responsible} }
                        : ()  ;
            my $work_title = $work->{title} ;

            if( non_story_content( $work_title ) ) {
                next WORK ;
            }
            if ( defined( $work_title ) &&  @work_resp  ) {
                
                $logger->debug("Field has both title & responsbile: title = $work_title, responsible_for = " . join(', ', @work_resp ) );
                
                my $title_node = fetch_or_create_work_node({title => $work_title }) ;
                
                # book contains work
                $title_node->relate_to( $book_node, 'contained_in' ) ;
                
                
                foreach my $work_resp (@work_resp ) {
                    my $resp_node
                        = fetch_or_create_responsible_node( {name => $work_resp,
                                                         },                                                    ) ;
                    
                    # reponsible created work
                    $resp_node->relate_to( $title_node, 'responsible_for' ) ;
                }
            }
            elsif( defined $work_title ) {
                
                $logger->debug("Work only has title  $work_title") ;
                my $title_node = fetch_or_create_work_node({title => $work_title,
                                                        }) ;
                
                # work contained_in book
                $title_node->relate_to( $book_node, 'contained_in' ) ;
                
                
            }
        }
    }
    
    $logger->info("finished processing records") ;
}

sub get_skip_list {

    my $file_path = shift ;

    return map { $_ => 1 } read_file( $file_path, { chomp => 1 } ) ;
    
}

sub is_extended_content {

    my $contents_field = shift ;
    # couple of cases for our possible content nodes
    # a) it's a 505 w/ indicator 0 with actual  t & r subfields (or...let's just see if it has t subfields
    # b) it's a 505 w/ indicator 0, but no t & r subfields
    # c) it's a 505.
    #
    # Only case a should get actual parsing

    # need to refactor out w/ filter_records.pl way of
    # handling 505
    # into a package
    # not sure about bothering with the
    # indicator, would be nice to do some statistics
    
    if(    $contents_field->tag() eq '505'
       &&  defined ($contents_field->subfield('t') ) ) {
        return 1 ;
    }

    return 0 ;
}

#
# ONLY WORKS for basic
sub contains_toc_in_subfield_a {

    my $field = shift ;

    if(   defined( $field->subfield('a') )
              && $field->subfield('a') =~ /--/ ) {
        return 1 ;
    }

    return 0 ;
}


# pattern 1: title / author -- [title / author ...].
sub parse_pattern_one {

    my $contents_string = shift ;

    my @works = () ;
    
    # going to assume title / statment of responibility -- 
    my @subparts = split(/ ?-- ?/,
                         $contents_string,
                     ) ;
    
    foreach my $subpart (@subparts) {
        
        my ($title, $resp_part) = split(/\//, $subpart) ;
        
        # do we really want to worry about this relatively rare
        # edge case where there is multiple authors for
        # one short story (and what if three? dealing with ,? )

        $resp_part =~ s/\.\s*$//; # remove trailing period
        
        my @responsibles
            = map
              { trim ($_) }
              split( / and /, $resp_part );

        push(@works,{
            title => trim($title),
            responsible  => \@responsibles,
        });
    }

    return @works ;
}



# pattern 2: last name, initials, titleAddress. title1. title2.
sub parse_pattern_two {

    my $contents_string = shift ;

    my @works = () ;
    foreach my $work_string (split(/--/, $contents_string ) ) {
        push( @works,
              ParseTwoFSM::parse( $work_string ), ) ;
    }
    return @works ;
}


# pulled out ot make it easier to do some statistics 
sub determine_parse_pattern {
    
    my $contents_string = shift ;

    if(   $contents_string =~ /\//
       && $contents_string =~  /--/ ) {
        return 1 ;
    }
    elsif (   $contents_string =~ /--/
           && $contents_string =~ tr/\.// > 3 ) {
        return 2 ;
    }
    
    return 0 ;
 
}

sub parse_string_of_contents {

    my $contents_string = shift ;
    
    my @works = () ;


    # note, it seems at least some records switch up to
    # be author / title, but I can't think of a reasonable way...yet
    # that I can filter those out...at some point am tempted
    # to do a mix of manual and automated input....
    
    # need to look into some syntaxes/parsers in the long run
    # rather than doing the hacks below

    # also should run some statistics 
    
    # pattern 1: title / author -- [title / author ...].
    # pattern 2: last name, initials, titleAddress. title1. title2.--last name

    my $parse_pattern = determine_parse_pattern( $contents_string ) ;

    #print "parse pattern for $contents_string is $parse_pattern\n";
    # some meta-programming might be useful here,
    # or hash of first-order function
    if ( $parse_pattern == 1) {
        return parse_pattern_one ( $contents_string ) ;
    }
    elsif ( $parse_pattern == 2 ) {
        return parse_pattern_two ( $contents_string ) ;
    }
    
    
    return @works ;

}

    
sub parse_basic_contents {

    my $contents_field = shift ;
    
    return parse_string_of_contents( $contents_field->subfield('a') ) ;

}

sub parse_enhanced_contents {

    my $contents_field = shift ;
    
    # probably need something a bit more intelligent or
    # a better parser, but
    # for now going to assume either a $t or a $t $r pattern

    my @entries ;

    # for now haven't decided what to do if
    # record doesn't have t r pattern
    # see 00702848 as an example of one that apparently didn't
    # but instead mixes t and r up

    foreach my $subfield ($contents_field->subfields() ) {
        
        $logger->debug( "Subfield: " . Dumper( $subfield ) );
                        
        if(   $subfield->[0] eq 'r' ) {
            $logger->debug("Subfield of type 'r'") ;

            my $resp = remove_common_attributions( $subfield->[1] ) ;
            $logger->debug("adding person responsible") ;
            # need to create more test records for
            # different patterns

            #if( ! defined ( $entries[-1] ) || ! defined(

            push( @{  $entries[-1]->{responsible} },
                  $resp ) ;
        }
        elsif( $subfield->[0] eq 't' ) {

            $logger->debug("Subfield of type 't'") ;

            my $title = $subfield->[1] ;
            $title =~ / ?-- ?/ ;
            
            push(@entries,
                 { title => $title  } ) ;
        }
    }
    return @entries;
}

sub remove_common_attributions {

    my $string = shift ;

    $string =~ s/ ?by ?// ;

    return $string ; 
}

sub marc_filter {
    my ($tagno,$tagdata) = @_;
    
    return ($tagno == 245) || ($tagno == 505);
}

sub trim {

    my $string = shift ;

    if(!defined($string))  {
        return $string ;
    }
    
    $string =~ s/^\s*// ;
    $string =~ s/\s*$// ;

    return $string ;
}
sub setup_neo4j {
    

    REST::Neo4p->connect('http://127.0.0.1:7474');
    # for now?
    
    #my $index = REST::Neo4p::Index->new('node', 'anthology');

#    return $index ;
}

sub fetch_or_create_node {

    
    my $type = shift ;
    my $node_properties = shift ;
    my $labels_ref = shift ;
    
    # default to what I've been calling "type" if not provided
    if(!defined($labels_ref)) {
        $labels_ref = [ $type ] ;
    }
    
    use Data::Dumper ;
    $logger->debug( "Adding node of $type " . Dumper( $node_properties ) ) ;

    
    my $value = $node_properties->{ $type_lookup_key{ $type } } ;

    my $query_h = $query_cache{ $type } ;

    # should verify needed 
    $value =~ s/'/\\'/g ;
    $value =~ s/\\/\\\\/g ;
    
    $query_h->execute( value => $value ) ;
    
    if($query_h->err) {
        die("Had issue with neo4j query " . $query_h->errstr) ;
     }

    my $node ;
    RESULTS: while( my $row = $query_h->fetch() ) {
          $node = $row->[0] ;
      }
    if( !defined($node) ) {
        $node = REST::Neo4p::Node->new( $node_properties ) ;
        $node->set_labels( @{ $labels_ref} ) ;
    }

    $logger->debug("finished adding node");
    return $node ;
}

#need to refactor above at some point
sub fetch_or_create_responsible_node {
    
    my $node_properties = shift ;

    return fetch_or_create_node('responsible',
                                $node_properties,
                            ) ;
}


sub fetch_or_create_work_node {

    my $node_properties = shift ;
    return fetch_or_create_node('work',
                                $node_properties );
}

sub non_story_content {

    my $title = shift ;

    $title =~ s/\.//g ;
    $title =~ s/ //g ;

    $title = lc( $title ) ;
    
    if(   $title =~ /tpverso/
       || $title eq 'introduction'
       || $title eq 'cover' 
       || $title eq 'forward' ) {
        return 1 ;
    }
    return 0 ;
    
}

sub book_node_exists {

    my $bib_id = shift ;

    my $check_exists_h = $query_cache{ 'book_exists' } ;

    $logger->debug("Calling  $check_book_already_added_q with $bib_id " ) ;
    $check_exists_h->execute( bib_id => $bib_id ) ;

    my $count = $check_exists_h->fetch->[0] ; 
    
    if ( $count > 0 ) {
        return 1 ;
    }
    return 0 ;
    
}


__END__
