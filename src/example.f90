! example.f90 --
!      Simple example of throwing an exception and catching it
!
!      The actual calculation is a trifle silly:
!      Use Monte Carlo to integrate the function x**2 * exp(-x**2) / sqrt(2pi) over -Inf to Inf
!      (the factor exp(-x**2) / sqrt(2*pi) drops out of the calculation)
!
module random_numbers
    implicit none

contains
subroutine rnd_normal( x )
    real, intent(out) :: x

    real, dimension(2) :: y

    call random_number( y )

    x = -log(y(1)) * cos( 2.0 * acos(-1.0) * y(2) )
end subroutine rnd_normal

end module random_numbers

!
! Simple integration via Monte Carlo
!
module integration
    use random_numbers
    implicit none

contains
subroutine integrate( func, result )
    use exceptions
    interface
        subroutine func( x, y)        ! Subroutine because of limitation in preprocessor
            real, intent(in)  :: x
            real, intent(out) :: y
        end subroutine func
    end interface

    real, intent(out) :: result

    real              :: x, y

    integer           :: i

    i      = 0
    result = 0.0

    do while ( i < 1000 )
        i = i + 1

        try
            call rnd_normal( x )
            call func( x, y )
            result = result + y
        catch (ex_refused)
            i = i - 1 ! Try again
        endtry
    enddo

    result = result / 1000.0
end subroutine integrate

end module integration

!
! Driver program
!
program demo_exceptions
    use exceptions
    use integration

    real :: result

    call integrate( func, result )

    write(*,*) result

contains
subroutine func( x, y )
    real, intent(in)  :: x
    real, intent(out) :: y

    if ( abs(x) > 3.0 ) then
        throw ex_refused('x out of range')
    else
        y = x ** 2
    endif
end subroutine func

end program demo_exceptions
