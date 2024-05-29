MODULE diffev_random
!
!  Handles logging of the random number status 
!
!  The status of the random number generator at the start of the 
!  currently best individuum is preserved.
!
IMPLICIT NONE
!
CHARACTER(LEN=100), DIMENSION(16) :: random_macro
CHARACTER(LEN=100), DIMENSION(16) :: random_prog
LOGICAL           , DIMENSION(16) :: random_repeat
LOGICAL :: write_random_state = .FALSE.
integer :: l_get_random_state = -1    
!INTEGER, DIMENSION(:,:), ALLOCATABLE :: random_state  ! Status for current members
INTEGER                              :: random_n      ! number of run_mpi commands prior to 'compare'
INTEGER                              :: random_nseed
INTEGER, DIMENSION(0:64)             :: random_best   ! Status for best    member
!
CONTAINS
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
SUBROUTINE diffev_random_on
!
IMPLICIT NONE
!
l_get_random_state = -1
!
END SUBROUTINE diffev_random_on
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
SUBROUTINE diffev_random_off
!
IMPLICIT NONE
!
l_get_random_state = 0
!
END SUBROUTINE diffev_random_off
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
integer FUNCTION diffev_random_status()
!
IMPLICIT NONE
!
diffev_random_status = l_get_random_state
!
END FUNCTION diffev_random_status
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
SUBROUTINE diffev_random_write_on(prog, prog_l, macro, macro_l, do_repeat)
!
IMPLICIT NONE
!
CHARACTER(LEN=*), INTENT(IN) :: prog
CHARACTER(LEN=*), INTENT(IN) :: macro
INTEGER         , INTENT(IN) :: prog_l
INTEGER         , INTENT(IN) :: macro_l
LOGICAL         , INTENT(IN) :: do_repeat
!
write_random_state = .TRUE.     ! Turn on  documentation
random_n     = random_n + 1     ! another run_mpi command
random_prog(random_n)  = prog(1:prog_l)
random_macro(random_n) = macro(1:macro_l)
random_repeat(random_n) = do_repeat
!
END SUBROUTINE diffev_random_write_on
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
SUBROUTINE diffev_random_write_off
!
IMPLICIT NONE
!
write_random_state = .FALSE.    ! Turn off documentation
random_n     = 0                ! No run_mpi commands yet
random_prog(:)   = ' '
random_macro(:)  = ' '
random_repeat(:) = .FALSE.
!
END SUBROUTINE diffev_random_write_off
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
SUBROUTINE diffev_random_save(new)
!
IMPLICIT NONE
!
INTEGER, DIMENSION(0:64), INTENT(IN) :: new
!
random_best(:) = new(:)
random_nseed   = MIN(64, new(0))
!
END SUBROUTINE diffev_random_save
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
SUBROUTINE diffev_best_macro
!
USE population
USE run_mpi_mod
!
USE errlist_mod
USE random_state_mod
USE precision_mod
USE support_mod
!
IMPLICIT NONE
!
INTEGER, PARAMETER :: IWR = 88
!
CHARACTER(LEN=40) :: macro_file = 'diffev_best.mac'
CHARACTER(LEN=PREC_STRING) :: line
CHARACTER(LEN=  39), PARAMETER :: string = 'cat *.mac |grep -F ref_para > /dev/null'
CHARACTER(LEN=PREC_STRING) :: message
INTEGER            , PARAMETER :: lstring = 39
INTEGER :: exit_msg
INTEGER :: i, i1, nn
INTEGER :: nseed_run    ! Actual number of seed used by compiler
LOGICAL, SAVE :: l_test     = .TRUE.
LOGICAL, SAVE :: l_ref_para = .FALSE.
!
IF(l_test) THEN     ! Need to test for ref_para in macros
   CALL EXECUTE_COMMAND_LINE(string(1:lstring), CMDSTAT=ier_num, &
                             CMDMSG=message, EXITSTAT=exit_msg  )
   IF(exit_msg == 0) l_ref_para = .TRUE.   ! string "ref_para" was found
   l_test = .FALSE.                        ! no more need to test
ENDIF
!
nseed_run = random_nseeds()
random_nseed   = MIN(RUN_MPI_NSEEDS, nseed_run)  !  to be debugged depend on compiler ???
IF(write_random_state) THEN
   CALL oeffne(IWR, macro_file, 'unknown')
