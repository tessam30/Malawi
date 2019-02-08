theme_gantt <- function(base_size=11, base_family="Source Sans Pro Light") {
  ret <- theme_bw(base_size, base_family) %+replace%
    theme(panel.background = element_rect(fill="#ffffff", colour=NA),
          axis.title.x=element_text(vjust=-0.2), axis.title.y=element_text(vjust=1.5),
          title=element_text(vjust=1.2, family="Source Sans Pro Semibold"),
          panel.border = element_blank(), axis.line=element_blank(),
          panel.grid.minor=element_blank(),
          panel.grid.major.y = element_blank(),
          panel.grid.major.x = element_line(size=0.5, colour="grey80"),
          axis.ticks=element_blank(),
          legend.position="bottom", 
          axis.title=element_text(size=rel(0.8), family="Source Sans Pro Semibold"),
          strip.text=element_text(size=rel(1), family="Source Sans Pro Semibold"),
          strip.background=element_rect(fill="#ffffff", colour=NA),
          panel.spacing.y=unit(10, "lines"),
          legend.key = element_blank())
  
  ret
}

theme_timeline <- function(base_size = 10, base_family = "Lato Light") {
  ret <- theme_minimal(base_size, base_family) %+replace%
    theme(axis.ticks.x = element_blank(), 
          axis.line.x = element_blank(),
          legend.key = element_blank(),
          legend.position = "none",
          axis.text.y = element_blank(),
          axis.title.y = element_blank(),
          axis.title.x = element_blank(),
          panel.background = element_blank(),
          panel.grid.minor.y = element_blank(),
          panel.grid.major.y = element_blank())
  ret
}