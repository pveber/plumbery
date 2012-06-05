Plumbery
========

This library can be used to evaluate a function application on a
cluster of machines running a Portable Batch Submission (PBS) system,
like Torque. This functionality is offered by an `eval` function of
type:

```
val eval : ('a -> 'b) -> 'a -> 'b Lwt.t
```

In brief, the closure and its argument are marshalled to another
process which is invoked through a `qsub` command. The result is
provided through a lwt thread.

Beware, this code is very naive and preliminary, but it's already
something.

Contributions and comments are of course welcomed.
