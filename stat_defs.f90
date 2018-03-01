!!
!!  Copyright (C) 2009-2013  Johns Hopkins University
!!
!!  This file is part of lesgo.
!!
!!  lesgo is free software: you can redistribute it and/or modify
!!  it under the terms of the GNU General Public License as published by
!!  the Free Software Foundation, either version 3 of the License, or
!!  (at your option) any later version.
!!
!!  lesgo is distributed in the hope that it will be useful,
!!  but WITHOUT ANY WARRANTY; without even the implied warranty of
!!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!!  GNU General Public License for more details.
!!
!!  You should have received a copy of the GNU General Public License
!!  along with lesgo.  If not, see <http://www.gnu.org/licenses/>.
!!

!**********************************************************************
module stat_defs
!**********************************************************************
use types, only : rprec
use param, only : nx,ny,nz,lh,ld,ny2
use derivatives, only: convolve, convolve2, dft_direct_back_2d_n_yonlyC

save
public

type point_t
  integer :: istart, jstart, kstart, coord
  real(rprec) :: xdiff, ydiff, zdiff
  integer :: fid
end type point_t

type plane_t
  integer :: istart
  real(rprec) :: ldiff
end type plane_t

type zplane_t
  integer :: istart, coord
  real(rprec) :: ldiff
end type zplane_t  

type rs_t
  real(rprec) :: up2, vp2, wp2, upvp, upwp, vpwp 
end type rs_t

!!$type spectra_t
!!$  real(rprec), dimension(:), allocatable :: power
!!$  real(rprec), dimension(:), allocatable :: upower,vpower,wpower
!!$  integer :: istart, coord
!!$  real(rprec) :: ldiff 
!!$end type spectra_t

!real(rprec) :: spectra_total_time
!real(rprec) :: span_spectra_total_time
real(rprec) :: tavg_total_time
$if($OUTPUT_EXTRA)
real(rprec) :: tavg_total_time_sgs
$endif
! Time between calls of tavg_compute, built by summing dt
real(rprec) :: tavg_dt
! Switch for determining if time averaging has been initialized
logical :: tavg_initialized = .false.

!!$! Time between calls of spectra_compute, built by summing dt
!!$real(rprec) :: spectra_dt
!!$real(rprec) :: span_spectra_dt
!!$! Switch for determining if time averaging has been initialized
!!$logical :: spectra_initialized = .false.
!!$logical :: span_spectra_initialized = .false.

!  Sums performed over time
type tavg_t
  real(rprec) :: u, v, w, u_uv
  real(rprec) :: u2, v2, w2, uv, uw, vw
  real(rprec) :: dudz, dvdz
  real(rprec) :: txx, tyy, tzz, txy, txz, tyz
  real(rprec) :: fx, fy, fz
  real(rprec) :: cs_opt2  
  real(rprec) :: Nu_t   !!jb
  real(rprec) :: dpdx, dpdy, dpdz   !!jb
end type tavg_t

type spec_t     !!jb
   real(rprec) :: uu, vv, ww, uv, uw, vw
   real(rprec) :: vortx, vorty, vortz
   real(rprec) :: vortp, vorts  ! physical and spectral
   real(rprec) :: vortsx, vortsy, vortsz  ! spectral
end type spec_t
  
!  Sums performed over time (for subgrid variables)
$if($OUTPUT_EXTRA)
type tavg_sgs_t
  real(rprec) :: Tn  !, Nu_t    !!jb (moved Nu_t up to tavg_t)
  real(rprec) :: F_LM, F_MM, F_QN, F_NN
!  real(rprec) :: ee_now
!  $if ($DYN_TN)
!  real(rprec) :: F_ee2, F_deedt2
!  $endif
end type tavg_sgs_t
$endif

! Types for including wind-turbines as drag disks
$if ($TURBINES)
! Single turbines
type turbine_t
  real(rprec) :: xloc, yloc, height, dia, thk
  real(rprec) :: vol_c                        ! term used for volume correction  
  real(rprec) :: theta1                       ! angle CCW(from above) from -x direction [degrees]
  real(rprec) :: theta2                       ! angle above the horizontal, from -x dir [degrees]
  real(rprec), dimension(3) :: nhat           ! (nx,ny,nz) of unit normal for each turbine
  real(rprec) :: Ct_prime                     ! thrust coefficient
  integer :: num_nodes                        ! number of nodes associated with each turbine
  integer, dimension(5000,3) :: nodes         ! (i,j,k) of each included node
  integer, dimension(6) :: nodes_max          ! search area for nearby nodes
  real(rprec) :: u_d, u_d_T                   ! running time-average of mean disk velocity
  real(rprec) :: f_n                          ! normal force on turbine disk
  real(rprec), dimension(5000) :: ind         ! indicator function - weighting of each node
  !$if ($USE_RNL)
  real(rprec), allocatable, dimension(:) :: u_d_kx   !!jb 
  !$endif
