import options

type Link* = object
  src*: string
  dst*: string

type Config* = object
  extends*: Option[seq[string]]
  mount*: Option[seq[string]]
  romount*: Option[seq[string]]
  symlinks*: Option[seq[Link]]
