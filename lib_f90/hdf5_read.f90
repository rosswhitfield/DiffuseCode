module lib_hdf5_read_mod
!
! Load an HDF5 file into the lib_f90 data structure
!
use errlist_mod
use lib_data_struc_h5
use lib_hdf5_params_mod
use hdf5_def_mod
use precision_mod
!
private
public hdf5_read
!
CHARACTER(LEN=PREC_STRING)                            :: h5_infile         ! input file
CHARACTER(LEN=PREC_STRING), DIMENSION(:), ALLOCATABLE :: h5_datasets       ! Names of the data set in file
!INTEGER                                               :: h5_number   = 0   ! Currently loaded h5 data sets
INTEGER                                               :: ndims             ! Number of dimensions
INTEGER                                               :: one_ndims         ! Number of dimensions
INTEGER                                               :: H5_MAX_DATASETS   ! Current MAX data sets
INTEGER                                               :: h5_n_datasets     ! Current actual data sets
INTEGER                                               :: h5_layer=1        ! Current layer in data set
INTEGER(KIND=LIB_HSIZE_T), DIMENSION(3)               :: h5_dims           ! Actual dimensions
INTEGER(KIND=LIB_HSIZE_T), DIMENSION(3)               :: maxdims           ! Maximum dimensions
INTEGER(KIND=LIB_HSIZE_T), DIMENSION(3)               :: one_dims          ! Actual dimensions
INTEGER(KIND=LIB_HSIZE_T), DIMENSION(3)               :: one_maxdims       ! Maximum dimensions
LOGICAL                                               :: h5_direct         ! Direct space == TRUE
REAL(KIND=PREC_SP)   , DIMENSION(:,:,:), ALLOCATABLE  :: h5_data           ! Actual diffraction data
REAL(KIND=PREC_DP)   , DIMENSION(3)                   :: h5_llims          ! Lower limits
REAL(KIND=PREC_DP)   , DIMENSION(3)                   :: h5_steps          ! steps in H, K, L
REAL(KIND=PREC_DP)   , DIMENSION(3,3)                 :: h5_steps_full     ! steps in H, K, L
!
CONTAINS
!
!*******************************************************************************
!
SUBROUTINE hdf5_read(infile, length, O_LAYER, NOPTIONAL, opara, lopara,         &
                     lpresent, owerte,               &
                     MAXARRAY, MAXKURVTOT, fname, iz, x, y, z, nx, ny, &
                     xmin, xmax, ymin, ymax, offxy, offz, lni, lh5, lenc,       &
                     ier_num, ier_typ, idims, ier_msg, ER_APPL, ER_IO, output_io)
