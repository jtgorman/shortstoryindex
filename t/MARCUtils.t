#!/usr/bin/env perl

use strict ;
use warnings ;

use Test::More ;

use MARC::Record ;

use MARCUtils qw( get_last_record number_of_records );

my $small_file_path = setup_small() ;
my $large_file_path = setup_large() ;

test_get_last_record($small_file_path, '3' ) ;
test_get_last_record($large_file_path, '10026742') ;

is( number_of_records( $small_file_path ),
    4,
    'Number of records should be 4'
) ;

is( number_of_records( $large_file_path ),
    250000,
    'Number of records should be 250000'
) ;

done_testing() ;

sub test_get_last_record {

    my $file_path = shift ;
    my $expected = shift ;
    
    my $last_record = get_last_record( $file_path  ) ;

    is(_trim($last_record->field('001')->data()),
       $expected,
       "last record id should be $expected") ;
}

sub test_number_of_records {

    my $actual
}

sub _trim {

    my $s = shift ;

    $s =~ s/^\s*//;
    $s =~ s/\s*$//;

    return $s ;
}

    

sub setup_small {
    my $test_file_path = 't/test_for_last.marc' ;
    open my $test_file, '>', $test_file_path or die "Could not open $test_file_path for writing" ;

    for( my $i = 0; $i < 4; $i++) {
        my $record = MARC::Record->new() ;

        my @fields = (MARC::Field->new('001', $i ),
                      MARC::Field->new('245','0','4',
                                       'a' => "The wonder book number $i / ", 
                                       'c' => "Joe Anon",
                                       ),
                  ) ;
        
        $record->append_fields( @fields ) ;

        print $test_file $record->as_usmarc() ;
    }
    close $test_file ;
    return $test_file_path ;

}
# instead of trying to create some dump (which we should)
# or dynamically downloading, for now just using a copied "big" file
sub setup_large{
    return 't/large_dump.marc' ;
}

