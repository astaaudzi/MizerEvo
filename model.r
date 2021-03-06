# this file is here to run the model composed of different functions

# I have to pass all the parameters here to be able to build mutants again
myModel <- function(no_sp = 10, # number of species #param described in Andersen & Pedersen 2010
                    min_w_inf = 10, # minimum weight of sp
                    max_w_inf = 1e5, # maximum weight of sp
                    no_w = 100, # number of size bins community spectrum
                    min_w = 0.001, #min size bin of community spectrum/The smallest size of the species community size spectrum
                    max_w = max_w_inf * 1.1, #max size bin of both spectrum
                    min_w_pp = 1e-10, #min size bin of background size spectrum
                    no_w_pp = round(no_w)*0.3, # number of size bins background spectrum
                    w_pp_cutoff = 0.5, # cut of size of the background spectrum
                    k0 = 50, # recruitment adjustment parameter
                    n = 0.75, # exponent of maximum intake (scaling of intake)
                    p = 0.75, # exponent of standard metabolism
                    q = 0.8, # exponent of search volume
                    eta = 0.25, # size at maturation relative to Mg (mass in grams ?)
                    r_pp = 4, # growth rate of resource spectrum (primary production)
                    kappa = 0.05, # ressource spectrum carrying capacity
                    lambda = 2+q-n, # exponent of the background spectrum.
                    alpha = 0.6, # assimilation efficiency
                    ks = 2, # factor for standard metabolism
                    z0pre = 0.84, # background mortality factor
                    h = 95, # factor of maximum intake
                    beta = 100, # preferred predator-prey weight ratio
                    sigma = 1.3, # width of selection function
                    f0 = 0.6, # average feeding level of the community/feeding level of small individuals feeding on background
                    knife_edge_size = 1000, #knife edge position
                    gear_names = "knife_edge_gear",
                    t_max = 100,
                    dt = 0.1,
                    mu = 5,
                    data = FALSE, # this condition to choose between retruning the normal run or other type of data in case I'm exploring stuff, no mutants allowed for now
                    extinct = TRUE, # extinction option
                    RMAX = TRUE, # enable egg density dependence
                    rm = NULL, # set up rmax by user
                    OptMutant = "M2", # mutation depends on number of eggs or not?
                    Traits = TRUE, # False if one trait only mute per new ecotype
                    r_mult = 1e0, #rmax multiplier to try things
                    cannibalism = 1, # to tweak cannibalism in the interaction matrix
                    erepro = 0.1, # reproduction efficiency
                    hartvig = F, # old set of parameters
                    no_run = 1, # number of sim in a row to do
                    effort = 0,
                    initCondition = NULL, # if I want to input previous mizer object as initial condition
                    initTime = 50, # time for initialisation
                    param = NULL, # can input a param data.frame to do multispecies model
                    print_it = T, # if you want to display messages or not
                    normalFeeding = T, #if want to normalised feeding kernel
                    mAmplitude = 0.05, # width of distribution of new trait value
                    save_it = F, # do you want to save?
                    path_to_save = NULL, # where?
                    predMort = NULL, # if want to replace dynamics m2 by constant one
                    ...){
  if (hartvig==TRUE)
  {
    h = 85
    w_pp_cutoff = 1e3
    #kappa = 5e-3
    ks = 10
    sigma = 1
  }
  if (is.null(initCondition) == TRUE)
  {
    firstRun = 1
    s_max = no_run * t_max / dt
    # I'm deleting all the default from this function so it uses only the ones in myModel
    if (is.null(param))
      param <- set_TBM(no_sp = no_sp, 
                       min_w_inf = min_w_inf, 
                       max_w_inf = max_w_inf,
                       no_w = no_w, 
                       min_w = min_w, 
                       max_w = max_w,
                       min_w_pp = min_w_pp, 
                       no_w_pp = no_w_pp, 
                       w_pp_cutoff = w_pp_cutoff,
                       k0 = k0, 
                       n = n, 
                       p = p, 
                       q = q,
                       eta = eta, 
                       r_pp = r_pp, 
                       kappa = kappa,
                       lambda = lambda, 
                       alpha = alpha, 
                       ks = ks, 
                       z0pre = z0pre, 
                       h = h, 
                       beta = beta, 
                       sigma = sigma, 
                       f0 = f0, 
                       knife_edge_size = knife_edge_size,
                       gear_names = gear_names,
                       r_mult = r_mult,
                       cannibalism = cannibalism,
                       erepro = erepro,
                       s_max = s_max,
                       rm = rm,
                       normalFeeding = normalFeeding) 
    
    
    # Initialisation ---------------------
    # Mutant option
    M3List <- list() # So I'm creating this list to store parameters from user input and only have one thing to pass between functions
    if (OptMutant == "M3") # means that we need to know when user want mutation to appear
    {
      prompt <- "At what time do you want the mutation to occur?\n"
      M3List[[1]] <- as.integer(strsplit(readline(prompt), " ")[[1]])
      if (length(M3List[[1]]) == 0 )M3List[[1]] = 0
    }
    
    # Kick start the abundance
    if (print_it) cat(sprintf("Initialisation of the simulation, please wait.\n"))
    initBio <- project(param, t_max = initTime, extinct = FALSE, OptMutant="yo", RMAX = RMAX) # init abundance
    n_init <- initBio@n[dim(initBio@n)[1],,]
    n_pp_init <- initBio@n_pp[dim(initBio@n_pp)[1],]
    if (print_it) cat(sprintf("Initialisation completed, starting simulation.\n"))
    nameList = initBio@params@species_params$ecotype
  }
  
  else 
  {
    Nparam = initCondition@params@species_params[initCondition@params@species_params$extinct == F,] # take the sp not extinct to start the sim
    #Nparam$pop = 0
    #Nparam$timeMax = Nparam$timeMax + no_run * t_max / dt # update the time max of the sim, ///additon of time or
    Nparam$timeMax = no_run * t_max / dt # update the time max of the sim /// start from beginning
    #print(Nparam)
    param <- MizerParams(Nparam, min_w = min_w, max_w=max_w, no_w = no_w, min_w_pp = min_w_pp, w_pp_cutoff = w_pp_cutoff, n = n, p=p, q=q, r_pp=r_pp, kappa=kappa, lambda = lambda, normalFeeding = normalFeeding)
    spIndex = as.character(Nparam$ecotype)
    #print(spIndex)
    initCondition@n = initCondition@n[,spIndex,] # take the abundance of only the present species
    n_init = initCondition@n[dim(initCondition@n)[1],,] # take last time step of the abundance to make it first time step
    n_pp_init = initCondition@n_pp[dim(initCondition@n_pp)[1],] # same for plankton
    if (print_it) cat(sprintf("Starting simulation with previous run.\n"))
    no_run = no_run + max(Nparam$run) # update number of runs
    firstRun = max(Nparam$run) +1 # state at which run we're starting
    nameList = initCondition@params@species_params$ecotype # this list keep in memory all the species name (as I lose some in my ecotypes by getting rid of the extinct/ use to give ecotypes namee)
  }
  oneSpMode = F
  if (no_sp == 1)
  {
    oneSpMode = T
    cat(sprintf("Simulation in mode: one species only\n"))
  }
  
  #Multiple run --------------------------------
  allRun <- list() # save all the runs
  
  for(j in firstRun:no_run){
    # to keep a semblance of identity in my data, I am ordering everything by appartition order. To keep that even if I stop and re initialise the sim, I need to change the run number
    # it means that if I do a sim after another one, the first run wont be one but the previous number of run + one
    if (print_it) cat(sprintf("run = %s\n",j))
    # First run without mutants
    
    sim <- project(param, t_max = t_max, dt =dt, mu = mu, initial_n = n_init, initial_n_pp=n_pp_init, data = data, extinct = extinct, RMAX=RMAX, OptMutant=OptMutant, M3List = M3List, checkpoint = j, effort = effort, print_it = print_it, predMort = predMort) # init first step
    
    
    # Post initialisation -------------------
    if (data==FALSE){ #this thing is here in the case in the case I don't want the normal sim but other stuff
      
      allData <- list() # this list will save the data output of all the projections
      counter = 1 # used to increment the list (I guess there is a better way to do that)
      
      while (length(sim) > 3 ) # ugly but if everything is done, length(sim) = 1, if sim dead, length =2, if a mutant appear, length = 5( sim,time,resident, n , npp)
      {
        #print("start")
        n_init = sim$n # last time abundance, that will be modified and use as initiation for next projection
        
        # SAVE THE DATA FROM PREVIOUS PROJECTION
        allData[[counter]] <- sim$data
        counter = counter +1
        
        # CREATE MUTANTS
        for (i in 1: length(sim$resident))
        {
          #print("create mutant")
          # resident = sim$resident[i] # this is the rowname of the resident
          
          # resident_params <- sim$data@params@species_params[noResident,] #get the params of the resident
          
          resident = sim$resident[i] # this is the ecotype
          
          resident_params = sim$data@params@species_params[sim$data@params@species_params$ecotype == resident,]
          
          #noResident <- rownames(sim$data@param@species_params[sim$data@param@species_params$ecotype == resident,]) # this is the rownumber of the resident
          
          mutant <- resident_params # create a perfect copy
          mutant$pop = sim$i_stop + (j-1)*t_max/dt
          mutant$run = j
          # while (mutant$ecotype %in% sim$data@params@species_params$ecotype) mutant$ecotype = as.numeric(mutant$ecotype) + 1
          #special case if only one species as I reach easly the limit of 16 digits names
          # if (oneSpMode)
          # {
            mutant$ecotype =  as.numeric(unlist(strsplit(as.character(resident), "")))[1]
            while (mutant$ecotype %in% nameList) mutant$ecotype = as.numeric(paste(as.numeric(unlist(strsplit(as.character(resident), "")))[1],sample(seq(1:1e5),1),sep=""))
          # } else {
          #   mutant$ecotype =  as.numeric(paste(c(resident, 1), collapse = ""))
          #   while (mutant$ecotype %in% nameList) mutant$ecotype = as.numeric(mutant$ecotype) + 1
          #   nameList = c(nameList,mutant$ecotype)
          # }
          
          # TRAITS
          switch(Traits,
                 size = {
                   # Trait = asymptotic size
                   sd = as.numeric(mAmplitude *  resident_params["w_inf"]) # standard deviation
                   mutant["w_inf"] <- resident_params["w_inf"] + rnorm(1, 0, sd) # change a bit the asymptotic size
                   mutant["w_mat"] <- mutant["w_inf"] * eta # calculate from the new w_inf value
                   mutant["z0"] <- z0pre * as.numeric(mutant["w_inf"]) ^ (n - 1) # if I don't put as.numeric I lose the name z0
                   #cat(sprintf("Its size mutes slightly.\n"))
                 },
                 beta = {
                   # Trait = PPMR
                   sd = as.numeric(mAmplitude *  resident_params["beta"]) # standard deviation
                   mutant["beta"] <- resident_params["beta"] + rnorm(1, 0, sd) # change a bit the PPMR
                   # calculate the new gamma
                   alpha_e <- sqrt(2 * pi) * mutant$sigma * mutant$beta ^ (lambda - 2) * exp((lambda - 2) ^ 2 * mutant$sigma ^ 2 / 2)
                   mutant["gamma"] <- h * f0 / (alpha_e * kappa * (1 - f0))
                   #cat(sprintf("Its PPMR mutes slightly.\n"))
                 },
                 sigma = {
                   # Trait = fedding kernel
                   sd = as.numeric(mAmplitude *  resident_params["sigma"]) # standard deviation
                   mutant["sigma"] <- resident_params["sigma"] + rnorm(1, 0, sd) # change a bit the diet breadth
                   # calculate the new gamma
                   alpha_e <- sqrt(2 * pi) * mutant$sigma * mutant$beta ^ (lambda - 2) * exp((lambda - 2) ^ 2 * mutant$sigma ^ 2 / 2)
                   mutant["gamma"] <- h * f0 / (alpha_e * kappa * (1 - f0))
                   #cat(sprintf("Its diet breadth mutes slightly.\n"))
                 },
                 eta = {
                   # Trait = eta
                   sd = as.numeric(mAmplitude *  resident_params["eta"]) # standard deviation
                   mutant["eta"] <- resident_params["eta"] + rnorm(1, 0, sd) # change a bit eta
                   mutant["w_mat"] <- mutant["w_inf"] * mutant["eta"] # update
                   #cat(sprintf("Its winf/wmat ratio mutes slightly.\n"))
                 },
                 all = {
                   # Trait = asymptotic size
                   sd = as.numeric(mAmplitude *  resident_params["w_inf"]) # standard deviation
                   mutant["w_inf"] <- resident_params["w_inf"] + rnorm(1, 0, sd) # change a bit the asymptotic size
                   mutant["w_mat"] <- mutant["w_inf"] * eta # calculate from the new w_inf value
                   mutant["z0"] <- z0pre * as.numeric(mutant["w_inf"]) ^ (n - 1) # if I don't put as.numeric I lose the name z0
                   # Traits = predation
                   sd = as.numeric(mAmplitude *  resident_params["beta"]) # standard deviation
                   mutant["beta"] <- resident_params["beta"] + rnorm(1, 0, sd) # change a bit the PPMR
                   sd = as.numeric(mAmplitude *  resident_params["sigma"]) # standard deviation
                   mutant["sigma"] <- resident_params["sigma"] + rnorm(1, 0, sd) # change a bit the diet breadth
                   # calculate the new gamma
                   alpha_e <- sqrt(2 * pi) * mutant$sigma * mutant$beta ^ (lambda - 2) * exp((lambda - 2) ^ 2 * mutant$sigma ^ 2 / 2)
                   mutant["gamma"] <- h * f0 / (alpha_e * kappa * (1 - f0))
                   #cat(sprintf("Its traits mute slightly.\n"))
                 },
                 {
                   print("congrats, you managed to fuck up somewhere")
                 })
          
          
          #print("naming")
          # I need to specify the name myself as the dataframe way is not consistant and subject to errors. It will work as long as a parent has less than 10 mutants
          rownames(mutant) = mutant$ecotype
          # while (rownames(mutant) %in% rownames(sim$data@params@species_params)) rownames(mutant) = as.numeric(rownames(mutant)) + 1
          
          sim$data@params@species_params <- rbind(sim$data@params@species_params, mutant) #include the mutant in the dataframe
          
          #need to update some suff now that there is one more sp
          no_sp = no_sp + 1
          w_inf <- as.numeric(unlist(sim$data@params@species_params["w_inf"])) # need to recreate the vector
          #transform(trait_params_df_test, w_inf = as.numeric (w_inf))
          w_mat <-  as.numeric(unlist(sim$data@params@species_params["w_mat"]))
          
          # so ... I will recreate the "param" object needed for the projection from here
          #print("reboot df param")
          trait_params <- MizerParams(sim$data@params@species_params, min_w = min_w, max_w=max_w, no_w = no_w, min_w_pp = min_w_pp, w_pp_cutoff = w_pp_cutoff, n = n, p=p, q=q, r_pp=r_pp, kappa=kappa, lambda = lambda, normalFeeding = normalFeeding)
          
          # # this piece of code is from TBM1 to calculate r_max. I don't want to update it however so fuck it 
          # # warning, beta is not updated here but it's for the calcul of Rmax so osef
          # alpha_p <- f0 * h * beta^(2 * n - q - 1) * exp((2 * n * (q - 1) - q^2 + 1) * sigma^2 / 2)
          # alpha_rec <- alpha_p / (alpha * h * f0 - ks)
          # # Calculating dw using Ken's code - see Ken's email 12/08/13
          # tmpA <- w_inf[1]
          # tmpB <- (log10(w_inf[length(w_inf)]) - log10(w_inf[1])) / (no_sp - 1) # Difference between logged w_infs, fine
          # dw_winf <- tmpB * tmpA *10^(tmpB*((1:no_sp)-1)) # ?
          # N0_max <- k0 * w_inf^(n*2-q-3+alpha_rec) * dw_winf  # Why * dw_winf, not / ? Ken confirms * in email
          # # No need to include (1 - psi) in growth equation because allocation to reproduction at this size = 0, so 1 - psi = 1
          # g0 <- (alpha * f0 * h * trait_params@w[1]^n - ks * trait_params@w[1]^p)
          # r_max <- N0_max * g0
          #trait_params@species_params$r_max <- r_max
          
          
          
          
          
          
          
          # SEND SOME INTITIAL CONDITIONS
          # what is the first dim of sim[[2]]@n ? (time step) aaargh the object is build of the "right" dimension in projection so it's just square of 0.
          # re-aaaargh, is there a save for n at each time step? probably not
          
          # start a new projection but with the old data
          # my initial condition are in 
          
          
          
          # I need to add one row for the mutant!
          # initialisation of the mutant, what assumptions do I take? only eggs?
          # add a new row and then sort ascendant order by sp
          # add only eggs depending on the egg output of the resident or same for every sp?
          # I could add just a few eggs and let stocasticity happens, but I need to input a biomass limit for extinction
          # I can use Hartvig data for that: n <10 ^-30 g/m3 to be eliminated
          
          #print("initialisation abundance")
          n_mutant <- rep(0,no_w)
          
          # abundance of the mutant
          
          #n_mutant = 0.05 * sim$data@n[sim$i_stop,dimnames(sim[[1]]@n)$sp ==resident,] # the initial abundance is 5% of the resident pop
          n_mutant = 0.05 * n_init[dimnames(sim[[1]]@n)$sp ==resident,]
          n_init[dimnames(sim[[1]]@n)$sp ==resident,]= n_init[dimnames(sim[[1]]@n)$sp ==resident,] - 0.05*n_init[dimnames(sim[[1]]@n)$sp ==resident,] # Witdraw the abundance of the mutant from its parent (we're not talking about eggs here but different ecotype already present)
          n_init <- rbind(n_init,n_mutant) # this include the new mutant as last column
          rownames(n_init)[length(rownames(n_init))] <- rownames(mutant) # update the name of the mutant accordingly
        }
        
        # in the case of constant predation mortality
        if (!is.null(predMort)){
          predMort = matrix(data = predMort[1,], nrow = no_sp, ncol = dim(predMort)[2],byrow = T)
          #rownames(predMort) = "prey"
        }
        
        # print("end")
        sim <- project(trait_params, t_max = t_max, dt = dt, i_stop = sim$i_stop, initial_n = n_init, initial_n_pp=sim$n_pp, mu = mu, data = data, extinct = extinct, RMAX=RMAX,OptMutant=OptMutant, M3List = M3List,checkpoint = j, effort = effort, print_it = print_it, predMort = predMort ) # add something in the function to give new init param
      }
      allData[[counter]] <- sim # one last time for the last projection
      
      # if simulation went extinct
      if (length(sim) == 2) 
      {
        for (i in 1:(length(allData)-1)) # change the time max of the sim as it's shorter now
        {
          allData[[i]]@params@species_params$timeMax = length(sim[[1]])*t_max/dt
        }
        #allData[[length(allData)]] = NULL # delete the last half run
        return(allData)
      }
      # now allData has all the successive runs, lets stitch them
      biomass <- stitch(allData) # biomass is a list of n and n_pp
      
      sim@n = biomass[[1]]
      sim@n_pp = biomass[[2]]
      
      # now I want to do more run with as initial conditions, the final step of the previous run
      # but first I need to save it
      allRun[[j]] <- sim
      
      # then let's clean the sim of the extinct species and initialse next sim
      Nparam = sim@params@species_params[sim@params@species_params$extinct == F,]
      param <- MizerParams(Nparam, min_w = min_w, max_w=max_w, no_w = no_w, min_w_pp = min_w_pp, w_pp_cutoff = w_pp_cutoff, n = n, p=p, q=q, r_pp=r_pp, kappa=kappa, lambda = lambda, normalFeeding = normalFeeding)
      spIndex = as.character(Nparam$ecotype)
      n_init = sim@n[dim(sim@n)[1],spIndex,]
      n_pp_init = sim@n_pp[dim(sim@n)[1],]
      
      #cat(sprintf("run %s done\n",j))
      
    }
    
    else allRun = sim
  }
  # final param counting the extinct species
  
  if (data==FALSE)
  {
    #for (i in firstRun:length(allRun) ) allRun[[i]]@params@species_params[ , "ecotype"] <- rownames(allRun[[i]]@params@species_params) # save the ecotype (which is the row number)
    a = NULL
    for (i in firstRun:length(allRun) ) a = rbind(a,allRun[[i]]@params@species_params) # bind the different dataframes
    a <- a[order(a$ecotype, a$extinct, decreasing=TRUE),] # weird 3 lines to get rid of duplicates and keep the ones with the extinction value
    a <- a[!duplicated(a$ecotype),]
    SummaryParams = a[order(a$pop,a$ecotype),]
    
    # Update all the other param from the dataframe
    FinalParam <- MizerParams(SummaryParams, min_w = min_w, max_w=max_w, no_w = no_w, min_w_pp = min_w_pp, w_pp_cutoff = w_pp_cutoff, n = n, p=p, q=q, r_pp=r_pp, kappa=kappa, lambda = lambda, normalFeeding = normalFeeding)
    
    #return(list(allRun,FinalParam))
    
    # handle and save the final data
    sim = finalTouch(list(allRun,FinalParam))
    gc()
    simOpt = superOpt(sim) 
    
    if (save_it)
    {
      if (is.null(path_to_save)) path_to_save = paste(getwd(),"/temporary",sep="")
      ifelse(!dir.exists(file.path(path_to_save)), dir.create(file.path(path_to_save),recursive = T), FALSE) #create the file if it does not exists
      save(simOpt,file = paste(path_to_save,"/run.Rdata",sep="")) #save it
    }
    
    return(simOpt)
  }
  else return(allRun)
}