!
USE hdf5
USE iso_c_binding
!
USE ber_params_mod
use precision_mod
!
IMPLICIT NONE
!
CHARACTER(LEN=1024), INTENT(IN) :: infile
INTEGER            , INTENT(IN) :: length
INTEGER            , INTENT(IN) :: O_LAYER
INTEGER            , INTENT(IN) :: NOPTIONAL
CHARACTER(LEN=*)   , DIMENSION(NOPTIONAL), INTENT(IN) :: opara
INTEGER            , DIMENSION(NOPTIONAL), INTENT(IN) :: lopara
LOGICAL            , DIMENSION(NOPTIONAL), INTENT(IN) :: lpresent
REAL(KIND=PREC_DP) , DIMENSION(NOPTIONAL), INTENT(IN) :: owerte
INTEGER, INTENT(IN)    :: MAXARRAY     ! KUPLOT array size
INTEGER, INTENT(IN)    :: MAXKURVTOT   ! KUPLOT array size
CHARACTER(LEN=200), DIMENSION(MAXKURVTOT), INTENT(INOUT) :: fname
INTEGER, INTENT(INOUT) :: iz     ! KUPLOT data set number
REAL(kind=PREC_DP), DIMENSION(MAXARRAY)  , INTENT(INOUT) :: x
REAL(kind=PREC_DP), DIMENSION(MAXARRAY)  , INTENT(INOUT) :: y
REAL(kind=PREC_DP), DIMENSION(MAXARRAY)  , INTENT(INOUT) :: z
INTEGER, DIMENSION(MAXKURVTOT), INTENT(INOUT) :: nx
INTEGER, DIMENSION(MAXKURVTOT), INTENT(INOUT) :: ny
REAL(kind=PREC_DP), DIMENSION(MAXKURVTOT), INTENT(INOUT) :: xmax ! (maxkurvtot)
REAL(kind=PREC_DP), DIMENSION(MAXKURVTOT), INTENT(INOUT) :: xmin ! (maxkurvtot)
REAL(kind=PREC_DP), DIMENSION(MAXKURVTOT), INTENT(INOUT) :: ymax ! (maxkurvtot)
REAL(kind=PREC_DP), DIMENSION(MAXKURVTOT), INTENT(INOUT) :: ymin
INTEGER, DIMENSION(0:maxkurvtot), INTENT(INOUT) :: offxy
INTEGER, DIMENSION(0:maxkurvtot), INTENT(INOUT) :: offz
LOGICAL, DIMENSION(  maxkurvtot), INTENT(INOUT) :: lni
LOGICAL, DIMENSION(0:maxkurvtot), INTENT(INOUT) :: lh5
INTEGER, DIMENSION(  MAXKURVTOT), INTENT(INOUT) :: lenc
!
INTEGER,                            INTENT(OUT)   :: ier_num
INTEGER,                            INTENT(OUT)   :: ier_typ
INTEGER,                            INTENT(IN )   :: idims
CHARACTER(LEN=*), DIMENSION(idims), INTENT(INOUT) :: ier_msg    ! Error message
INTEGER,                            INTENT(IN )   :: ER_APPL
INTEGER,                            INTENT(IN )   :: ER_IO
INTEGER, INTENT(IN)    :: output_io   ! KUPLOT array size
!
!INTEGER(KIND=SIZE_T), PARAMETER :: f_str_len = 20  ! Length F-string to receive  
!
CHARACTER(LEN=14)   :: dataname    ! Dummy name for HDF5 datasets
!CHARACTER(LEN=f_str_len)   :: progname    ! Program that created H5 FILE 
!CHARACTER(LEN=f_str_len), DIMENSION(:), ALLOCATABLE, TARGET   :: rstring    ! string that is read
!CHARACTER(LEN=9), DIMENSION(1:1), TARGET ::  rstring
INTEGER(KIND=HID_T) :: file_id     ! File identifier
!INTEGER(KIND=HID_T) :: filetype    ! Filetype identifier
!INTEGER(KIND=HID_T) ::  memtype    ! Mem type identifier
INTEGER(KIND=HID_T) :: dset_id     ! dataset identifier
INTEGER(KIND=HID_T) :: space_id    ! space identifier
!INTEGER(KIND=SIZE_T) :: c_str_len  ! Length C-string in 'PROGRAM'
!INTEGER(KIND=HSIZE_T), DIMENSION(2) :: cdims
!INTEGER(KIND= SIZE_T), DIMENSION(2) :: clens=(/8,1/)
INTEGER             :: hdferr      ! Error number
INTEGER(KIND=HSIZE_T) :: idx
INTEGER             :: ret_value   ! Error number
TYPE(C_FUNPTR)      :: funptr      ! Pointer to display function
TYPE(C_PTR), DIMENSION(:), ALLOCATABLE, TARGET :: rdata   ! READ buffer
TYPE(C_PTR)         :: f_ptr        ! Pointer to data elements
TYPE(C_PTR) :: ptr
CHARACTER(LEN=1024, KIND=c_char),  POINTER ::  rstring
INTEGER(KIND=2), TARGET :: r_is_direct
!INTEGER(KIND=2), DIMENSION(10), TARGET :: rstring
!INTEGER(HSIZE_T) :: nummer
!
INTEGER, PARAMETER                          :: MAXW = 1
INTEGER                                     :: ianz
CHARACTER(LEN=PREC_STRING), DIMENSION(MAXW) :: cpara
INTEGER                   , DIMENSION(MAXW) :: lpara
REAL(KIND=PREC_DP)        , DIMENSION(MAXW) :: werte
REAL(KIND=PREC_DP)        , DIMENSION(3)    :: steps     ! dummy steps in H, K, L
INTEGER :: i,j                      ! Dummy loop indices
INTEGER :: nlayer                   ! Layer to place into KUPLOT
!
h5_infile = infile
dataname = ' '
!dset_id  = 0
!file_id  = 0
!write(*,*) 'SETTING NEW NODE '
CALL hdf5_new_node
!write(*,*) 'DONE    NEW NODE '
!
!
H5_MAX_DATASETS = 10                                        ! Initial estimate of dataset number
ALLOCATE(h5_datasets(H5_MAX_DATASETS))
h5_n_datasets = 0                                           ! Currently no datasets found
!
h5_dims    = 1
maxdims = 1
CALL H5open_f(hdferr)                                       ! Open access to HDF5 stream
CALL H5Eset_auto_f(1, hdferr)                              ! Turn Error messages off
!
CALL H5Fopen_f(h5_infile, H5F_ACC_RDWR_F, file_id, hdferr)     ! Open existing file
IF(hdferr/=0) THEN
   CALL hdf5_error(h5_infile, file_id, dataname, dset_id, ier_num, ier_typ, idims,ier_msg,&
                   -2, ER_IO, 'Could not open ''H5'' file')
   RETURN
