## VTune analysis

First, the code has been run under VTune on DevCloud "cluster" and we obtained the following picture:  

![](./img/vtune/old/new_core.c_ua1.png) 

As we can see, VTune marks the most CPU consuming task as "Outside any known module", and lots of lines are grayed out and marked "unreliable" when pointed with a mouse. It looks like we do not have proper access to hardware counters on Intel machine, so we went to a local laptop to see more detailed results. Thus the following picture has been obtained:

![](./img/vtune/original_bottomup_uarc.png)

Now we do not have any "Outside any known module" and can see that the function "evolve interior" does, in fact, consume the most resources. Here are the few summaries that VTune gave us:

![](img/vtune/original_memory_summary.png)

We see that the bandwidth we get is rather high, around 28 GB/sec.

![](img/vtune/original_summary_the.png)

The CPU utilization seems low, but that is because the software detects all available CPUs while we couldn't run the code on 6 cores due to how the distribution of the data is implemented. So we were only using 4 cores and got effective utilization of 3.623.



Now lets look at our memory usage:

![](img/vtune/original_memory_bottomup.png)

![](img/vtune/original_summary_uarch.png)

We see that the application is memory bound and the most time is spent accessing DRAM.

If we ask to show which line of code takes the most, we, unsurprisingly, obtain the following:

![](img/vtune/original_memory_code.png)

We have tried to modify the loop (doing simple modification like taking all the common factors out of the loops) and only got slightly slower results with higher cpi rate. Apparently, compiler is able to modify simple loops better than us. 

![](img/vtune/modified_bottomup_uarch.png)



![](img/vtune/modified_memory_summary.png)

![](img/vtune/modified_summary_the.png)

But overall we see that nothing changed much and we are still heavily memory bound. We know that the problem comes from accessing a different raw when doing stencil calculations.

So, we decided to use the idea of "fast matrix transpose" and first copy part of the memory into smaller arrays that are much more cache-friendly. This became, however, a great illustration to why sometimes it's better to not try optimizing...

The overall time actually went up from 19 to 22, but we are not so DRAM bound anymore.

![](img/vtune/modified_2_bottomup_memory.png)



![](img/vtune/modified_2_summary_uarch.png)

We can see that we actually lowered the bandwidth from 28 GB/sec to 24:

![](img/vtune/modified_2_summary_memory.png)

So, at the end we see that we moved the problem from  evolve_interior to memcpy:

![](img/vtune/modified_2_bottomup_uarch.png)



## Conclusions:

- VTune showed us where the hotspot was and that the application was memory bound with lots of cache-misses. 

- We implemented the memcpy, thus getting rid of cache misses, but the overall run time increased around 16 % due to spending time on memory rearrangements. 

- There are two possible things to do for future work: implement avx with intrinsics and globally redesign the algorithm to work in batches from the start.   








