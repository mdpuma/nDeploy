#!/usr/bin/env perl

#use strict;
use warnings;

use YAML::Tiny;
use Getopt::Long;
use Data::Dumper;
use YAML::Tiny;

#my @PHPFPM_BACKENDS=();
my @PHPFPM_BACKENDS=("5.4", "5.6", "7.0");
my $date = `date`;
chomp($date);

sub free_fpm_sockets{
	my $PREFIX = shift;
	my $PIDS = `lsof $PREFIX/var/run/\*.sock 2>/dev/null | grep -v COMMAND | awk '{ print \$2}' | sort -u`;
	my @PID = split(/\n/, $PIDS);
	foreach(@PID) {
		chomp;
		kill(9, $_);
		print "Killed php-fpm($_)\n";
	}
}

sub check_nginx{
	# check nginx /status
	my $URL = "http://localhost:808/nginx-status";
	my $RESPONSE = `curl --max-time 15 $URL 2>/dev/null | xargs`;
	chomp($RESPONSE);
	print "[$date] URL=$URL Response=$RESPONSE\n";
	unless($RESPONSE =~ /^Active connections:/) {
		print STDERR "Restarted nginx\n";
		if(-d "/etc/systemd") {
			system("systemctl restart nginx");
		} else {
			system("/etc/init.d/nginx restart");
		}
	}
}

sub check_phpfpm{
	# check php-fpm /status
	foreach $VER(@PHPFPM_BACKENDS) {
		my $URL = "http://localhost:808/ping$VER";
		my $RESPONSE=`curl --max-time 15 $URL 2>/dev/null`;
		chomp($RESPONSE);
		print "[$date] URL=$URL Response=$RESPONSE\n";
		if($RESPONSE ne "pong") {
			print STDERR "No pong response, restarted php-$VER\n";
			system("/opt/nDeploy/scripts/init_backends.pl --action=restart --forced --php=$VER");
		}
	}
	
	# check pid
	my $yaml_parsed = YAML::Tiny->read('/opt/nDeploy/conf/backends.yaml');
	my $ref_php = $yaml_parsed->[0]->{'PHP'};
	my %php = %$ref_php;
	for my $VER (keys %php) {
		my $pid_file = $php{$VER}.'/var/run/php-fpm.pid';
		system("ps -p `cat $pid_file 2>/dev/null` >/dev/null 2>&1");
		if($? ne 0) {
			free_fpm_sockets($php{$VER});
			print STDERR "No process pidfile, restarted $VER\n";
			$VER =~ s/php-//;
			system("/opt/nDeploy/scripts/init_backends.pl --action=restart --forced --php=$VER");
		}
	}
}

sub check_watcher{
	# check pid
	system("ps -p `cat /opt/nDeploy/watcher.pid 2>/dev/null` >/dev/null 2>&1");
	if($? ne 0) {
		print STDERR "Restarted ndeploy_watcher\n";
		if(-d "/etc/systemd") {
			system("systemctl restart ndeploy_watcher");
		} else {
			system("/etc/init.d/ndeploy_watcher restart");
		}
	}
}

check_phpfpm
check_nginx
check_watcher