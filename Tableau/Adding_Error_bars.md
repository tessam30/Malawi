### Adding error bars to a dot plot in Tableau
__Background__: we have a series of point estimates that have been created with a statistical software package. The point estimates include lower and upper bounds based on a 95% confidence interval. The goal is to create a dot plot with error bars to show the range of uncertainty. To do this, you will need to calculate the lower bound and the distance between the lower bound and upper bound estimate. 

__Steps__: 
1) __Dot plot__: Drop the appropriate dimension variable on the rows shelf. Next, add the point estimate variable to the columns  (`stunting`). Change the mark type to a circle. Drop the same variable on the color to double encode the circle. Add a stroke to the circle using the color button on the marks card.
2) __Setting Measure Values__: Add the `# Measure Values` measure to the Filters card. The filter window will pop up. Select the lower bound measure. 
3) __Adding Measure Values__: Drop the `# Measure Values` measure on the columns shelf. A new graph should appear next to the dot plot.
4) __Create confidence interval__: Convert the new graph to a Gantt Bar. Drop the `confidence interval distance` measure on the size button in the marks card. The Gantt chart will turn into a bar graph. Reduce the size of the bar using the size button. If you want to double encode the estimate, drag the `confidence interval distance` on the color button. 
5) __Combine graphs, synchronize axes__: Finally, right click on the `MeasureValues` pill and select dual axis. Right click on the axis at the top of the screen, select synchronize axis, and then hide the axis by clicking show header. 
6) __Over time__: If you want to create dot plots across time, create a discrete time variable and drop it on the Filters card. 

You should now have a dotplot with lower and upper confidence intervals. Sort the estimates as desired. Use parameters to allow the user to toggle between years. 
