#!/bin/bash
#
# NREL Eagle Paraview remote connection script
#

#SBATCH --job-name=paraview
#SBATCH --account=hfm
#SBATCH --time=12:00:00
#SBATCH --output=out.%x_%j

tmux_update ()
{
    # Return early if we are not in a tmux session
    [ -z "${TMUX}" ] && return

    local tmux_vars=(
        DISPLAY
        SSH_AUTH_SOCK
        SSH_CLIENT
        SSH_CONNECTION
    )

    for vname in "${tmux_vars[@]}" ; do
        eval $(tmux show-environment -s ${vname})
    done
}

submit_job ()
{
    # Update TMUX settings if necessary
    tmux_update || echo "Error updating TMUX"

    # Determine remote server
    local ssh_ip="${SSH_CONNECTION%% *}"
    export PV_REMOTE_CLIENT="${PV_REMOTE_CLIENT:-${ssh_ip}}"

    local sbatch_args="$@"
    if [ "$#" = "0" ] ; then
        sbatch_args=" -N 1 "
    fi

    # Name of this script
    local script_name="${BASH_SOURCE[0]}"

    echo "==> Setting remote IP = ${PV_REMOTE_CLIENT}"
    sbatch ${sbatch_args} ${script_name}
}

run_pvserver ()
{
    module use /nopt/nrel/ecom/hpacf/software/modules/gcc-7.3.0
    module load paraview

    # Suppress MPICH warnings
    export MXM_LOG_LEVEL=error

    # Determine remote server
    local ssh_ip="${SSH_CONNECTION%% *}"
    export PV_REMOTE_CLIENT="${PV_REMOTE_CLIENT:-${ssh_ip}}"

    local tasks_per_node=${SLURM_NTASKS_PER_NODE:-${SLURM_CPUS_ON_NODE}}
    local ranks_avail=$(expr $SLURM_JOB_NUM_NODES \* ${tasks_per_node})
    local num_ranks=${SLURM_NTASKS:-${ranks_avail}}
    local cpus_per_task=${SLURM_CPUS_PER_TASK:-1}

    echo "Job name       = $SLURM_JOB_NAME"
    echo "Num. nodes     = $SLURM_JOB_NUM_NODES"
    echo "Num. MPI ranks = ${num_ranks}"
    echo "Working dir    = $PWD"

    local pvcmd=(
        srun -n ${num_ranks} -c ${cpus_per_task} --cpu-bind=cores
        pvserver -rc --force-offscreen-rendering --client-host=${PV_REMOTE_CLIENT}
    )

    echo "Executing command: "
    echo "${pvcmd[@]}"
    eval "${pvcmd[@]}"
}

main ()
{
    if [ -z ${SLURM_JOB_ID} ] ; then
        submit_job "$@"
    else
        run_pvserver
    fi
}

main "$@"