end type turbine_t

! A collection of wind-turbines
type wind_farm_t
  type(turbine_t), pointer, dimension(:) :: turbine
end type wind_farm_t
    
type(wind_farm_t) :: wind_farm
$endif

! Histogram (single)
type hist_t
    real(rprec) :: bmin, bmax, db             ! bin min, max, and spacing
    integer :: nbins                          ! number of bins
    real(rprec), allocatable, dimension(:) :: bins  ! bin centers
    real(rprec), allocatable, dimension(:) :: vals  ! count for each bin (may be normalized)
end type hist_t

! Collection of histograms (one for each zplane) for a single variable
type hist_zplanes_t  
    integer, allocatable, dimension(:) :: coord         ! processor where this plane exists
    integer, allocatable, dimension(:) :: istart        ! nearest node below plane (for interpolation)
    real(rprec), allocatable, dimension(:) :: ldiff     ! distance from istart to plane (for interpolation)
    type(hist_t), allocatable, dimension(:) :: hist     ! the histograms for each plane
end type hist_zplanes_t

! Create histogram groups here 
type(hist_zplanes_t) :: HISTcs2   ! SGS coefficient, squared
type(hist_zplanes_t) :: HISTtn    ! Lagrangian time scale
type(hist_zplanes_t) :: HISTnu    ! Eddy viscosity
!type(hist_zplanes_t) :: HISTee    ! Error in SGS model

! Create types for outputting data (instantaneous or averaged)
type(point_t), allocatable, dimension(:) :: point
type(plane_t), allocatable, dimension(:) :: xplane, yplane
type(zplane_t), allocatable, dimension(:) :: zplane

type(tavg_t), allocatable, dimension(:,:,:) :: tavg
type(tavg_t), allocatable, dimension(:) :: tavg_zplane
type(spec_t), allocatable, dimension(:,:,:) :: spec1dkx
type(spec_t), allocatable, dimension(:,:,:) :: spec1dky
type(spec_t), allocatable, dimension(:,:,:) :: spec2d
type(spec_t), allocatable, dimension(:,:,:) :: specvort

$if ($OUTPUT_EXTRA)
type(tavg_sgs_t), allocatable, dimension(:,:,:) :: tavg_sgs
$endif

type(rs_t), allocatable, dimension(:,:,:) :: rs
type(rs_t), allocatable, dimension(:) :: rs_zplane, cnpy_zplane
!type(spectra_t), allocatable, dimension(:) :: spectra
!type(spectra_t), allocatable, dimension(:) :: span_spectra

! Overloaded operators for tavg and rs types
INTERFACE OPERATOR (.ADD.)
  MODULE PROCEDURE tavg_add, tavg_scalar_add, rs_add
END INTERFACE

INTERFACE OPERATOR (.SUB.)
  MODULE PROCEDURE tavg_sub, rs_sub
END INTERFACE

INTERFACE OPERATOR (.DIV.)
  $if($OUTPUT_EXTRA)
    MODULE PROCEDURE tavg_scalar_div, rs_scalar_div, spec_scalar_div, tavg_sgs_scalar_div
  $else
    MODULE PROCEDURE tavg_scalar_div, rs_scalar_div, spec_scalar_div  !!jb
  $endif  
END INTERFACE

INTERFACE OPERATOR (.MUL.)
  MODULE PROCEDURE tavg_mul, tavg_scalar_mul
END INTERFACE

INTERFACE type_set
  $if($OUTPUT_EXTRA)
    MODULE PROCEDURE tavg_set, rs_set, spec_set, tavg_sgs_set
  $else
    MODULE PROCEDURE tavg_set, rs_set, spec_set  !!jb
  $endif  
END INTERFACE

INTERFACE type_zero_bogus
  MODULE PROCEDURE tavg_zero_bogus_2D, tavg_zero_bogus_3D
END INTERFACE

INTERFACE hist_binit
  MODULE PROCEDURE hist_binit_1D, hist_binit_2D, hist_binit_3D
END INTERFACE

contains

!//////////////////////////////////////////////////////////////////////
!/////////////////// TAVG OPERATORS ///////////////////////////////////
!//////////////////////////////////////////////////////////////////////

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function tavg_add( a, b) result(c)
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
implicit none
type(tavg_t), intent(in) :: a, b
type(tavg_t) :: c

