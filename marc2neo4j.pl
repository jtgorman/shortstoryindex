#!/usr/bin/env perl

use strict ;
use warnings ;

# need to create a template...

#use Log::Log4Perl ;

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

#my $index =
setup_neo4j() ;

# look more into batch mode later...

my $batch = MARC::Batch->new( 'USMARC', @ARGV );
my $count = 0 ;
#while ( my $marc = $batch->next(\&marc_filter) ) {
# going to remove the filter temporarily, while we try to get a better
# system for picking records
RECORD: while ( my $marc = $batch->next() ) {

    my $title = $marc->title() ;
    my $notes_field = $marc->field('505') ;
    #ok, let's say for now we only care about Complete, enhanced contents...
    
   
    print "At record " . $count++ . "\n" ;
    print "title: " . $marc->title() . "\n" ;
    print "TOC: " . $marc->field('505')->as_formatted() . "\n" ;
    print "raw TOC: " . $marc->field('505')->as_usmarc() . "\n" ;

    #make a content object...eventually
    my @contents = () ;
    
    # should see if there's an ISBD parser, if not
    # make one, but for now, being lazy
    if($notes_field->indicator(2) eq q{} || $notes_field->indicator(2) eq q{ }) {
        push(@contents,
             parse_basic_contents( $notes_field )
         ) ;

    }
    elsif ($notes_field->indicator(2) =~ /\d/ && $notes_field->indicator(2)  == 0) {
        push(@contents,
             parse_enhanced_contents( $notes_field)
         );

    }

    use Data::Dumper ;
    print Dumper( \@contents ) ;


        print "Gets here, title is $title \n" ;
    
    # Add a node for the book
    my $book_node = REST::Neo4p::Node->new( {title => $title} ) ;
    #$index->add_entry( $book_node, {title => $title, type => 'book'} ) ;

    print "Gets past first add_entry \n" ;
    foreach my $work (@contents ) {

        my $work_resp = $work->{responsible} ;
        my $work_title = $work->{title} ;

        if (   defined( $work_title )
            && defined( $work_resp ) ) {

            print "getting here! Title: $work_title, Resp: $work_resp \n\n " ;
            my $resp_node = fetch_or_create_responsible_node(  {name => $work_resp,
                                                                type => 'responsibility'} ) ;
                #REST::Neo4p::Node->new( {name => $work_resp} ) ;
           # $index->add_entry( $resp_node, {name => $work_resp,
           #                                 type => 'responsibility'} ) ;

            my $title_node = fetch_or_create_work_node({title => $work_title,
                                                        type => 'work'}) ;
            #my $title_node = REST::Neo4p::Node->new( {title => $work_title} ) ;
            #$index->add_entry( $title_node, {title => $work_title,
            #                                 type => 'work'} ) ;
            # apparent neo4j will allow traversal "against" directionality"
            
            # work created_by responsible
            #$title_node->relate_to( $resp_node, 'created_by' ) ;
            
            # reponsible created work
            $resp_node->relate_to( $title_node, 'created' ) ;

            # book contains work
            $book_node->relate_to( $title_node, 'contains' ) ;

            
            # work contained_in book
            #$title_node->relate_to( $book_node, 'contained_in' ) ;

            
        }
        elsif( defined $work_title ) {

            print "getting here! Title: $work_title \n\n" ;
            #my $title_node = REST::Neo4p::Node->new( {title => $work_title} ) ;
            my $title_node = fetch_or_create_work_node({title => $work_title,
                                                        type => 'work'}) ;

            # book contains work
            # $book_node->relate_to( $title_node, 'contains' ) ;

            # work contained_in book
            $title_node->relate_to( $book_node, 'contained_in' ) ;
            #$index->add_entry( $title_node, {title => $work_title,
            #                                 type => 'work'} ) ;

            
        }
    }
}

sub _parse_string_of_contents {

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
    
    return _parse_string_of_contents( $contents_field->subfield('a') ) ;

}

sub parse_enhanced_contents {

    # we're going to assume (although we should make more robust)
    # following $t title / $r statment of resp --
    
    #my $contents_field = shift ;

    #quick hack

    my $contents_field = shift ;
    
    return _parse_string_of_contents( $contents_field->as_formatted() );

    
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
