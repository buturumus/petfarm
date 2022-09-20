#!/usr/bin/perl
# make_docker-compose.pl

# find exact name of vpn command
open(FILE, "./vpn.cmds");
  foreach $line (<FILE>) {
    if ($line =~ /^VPN_CMD=/) {
      $vpn_cmd = $';
    };
  };
close FILE;
chomp($vpn_cmd);
# read and subst.raw source's content
open(FILE, "./docker-compose.raw");
  @new_lines = ();
  foreach $line (<FILE>) {
    if ($line =~ /VPN_CMD/) {
      $new_line = $line;
      $new_line =~ s/VPN_CMD/$vpn_cmd/g;
      @new_lines = (@new_lines, $new_line);
    } else {
      @new_lines = (@new_lines, $line);
    };
  };
close FILE;
# write to yml 
open(FILE, ">./docker-compose.yml");
  print FILE @new_lines; 
close FILE;