c % u = a % u + b % u
c % u_uv = a % u_uv + b % u_uv
c % v = a % v + b % v
c % w = a % w + b % w
c % u2 = a % u2 + b % u2
c % v2 = a % v2 + b % v2
c % w2 = a % w2 + b % w2
c % uv = a % uv + b % uv
c % uw = a % uw + b % uw
c % vw = a % vw + b % vw
c % dudz = a % dudz + b % dudz
c % dvdz = a % dvdz + b % dvdz
c % txx = a % txx + b % txx
c % tyy = a % tyy + b % tyy
c % tzz = a % tzz + b % tzz
c % txy = a % txy + b % txy
c % txz = a % txz + b % txz
c % tyz = a % tyz + b % tyz
c % fx = a % fx + b % fx
c % fy = a % fy + b % fy
c % fz = a % fz + b % fz
c % cs_opt2 = a % cs_opt2 + b % cs_opt2
c % Nu_t = a % Nu_t + b % Nu_t
c % dpdx = a % dpdx + b % dpdx  !!jb
c % dpdy = a % dpdy + b % dpdy  !!jb
c % dpdz = a % dpdz + b % dpdz  !!jb

return
end function tavg_add

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function tavg_sub( a, b) result(c)
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
implicit none
type(tavg_t), intent(in) :: a, b
type(tavg_t) :: c

c % u = a % u - b % u
c % u_uv = a % u_uv - b % u_uv
c % v = a % v - b % v
c % w = a % w - b % w
c % u2 = a % u2 - b % u2
c % v2 = a % v2 - b % v2
c % w2 = a % w2 - b % w2
c % uv = a % uv - b % uv
c % uw = a % uw - b % uw
c % vw = a % vw - b % vw 
c % dudz = a % dudz - b % dudz
c % dvdz = a % dvdz - b % dvdz
c % txx = a % txx - b % txx
c % tyy = a % tyy - b % tyy
c % tzz = a % tzz - b % tzz
c % txy = a % txy - b % txy
c % txz = a % txz - b % txz
c % tyz = a % tyz - b % tyz
c % fx = a % fx - b % fx
c % fy = a % fy - b % fy
c % fz = a % fz - b % fz
c % cs_opt2 = a % cs_opt2 - b % cs_opt2
c % Nu_t = a % Nu_t - b % Nu_t
c % dpdx = a % dpdx - b % dpdx  !!jb
c % dpdy = a % dpdy - b % dpdy  !!jb
c % dpdz = a % dpdz - b % dpdz  !!jb

return
end function tavg_sub

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function tavg_scalar_add( a, b ) result(c)
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
use types, only : rprec
implicit none

type(tavg_t), intent(in) :: a
real(rprec), intent(in) :: b
type(tavg_t) :: c

c % u = a % u + b
c % u_uv = a % u_uv + b
c % v = a % v + b
c % w = a % w + b
c % u2 = a % u2 + b
c % v2 = a % v2 + b
c % w2 = a % w2 + b
c % uv = a % uv + b
c % uw = a % uw + b
c % vw = a % vw + b
c % dudz = a % dudz + b
c % dvdz = a % dvdz + b
c % txx = a % txx + b
c % tzz = a % tzz + b
c % tyy = a % tyy + b
c % txy = a % txy + b
c % txz = a % txz + b
c % tyz = a % tyz + b
c % fx = a % fx + b
c % fy = a % fy + b
c % fz = a % fz + b
c % cs_opt2 = a % cs_opt2 + b
c % Nu_t = a % Nu_t + b
c % dpdx = a % dpdx + b  !!jb
c % dpdy = a % dpdy + b  !!jb
c % dpdz = a % dpdz + b  !!jb

return
end function tavg_scalar_add

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
subroutine tavg_zero_bogus_2D( c )
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
use types, only : rprec
implicit none

type(tavg_t), dimension(:,:), intent(inout) :: c

c % txx = 0._rprec
c % tyy = 0._rprec
c % tzz = 0._rprec
c % txy = 0._rprec
c % txz = 0._rprec
c % tyz = 0._rprec
c % fx = 0._rprec
c % fy = 0._rprec
c % fz = 0._rprec

return
end subroutine tavg_zero_bogus_2D

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
subroutine tavg_zero_bogus_3D( c )
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
use types, only : rprec
implicit none

type(tavg_t), dimension(:,:,:), intent(inout) :: c

c % txx = 0._rprec
c % tyy = 0._rprec
c % tzz = 0._rprec
c % txy = 0._rprec
c % txz = 0._rprec
c % tyz = 0._rprec
c % fx = 0._rprec
c % fy = 0._rprec
c % fz = 0._rprec

