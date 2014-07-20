#!/usr/bin/env perl

package MARCUtils ;



use strict ;
use warnings ;

use MARC::File::USMARC ;
use MARC::Batch ;

use Tie::File ;

use Exporter;


# base class of this(Arithmetic) module
our @ISA = qw(Exporter);



# Exporting the add and subtract routine
#@EXPORT = qw(add subtract);
# Exporting the multiply and divide  routine on demand basis.
our @EXPORT_OK = qw(get_last_record number_of_records get_bib_ids get_bib_id);


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


sub get_bib_ids {

    my @file_paths = @_ ;
    my @bib_ids = ();
    
    my $batch = MARC::Batch->new( 'USMARC', @file_paths ) ;
    while( my $record = $batch->next( \&_001_filter ) ) {

        my $bib_id = get_bib_id( $record ) ;
        push( @bib_ids,
              $bib_id ,
          ) ;
              
    }

    return @bib_ids ;
}

sub _001_filter {

    my ($tagno,$tagdata) = @_ ;
    return ($tagno == '001') ; 
}

sub get_bib_id {

    my $record = shift ;

    my $field_001 = $record->field('001')->data() ;

    $field_001 =~ s/^\s*// ;
    $field_001 =~ s/\s*$// ;

    return $field_001 ;

}

1;
