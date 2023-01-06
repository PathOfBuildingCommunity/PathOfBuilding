This document is intended to help contributors understand what's going on in the offensive calculation process. More specifically, it aims to ensure that you understand what an output is, and where they are set.

At the most basic level, an output is a collection of values that belong to an actor. The very first [lines](../src/Modules/CalcPerform.lua#L1133) of the calcs.perform function shows this.

In CalcOffence a number of [passes](../src/Modules/CalcOffence.lua#L1393) are made. For attacks, it's a pass for main hand and one for off hand if it exists. For non-attacks, it's just the one pass. For attacks this means that the output is set to the output of the weapon, so `output.MainHand` rather than output. The consequence of this is that any value added to output inside of a damage pass may not be added onto the main or global output.

The places passes are iterated through are:

[hit speed and accuracy](../src/Modules/CalcOffence.lua#L1532)

[damage](../src/Modules/CalcOffence.lua#L1853)

[ailments and debuffs](../src/Modules/CalcOffence.lua#L2989)


As a concrete example, let's say the active skill is an attack. You want to add the variable `VeryCoolVar` to the main output, and you want to do it inside of one of the damage pass. As you can see on the first few lines of each of the for loops iterating over the passes, the first thing that happens is that `globalOutput` is defined to be output, and a local `output` is set to `pass.output`. In other words:

Inside the for loops for the passes, when using an attack, `output.VeryCoolVar` is actually `actor.output.MainHand.VeryCoolVar` or `actor.output.OffHand.VeryCoolVar`. Outside the for loops, `output.VeryCoolVar` is `actor.output.VeryCoolVar`. 

In order to add a variable to `actor.output` while inside the passes, you have two options. 

1) Add it to `globalOutput`, which points to `actor.output`. This is great when it's a stat not connected to a hand, so there's no point calculating it for both hands.
2) Combine the stats. The function `combineStat` takes the specified stat from both `actor.output.MainHand.stat` and `actor.output.OffHand.stat` and combines them into `actor.output.stat`. This is already done for other stats after every loop that iterates over the passes. To reiterate, while inside the passes as an attack, the local variable `output` is already set to `actor.output.MainHand` or OffHand. All you need to do is add `output.VeryCoolVar` inside the pass, and then `combineStat("VeryCoolVar", type)` after the passes are done.

If you're trying to add something to an output and it's not showing up, it's likely you're adding it to the wrong output. Double check where you are in the code and what output is behind the currently local `output` variable.