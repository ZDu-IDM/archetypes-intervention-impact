library(data.table)
library(raster)
library(rasterVis)

rm(list=ls())

main_dir <- file.path(Sys.getenv("USERPROFILE"), 
                      "Dropbox (IDM)/Malaria Team Folder/projects/map_intervention_impact/seasonal_classification")
out_dir <- copy(main_dir)

continent <- "africa"
cov <- "vector_abundance"

this_dir <- file.path(main_dir, continent)
out_dir<- file.path(this_dir, "rasters", "astmh")

traces <- fread(file.path(this_dir, "kmeans", "random_trace_tsi_rainfall_vector_abundance_6.csv"))
traces <- traces[variable_name=="month"]
traces[, variable_val:=as.integer(variable_val)]
traces[, cluster:=as.factor(cluster)]
summary_traces <- traces[, list(perc_25=quantile(cov_val, c(0.25)),
                                perc_75=quantile(cov_val, c(0.75)),
                                median=median(cov_val)), by=list(cov, cluster, variable_val)]

ggplot(summary_traces, aes(x=variable_val, y=median, color=cluster)) +
  geom_line() +
  facet_grid(cov~cluster, scales="free") +
  geom_ribbon(aes(ymin=perc_25, ymax=perc_75, fill=cluster), alpha=0.5)
  




all_fnames <- list.files(file.path(this_dir, rasters), full.names = T)

for (cov in c("rainfall", "tsi", "vector_abundance")){
  
  print(cov)
  
  fnames <- all_fnames[all_fnames %like% cov]
  if (length(fnames)==12){fnames<- fnames[c(3,6,9,12)]}
  rasters <- lapply(fnames, raster)
  
  if (cov=="vector_abundance"){
    
    palettes <- c("Greens", "Reds", "Blues")
    idx <- 1
    
    for(layer in rasters){
      print(names(layer))
      pdf(file.path(out_dir, paste0(names(layer), ".pdf")), width=9, height=6)
      this_plot <- levelplot(layer, par.settings=rasterTheme(brewer.pal(9, palettes[idx])), scales=list(draw=FALSE), xlab=NULL, ylab=NULL, margin=F)
      print(this_plot)
      graphics.off()
      idx <- idx + 1
    }
    
  }else{
    pdf(file.path(out_dir, paste0(cov, ".pdf")), width=9, height=6)
    
    rasters <- stack(rasters)
    
    if (cov=="rainfall"){
      # calculate breaks
      maxvals <- maxValue(rasters)
      biggest <- which(maxvals==maxvals[maxvals==max(maxvals)])
      breaks <- breaks <- quantile(rasters[[biggest]], probs=seq(0, 1, 0.05))
      
      this_plot <- levelplot(rasters, par.settings=rasterTheme(brewer.pal(7, "BrBG")), scales=list(draw=FALSE), at=breaks, xlab=NULL, ylab=NULL, margin=F)
      print(this_plot)
      
    }else{
      this_plot <- levelplot(rasters, par.settings=rasterTheme(rev(terrain.colors(10))), scales=list(draw=FALSE), xlab=NULL, ylab=NULL, margin=F)
      print(this_plot)
    }
    graphics.off()
    
  }
}









