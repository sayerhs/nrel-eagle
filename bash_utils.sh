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
    module use ${hpacf_modules_dir}/compilers/${moddate}
    module use ${hpacf_modules_dir}/utilities/${moddate}
    module use ${hpacf_modules_dir}/software/${moddate}/${compiler_arg}

    echo "==> Using modules: $(readlink -f ${hpacf_modules_dir}/software/${moddate}/${compiler_arg})"
}

# ijob - Get an interactive job
#
ijob ()
{
    local nodes=1
    local queue=" "
    local walltime="04:00:00"
    local gpu_args=" "
    local account=hfm

    OPTIND=1
    while getopts ":n:q:w:gh" opt; do
        case "$opt" in
            h|\?)
                echo "Usage: ijob [-n nodes] [-w walltime] [-q queue] [-g] [-- other_opts]"
                return
                ;;
            n)
                nodes=$OPTARG
                ;;
            q)
                queue="-p $OPTARG"
                ;;
            w)
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
}


#### ALIASES
alias qinfo="sinfo -o '%24P %.5a  %.12l  %.16F %G'"
alias myjobs="squeue -u ${USER} -o '%12i %20j %.6D %.2t %.10M %.9P %r'"
