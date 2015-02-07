/// represent the types of commands that can be run
module command;

/// type of action to take
enum CommandType {
  create, /// record a new transaction
  query   /// retrieve information on previous transactions
}

/// keywords used to identify transaction and query parameters
enum CommandKeyword {
  amount, /// the quantity of money in a transaction
  source, /// the source (sender) of a transaction
  dest  , /// the destination (recipient) of a transaction
  date  , /// to date on which a transaction occured
  note  , /// a note about the transaction
}
