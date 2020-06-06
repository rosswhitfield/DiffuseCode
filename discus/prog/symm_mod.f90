MODULE symm_mod
!+
!
!     variables needed for the generalized symmetry operations
!-
!
!
SAVE
!
INTEGER, PARAMETER       :: SYM_RUN_MOLECULE = 0
INTEGER, PARAMETER       :: SYM_RUN_DOMAIN   = 1
!
INTEGER                                      ::  SYM_MAXSCAT = 1
INTEGER                                      ::  SYM_MAXSITE = 1
!
LOGICAL,          DIMENSION(:), ALLOCATABLE  ::  sym_latom   ! (0:SYM_MAXSCAT)
LOGICAL,          DIMENSION(:), ALLOCATABLE  ::  sym_lsite   ! (0:SYM_MAXSCAT)
!
CHARACTER (LEN = 4)      :: sym_incl       = 'list'
INTEGER                  :: sym_use        = 0  ! Use space group symmetry operation no. N
INTEGER                  :: sym_sel_mode   = 0
INTEGER, DIMENSION(0:1)  :: sym_sel_prop   = (/0,0/)
INTEGER                  :: sym_start      = 1
INTEGER                  :: sym_end        = 1
INTEGER                  :: sym_sub_start  = 1
INTEGER                  :: sym_sub_end    = 1
INTEGER                  :: sym_n_excl     = 1
INTEGER, DIMENSION(:), ALLOCATABLE  :: sym_excl
INTEGER                  :: sym_power      = 1
INTEGER                  :: sym_axis_type  = 0  ! axis type (0 abolute, 1 atoms in crystal, -1 atoms in mol
INTEGER, DIMENSION(3)    :: sym_axis_atoms = 0  ! Atoms that define the axis
INTEGER                  :: sym_orig_type  = 0  ! origin type (0 abolute, 1 atoms in crystal, -1 atoms in mol
INTEGER                  :: sym_orig_atom  = 1  ! Atom at origin of symmetry operation
LOGICAL                  :: sym_mode       = .true.
LOGICAL                  :: sym_new        = .false.
LOGICAL                  :: sym_orig_mol   = .true.
LOGICAL                  :: sym_power_mult = .true.
LOGICAL                  :: sym_type       = .true.
LOGICAL                  :: sym_occup      = .false.
LOGICAL                  :: sym_sel_atom   = .true.
LOGICAL                  :: sym_sel_sub    = .FALSE.
LOGICAL                  :: sym_dom_mode_shape = .false.
LOGICAL                  :: sym_dom_mode_atom  = .false.
REAL                     :: sym_angle     = 0.0
REAL                     :: sym_radius    = 1.0E-8
REAL, DIMENSION(3)       :: sym_hkl       = (/0.0, 0.0, 1.0/)
REAL, DIMENSION(3)       :: sym_orig      = (/0.0, 0.0, 0.0/)
REAL, DIMENSION(3)       :: sym_or_tr     = (/0.0, 0.0, 0.0/)
REAL, DIMENSION(3)       :: sym_trans     = (/0.0, 0.0, 0.0/)
REAL, DIMENSION(3)       :: sym_uvw       = (/0.0, 0.0, 1.0/)
REAL, DIMENSION(4,4)     :: sym_mat       = 0.0
REAL, DIMENSION(4,4)     :: sym_rmat      = 0.0
!
INTEGER                  :: sym_size_of  ! Bytes allocated for symmetry
!
END MODULE symm_mod
MODULE symm_temp_mod
!+
!
!     variables needed for the generalized symmetry operations
!-
!
!
SAVE
!
INTEGER, PARAMETER                           :: SYM_RUN_MOLECULE = 0
INTEGER, PARAMETER                           :: SYM_RUN_DOMAIN   = 1
!
INTEGER                                      ::  SYM_TEMP_MAXSCAT = 1
INTEGER                                      ::  SYM_TEMP_MAXSITE = 1
!
LOGICAL,          DIMENSION(:), ALLOCATABLE  ::  sym_TEMP_latom   ! (0:SYM_MAXSCAT)
LOGICAL,          DIMENSION(:), ALLOCATABLE  ::  sym_TEMP_lsite   ! (0:SYM_MAXSCAT)
!
CHARACTER (LEN = 4)      :: sym_temp_incl       = 'list'
INTEGER                  :: sym_temp_use        = 0  ! Use space group symmetry operation no. N
INTEGER                  :: sym_temp_sel_mode   = 0
INTEGER, DIMENSION(0:1)  :: sym_temp_sel_prop   = (/0,0/)
INTEGER                  :: sym_temp_start      = 1
INTEGER                  :: sym_temp_end        = 1
INTEGER                  :: sym_temp_sub_start  = 1
INTEGER                  :: sym_temp_sub_end    = 1
INTEGER                  :: sym_temp_n_excl     = 1
INTEGER, DIMENSION(:), ALLOCATABLE  :: sym_temp_excl
INTEGER                  :: sym_temp_power      = 1
INTEGER                  :: sym_temp_axis_type  = 0  ! axis type (0 abolute, 1 atoms in crystal, -1 atoms in mol
INTEGER, DIMENSION(3)    :: sym_temp_axis_atoms = 0  ! Atoms that define the axis
INTEGER                  :: sym_temp_orig_type  = 0  ! origin type (0 abolute, 1 atoms in crystal, -1 atoms in mol
INTEGER                  :: sym_temp_orig_atom  = 1  ! Atom at origin of symmetry operation
LOGICAL                  :: sym_temp_mode       = .true.
LOGICAL                  :: sym_temp_new        = .false.
LOGICAL                  :: sym_temp_orig_mol   = .true.
LOGICAL                  :: sym_temp_power_mult = .true.
LOGICAL                  :: sym_temp_type       = .true.
LOGICAL                  :: sym_temp_occup      = .false.
LOGICAL                  :: sym_temp_sel_atom   = .true.
LOGICAL                  :: sym_temp_sel_sub    = .FALSE.
LOGICAL                  :: sym_temp_dom_mode_shape = .false.
LOGICAL                  :: sym_temp_dom_mode_atom  = .false.
REAL                     :: sym_temp_angle     = 0.0
REAL                     :: sym_temp_radius    = 1.0E-8
REAL, DIMENSION(3)       :: sym_temp_hkl       = (/0.0, 0.0, 1.0/)
REAL, DIMENSION(3)       :: sym_temp_orig      = (/0.0, 0.0, 0.0/)
REAL, DIMENSION(3)       :: sym_temp_or_tr     = (/0.0, 0.0, 0.0/)
REAL, DIMENSION(3)       :: sym_temp_trans     = (/0.0, 0.0, 0.0/)
REAL, DIMENSION(3)       :: sym_temp_uvw       = (/0.0, 0.0, 1.0/)
REAL, DIMENSION(4,4)     :: sym_temp_mat       = 0.0
REAL, DIMENSION(4,4)     :: sym_temp_rmat      = 0.0
!
INTEGER                  :: sym_size_of  ! Bytes allocated for symmetry
!
END MODULE symm_temp_mod
