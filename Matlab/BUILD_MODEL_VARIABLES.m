clear;
%=======================ADD PATH FOR MODEL VARIABLE FILES FROM VIGNETTES
    current_folder  = pwd;
    idcs            = strfind(current_folder,'/');
    mother_folder   = current_folder(1:idcs(end)-1);
    R_folder        = [mother_folder '/vignettes'];
    path(path,R_folder);
%==========================PREPARE PATH FOR THE NEW MODEL VARIABLE FILES
    path_new        = [mother_folder '/vignettes/'];
    model_new       = 'MIXTURE-A';





%=======================================PREPARE NEW MODEL VARIABLE FILES
%===Input model variables from old model
%   Input model variable file - variables
    model_old                                       = 'HGSOC-BULK';
    filename                                        = [path_new model_old '-input-variables.csv'];
    TABLE_INPUT_VARIABLES                           = readtable(filename,'Delimiter',',');
%   Input model variable file - total population dynamics
    filename                                        = [path_new model_old '-input-population-dynamics.csv'];
    TABLE_INPUT_POPULATION_DYNAMICS                 = readtable(filename,'Delimiter',',');
%   Input model variable file - chromosome bin counts and centromere locations
    filename                                        = [path_new model_old '-input-copy-number-blocks.csv'];
    TABLE_INPUT_CHROMOSOME_CN_INFO                  = readtable(filename,'Delimiter',',');
%   Input model variable file - mutational and CNA genes
    filename                                        = [path_new model_old '-input-cancer-genes.csv'];
    TABLE_INPUT_CANCER_GENES                        = readtable(filename,'Delimiter',',');
%===Make changes to model variables
%---Make changes to variables
    rate_driver                                     = 1e-16;

    prob_CN_whole_genome_duplication                = 1e-6;
    prob_CN_missegregation                          = 1e-6;
    prob_CN_chrom_arm_missegregation                = 1e-6;
    prob_CN_focal_amplification                     = 1e-6;
    prob_CN_focal_deletion                          = 1e-6;
    prob_CN_cnloh_interstitial                      = 1e-6;
    prob_CN_cnloh_terminal                          = 1e-6;

    prob_CN_focal_amplification_length              = 0.1;
    prob_CN_focal_deletion_length                   = 0.1;
    prob_CN_cnloh_interstitial_length               = 0.1;
    prob_CN_cnloh_terminal_length                   = 0.1;

    TABLE_INPUT_VARIABLES.Value(find(strcmp(TABLE_INPUT_VARIABLES.Variable,'rate_driver'))) = rate_driver;

    TABLE_INPUT_VARIABLES.Value(find(strcmp(TABLE_INPUT_VARIABLES.Variable,'prob_CN_whole_genome_duplication'))) = prob_CN_whole_genome_duplication;
    TABLE_INPUT_VARIABLES.Value(find(strcmp(TABLE_INPUT_VARIABLES.Variable,'prob_CN_missegregation'))) = prob_CN_missegregation;
    TABLE_INPUT_VARIABLES.Value(find(strcmp(TABLE_INPUT_VARIABLES.Variable,'prob_CN_chrom_arm_missegregation'))) = prob_CN_chrom_arm_missegregation;
    TABLE_INPUT_VARIABLES.Value(find(strcmp(TABLE_INPUT_VARIABLES.Variable,'prob_CN_focal_amplification'))) = prob_CN_focal_amplification;
    TABLE_INPUT_VARIABLES.Value(find(strcmp(TABLE_INPUT_VARIABLES.Variable,'prob_CN_focal_deletion'))) = prob_CN_focal_deletion;
    TABLE_INPUT_VARIABLES.Value(find(strcmp(TABLE_INPUT_VARIABLES.Variable,'prob_CN_cnloh_interstitial'))) = prob_CN_cnloh_interstitial;
    TABLE_INPUT_VARIABLES.Value(find(strcmp(TABLE_INPUT_VARIABLES.Variable,'prob_CN_cnloh_terminal'))) = prob_CN_cnloh_terminal;

    TABLE_INPUT_VARIABLES.Value(find(strcmp(TABLE_INPUT_VARIABLES.Variable,'prob_CN_focal_amplification_length'))) = prob_CN_focal_amplification_length;
    TABLE_INPUT_VARIABLES.Value(find(strcmp(TABLE_INPUT_VARIABLES.Variable,'prob_CN_focal_deletion_length'))) = prob_CN_focal_deletion_length;
    TABLE_INPUT_VARIABLES.Value(find(strcmp(TABLE_INPUT_VARIABLES.Variable,'prob_CN_cnloh_interstitial_length'))) = prob_CN_cnloh_interstitial_length;
    TABLE_INPUT_VARIABLES.Value(find(strcmp(TABLE_INPUT_VARIABLES.Variable,'prob_CN_cnloh_terminal_length'))) = prob_CN_cnloh_terminal_length;
%---Make changes to mutational and CNA genes
%   Set selection strengths for each driver class
    N_drivers                                       = size(TABLE_INPUT_CANCER_GENES,1);
    vec_unique_freq                                 = unique(TABLE_INPUT_CANCER_GENES.Affected_donor_count);
    vec_unique_selection_rates                      = [[0.01:0.02:0.17] 0.3];
    vec_selection_rates                             = zeros(1,N_drivers);
    for i=1:length(vec_unique_freq)
        freq                                        = vec_unique_freq(i);
        vec_loc                                     = find(TABLE_INPUT_CANCER_GENES.Affected_donor_count==freq);
        vec_selection_rates(vec_loc)                = vec_unique_selection_rates(i);
    end