ENDIF
!
idx = 0
funptr = C_FUNLOC(op_func) ! call back function
ptr    = C_NULL_PTR
 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Iterate across file to obtain format, and list of datasets
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
CALL H5Literate_f(file_id, H5_INDEX_NAME_F, H5_ITER_NATIVE_F, idx, funptr, ptr, ret_value, hdferr)
IF(hdferr/=0) THEN
   dataname = ' '
   dset_id  = 0
   CALL hdf5_error(h5_infile, file_id, dataname, dset_id, ier_num, ier_typ, idims,ier_msg,&
                   -70, ER_APPL, 'Initial iteration failed')
   RETURN
ENDIF
!
IF(h5_n_datasets<1) THEN
   dataname = ' '
   dset_id  = 0
   CALL hdf5_error(h5_infile, file_id, dataname, dset_id, ier_num, ier_typ, idims,ier_msg,&
                   -69, ER_APPL, 'No datasets in H5 file')
   RETURN
ENDIF
!write(*,*) 'NUMBER of data sets found ', h5_n_datasets
yd_present = .false.              ! Assume all data set missing
DO i=1,h5_n_datasets
   loop_ydnd:do j=1, YD_ND
      if(h5_datasets(i)==yd_datasets(j)) then
         yd_present(j) = .true.
         exit loop_ydnd
      endif
   enddo loop_ydnd
!   WRITE(*,*) ' DATASETS ', h5_datasets(i)(1:LEN_TRIM(h5_datasets(i)))
ENDDO
!do j=1, YD_ND
!   write(*,*) ' DATASETS ', yd_present(j),yd_datasets(j)
!enddo
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! get the format identifier
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
dataname = 'format'
CALL H5Dopen_f(file_id, dataname, dset_id, hdferr)           ! Open the 'format'
IF(hdferr/=0) THEN
   CALL hdf5_error(h5_infile, file_id, dataname, dset_id, ier_num, ier_typ, idims,ier_msg,&
                   -69, ER_APPL, 'Dataset does not exist')
   RETURN
ENDIF
!CALL H5Dget_storage_size_f(dset_id, nummer, hdferr)          ! Get rough storage size
!
ALLOCATE(rdata(1:1024))
f_ptr = C_LOC(rdata(1))
CALL H5Dread_F(dset_id, H5T_STRING, f_ptr, hdferr)
CALL C_F_POINTER(rdata(1), rstring)
j = 0
DO
   IF(j>8) EXIT
   IF(rstring(j+1:j+1)==C_NULL_CHAR) EXIT
   j = j+1
