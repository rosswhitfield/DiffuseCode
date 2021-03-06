MODULE fourier_menu
!
USE errlist_mod 
!
CONTAINS
      SUBROUTINE fourier 
!+                                                                      
!     This subroutine 'fourier' calculates the Fourier transform        
!     of the given crystal structure. The algorithm to speed up         
!     the explicite Fourier is based on the program 'DIFFUSE' by        
!     B.D. Butler. See also: B.D. Butler & T.R. Welberry, (1992).       
!     J. Appl. Cryst. 25, 391-399.                                      
!                                                                       
!-                                                                      
      USE discus_config_mod 
      USE discus_allocate_appl_mod
      USE crystal_mod 
      USE diffuse_mod 
      USE external_four
      USE fourier_sup
      USE modify_mod
      USE output_mod 
!
      USE doact_mod 
      USE learn_mod 
      USE class_macro_internal 
      USE prompt_mod 
      IMPLICIT none 
!                                                                       
       
!                                                                       
      INTEGER, PARAMETER :: MIN_PARA = 21  ! A command requires at least these no of parameters
      INTEGER maxw 
      LOGICAL lold 
      PARAMETER (lold = .false.) 
!                                                                       
      CHARACTER (LEN=1024), DIMENSION(MAX(MIN_PARA,MAXSCAT+1))   :: cpara ! (MIN(10,MAXSCAT)) 
      INTEGER             , DIMENSION(MAX(MIN_PARA,MAXSCAT+1))   :: lpara ! (MIN(10,MAXSCAT))
      INTEGER             , DIMENSION(MAX(MIN_PARA,MAXSCAT+1))   :: jj    ! (MAXSCAT) 
      REAL                , DIMENSION(MAX(MIN_PARA,MAXSCAT+1))   :: werte ! (MAXSCAT)
      CHARACTER(5) befehl 
      CHARACTER(50) prom 
      CHARACTER(1024) zeile
      CHARACTER(1024) line 
      INTEGER :: i, j=1, k, ianz, lp, length 
      INTEGER indxg, lbef 
      INTEGER              :: n_qxy    ! required size in reciprocal space this run
      INTEGER              :: n_nscat  ! required no of atom types right now
      INTEGER              :: n_natoms ! required no of atoms
      LOGICAL              :: ldim 
      LOGICAL              :: ltop = .false. ! the top left corner has been defined
      REAL   , DIMENSION(3)::  divis
      REAL   , DIMENSION(3)::  rhkl
!                                                                       
      INTEGER len_str 
      LOGICAL str_comp 
!
      maxw     = MAX(MIN_PARA,MAXSCAT+1)
      n_qxy    = 1
      n_nscat  = 1
      n_natoms = 1
!                                                                       
   10 CONTINUE 
!                                                                       
      CALL no_error 
      divis (1) = float (max (1, inc (1) - 1) ) 
      divis (2) = float (max (1, inc (2) - 1) ) 
      divis (3) = float (max (1, inc (3) - 1) ) 
!                                                                       
      prom = prompt (1:len_str (prompt) ) //'/fourier' 
      CALL get_cmd (line, length, befehl, lbef, zeile, lp, prom) 
      IF (ier_num.eq.0) then 
         IF (line (1:1)  == ' '.or.line (1:1)  == '#' .or.   & 
             line == char(13) .or. line(1:1) == '!'  ) GOTO 10
!                                                                       
!     search for "="                                                    
!                                                                       
         indxg = index (line, '=') 
      IF (indxg.ne.0.and..not. (str_comp (befehl, 'echo', 2, lbef, 4) ) &
     &.and..not. (str_comp (befehl, 'syst', 2, lbef, 4) ) .and..not. (st&
     &r_comp (befehl, 'help', 2, lbef, 4) .or.str_comp (befehl, '?   ', &
     &2, lbef, 4) ) ) then                                              
!                                                                       
!     --evaluatean expression and assign the value to a variabble       
!                                                                       
            CALL do_math (line, indxg, length) 
         ELSE 
!                                                                       
!------ execute a macro file                                            
!                                                                       
            IF (befehl (1:1) .eq.'@') then 
               IF (length.ge.2) then 
                  CALL file_kdo (line (2:length), length - 1) 
               ELSE 
                  ier_num = - 13 
                  ier_typ = ER_MAC 
               ENDIF 
!                                                                       
!     Define the ascissa 'absc'                                         
!                                                                       
            ELSEIF (str_comp (befehl, 'absc', 1, lbef, 4) ) then 
               CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
               IF (ianz.eq.1) then 
                  IF (cpara (1) .eq.'h') then 
                     extr_abs = 1 
                  ELSEIF (cpara (1) .eq.'k') then 
                     extr_abs = 2 
                  ELSEIF (cpara (1) .eq.'l') then 
                     extr_abs = 3 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ELSE 
                  ier_num = - 6 
                  ier_typ = ER_COMM 
               ENDIF 
