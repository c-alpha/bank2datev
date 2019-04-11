LH2MonKey
=========

Process transactions from
[Lufthansa Mile&More credit cards](https://www.miles-and-more-kreditkarte.com)
as downloaded from their clients portal as CSV files, generate extra
transactions reflecting foreign use surcharges, and import everything
into the [MonKey Office](http://www.monkey-office.de) accounting
software.

Why does this project exist?
----------------------------

The Mile&More transaction statement informs about foreign use
surcharges in additional columns. Effectively this gives you two
transactions in one line: the actual purchase, and the foreign use
surcharge. MonKey Office will however only import a single transaction
per line. Hence, the CSV files downloaded from Miles&More are not
directly usable with MonKey Office.

**Update April 2018:** DKB have introduced an all new CSV format,
which provides the foreign use surcharges as separate transactions
already; hence they don't need to be generated for the 2018
format. The scripts have been updated to convert the 2018 format data
into a format that can be imported into MonKey Office. The AWK script
auto-recognises the input format and behaves accordingly. Effectively
this means you can keep your workflow unchanged, and will still be
able to process DKB's CSV files, regardless when you downloaded them,
and including the new 2018 format.

How does it work?
-----------------

The **AWK script** LH_split parses the CSV file from the Miles&More
website, splits transactions subject to foreign use surcharge (hence
the name), and inserts extra transactions reflecting those extra
charges. It is capable of processing the pre-2015 transaction format,
the 2015 transaction format which adds a new column indicating AidA
transactions, the 2017 transaction format which adds a new first
column containing a pseudonymized form of the credit card number used
for the purchase, and the 2018 format introduced along with the DKB
system upgrade. In the output, the AidA and credit card number columns
(if and when present) are removed for compatibility with the MonKey
Office import definition. You can either run the AWK script manually,
or as part of your own shell script. Simply redirect its output to a
new file, and ignore stderr.

The **MonKey Office import definition** parses the pre-2015 CSV format
from Miles&More, and the output of the LH-split awk script. To use it,
add a new bank statement import definition in MonKey Office, give it a
calling name, and use the contents of the text file in this repo as
the import script. As a further consistency check, the import script
compares the Miles&More member number found in the transaction records
with what you have set as the bank account number of the account in
MonKey Office. Further details in the MonKey Office manuals.

**Update April 2018:** Since the Miles&More member number is absent
from the 2018 format, it is no longer possible to provide it in the
output of the LH-split awk script. The MonKey Office import definition
has hence been updated to compare the Miles&More member number against
bank account number of the account in MonKey Office only if and when
the Miles&More member number is present in the file to import.

How do I install it?
--------------------

Call the AWK script manually, redirecting stdout to a new file, and
import that new file as a bank account statement in MonKey Office.

AppleScript automation does unfortunately not seem possible, since I
am not aware of any AppleScript support in MonKey Office.

How do I contribute?
--------------------

Fork this project, make some changes and submit a pull request. Check
the issues tab for inspiration on what to fix. Please make sure your
fork is the latest development version!

If you find any issues or have a feature request please contribute by
submitting an issue here on Github!

Who did make this app?
----------------------

* [c-alpha](https://github.com/c-alpha)

Change log
----------

2019-04-11 - **v1.2**

* DKB upgraded their systems, resulting in a new website design, and
  an all new CSV export format ([c-alpha](https://github.com/c-alpha))

2017-07-10 - **v1.1**

* DKB added a new first column to their export format as of July 2017 ([c-alpha](https://github.com/c-alpha))

2015-02-20 - **v1.0**

* First commit. ([c-alpha](https://github.com/c-alpha))
