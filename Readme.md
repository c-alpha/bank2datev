# bank2datev 🏦💳 #

Process transactions in CSV-ish formats from payment services and
financial institutions, such as for instance credit card operators and
banks, convert them into [DATEV
ASCII-Weiterverarbeitungsdatei](https://apps.datev.de/help-center/documents/9226961)
format, and import that into the [MonKey
Office](http://www.monkey-office.de) accounting software.

## Why Does This Project Exist? ##

Back in 2010 when I started my business, the Miles&More CSV
transaction statement informed about foreign use surcharges in
additional columns. Effectively this gave you two transactions in one
line: the actual purchase, and the foreign use surcharge. MonKey
Office will however import a single transaction per line only; no way
to generate two transactions from a single line of input. Hence, the
CSV files downloaded from the Miles&More credit card website were not
directly usable with MonKey Office. The solution idea was quite
simple: parse the Miles&More CSV, detect foreign use surcharges, and
insert new transactions for those charges. This is how the script
started.

Over time, Miles&More inevitably kept making changes to their CSV
format:

| CSV format version | Usage Period                                                                       | Remarks                                                                                                                                                                                                  |
|--------------------|------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 2014               | Historical format in use from (at least) 2010 until end 2014, and again after 2015 | no AidA column                                                                                                                                                                                           |
| 2015               | Historical format in use in 2015                                                   | inserts a new AidA column as column number three (i.e. between "R.-Datum" and "R.-Pos.")                                                                                                                 |
| 2017               | Historical format in use starting July 2017                                        | inserts a credit card number column of the form "123456xxxxxx1234" at the beginning of each line                                                                                                         |
| 2018               | Historical format in use starting April 2018                                       | new header structure with empty lines, format reduced to eight columns (previous formats had 19), already contains foreign use surcharges as separate transactions, fields are enclosed in double quotes |
| 2023               | Current format in use sicnce the website relaunch in summer 2023                   | reduced header structure, new order of columns, fields are unquoted again (cf. 2018 format)                                                                                                              |

The `mm2datev` script recognises all above listed historical and
current formats, and processes them. Thus, in case you should still
have any historical data to work with, it will still generate output
for those.


## How Does It Work? ##


### `mm2datev` ###

The **AWK script** `mm2datev` parses a CSV file from the [Lufthansa
Mile&More credit card
website](https://www.miles-and-more-kreditkarte.com), splits
transactions subject to foreign use surcharge and inserts extra
transactions reflecting those extra charges as needed. You can either
run the AWK script manually:

```console
user@example$ mm2datev <mm-data.csv >monkey-data.txt
Detected 2023 website relaunch file format.
Converted 141 transactions to DATEV format.
```

Or, when using it as part of your own shell script, simply redirect
its output to a new file, and ignore `stderr`:

```bash
#!/usr/bin/env bash
# ...

mm2datev <${infile} >${outfile} 2>/dev/null
```

**Note well** that the generated output data will **not** include those
transactions where the credit card's expenses are recovered from the linked bank
account once a month (booking text "Lastschrift"). As it is assumed
that the linked bank account's transactions will also be imported into
MonKey Office, importing the "Lastschrift" transactions from the
credit card would double up these transactions, resulting in double
bookings in MonKey Office. Dropping them in `mm2datev` avoids such
double bookings.

**The format of the generated data will depend on the format of the
input data:**

  * **When processing historical (i.e. pre-2023) Miles&More CSV
    data,** the generated output will be in the same format as the
    2014 input format. To import this into MonKey Office, use the
    `import-miles-and-more-credit-card.txt` import definition.

  * **When processing current 2023 format Miles&More CSV data,** the
    generated output will be in [DATEV
    ASCII-Weiterverarbeitungsdatei](https://apps.datev.de/help-center/documents/9226961)
    format. To import this into MonKey Office, use the
    `import-datev-ascii-weiterverarbeitungsdatei.txt` import
    definition.

Why the change of output format? 

Because I wanted to start using a standardised format, which gives me
some interoperability between different accounting tools. 

Why the DATEV format? 

After a period of experimenting with CAMT.053 XML (which is [an ISO
standard](https://www.iso20022.org/iso-20022-message-definitions)), my
conclusion was that the levels of XML support in the banking and
accounting tools relevant to my workflow, were too different to be
both robust and practical enough for everyday use. DATEV file formats,
on the other hand, are a de-facto standard among tax advisers in the
German speaking countries. Consequently, all banking and accounting
tools targeting these countries will all but certainly have some
built-in support for DATEV format files.


### `bx2datev` ###

The **AWK script** `bx2datev` parses an exported CSV file from the
[Banx X banking app for
macOS](https://www.application-systems.de/bankx/), and converts them
to the same [DATEV
ASCII-Weiterverarbeitungsdatei](https://apps.datev.de/help-center/documents/9226961)
format for further processing. The Bank X app can export transactions
in various formats. `bx2datev` reads files exported as "komplette
Buchungen" from Bank X, since in this format Bank X exports the
most information for each transaction.

You can either run the AWK script manually:

```console
user@example$ bx2datev <bx-data.csv >monkey-data.txt
Converted 89 transactions to DATEV format.
```

Or, when using it as part of your own shell script, simply redirect
its output to a new file, and ignore `stderr`:

```bash
#!/usr/bin/env bash
# ...

bx2datev <${infile} >${outfile} 2>/dev/null
```


## How Do I Install and Use It? ##

First, create new bank account statement import definitions in MonKey
Office:
1. In MonKey Office, create a new bank account statement import
   definition called "Miles&More Credit Card". Keep the import
   definition editor dialogue open.
2. Copy and paste the contents of the
   `import-miles-and-more-credit-card.txt` file into the text editor
   area of the import definition editor dialogue. Keep it open.
3. Set the values of the five settings across the top of the import
   definition editor dialogue according to the comment block at the
   start of the `import-miles-and-more-credit-card.txt` file.
4. Click "Ok" to close the import definition editor dialogue, and save
   the new import definition.
5. Repeat steps 1 through 4 to create a second new bank account
   statement import definition called "DATEV
   ASCII-Weiterverarbeitungsdatei", and this time copying and pasting
   the contents of the
   `import-datev-ascii-weiterverarbeitungsdatei.txt` file.

Now you can call one of the AWK scripts manually, redirecting `stdout`
to a new file, and then import that new file as a bank account
statement in MonKey Office, using the corresponding import definition.

A Miles&More 2023 data format caveat:
  * As of this writing, there is no option on the Miles&More credit
    card website to restrict the period for which transactions will be
    put in the CSV file. You will always get the full transaction list
    as displayed in your browser window. To get transactions for a
    specific period only, you will need to filter the generated data.
    For instance by using `awk` to extract all transactions with a
    transaction date in April 2023 before passing the data to `mm2datev`:
    ```console
    user@example$ awk -F";" '$1 ~ /[0-9]{2}\/04\/2023/' mm-data.csv | mm2datev >monkey-data-2023-04.txt
    Detected 2023 website relaunch file format.
    Converted 13 transactions to DATEV format.
    ```
    
A general DATEV format caveat:
  * The DATEV format output is 99.999% compliant with the [DATEV
    ASCII-Weiterverarbeitungsdatei](https://apps.datev.de/help-center/documents/9226961)
    format specification. Where is the missing 0.001%? The DATEV
    format specification requires that all bank transactions within
    any given file must be sorted in ascending order by booking date
    (i.e. oldest entry first). The scripts do not ensure this sorting,
    however. They will simply generate the transactions in whatever
    order they appear in the input. To get 100%, you will need to sort
    the output. For instance:
    ```console
    user@example$ mm2datev <mm-data.csv >monkey-data.txt
    Detected 2023 website relaunch file format.
    Converted 141 transactions to DATEV format.
    user@example$ sort -n -t ";" -k 6.7,6.10 -k 6.4,6.5 -k 6.1,6.2 -o monkey-data.txt monkey-data.txt
    ```

## How Do I Contribute? ##

Fork this project, make some changes and submit a pull request. Check
the issues tab for inspiration on what to fix. Please make sure your
fork is the latest development version!

If you find any issues or have a feature request please contribute by
submitting an issue here on Github!