!
   WRITE(IWR,'(a)') 'discus'
   WRITE(IWR,'(a)') 'reset'
   WRITE(IWR,'(a)') 'exit'
   WRITE(IWR,'(a)') 'kuplot'
   WRITE(IWR,'(a)') 'reset'
   WRITE(IWR,'(a)') 'exit'
   WRITE(IWR,'(a,a)') random_prog(1)(1:LEN_TRIM(random_prog(1))), '   ! temporarily step into section'
   WRITE(IWR,'(a)') '#@ HEADER'
   WRITE(IWR,'(a)') '#@ NAME         diffev_best.mac'
   WRITE(IWR,'(a)') '#@ '
   WRITE(IWR,'(a)') '#@ KEYWORD      diffev, best member, initialize'
   WRITE(IWR,'(a)') '#@ '
   WRITE(IWR,'(a)') '#@ DESCRIPTION  This macro contains the parameters for the current best'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  member. If run, the best member will be recreated.'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  As the random state is explicitely contained as well, the'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  best member will be recreated exactly.'
   WRITE(IWR,'(a)') '#@ DESCRIPTION'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  This macro uses the original macro on the run_mpi command'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  line. Make sure to turn on writing of desired output files.'
   WRITE(IWR,'(a)') '#@ DESCRIPTION'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  Each of the macros on a run_mpi line must have an ''exit'' '
   WRITE(IWR,'(a)') '#@ DESCRIPTION  command, which returns to the suite level.'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  As the run_mpi command internally switches to the correct'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  section, the switch is done here with preceding the macro call '
   WRITE(IWR,'(a)') '#@ DESCRIPTION  with the proper ''discus'' or ''kuplot'' command.'
   WRITE(IWR,'(a)') '#@'
   WRITE(IWR,'(a)') '#@ PARAMETER    $0, 0'
   WRITE(IWR,'(a)') '#@'
   WRITE(IWR,'(a)') '#@ USAGE        @diffev_best.mac'
   WRITE(IWR,'(a)') '#@'
   WRITE(IWR,'(a)') '#@ END'
   WRITE(IWR,'(a)') '#'
   WRITE(IWR,'(a,i12)') 'REF_GENERATION = ',pop_gen
   WRITE(IWR,'(a,i12)') 'REF_MEMBER     = ',pop_n
   WRITE(IWR,'(a,i12)') 'REF_CHILDREN   = ',pop_c
   WRITE(IWR,'(a,i12)') 'REF_DIMENSION  = ',pop_dimx
   WRITE(IWR,'(a,i12)') 'REF_NINDIV     = ',run_mpi_senddata%nindiv
   WRITE(IWR,'(a,i12)') 'REF_KID        = ',9999
   WRITE(IWR,'(a,i12)') 'REF_INDIV      = ',0001
   DO i=0,pop_dimx
      WRITE(IWR,'(A,A)') 'variable real, ', pop_name(i)
   ENDDO
   WRITE(IWR,'(A,       A,E17.10)') pop_name(0),      ' = ',child_val(pop_best,0)
   DO i=1,pop_dimx
      WRITE(IWR,'(A,       A,E17.10)') pop_name(i),      ' = ',child(i,pop_best)
!     WRITE(IWR,'(A,I12,A,E17.10)') 'ref_para[',i,'] = ',child(i,pop_best)
   ENDDO
   IF(l_ref_para) THEN
      WRITE(IWR,'(A,i4,    A,E17.10)') 'ref_para[',0,']   = ',child_val(pop_best,0)
      DO i=1,pop_dimx
         WRITE(IWR,'(A,i4,    A,E17.10)') 'ref_para[',i,']   = ',child(i,pop_best)
      ENDDO
   ENDIF
!
!  IF(random_nseed>0) THEN
!     line = ' '
!     line(1:5) = 'seed '
!     DO i=1, random_nseed - 1
!        i1 = 6 + (i-1)*10
!        WRITE(line(i1:i1+9),'(I8,A2)') random_best(i),', '
!     ENDDO
!     i = random_nseed
!     i1 = 6 + (i-1)*10
!     WRITE(line(i1:i1+7),'(I8)') random_best(i)
!     WRITE(IWR,'(a)') line(1:LEN_TRIM(line))
!  ENDIF
!
   IF(random_nseed>0) THEN
      line = ' '
      line(1:5) = 'seed '
      i1 = 6
