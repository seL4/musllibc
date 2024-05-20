#!/usr/bin/env python3
import pandas as pd
import plotnine as p9

# Load the benchmark data
data = pd.read_csv("benchmark_results.csv")

# Extract number of functions and shared objects from binary name
data["num_functions"] = data["binary"].apply(lambda x: int(x.split("_")[1]))
data["num_shared_objects"] = data["binary"].apply(lambda x: int(x.split("_")[2]))

# Create the heatmap
heatmap = (
    p9.ggplot(
        data,
        p9.aes(
            x="factor(num_functions)",
            y="factor(num_shared_objects)",
            fill="median_speedup",
        ),
    )
    + p9.geom_tile(p9.aes(width=0.95, height=0.95))
    + p9.labs(
        title="", x="Number of Functions", y="Number of Shared Objects", fill="Speedup"
    )
    + p9.scale_fill_gradient2(
        low="red",
        mid="white",
        high="green",
        midpoint=1,
    )
    + p9.geom_text(p9.aes(label="median_speedup"), size=9, show_legend=False)
    + p9.theme(  # new
        axis_ticks=p9.element_blank(),
        panel_background=p9.element_rect(fill="white"),
    )
    + p9.coord_fixed()
)

# Save the heatmap
heatmap.save("benchmark_heatmap.png")
print("Heatmap saved to benchmark_heatmap.png")
