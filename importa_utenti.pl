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
my $remove_users;
my $record;
my $user_already_exists;
my $displayHelp;
my $accountsDb = esmith::AccountsDB->open() || die("Could not open accounts DB");

GetOptions (
  "file=s" => \$file,
  "separator=s" => \$separator,
  "add_existing_users_to_groups"  => \$add_existing_users_to_groups,
  "remove_users"  => \$remove_users,
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

    if( ! $firstName && ! $remove_users) {
        warn "[WARNING] Account `$username` is missing FirstName column: skipped.\n";
        next;
    }

    if( ! $lastName && ! $remove_users) {
        warn "[WARNING] Account `$username` is missing LastName column: skipped.\n";
        next;
    }

    $user_already_exists = 0;
    $record = $accountsDb->get($username);
    if($record) {
        if ( $remove_users ) {
            $record->delete;
            warn "[INFO] deleted $username\n";
            next;
        } else {
          if ( ! $add_existing_users_to_groups ) {
            warn "[WARNING] Account `$username` already registered: skipped.\n";
            next;
          } else {
            $user_already_exists = 1;
          }
        }
    }

    if ( $remove_users ) {
        next;
    }

    GRP: foreach my $group (@groups) {
      next GRP if $group =~ /^-/;
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
        if ( $group =~ m/^\-/ ) {
            $group =~ s/^\-//;
            $accountsDb->remove_user_from_groups($username, $group);
            warn "[INFO] $username removed from group $group\n";
        } else {
            $accountsDb->add_user_to_groups($username, $group);
            warn "[INFO] $username added to group $group\n";
        }
    }

    warn "[INFO] imported $username\n";

}


sub displayHelp {
   die("Usage: $0 [--file INPUTFILE] [--separator SEPARATOR] [--add_existing_users_to_groups] [--remove_users]\n");
}
