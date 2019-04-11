#!/usr/bin/awk -f
BEGIN {
    FS=";";
    num_foreign=0;
    fmt_2014=0;
    fmt_2015=0;
    fmt_2017=0;
    fmt_2018=0;
}

function unquote(str) {
    return (substr(str, 2, length(str)-2));
}

function isodate(str) {
    split(str, date, ".");
    return (sprintf("%04d-%02d-%02d", date[3], date[2], date[1]));
}

###
#   Format detection heurtistics
#

# detect old format til end 2014, and used again after 2015 (no AidA
# column)
(NR==4) && match($1, "Rechnung") && ( ! match($3, "A.I.D.A. Transaktion")) {
    fmt_2014=1;
    print "[Detected pre/post-2015 file format.]" >"/dev/stderr";
}

# detect new format 2015 which inserts AidA column as #3 between
# "R.-Datum" and "R.-Pos."
# (NOTE: this format was dropeed again after 2015 END NOTE)
(NR==4) && match($1, "Rechnung") && match($3, "A.I.D.A. Transaktion") {
    fmt_2015=1;
    print "[Detected 2015 file format with AidA information.]" >"/dev/stderr";
}

# detect new format as of July 2017 which inserts a credit card number
# column of the form "123456xxxxxx1234" at the beginning of each line
(NR==4) && match($1, "Kartennummer") && match($2, "Rechnung") {
    fmt_2017=1;
    print "[Detected 2017 file format with credit card number column.]" >"/dev/stderr";
}

# detect new format as of April 2018 (introduced with major system update)
# new features:
#  - new header structure with empty lines
#  - format reduced to eight columns (old formats had 19)
#  - already contains foreign use surcharges as separate transactions
#  - fields are enclosed in double quotes
(NR==1) && match($1, "Kreditkarte:") {
    fmt_2018=1;
    card_number=unquote($2);
    print "[Detected 2018 post system update file format.]" >"/dev/stderr";
}
(fmt_2018==1) && (NR==5) && match($1, "Datum:") {
    invoice_date=isodate(unquote($2));
}


###
#   Generate header lines
#

# retain lines that are not transactions (i.e. no transaction ID in
# first column) from pre-2018 formats
(fmt_2018==0) && ( ! match($1, "^[0-9]+.*$")) {
    print $0;
}

# for the 2018 file format, generate a legacy header to remain
# compatible with the MonKey Office import script
(fmt_2018==1) && (NR==7) {
    print "Kartennummer(n);'" card_number "'";
    print "Servicekartennummer(n);";
    print ";;;;"
    print "Rechnung;R.-Datum;R.-Pos.;Kaufdatum;Buch.Datum;Umsatzbeschreibung;;VK-Währung;VK-Betrag;Soll/Haben;Kurs;Abr-Währung;Abgerechnet;Soll/Haben"
}


###
#   Generate transaction lines
#

# format til end 2014, and used again after 2015 (no AidA column)
(fmt_2014==1) && match($1, "^[0-9]+$") {
    # keep the original transaction
    print $0;
    if (NF>14) {
        num_foreign++;
        # if foreign use surcharge incurred, generate a new
        # transaction for the additional fee
        print $1";"$2";"$3";"$4";"$5";Ausl.geb. "$6";"$7";"$17";"$18";S;1;"$17";"$18";S";
    }
}

# format during 2015 (with AidA column)
(fmt_2015==1) && match($1, "^[0-9]+$") {
    # keep the original transaction, but remove AidA column
    print $1";"$2";"$4";"$5";"$6";"$7";"$8";"$9";"$10";"$11";"$12";"$13";"$14";"$15";"$16";"$17";"$18";"$19;
    if (NF>15) {
        num_foreign++;
        # if foreign use surcharge incurred, generate a new
        # transaction for the additional fee
        print $1";"$2";"$4";"$5";"$6";Ausl.geb. "$7";"$8";"$18";"$19";S;1;"$18";"$19";S";
    }
}

# format starting July 2017
(fmt_2017==1) && match($1, "^[0-9]{6}[x]{6}[0-9]{4}$") {
    # keep the original transaction but remove credit card column
    print $2";"$3";"$4";"$5";"$6";"$7";"$8";"$9";"$10";"$11";"$12";"$13";"$14";"$15";"$16";"$17";"$18";"$19;
    if (NF>15) {
        num_foreign++;
        # if foreign use surcharge incurred, generate a new
        # transaction for the additional fee
        print $2";"$3";"$4";"$5";"$6";Ausl.geb. "$7";"$8";"$18";"$19";S;1;"$18";"$19";S";
    }
}

# format starting April 2018
(fmt_2018==1) && (NR>7) {
    if ($3!="\"Lastschrift\"") {
        line_item_number  = NR-7;
        purchase_date     = isodate(unquote($1));
        booked_date       = isodate(unquote($2));
        description_text  = unquote($3);
        purchase_currency = (match($5, "[A-Z]{3}")) ? substr($5, RSTART, RLENGTH) : "EUR";
        purchase_amount   = (match($5, "[0-9]+,[0-9]{2}")) ? substr($5, RSTART, RLENGTH) : booked_amount;
        debit_or_credit   = (match($4, "^\"-")) ? "S" : "H";
        exhange_rate      = ($6!="\"\"") ? unquote($6) : "1,00";
        booked_currency   = "EUR";
        sub("-", "", $4);
        booked_amount     = unquote($4);
        printf "00000000;%s;%d;%s;%s;%s;;%s;%s;%s;%s;%s;%s;%s;;;;\n",
            invoice_date,
            line_item_number,
            purchase_date,
            booked_date,
            description_text,
            purchase_currency,
            purchase_amount,
            debit_or_credit,
            exhange_rate,
            booked_currency,
            booked_amount,
            debit_or_credit;
        num_foreign++;
    }
}


###
#   Success message
#
END {
    if (fmt_2018==0) {
        print "[Generated "num_foreign" transactions for foreign use surcharges.]" >"/dev/stderr";
    } else {
        print "[Converted "num_foreign" transactions to MonKey Office import format.]" >"/dev/stderr";
    }
}
