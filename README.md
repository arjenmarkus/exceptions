# Experiment with exceptions

Adding exceptions to the Fortran language has been on the wishlist for a long time. Apparently,
exceptions can have a large impact on the performance, even if the code itself does not use them.

The experiment presented here illustrates a very simple approach to exceptions, but it does not pretend
to provide a definitive solution. It is, after all, an experiment and the code that uses the approach
is very limited.

Furthermore, the preprocessor is very limited: it works for a particular style only -- the keywords are precisely
"try", "endtry", "catch" and "throw" (no uppercase or "end try") and only calls to subroutines are treated.


# How it works

To support such syntax as "try" and "catch" a preprocessor is used (`prepare_exceptions.f90`). It takes the
name of a source file and writes the processed code to another file (`_` + filename).

The preprocessor converts code like:

```fortran
    try
        call subx( ... )
        call suby( ... )
        write(*,*) 'Answer: ',x, y
    catch (exception_overflow)
        write(*,*) 'Overflow occurred'
    catch (exception_invalid)
        write(*,*) 'Instance of parameter out of range: ', exception%name
    end try
```

into (edited for consistent indentation):

```fortran
do
    call subx( ... )
    if ( exception_raised ) exit
    call suby( ... )
    if ( exception_raised ) exit
        write(*,*) 'Answer: ',x, y
    exit
enddo
if ( exception_raised ) then
   select type (exception_data)
       type is  (exception_overflow)
           write(*,*) 'Overflow occurred'
       type is  (exception_invalid)
           write(*,*) 'Instance of parameter out of range: ', exception%name
   endselect
endif
```

Summarising:

* The transformation is limited to the lines in a `try` block
* The `try` block up to the first `catch` statement is enclosed in a do-loop, so that we can jump out
  without a `goto` statement
* Exception types are actually derived types extended from the base class `exception_base_type`, so that the
  `select typ` construct can handle each `catch` block in turn.
* A `throw` statement `throw ex_refused('x out of range')` is turned into code like:

```fortran
    exception_raised   = .true.
    exception_data     =  ex_refused('x out of range')
    exception_lineno   = ...
    exception_filename = 'filename.f90'
    return
```

*Important:* for this to work properly, all code that may throw and catch an exception must be properly
preprocessed. The implementation depends on cooperation. This makes it lightweight, as it can be realised
within the bounds of the current Fortran standard, but any code that is not preprocessed will hinder the
operation.

# Source files

`prepare_expections.f90` -- limited preprocessor, transforms the given source files

`example.f90` - straightforward program, using exceptions. If the random number is out of range, an exception is thrown.

`exceptions.f90` - basic implementation of an exceptions module

# Building the example

First build the preprocessor program in `prepare_expections.f90`

Then preprocessor the source file `example.f90`, the result is `_example.f90`

Together with the file `exceptions.f90` this is the source for the program. It prints the final results. You may
want to add write statements to see the exceptions.
