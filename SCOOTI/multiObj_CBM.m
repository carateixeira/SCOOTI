function multiObj_CBM(jj, COBRA_path, GEM_path, model_name, obj_candidate_list_file, input_obj_tb, paraLen, random_para, init_objective, genekoflag, rxnkoflag, FVAflag, pfba, medium_perturbation, data_dir, prefix_name, medium, labe_stage, early_stage, simulation, constraint, save_root_path)

%% Part 1: metabolic model
  % initialize COBRA toolbox
  addpath(COBRA_path)
  run initCobraToolbox(false)
  % INPUT files
  % Load metabolic network model
  model = load(model_path);
  fn = fieldnames(model);
  model = getfield(model, fn{1});
  % objective candidates
  obj_candidate_list_file = '';

% Part 2: Input data
  % random sampling
  reind = randsample(paraLen*paraLen, paraLen);
  input_data_choose = 'model'

  % additional input for objectives and corresponding weights
  if strcmp(input_obj_tb, ''),
    input_obj_file = './tutorial/regression_models/scEmbryo/flux_sl_sc2CBC_input_norm_outcome_nonorm_k0.1_r0.01.csv';
    input_objective_weights = 0; % set to 1 if giving existing objective weights
  else,
    input_obj_file = input_obj_tb;
    input_objective_weights = 1;
  end
  
  % read coefficients for objectives
  input_obj_tb = readtable();

  %cols = input_obj_tb.Properties.VariableNames
  [data_series, prefix_name, prefix_series, root_path, late_stage, early_stage, simulation, ctrl, medium_series, prefix_pattern_func] = CBM_dataInput(input_data_choose, data_dir, prefix_name, medium)


%% Part 3: Parameter settings for CBM
  
  if strcmp(simulation, 'DFA')==1, % optimize reactions/new demand reactions
%% settings for parameter space for DFA kappa
    DFA_para_space = logspace(1, -3, paraLen);
    disp('Parameter settings for DFA...')
    if random_para==1,
      DFA_para_space = logspace(1, -3, paraLen*paraLen);
      DFA_para_space = DFA_para_space(reind);
    end
    kappa = DFA_para_space(jj)
    rho = 0; % for bugs in DFA (unnecessary parameter)
  else, % CFR or model
%% settings for parameter space of CFR kappa and rho
    CFR_para_space = logspace(1, -3, paraLen);
    [Y, Z] = meshgrid(CFR_para_space, CFR_para_space);
    CFR_para_pack = [Y(:), Z(:)];
    disp('Parameter settings for CFR...')
    if random_para==1,
      CFR_para_pack = CFR_para_pack(reind, :);
    end
    kappa = 1%CFR_para_pack(jj, 1)%1E-1 1E0 [10, 1, 0.1, 0.01, 0.001]
    rho = 1%CFR_para_pack(jj, 2)%1E0 1E-2 linspace(0, 100, 100)
    
    %if input_objective_weights==1,
    %  for coli=2:length(input_obj_tb.Properties.VariableNames),
    %    input_obj_tb.Properties.VariableNames{coli} = sprintf('%s_', input_obj_tb.Properties.VariableNames{coli});
    %  end
    %  paraComb = sprintf('k%g_r%g_', kappa, rho);
    %  paraComb = strrep(paraComb, '.', '_');
    %  input_obj_tb = input_obj_tb(:, [logical(1) contains(input_obj_tb.Properties.VariableNames(2:end), paraComb)]);
    %end
  end

%% Part4: Iterate through all different input datasets
  % setups for parallel computing
  delete(gcp('nocreate'));
  parpool(32);
  %disp(length(data_series))