!                                                                       
!     calculate at a single reciprocal point 'calc'                     
!                                                                       
            ELSEIF (str_comp (befehl, 'calc', 2, lbef, 4) ) then 
               CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
               IF (ier_num.eq.0) then 
                  IF (ianz.eq.3) then 
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                     IF (ier_num.eq.0) then 
                        rhkl (1) = werte (1) 
                        rhkl (2) = werte (2) 
                        rhkl (3) = werte (3) 
                        IF (inc(1) * inc(2) * inc(3) .gt. MAXQXY  .OR.   &
                            cr_natoms > DIF_MAXAT                 .OR.   &
                            cr_nscat>DIF_MAXSCAT              ) THEN
                          n_qxy    = MAX(n_qxy,inc(1) * inc(2)*inc(3),MAXQXY)
                          n_natoms = MAX(n_natoms,cr_natoms,DIF_MAXAT)
                          n_nscat  = MAX(n_nscat,cr_nscat,DIF_MAXSCAT)
                          call alloc_diffuse (n_qxy, n_nscat, n_natoms)
                          IF (ier_num.ne.0) THEN
                            RETURN
                          ENDIF
                        ENDIF
                        CALL dlink (ano, lambda, rlambda, &
                                    diff_radiation, diff_power) 
                        CALL calc_000 (rhkl) 
                     ENDIF 
                  ELSEIF (ianz.eq.0) then 
                     rhkl (1) = 0.0 
                     rhkl (2) = 0.0 
                     rhkl (3) = 0.0 
                     CALL dlink (ano, lambda, rlambda,    &
                                    diff_radiation, diff_power) 
                     CALL calc_000 (rhkl) 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ENDIF 
!                                                                       
!     continues a macro 'continue'                                      
!                                                                       
            ELSEIF (str_comp (befehl, 'continue', 1, lbef, 8) ) then 
               CALL macro_continue (zeile, lp) 
!                                                                       
!     define the anomalous scattering curve for an element 'delf'       
!                                                                       
            ELSEIF (str_comp (befehl, 'delf', 2, lbef, 4) ) then 
               CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
               IF (ianz.eq.3) then 
                  i = 1 
                  CALL get_iscat (i, cpara, lpara, werte, maxw, lold) 
                  IF (ier_num.eq.0) then 
                     IF (werte (1) .gt.0) then 
                        DO k = 1, i 
                        jj (k) = nint (werte (1) ) 
                        ENDDO 
                        cpara (1) = '0.0' 
                        lpara (1) = 3 
                        CALL ber_params (ianz, cpara, lpara, werte,     &
                        maxw)                                           
                        IF (ier_num.eq.0) then 
                           DO k = 1, i 
                           cr_delfr (jj (k) ) = werte (2) 
                           cr_delfi (jj (k) ) = werte (3) 
                           cr_delf_int (jj (k) ) = .false. 
                           ENDDO 
                        ENDIF 
                     ELSE 
                        ier_num = - 27 
                        ier_typ = ER_APPL 
                     ENDIF 
                  ENDIF 
               ELSEIF (ianz.eq.2) then 
                  IF (str_comp (cpara (2) , 'internal', 2, lpara (2) ,  &
                  8) ) then                                             
                     CALL get_iscat (i, cpara, lpara, werte, maxw, lold) 
                     IF (ier_num.eq.0) then 
                        i = nint (werte (1) ) 
                        IF (i.gt.0) then 
                           cr_delf_int (i) = .true. 
                        ELSEIF (i.eq. - 1) then 
                           DO k = 1, cr_nscat 
                           cr_delf_int (k) = .true. 
                           ENDDO 
                        ELSE 
                           ier_num = - 6 
                           ier_typ = ER_COMM 
                        ENDIF 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ELSE 
                  ier_num = - 6 
                  ier_typ = ER_COMM 
               ENDIF 
!                                                                       
!     Switch dispersion on/off 'disp' second parameter 'anom' or 'off'  
!                                                                       
            ELSEIF (str_comp (befehl, 'disp', 2, lbef, 4) ) then 
               CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
               IF (ier_num.eq.0) then 
                  IF (ianz.eq.1) then 
                     IF (cpara (1) (1:1) .eq.'a') then 
                        ano = .true. 
                     ELSEIF (cpara (1) (1:1) .eq.'o') then 
                        ano = .false. 
                     ELSE 
                        ier_num = - 6 
                        ier_typ = ER_COMM 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ENDIF 
!                                                                       
!------ Echo a string, just for interactive check in a macro 'echo'     
!                                                                       
            ELSEIF (str_comp (befehl, 'echo', 2, lbef, 4) ) then 
               CALL echo (zeile, lp) 
!                                                                       
!      Evaluate an expression, just for interactive check 'eval'        
!                                                                       
            ELSEIF (str_comp (befehl, 'eval', 2, lbef, 4) ) then 
               CALL do_eval (zeile, lp) 
!                                                                       
!     Terminate Fourier 'exit'                                          
!                                                                       
            ELSEIF (str_comp (befehl, 'exit', 3, lbef, 4) ) then 
               GOTO 9999 