return
end subroutine tavg_zero_bogus_3D


!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function tavg_scalar_div( a, b ) result(c)
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
use types, only : rprec
implicit none

type(tavg_t), intent(in) :: a
real(rprec), intent(in) :: b
type(tavg_t) :: c

c % u = a % u / b
c % u_uv = a % u_uv / b
c % v = a % v / b
c % w = a % w / b
c % u2 = a % u2 / b
c % v2 = a % v2 / b
c % w2 = a % w2 / b
c % uv = a % uv / b
c % uw = a % uw / b
c % vw = a % vw / b
c % dudz = a % dudz / b
c % dvdz = a % dvdz / b
c % txx = a % txx / b
c % tyy = a % tyy / b
c % tzz = a % tzz / b
c % txy = a % txy / b
c % txz = a % txz / b
c % tyz = a % tyz / b
c % fx = a % fx / b
c % fy = a % fy / b
c % fz = a % fz / b
c % cs_opt2 = a % cs_opt2 / b
c % Nu_t = a % Nu_t / b
c % dpdx = a % dpdx / b  !!jb
c % dpdy = a % dpdy / b  !!jb
c % dpdz = a % dpdz / b  !!jb

return
end function tavg_scalar_div

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function spec_scalar_div( a, b ) result(c)     !!jb
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
use types, only : rprec
implicit none

type(spec_t), intent(in) :: a
real(rprec), intent(in) :: b
type(spec_t) :: c

c % uu = a % uu / b
c % vv = a % vv / b
c % ww = a % ww / b
c % uv = a % uv / b
c % uw = a % uw / b
c % vw = a % vw / b

c % vortx = a % vortx / b
c % vorty = a % vorty / b
c % vortz = a % vortz / b
c % vortp = a % vortp / b
c % vortsx = a % vortsx / b
c % vortsy = a % vortsy / b
c % vortsz = a % vortsz / b
c % vorts = a % vorts / b

return
end function spec_scalar_div

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function tavg_mul( a, b) result(c)
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
implicit none
type(tavg_t), intent(in) :: a, b
type(tavg_t) :: c

c % u = a % u * b % u
c % u_uv = a % u_uv * b % u_uv
c % v = a % v * b % v
c % w = a % w * b % w
c % u2 = a % u2 * b % u2
c % v2 = a % v2 * b % v2
c % w2 = a % w2 * b % w2
c % uv = a % uv * b % uv
c % uw = a % uw * b % uw
c % vw = a % vw * b % vw
c % dudz = a % dudz * b % dudz
c % dvdz = a % dvdz * b % dvdz
c % txx = a % txx * b % txx
c % tyy = a % tyy * b % tyy
c % tzz = a % tzz * b % tzz
c % txy = a % txy * b % txy
c % txz = a % txz * b % txz
c % tyz = a % tyz * b % tyz
c % fx = a % fx * b % fx
c % fy = a % fy * b % fy
c % fz = a % fz * b % fz
c % cs_opt2 = a % cs_opt2 * b % cs_opt2
c % Nu_t = a % Nu_t * b % Nu_t
c % dpdx = a % dpdx * b % dpdx  !!jb
c % dpdy = a % dpdy * b % dpdy  !!jb
c % dpdz = a % dpdz * b % dpdz  !!jb

return
end function tavg_mul

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function tavg_scalar_mul( a, b ) result(c)
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
use types, only : rprec
implicit none

type(tavg_t), intent(in) :: a
real(rprec), intent(in) :: b
type(tavg_t) :: c

c % u = a % u * b
c % u_uv = a % u_uv * b
c % v = a % v * b
c % w = a % w * b
c % u2 = a % u2 * b
c % v2 = a % v2 * b
c % w2 = a % w2 * b
c % uv = a % uv * b
c % uw = a % uw * b
c % vw = a % vw * b
c % dudz = a % dudz * b
c % dvdz = a % dvdz * b
c % txx = a % txx * b
c % tyy = a % tyy * b
c % tzz = a % tzz * b
c % txy = a % txy * b
c % txz = a % txz * b
c % tyz = a % tyz * b
c % fx = a % fx * b
c % fy = a % fy * b
c % fz = a % fz * b
c % cs_opt2 = a % cs_opt2 * b
c % Nu_t = a % Nu_t * b
c % dpdx = a % dpdx * b !!jb
c % dpdy = a % dpdy * b !!jb
c % dpdz = a % dpdz * b !!jb

return
end function tavg_scalar_mul

