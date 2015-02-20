LH2MonKey
=========

Process transactions for [Lufthansa Mile&More credit cards][https://www.miles-and-more-kreditkarte.com] as downloaded from their clients portal as CSV files, generate extra transactions reflecting foreign use surcharges, and import everything into the [MonKey Office][http://www.monkey-office.de] accounting software.

Why does this project exist?
----------------------------

The Mile&More transaction statement informs about foreign use surcharges in additional columns. Effectively this gives you two transactions in one line: the actual purchase, and the foreign use surcharge. MonKey Office will however only import a single transaction per line. Hence, the CSV files downloaded from Miles&More are not directly usable with MonKey Office.

How does it work?
-----------------

The **AWK script** LH_split parses the CSV file from the Miles&More website, splits transactions subject to foreign use surcharge (hence the name), and inserts extra transactions reflecting those extra charges. It is capable of processing the pre-2015 transaction format, and the 2015 transaction format which adds a new column indicating AidA transactions. In its output, the AidA column is removed for compatibility with the MonKey Office import definition. You can either run the AWK script manually, or as part of your own shell script. Simply redirect its output to a new file, and ignore stderr.

The **MonKey Office import definition** parses the pre-2015 CSV format from Miles&More, and the output of the LH-split awk script. Add a new bank statement import definition in MonKey Office, give it a calling name, and use the contents of the text file as the import script. Further details in the MonKey Office manuals.

How do I install it?
--------------------

Call the AWK script manually, redirecting stdout to a new file, and import that new file as a bank account statement in MonKey Office.

AppleScript automation does unfortunately not seem possible, since I am not aware of any AppleScript support in MonKey Office.

How do I contribute?
--------------------

Fork this project, make some changes and submit a pull request. Check the issues tab for inspiration on what to fix. Please make sure your fork is the latest development version!

If you find any issues or have a feature request please contribute by submitting an issue here on Github!

Who did make this app?
----------------------

* [c-alpha](https://github.com/c-alpha)

Change log
----------

2015-02-20 - **v1.0**

* First commit. ([c-alpha](https://github.com/c-alpha))
