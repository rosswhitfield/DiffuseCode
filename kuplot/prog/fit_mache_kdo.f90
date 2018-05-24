SUBROUTINE fit_mache_kdo(line, lend, length)
!
USE kuplot_mod
USE fit_params_mod
!
USE ber_params_mod
USE blanks_mod
USE calc_expr_mod
USE errlist_mod
USE get_params_mod
USE kdo_all_mod
USE set_sub_generic_mod
!

IMPLICIT NONE
!
CHARACTER(LEN=*), INTENT(INOUT) :: line
LOGICAL         , INTENT(  OUT) :: lend
INTEGER         , INTENT(INOUT) :: length
!
INTEGER, PARAMETER :: MAXP = 2
CHARACTER(LEN=1024), DIMENSION(MAXP) :: cpara
INTEGER            , DIMENSION(MAXP) :: lpara
REAL               , DIMENSION(MAXP) :: werte
!
CHARACTER(LEN=4)    :: befehl
CHARACTER(LEN=1024) :: zeile
INTEGER             :: indxg, indxt, indxb
INTEGER             :: lbef, lp
INTEGER             :: ind
INTEGER             :: ianz
!
LOGICAL str_comp
!
IF(length==0) RETURN
IF(line == ' '.OR.line (1:1)  == '#' .OR. LINE=='!') RETURN
befehl = '    '
indxt  = INDEX (line, ACHAR(9))       ! find a tabulator
IF(indxt==0) indxt = length + 1
indxb  = INDEX (line, ' ')            ! find a blank
IF(indxb==0) indxb = length + 1
indxb  = MIN(indxb,indxt)
lbef   = MIN (indxb - 1, 4)
befehl = line (1:lbef)
indxg  = INDEX (line, '=')
!
!     command parameters start at the first character                   
!     following the blank
!
zeile = ' '
lp    = 0
IF (indxb + 1.le.length) THEN
   zeile = line (indxb + 1:length)
   lp    = length - indxb
   CALL rem_leading_bl(zeile, lp)
ENDIF
!
IF (indxg /= 0                                            &
   .AND..NOT. (str_comp (befehl, 'echo', 2, lbef, 4) )    &
   .AND..NOT. (str_comp (befehl, 'help', 2, lbef, 4) .OR. &
               str_comp (befehl, '?   ', 2, lbef, 4) )    &
   .AND. INDEX(line,'==') == 0                          )THEN
   CALL do_math (line, indxg, length)
!
!------ execute a macro file                                            
!
ELSEIF (befehl (1:1)  == '@') THEN
   CALL file_kdo (line (2:length), length - 1)
!
!     continues a macro 'continue'                                      
!
ELSEIF (str_comp (befehl, 'continue', 3, lbef, 8) ) THEN
   CALL macro_continue (zeile, lp)
!
!-------Set number of cycles 'cyc'                                      
!
ELSEIF (str_comp (befehl, 'finished', 4, lbef, 8) ) THEN
   lend = .TRUE.
!ELSEIF (str_comp (befehl, 'value', 4, lbef, 5) ) THEN
!   CALL get_params (zeile, ianz, cpara, lpara, MAXP, lp)
!   IF(ier_num/=0) RETURN
!   CALL ber_params (ianz, cpara, lpara, werte, MAXP)
!   IF(ier_num/=0) RETURN
!   ff = werte(1)
!ELSEIF (str_comp (befehl, 'deriv', 4, lbef, 5) ) THEN
!   IF(iwert>0) THEN
!      CALL get_params (zeile, ianz, cpara, lpara, MAXP, lp)
!      IF(ier_num/=0) RETURN
!      CALL ber_params (ianz, cpara, lpara, werte, MAXP)
!      IF(ier_num/=0) RETURN
!      ind = NINT(werte(1))
!      IF (pinc (ind) /=  0) THEN
!         dff(ind) = werte(2)
!      ELSE
!         dff(ind) = 0.0
!      ENDIF
!   ENDIF
ELSEIF (str_comp (befehl, 'top', 3, lbef, 3) ) THEN
   CALL p_top('kuplot_fit')
ELSE
   CALL kdo_all (befehl, lbef, zeile, lp)
ENDIF
!
END SUBROUTINE fit_mache_kdo
