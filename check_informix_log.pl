#!/usr/bin/perl
# check_informix_log.pl - Checks today's Informix Online Log
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
#
# The returned message shows only the last located issue, because Nagios only accepts one line for the returned text.

use warnings;
use strict;
use Getopt::Std;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
my @days = qw( Sun Mon Tue Wed Thu Fri Sat );

$year += 1900;
my $today = "$days[$wday] $months[$mon] $mday";

our ($opt_i);

sub usage {
	print "Usage: $0 -i INFORMIXSERVER\n";
    exit (1);
}

if (!(getopts("i:"))) {
    usage();
}
elsif (!(defined($opt_i))) {
    usage();
}
else {
	$ENV{"INFORMIXSERVER"} = $opt_i;
	$ENV{"INFORMIXSHMBASE"} = 0;
	$ENV{"INFORMIXDIR"} = "/opt/IBM/informix";
	$ENV{"PATH"} = $ENV{"PATH"}.":".$ENV{"INFORMIXDIR"}."/bin";

	my @INPUT = `onstat -m`;
	my @LOGINPUT;
	my $log;
	my $begin = 0;

	my $critical = 0;
	my $warning = 0;

	my $text = "";

	foreach my $line (@INPUT) {
		if ($line =~ /Message Log File:/) {
			@LOGINPUT = split(/:/, $line);
			$log = $LOGINPUT[1];
			$log =~ s/^\s+|\s+$//g;
		}
	}

	open(FILE, '<', $log) or die "Error: $!\n";

	while(<FILE>) {
		if ($_ =~ /$today.*$year$/) {
			$begin = 1;
			next;
		}

		if ($begin == 1) {
			if ($_ =~ /warning/i) {
				$warning++;
				$text = $text." $_";
			}
			elsif ($_ =~ /error|failed|corrupted/i) {
				$critical++;
				$text = $text." $_";
			}
		}
	}

	close(FILE);

    if ($critical > 0) {
        print "CRITICAL: $text\n";
        exit (2);
    }
    elsif ($warning > 0) {
        print "WARNING: $text\n";
		exit (1);
	}
    else {
        print "OK: No Errors found in Log for $today $year\n";
        exit (0);
	}
}