ENDDO
!write(*,*) ' RSTRING ', rstring(1:j), ' J ', j, LEN_TRIM(rstring)
CALL H5Dclose_f(dset_id , hdferr)
!
DEALLOCATE(rdata)
!
IF(rstring(1:j)/='Yell 1.0') THEN
   CALL hdf5_error(h5_infile, file_id, rstring, dset_id, ier_num, ier_typ, idims,ier_msg,&
                   -69, ER_APPL, 'format dataset has wrong value')
   RETURN
ENDIF
!
!Qdataname  = 'PROGRAM'
!QCALL H5Dopen_f(file_id, dataname, dset_id, hdferr)           ! Open the 'PROGRAM'
!Qwrite(*,*) ' PROGRAM open  ', hdferr
!Q!
!Q! Get the datatype and its size.
!Q!
!QCALL H5Dget_type_f(dset_id, filetype, hdferr)
!Qwrite(*,*) ' GET_TYPE  ', hdferr
!QCALL H5Tget_size_f(filetype, c_str_len, hdferr)
!Qwrite(*,*) ' C_STR_LEN ', c_str_len, hdferr
!QIF(c_str_len> f_str_len+1) THEN                              ! Fortran string is too short
!Q   CALL H5Dclose_f(dset_id , hdferr)
!Q   CALL H5close_f(hdferr)                                    ! Close HDF interface
!Q   RETURN
!QENDIF
!Q!
!Q! Get dataspace.
!Q!
!QCALL H5Dget_space_f(dset_id, space_id, hdferr)
!Qwrite(*,*) ' GET_SPACE  ', hdferr
!QCALL H5Sget_simple_extent_dims_f(space_id, one_dims, one_maxdims, hdferr)
!Qwrite(*,*) ' GET_EXTENT ', one_dims, hdferr
!QALLOCATE(rstring(1:one_dims(1)))
!Q!
!Q! Create the memory datatype.
!Q!
!QCALL H5Tcopy_f(H5T_FORTRAN_S1, memtype, hdferr)
!QCALL H5Tset_size_f(memtype, f_str_len, hdferr)
!Q!
!Q! Read the data.
!Q!
!Qf_ptr = C_LOC(rstring(1)(1:1))
!QCALL H5Dread_f(dset_id, memtype, f_ptr, hdferr, space_id)
!Qprogname = ' '
!Qprogname = rstring(1)
!Qwrite(*,*) ' PROGNAME ', progname
!Qwrite(*,*) ' RSTRING  ', rstring
!Q!
!QCALL H5Dclose_f(dset_id, hdferr)                             ! Close the dataset file
!QCALL H5Sclose_f(space_id, hdferr)
!QCALL H5Tclose_f(filetype, hdferr)
!QCALL H5Tclose_f(memtype, hdferr)
!Q!CALL H5Fclose_f(file_id, hdferr)
!Qwrite(*,*) ' PROGRAM close ', hdferr
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! get the data
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
dataname='data'
CALL H5Dopen_f(file_id, dataname, dset_id, hdferr)           ! Open the dataset
CALL H5Dget_space_f(dset_id, space_id, hdferr)
CALL H5Sget_simple_extent_ndims_f(space_id, ndims, hdferr)   ! Get the number of dimensions in data set
CALL H5Sget_simple_extent_dims_f(space_id, h5_dims, maxdims, hdferr)   ! Get the dimensions in data set
!write(*,*) ' h5_dims ', h5_dims
IF(ALLOCATED(h5_data)) DEALLOCATE(h5_data)
ALLOCATE(h5_data(h5_dims(1), h5_dims(2), h5_dims(3)))
CALL H5Dread_f(dset_id, H5T_NATIVE_REAL, h5_data, h5_dims, hdferr)
CALL H5Dclose_f(dset_id, hdferr)                             ! Close the dataset file
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Get the limits
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
dataname = 'lower_limits'
one_dims    = 1
one_maxdims = 1
CALL H5Dopen_f(file_id, dataname, dset_id, hdferr)           ! Open the dataset
CALL H5Dget_space_f(dset_id, space_id, hdferr)
CALL H5Sget_simple_extent_ndims_f(space_id, one_ndims, hdferr)   ! Get the number of dimensions in data set
CALL H5Sget_simple_extent_dims_f(space_id, one_dims, one_maxdims, hdferr)   ! Get the dimensions in data set
CALL H5Dread_f(dset_id, H5T_NATIVE_DOUBLE, h5_llims, one_dims, hdferr)
CALL H5Dclose_f(dset_id, hdferr)                             ! Close the dataset file
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Get the is_direct dataset
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
dataname = 'is_direct'
CALL H5Dopen_f(file_id, dataname, dset_id, hdferr)           ! Open the dataset
CALL H5Dget_space_f(dset_id, space_id, hdferr)
f_ptr = C_LOC(r_is_direct)
CALL H5Dread_F(dset_id, H5T_STD_I8BE , f_ptr, hdferr)
CALL H5Dclose_f(dset_id, hdferr)
h5_direct = 1 == r_is_direct
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Get the stepss
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
dataname = 'step_sizes'
one_dims    = 1
one_maxdims = 1
CALL H5Dopen_f(file_id, dataname, dset_id, hdferr)           ! Open the dataset
CALL H5Dget_space_f(dset_id, space_id, hdferr)
CALL H5Sget_simple_extent_ndims_f(space_id, one_ndims, hdferr)   ! Get the number of dimensions in data set
CALL H5Sget_simple_extent_dims_f(space_id, one_dims, one_maxdims, hdferr)   ! Get the dimensions in data set
CALL H5Dread_f(dset_id, H5T_NATIVE_DOUBLE, h5_steps, one_dims, hdferr)
CALL H5Dclose_f(dset_id, hdferr)                             ! Close the dataset file
!write(*,*) ' H5_steps      ', h5_steps
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Get the steps DISCUS style
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
if(yd_present(YD_step_sizes_abs)) then
   dataname = 'step_sizes_abs'
   one_dims    = 1
   one_maxdims = 1
   CALL H5Dopen_f(file_id, dataname, dset_id, hdferr)           ! Open the dataset
   if(hdferr==0) then
      CALL H5Dget_space_f(dset_id, space_id, hdferr)
      CALL H5Sget_simple_extent_ndims_f(space_id, one_ndims, hdferr)   ! Get the number of dimensions in data set
      CALL H5Sget_simple_extent_dims_f(space_id, one_dims, one_maxdims, hdferr)   ! Get the dimensions in data set
      CALL H5Dread_f(dset_id, H5T_NATIVE_DOUBLE, steps, one_dims, hdferr)
      h5_steps_full(:,1) = steps
      CALL H5Dclose_f(dset_id, hdferr)                             ! Close the dataset file
   endif
