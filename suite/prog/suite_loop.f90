MODULE suite_loop_mod
!
CONTAINS
!
SUBROUTINE suite_loop
!                                                                       
USE do_exit_mod
USE doact_mod
USE errlist_mod 
USE learn_mod 
USE class_macro_internal
USE prompt_mod 
!                                                                       
IMPLICIT none 
!
!*****7*****************************************************************
!                                                                       
!     Main loop for DISCUS_SUITE                                           
!                                                                       
!     This is the main program for DISCUS_SUITE. It sets up most              
!     variables and calls the loop interpreting the commands.           
!                                                                       
!     Authors : R.B. Neder  (reinhard.neder@fau.de)      
!                                                                       
!*****7*****************************************************************
!
!                                                                       
CHARACTER (LEN=1024)           :: line, zeile 
CHARACTER (LEN=4)              :: befehl 
LOGICAL                        :: lend    = .false.
INTEGER                        :: laenge, lp, lbef 
!
      CALL no_error 
!                                                                       
!------ This is the main loop: reading commands ..                      
!                                                                       
      main: DO while (.not.lend) 
         CALL get_cmd (line, laenge, befehl, lbef, zeile, lp, prompt) 
      no_cmd: IF (ier_num.eq.0.and.laenge.gt.0) then 
!                                                                       
!     - If not a comment continue                                       
!                                                                       
            IF (.not. (line (1:1) .eq.'#'.or.line (1:1) .eq.'!') ) then 
!                                                                       
!  - execute command                                                 
!                                                                       
               IF (line (1:3) .eq.'do '.OR.line (1:2) .eq.'if') then 
                  CALL do_loop (line, lend, laenge) 
               ELSE 
                  CALL suite_mache_kdo (line, lend, laenge) 
               ENDIF 
            ENDIF 
         ENDIF no_cmd
!                                                                       
!     - Handle error message                                            
!                                                                       
         IF (ier_num.ne.0) then 
            IF( ier_num ==-9.and. ier_typ==ER_IO) THEN
               write(output_io, 8000)
               write(output_io, 9000)
               stop
            ENDIF
            CALL errlist 
            IF (ier_sta.ne.ER_S_LIVE) then 
               IF (lmakro.and.ier_sta.ne.ER_S_LIVE) then 
                  CALL macro_close 
                  prompt_status = PROMPT_ON 
               ENDIF 
               lblock = .false. 
               CALL no_error 
            ENDIF 
         ENDIF 
      ENDDO main
!                                                                       
!
   CALL do_exit
!
8000 format(' ****EXIT**** Input error on normal read        ',        &
     &       '        ****',a1/)
9000 format(' ****EXIT**** Program terminated by error status',        &
     &       '        ****',a1/)
!                                                                       
END SUBROUTINE suite_loop
!*****7*****************************************************************
END MODULE suite_loop_mod
