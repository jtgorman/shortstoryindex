#!/usr/bin/env perl

# ./create_pull_file.pl --out bibs.txt records1.marc [records2.marc ..]
#
# A small utility script
# early on I realized that there were some encoding issues
# been a bit lazy about fixing, but it bothered me enough
# that I've gone ahead and converted the records via yaz-marcdump
#
# however, I dont' want to sit and through and pick records I already have
# so figure this is useful.
#
# Note this appends, not replaces, the specified outfile

use MARCUtils qw( get_bib_ids ) ;

use File::Slurp ;

use Getopt::Long ;

use Data::Dumper ;


my $out = '' ;

GetOptions(
    "out=s" => \$out,
    );

# whatever is left is files
my @in_files = @ARGV;

if ( @in_files == 0 ) {
    die "No input files specified, use ./create_pull_file.pl --out filename marc_file_1.mrc [marc_file_2.mrc ...] ) " ;
    }

if( $out eq '') {
    die "No output file specified, use --out (eg  ./create_pull_file.pl --out filename marc_file_1.mrc [marc_file_2.mrc ...] )" ;
}

print "writing to $out \n ";


FILE: foreach my $file (@in_files ) {
    my @bib_ids = get_bib_ids( $file ) ;
    unless(@bib_ids > 0) {
        warn "No bib ids found for $file ";
        next FILE ;
    };
    
    write_file( $out,
                { append => 1 },
                join("\n",@bib_ids) ,
            ) ;
}