%   Count the number of TSGs and ONCOGENEs
    count_TSG                                       = sum(count(TABLE_INPUT_CANCER_GENES.Gene_role,'TSG'));
    count_ONCOGENE                                  = sum(count(TABLE_INPUT_CANCER_GENES.Gene_role,'ONCOGENE'));
%   Compute selection rates for TSGs
    list_TSG                                        = find(strcmp(TABLE_INPUT_CANCER_GENES.Gene_role,'TSG'));
    s_normalization                                 = 1;
    for driver=1:length(list_TSG)
        row                                         = list_TSG(driver);
%       Get its selection strength
        driver_sel_rate                             = vec_selection_rates(row);
%       Compute its selection rate for WT and MUT alleles
        TABLE_INPUT_CANCER_GENES.s_rate_WT(row)     = 1/(1+driver_sel_rate);
        TABLE_INPUT_CANCER_GENES.s_rate_MUT(row)    = 1;
%       Update normalizer for selection rate
        s_normalization                             = s_normalization*(1+driver_sel_rate);
    end
%   Compute selection rates for ONCOGENEs
    s_normalization                                 = s_normalization^(1/count_ONCOGENE);
    list_ONCOGENE                                   = find(strcmp(TABLE_INPUT_CANCER_GENES.Gene_role,'ONCOGENE'));
    for driver=1:length(list_ONCOGENE)
        row                                         = list_ONCOGENE(driver);
%       Get its selection strength
        driver_sel_rate                             = vec_selection_rates(row);
%       Compute its selection rate for WT and MUT alleles
        TABLE_INPUT_CANCER_GENES.s_rate_WT(row)     = s_normalization;
        TABLE_INPUT_CANCER_GENES.s_rate_MUT(row)    = s_normalization*(1+driver_sel_rate);
    end
%===Create model variables for new model
%---Create model variables - initial copy number state
    vec_chrom                                       = [];
    vec_bin                                         = [];
    vec_cn_strand_1                                 = {};
    vec_cn_strand_2                                 = {};

vec_cn_strand_3={};

    for i=1:length(TABLE_INPUT_CHROMOSOME_CN_INFO.Chromosome)
        chrom                                       = TABLE_INPUT_CHROMOSOME_CN_INFO.Chromosome(i);
        bin_count                                   = TABLE_INPUT_CHROMOSOME_CN_INFO.Bin_count(i);
        for bin=1:bin_count
            vec_chrom(end+1)                        = chrom;
            vec_bin(end+1)                          = bin;
            vec_cn_strand_1{end+1}                  = 'A';
            vec_cn_strand_2{end+1}                  = 'B';

vec_cn_strand_3{end+1}='NA';

        end
    end
    % TABLE_INPUT_INITIAL_COPY_NUMBER_PROFILES        = table(vec_chrom',vec_bin',vec_cn_strand_1',vec_cn_strand_2','VariableNames',["Chromosome","Bin","Clone_1_strand_1","Clone_1_strand_2"]);

TABLE_INPUT_INITIAL_COPY_NUMBER_PROFILES        = table(vec_chrom',vec_bin',vec_cn_strand_1',vec_cn_strand_2',vec_cn_strand_3','VariableNames',["Chromosome","Bin","Clone_1_strand_1","Clone_1_strand_2","Clone_1_strand_3"]);
% TABLE_INPUT_INITIAL_COPY_NUMBER_PROFILES

%---Create model variables - initial state, other information
    vec_clone                                       = [1]
    vec_cell_count                                  = [1]
    vec_drivers                                     = ["TP53_strand1_unit1"];
    TABLE_INPUT_INITIAL_OTHERS                      = table(vec_clone',vec_cell_count',vec_drivers','VariableNames',["Clone","Cell_count","Drivers"]);
%===Output model variables for new model
%   Output model variable file - variables
    filename                                        = [path_new model_new '-input-variables.csv'];
    writetable(TABLE_INPUT_VARIABLES,filename);
%   Output model variable file - total population dynamics
    filename                                        = [path_new model_new '-input-population-dynamics.csv'];
    writetable(TABLE_INPUT_POPULATION_DYNAMICS,filename);
%   Output model variable file - chromosome bin counts and centromere locations
    filename                                        = [path_new model_new '-input-copy-number-blocks.csv'];
    writetable(TABLE_INPUT_CHROMOSOME_CN_INFO,filename);
%   Output model variable file - mutational and CNA genes
    filename                                        = [path_new model_new '-input-cancer-genes.csv'];
    writetable(TABLE_INPUT_CANCER_GENES,filename);
%   Output model variable file - initial copy number state
    filename                                        = [path_new model_new '-input-initial-cn-profiles.csv'];
    writetable(TABLE_INPUT_INITIAL_COPY_NUMBER_PROFILES,filename);
%   Output model variable file - initial state, other information
    filename                                        = [path_new model_new '-input-initial-others.csv'];
    writetable(TABLE_INPUT_INITIAL_OTHERS,filename);
