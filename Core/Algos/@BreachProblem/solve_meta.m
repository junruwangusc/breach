function res = solve_meta(this)

% display header
if ~strcmp(this.display,'off')
    fprintf('\nSTART OPTIMIZATION METAHEURISTICS\n');   
end

opt = this.solver_options;


if opt.num_corners>0
    if ~strcmp(this.display,'off')
        fprintf('\n     TEST CORNERS\n');
    end
    res= this.solve_corners();
    if ~strcmp(this.display,'off')&&~this.stopping()
        this.display_status();
        this.Display_Best_Results(res.f, res.x);
    end
end

while ~this.stopping()
    qr_step = opt.quasi_rand_seed;
    
    %% Quasi-random phase
    if ~strcmp(this.display,'off')
        fprintf('\nTEST QUASI-RANDOM SAMPLES\n');
    end

    this.setup_quasi_random('quasi_rand_seed',qr_step,'num_quasi_rand_samples',opt.num_quasi_rand_samples);
    res = this.solve_quasi_random();
    opt.quasi_rand_seed = opt.quasi_rand_seed+opt.num_quasi_rand_samples;  

    %% Next best man
    [~, admin_idx] = find(res.cval>=0);
    if ~isempty(admin_idx)
        [~, best_idx] = min(res.fval(admin_idx));
        x_best_phase = res.X0(:,admin_idx(best_idx)); % best x for next phase
        f_best_phase = res.fval(admin_idx(best_idx));
    end
    
    %% Disp
    if this.stopping()
        break;
    else
        if ~strcmp(this.display,'off')
            if ~isempty(admin_idx)
                fprintf('Best value found during quasi-random phase: %g with\n', f_best_phase);
                this.Display_X(x_best_phase);
            else
                fprintf('No admissible variable found during quasi-random phase. \n');
                f_best_phase = res.f;
                x_best_phase = res.x;
                fprintf('Best non admissible value found: %g with\n', f_best_phase);
                this.Display_X(x_best_phase);
            end
        end
    end
    
    if opt.local_max_obj_eval >0
        %% Local phase
        if ~strcmp(this.display,'off')
            fprintf('\nRUN LOCAL OPTIMIZATION\n');
        end
        
        res = run_nelder_mead(this,opt,x_best_phase);
        this.solver_options = opt;
        %% Disp
        if this.stopping()
            break;
        else
            if ~strcmp(this.display,'off')
                this.Display_Best_Results(res.fval, res.x);
            end
        end
    end
end

if ~strcmp(this.display,'off')
    fprintf('\nEND OPTIMIZATION METAHEURISTICS\n');
end

end

function res = run_nelder_mead(this, opt,  x0)

this.setup_nelder_mead(x0, 'MaxFunEvals', opt.local_max_obj_eval, 'Display', 'off');
res = this.solve_nelder_mead();

end


