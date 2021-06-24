! exceptions.f90 --
!     Sample implementation of exceptions
!
module exceptions_base_mod
    implicit none

    logical                       :: exception_raised = .false.
    integer                       :: exception_lineno
    character(len=:), allocatable :: exception_filename

    type exception_base_type
        character(len=:), allocatable :: message
    end type exception_base_type

    class(exception_base_type), allocatable :: exception_data
end module exceptions_base_mod

module exceptions
    use exceptions_base_mod
    implicit none

    type, extends(exception_base_type) :: ex_refused
    end type ex_refused
end module exceptions