$if($OUTPUT_EXTRA)
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function tavg_sgs_scalar_div( a, b ) result(c)
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
use types, only : rprec
implicit none

type(tavg_sgs_t), intent(in) :: a
real(rprec), intent(in) :: b
type(tavg_sgs_t) :: c

c % Tn = a % Tn / b
c % Nu_t = a % Nu_t / b
c % F_LM = a % F_LM / b
c % F_MM = a % F_MM / b
c % F_QN = a % F_QN / b
c % F_NN = a % F_NN / b
!c % ee_now = a % ee_now / b
!$if($DYN_TN)
!c % F_ee2 = a % F_ee2 / b
!c % F_deedt2 = a % F_deedt2 / b
!$endif

return
end function tavg_sgs_scalar_div
$endif

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function tavg_interp_to_uv_grid( a ) result(c)
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
use param, only: lbz
use functions, only : interp_to_uv_grid
implicit none

type(tavg_t), dimension(:,:,lbz:), intent(in) :: a
type(tavg_t), allocatable, dimension(:,:,:) :: c

integer :: ubx, uby, ubz

ubx = ubound(a,1)
uby = ubound(a,2)
ubz = ubound(a,3)

allocate(c(ubx,uby,lbz:ubz))

c = a

!c % fz = interp_to_uv_grid( a % fz, lbz )

return

end function tavg_interp_to_uv_grid

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function tavg_interp_to_w_grid( a ) result(c)
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
use param, only: lbz
use functions, only : interp_to_w_grid
implicit none

type(tavg_t), dimension(:,:,lbz:), intent(in) :: a
type(tavg_t), allocatable, dimension(:,:,:) :: c

integer :: ubx, uby, ubz

ubx = ubound(a,1)
uby = ubound(a,2)
ubz = ubound(a,3)

allocate(c(ubx,uby,lbz:ubz))

c = a

c % txx =  interp_to_w_grid( a % txx, lbz )
c % tyy =  interp_to_w_grid( a % tyy, lbz )
c % tzz =  interp_to_w_grid( a % tzz, lbz )
c % txy =  interp_to_w_grid( a % txy, lbz )

c % fx = interp_to_w_grid( a % fx, lbz )
c % fy = interp_to_w_grid( a % fy, lbz )

return

end function tavg_interp_to_w_grid

!///////////////////// RS OPERATORS ///////////////////////////////////
!//////////////////////////////////////////////////////////////////////

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function rs_add( a, b) result(c)
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
implicit none

type(rs_t), intent(in) :: a, b
type(rs_t) :: c

c % up2 = a % up2 + b % up2
c % vp2 = a % vp2 + b % vp2
c % wp2 = a % wp2 + b % wp2
c % upvp = a % upvp + b % upvp
c % upwp = a % upwp + b % upwp
c % vpwp = a % vpwp + b % vpwp

return
end function rs_add

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function rs_sub( a, b) result(c)
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
implicit none

type(rs_t), intent(in) :: a, b
type(rs_t) :: c

c % up2 = a % up2 - b % up2
c % vp2 = a % vp2 - b % vp2
c % wp2 = a % wp2 - b % wp2
c % upvp = a % upvp - b % upvp
c % upwp = a % upwp - b % upwp
c % vpwp = a % vpwp - b % vpwp

return
end function rs_sub

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function rs_scalar_div( a, b) result(c)
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
implicit none

type(rs_t), intent(in) :: a
real(rprec), intent(in) :: b
type(rs_t) :: c

c % up2 = a % up2 / b
c % vp2 = a % vp2 / b 
c % wp2 = a % wp2 / b
c % upvp = a % upvp / b
c % upwp = a % upwp / b 
c % vpwp = a % vpwp / b 

return
end function rs_scalar_div

!//////////////////////////////////////////////////////////////////////
!/////////////////// SPECIAL RS FUNCTIONS /////////////////////////////
!//////////////////////////////////////////////////////////////////////

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function rs_compute( a , lbz2) result(c)
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
implicit none
integer, intent(in) :: lbz2
type(tavg_t), dimension(:,:,lbz2:), intent(in) :: a
type(rs_t), allocatable, dimension(:,:,:) :: c
integer :: ubx, uby, ubz

ubx=ubound(a,1)
uby=ubound(a,2)
ubz=ubound(a,3)

allocate(c(ubx,uby,lbz2:ubz))

c % up2 = a % u2 - a % u * a % u
c % vp2 = a % v2 - a % v * a % v
c % wp2 = a % w2 - a % w * a % w
c % upvp = a % uv - a % u * a % v
c % upwp = a % uw - a % u * a % w
c % vpwp = a % vw - a % v * a % w