!     DO i=1, random_nseed 
!        i1 = 6 + (i-1)*19
!        ir1 =         IABS(random_best(i)/ 100000000)
!        ir2 =     MOD(IABS(random_best(i)), 100000000)/10000
!        ir3 =     MOD(IABS(random_best(i)), 10000)
!        IF(random_best(i)<0) THEN
!           IF(ir1==0 .AND. ir2==0) THEN
!              ir3 = -ir3
!           ELSEIF(ir1==0) THEN
!              ir2 = -ir2
!           ELSE
!              ir1 = -ir1
!           ENDIF
!        ENDIF
!        WRITE(line(i1:i1+18),'(I5,A1,I5,A1,I5,A2)') ir1,',',ir2,',',ir3,', '
!     ENDDO
!     WRITE(line(i1+19:i1+27),'(a8)') ' group:3'
      DO i=1, random_nseed 
         i1 = 6 + (i-1)*15
         WRITE(line(i1:i1+16),'(I12,A1)') random_best(i), ','
      ENDDO
      i= LEN_TRIM(LINE)
      IF(line(i:i)==',') line(i:i) = ' '
      WRITE(IWR,'(a)') line(1:LEN_TRIM(line))
   ENDIF
   WRITE(IWR,'(a)') '#'
   WRITE(IWR,'(a)') 'exit   ! Return to SUITE'
   WRITE(IWR,'(a)') '#      ! Each macro on run_mpi command must have an exit to suite as well'
   WRITE(IWR,'(a)') '#      ! Each macro is preceeded with a command that steps into the section'
   WRITE(IWR,'(a)') '#'
   DO nn = 1, MIN(1,random_n)
      IF(random_repeat(nn)) THEN
         WRITE(IWR,'(a)') 'do REF_INDIV=1,REF_NINDIV'
         WRITE(IWR,'(a,a)'   ) '  ',random_prog(nn)(1:LEN_TRIM(random_prog(nn)))
         WRITE(IWR,'(a3,a,a)') '  @',random_macro(nn)(1:LEN_TRIM(random_macro(nn))),'  ., REF_KID, REF_INDIV'
         WRITE(IWR,'(a)') 'enddo'
      ELSE
         WRITE(IWR,'(a)') random_prog(nn)(1:LEN_TRIM(random_prog(nn)))
         WRITE(IWR,'(a1,a,a)') '@',random_macro(nn)(1:LEN_TRIM(random_macro(nn))),'  ., REF_KID, REF_INDIV'
      ENDIF
      WRITE(IWR,'(a)') '#'
   ENDDO
   WRITE(IWR,'(a)') '#'
   WRITE(IWR,'(a)') 'set error, continue'
!  WRITE(IWR,'(a)') 'exit'
!
   CLOSE(IWR)
!
ENDIF
!
CALL diffev_random_write_off    ! Turn off documentation
!
END SUBROUTINE diffev_best_macro
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
SUBROUTINE diffev_error_macro
!
USE population
USE run_mpi_mod
!
USE errlist_mod
USE random_state_mod
USE precision_mod
USE support_mod
!
IMPLICIT NONE
!
INTEGER, PARAMETER :: IWR = 88
!
CHARACTER(LEN=40) :: macro_file = 'diffev_error.0000.0000.mac'
CHARACTER(LEN=PREC_STRING) :: line
CHARACTER(LEN=  39), PARAMETER :: string = 'cat *.mac |grep -F ref_para > /dev/null'
CHARACTER(LEN=PREC_STRING) :: message
INTEGER            , PARAMETER :: lstring = 39
INTEGER :: exit_msg
INTEGER :: i, i1, nn
INTEGER :: nseed_run    ! Actual number of seed used by compiler
LOGICAL, SAVE :: l_test     = .TRUE.
LOGICAL, SAVE :: l_ref_para = .FALSE.
!
CALL diffev_random_write_on(run_mpi_senddata%prog, run_mpi_senddata%prog_l,  &
     run_mpi_senddata%mac, run_mpi_senddata%mac_l, run_mpi_senddata%repeat)
