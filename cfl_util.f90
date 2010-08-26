!**********************************************************************
subroutine cfl_max(cfl)
!**********************************************************************
use types, only : rprec
use param, only : dt, dx, dy, dz, nx, ny, nz
use sim_param, only : u,v,w

$if($MPI)
use mpi
use param, only : up, down, ierr, MPI_RPREC, status, comm, coord
$endif

implicit none

real(rprec), intent(OUT) :: cfl

$if($MPI)
real(rprec) :: cfl_buf
$endif

cfl = maxval( (/ dt * abs(u(1:nx,1:ny,1:nz-1)) / dx, &
                 dt * abs(v(1:nx,1:ny,1:nz-1)) / dy, &
                 dt * abs(w(1:nx,1:ny,1:nz-1)) / dz /) )

$if($MPI)
call mpi_allreduce(cfl, cfl_buf, 1, MPI_RPREC, MPI_MAX, comm, ierr)
cfl = cfl_buf
$endif

return
end subroutine cfl_max

$if($CFL_DT)
!**********************************************************************
subroutine cfl_set_dt(dt)
!**********************************************************************
use types, only : rprec
use param, only : cfl, dx, dy, dz, nx, ny, nz
use sim_param, only : u,v,w

$if($MPI)
use mpi
use param, only : up, down, ierr, MPI_RPREC, status, comm, coord
$endif

implicit none

real(rprec), intent(OUT) :: dt

$if($MPI)
real(rprec) :: dt_buf
$endif

dt = minval( (/ cfl * dx / abs(u(1:nx,1:ny,1:nz-1)), &
                cfl * dy / abs(v(1:nx,1:ny,1:nz-1)), &
                cfl * dz / abs(w(1:nx,1:ny,1:nz-1)) /) )

$if($MPI)
call mpi_allreduce(dt, dt_buf, 1, MPI_RPREC, MPI_MIN, comm, ierr)
dt = dt_buf
$endif

return
end subroutine cfl_set_dt
$endif