return
end function rs_compute

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function rs_compute_fourier( a , lbz2) result(c)
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
implicit none
integer, intent(in) :: lbz2
type(tavg_t), dimension(:,:,lbz2:), intent(in) :: a
type(rs_t), allocatable, dimension(:,:,:) :: c

real(rprec), allocatable, dimension(:,:,:) :: u_w, v_w, w_w
real(rprec), allocatable, dimension(:,:,:) :: uuF
real(rprec), allocatable, dimension(:,:,:) :: vvF
real(rprec), allocatable, dimension(:,:,:) :: wwF
real(rprec), allocatable, dimension(:,:,:) :: uvF
real(rprec), allocatable, dimension(:,:,:) :: uwF
real(rprec), allocatable, dimension(:,:,:) :: vwF

integer :: ubx, uby, ubz, jz
ubx=ubound(a,1)
uby=ubound(a,2)
ubz=ubound(a,3)

allocate(c(ubx,uby,lbz2:ubz))

allocate(u_w(ld,ny,lbz2:nz))
allocate(v_w(ld,ny,lbz2:nz))
allocate(w_w(ld,ny,lbz2:nz))
allocate(uuF(ld,ny,lbz2:nz))
allocate(vvF(ld,ny,lbz2:nz))
allocate(wwF(ld,ny,lbz2:nz))
allocate(uvF(ld,ny,lbz2:nz))
allocate(uwF(ld,ny,lbz2:nz))
allocate(vwF(ld,ny,lbz2:nz))

u_w(:,:,:) = a % u
v_w(:,:,:) = a % v
w_w(:,:,:) = a % w

!!$do jz=lbz2,nz
!!$   call dft_direct_back_2d_n_yonlyC( u_w(:,:,jz) )
!!$   call dft_direct_back_2d_n_yonlyC( v_w(:,:,jz) )
!!$   call dft_direct_back_2d_n_yonlyC( w_w(:,:,jz) )
!!$enddo
do jz=lbz2,nz
   uuF(:,:,jz) = convolve2( u_w(:,:,jz), u_w(:,:,jz) )
   vvF(:,:,jz) = convolve2( v_w(:,:,jz), v_w(:,:,jz) )
   wwF(:,:,jz) = convolve2( w_w(:,:,jz), w_w(:,:,jz) )
   uvF(:,:,jz) = convolve2( u_w(:,:,jz), v_w(:,:,jz) )
   uwF(:,:,jz) = convolve2( u_w(:,:,jz), w_w(:,:,jz) )
   vwF(:,:,jz) = convolve2( v_w(:,:,jz), w_w(:,:,jz) )
enddo

c % up2 = a % u2 - uuF !(1:ubx,1:uby,lbz2:ubz)
c % vp2 = a % v2 - vvF !(1:ubx,1:uby,lbz2:ubz)
c % wp2 = a % w2 - wwF !(1:ubx,1:uby,lbz2:ubz)
c % upvp = a % uv - uvF !(1:ubx,1:uby,lbz2:ubz)
c % upwp = a % uw - uwF !(1:ubx,1:uby,lbz2:ubz)
c % vpwp = a % vw - vwF !(1:ubx,1:uby,lbz2:ubz)

return
end function rs_compute_fourier

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function cnpy_tavg_mul( a ) result(c)
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
! 
! This performs one set of multiplication for the canopy stresses
!
implicit none

type(tavg_t), intent(in) :: a
type(rs_t) :: c

c % up2 = a % u * a % u
c % vp2 = a % v * a % v
c % wp2 = a % w * a % w
c % upvp = a % u * a % v
c % upwp = a % u * a % w
c % vpwp = a % v * a % w

return
end function cnpy_tavg_mul

!//////////////////////////////////////////////////////////////////////
!///////////////// SPECIAL TAVG SUBROUTINES ///////////////////////////
!//////////////////////////////////////////////////////////////////////

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
subroutine tavg_set( c, a )
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
use types, only : rprec
implicit none
real(rprec), intent(in) :: a
type(tavg_t), intent(out) :: c

c % u = a
c % u_uv = a
c % v = a
c % w = a
c % u2 = a
c % v2 = a
c % w2 = a
c % uv = a
c % uw = a
c % vw = a
c % dudz = a
c % dvdz = a
c % txx = a
c % tyy = a
c % tzz = a
c % txy = a
c % txz = a
c % tyz = a
c % fx = a
c % fy = a
c % fz = a
c % cs_opt2 = a
c % Nu_t = a
c % dpdx = a   !!jb
c % dpdy = a   !!jb
c % dpdz = a   !!jb

