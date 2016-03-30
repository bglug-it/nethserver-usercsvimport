# nethserver-usercsvimport
Batch import a lot of users and groups.
You need a CSV file with this layout:

    username Firstname Lastname password group1 [group2] [group3] [groupN]

See test.csv file for a sample.
You can use the TAB as a separator (this is the default), or whatever character you want.
Beware that Microsoft Excel uses the semicolon (;) as a separator instead the comma (,) for a CSV file (COMMA separated value).

To import, simply call the script passing the input file as STDIN or via the --file switch.

    ./importa_utenti.pl [--file INPUTFILE] [--separator SEPARATOR] [--add_existing_users_to_groups]

Some examples:

    ./importa_utenti.pl < test.csv
    ./importa_utenti.pl --file test.csv --separator ";"
    cat test.csv | ./importa_utenti.pl --separator "," --add_existing_users_to_groups

You can specify a custom field separator.
The import process will create all non-existing groups. If the user already exists and the "add_existing_users_to_groups" switch is NOT set, then the line is skipped (so if you specify a nonexistent group for this user, the group won't be created). If you enable "add_existing_users_to_groups" and the user is already present, the nonexisting groups are created and the user is assigned to all the specified groups.
