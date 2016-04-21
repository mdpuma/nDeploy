#!/usr/bin/env perl

#use strict;
use warnings;

use YAML::Tiny;
use Getopt::Long;
use Data::Dumper;
use YAML::Tiny;

my @PHPFPM_BACKENDS=("5.3", "5.4", "5.6");
my $date = `date`;
chomp($date);

sub check_nginx{
	my $URL = "http://localhost:808/nginx-status";
	my $RESPONSE = `curl --max-time 15 $URL 2>/dev/null | xargs`;
	chomp($RESPONSE);
	print "[$date] URL=$URL Response=$RESPONSE\n";
	unless($RESPONSE =~ /^Active connections:/) {
		if(-d "/etc/systemd") {
			system("systemctl restart nginx");
		} else {
			system("/etc/init.d/nginx restart");
		}
		print STDERR "Restarted nginx\n";
	}
}

sub check_phpfpm{
	# check pid
	my $yaml_parsed = YAML::Tiny->read('/opt/nDeploy/conf/backends.yaml');
	my $ref_php = $yaml_parsed->[0]->{'PHP'};
	my %php = %$ref_php;
	for my $VER (keys %php) {
		my $pid_file = $php{$VER}.'/var/run/php-fpm.pid';
		system("pgrep -F $pid_file >/dev/null 2>&1");
		if($? ne 0) {
			system("/opt/nDeploy/scripts/init_backends.pl --action=restart --forced --php=$VER");
			print STDERR "No process pidfile, restarted php-$VER\n";
		}
	}
	
	# check php-fpm /status
	foreach $VER(@PHPFPM_BACKENDS) {
		my $URL = "http://localhost:808/ping$VER";
		my $RESPONSE=`curl --max-time 15 $URL 2>/dev/null`;
		chomp($RESPONSE);
		print "[$date] URL=$URL Response=$RESPONSE\n";
		if($RESPONSE ne "pong") {
			system("/opt/nDeploy/scripts/init_backends.pl --action=restart --forced --php=$VER");
			print STDERR "No pong response, restarted php-$VER\n";
		}
	}
}

sub check_watcher{
	system("pgrep -F /opt/nDeploy/watcher.pid >/dev/null 2>&1");
	if($? ne 0) {
		if(-d "/etc/systemd") {
			system("systemctl restart ndeploy_watcher");
		} else {
			system("/etc/init.d/ndeploy_watcher restart");
		}
		print STDERR "Restarted ndeploy_watcher\n";
	}
}

check_nginx
check_phpfpm
check_watcher