!
WRITE(macro_file, '(a,I4.4,a,i4.4,a)') 'diffev_error.',run_mpi_senddata%kid, '.', &
     run_mpi_senddata%indiv, '.mac'
!
IF(l_test) THEN     ! Need to test for ref_para in macros
   CALL EXECUTE_COMMAND_LINE(string(1:lstring), CMDSTAT=ier_num, &
                             CMDMSG=message, EXITSTAT=exit_msg  )
   IF(exit_msg == 0) l_ref_para = .TRUE.   ! string "ref_para" was found
   l_test = .FALSE.                        ! no more need to test
ENDIF
!
nseed_run = run_mpi_senddata%nseeds
random_nseed   = MIN(RUN_MPI_NSEEDS, nseed_run)  !  to be debugged depend on compiler ???
!IF(write_random_state) THEN
   CALL oeffne(IWR, macro_file, 'unknown')
!
   WRITE(IWR,'(a)') 'discus'
   WRITE(IWR,'(a)') 'reset'
   WRITE(IWR,'(a)') 'exit'
   WRITE(IWR,'(a)') 'kuplot'
   WRITE(IWR,'(a)') 'reset'
   WRITE(IWR,'(a)') 'exit'
   WRITE(IWR,'(a,a)') run_mpi_senddata%prog(1:LEN_TRIM(run_mpi_senddata%prog)), '   ! temporarily step into section'
   WRITE(IWR,'(a)') '#@ HEADER'
   WRITE(IWR,'(a,I4.4,a,i4.4,a)') '#@ NAME         diffev_error.',run_mpi_senddata%kid, '.', run_mpi_senddata%indiv,'.mac'
   WRITE(IWR,'(a)') '#@ '
   WRITE(IWR,'(a)') '#@ KEYWORD      diffev, erroneous member, initialize'
   WRITE(IWR,'(a)') '#@ '
   WRITE(IWR,'(a)') '#@ DESCRIPTION  This macro contains the parameters for the current kid,'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  indiv combination that caused an error during slave   ,'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  If run, the erroneous member will be recreated.'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  As the random state is explicitely contained as well, the'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  erroneous member will be recreated exactly.'
   WRITE(IWR,'(a)') '#@ DESCRIPTION'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  This macro uses the original macro on the run_mpi command'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  line. Make sure to turn on writing of desired output files.'
   WRITE(IWR,'(a)') '#@ DESCRIPTION'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  Each of the macros on a run_mpi line must have an ''exit'' '
   WRITE(IWR,'(a)') '#@ DESCRIPTION  command, which returns to the suite level.'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  As the run_mpi command internally switches to the correct'
   WRITE(IWR,'(a)') '#@ DESCRIPTION  section, the switch is done here with preceding the macro call '
   WRITE(IWR,'(a)') '#@ DESCRIPTION  with the proper ''discus'' or ''kuplot'' command.'
   WRITE(IWR,'(a)') '#@'
   WRITE(IWR,'(a)') '#@ PARAMETER    $0, 0'
   WRITE(IWR,'(a)') '#@'
   WRITE(IWR,'(a,I4.4,a,i4.4,a)') '#@ USAGE        @diffev_error',run_mpi_senddata%kid, '.', run_mpi_senddata%indiv,'.mac'
   WRITE(IWR,'(a)') '#@'
   WRITE(IWR,'(a)') '#@ END'
   WRITE(IWR,'(a)') '#'
   WRITE(IWR,'(a,i12)') 'REF_GENERATION = ',pop_gen
   WRITE(IWR,'(a,i12)') 'REF_MEMBER     = ',pop_n
   WRITE(IWR,'(a,i12)') 'REF_CHILDREN   = ',pop_c
   WRITE(IWR,'(a,i12)') 'REF_DIMENSION  = ',pop_dimx
   WRITE(IWR,'(a,i12)') 'REF_NINDIV     = ',run_mpi_senddata%nindiv
   WRITE(IWR,'(a,i12)') 'REF_KID        = ',run_mpi_senddata%kid
   WRITE(IWR,'(a,i12)') 'REF_INDIV      = ',run_mpi_senddata%indiv
   DO i=0,pop_dimx
      WRITE(IWR,'(A,A)') 'variable real, ', pop_name(i)
   ENDDO
   WRITE(IWR,'(A,       A,E17.10)') pop_name(0),      ' = ',run_mpi_senddata%rvalue(0)
   DO i=1,pop_dimx
      WRITE(IWR,'(A,       A,E17.10)') pop_name(i),      ' = ',run_mpi_senddata%trial_values(i)
