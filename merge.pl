#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

# Join two files by the specified columns
my %opts = (1=>undef, 2=>undef, h=>undef, empty=>"", d=>"\t", a=>undef, f2=>undef);
my $res = GetOptions ("1:s"  => \$opts{1}, "2:s"  => \$opts{2}, "h:s" => \$opts{h}, "empty:s" => \$opts{empty}, "d:s" => \$opts{d}, "a:s" => \$opts{a}, "f2:s" => \$opts{f2});


die(qq/
Description: merge two files using selected columns. 
	- Columns can be specified as column number or column name. In that case, header must be present in both files. If column names are different, column name from file2 will be used.
	- The output will contain file2 columns first. 
	- By default output will contain only the interesection. 
	- If there are duplicated values in file1, only the first value will be merged. 
	- It accepts 'gz' files

Usage:   merge.pl [-h -d -f2 -a -empty NA] -1 col1\/name1 -2 col2\/name  <file1> <file2>

Options:
	-h	BOOL	Join headers. Require header in both files. Unset by default. Activated if column names are used
	-d	CHAR	Column separator. Default "\\t"
	-a	BOOL	Print all lines from file2. Unset by default
	-empty	CHAR	Character for emtpy fields. Requires option -a . None by default
	-f2	BOOL	Print only lines in file2. Unset by default

Contact: fcastroginer\@gmail.com
\n/) if (@ARGV != 2 || ! defined $opts{1} || ! defined $opts{2});	

die ("ERROR: file 1 $ARGV[0] doesn't exists") if( ! -e $ARGV[0] );
die ("ERROR: file 2 $ARGV[1] doesn't exists at") if( ! -e $ARGV[1] );

# Check column class
my $coltype;
if ($opts{1} =~ /\d+/ && $opts{2} =~ /\d+/) {
	$coltype = "numeric";
} elsif ($opts{1} =~ /\D+/ && $opts{2} =~ /\D+/) {
	$coltype = "string";
} else {
	die ("ERROR: specified columns must have the same format : numeric or string");
}
$opts{h} = 1 if ($coltype eq "string");

# Column Variable
my $col1 = $opts{1};
my $col2 = $opts{2};

# Convert column number 1-based to 0-based
$col1 = $opts{1} - 1 if($coltype eq "numeric");
$col2 = $opts{2} - 1 if($coltype eq "numeric");


# Reading file one
if ($ARGV[0] =~ m/\.gz$/){
	open (FILE1, "gunzip -c $ARGV[0]|");
} else {
	open (FILE1, "<$ARGV[0]");
}

my %ONE;
my $ncol1;

# Read Header 1
my $header1;
if (defined($opts{h}))
{
	my $l = <FILE1>;
	chomp $l;
	my @l = split $opts{d},$l;
	
	# Get column index if coltype = string
	if($coltype eq "string")
	{
		my @tmp = grep { $l[$_] eq $col1 } 0..$#l;
		$col1 = $tmp[0];
	}

	my @o;
	foreach my $index (0 .. $#l){
		push(@o, $l[$index]) if($index != $col1);
	}
	$header1 = join($opts{d}, @o);
}


 
# Reading rest of the file
while(<FILE1>)
{
	chomp;
	my @l = split $opts{d};
	my @o;
	if(exists $l[$col1]) {
		foreach my $index (0 .. $#l){
			push(@o, $l[$index]) if($index != $col1);
		}
		$ncol1 = @o;
		$ONE{$l[$col1]} = join($opts{d}, @o) if(!exists $ONE{$l[$col1]});
	}
}

# Create empty fields
my $empty="";
foreach my $i (1 .. $ncol1)
{
	$empty = $empty.$opts{d}.$opts{empty};
}

# Reading file two
if ($ARGV[1] =~ m/\.gz$/){
	open (FILE2, "gunzip -c $ARGV[1]|");
} else {
	open (FILE2, "<$ARGV[1]");
}

# Read Header 2
if (defined($opts{h}))
{
	my $header2 = <FILE2>;
	chomp $header2;
	print $header2.$opts{d}.$header1."\n" if (!defined $opts{f2});
	print $header2."\n" if (defined $opts{f2});
	
	# Get column index if coltype = string
	if($coltype eq "string")
	{
		my @l = split $opts{d},$header2;
		my @tmp = grep { $l[$_] eq $col2 } 0..$#l;
		$col2 = $tmp[0];
	}
	
}


while(<FILE2>)
{
	chomp;
	my @l = split $opts{d};
	#chomp if ($l[$#l] =~ /\w+/);
	#chomp $l[$#l] if ($l[$#l] =~ /\w+/);
	
	if ( defined $l[$col2])
	{	
		if( exists ($ONE{$l[$col2]}) && !defined $opts{f2})
		{
			print $_.$opts{d}.$ONE{$l[$col2]}."\n";
		} elsif (defined $opts{a} && !defined $opts{f2}) {
			print $_.$empty."\n";
		} elsif (!exists $ONE{$l[$col2]} && defined $opts{f2}) {
			print $_."\n";
		}
	} else {
		if( defined $opts{f2} )
		{
			print $_."\n";
		} elsif (defined $opts{a}) {
			print $_.$empty."\n";
		}	
	}
}


