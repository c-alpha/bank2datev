#!/usr/bin/awk -f
BEGIN {
    FS=";";
    aida_col=0;
    cc_col=0;
    num_foreign=0;
}

# retain lines that are not transactions (i.e. no transaction ID in
# first column)
( ! match($1, "^[0-9]+.*$")) {
    print $0;
}

# detect new format 2015 which inserts AidA column as #3 between
# "R.-Datum" and "R.-Pos."
# (NOTE: this format was dropeed again after 2015 END NOTE)
match($1, "Rechnung") && match($3, "A.I.D.A. Transaktion") {
    aida_col=1;
    print "[Detected 2015 file format with AidA information.]" >"/dev/stderr";
}

# detect new format as of July 2017 which inserts a credit card number
# column of the form "123456xxxxxx1234" at the beginning of each line
match($1, "Kartennummer") && match($2, "Rechnung") {
    cc_col=1;
    print "[Detected 2017 file format with credit card number column.]" >"/dev/stderr";
}

# old format til end 2014, and used again after 2015
match($1, "^[0-9]+$") && (aida_col==0) {
    # keep the original transaction
    print $0;
    if (NF>14) {
        num_foreign++;
        # if foreign use surcharge incurred, generate a new
        # transaction for the additional fee
        print $1";"$2";"$3";"$4";"$5";Ausl.geb. "$6";"$7";"$17";"$18";S;1;"$17";"$18";S";
    }
}

# new format during 2015
match($1, "^[0-9]+$") && (aida_col==1) {
    # keep the original transaction, but remove AidA column
    print $1";"$2";"$4";"$5";"$6";"$7";"$8";"$9";"$10";"$11";"$12";"$13";"$14";"$15";"$16";"$17";"$18";"$19;
    if (NF>15) {
        num_foreign++;
        # if foreign use surcharge incurred, generate a new
        # transaction for the additional fee
        print $1";"$2";"$4";"$5";"$6";Ausl.geb. "$7";"$8";"$18";"$19";S;1;"$18";"$19";S";
    }
}

# new format starting July 2017
match($1, "^[0-9]{6}[x]{6}[0-9]{4}$") && (cc_col==1) {
    # keep the original transaction
    print $0;
    if (NF>15) {
        num_foreign++;
        # if foreign use surcharge incurred, generate a new
        # transaction for the additional fee
        print $1";"$2";"$3";"$4";"$5";"$6";Ausl.geb. "$7";"$8";"$18";"$19";S;1;"$18";"$19";S";
    }
}

END {
    print "[Generated "num_foreign" transactions for foreign use surcharges.]" >"/dev/stderr";
}