!write(*,*) ' H5_steps abs  ', h5_steps_full(:,1)
endif
!
if(yd_present(YD_STEP_SIZES_ORD)) then
   dataname = 'step_sizes_ord'
   one_dims    = 1
   one_maxdims = 1
   CALL H5Dopen_f(file_id, dataname, dset_id, hdferr)           ! Open the dataset
   if(hdferr==0) then
      CALL H5Dget_space_f(dset_id, space_id, hdferr)
      CALL H5Sget_simple_extent_ndims_f(space_id, one_ndims, hdferr)   ! Get the number of dimensions in data set
      CALL H5Sget_simple_extent_dims_f(space_id, one_dims, one_maxdims, hdferr)   ! Get the dimensions in data set
      CALL H5Dread_f(dset_id, H5T_NATIVE_DOUBLE, steps, one_dims, hdferr)
      h5_steps_full(:,2) = steps
      CALL H5Dclose_f(dset_id, hdferr)                             ! Close the dataset file
   endif
!write(*,*) ' H5_steps ord  ', h5_steps_full(:,2)
endif
!
if(yd_present(YD_STEP_SIZES_TOP)) then
   dataname = 'step_sizes_top'
   one_dims    = 1
   one_maxdims = 1
   CALL H5Dopen_f(file_id, dataname, dset_id, hdferr)           ! Open the dataset
   if(hdferr==0) then
      CALL H5Dget_space_f(dset_id, space_id, hdferr)
      CALL H5Sget_simple_extent_ndims_f(space_id, one_ndims, hdferr)   ! Get the number of dimensions in data set
      CALL H5Sget_simple_extent_dims_f(space_id, one_dims, one_maxdims, hdferr)   ! Get the dimensions in data set
      CALL H5Dread_f(dset_id, H5T_NATIVE_DOUBLE, steps, one_dims, hdferr)
      h5_steps_full(:,3) = steps
      CALL H5Dclose_f(dset_id, hdferr)                             ! Close the dataset file
   endif
