! prepare_exceptions.f90 --
!     Simple preprocessor to instrument exceptions in Fortran
!     Low-impact experiment
!
program prepare_exceptions
    implicit none

    character(len=200) :: line
    character(len=80)  :: filename
    character(len=20)  :: first_word
    logical            :: in_try
    logical            :: first_catch
    integer            :: ierr, k
    integer            :: lineno
    integer            :: luinp, luout

    call get_command_argument( 1, filename, status = ierr )

    if ( ierr /= 0 ) then
        write(*,*) 'Usage: prepare <filename>'
        stop
    endif

    open( newunit = luinp, file = filename, status = 'old', iostat = ierr )

    if ( ierr /= 0 ) then
        write(*,*) 'File could not be opened: ', trim(filename)
        stop
    endif

    open( newunit = luout, file = '_' // filename )

    lineno = 0

    do
        read( luinp, '(a)', iostat = ierr ) line

        if ( ierr /= 0 ) then
            exit
        endif

        !
        ! The first word on the line will determine our action
        ! - quick and dirty, don't try a foolproof parsing
        !
        ! Limitations:
        ! - Only treat calls to subroutines and only single-line ones
        !
        !
        read( line, *, iostat = ierr ) first_word
        lineno = lineno + 1

        if ( ierr /= 0 ) then
            write( luout, '(a)' ) trim(line)
            cycle
        endif

        select case ( first_word)
            case ('try')
                write( luout, '(a)' )  'do'
                in_try      = .true.
                first_catch = .true.
            case ('call')
                if ( in_try ) then
                    write( luout, '(a)' ) trim(line)
                    write( luout, '(a)' ) 'if ( exception_raised ) exit'
                else
                    write( luout, '(a)' ) trim(line)
                endif
            case ('catch')
                if ( first_catch ) then
                    first_catch = .false.
                    write( luout, '(a)' ) 'exit'
                    write( luout, '(a)' ) 'enddo'
                    write( luout, '(a)' ) 'if ( exception_raised ) then'
                    write( luout, '(a)' ) 'select type (exception_data)'
                endif
                k = index( line, 'catch' )
                line = line(k+5:)
                write( luout, '(a)' ) '   type is ' // trim(line)

            case ('throw')
                k = index( line, 'throw' )
                line = line(k+5:)
                write( luout, '(a)' )    '   exception_raised = .true.'
                write( luout, '(2a)' )   '   exception_data = ', trim(line)
                write( luout, '(a,i0)' ) '   exception_lineno   = ', lineno
                write( luout, '(a,2a)' ) '   exception_filename = ''', trim(filename), ''''
                write( luout, '(a)' )    '   return'

            case ('endtry')
                write( luout, '(a)' ) '   class default '
                write( luout, '(a)' ) '       write(*,*)  ''Unspecified exception at: '''
                !write( luout, '(a)' ) '       write(*,*)  ''    line '', exception_data%lineno, '' in file '', trim(exception_data%filename)'
                write( luout, '(a)' ) '       write(*,*)  ''    line '', exception_lineno, '' in file '', trim(exception_filename) '
                write( luout, '(a)' ) 'end select'
                write( luout, '(a)' ) 'exception_raised = .false.'
                write( luout, '(a)' ) 'endif'
                in_try = .false.

            case default
                write( luout, '(a)' ) trim(line)
        end select
    enddo
end program