%% Parfor...
  parfor data_index=1:length(data_series),
  %for data_index=1:length(data_series),
    %data_index = 1;
    size(data_series)
    size(medium_series)
    data_path = data_series{data_index}
    disp('Read file...')
    disp(data_path)
    % info of the data/simulation
    prefix = prefix_series{data_index}
    % get cell-specific objective with corresponding cell names
    if input_objective_weights & strcmp(input_data_choose, 'model')==0,
      prefix_str = prefix_pattern_func(prefix);
      input_obj_tb_ind = find([logical(1) contains(input_obj_tb.Properties.VariableNames(2:end), prefix_str)]);
    end
    % change culture medium KSOM_AA_Jin or DMEMF12_MGSA
    medium = medium_series{data_index};
    
    % parameters
    if strcmp(obj_candidate_list_file, ''),
      if strcmp(model_name, 'Recon3D'),
        % candidate objectives for Recon3D
        single_obj =  {'';'gh';'atp';'nadh';'nadph';'amet';'gthox';'gthrd';'nmn';'accoa';'ala__L';'amp';'arg__L';'asn__L';'asp__L';'chsterol';'clpn_hs';'cmp';'cys__L';'dag_hs';'damp';'dcmp';'dgmp';'dtmp';'gln__L';'glu__L';'gly';'glygn1';'gmp';'h2o';'his__L';'ile__L';'leu__L';'lpchol_hs';'lys__L';'mag_hs';'met__L';'pa_hs';'pail_hs';'pchol_hs';'pe_hs';'phe__L';'pro__L';'ps_hs';'ser__L';'sphmyln_hs';'tag_hs';'thr__L';'trp__L';'tyr__L';'ump';'val__L';'xolest_hs'};
      elseif strcmp(model_name, 'Recon2.2'),
        single_obj =  {'';'gh';'atp';'nadh';'nadph';'amet';'gthox';'gthrd';'nmn';'accoa';'ala_L';'amp';'arg_L';'asn_L';'asp_L';'chsterol';'clpn_hs';'cmp';'cys_L';'dag_hs';'damp';'dcmp';'dgmp';'dtmp';'gln_L';'glu_L';'gly';'glygn1';'gmp';'h2o';'his_L';'ile_L';'leu_L';'lpchol_hs';'lys_L';'mag_hs';'met_L';'pa_hs';'pail_hs';'pchol_hs';'pe_hs';'phe_L';'pro_L';'ps_hs';'ser_L';'sphmyln_hs';'tag_hs';'thr_L';'trp_L';'tyr_L';'ump';'val_L';'xolest_hs'};
      else,
      % manually curated objectives
      % candidate objectives for Recon1/Shen2019 model
        single_obj =  {'';'gh';'atp';'nadh';'nadph';'amet';'gthox';'gthrd';'nmn';'accoa';'ala-L';'amp';'arg-L';'asn-L';'asp-L';'chsterol';'clpn_hs';'cmp';'cys-L';'dag_hs';'damp';'dcmp';'dgmp';'dtmp';'gln-L';'glu-L';'gly';'glygn1';'gmp';'h2o';'his-L';'ile-L';'leu-L';'lpchol_hs';'lys-L';'mag_hs';'met-L';'pa_hs';'pail_hs';'pchol_hs';'pe_hs';'phe-L';'pro-L';'ps_hs';'ser-L';'sphmyln_hs';'tag_hs';'thr-L';'trp-L';'tyr-L';'ump';'val-L';'xolest_hs'};
      end
    else,
      % get single objectives from files
      single_obj = {};
      single_obj{1, 1} = '';
      candidates = readtable(obj_candidate_list_file);
      candidate_size = size(candidates);
      for i=1:candidate_size,
        single_obj(i+1, 1) = candidates{i, 2};
      end
    end
    
    % objective weights for single objectives
    para_pack = eye(length(single_obj));
   
