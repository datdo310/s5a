#!/usr/bin/perl

my $incsv = $ARGV[0];
my $module = $ARGV[1];

my $excelfile = $incsv;
$excelfile =~ s/\.csv/\.xlsx/;

use lib("./bin/perl_lib/Archive-Zip-1.59/lib");
use lib("./bin/perl_lib/Excel-Writer-XLSX-0.95/lib");
use strict;
use warnings;

use Excel::Writer::XLSX;

my $workbook = Excel::Writer::XLSX->new("$excelfile")
   or die "* Error: $0 cannot write $excelfile: $!\n";

my $worksheet = $workbook->add_worksheet("$module");
open (my $INPUT,"<", "$incsv");
my $row = 0;
my $col = 0;
while (my $line = <$INPUT>) {
    chomp($line);

    my @elements = split(",",$line);

    for ($col = 0; $col <= $#elements; $col++) {
        $worksheet->write_string($row, $col, $elements[$col]);
    }
    $row++;
}
close($INPUT);
$workbook->close();
