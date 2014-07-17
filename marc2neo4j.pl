#!/usr/bin/env perl

use strict ;
use warnings ;

# need to create a template...

use Log::Log4perl qw(get_logger :levels);

Log::Log4perl::init('log.config') ;
my $logger = Log::Log4perl->get_logger() ;

#use Config::General ;
#my $conf = Config::General->new("marc2neo4j.config");
#my %config = $conf->getall;


# We'll want to pull this out into a module later


# but basically want to
# * get the 245 a & b -> title (and maybe some sort of id?)
# then create author / short story title from 505 (throw out if no 505)
# parse the different common patterns for such
# then do queries
#
# can make more complicated later

use MARC::Batch ;
use MARC::Record ;


use REST::Neo4p;

#use REST::Neo4p::Batch ;

setup_neo4j() ;

# look more into batch mode later...

my $batch = MARC::Batch->new( 'USMARC', @ARGV );
my $count = 0 ;
#while ( my $marc = $batch->next(\&marc_filter) ) {
# going to remove the filter temporarily, while we try to get a better
# system for picking records
RECORD: while ( my $marc = $batch->next() ) {
    
    my $title = $marc->title() ;
    my @note_fields = $marc->field('505') ;
    push(@note_fields,
         $marc->field('500') ) ;

    my @contents = () ;
    
    $logger->debug( "At record " . $count++ )  ;
    $logger->debug("title: " . $marc->title() ) ;
    $logger->debug(  "TOCs: "
                         . join(map
                                  { $_->as_formatted() }
                                  @note_fields ) );
    
    
    # Add a node for the book
    my $book_node = REST::Neo4p::Node->new( {title => $title,
                                             name => $title,
                                             loc_bib_id => $marc->field('001')->data(),
                                             type => 'book'
                                         }
                                        );
        
        if( $marc->author() ) {
            my $book_resp_node
                = fetch_or_create_responsible_node( {name => $marc->author(),
                                                     type => 'responsible' } ) ;
            
            $book_resp_node->relate_to( $book_node, 'responsible_for') ; 
        }


        
    
    
    foreach my $note_field (@note_fields) {
        #make a content object...eventually
        
        # should see if there's an ISBD parser, if not
        # make one, but for now, being lazy

        if( is_extended_content($note_field) ) {
            push(@contents,
                 parse_enhanced_contents( $note_field) );
        }
        elsif ( contains_toc_in_subfield_a( $note_field ) ) {
            push(@contents,
                 parse_basic_contents( $note_field ) ) ;
        }
        
    }
    use Data::Dumper ;
    $logger->debug( Dumper( \@contents ) );

        
 
    print "Gets past first add_entry \n" ;
    foreach my $work (@contents ) {

        my $work_resp = $work->{responsible} ;
        my $work_title = $work->{title} ;

        if (   defined( $work_title )
            && defined( $work_resp ) ) {

            $logger->debug("Field has both title & responsbile, $work_title, work_resp") ;
            my $resp_node = fetch_or_create_responsible_node(  {name => $work_resp,
                                                                type => 'responsible'},                                                               
                                                           ) ;

            my $title_node = fetch_or_create_work_node({title => $work_title,
                                                        type => 'work',
                                                        name => $work_title,
                                                        }) ;
            
            # reponsible created work
            $resp_node->relate_to( $title_node, 'responsible_for' ) ;
            
            # book contains work
            $title_node->relate_to( $book_node, 'contained_in' ) ;


                                                        
        }
        elsif( defined $work_title ) {

            $logger->debug("Work only has title  $work_title") ;
            my $title_node = fetch_or_create_work_node({title => $work_title,
                                                        type => 'work'}) ;

            # work contained_in book
            $title_node->relate_to( $book_node, 'contained_in' ) ;

            
        }
    }
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

sub parse_string_of_contents {

    my $contents_string = shift ;
    
    my @works = () ;
    # going to assume title / statment of responibility -- 
    my @subparts = split(/ ?-- ?/,
                         $contents_string,
                      ) ;
    foreach my $subpart (@subparts) {
        my ($title, $resp) = split(/\//, $subpart) ;
        push(@works,{
            title => trim($title),
            responsibility  => trim($resp),
        });
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
    
    foreach my $subfield ($contents_field->subfields() ) {
        if( $subfield->[0] eq 'r' ) {
            my $resp = remove_common_attributions( $subfield->[1] ) ;
            push($entries[-1]->{responsible},
                 $resp ) ;
        }
        elsif( $subfield->[0] eq 't' ) {
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

    my $info_ref = shift ;
    my $match_property = shift ;

    my $value = $info_ref->{$match_property} ;

    $value =~ s/'/\\'/g ;

    my $query_text = "MATCH (node {$match_property:'${value}'}) RETURN node" ;

    print $query_text . "\n" ;
    my $query = REST::Neo4p::Query->new( $query_text );
    $query->execute() ;

    if($query->err) {
         die("Had issue " . $query->errstr) ;
     }

    
    while( my $row = $query->fetch() ) {
        # if there's a node, return the first one
        return $row->[0] ;
    } 
    return REST::Neo4p::Node->new( $info_ref ) ;
}

#need to refactor above at some point
sub fetch_or_create_responsible_node {
    my $info_ref = shift ;
    
    return fetch_or_create_node($info_ref, 'name') ;
}


sub fetch_or_create_work_node {

    my $info_ref = shift ;
    return fetch_or_create_node($info_ref, 'title') ;
    
}