%% CFR simulations with different objective weights
    % parallel computing settings
    %init_for = 1;
    disp('input_obj_check')
    disp(input_objective_weights)
    if input_objective_weights==0, % single objective
      init_for = init_objective;
      if strcmp(input_data_choose, 'model')==1, % iterate thru all obj
        end_for = length(single_obj);
      else, % without obj for constraint models
        end_for = init_for;%length(single_obj);%1
      end
    elseif strcmp(input_data_choose, 'model')==1,
      % use new objectives without constraint
      init_for = 2;
      ss = size(input_obj_tb)
      end_for = ss(2);
    else,
      % use new objective WITH constraint
      init_for = 2;%init_for;
      ss = size(input_obj_tb(1:end, input_obj_tb_ind))
      end_for = ss(2);
    end
    %delete(gcp('nocreate'))
    %parpool(32);
    for ii=init_for:end_for,
    %parfor ii=init_for:end_for,

      % use single objective functions
      if input_objective_weights==0,
        % for single objective
        obj = single_obj; % comment out this one if you to model
        % objective weights
        disp('Weights for objectives:')
        obj_c = [];
        for d=1:length(obj),
          obj_c = [obj_c, para_pack(ii, d)];
        end

      % use multiobjective functions from files without constraint
      elseif strcmp(input_data_choose, 'model')==1,
        
        obj = input_obj_tb{2:ss(1), 1};
        obj_c = input_obj_tb{2:ss(1), ii}; 
        get_late_stage = input_obj_tb.Properties.VariableNames{ii};

      % use multiobjective function from files WITH corresponding constraint
      else,
        %cols = input_obj_tb.Properties.VariableNames

        %for kk=1:length(cols),
        %    cols{kk} = regexprep(cols{kk}, '[^a-zA-Z0-9\s]', '')
        %end
        %disp(prefix_name)
        %split_term = sprintf('%s_', prefix_name);
        %celltype = strsplit(prefix, split_term);
        %tmp = celltype;
        %disp(split_term)
        %disp(celltype)
        %celltype = regexprep(celltype{2}, '[^a-zA-Z0-9\s]', '');
        %matched = find(strcmp(cols, celltype))
        
        obj = input_obj_tb{2:ss(1), 1}
        obj_c = input_obj_tb{2:ss(1), ii}
        get_late_stage = late_stage

      end
      % DO NOT CHANGE ANYTHING BELOW
      % Running exps for all conditions
      disp('Optimizing the demand reaction:')
      disp(obj)
      if strcmp(obj, ''),
          obj_type = '';
      else,
          obj_type = 'Demand';
      end
      
      
      %%%%%%%%%%%%%%%%%%
      % start simulation
      %%%%%%%%%%%%%%%%%%
      % later stages
      
      % filename logics: 
      % 1: '[datetime]Project_simulation_fluxes.csv'
      % 2: '[datetime]Project_simulation_metadata.json'
      % 3: Other outputs
      out_name = sprintf('%s_ct%d_obj%d_data%d', simulation, jj, ii, data_index)
      disp('Results will be saved in:')
      disp(out_name)
      
      if strcmp(simulation, 'DFA')==1, 
        disp('DFA...')
        %rho = 0
        % change culture medium KSOM_AA_Jin or DMEMF12_MGSA
        DFAinterface(model_path, obj, obj_type, obj_c, root_path, data_path, prefix, early_stage, late_stage, out_name, ctrl, kappa, genekoflag, rxnkoflag, medium, media_perturbation, FVAflag, model_name);
      else,
      %simulation=='CFR' | simulation=='model',
        % CFR with fluxes
        if input_objective_weights==0,
          CFRinterface(model_path, pfba, obj, obj_type, obj_c, root_path, data_path, out_name, late_stage, early_stage, ctrl, kappa, rho, medium, genekoflag, rxnkoflag, media_perturbation, FVAflag, model_name);
        else,
          CFRinterface(model_path, pfba, obj, obj_type, obj_c, root_path, data_path, out_name, get_late_stage, early_stage, ctrl, kappa, rho, medium, genekoflag, rxnkoflag, media_perturbation, FVAflag, model_name);
        end
        % % earlier stages
        %out_name = sprintf('Jin_%s_%d', simulation, ii);
        %disp('Results will be saved in:')
        %disp(out_name)
        % % CFR with fluxes
        % CFRinterface(model_path, obj, obj_type, obj_c, data_path, out_name, early_stage, late_stage, ctrl, kappa, rho, medium, genekoflag, rxnkoflag, media_perturbation);
      end

    end
  end





