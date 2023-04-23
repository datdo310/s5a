#!/usr/bin/perl

my $person_list = "./apply/ALL/person.list";
my $incsv  = $ARGV[0];
my $outcsv = $ARGV[1];

# Read hier info from config file
my $config = "make_excelsum.cfg";
my %skip;
my %add;
&read_config($config);

# Read person in charge
my %cperson;
my %person;
&setting_person($person_list);

open(my $IN,"<","$incsv")   || die "* Error: $0 cannot read $incsv: $!\n";
open(my $OUT,">","$outcsv") || die "* Error: $0 cannot write $outcsv: $!\n";

while (my $line = <$IN>) {
    chomp($line);
    if ($line =~ m/^,Startpoint,Endpoint,Path Group/) {
        $line =~ s/^/No/;
        $line =~ s/$/CLOCK,TRUE or FALSE,PIC/;
    } else {
        my @elements = split(",",$line);
        my $stpoint = $elements[1];
        my $edpoint = $elements[2];
        my $_inst;
        if ($incsv =~ m/STARTPOINT_METAS/) {
            print STDOUT "start\n";
            $_inst = $stpoint;
        } else {
            print STDOUT "end\n";
            $_inst = $edpoint;
        }
        my $hier = &shorten($_inst);
        if (defined($person{$hier})) {
            $line =~ s/$/,$person{$hier}/;
        }
    }
    printf $OUT "$line"."\n";
}

close ($IN);
close ($OUT);

sub setting_person {
    my ($person_list) = @_;
    if (-f $person_list) {
        open(IN,"$person_list") || die "* Error: $0 Cannot read $person_list: $!\n";
        my $mnum = 0;
        my $cnum = 0;
        while (my $line = <IN>) {
            if ($line !~ m/^\s*#/ && $line !~ m/^\s*$/) {
                if ($line =~ m/^\s*(\S+)\s+CLOCK\s+(\S+)/) {
                    my $_clock = $1;
                    $cperson{$_clock} = $2;
                    $cnum++;
                } elsif ($line =~ m/^\s*(\S+)\s+(\S+)\s+(\S+)/) {
                    my $_inst         = $1;
                    $person{$_inst} = $3;
                    $mnum++;
                }
            }
        }
        close (IN);
    }
}

sub shorten {
    my($inst ) = @_;
    my($add_hier) = "";
    @tmp = split(/\//,$inst);
    for ($i=0 ; $i<=$#tmp; $i++){
        if (defined($add{$tmp[$i]})) {
            $add_hier = $add_hier.$add{$tmp[$i]};
        }
        if (!defined($skip{$tmp[$i]}) || !defined ($tmp[$i+1])) {
            $add_hier = $add_hier.$tmp[$i];
            return $add_hier;
        }
    }
}

sub read_config {
    my ($config) = @_;
    open(my $CFG,"<","$config") || die "* Error: $0 cannot read $config:$!\n";
    while (my $line = <$CFG>) {
        chomp($line);
        if ($line =~ m/^\s*CHKPRIME\s*\,/) {
            my @str = split(/\s*\,\s*/,$line);
            if ($str[1] eq "SKIP_HIER") {
                $skip{$str[2]} = "SKIP";
            } elsif ($str[1] eq "ADD_HIER") {
                $add{$str[2]} = $str[3];
            }
        }
    }
    close (CFG);
}

