create_figure1 <- function(results) {
    figure1 <- grViz("digraph flowchart {
      # node definitions with substituted label text
      node [fontname = Helvetica, shape = rectangle, width = 4]        
      graph [rankdir = LR]
      
      tab1 [label = '@@1']
      tab2 [label = '@@2']
      tab3 [label = '@@3']
      tab4 [label = '@@4']
      tab5 [label = '@@5']
      tab6 [label = '@@6']
      tab7 [label = '@@7']
      
      node [shape = point, style = filled ,color = black, label = '', height = 0]
      a,b,c,d,f
      
      subgraph {
      rank = same;
      tab1 -> a [arrowhead=none] 
      a-> tab2 
      tab2 -> b [arrowhead=none] 
      b -> tab3 
      tab3 -> c [arrowhead=none] 
      c -> tab4
      
      }

      # edge definitions with the node IDs
      a -> tab5 
      b -> tab6 
      c -> tab7
      }

      [1]: paste0('Participants in the TITCO cohort: ', results$n.cohort )
      [2]: paste0('Participants above age 18: ', results$n.adults)
      [3]: paste0('Participants alive at admission: ', results$n.included)
      [4]: paste0('Participants with complete data: ', results$n.complete)
      [5]: paste0('Participants below age 18: ', results$n.younger.than.18)
      [6]: paste0('Participants died before admission: ', results$n.incl2)
      [7]: paste0('Participants with missing data: ', results$n.NA_TOT, '\\n', 'Missing ICU admission: ', results$n.NA_ICU, '\\n','Missing systolic blood preassure: ', results$n.NA_SBP, '\\n', 'Missing respiratory rate: ', results$n.NA_RR, '\\n', 'Missing Glascow coma scale: ', results$n.NA_GCS)

      ")
    export_svg(figure1) %>% charToRaw %>% rsvg_svg("figure1.svg")
    message("Figure 1 created and saved to disk")
    invisible(figure1)
}
