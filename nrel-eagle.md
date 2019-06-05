<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Introduction](#introduction)
- [Slurm -- Job management](#slurm----job-management)
    - [Getting information about queues and jobs](#getting-information-about-queues-and-jobs)
        - [sinfo - List free/allocated nodes](#sinfo---list-freeallocated-nodes)
        - [squeue - List jobs on queue](#squeue---list-jobs-on-queue)
    - [Job submission](#job-submission)
        - [Batch submissions](#batch-submissions)
        - [Job dependencies](#job-dependencies)
        - [Multiple serial jobs in one batch script](#multiple-serial-jobs-in-one-batch-script)
            - [Using srun](#using-srun)
            - [Using job arrays](#using-job-arrays)
        - [Other commands](#other-commands)
- [Client/Server connections](#clientserver-connections)
    - [Paraview reverse connection](#paraview-reverse-connection)
    - [Connecting to remote Jupyter notebook](#connecting-to-remote-jupyter-notebook)
- [Remote connection tips](#remote-connection-tips)
    - [SSH config](#ssh-config)
    - [SSH tunneling](#ssh-tunneling)
    - [Session management -- tmux/screen](#session-management----tmuxscreen)
- [File/Directory permissions](#filedirectory-permissions)

<!-- markdown-toc end -->

# Introduction

Resources

- [NREL HPC Eagle documentation](https://www.nrel.gov/hpc/eagle-system.html)
- [NREL HPC Eagle workshop presentations](https://github.com/NREL/HPC/blob/master/workshops/README.md)

# Slurm -- Job management 

Eagle uses [Slurm](https://slurm.schedmd.com) for scheduling and managing jobs
on the system. 

- [Quick start user guide](https://slurm.schedmd.com/quickstart.html)
- [Cheatsheet (PDF)](https://slurm.schedmd.com/pdfs/summary.pdf)
- [Detailed manual pages](https://slurm.schedmd.com/man_index.html)
- [Rosetta stone](https://slurm.schedmd.com/rosetta.html)
- [NREL "Slurm: Advanced Topics" presentation](https://www.nrel.gov/hpc/assets/pdfs/slurm-advanced-topics.pdf)

## Getting information about queues and jobs

### sinfo - List free/allocated nodes

Use [sinfo](https://slurm.schedmd.com/sinfo.html) to list nodes and partition
information. Alternately, use `shownodes` provided by NREL HPC admins.

You can pass a formatting string to summarize the information.

```bash
eagle$ sinfo -o '%24P %.5a  %.12l  %.16F'
PARTITION                AVAIL     TIMELIMIT    NODES(A/I/O/T)
short                       up       4:00:00   1424/648/9/2081
standard                    up    2-00:00:00   1424/648/9/2081
long                        up   10-00:00:00   1424/648/9/2081
bigmem                      up    2-00:00:00        20/58/0/78
gpu                         up    2-00:00:00         1/41/0/42
bigscratch                  up    2-00:00:00         1/19/0/20
debug                       up    1-00:00:00         1/12/0/13
```

`(A/I/O/T) = Allocated / Idle / Offline / Total`

Alternate format showing *generic resources* available on the queues. 

```bash
eagle$ sinfo -o '%24P %.5a  %.12l  %.16F %G'
PARTITION                AVAIL     TIMELIMIT    NODES(A/I/O/T) GRES
short                       up       4:00:00   1424/616/9/2049 (null)
short                       up       4:00:00         0/32/0/32 gpu:v100:2
standard                    up    2-00:00:00   1424/616/9/2049 (null)
standard                    up    2-00:00:00         0/32/0/32 gpu:v100:2
long                        up   10-00:00:00   1424/616/9/2049 (null)
long                        up   10-00:00:00         0/32/0/32 gpu:v100:2
bigmem                      up    2-00:00:00        20/26/0/46 (null)
bigmem                      up    2-00:00:00         0/32/0/32 gpu:v100:2
gpu                         up    2-00:00:00         1/41/0/42 gpu:v100:2
bigscratch                  up    2-00:00:00          1/9/0/10 gpu:v100:2
bigscratch                  up    2-00:00:00         0/10/0/10 (null)
debug                       up    1-00:00:00           1/8/0/9 (null)
debug                       up    1-00:00:00           0/4/0/4 gpu:v100:2
```

Use an alias once you have figured out your preferred output format, e.g., 

```bash
alias qinfo="sinfo -o '%24P %.5a  %.12l  %.16F %G'"
```

To view *node state* in summary view

```bash
eagle$ sinfo -o '%24P %.5a  %.12l  %.16F %T'
PARTITION                AVAIL     TIMELIMIT    NODES(A/I/O/T) STATE
short                       up       4:00:00           0/0/1/1 down$
short                       up       4:00:00         60/0/0/60 draining$
short                       up       4:00:00     1300/0/0/1300 allocated$
short                       up       4:00:00       1/711/8/720 maint
standard                    up    2-00:00:00           0/0/1/1 down$
standard                    up    2-00:00:00         60/0/0/60 draining$
standard                    up    2-00:00:00     1300/0/0/1300 allocated$
standard                    up    2-00:00:00       1/711/8/720 maint
long                        up   10-00:00:00           0/0/1/1 down$
long                        up   10-00:00:00         60/0/0/60 draining$
long                        up   10-00:00:00     1300/0/0/1300 allocated$
long                        up   10-00:00:00       1/711/8/720 maint
bigmem                      up    2-00:00:00         20/0/0/20 allocated$
bigmem                      up    2-00:00:00         0/58/0/58 maint
gpu                         up    2-00:00:00           1/0/0/1 allocated$
gpu                         up    2-00:00:00         0/41/0/41 maint
bigscratch                  up    2-00:00:00           1/0/0/1 allocated$
bigscratch                  up    2-00:00:00         0/19/0/19 maint
debug                       up    1-00:00:00           1/0/0/1 allocated$
debug                       up    1-00:00:00         0/12/0/12 maint
```

---

### squeue - List jobs on queue

Use [squeue](https://slurm.schedmd.com/squeue.html) to list jobs on the queue.
Use `-u ${USER}` to list a particular user's jobs. 

```bash
eagle$ squeue -u gvijayak
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REA
            806661  standard actline_ gvijayak  R    5:51:45     40 r2i0n[24-35]
            806674  standard fsi_noct gvijayak  R    5:51:45     30 r3i2n[30-35]
            805057  standard fsi_node gvijayak  R 1-23:01:54     30 r2i3n[9-12],
            805054  standard fsi_node gvijayak  R 1-23:06:00     30 r4i0n[1-8],r
            805055  standard fsi_node gvijayak  R 1-23:06:00     30 r5i5n[10-26]
            805048  standard fsi_node gvijayak  R 1-23:21:57     30 r2i6n[30-31]
            805046  standard fsi_node gvijayak  R 1-23:23:48     30 r1i0n4,r1i2n
            805045  standard fsi_node gvijayak  R 1-23:25:47     30 r5i3n[20-28]
            805041  standard fsi_node gvijayak  R 1-23:29:09     30 r1i0n[34-35]
            805040  standard fsi_node gvijayak  R 1-23:29:48     30 r1i6n[10-21]
            805039  standard fsi_node gvijayak  R 1-23:31:45     30 r1i0n[18-19]
            804563      long fsi_defl gvijayak  R 2-10:12:41     30 r1i1n[22-33]
            804561      long fsi_defl gvijayak  R 2-10:23:40     30 r1i4n[0-14],
            804557      long fsi_defl gvijayak  R 2-10:42:05     30 r1i2n[23-35]
            804555      long fsi_defl gvijayak  R 2-10:51:03     30 r1i2n[3-19],
            804533      long fsi_defl gvijayak  R 2-11:13:48     30 r2i3n[17-35]
            804517      long fsi_defl gvijayak  R 2-12:09:55     30 r1i0n[31-33]
            804509      long fsi_defl gvijayak  R 2-12:26:34     30 r6i5n[22-35]
            804495      long fsi_defl gvijayak  R 2-12:33:22     30 r2i0n[13-23]
```

Pass formatting string to tailor output based on your preference.

```bash
eagle$ squeue -u gvijayak -o '%12i %20j %.6D %.2t %.10M %.9P %r'
JOBID        NAME                  NODES ST       TIME PARTITION REASON
806661       actline_noctrl_13mps     40  R    5:54:42  standard None
806674       fsi_noctrl_8mps          30  R    5:54:42  standard None
805057       fsi_nodefl_20mps         30  R 1-23:04:51  standard None
805054       fsi_nodefl_6mps          30  R 1-23:08:57  standard None
805055       fsi_nodefl_7mps          30  R 1-23:08:57  standard None
805048       fsi_nodefl_15mps         30  R 1-23:24:54  standard None
805046       fsi_nodefl_13mps         30  R 1-23:26:45  standard None
805045       fsi_nodefl_11mps         30  R 1-23:28:44  standard None
805041       fsi_nodefl_10mps         30  R 1-23:32:06  standard None
805040       fsi_nodefl_9mps          30  R 1-23:32:45  standard None
805039       fsi_nodefl_8mps          30  R 1-23:34:42  standard None
804563       fsi_defl_15mps           30  R 2-10:15:38      long None
804561       fsi_defl_13mps           30  R 2-10:26:37      long None
804557       fsi_defl_11mps           30  R 2-10:45:02      long None
804555       fsi_defl_10mps           30  R 2-10:54:00      long None
804533       fsi_defl_9mps            30  R 2-11:16:45      long None
804517       fsi_defl_8mps            30  R 2-12:12:52      long None
804509       fsi_defl_7mps            30  R 2-12:29:31      long None
804495       fsi_defl_6mps            30  R 2-12:36:19      long None
```


## Job submission 

Three commands: [srun](https://slurm.schedmd.com/srun.html),
[sbatch](https://slurm.schedmd.com/sbatch.html), and
[salloc](https://slurm.schedmd.com/salloc.html).

- **salloc**: Obtain necessary resources and run a command specified by the user. 

- **sbatch**: Like `salloc`, but run a batch script instead of a command. The
  script specified can contain `#SBATCH` options to control the job. The
  `#SBATCH` options can be overridden by options specified in the command line.
  
- **srun**: Behaves like `salloc` when executed outside of an allocation. Within
  an allocation starts a *job step* which can use all the available resources or
  a subset of resources.
  
  - Use `srun` instead of `mpiexec` or `mpirun`, SLURM will automatically invoke
    the right MPI regardless of whether the executable is compiled with OpenMPI,
    MPICH or Intel MPI.
    
  - See [Slurm FAQ entry](https://slurm.schedmd.com/faq.html#sbatch_srun) for
    differences in behavior with `sbatch` and `srun`.
    
---

### Batch submissions

See [NREL Eagle
website](https://www.nrel.gov/hpc/eagle-sample-batch-script.html) for sample
batch scripts.

```bash
#!/bin/bash

#### SLURM options
#SBATCH --job-name=nrel5mw_w080
#SBATCH --account=hfm
#SBATCH --nodes=30
#SBATCH --time=48:00:00
#SBATCH --output=%x_%j.slurm
#SBATCH --mail-user=username@nrel.gov
#SBATCH --mail-type=NONE #BEGIN,END,FAIL

#### Initialize environment
hpacf_modules

#### Setup MPI run settings
ranks_per_node=36
mpi_ranks=$(expr $SLURM_JOB_NUM_NODES \* $ranks_per_node)
export OMP_NUM_THREADS=1
export OMP_PLACES=threads
export OMP_PROC_BIND=spread

nalu_exec=/projects/hfm/shreyas/exawind/install/gcc/nalu-wind/bin/naluX

echo "Job name       = $SLURM_JOB_NAME"
echo "Num. nodes     = $SLURM_JOB_NUM_NODES"
echo "Num. MPI Ranks = $mpi_ranks"
echo "Num. threads   = $OMP_NUM_THREADS"
echo "Working dir    = $PWD"

srun -n ${mpi_ranks} -c ${OMP_NUM_THREADS} --cpu-bind=cores ${nalu_exec} -i nrel5mw04.yaml -o nrel5mw04.log
```

For more details on dealing with multi-core architectures refer to [Slurm
multi-core](https://slurm.schedmd.com/mc_support.html). See
[bash_utils.sh](https://github.com/sayerhs/nrel-eagle/blob/master/bash_utils.sh)
for utility functions (e.g., `hpacf_modules`).

**Example**

```bash
# Submit job with defaults
eagle$ sbatch nrel5mw.slurm

# Override options at command line
eagle$ sbatch -A mmc -N 40 nrel5mw.slurm
```

---

### Job dependencies 

Use job dependencies to *chain jobs* based on the status of a previous job or
jobs. Useful for codes with restart on `short` or `standard` queues. For
example, set `startTime` to `latestTime` in `OpenFOAM` and submit the same job
several times to the standard queue with dependencies if it requires more than
48 hours to complete.

See [sbatch](https://slurm.schedmd.com/sbatch.html) manpage for all options. Two
formats

- `<condition>:job_id[:job_id]` - Execute this job if the condition succeeds for
  the `job_id`(s) listed. Example conditions: `after`, `afterany`, `afterok`,
  `afternotok`.
  
- `singleton` - Start execution after any previous jobs sharing the same job
  name and user have terminated. Easier than having to figure out the JOBID with
  `-d afterany:job_id`
  
**Example**

```bash
# Specify exact job ID
sbatch -d afterany:804517 fsi_defl_9mps.slurm

# Using singleton to automatically restart when the current job exits
sbatch -d singleton fsi_defl_9mps.slurm
```

### Multiple serial jobs in one batch script

Eagle/SLURM does not allow sharing nodes with jobs, this means that for a serial
job the remaining 35 cores are idle while the job is executing. If you are
performing parameteric runs with a lot of serial jobs, *pack* jobs into the same
script for more efficient use of resources using either `srun` yourself or with
[Using job arrays](#using-job-arrays).

---

#### Using srun

```bash
#!/bin/bash

#### SLURM options
#SBATCH --job-name=nrel5mw
#SBATCH --account=hfm
#SBATCH --nodes=1
#SBATCH --time=48:00:00
#SBATCH --output=%x_%j.slurm

for i in $(seq 5 10) ; do
    cd wspd_%{i}
    srun -n 1 -c 1 --exclusive ./myexecutable &
done

wait
```

- Use `--exclusive` to ensure that each job is running on a separate core 
- Use `&` to background the job with `srun` and `wait` to wait for all jobs to
  complete execution.
- Can run up to 36 serial jobs on one node, request more nodes and can execute
  the entire parametric run within one job submission script.

---

#### Using job arrays

```bash
#!/bin/bash

#### SLURM options
#SBATCH --job-name=nrel5mw
#SBATCH --account=hfm
#SBATCH --array=1-50
#SBATCH --ntasks=1
#SBATCH --time=48:00:00
#SBATCH --output=%x_%A_%a.slurm

# Pass a unique ID to launch the appropriate case
./my_python_script.py ${SLURM_ARRAY_TASK_ID}

# If case parameters are stored in a text file; one per line
./my_executable $(sed -n "${SLURM_ARRAY_TASK_ID}p" case_parameters.txt)
```

**Example**

```bash
# Execute only specific cases
sbatch --array=1,3,8,20 myscript.slurm

# Execute odd numbered cases
sbatch --array=1,11:2 myscript.slurm 
```

See [Slurm docs](https://slurm.schedmd.com/job_array.html) for more details.

### Other commands

- [scancel](https://slurm.schedmd.com/scancel.html) -- Cancel jobs - step, array
  ID etc.
  
- [scontrol](https://slurm.schedmd.com/scontrol.html) -- View or modify the
  state of jobs on the queue.
  
  **Example**
  
  ```bash
  # Show job details (working directory, command etc.)
  scontrol show job 804555
  
  # Hold job 
  scontrol hold 804555
  
  # Resume job
  scontrol resume 804555
  ```

- [sacct](https://slurm.schedmd.com/sacct.html) - Display accounting information

- `hours_report` -- NREL HPC provided command to track usage for your various allocations

# Client/Server connections

## Paraview reverse connection

Run [Paraview](https://www.paraview.org) in parallel on compute nodes and
interact with it from a local paraview instance to process large datasets. See
[pvconnect.sh](https://github.com/sayerhs/nrel-eagle/blob/master/pvconnect.sh).

**Steps on Eagle**

```bash
# Obtain the necessary compute resources (2 node for 72 MPI ranks)
salloc -N 2 -t 12:00:00 -A hfm --exclusive

# Load the necessary module for Paraview
module use /nopt/nrel/ecom/hpacf/software/modules/gcc-7.4.0
module load paraview

# Suppress MPICH warnings
export MXM_LOG_LEVEL=error

# Determine remote server or set IP yourself
local ssh_ip="${SSH_CONNECTION%% *}"
export PV_REMOTE_CLIENT="${PV_REMOTE_CLIENT:-${ssh_ip}}"

srun -n 72 --cpu-bind=cores pvserver -rc --force-offscreen-rendering --client-host={$PV_REMOTE_CLIENT}
```

**Steps on your laptop**

- Open Paraview 

- One time setup: Click on `connect` icon; **Add server**; choose `Client /
  Server (reverse connection)`; choose name and save.
  
- Select server option and click `connect`

## Connecting to remote Jupyter notebook

The key here is [SSH tunneling](#ssh-tunneling) to allow access to the notebook
on Eagle from local browser.

```bash
# Launch notebook server on DAV or compute node
jupyter notebook --no-browser
[C 09:41:10.012 NotebookApp]

    To access the notebook, open this file in a browser:
        file:///run/user/122774/jupyter/nbserver-16170-open.html
    Or copy and paste one of these URLs:
        http://localhost:8888/?token=ff327124313e9fdf1d66bffc64a0f155a64947f44b86aeda
        
# Determine remote server or set IP yourself
local ssh_ip="${SSH_CONNECTION%% *}"
export PV_REMOTE_CLIENT="${PV_REMOTE_CLIENT:-${ssh_ip}}"

# Reverse port forwarding
ssh -fNT -R 8888:localhost:8888 ${PV_REMOTE_CLIENT}

# From your local laptop's browser open the URL displayed above
```

Parallelizing within Python

- [multiprocessing](https://docs.python.org/3/library/multiprocessing.html)
- [Numba](https://numba.pydata.org) - Use threading, SIMD, and/or GPUs
- [Parallel IPython](https://ipyparallel.readthedocs.io/en/latest/)
- [mpi4py](https://ipyparallel.readthedocs.io/en/latest/)
- Machine learning/deep learning packages
  - [PyTorch](https://pytorch.org)
  - [Keras](https://keras.io)
  - [TensorFlow](https://www.tensorflow.org)

# Remote connection tips

## SSH config

```
Host *
    UseKeychain yes
    AddKeysToAgent yes
    ForwardAgent yes
    
Host eagle
    Hostname eagle.hpc.nrel.gov

Host el1
    HostName el1.hpc.nrel.gov

Host el2
    HostName el2.hpc.nrel.gov

Host el3
    HostName el3.hpc.nrel.gov

Host el4
    HostName el4.hpc.nrel.gov

Host ed1
    Hostname ed1.hpc.nrel.gov

Host ed2
    Hostname ed2.hpc.nrel.gov

Host ed3
    Hostname ed3.hpc.nrel.gov

Host ed4
    Hostname ed4.hpc.nrel.gov
```

- Use `passphrase` with SSH keys, use `ssh-agent` to manage passphrase that can
  be transferred to `eagle` during login.
  
- Create aliases for systems that can be used with `ssh` and `scp` commands.

  **Example**
  
  ```
  scp localfile.txt el2:~/remote_dir/remotefile.txt
  
  scp el2:~/remote_dir/remotefile2.txt .
  ```
  
---
  
## SSH tunneling

**Local-port forwarding**

```bash
# Login to DAV node and forward 8888 to access Jupyter notebooks from local browser
ssh -L 8890:localhost:8890 ed1
```

*Forward port 8890 on local machine to port 8890 on `ed1` (`localhost`).* After
successful connection, requests on port 8890 on local machine will behave as if
you executed them on DAV node (via FastX for example).

Another example:

```bash
# At your laptop's command prompt
ssh -L 8890:r6i1n14:8890 el1
```

Forward port 8890 on your laptop to compute node's port (assuming you have an
allocation) via `el1`. 

**Remote-port forwarding**

```bash
# In a job script or from Eagle (login, dav, compute node) command prompt
ssh -NTf -R 8888:localhost:8888 ${IP_ADDRESS_OF_LAPTOP}
```

- *Listen on port 8888 on the laptop and forward requests from that port to 8888
  on the local login, dav, or compute node.* With key-based authentication,
  useful for adding in `sbatch` submission scripts.

- For remote-port forwarding, we are only interested in forwarding ports and
  don't want to create a session and hold up the terminal/shell. The flags
  `-NTf` disables remote command execution, disables pseudo-TTY allocation and
  tells SSH to background itself after a successful connection. Don't use `-f`
  flag if you don't have key-based authentication and need to enter a password.

Another example:

```bash
# At your laptop's command prompt
ssh -R 8022:cori.nersc.gov:22 ed1.hpc.nrel.gov

# On ed1 command prompt
ssh -p 8022 localhost # Login to NERSC Cori
```

## Session management -- tmux/screen

- Use [tmux](https://github.com/tmux/tmux) or
  [screen](https://www.gnu.org/software/screen/) for persistent sessions.

  ```
  # Load necessary module
  module use /nopt/nrel/ecom/hpacf/utilities/modules
  module load tmux 
  
  # Create or attach to a session named `hfm`
  tmux -u new -A -s hfm 
  
  # When using iTerm2 on OS X
  tmux -u -CC new -A -s hfm
  ```
 
- Useful commands

  - `tmux new` -- Create a new session; `-s <name>` provides a unique name for
    the session for future reference (detach/reattach etc.); `-A` forces `new`
    to behave like `attach` if there is already a session with the name
    provided.
  
  - `tmux ls` -- List current `tmux` sessions
  
     ```bash
     eagle$ tmux ls
     wind: 3 windows (created Thu May 23 08:09:09 2019) [80x48] (attached)
     ```
     
  - `tmux lscm` -- List available commands
  
  - `tmux attach` -- Attach to a session, must exist or error
  
- Useful options

  - `-u` -- Force `UTF-8` support, useful for `vim`/`emacs` in terminal mode.
  
  - `-C` -- Start `tmux` in control mode, `-CC` disables echo. Useful with Mac
    OS X `iTerm2` application, where `tmux` windows behave like `iTerm2` tabs
    and you can interact with `iTerm2` commands.
  
- Suggested options in `~/.tmux.conf`

  ```
  # Update environment on SSH reconnects (for ssh-agent)
  set -g update-environment "DISPLAY SSH_AUTH_SOCK SSH_CONNECTION SSH_CLIENT"
  
  # Set terminal if not detected automatically
  set -g default-terminal "screen-256color"
  ```
  
  - Other useful options
  
    ```bash
    # Replace Ctrl+b with Ctrl+a (to behave like screen)
    unbind C-b
    bind C-a send-prefix
    
    # Start window numbering from 1 instead of 0, so that <prefix>-1 jumps to first window 
    set -g base-index 1
    ```

# File/Directory permissions

- Basic commands `chmod`, `chgrp` etc.

  ```bash
  # Read-execute permissions for all
  chmod a+rx <file>
  
  # read for files/directories, but set execute bit for directories recursively
  chmod -R go+rX <directory>
  ```

- Use `setfacl`/`getfacl` for more fine-grained control. Useful to restrict NDA
  material with a subset of the groups in `/projects` directory.
  
  ```bash
  # Allow read/execute access for a specific user
  setfacl -m u:gvijayak:rx <directory>
  
  # Show current permissions for <path>
  getfacl <path>
  ```

