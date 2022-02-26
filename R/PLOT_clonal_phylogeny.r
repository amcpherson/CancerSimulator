#================================PLOT CLONAL EVOLUTION AS PHYLOGENY TREE
PLOT_clonal_phylogeny <- function(package_simulation){
    package_sample_phylogeny        <- package_simulation[[3]]
    clone_phylogeny_phylo           <- package_sample_phylogeny[[2]]

    i       <- ape::which.edge(clone_phylogeny_phylo, c("A"))


    ape::plot.phylo(clone_phylogeny_phylo,direction="downward")

    ape::edgelabels(text=TeX(r'(Using $\LaTeX$ for plotting in base graphics!)', bold=TRUE)),edge=i)

    # ape::tiplabels()

}
