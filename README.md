Tact
=====

Tact is a simple CLI finanace manager that makes it quick and easy to record and
query transactions.

Recording Transactions
-----

To record a transaction, use a command of the form

```
tact <amount> from <source> to <destination> on <date> for <note>
```

If a date is not specified, it defaults to the current date.
The note defaults to an empty string if not specified

Here are a few examples:

```
tact 125.25 from credit_card to grocery_store on 1/3/15 for "food and stuff" 
tact 300 from savings to credit_card on 1/3/15
tact 250 from payroll to savings
```

Querying Transactions
-----

To list recorded transactions, use a command of the form

```
tact list amount <amount> from <source> to <destination> on <date> for <note>
```

Note that the first argument is the keyword `list` -- this tells `tact` that
you want to list existing transactions rather than create a new one. This
keyword can be changed in the config file, discussed next.

The arguments provided for `source`, `destination`, and `note` for a `list`
command may be provided as globs. Just make sure to escape the globs from
interpretation by your shell (e.g. by quoting).

The arguments provided for `amount` and `date` for a `list` may represent a
range of values. The default delimiter for a range is `,`, which may be chagned
in the config file.

The below example query lists all transactions payed from your account named
"credit\_card" on January 1st 2015 for an amount between 100 and 500 with
a note containing the phrase "grocery".

```
tact list amount 100-500 from credit_card on 1/1/15 for "*grocery*"
```

Configuration
-----
Tact reads custom settings from the file `~/.tactrc`.

Here is an example `.tactrc`, note that all string values **must** be quoted:

```
[general]
storageDir     = "~/.config/tact"
rangeDelimiter = ":"
dateFormat     = "%y/%m/%d"

[alias]
amt  = "amount"
src  = "from"
dst  = "to"
date = "on"
```

`storageDir` determines where `tact` will store transaction data files.
**default: ~/.tact**


`rangeDelimiter` is a string used to separate value ranges in the amount and date query arguments.
For example, if `rangeDelimiter` = `,`, then the query argument `amount 100,300` would include
transactions whose amounts fall between 100 and 300.
**default: -**


`dateFormat` is the format used to parse and print dates. See `man strftime` for format options.
**default: %m/%d/%y**


The `alias` section allows you to define your own keywords to use.
The left side of an alias entry is your keyword, the right side is the default keyword it maps to.

Storage
-----
Tact stores data in json files at a location determined by the `storageDir`
setting in your `tactrc` (which defaults to `~/.tact`.

When storing a transaction, `tact` creates a subdirectory for the year and a
file for the month. For example, using the default storage dir, a transaction
that occured on 2015-05-22 would be found in the file `~/.tact/2015/5.json`. 