!                                                                       
!     switch to electron diffraction 'electron'                                
!                                                                       
            ELSEIF (str_comp (befehl, 'electron', 2, lbef, 8) ) then 
               lxray = .true. 
               diff_radiation = RAD_ELEC
!                                                                       
!     help 'help' , '?'                                                 
!                                                                       
      ELSEIF (str_comp (befehl, 'help', 2, lbef, 4) .or.str_comp (befehl&
     &, '?   ', 1, lbef, 4) ) then                                      
               IF (str_comp (zeile, 'errors', 2, lp, 6) ) then 
                  lp = lp + 7 
                  CALL do_hel ('discus '//zeile, lp) 
               ELSE 
                  lp = lp + 12 
                  CALL do_hel ('discus four '//zeile, lp) 
               ENDIF 
!                                                                       
!     define the whole layer 'laye'                                     
!                                                                       
            ELSEIF (str_comp (befehl, 'laye', 2, lbef, 4) ) then 
               CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
               IF (ier_num.eq.0) then 
                  IF (ianz.eq.11) then 
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                     IF (ier_num.eq.0) then 
                        DO j = 1, 3 
                        DO i = 1, 3 
                           eck (i, j) = werte ( (j - 1) * 3 + i) 
                        ENDDO 
                        ENDDO 
                        eck(1,4) = eck(1,1)       ! This is a layer
                        eck(2,4) = eck(2,1)       ! Set verticval corner
                        eck(3,4) = eck(3,1)       ! to lower left values
                        inc (1) = nint (werte (10) ) 
                        inc (2) = nint (werte (11) ) 
                        inc (3) = 1             ! No increment along vertical axis
                        divis (1) = float (max (1, inc (1) - 1) ) 
                        divis (2) = float (max (1, inc (2) - 1) ) 
                        divis (3) =             1
                        DO i = 1, 3 
                        vi (i, 1) = (eck (i, 2) - eck (i, 1) ) / divis (1)
                        vi (i, 2) = (eck (i, 3) - eck (i, 1) ) / divis (2)
                        vi (i, 3) = (eck (i, 4) - eck (i, 1) ) / divis (3)
                        ENDDO 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ENDIF 
!                                                                       
!     define the corners 'll', 'lr', 'ul'                               
!                                                                       
      ELSEIF (str_comp (befehl, 'll  ', 2, lbef, 4) .or. &
              str_comp (befehl, 'lr  ', 2, lbef, 4) .or. &
              str_comp (befehl, 'ul  ', 2, lbef, 4) .or. &
              str_comp (befehl, 'tl  ', 2, lbef, 4) ) then                                                              
               CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
               IF (ier_num.eq.0) then 
                  IF (ianz.eq.3) then 
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                     IF (ier_num.eq.0) then 
                        IF (str_comp (befehl, 'll  ', 2, lbef, 4) ) j = 1 
                        IF (str_comp (befehl, 'lr  ', 2, lbef, 4) ) j = 2 
                        IF (str_comp (befehl, 'ul  ', 2, lbef, 4) ) j = 3 
                        IF (str_comp (befehl, 'tl  ', 2, lbef, 4) ) j = 4 
                        IF (str_comp (befehl, 'tl  ', 2, lbef, 4) ) ltop = .true.
                        DO i = 1, 3 
                           eck (i, j) = werte (i) 
                        ENDDO 
                        DO i = 1, 3 
                           vi (i, 1) = (eck (i, 2) - eck (i, 1) ) / divis ( 1)                                              
                           vi (i, 2) = (eck (i, 3) - eck (i, 1) ) / divis ( 2)                                              
                           vi (i, 3) = (eck (i, 4) - eck (i, 1) ) / divis ( 3)                                              
                        ENDDO 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ENDIF 
!                                                                       
!     set Fourier volume (lots)                                         
!                                                                       
            ELSEIF (str_comp (befehl, 'lots', 3, lbef, 4) ) then 
               CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
               IF (ier_num.eq.0) then 
                  IF (ianz.eq.1) then 
                     CALL do_cap (cpara (1) ) 
                     IF (cpara (1) (1:1) .eq.'O') then 
                        ilots = LOT_OFF 
                        nlots = 1 
                     ELSE 
                        ier_num = - 6 
                        ier_typ = ER_COMM 
                     ENDIF 
                  ELSEIF (ianz.eq.6) then 
                     CALL do_cap (cpara (1) ) 
                     IF (cpara (1) (1:1) .eq.'B') then 
                        ilots = LOT_BOX 
                     ELSEIF (cpara (1) (1:1) .eq.'E') then 
                        ilots = LOT_ELI 
                     ELSE 
                        ier_num = - 2 
                        ier_typ = ER_FOUR 
                     ENDIF 
                     IF (ier_num.eq.0) then 
                        CALL del_params (1, ianz, cpara, lpara, maxw) 
                        CALL ber_params (ianz - 1, cpara, lpara, werte, &
                        maxw)                                           
                        IF (ier_num.eq.0) then 
                           ldim = .true. 
                           DO i = 1, 3 
                           ldim = ldim.and. (0..lt.nint (werte (i) )    &
                           .and.nint (werte (i) ) .le.cr_icc (i) )      
                           ENDDO 
                           IF (ldim) then 
                              ls_xyz (1) = nint (werte (1) ) 
                              ls_xyz (2) = nint (werte (2) ) 
                              ls_xyz (3) = nint (werte (3) ) 
                              nlots = nint (werte (4) ) 
                              CALL do_cap (cpara (5) ) 
                              lperiod = (cpara (5) (1:1) .eq.'Y') 
                           ELSE 
                              ier_num = - 101 
                              ier_typ = ER_APPL 
                           ENDIF 
                        ENDIF 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ENDIF 
!                                                                       
!     define the number of points along the abscissa 'na'               
!                                                                       
            ELSEIF (str_comp (befehl, 'nabs', 2, lbef, 4) ) then 
               CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
               IF (ier_num.eq.0) then 
                  IF (ianz.eq.1) then 
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                     IF (ier_num.eq.0) then 
                        IF (werte (1) .gt.0) then 
                           inc (1) = nint (werte (1) ) 
                           divis (1) = float (max (1, inc (1) - 1) ) 
                           DO i = 1, 3 
                           vi (i, 1) = (eck (i, 2) - eck (i, 1) ) / divis (1)                                  
                           vi (i, 2) = (eck (i, 3) - eck (i, 1) ) / divis (2)                                  
                           vi (i, 3) = (eck (i, 4) - eck (i, 1) ) / divis (3)                                  
                           ENDDO 
                        ELSE 
                           ier_num = - 12 
                           ier_typ = ER_APPL 
                        ENDIF 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ENDIF 
!                                                                       
!     switch to neutron diffraction 'neut'                              
!                                                                       
            ELSEIF (str_comp (befehl, 'neut', 2, lbef, 4) ) then 
               lxray = .false. 
               diff_radiation = RAD_NEUT
!                                                                       
!     define the number of points along the ordinate 'no'               
!                                                                       
            ELSEIF (str_comp (befehl, 'nord', 2, lbef, 4) ) then 
               CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
               IF (ier_num.eq.0) then 
                  IF (ianz.eq.1) then 
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                     IF (ier_num.eq.0) then 
                        IF (werte (1) .gt.0) then 
                           inc (2) = nint (werte (1) ) 
                           divis (2) = float (max (1, inc (2) - 1) ) 
                           DO i = 1, 3 
                           vi (i, 1) = (eck (i, 2) - eck (i, 1) ) / divis (1)
                           vi (i, 2) = (eck (i, 3) - eck (i, 1) ) / divis (2)
                           vi (i, 3) = (eck (i, 4) - eck (i, 1) ) / divis (3)                                  
                           ENDDO 
                        ELSE 
                           ier_num = - 12 
                           ier_typ = ER_APPL 
                        ENDIF 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ENDIF 
!                                                                       
!     define the number of points along the vertical 'ntop'               
!                                                                       
            ELSEIF (str_comp (befehl, 'ntop', 2, lbef, 4) ) then 
               CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
               IF (ier_num.eq.0) then 
                  IF (ianz.eq.1) then 
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                     IF (ier_num.eq.0) then 
                        IF (werte (1) .gt.0) then 
                           inc (3) = nint (werte (1) ) 
                           divis (3) = float (max (1, inc (3) - 1) ) 
                           DO i = 1, 3 
                           vi (i, 1) = (eck (i, 2) - eck (i, 1) ) / divis (1)
                           vi (i, 2) = (eck (i, 3) - eck (i, 1) ) / divis (2)
                           vi (i, 3) = (eck (i, 4) - eck (i, 1) ) / divis (3)                                  
                           ENDDO 
                           ltop = .true.
                        ELSE 
                           ier_num = - 12 
                           ier_typ = ER_APPL 
                        ENDIF 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ENDIF 
!                                                                       
!     define the ordinate  'ordi'                                       
!                                                                       
            ELSEIF (str_comp (befehl, 'ordi', 2, lbef, 4) ) then 
               CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
               IF (ianz.eq.1) then 
                  IF (cpara (1) .eq.'h') then 
                     extr_ord = 1 
                  ELSEIF (cpara (1) .eq.'k') then 
                     extr_ord = 2 
                  ELSEIF (cpara (1) .eq.'l') then 
                     extr_ord = 3 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ENDIF 
!                                                                       
!     start the Fourier transform 'run'                                 
!                                                                       
            ELSEIF (str_comp (befehl, 'run ', 1, lbef, 4) ) then 
               IF(.not.ltop) THEN           ! The three-D corner was never defined, assume 2D
                  eck(1,4) = eck(1,1)       ! This is a layer
                  eck(2,4) = eck(2,1)       ! Set verticval corner
                  eck(3,4) = eck(3,1)       ! to lower left values
                  vi (1,3) = 0.00
                  vi (2,3) = 0.00
                  vi (3,3) = 0.00
                  inc(3)   = 1
                  divis(3) = 1
               ENDIF
               IF (inc(1) * inc(2) *inc(3) .gt. MAXQXY  .OR.    &
                   cr_natoms > DIF_MAXAT                .OR.    &
                   cr_nscat>DIF_MAXSCAT              ) THEN
                 n_qxy    = MAX(n_qxy,inc(1)*inc(2)*inc(3),MAXQXY)
                 n_natoms = MAX(n_natoms,cr_natoms,DIF_MAXAT)
                 n_nscat  = MAX(n_nscat,cr_nscat,DIF_MAXSCAT)
                 call alloc_diffuse (n_qxy, n_nscat, n_natoms)
                 IF (ier_num.ne.0) THEN
                   RETURN
                 ENDIF
               ENDIF
               IF (inc (1) * inc (2) * inc(3) .le.MAXQXY) then 
                  CALL dlink (ano, lambda, rlambda, &
                              diff_radiation, diff_power) 
                  IF (four_mode.eq.INTERNAL) then 
                     IF (ier_num.eq.0) then 
                        four_log = .true. 
                        CALL four_run 
                     ENDIF 
                  ELSE 
                     four_log = .true. 
                     CALL four_external 
                  ENDIF 
                  four_was_run = .true.
               ELSE 
                  ier_num = - 8 
                  ier_typ = ER_APPL 
               ENDIF 
!                                                                       
!     define the scattering curve for an element 'scat'                 
!                                                                       
            ELSEIF (str_comp (befehl, 'scat', 2, lbef, 4) ) then 
               CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
               IF (ianz.eq.10. .or. ianz==12) then 
                  i = 1 
                  CALL get_iscat (i, cpara, lpara, werte, maxw, lold) 
                  IF (ier_num.eq.0) then 
                     IF (werte (1) .gt.0) then 
                        DO k = 1, i 
                        jj (k) = nint (werte (1) ) 
                        ENDDO 
                        cpara (1) = '0.0' 
                        lpara (1) = 3 
                        CALL ber_params (ianz, cpara, lpara, werte,     &
                        maxw)                                           
                        IF (ier_num.eq.0) then 
                           DO k = 1, i 
                           DO i = 2, ianz-1 
                           cr_scat (i, jj (k) ) = werte (i) 
                           ENDDO 
                           cr_scat (1, jj (k) ) = werte (ianz) 
                           cr_scat_int (jj (k) ) = .false. 
                           ENDDO 
                        ENDIF 
                     ELSE 
                        ier_num = - 27 
                        ier_typ = ER_APPL 
                     ENDIF 
                  ENDIF 
               ELSEIF (ianz.eq.2) then 
                  i = 1 
                  CALL get_iscat (i, cpara, lpara, werte, maxw, lold) 
                  IF (ier_num.eq.0) then 
                     IF (str_comp (cpara (2) , 'internal', 2, lpara (1) &
                     , 8) ) then                                        
                        IF (werte (1) .gt.0) then 
                           k = nint (werte (1) ) 
                           cr_scat_int (k) = .true. 
                           cr_scat_equ (k) = .false. 
                        ELSEIF (werte (1) .eq. - 1) then 
                           DO k = 0, cr_nscat 
                           cr_scat_int (k) = .true. 
                           cr_scat_equ (k) = .false. 
                           ENDDO 
                        ENDIF 
                     ELSE 
                        IF (werte (1) .gt.0) then 
                           k = nint (werte (1) ) 
                           cr_scat_equ (k) = .true. 
                           CALL do_cap (cpara (2) ) 
                           cr_at_equ (k) = cpara (2) (1:lpara(2))
                        ELSEIF (werte (1) .eq. - 1) then 
                           k = nint (werte (1) ) 
                           CALL do_cap (cpara (2) ) 
                           DO k = 1, cr_nscat 
                           cr_scat_equ (k) = .true. 
                           cr_at_equ (k) = cpara (2) (1:lpara(2))
                           ENDDO 
                        ELSE 
                           ier_num = - 27 
                           ier_typ = ER_APPL 
                        ENDIF 
                     ENDIF 
                  ENDIF 
               ELSE 
                  ier_num = - 6 
                  ier_typ = ER_COMM 
               ENDIF 
!                                                                       
!     set desired mode of Fourier transform 'set'                       
!                                                                       
            ELSEIF (str_comp (befehl, 'set', 2, lbef, 3) ) then 
               CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
               IF (ier_num.eq.0) then 
                  IF (ianz.ge.1.and.ianz.le.2) then 
                     IF (str_comp (cpara (1) , 'aver', 1, lpara (1) , 4)&
                     ) then                                             
                        IF (ianz.eq.1) then 
                           fave = 0.0 
                        ELSE 
                           CALL del_params (1, ianz, cpara, lpara, maxw) 
                           CALL ber_params (ianz, cpara, lpara, werte,  &
                           maxw)                                        
                           IF (ier_num.eq.0) then 
                              IF (werte (1) .ge.0.0.and.werte (1)       &
                              .le.100.0) then                           
                                 fave = werte (1) * 0.01 
                              ELSE 
                                 ier_num = - 1 
                                 ier_typ = ER_FOUR 
                              ENDIF 
                           ENDIF 
                        ENDIF 
                     ELSEIF (str_comp (cpara (1) , 'extern', 1, lpara ( &
                     1) , 6) ) then                                     
                        four_mode = EXTERNAL 
                     ELSEIF (str_comp (cpara (1) , 'intern', 1, lpara ( &
                     1) , 6) ) then                                     
                        four_mode = INTERNAL 
                     ELSE 
                        ier_num = - 1 
                        ier_typ = ER_FOUR 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ENDIF 
!                                                                       
!     Show the current settings for the Fourier 'show'                  
!                                                                       
            ELSEIF (str_comp (befehl, 'show', 2, lbef, 4) ) then 
               IF(.not.ltop) THEN           ! The three-D corner was never defined, assume 2D
                  eck(1,4) = eck(1,1)       ! This is a layer
                  eck(2,4) = eck(2,1)       ! Set verticval corner
                  eck(3,4) = eck(3,1)       ! to lower left values
                  vi (1,3) = 0.00
                  vi (2,3) = 0.00
                  vi (3,3) = 0.00
                  inc(3)   = 1
                  divis(3) = 1
               ENDIF
               CALL dlink (ano, lambda, rlambda, &
                           diff_radiation, diff_power) 
               CALL four_show  ( ltop )
!                                                                       
!     Switch usage of temperature coefficients on/off 'temp'            
!                                                                       
            ELSEIF (str_comp (befehl, 'temp', 1, lbef, 4) ) then 
               CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
               IF (ier_num.eq.0) then 
                  IF (ianz.eq.1) then 
                     IF (cpara (1) (1:2) .eq.'ig') then 
                        ldbw = .false. 
                     ELSEIF (cpara (1) (1:2) .eq.'us') then 
                        ldbw = .true. 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ENDIF 
!                                                                       
!     define the ordinate  'top'                                       
!                                                                       
            ELSEIF (str_comp (befehl, 'top', 2, lbef, 3) ) then 
               CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
               IF (ianz.eq.1) then 
                  IF (cpara (1) .eq.'h') then 
                     extr_top = 1 
                  ELSEIF (cpara (1) .eq.'k') then 
                     extr_top = 2 
                  ELSEIF (cpara (1) .eq.'l') then 
                     extr_top = 3 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
               ENDIF 
!                                                                       
!-------Operating System Kommandos 'syst'                               
!                                                                       
            ELSEIF (str_comp (befehl, 'syst', 2, lbef, 4) ) then 
               IF (zeile.ne.' ') then 
                  CALL do_operating (zeile (1:lp), lp) 
               ELSE 
                  ier_num = - 6 
                  ier_typ = ER_COMM 
               ENDIF 
!                                                                       
!------ waiting for user input                                          
!                                                                       
            ELSEIF (str_comp (befehl, 'wait', 3, lbef, 4) ) then 
               CALL do_input (zeile, lp) 
!                                                                       
!     set the wave length to be used 'wvle'                             
!                                                                       
            ELSEIF (str_comp (befehl, 'wvle', 1, lbef, 4) ) then 
               CALL do_cap (zeile) 
               CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
               IF (ianz.eq.1) then 
                  IF (ichar ('A') .le.ichar (cpara (1) (1:1) )          &
                  .and.ichar (cpara (1) (1:1) ) .le.ichar ('Z') ) then  
                     lambda = cpara (1) (1:lpara(1))
                  ELSE 
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                     rlambda = werte (1) 
                     lambda = ' ' 
                  ENDIF 
               ELSE 
                  ier_num = - 6 
                  ier_typ = ER_COMM 
               ENDIF 
!                                                                       
!     switch to x-ray diffraction 'xray'                                
!                                                                       
            ELSEIF (str_comp (befehl, 'xray', 1, lbef, 4) ) then 
               lxray = .true. 
               diff_radiation = RAD_XRAY
            ELSE 
               ier_num = - 8 
               ier_typ = ER_COMM 
            ENDIF 
         ENDIF 
      ENDIF 
!                                                                       
!------ end of command list                                             
!                                                                       
      IF (ier_num.ne.0) then 
         CALL errlist 
         IF (ier_sta.ne.ER_S_LIVE) then 
            IF (lmakro) then 
               CALL macro_close 
            ENDIF 
            IF (lblock) then 
               ier_num = - 11 
               ier_typ = ER_COMM 
               RETURN 
            ENDIF 
            CALL no_error 
         ENDIF 
      ENDIF 
      GOTO 10 
 9999 CONTINUE 
!                                                                       
      END SUBROUTINE fourier                        
!*****7*****************************************************************
      SUBROUTINE four_show ( ltop )
!+                                                                      
!     prints summary of current fourier settings                        
!-                                                                      
      USE discus_config_mod 
      USE diffuse_mod 
      USE metric_mod
      USE output_mod 
      USE prompt_mod 
      IMPLICIT none 
!                                                                       
!
      LOGICAL, INTENT(IN) :: ltop
!                                                                       
      CHARACTER(8) radiation 
      CHARACTER (LEN=8), DIMENSION(3), PARAMETER :: c_rad = (/ &
         'X-ray   ', 'neutron ', 'electron' /)
      CHARACTER(LEN=1), DIMENSION(0:3)           ::  extr_achs (0:3) 
      REAL            , DIMENSION(3)             ::  hor
      REAL            , DIMENSION(3)             ::  ver
      REAL            , DIMENSION(3)             ::  top
      REAL                                       ::  angle_vh
      REAL                                       ::  ratio_vh
      REAL                                       ::   aver_vh
      REAL                                       ::  angle_ht
      REAL                                       ::  ratio_ht
      REAL                                       ::   aver_ht
      REAL                                       ::  angle_tv
      REAL                                       ::  ratio_tv
      REAL                                       ::   aver_tv
      REAL            , DIMENSION(3)             ::  zero = (/0.0, 0.0, 0.0/)
      REAL            , DIMENSION(3)             ::  length = (/0.0, 0.0, 0.0/)
      INTEGER i, j 
      LOGICAL lspace 
!                                                                       
!     REAL do_blen, do_bang 
!                                                                       
      DATA extr_achs / ' ', 'h', 'k', 'l' / 
!                                                                       
      IF (fave.eq.0.0) then 
         WRITE (output_io, 1010) 
      ELSE 
         WRITE (output_io, 1020) fave * 100.0 
      ENDIF 
      IF (four_mode.eq.INTERNAL) then 
         WRITE (output_io, 1030) 'atom form factors' 
      ELSEIF (four_mode.eq.EXTERNAL) then 
         WRITE (output_io, 1030) 'object form factors' 
      ENDIF 
!                                                                       
      IF (ilots.eq.LOT_OFF) then 
         WRITE (output_io, 1100) 
      ELSEIF (ilots.eq.LOT_BOX) then 
         WRITE (output_io, 1110) nlots 
         WRITE (output_io, 1130) (ls_xyz (i), i = 1, 3), lperiod 
      ELSEIF (ilots.eq.LOT_ELI) then 
         WRITE (output_io, 1120) nlots 
         WRITE (output_io, 1130) (ls_xyz (i), i = 1, 3), lperiod 
      ENDIF 
!                                                                       
      radiation = 'neutron' 
      IF (lxray) radiation = 'x-ray' 
      radiation = c_rad(diff_radiation)
      IF (lambda.eq.' ') then 
         WRITE (output_io, 1200) radiation, rlambda 
      ELSE 
         WRITE (output_io, 1210) radiation, lambda, rlambda 
      ENDIF 
!                                                                       
      IF (ldbw) then 
         WRITE (output_io, 1300) 'used' 
      ELSE 
         WRITE (output_io, 1300) 'ignored' 
      ENDIF 
!                                                                       
      IF (ano) then 
         WRITE (output_io, 1310) 'used' 
      ELSE 
         WRITE (output_io, 1310) 'ignored' 
      ENDIF 
!                                                                       
!    !DO i = 1, 3 
!    !u (i) = vi (i, 1) 
!     v (i) = 0.0 
!     w (i) = vi (i, 2) 
!     ENDDO 
!     lspace = .false. 
!     dvi1 = do_blen (lspace, u, zero) 
!     dvi2 = do_blen (lspace, w, zero) 
!     IF (inc (1) .gt.1.and.inc (2) .gt.1) then 
!        dvi3 = do_bang (lspace, u, zero, w) 
!     ELSE 
!        dvi3 = 0.0 
!     ENDIF 
!     IF (dvi3.gt.0) then 
!        dvi4 = dvi2 / dvi1 
!        IF (abs (u (extr_abs) ) .gt.0.0.and.abs (w (extr_ord) )        &
!        .gt.0.0) then                                                  
!           dvi5 = (dvi2 / w (extr_ord) ) / (dvi1 / u (extr_abs) ) 
!        ELSE 
!           ier_num = - 4 
!           ier_typ = ER_FOUR 
!        ENDIF 
!     ELSE 
!        dvi4 = 0.0 
!        dvi5 = 0.0 
!     ENDIF 
!
!     Calculate lengths in Ang-1
!
      hor(:) = vi(:,1)
      ver(:) = vi(:,2)
      top(:) = vi(:,3)
      length = 0.0
      IF(inc(1)>1) length(1) = do_blen(lspace,hor,zero)
      IF(inc(2)>1) length(2) = do_blen(lspace,ver,zero)
      IF(inc(3)>1) length(3) = do_blen(lspace,top,zero)
      CALL angle(angle_vh, inc(2), inc(1), ver, hor,        &
                 length(2), length(1), extr_ord, extr_abs,  &
                 ratio_vh, aver_vh)
      IF(ltop .AND. inc(3)>1) THEN
         CALL angle(angle_ht, inc(3), inc(1), hor, top,        &
                    length(1), length(3), extr_abs, extr_top,  &
                    ratio_ht, aver_ht)
         CALL angle(angle_tv, inc(3), inc(2), top, ver,        &
                    length(3), length(2), extr_top, extr_ord,  &
                    ratio_tv, aver_tv)
      ENDIF
!                                                                       
      WRITE (output_io, 1400) ( (eck (i, j), i = 1, 3), j = 1, 4) 
      WRITE (output_io, 1410) (vi (i, 1), i = 1, 3), length(1), &
                              (vi (i, 2), i = 1, 3), length(2), &
                              (vi (i, 3), i = 1, 3), length(3)
      WRITE (output_io, 1420) (inc (i), i = 1, 3), extr_achs (extr_abs),&
      extr_achs (extr_ord), extr_achs(extr_top)                          
      WRITE (output_io, 1430) 'v/h',angle_vh, ratio_vh, aver_vh
      IF(ltop .AND. inc(3)>1) THEN
         WRITE (output_io, 1430) 'h/t',angle_ht, ratio_ht, aver_ht
         WRITE (output_io, 1430) 't/v',angle_tv, ratio_tv, aver_tv
      ENDIF
!                                                                       
 1010 FORMAT (  ' Fourier technique    : turbo Fourier') 
 1020 FORMAT (  ' Fourier technique    : turbo Fourier, minus <F>',     &
     &          ' (based on ',F5.1,'% of cryst.)')                      
 1030 FORMAT (  ' Fourier calculated by: ',a) 
 1100 FORMAT (  '   Fourier volume     : complete crystal') 
 1110 FORMAT (  '   Fourier volume     : ',I4,' box shaped lots') 
 1120 FORMAT (  '   Fourier volume     : ',I4,' ellipsoid shaped lots') 
 1130 FORMAT (  '   Lot size           : ',I3,' x ',I3,' x ',I3,        &
     &          ' unit cells (periodic boundaries = ',L1,')')           
 1200 FORMAT (  '   Radiation          : ',A,', wavelength = ',         &
     &          F7.4,' A')                                              
 1210 FORMAT (  '   Radiation          : ',A,', wavelength = ',A4,      &
     &          ' = ',F7.4,' A')                                        
 1300 FORMAT (  '   Temp. factors      : ',A) 
 1310 FORMAT (  '   Anomalous scat.    : ',A) 
 1400 FORMAT (/,' Reciprocal layer     : ',/                            &
     &          '   lower left  corner : ',3(2x,f9.4),/                 &
     &          '   lower right corner : ',3(2x,f9.4),/                 &
     &          '   upper left  corner : ',3(2x,f9.4),/                 &
     &          '   top   left  corner : ',3(2x,f9.4))                  
 1410 FORMAT (/,'   hor. increment     : ',3(2x,f9.4),2x,               &
     &          ' -> ',f9.4,' A**-1',/                                  &
     &          '   vert. increment    : ',3(2x,f9.4),2x,               &
     &          ' -> ',f9.4,' A**-1',/                                  &
     &          '   top   increment    : ',3(2x,f9.4),2x,               &
     &          ' -> ',f9.4,' A**-1')                                   
 1420 FORMAT (  '   # of points        :  ',I5,' x',I5,' x',I5,'  (',   &
     &          A1,',',A1,',',A1,')')                                          
 1430 FORMAT (  '   Angle Ratio Aver ',a3, 3x,f9.4,' degrees',3x        &
     &                                    ,2(2x,f9.4))                  
      END SUBROUTINE four_show 
!
!
      SUBROUTINE angle(angle_vh, inc2, inc1, ver, hor , &
                 length2, length1, extr_ord, extr_abs,  &
                 ratio_vh, aver_vh)
!
      USE metric_mod
      IMPLICIT NONE
!
      REAL              , INTENT(OUT):: angle_vh
      INTEGER           , INTENT(IN) :: inc1
      INTEGER           , INTENT(IN) :: inc2
      REAL, DIMENSION(3), INTENT(IN) :: hor
      REAL, DIMENSION(3), INTENT(IN) :: ver
      REAL              , INTENT(IN) :: length1
      REAL              , INTENT(IN) :: length2
      INTEGER           , INTENT(IN) :: extr_abs
      INTEGER           , INTENT(IN) :: extr_ord
      REAL              , INTENT(OUT):: ratio_vh
      REAL              , INTENT(OUT):: aver_vh
!
      REAL   , DIMENSION(3) :: zero = (/0.0, 0.0, 0.0/)
      LOGICAL, PARAMETER    :: lspace =.true.
!
!     REAL do_bang 
!
      angle_vh = 0.0
      ratio_vh = 0.0 
      aver_vh  = 0.0 
      IF( inc1>1 .and. inc2>1 )THEN
         angle_vh = do_bang (lspace, hor, zero, ver) 
         ratio_vh = length2 / length1 
         IF (abs (hor(extr_abs)) > 0.0  .and. abs (ver(extr_ord)) >   0.0) then                                                  
            aver_vh = (length2 / ver(extr_ord) ) / (length1 / hor(extr_abs) ) 
         ELSE 
            ier_num = - 4 
            ier_typ = ER_FOUR 
         ENDIF 
      ELSE 
      ENDIF 
!
      END SUBROUTINE angle
END MODULE fourier_menu
