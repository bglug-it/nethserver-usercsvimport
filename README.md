# nethserver-usercsvimport
Batch import a lot of users and groups.
You need a CSV file with this layout:

    username Firstname Lastname password group1 [group2] [group3] [groupN]

See test.csv file for a sample.
You can use the TAB as a separator (this is the default), or whatever character you want.
Beware that Microsoft Excel uses the semicolon (;) as a separator instead the comma (,) for a CSV file (COMMA separated value).

To import, simply call the script passing the input file as STDIN or via the --file switch.

    ./importa_utenti.pl [--file INPUTFILE] [--separator SEPARATOR] [--add_existing_users_to_groups] [--remove_users]

Some examples:

    ./importa_utenti.pl < test.csv
    ./importa_utenti.pl --file test.csv --separator ";"
    cat test.csv | ./importa_utenti.pl --separator "," --add_existing_users_to_groups

You can specify a custom field separator.
The import process will create all non-existing groups. If the user already exists and the "add_existing_users_to_groups" switch is NOT set, then the line is skipped (so if you specify a nonexistent group for this user, the group won't be created). If you enable "add_existing_users_to_groups" and the user is already present, the non-existing groups are created and the user is assigned to all the specified groups.

If you specify a group name which starts with a "-" (dash), then the user will be removed from that group. This feature is working even if you don't enable "add_existing_users_to_groups".

To remove users you can use the same .CSV file you used for creation, or you can provide a file with a users list (one user per line). This file will be parsed for user deletion if you specify the "--remove_users" parameter.
