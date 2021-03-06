!*****7****************************************************************
!
SUBROUTINE suite_errlist_appl
!-
!     Displays error Messages for the error type APPLication
!+
USE errlist_mod
IMPLICIT      none
!
!
INTEGER       iu,io
PARAMETER    (IU=  0,IO=0)
!
CHARACTER(LEN=45) ERROR(IU:IO)
!
DATA ERROR (  0:  0) /                                            &
  &  ' '                                                             & !  0  ! diffev
  &  /
!
CALL disp_error ('APPL',error,iu,io)
!
END SUBROUTINE suite_errlist_appl
!*****7****************************************************************
