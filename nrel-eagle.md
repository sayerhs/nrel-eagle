<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Introduction](#introduction)
- [SLURM -- Job submission and management](#slurm----job-submission-and-management)
    - [Command overview](#command-overview)
        - [List free/allocated nodes](#list-freeallocated-nodes)
        - [List jobs on queue](#list-jobs-on-queue)

<!-- markdown-toc end -->

# Introduction

# SLURM -- Job submission and management 

Eagle uses [SLURM](https://slurm.schedmd.com) for scheduling and managing jobs
on the system. 

- [Quick start user guide](https://slurm.schedmd.com/quickstart.html)
- [Cheatsheet (PDF)](https://slurm.schedmd.com/pdfs/summary.pdf)
- [Detailed manual pages](https://slurm.schedmd.com/man_index.html)

## Command overview

### List free/allocated nodes

Use [sinfo](https://slurm.schedmd.com/sinfo.html) to list nodes and partition
information. You can pass a formatting string to summarize the information.

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
eagle$ $ sinfo -o '%24P %.5a  %.12l  %.16F %G'
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

### List jobs on queue

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
eagle$ $ squeue -u gvijayak -o '%12i %20j %.6D %.2t %.10M %.9P %r'
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