return
end subroutine tavg_set

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
subroutine spec_set( c, a )    !!jb
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
use types, only : rprec
implicit none
real(rprec), intent(in) :: a
type(spec_t), intent(out) :: c

c % uu = a
c % vv = a
c % ww = a
c % uv = a
c % uw = a
c % vw = a

c % vortx = a
c % vorty = a
c % vortz = a
c % vortp = a
c % vortsx = a
c % vortsy = a
c % vortsz = a
c % vorts = a

return
end subroutine spec_set

$if($OUTPUT_EXTRA)
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
subroutine tavg_sgs_set( c, a )
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
use types, only : rprec
implicit none
real(rprec), intent(in) :: a
type(tavg_sgs_t), intent(out) :: c

c % Tn =  a
c % Nu_t =  a
c % F_LM =  a
c % F_MM =  a
c % F_QN =  a
c % F_NN =  a
!c % ee_now = a
!$if($DYN_TN)
!c % F_ee2 = a
!c % F_deedt2 = a
!$endif

return
end subroutine tavg_sgs_set
$endif

!//////////////////////////////////////////////////////////////////////
!/////////////////// SPECIAL RS SUBROUTINES ///////////////////////////
!//////////////////////////////////////////////////////////////////////

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
subroutine rs_set( c, a )
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
use types, only : rprec
implicit none
real(rprec), intent(in) :: a
type(rs_t), intent(out) :: c

c % up2 = a
c % vp2 = a
c % wp2 = a
c % upvp = a
c % upwp = a
c % vpwp = a

return
end subroutine rs_set

!//////////////////////////////////////////////////////////////////////
!/////////////////// SPECIAL HIST SUBROUTINES /////////////////////////
!//////////////////////////////////////////////////////////////////////

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
$if($LVLSET)
subroutine hist_binit_1D( a, var, phi_ls )
$else
subroutine hist_binit_1D( a, var )
$endif
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
! This subroutine takes the values in var and bins them in the histogram
!   a only if the location is outside a body (level set function phi>0 )
!
! If phi_ls is not included as an input then all values are binned
!
! Inputs:
!   a   :: the histogram to be updated
!   var :: the values that will be used to update the histogram
!   phi_ls :: the level set function (phi from level_set_base module)

use types, only : rprec
implicit none

type(hist_t), intent(inout) :: a                
real(rprec), intent(in), dimension(:) :: var
$if ($LVLSET)
real(rprec), intent(in), dimension(:), optional :: phi_ls ! phi_ls<0 is inside a body
$endif

integer :: dim1, i, ib
real(rprec) :: countme

! Determine length of input arrays
    dim1 = size(var,1)

    !! Check that phi_ls is the same length as var (if present)
    !if (present (phi_ls)) then
    !    if ( size(phi_ls,1) .ne. dim1 ) then
    !        write(*,*) 'In hist_binit_1D: size of phi_ls should match size of var'
    !        stop
    !    endif
    !endif

! Prepare temp array and counting variable
    countme = 1.0_rprec
    
$if ($LVLSET) 
    if (present (phi_ls)) then
        do i=1,dim1
            ! if phi<0 (inside body) don't count it!  (1=outside body, 0=inside)
            countme = 0.5_rprec * ( 1.0_rprec + sign(1.0_rprec,phi_ls(i)) )  

            ! Determine which bin and add 1.0 to that val
            ib = min( ceiling( max(var(i)-a%bmin,-0.5_rprec) /a%db ), a%nbins+1 )
            a%vals(ib) = a%vals(ib) + countme
        enddo
    else
$endif
        do i=1,dim1
            ! Determine which bin and add 1.0 to that val
            ib = min( ceiling( max(var(i)-a%bmin,-0.5_rprec) /a%db ), a%nbins+1 )
            a%vals(ib) = a%vals(ib) + countme
        enddo
$if ($LVLSET) 
    endif
$endif

return
end subroutine hist_binit_1D

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
$if($LVLSET)
subroutine hist_binit_2D( a, var, phi_ls )
$else
subroutine hist_binit_2D( a, var )
$endif
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
! This subroutine takes the values in var and bins them in the histogram
!   a only if the location is outside a body (level set function phi>0 )
!
! If phi_ls is not included as an input then all values are binned
!
! Inputs:
!   a   :: the histogram to be updated
!   var :: the values that will be used to update the histogram
!   phi_ls :: the level set function (phi from level_set_base module)

use types, only : rprec
implicit none

