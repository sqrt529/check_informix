#!/usr/bin/perl
# check_informix_dbspace.pl - Checks size of the given DBSpace
#
# Copyright (C) 2010 Joachim "Joe" Stiegler <blablabla@trullowitsch.de>
# 
# This program is free software; you can redistribute it and/or modify it under the terms
# of the GNU General Public License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program;
# if not, see <http://www.gnu.org/licenses/>.
#
# --
# 
# Version: 1.0 - 2010-10-13

use warnings;
use strict;
use Getopt::Std;

our ($opt_c, $opt_w, $opt_d, $opt_h, $opt_i, $opt_p);

my $dbsnumber;
my $dbsname = "";

sub usage {
	print "Usage: $0 -i INFORMIXSERVER -d <dbspace> -c <Critical size MB> -w <Warning size MB> [-p (+perf data)]\n";
	exit (1);
}

sub is_numeric {
    my $number = shift(@_);
    if ($number =~ /[^\d]/) {
        usage();
    }
    else {
		return (1);
	}
}

if (!getopts("c:w:d:hi:p")) {
	usage();
}

if ( (!defined($opt_c)) || (!defined($opt_w)) || (!defined($opt_d)) || (defined($opt_h)) || (!defined($opt_i)) ) {
	usage();
}

if ( (is_numeric($opt_c)) && (is_numeric($opt_w)) ) {
	
	$ENV{"INFORMIXSERVER"} = $opt_i;
	$ENV{"INFORMIXSHMBASE"} = 0;
	$ENV{"INFORMIXDIR"} = "/opt/IBM/informix";
	$ENV{"PATH"} = $ENV{"PATH"}.":".$ENV{"INFORMIXDIR"}."/bin";

	my @INPUT = `onstat -d`;
	my @DBSpaces;
	my @Chunks;
	
	my $size = 0;
	my $free = 0;
	my $pagesize = 0;
	
	my $begin = 0;
	my $end = 0;
	
	foreach my $dbsline (@INPUT) {

		if ($dbsline =~ /^address          number   flags      fchunk   nchunks  pgsize   flags    owner    name$/) {
			$begin = 1;
			next;
		}
		elsif ($dbsline =~ /maximum$/) {
			$end = 1;
		}
	
		if ($begin == 1 && $end == 0) {

			@DBSpaces = split(' ', $dbsline);

			my $fields = scalar @DBSpaces - 1;

			if ($DBSpaces[$fields] eq $opt_d) {
				$dbsnumber = $DBSpaces[1];
				$pagesize = $DBSpaces[5];
				$dbsname = $DBSpaces[$fields];
				$begin = 0;
				$end = 1;
			}
			else {
				next;
			}
		}
	
		if ($dbsname eq $opt_d) {
			if ($dbsline =~ /^address          chunk\/dbs     offset     size       free       bpages     flags pathname$/) {
				$begin = 2;
				$end = 0;
				next;
			}
			elsif ($dbsline =~ /maximum$/) {
				$end = 1;
			}
	
			if ($dbsline =~ /Metadata/) {
				next;
			}
		
			if ($begin == 2 && $end == 0) {
				@Chunks = split(' ', $dbsline);
				if ($Chunks[2] == $dbsnumber) {
					$size += $Chunks[4];
					$free += $Chunks[5];
				}
			}
		}
	}

	$size = int(($size * $pagesize) / (1024 * 1024));
	$free = int(($free * $pagesize) / (1024 * 1024));

	my $used = $size - $free;
	my $pt = int((100 / $size) * $used) if ($size > 0);
	
	my $text = "$pt% used in $dbsname ($free MB of $size MB available)";
	
	if (defined($opt_p)) {
		$text = $text."|used=".$pt;
	}

	if ($free <= $opt_c) {
		print "CRITICAL: $text\n";
		exit (2);
	}
	elsif ($free <= $opt_w) {
		print "WARNING: $text\n";
		exit (1);
	}
	else {
		print "OK: $text\n";
		exit (0);
	}
}
