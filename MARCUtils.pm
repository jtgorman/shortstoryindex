#!/usr/bin/env perl

package MARCUtils ;



use strict ;
use warnings ;

use MARC::File::USMARC ;

use Tie::File ;

use Exporter;


# base class of this(Arithmetic) module
our @ISA = qw(Exporter);



# Exporting the add and subtract routine
#@EXPORT = qw(add subtract);
# Exporting the multiply and divide  routine on demand basis.
our @EXPORT_OK = qw(get_last_record number_of_records);


# really need to benchmark this, might be better to roll our own
sub get_last_record {

    my $file_path = shift ;

    my @records ;
    tie @records, 'Tie::File', $file_path, recsep => chr(0x1d)
        or die "Could not get $file_path";

    my $last_record_text = $records[-1] ;
    
    return MARC::File::USMARC::decode( $last_record_text )   ;
    
}

sub number_of_records {

    my $file_path = shift ;
    
    my @records ;
    tie @records, 'Tie::File', $file_path, recsep => chr(0x1d)
        or die "Could not get $file_path";

    return scalar( @records ) ;
 
}