!write(*,*) ' H5_steps top  ', h5_steps_full(:,3)
endif
!
CALL h5fclose_f(file_id, hdferr)                             ! Close the input file
!
CALL H5close_f(hdferr)                                    ! Close HDF interface
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Copy into H5 storage
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
CALL hdf5_set_node(h5_infile, h5_layer, h5_direct, ndims, one_ndims, h5_dims, &
                   maxdims, one_dims, one_maxdims, h5_data, h5_llims, h5_steps,&
                   h5_steps_full)
 
!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Copy into KUPLOT array
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
IF(opara(O_LAYER)=='bottom') THEN
   nlayer = 1
ELSEIF(opara(O_LAYER)=='middle') THEN
   nlayer = INT((h5_dims(1)+1)/2)
ELSEIF(opara(O_LAYER)=='top') THEN
   nlayer = h5_dims(1)
ELSE
   cpara(1) = opara(O_LAYER)
   lpara(1) = lopara(O_LAYER)
   ianz = 1
   CALL ber_params (ianz, cpara, lpara, werte, maxw)
   nlayer = NINT(werte(1))
   IF(nlayer  <=0) THEN
      ier_num = -71
      ier_typ = ER_APPL
      ier_msg(1) = 'Layer number <= 0'
      ier_msg(2) = 'FILE '//h5_infile (1:LEN(ier_msg)-5)
      DEALLOCATE(h5_datasets)
      RETURN
   ELSEIF(nlayer  >  h5_dims(1)) THEN
      ier_num = -71
      ier_typ = ER_APPL
      WRITE(ier_msg(1),'(a,i4)') 'Layer number > ', nlayer
      ier_msg(2) = 'FILE '//h5_infile (1:LEN(ier_msg)-5)
      DEALLOCATE(h5_datasets)
      RETURN
   ENDIF
ENDIF
!
!if(h5_temp%h5_dims(1)==1 .and. h5_temp%h5_dims(2)==1) then
!   CALL hdf5_place_kuplot_1d(nlayer, .TRUE.,.TRUE., .TRUE.,               &
!      MAXARRAY, MAXKURVTOT, fname, iz, x, y, z, nx, ny, &
!      xmin, xmax, ymin, ymax, &
!      offxy, offz, lni, lh5, lenc, ier_num, ier_typ, output_io)
!else
!   CALL hdf5_place_kuplot(nlayer, .TRUE.,.TRUE., .TRUE.,               &
!      MAXARRAY, MAXKURVTOT, fname, iz, x, y, z, nx, ny, &
!      xmin, xmax, ymin, ymax, &
!      offxy, offz, lni, lh5, lenc, ier_num, ier_typ, output_io)
!endif
!
DEALLOCATE(h5_datasets)
DEALLOCATE(h5_data)
!
END SUBROUTINE hdf5_read
!
!*******************************************************************************
!
INTEGER FUNCTION op_func(loc_id, name, info, operator_data) bind(C)
     
    USE allocate_generic
    USE HDF5
    USE ISO_C_BINDING
    IMPLICIT NONE
     
    INTEGER, PARAMETER ::MAXSTR = 1024
    INTEGER(HID_T), VALUE :: loc_id
    CHARACTER(LEN=1), DIMENSION(1:MAXSTR) :: name ! must have LEN=1 for bind(C) strings
    TYPE(C_PTR) :: info
    TYPE(C_PTR) :: operator_data
     
    INTEGER   :: status, i, length
 
    TYPE(H5O_info_t), TARGET :: infobuf
!   TYPE(C_PTR) :: ptr
    CHARACTER(LEN=MAXSTR) :: name_string
