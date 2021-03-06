#!/usr/local/bin/perl -w

use strict;
use lib "/home/k/PAUSE/lib";
use Getopt::Long;
use PAUSE;
use DBI;

my %Opt;
GetOptions(\%Opt,
           "dry-run|n",
          ) or die;

my $user = shift @ARGV or die "Usage: $0 user";

my $db = DBI->connect(
		      $PAUSE::Config->{AUTHEN_DATA_SOURCE_NAME},
		      $PAUSE::Config->{AUTHEN_DATA_SOURCE_USER},
		      $PAUSE::Config->{AUTHEN_DATA_SOURCE_PW},
		      {RaiseError => 1}
		     );
my $sth = $db->prepare(qq{SELECT password FROM usertable WHERE user=?});
my $ret = $sth->execute(uc $user);

die "User '$user' not found" unless $sth->rows > 0;
die "Panic: more than one user '$user'" if $sth->rows > 1;

my($passwd) = $sth->fetchrow_array;
$sth->finish;
$db->disconnect;

my $lcuser = lc $user;
if ($Opt{"dry-run"}) {
    warn "WOULD now call
  adduser --group $lcuser
  adduser --ingroup $lcuser --disabled-login $lcuser
WOULD then recommend to call
  vipw -s
and set the crypted password of '$lcuser' to '$passwd'\n";
} else {
    my @system = ("adduser", "--group", $lcuser);
    $ret = system @system;
    die "'@system' returned bad status: '$ret'" if $ret;
    @system = ("adduser", "--ingroup", $lcuser, "--disabled-login", $lcuser);
    $ret = system @system;
    die "'@system' returned bad status: '$ret'" if $ret;
    print "please run
    vipw -s
now and set the crypted password of '$lcuser' to '$passwd'\n";
}