!     WRITE(IWR,'(A,I12,A,E17.10)') 'ref_para[',i,'] = ',child(i,pop_best)
   ENDDO
   IF(l_ref_para) THEN
      WRITE(IWR,'(A,i4,    A,E17.10)') 'ref_para[',0,']   = ',run_mpi_senddata%rvalue(0)
      DO i=1,pop_dimx
         WRITE(IWR,'(A,i4,    A,E17.10)') 'ref_para[',i,']   = ',run_mpi_senddata%trial_values(i)
      ENDDO
   ENDIF
!
!  IF(random_nseed>0) THEN
!     line = ' '
!     line(1:5) = 'seed '
!     DO i=1, random_nseed - 1
!        i1 = 6 + (i-1)*10
!        WRITE(line(i1:i1+9),'(I8,A2)') random_best(i),', '
!     ENDDO
!     i = random_nseed
!     i1 = 6 + (i-1)*10
!     WRITE(line(i1:i1+7),'(I8)') random_best(i)
!     WRITE(IWR,'(a)') line(1:LEN_TRIM(line))
!  ENDIF
!
   IF(random_nseed>0) THEN
      line = ' '
      line(1:5) = 'seed '
      i1 = 6
!     DO i=1, random_nseed 
!        i1 = 6 + (i-1)*17
!        ir1 =              run_mpi_senddata%seeds(i)/ 100000000
!        ir2 =     MOD(IABS(run_mpi_senddata%seeds(i)), 100000000)/10000
!        ir3 =     MOD(IABS(run_mpi_senddata%seeds(i)), 10000)
!        WRITE(line(i1:i1+16),'(I5,A1,I4,A1,I4,A2)') ir1,',',ir2,',',ir3,', '
!     ENDDO
!     WRITE(line(i1+17:i1+25),'(a8)') ' group:3'
      DO i=1, random_nseed 
         i1 = 6 + (i-1)*15
         WRITE(line(i1:i1+16),'(I12,A1)') run_mpi_senddata%seeds(i), ','
      ENDDO
      i= LEN_TRIM(LINE)
      IF(line(i:i)==',') line(i:i) = ' '
      WRITE(IWR,'(a)') line(1:LEN_TRIM(line))
   ENDIF
   WRITE(IWR,'(a)') '#'
   WRITE(IWR,'(a)') 'exit   ! Return to SUITE'
   WRITE(IWR,'(a)') '#      ! Each macro on run_mpi command must have an exit to suite as well'
   WRITE(IWR,'(a)') '#      ! Each macro is preceeded with a command that steps into the section'
   WRITE(IWR,'(a)') '#'
   DO nn = 1, random_n
      IF(random_repeat(nn)) THEN
         WRITE(IWR,'(a)') 'do REF_INDIV=1,REF_NINDIV'
         WRITE(IWR,'(a,a)'   ) '  ',random_prog(nn)(1:LEN_TRIM(random_prog(nn)))
         WRITE(IWR,'(a3,a,a)') '  @',random_macro(nn)(1:LEN_TRIM(random_macro(nn))),'  ., REF_KID, REF_INDIV'
         WRITE(IWR,'(a)') 'enddo'
      ELSE
         WRITE(IWR,'(a)') random_prog(nn)(1:LEN_TRIM(random_prog(nn)))
         WRITE(IWR,'(a1,a,a)') '@',random_macro(nn)(1:LEN_TRIM(random_macro(nn))),'  ., REF_KID, REF_INDIV'
      ENDIF
      WRITE(IWR,'(a)') '#'
   ENDDO
   WRITE(IWR,'(a)') '#'
   WRITE(IWR,'(a)') 'set error, continue'
!  WRITE(IWR,'(a)') 'exit'
!
   CLOSE(IWR)
!
!ENDIF
!
CALL diffev_random_write_off    ! Turn off documentation
!
END SUBROUTINE diffev_error_macro
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
END MODULE diffev_random
