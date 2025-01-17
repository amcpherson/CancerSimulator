# ================================================SIMULATE MISSEGREGATION
#' @export
SIMULATOR_FULL_PHASE_1_CN_missegregation <- function(genotype_to_react, genotype_daughter_1, genotype_daughter_2) {
    #------------------------------------Find the new CN and driver profiles
    #   Find the daughter cells' current CN and driver profiles
    ploidy_chrom_1 <- genotype_list_ploidy_chrom[[genotype_daughter_1]]
    ploidy_allele_1 <- genotype_list_ploidy_allele[[genotype_daughter_1]]
    ploidy_block_1 <- genotype_list_ploidy_block[[genotype_daughter_1]]
    driver_count_1 <- genotype_list_driver_count[genotype_daughter_1]
    driver_map_1 <- genotype_list_driver_map[[genotype_daughter_1]]

    ploidy_chrom_2 <- genotype_list_ploidy_chrom[[genotype_daughter_2]]
    ploidy_allele_2 <- genotype_list_ploidy_allele[[genotype_daughter_2]]
    ploidy_block_2 <- genotype_list_ploidy_block[[genotype_daughter_2]]
    driver_count_2 <- genotype_list_driver_count[genotype_daughter_2]
    driver_map_2 <- genotype_list_driver_map[[genotype_daughter_2]]
    #   Find information about the missegregation
    while (1) {
        #       Choose which cell to gain/lose the strand
        i_gain <- sample.int(2, size = 1)
        #       Choose the chromosome to be mis-segregated
        chrom <- sample.int(N_chromosomes, size = 1)
        if (i_gain == 1) {
            no_strands <- ploidy_chrom_2[chrom]
        } else {
            if (i_gain == 2) {
                no_strands <- ploidy_chrom_1[chrom]
            }
        }
        if (no_strands <= 0) {
            next
        }
        #       Choose the strand to be mis-segregated
        strand <- sample.int(no_strands, size = 1)
        break
    }
    #   Find all drivers located on this strand in the losing cell
    if ((i_gain == 1) && (driver_count_2 > 0)) {
        pos_drivers_to_move <- intersect(which((driver_map_2[, 2] == chrom)), which((driver_map_2[, 3] == strand)))
    } else {
        if ((i_gain == 2) && (driver_count_1 > 0)) {
            pos_drivers_to_move <- intersect(which((driver_map_1[, 2] == chrom)), which((driver_map_1[, 3] == strand)))
        } else {
            pos_drivers_to_move <- c()
        }
    }
    N_drivers_to_move <- length(pos_drivers_to_move)
    #   Change the chromosome ploidy of daughter cells
    if (i_gain == 1) {
        ploidy_chrom_1[chrom] <- ploidy_chrom_1[chrom] + 1
        ploidy_chrom_2[chrom] <- ploidy_chrom_2[chrom] - 1
    } else {
        if (i_gain == 2) {
            ploidy_chrom_2[chrom] <- ploidy_chrom_2[chrom] + 1
            ploidy_chrom_1[chrom] <- ploidy_chrom_1[chrom] - 1
        }
    }
    #   Update the chromosome strand allele identities of daughter cells
    if (i_gain == 1) {
        chrom_ploidy <- ploidy_chrom_1[chrom]
        ploidy_allele_1[[chrom]][[chrom_ploidy]] <- ploidy_allele_2[[chrom]][[strand]]
        chrom_ploidy <- ploidy_chrom_2[chrom]
        if (strand <= chrom_ploidy) {
            for (i_strand in strand:chrom_ploidy) {
                ploidy_allele_2[[chrom]][[i_strand]] <- ploidy_allele_2[[chrom]][[i_strand + 1]]
            }
        }
        ploidy_allele_2[[chrom]] <- ploidy_allele_2[[chrom]][-(chrom_ploidy + 1)] # Remove item from ploidy_block_2[[chrom]]
    } else {
        if (i_gain == 2) {
            chrom_ploidy <- ploidy_chrom_2[chrom]
            ploidy_allele_2[[chrom]][[chrom_ploidy]] <- ploidy_allele_1[[chrom]][[strand]]
            chrom_ploidy <- ploidy_chrom_1[chrom]
            if (strand <= chrom_ploidy) {
                for (i_strand in strand:chrom_ploidy) {
                    ploidy_allele_1[[chrom]][[i_strand]] <- ploidy_allele_1[[chrom]][[i_strand + 1]]
                }
            }
            ploidy_allele_1[[chrom]] <- ploidy_allele_1[[chrom]][-(chrom_ploidy + 1)]
        }
    }
    #   Move the chromosome strand from losing cell to winning cell
    if (i_gain == 1) {
        chrom_ploidy <- ploidy_chrom_1[chrom]
        ploidy_block_1[[chrom]][[chrom_ploidy]] <- ploidy_block_2[[chrom]][[strand]]
        chrom_ploidy <- ploidy_chrom_2[chrom]
        if (strand <= chrom_ploidy) {
            for (i_strand in strand:chrom_ploidy) {
                ploidy_block_2[[chrom]][[i_strand]] <- ploidy_block_2[[chrom]][[i_strand + 1]]
            }
        }
        # ploidy_block_2[[chrom]][strand:chrom_ploidy]   <- ploidy_block_2[[chrom]][strand+1:chrom_ploidy+1]
        # ploidy_block_2[[chrom]][[strand:chrom_ploidy]]   <- ploidy_block_2[[chrom]][[strand+1:chrom_ploidy+1]]

        ploidy_block_2[[chrom]] <- ploidy_block_2[[chrom]][-(chrom_ploidy + 1)] # Remove item from ploidy_block_2[[chrom]]
    } else {
        if (i_gain == 2) {
            chrom_ploidy <- ploidy_chrom_2[chrom]
            ploidy_block_2[[chrom]][[chrom_ploidy]] <- ploidy_block_1[[chrom]][[strand]]
            chrom_ploidy <- ploidy_chrom_1[chrom]

            if (strand <= chrom_ploidy) {
                for (i_strand in strand:chrom_ploidy) {
                    ploidy_block_1[[chrom]][[i_strand]] <- ploidy_block_1[[chrom]][[i_strand + 1]]
                }
            }
            # ploidy_block_1[[chrom]][strand:chrom_ploidy]   <- ploidy_block_1[[chrom]][strand+1:chrom_ploidy+1]
            # ploidy_block_1[[chrom]][[strand:chrom_ploidy]]   <- ploidy_block_1[[chrom]][[strand+1:chrom_ploidy+1]]

            ploidy_block_1[[chrom]] <- ploidy_block_1[[chrom]][-(chrom_ploidy + 1)]
        }
    }
    #   Move the drivers from losing cell to winning cell
    if ((i_gain == 1) && (N_drivers_to_move > 0)) {
        driver_map_new_1 <- driver_map_2[pos_drivers_to_move, ]
        if (!is.matrix(driver_map_new_1)) {
            driver_map_new_1 <- matrix(driver_map_new_1, nrow = 1)
        }
        driver_map_new_1[, 3] <- ploidy_chrom_1[chrom]
        driver_map_1 <- rbind(driver_map_1, driver_map_new_1)
        driver_map_2 <- driver_map_2[-pos_drivers_to_move, ]
        if (!is.matrix(driver_map_2)) {
            driver_map_2 <- matrix(driver_map_2, nrow = 1)
        }
    } else {
        if ((i_gain == 2) && (N_drivers_to_move > 0)) {
            driver_map_new_2 <- driver_map_1[pos_drivers_to_move, ]
            if (!is.matrix(driver_map_new_2)) {
                driver_map_new_2 <- matrix(driver_map_new_2, nrow = 1)
            }
            driver_map_new_2[, 3] <- ploidy_chrom_2[chrom]
            driver_map_2 <- rbind(driver_map_2, driver_map_new_2)
            driver_map_1 <- driver_map_1[-pos_drivers_to_move, ]
            if (!is.matrix(driver_map_1)) {
                driver_map_1 <- matrix(driver_map_1, nrow = 1)
            }
        }
    }
    #   Change the driver count in each daughter cell
    driver_unique_1 <- unique(driver_map_1[, 1])
    driver_unique_1 <- driver_unique_1[driver_unique_1 != 0]
    driver_count_1 <- length(driver_unique_1)

    driver_unique_2 <- unique(driver_map_2[, 1])
    driver_unique_2 <- driver_unique_2[driver_unique_2 != 0]
    driver_count_2 <- length(driver_unique_2)

    # print("----------------------------")
    # ploidy_chrom <- genotype_list_ploidy_chrom[[genotype_to_react]]
    # ploidy_allele <- genotype_list_ploidy_allele[[genotype_to_react]]
    # ploidy_block <- genotype_list_ploidy_block[[genotype_to_react]]
    # driver_count <- genotype_list_driver_count[genotype_to_react]
    # driver_map <- genotype_list_driver_map[[genotype_to_react]]
    # print("")
    # print(SIMULATOR_FULL_PHASE_1_selection_rate(driver_count, driver_map, ploidy_chrom, ploidy_block, ploidy_allele))
    # print("")
    #
    # if (i_gain == 2) {
    #     print("")
    #     print(SIMULATOR_FULL_PHASE_1_selection_rate(driver_count_1, driver_map_1, ploidy_chrom_1, ploidy_block_1, ploidy_allele_1))
    #     print("")
    # } else {
    #     print("")
    #     print(SIMULATOR_FULL_PHASE_1_selection_rate(driver_count_2, driver_map_2, ploidy_chrom_2, ploidy_block_2, ploidy_allele_2))
    #     print("")
    # }

    #-----------------------------------------------Output the new genotypes
    genotype_list_ploidy_chrom[[genotype_daughter_1]] <<- ploidy_chrom_1
    genotype_list_ploidy_allele[[genotype_daughter_1]] <<- ploidy_allele_1
    genotype_list_ploidy_block[[genotype_daughter_1]] <<- ploidy_block_1
    genotype_list_driver_count[genotype_daughter_1] <<- driver_count_1
    genotype_list_driver_map[[genotype_daughter_1]] <<- driver_map_1
    if (i_gain == 1) {
        loc_end <- length(evolution_genotype_changes[[genotype_daughter_1]])
        evolution_genotype_changes[[genotype_daughter_1]][[loc_end + 1]] <<- c("missegregation", chrom, strand, 1)
    } else {
        if (i_gain == 2) {
            loc_end <- length(evolution_genotype_changes[[genotype_daughter_1]])
            evolution_genotype_changes[[genotype_daughter_1]][[loc_end + 1]] <<- c("missegregation", chrom, strand, -1)
        }
    }

    genotype_list_ploidy_chrom[[genotype_daughter_2]] <<- ploidy_chrom_2
    genotype_list_ploidy_allele[[genotype_daughter_2]] <<- ploidy_allele_2
    genotype_list_ploidy_block[[genotype_daughter_2]] <<- ploidy_block_2
    genotype_list_driver_count[genotype_daughter_2] <<- driver_count_2
    genotype_list_driver_map[[genotype_daughter_2]] <<- driver_map_2
    if (i_gain == 1) {
        loc_end <- length(evolution_genotype_changes[[genotype_daughter_2]])
        evolution_genotype_changes[[genotype_daughter_2]][[loc_end + 1]] <<- c("missegregation", chrom, strand, -1)
    } else {
        if (i_gain == 2) {
            loc_end <- length(evolution_genotype_changes[[genotype_daughter_2]])
            evolution_genotype_changes[[genotype_daughter_2]][[loc_end + 1]] <<- c("missegregation", chrom, strand, 1)
        }
    }
}
print("")
