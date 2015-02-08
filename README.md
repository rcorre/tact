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
tact 125.25 from credit_card to grocery_store on 2015-01-03 for "food and stuff" 
tact 300 from savings to credit_card on 2015-01-03
tact 250 from payroll to savings
```

Configuration
-----
Tact reads custom settings from the file `~/.tactrc`.

Here is an example `.tactrc` containing the default settings:

```
storageDir = "~/.tact"

[keywords]
amount = amount
source = from
dest   = to
date   = on
note   = for
```

`storageDir` determines where `tact` will store transaction data files.

The `keywords` section allows you to override the custom keywords used to
identify fields in a command. For example, given the following config:

```
[keywords]
source = src
dest   = dst
date   = dt
```

a command might look like:

```
tact 125 src credit_card dst some_shop dt 2014-06-22
```

Storage
-----
Tact stores data in json files at a location determined by the `storageDir`
setting in your `tactrc` (which defaults to `~/.tact`.

When storing a transaction, `tact` creates a subdirectory for the year and a
file for the month. For example, using the default storage dir, a transaction
that occured on 2015-05-22 would be found in the file `~/.tact/2015/5.json`. 
