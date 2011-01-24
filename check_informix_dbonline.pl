#!/usr/bin/perl
# check_informix_dbonline.pl - Checks if Informix DB is online
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

our ($opt_i);

sub usage {
	print "Usage: $0 -i INFORMIXSERVER\n";
	exit (1);
}

if (!getopts("i:")) {
	usage();
}
elsif (!defined($opt_i)) {
	usage();
}
else {

	$ENV{"INFORMIXSERVER"} = $opt_i;
	$ENV{"INFORMIXSHMBASE"} = 0;
	$ENV{"INFORMIXDIR"} = "/opt/IBM/informix";
	$ENV{"PATH"} = $ENV{"PATH"}.":".$ENV{"INFORMIXDIR"}."/bin";

	my @INPUT = `onstat -`;
	my @DBInfo;

	foreach my $input (@INPUT) {
		if ($input =~ /^$/) {
			next;
		}
		elsif ($input =~ /-- On-Line --/) {
			@DBInfo = split(' ', $input);
			print "OK: DB is Online (Up since $DBInfo[10] $DBInfo[11] $DBInfo[12])\n";
			exit (0);
		}
		else {
			print "CRITICAL: DB state is abnormal: ($input)\n";
			exit (2);
		}
	}
}
