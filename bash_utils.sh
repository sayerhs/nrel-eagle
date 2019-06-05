#!/bin/bash

# hpacf_modules <compiler> <module_snapshot_date>
#
# Activate module environment from Jon Rood
#
# Example:
#    hpacf_modules gcc
#    module load tmux git cmake
#    module load paraview
#
#    # Load a different version
#    hpacf_modules gcc modules-2018-11-21
#
hpacf_modules ()
{
    local compiler=${1:-gcc}
    local moddate=${2:-modules}
    local hpacf_modules_dir=/nopt/nrel/ecom/hpacf

    # Remove existing modules
    module purge

    # Remove previously loaded paths to avoid clashes
    if [ ! -z "$MODULEPATH" ] ; then
        module unuse $MODULEPATH
    fi

    # Load HPACF modules
    module use ${hpacf_modules_dir}/binaries/${moddate}
    module use ${hpacf_modules_dir}/compilers/${moddate}
    module use ${hpacf_modules_dir}/utilities/${moddate}
    module use ${hpacf_modules_dir}/software/${moddate}/${compiler}*

    echo "==> Using modules: $(readlink -f ${hpacf_modules_dir}/software/${moddate}/${compiler})"
}

# ijob - Get an interactive job
#
# With no arguments, get one node for 4 hours on standard queue.
#
# Get a node with GPU
#     ijob -g
#
# Get 10 nodes for 1 hour
#     ijob -N 10 -t 01:00:00
#
ijob ()
{
    local nodes=1
    local queue=" "
    local walltime="04:00:00"
    local gpu_args=" "
    local account=hfm

    OPTIND=1
    while getopts ":N:q:t:gh" opt; do
        case "$opt" in
            h|\?)
                echo "Usage: ijob [-N nodes] [-t walltime] [-q queue] [-g] [-- other_opts]"
                return
                ;;
            N)
                nodes=$OPTARG
                ;;
            q)
                queue="-p $OPTARG"
                ;;
            t)
                walltime=$OPTARG
                ;;
            g)
                gpu_args="--gres=gpu:2"
                ;;
        esac
    done
    shift $((OPTIND-1))
    [ "$1" == "--" ] && shift

    local cmd="salloc -N ${nodes} -t ${walltime} -A ${account} ${queue} ${gpu_args} --exclusive $@"
    echo "${cmd}"
    eval "${cmd}"
}

# job_script - Output a skeleton job script
#
# Usage: job_script <output_file_name>
#
job_script ()
{
    local outfile=${1:-submit_script.slurm}

    cat <<'EOF' > ${outfile}
#!/bin/bash

#### SLURM options
#SBATCH --job-name=JOBNAME
#SBATCH --account=hfm
#SBATCH --nodes=1
#SBATCH --time=48:00:00
#SBATCH --output=%x_%j.slurm

#### Initialize environment
hpacf_modules

#### Setup MPI run settings
ranks_per_node=36
mpi_ranks=$(expr $SLURM_JOB_NUM_NODES \* $ranks_per_node)
export OMP_NUM_THREADS=1
export OMP_PLACES=threads
export OMP_PROC_BIND=spread

echo "Job name       = $SLURM_JOB_NAME"
echo "Num. nodes     = $SLURM_JOB_NUM_NODES"
echo "Num. MPI Ranks = $mpi_ranks"
echo "Num. threads   = $OMP_NUM_THREADS"
echo "Working dir    = $PWD"

srun -n ${mpi_ranks} -c ${OMP_NUM_THREADS} --cpu-bind=cores COMMAND
EOF

    echo "==> Created job script: ${outfile}"
}


#### ALIASES
alias qinfo="sinfo -o '%24P %.5a  %.12l  %.16F %G'"
alias myjobs="squeue -u ${USER} -o '%12i %20j %.6D %.2t %.10M %.9P %r'"
