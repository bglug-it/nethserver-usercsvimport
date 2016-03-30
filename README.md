# nethserver-usercsvimport
Batch import a lot of users and groups.
You need a CSV file with this layout:

    username Firstname Lastname password group1 [group2] [group3] [groupN]

See test.csv file for a sample.
You can use the TAB as a separator (this is the default), or whatever character you want.
Beware that Microsoft Excel uses the semicolon (;) as a separator instead the comma (,) for a CSV file (COMMA separated value).

To import, simply call the script, by passing the CSV file as a parameter and the separator as the second parameter.

    ./importa_utenti.pl test.CSV
    ./importa_utenti.pl test.CSV ";"
    ./importa_utenti.pl test.CSV ","

The import process will create all non-existing groups. If the user already exists then the line is skipped (so if you specify a nonexistent group for this user, the group won't be created).