type(hist_t), intent(inout) :: a                
real(rprec), intent(in), dimension(:,:) :: var
$if ($LVLSET)
real(rprec), intent(in), dimension(:,:), optional :: phi_ls 
$endif

integer :: dim1, dim2, i, j, ib
real(rprec) :: countme

! Determine length of input arrays
    dim1 = size(var,1)
    dim2 = size(var,2)

    !! Check that phi_ls is the same length as var (if present)
    !if (present (phi_ls)) then
    !    if (( size(phi_ls,1) .ne. dim1 ).or.( size(phi_ls,2) .ne. dim2 )) then
    !        write(*,*) 'In hist_binit_2D: size of phi_ls should match size of var'
    !        stop
    !    endif
    !endif

! Prepare temp array and counting variable
    countme = 1.0_rprec
    
$if ($LVLSET) 
    if (present (phi_ls)) then
        do j=1,dim2
        do i=1,dim1
            ! if phi<0 (inside body) don't count it!  (1=outside body, 0=inside)
            countme = 0.5_rprec * ( 1.0_rprec + sign(1.0_rprec,phi_ls(i,j)) )  

            ! Determine which bin and add 1.0 to that val
            ib = min( ceiling( max(var(i,j)-a%bmin,-0.5_rprec) /a%db ), a%nbins+1 )
            a%vals(ib) = a%vals(ib) + countme
        enddo
        enddo
    else
$endif
        do j=1,dim2
        do i=1,dim1
            ! Determine which bin and add 1.0 to that val
            ib = min( ceiling( max(var(i,j)-a%bmin,-0.5_rprec) /a%db ), a%nbins+1 )
            a%vals(ib) = a%vals(ib) + countme
        enddo
        enddo
$if ($LVLSET) 
    endif
$endif

return
end subroutine hist_binit_2D

!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
$if($LVLSET)
subroutine hist_binit_3D( a, var, phi_ls )
$else
subroutine hist_binit_3D( a, var )
$endif
!++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
! This subroutine takes the values in var and bins them in the histogram
!   a only if the location is outside a body (level set function phi>0 )
!
! If phi_ls is not included as an input then all values are binned
!
! Inputs:
!   a   :: the histogram to be updated
!   var :: the values that will be used to update the histogram
!   phi_ls :: the level set function (phi from level_set_base module)

use types, only : rprec
implicit none

type(hist_t), intent(inout) :: a                
real(rprec), intent(in), dimension(:,:,:) :: var
$if ($LVLSET)
real(rprec), intent(in), dimension(:,:,:), optional :: phi_ls 
$endif

integer :: dim1, dim2, dim3, i, j, k, ib
real(rprec) :: countme

! Determine length of input arrays
    dim1 = size(var,1)
    dim2 = size(var,2)
    dim3 = size(var,3)

    !! Check that phi_ls is the same length as var (if present)
    !if (present (phi_ls)) then
    !    if ( size(phi_ls,1) .ne. dim1 ) then
    !        write(*,*) 'In hist_binit_3D: size of phi_ls should match size of var (1)'
    !        stop
    !    endif
    !    if ( size(phi_ls,2) .ne. dim2 ) then
    !        write(*,*) 'In hist_binit_3D: size of phi_ls should match size of var (2)'
    !        stop
    !    endif
    !    if ( size(phi_ls,3) .ne. dim3 ) then
    !        write(*,*) 'In hist_binit_3D: size of phi_ls should match size of var (3)'
    !        stop
    !   endif
    !endif

! Prepare temp array and counting variable
    countme = 1.0_rprec
    
$if ($LVLSET) 
    if (present (phi_ls)) then
        do k=1,dim3
        do j=1,dim2
        do i=1,dim1
            ! if phi<0 (inside body) don't count it!  (1=outside body, 0=inside)
            countme = 0.5_rprec * ( 1.0_rprec + sign(1.0_rprec,phi_ls(i,j,k)) )  

            ! Determine which bin and add 1.0 to that val
            ib = min( ceiling( max(var(i,j,k)-a%bmin,-0.5_rprec) /a%db ), a%nbins+1 )
            a%vals(ib) = a%vals(ib) + countme
        enddo
        enddo
        enddo
    else
$endif
        do k=1,dim3
        do j=1,dim2
        do i=1,dim1
            ! Determine which bin and add 1.0 to that val
            ib = min( ceiling( max(var(i,j,k)-a%bmin,-0.5_rprec) /a%db ), a%nbins+1 )
            a%vals(ib) = a%vals(ib) + countme
        enddo
        enddo
        enddo
$if ($LVLSET) 
    endif
$endif

return
end subroutine hist_binit_3D

end module stat_defs

