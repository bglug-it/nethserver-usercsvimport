#!/usr/bin/perl

# TODO:  quando un gruppo viene cancellato, nel database cambia "tipo"
#        e da "group" diventa "group-deleted".
#        questo fa casino, perchè il gruppo esiste, ma è cancellato.
#        bisogna gestire correttamente questa cosa


use strict;

use esmith::AccountsDB;
use esmith::event;
use File::Temp qw(tempfile);

my $file = shift;
my $separator = shift;
my $accountsDb = esmith::AccountsDB->open() || die("Could not open accounts DB");

if($file) {
    open(FH, "<", $file) or die;
} else {
    open(FH, "-");
}

if( ! $separator) {
    $separator = "\t";
}

while(<FH>) {

    # Remove trailing whitespace:
    chomp $_;
    $_ =~ s/\s+$//;

    my ($username, $firstName, $lastName, $group, $password) = split(/$separator/, $_);

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

    if($accountsDb->get($username)) {
        warn "[WARNING] Account `$username` already registered: skipped.\n";
        next;
    }

    if(!$accountsDb->get($group)) {
        my $groupRecord = $accountsDb->new_record($group, {
          'type' => 'group'
        });
        warn "[INFO] created group $group.\n";
    }

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

    $accountsDb->add_user_to_groups($username, $group);

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

    warn "[INFO] imported $username\n";

}
