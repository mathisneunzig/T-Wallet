! transfer_fee.f90 — Transfer fee calculator for T-Wallet
! Usage: transfer_fee <raw_amount> <decimals>
! Output: fee in raw currency units (integer)
! Fee = max(1, floor(raw_amount * 0.5%))
!       i.e. floor(raw_amount * 5 / 1000)
! A minimum fee of 1 raw unit always applies.

program transfer_fee
    implicit none
    character(len=20) :: arg1, arg2
    integer(kind=8)   :: amount, fee

    call get_command_argument(1, arg1)
    call get_command_argument(2, arg2)

    if (len_trim(arg1) == 0) then
        write(*,'(A)') "1"
        stop
    end if

    read(arg1, *) amount

    ! 0.5% = multiply by 5, divide by 1000
    fee = amount * 5_8 / 1000_8

    if (fee < 1) fee = 1

    write(*,'(I0)') fee

end program transfer_fee