!
    INTEGER :: all_status ! allocation status
    INTEGER :: ndata      ! upper limit for allocation
    INTEGER :: size_d     ! allocated size
 
    !
    ! Get type of the object and display its name and type.
    ! The name of the object is passed to this FUNCTION by
    ! the Library.
    !
 
    DO i = 1, MAXSTR
       name_string(i:i) = name(i)(1:1)
    ENDDO
 
    CALL H5Oget_info_by_name_f(loc_id, name_string, infobuf, status)
 
    ! Include the string up to the C NULL CHARACTER
    length = 0
    DO
       IF(length>=MAXSTR) EXIT
       IF(name_string(length+1:length+1).EQ.C_NULL_CHAR.OR.length.GE.MAXSTR) EXIT
       length = length + 1
    ENDDO
 
    IF(infobuf%type.EQ.H5O_TYPE_GROUP_F)THEN
!      WRITE(*,*) "Group: ", name_string(1:length)
       CONTINUE
    ELSE IF(infobuf%type.EQ.H5O_TYPE_DATASET_F)THEN
!      WRITE(*,*) "Dataset: ", name_string(1:length)
       IF(h5_n_datasets==H5_MAX_DATASETS) THEN
          ndata = H5_MAX_DATASETS + 10
          CALL alloc_arr(h5_datasets, 1, ndata, all_status, ' ', size_d)
          H5_MAX_DATASETS = H5_MAX_DATASETS + 10
       ENDIF 
       h5_n_datasets = h5_n_datasets + 1
       h5_datasets(h5_n_datasets) = name_string(1:length)
    ELSE IF(infobuf%type.EQ.H5O_TYPE_NAMED_DATATYPE_F)THEN
!      WRITE(*,*) "Datatype: ", name_string(1:length)
       CONTINUE
    ELSE
!      WRITE(*,*) "Unknown: ", name_string(1:length)
       CONTINUE
    ENDIF
 
    op_func = 0 ! return successful
 
  END FUNCTION op_func
!
!*******************************************************************************
!
SUBROUTINE hdf5_error(infile, file_id, dataname, dset_id, ier_num, ier_typ, &
                      idims,ier_msg,er_nr, er_type, message)
!
IMPLICIT NONE
!
CHARACTER(LEN=*)       , INTENT(IN) :: infile     ! File name
INTEGER(KIND=LIB_HID_T), INTENT(IN) :: file_id    ! File identifier
CHARACTER(LEN=*)       , INTENT(IN) :: dataname   ! dataset name
INTEGER(KIND=LIB_HID_T), INTENT(IN) :: dset_id    ! dataset identifier
INTEGER            , INTENT(OUT) :: ier_num     ! Error number
INTEGER            , INTENT(OUT) :: ier_typ     ! Error type
INTEGER            , INTENT(IN)  :: idims       ! Dimension of ier_msg
CHARACTER(LEN=*), DIMENSION(idims)   , INTENT(OUT) :: ier_msg    ! Error message
INTEGER            , INTENT(IN) :: er_nr      ! Error number
INTEGER            , INTENT(IN) :: er_type    ! Error type
CHARACTER(LEN=*)   , INTENT(IN) :: message    ! Error message
!
INTEGER             :: hdferr      ! Error number
!
ier_num = er_nr             ! Copy error numbers into errlist_mod
ier_typ = er_type
ier_msg(1) = message(1:LEN(ier_msg))
IF(dataname /= ' ') ier_msg(2) = 'Dataset: '//dataname
IF(infile   /= ' ') ier_msg(3) = 'H5 File: '//infile
!
IF(ALLOCATED(h5_datasets)) DEALLOCATE(h5_datasets)
IF(ALLOCATED(h5_data))     DEALLOCATE(h5_data)
!
! CLOSE up, ignore error messages
IF(dset_id /= 0) CALL H5Dclose_f(dset_id , hdferr)                         ! Close dataset
IF(file_id /= 0) CALL h5fclose_f(file_id, hdferr)                          ! Close the input file
CALL H5close_f(hdferr)                                    ! Close HDF interface
!
END SUBROUTINE hdf5_error
!
!*******************************************************************************
!
end module lib_hdf5_read_mod
