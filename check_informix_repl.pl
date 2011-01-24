#!/usr/bin/perl
# check_informix_repl.pl - Checks the state of Informix DB replication (CDR)
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

our ($opt_h, $opt_i);

sub usage {
	print "Usage: $0 -i INFORMIXSERVER\n";
	exit (1);
}

if (!getopts("hi:")) {
	usage();
}

if ( (defined($opt_h)) || (!defined($opt_i)) ) {
	usage();
}
else {

	$ENV{"INFORMIXSERVER"} = $opt_i;
	$ENV{"INFORMIXSHMBASE"} = 0;
	$ENV{"INFORMIXDIR"} = "/opt/IBM/informix";
	$ENV{"PATH"} = $ENV{"PATH"}.":".$ENV{"INFORMIXDIR"}."/bin";

	my @INPUT = `cdr list server`;
	my @servers;
	my $critical = 0;
	my $text = "All servers are active";

	foreach my $line (@INPUT) {
		next if ($line =~ /^SERVER                 ID STATE    STATUS     QUEUE  CONNECTION CHANGED$/);
		next if ($line =~ /^-/);
		
		@servers = split(' ', $line);

		if (!($servers[2] =~ /Active/)) {
			$critical++;
			$text = $servers[0].": ".$servers[2];
		}
		
		if ( (!($servers[3] =~ /Connected/)) && (!($servers[3] =~ /Local/)) ) {
			$critical++;
			$text = $text." and ".$servers[3]."; ";
		}
	}
	
	if ($critical >= 1) {
		print "CRITICAL: $text\n";
		exit (2);
	}
	else {
		print "OK: $text\n";
		exit (0);
	}
}
