#!/usr/bin/perl

# TODO:  quando un gruppo viene cancellato, nel database cambia "tipo"
#        e da "group" diventa "group-deleted".
#        questo fa casino, perchè il gruppo esiste, ma è cancellato.
#        bisogna gestire correttamente questa cosa


use strict;
use Getopt::Long;
use esmith::AccountsDB;
use esmith::event;
use File::Temp qw(tempfile);

my $file;
my $separator = "\t";
my $add_existing_users_to_groups;
my $user_already_exists;
my $displayHelp;
my $accountsDb = esmith::AccountsDB->open() || die("Could not open accounts DB");

GetOptions (
  "file=s" => \$file,
  "separator=s" => \$separator,
  "add_existing_users_to_groups"  => \$add_existing_users_to_groups,
  "help" => \$displayHelp
  ) or displayHelp();

if ( $displayHelp ) {
  displayHelp();
}

if ( $file ) {
    open(FH, "<", $file) or die;
} else {
    open(FH, "-");
}

while(<FH>) {

    # Remove trailing whitespace:
    chomp $_;
    $_ =~ s/\s+$//;

    my ($username, $firstName, $lastName, $password, @groups) = split(/$separator/, $_);

    if( ! $username) {
        next;
    }

    if( ! $firstName) {
        warn "[WARNING] Account `$username` is missing FirstName column: skipped.\n";
        next;
    }

    if( ! $lastName) {
        warn "[WARNING] Account `$username` is missing LastName column: skipped.\n";
        next;
    }

    $user_already_exists = 0;
    if($accountsDb->get($username)) {
        warn "[WARNING] Account `$username` already registered: skipped.\n";
        if ( ! $add_existing_users_to_groups ) {
          next;
        } else {
          $user_already_exists = 1;
        }
    }

    foreach my $group (@groups) {
      if(!$accountsDb->get($group)) {
          my $groupRecord = $accountsDb->new_record($group, {
            'type' => 'group'
          });
          warn "[INFO] created group $group.\n";
      }
    }

    if ( ! $user_already_exists ) {

      my $record = $accountsDb->new_record($username, {
          'type' => 'user',
          'FirstName' => $firstName,
          'LastName' => $lastName,
          'Samba' => 'enabled'
      });

      if( ! $record ) {
          warn "[ERROR] Account `$username` record creation failed.\n";
          next;
      }

      if( ! esmith::event::event_signal('user-create', $username) ) {
          warn "[ERROR] Account `$username` user-create event failed.\n";
          next;
      }

      if($password) {
          my ($pfh, $pfilename) = tempfile('import_users_XXXXX', UNLINK=>0, DIR=>'/tmp');
          print $pfh $password;
          close($pfh);

          if( ! esmith::event::event_signal('password-modify', $username, $pfilename) ) {
              warn "[ERROR] Account `$username` user-create event failed.\n";
              next;
          }
          unlink $pfilename;
      }

    }

    foreach my $group (@groups) {
      $accountsDb->add_user_to_groups($username, $group);
    }

    warn "[INFO] imported $username\n";

}


sub displayHelp {
   die("Usage: $0 [--file INPUTFILE] [--separator SEPARATOR] [--add_existing_users_to_groups]\n");
}
