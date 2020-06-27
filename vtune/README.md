## VTune analysis

First, the code has been run under VTune on DevCloud "cluster" and we obtained the following picture:  

![](./img/vtune/old/new_core.c_ua1.png) 

As we can see, VTune marks the most CPU consuming task as "Outside any known module", and lots of lines are grayed out and marked "unreliable" when pointed with a mouse. It looks like we do not have proper access to hardware counters on Intel machine, so we went to a local laptop to see more detailed results. Thus the following picture has been obtained:

![](./img/vtune/original_bottomup_uarc.png)

Now we do not have any "Outside any known module" and can see that the function "evolve interior" does, in fact, consume the most resources. Here are the few summaries that VTune gave us:

![](img/vtune/original_memory_summary.png)



![](img/vtune/original_summary_the.png)

![](img/vtune/original_memory_bottomup.png)

![](img/vtune/original_summary_uarch.png)



If we ask to show which line of code takes the most, we, unsurprisingly, obtain the following:

![](img/vtune/old/core.c.analysis.png)

We have tried to modify the loop and only got slower results:

![](img/vtune/modified_bottomup_uarch.png)



![](img/vtune/modified_memory_summary.png)

![](img/vtune/modified_summary_the.png)

![](img/vtune/modified2_code_memory.png)

![](img/vtune/modified_2_summary_uarch.png)

![](img/vtune/modified_2_summary_memory.png)

![](img/vtune/modified_2_bottomup_memory.png)

![](img/vtune/modified_2_bottomup_uarch.png)