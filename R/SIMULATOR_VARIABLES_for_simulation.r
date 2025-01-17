# =============================SET ALL PARAMETERS REQUIRED FOR SIMULATION
#' @export
SIMULATOR_VARIABLES_for_simulation <- function(model) {
    #--------------------------------------Set up variables for cancer model
    #---Input table of variables from file
    filename <- paste(model, "-input-variables.csv", sep = "")
    TABLE_VARIABLES <- read.table(filename, header = TRUE, sep = ",")
    #---Input table of selection model from file
    filename <- paste(model, "-input-selection-model.csv", sep = "")
    TABLE_SELECTION <- read.table(filename, header = TRUE, sep = ",")






    #---Save file for GC content and mappability per CN bin
    filename <- paste(model, "-input-gc.csv", sep = "")
    TABLE_GC <- read.table(filename, header = TRUE, sep = ",")
    #---Input table of total population dynamics
    filename <- paste(model, "-input-population-dynamics.csv", sep = "")
    TABLE_POPULATION_DYNAMICS <- read.table(filename, header = TRUE, sep = ",")
    #---Input table of chromosome bin counts and centromere locations
    filename <- paste(model, "-input-copy-number-blocks.csv", sep = "")
    TABLE_CHROMOSOME_CN_INFO <- read.table(filename, header = TRUE, sep = ",")
    #---Input table of sampling information
    filename <- paste(model, "-input-sampling.csv", sep = "")
    TABLE_SAMPLING_INFO <- read.table(filename, header = TRUE, sep = ",")
    #---Input table of mutational and CNA genes
    filename <- paste(model, "-input-selection-genes.csv", sep = "")
    if (file.exists(filename)) {
        TABLE_CANCER_GENES <- read.table(filename, header = TRUE, sep = ",")
    } else {
        TABLE_CANCER_GENES <- data.frame()
    }

    #---Input table of selection rates for individual chromosome arms
    filename <- paste(model, "-input-selection-chrom-arm.csv", sep = "")
    if (file.exists(filename)) {
        TABLE_CANCER_ARMS <- read.table(filename, header = TRUE, sep = ",")
    } else {
        TABLE_CANCER_ARMS <- data.frame()
    }

    #---Input table of CN profiles for the initial population
    filename <- paste(model, "-input-initial-cn-profiles.csv", sep = "")
    TABLE_INITIAL_COPY_NUMBER_PROFILES <- read.table(filename, header = TRUE, sep = ",")
    #---Input other information for the initial population
    filename <- paste(model, "-input-initial-others.csv", sep = "")
    TABLE_INITIAL_OTHERS <- read.table(filename, header = TRUE, sep = ",")
    #---Set up individual variables from table
    for (i in 1:nrow(TABLE_VARIABLES)) {
        assign(TABLE_VARIABLES[i, 1], TABLE_VARIABLES[i, 2], envir = .GlobalEnv)
    }
    standard_time_unit <<- TABLE_VARIABLES$Unit[TABLE_VARIABLES$Variable == "age_end"]
    assign("standard_time_unit", standard_time_unit, envir = .GlobalEnv)


    for (i in 1:nrow(TABLE_SELECTION)) {
        if (is.na(suppressWarnings(as.numeric(TABLE_SELECTION[i, 2])))) {
            assign(TABLE_SELECTION[i, 1], TABLE_SELECTION[i, 2], envir = .GlobalEnv)
        } else {
            assign(TABLE_SELECTION[i, 1], as.numeric(TABLE_SELECTION[i, 2]), envir = .GlobalEnv)
        }
    }


    Table_sampling <<- TABLE_SAMPLING_INFO
    assign("Table_sampling", Table_sampling, envir = .GlobalEnv)







    #   level_purity is only for SIMULATOR_CLONAL and SIMULATOR_ODE
    level_purity <<- 1







    #---Set up individual variables from table
    N_chromosomes <<- nrow(TABLE_CHROMOSOME_CN_INFO)
    for (i in 1:ncol(TABLE_CHROMOSOME_CN_INFO)) {
        assign(colnames(TABLE_CHROMOSOME_CN_INFO)[i], TABLE_CHROMOSOME_CN_INFO[, i], envir = .GlobalEnv)
    }
    vec_chromosome_id <<- Chromosome
    vec_CN_block_no <<- Bin_count
    vec_centromere_location <<- Centromere_location
    #---Set up mutational and CNA driver library (without selection rates)
    if (length(TABLE_CANCER_GENES) == 0) {
        driver_library <<- data.frame()
    } else {
        driver_library <<- TABLE_CANCER_GENES
    }
    if (length(TABLE_CANCER_ARMS) == 0) {
        chrom_arm_library <<- data.frame()
    } else {
        chrom_arm_library <<- TABLE_CANCER_ARMS
    }


    #---Set up table of GC content and mappability per CN bin
    table_gc <<- TABLE_GC

    #-------------------------------Set up initial state for simulations
    #   Get number of clones in the initial population
    initial_N_clones <<- nrow(TABLE_INITIAL_OTHERS)
    vec_header <- names(TABLE_INITIAL_COPY_NUMBER_PROFILES)
    #---Initialize ID and population for each clone
    initial_clonal_ID <<- 1:initial_N_clones
    initial_population <<- rep(0, initial_N_clones)
    for (clone in 1:initial_N_clones) {
        #       Get driver profile of this clone
        loc <- which(TABLE_INITIAL_OTHERS$Clone == clone)
        population <- TABLE_INITIAL_OTHERS$Cell_count[loc]
        initial_population[loc] <<- population
    }
    #---Initialize the genotypes for each clone
    initial_ploidy_chrom <<- vector("list", length = initial_N_clones)
    initial_ploidy_allele <<- vector("list", length = initial_N_clones)
    initial_ploidy_block <<- vector("list", length = initial_N_clones)
    initial_driver_count <<- rep(0, initial_N_clones)
    initial_driver_map <<- vector("list", length = initial_N_clones)
    initial_DNA_length <<- vector("list", length = initial_N_clones)
    initial_selection_rate <<- rep(0, initial_N_clones)
    initial_prob_new_drivers <<- rep(0, initial_N_clones)
    assign("initial_N_clones", initial_N_clones, envir = .GlobalEnv)
    assign("initial_ploidy_chrom", initial_ploidy_chrom, envir = .GlobalEnv)
    assign("initial_ploidy_allele", initial_ploidy_allele, envir = .GlobalEnv)
    assign("initial_ploidy_block", initial_ploidy_block, envir = .GlobalEnv)
    assign("initial_driver_count", initial_driver_count, envir = .GlobalEnv)
    assign("initial_driver_map", initial_driver_map, envir = .GlobalEnv)
    assign("initial_DNA_length", initial_DNA_length, envir = .GlobalEnv)
    assign("initial_selection_rate", initial_selection_rate, envir = .GlobalEnv)
    assign("initial_prob_new_drivers", initial_prob_new_drivers, envir = .GlobalEnv)
    assign("initial_clonal_ID", initial_clonal_ID, envir = .GlobalEnv)
    assign("initial_population", initial_population, envir = .GlobalEnv)
    #---Set up the initial clones' CN genotypes
    for (clone in 1:initial_N_clones) {
        #       Extract mini table for the CN genotypes of this clone
        CLONE_INITIAL_COPY_NUMBER_PROFILES <- TABLE_INITIAL_COPY_NUMBER_PROFILES[TABLE_INITIAL_COPY_NUMBER_PROFILES$Clone == clone, ]
        #       Set up clone's CN genotype
        ploidy_chrom <- rep(0, N_chromosomes)
        ploidy_block <- list()
        ploidy_allele <- list()
        for (chrom in 1:N_chromosomes) {
            ploidy_block[[chrom]] <- list()
            ploidy_allele[[chrom]] <- list()
            #           Get CN genotype for this chromosome
            CHROM_COPY_NUMBER_PROFILES <- CLONE_INITIAL_COPY_NUMBER_PROFILES[CLONE_INITIAL_COPY_NUMBER_PROFILES$Chromosome == TABLE_CHROMOSOME_CN_INFO$Chromosome[chrom], ]
            if (nrow(CHROM_COPY_NUMBER_PROFILES) == 0) {
                ploidy_chrom[chrom] <- 0
                next
            } else {
                no_strands <- max(CHROM_COPY_NUMBER_PROFILES$Strand)
            }
            #           Update the strand count for each chromosome
            ploidy_chrom[chrom] <- no_strands
            #           Update the CN count and allele info for each chrosomome strand
            for (strand in 1:no_strands) {
                no_blocks <- vec_CN_block_no[chrom]
                strand_ploidy_block <- rep(0, no_blocks)
                strand_ploidy_allele <- matrix(rep(0, no_blocks), nrow = 1)
                STRAND_COPY_NUMBER <- CHROM_COPY_NUMBER_PROFILES[CHROM_COPY_NUMBER_PROFILES$Strand == strand, ]
                if (nrow(STRAND_COPY_NUMBER) > 0) {
                    for (i in 1:nrow(STRAND_COPY_NUMBER)) {
                        bin_start <- STRAND_COPY_NUMBER$Bin_start[i]
                        bin_end <- STRAND_COPY_NUMBER$Bin_end[i]
                        vec_allele <- STRAND_COPY_NUMBER$Allele[i]
                        if (vec_allele == "") {
                            no_units <- 0
                            strand_ploidy_block[bin_start:bin_end] <- no_units
                            next
                        }
                        no_units <- nchar(vec_allele)
                        strand_ploidy_block[bin_start:bin_end] <- no_units
                        for (unit in 1:no_units) {
                            if (unit > nrow(strand_ploidy_allele)) {
                                strand_ploidy_allele <- rbind(strand_ploidy_allele, rep(0, ncol(strand_ploidy_allele)))
                            }
                            strand_ploidy_allele[unit, bin_start:bin_end] <- utf8ToInt(substr(vec_allele, unit, unit)) - 64
                        }
                    }
                }
                ploidy_block[[chrom]][[strand]] <- strand_ploidy_block
                ploidy_allele[[chrom]][[strand]] <- strand_ploidy_allele
            }
        }
        #       Store the clone's CN profiles
        initial_ploidy_chrom[[clone]] <<- ploidy_chrom
        initial_ploidy_allele[[clone]] <<- ploidy_allele
        initial_ploidy_block[[clone]] <<- ploidy_block
    }
    #---Set up the initial clones' driver profiles
    for (clone in 1:initial_N_clones) {
        #       Get driver profile of this clone
        loc <- which(TABLE_INITIAL_OTHERS$Clone == clone)
        all_drivers <- TABLE_INITIAL_OTHERS$Drivers[loc]
        if (is.na(all_drivers) | all_drivers == "") {
            initial_driver_count[clone] <<- 0
            initial_driver_map[[clone]] <<- matrix(0, nrow = 1)
            next
        }
        list_drivers <- strsplit(all_drivers, ";")
        list_drivers <- list_drivers[[1]]
        #       Update the driver count for this clone
        initial_driver_count[clone] <<- length(list_drivers)
        #       Update the driver map for this clone
        driver_map <- c()
        for (driver in 1:length(list_drivers)) {
            driver_info <- strsplit(list_drivers[driver], "_")
            driver_info <- driver_info[[1]]
            #           Get driver's ID, strand and unit
            driver_ID <- driver_info[1]
            driver_strand <- strtoi(sub(".*strand", "", driver_info[2]))
            driver_unit <- strtoi(sub(".*unit", "", driver_info[3]))
            #           Get driver's chromosome and block
            driver_loc <- which(driver_library$Gene_ID == driver_ID)
            driver_chrom <- driver_library$Chromosome[driver_loc]
            driver_block <- driver_library$Bin[driver_loc]
            driver_map <- rbind(driver_map, c(driver_loc, driver_chrom, driver_strand, driver_block, driver_unit))
        }
        initial_driver_map[[clone]] <<- driver_map
    }
    #---Set up the initial clones' DNA length
    for (clone in 1:initial_N_clones) {
        ploidy_chrom <- initial_ploidy_chrom[[clone]]
        ploidy_block <- initial_ploidy_block[[clone]]
        DNA_length <- 0
        for (chrom in 1:N_chromosomes) {
            if (ploidy_chrom[chrom] == 0) {
                next
            }
            for (strand in 1:ploidy_chrom[chrom]) {
                DNA_length <- DNA_length + sum(ploidy_block[[chrom]][[strand]])
            }
        }
        DNA_length <- size_CN_block_DNA * DNA_length
        prob_new_drivers <- 1 - dpois(x = 0, lambda = rate_driver * DNA_length)
        initial_DNA_length[[clone]] <<- DNA_length
        initial_prob_new_drivers[clone] <<- prob_new_drivers
    }
    #---Set up the initial clones' selection rates
    for (clone in 1:initial_N_clones) {
        ploidy_chrom <- initial_ploidy_chrom[[clone]]
        ploidy_allele <- initial_ploidy_allele[[clone]]
        ploidy_block <- initial_ploidy_block[[clone]]
        driver_count <- initial_driver_count[clone]
        driver_map <- initial_driver_map[[clone]]
        selection_rate <- SIMULATOR_FULL_PHASE_1_selection_rate(driver_count, driver_map, ploidy_chrom, ploidy_block, ploidy_allele)
        initial_selection_rate[clone] <<- selection_rate
    }
    #---Set up total population dynamics as function of age (in days)
    for (i in 1:ncol(TABLE_POPULATION_DYNAMICS)) {
        assign(colnames(TABLE_POPULATION_DYNAMICS)[i], TABLE_POPULATION_DYNAMICS[, i], envir = .GlobalEnv)
    }
    vec_age_in_days <- Age_in_day
    vec_total_cell_count <- Total_cell_count
    linear_app_fun <<- approxfun(c(T_start_time - 300, vec_age_in_days, T_end_time + 300), c(vec_total_cell_count[1], vec_total_cell_count, tail(vec_total_cell_count, 1)), method = "linear")
    func_expected_population <<- function(time) linear_app_fun(time)
    #---Set up event rate as function of time (in days)
    func_event_rate <<- function(time) 1 / cell_lifespan
}
