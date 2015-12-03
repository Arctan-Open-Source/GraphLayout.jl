module GraphLayout

    __precompile__(true)

    if VERSION < v"0.4.0"
        using Docile
    end
    using Requires  # to optionally load JuMP
    using Compose  # for plotting features
    using Graphs  # for Graph interface

    # Graph interface functions to make AdjList behave as graph objects
    # allows backward compatibility if required
    include("AdjList.jl")

    # Spring-based force layout algorithms
    export layout_spring_adj
    include("spring.jl")

    # Stress majorization layout algorithms
    export layout_stressmajorize_adj
    include("stress.jl")

    # Tree layout algorithms
    export layout_tree
    include("tree.jl")
    # Optimization algorithm for tree layout
    include("tree_opt.jl")
    # Heuristic algortihms for tree layout
    include("tree_heur.jl")
    # Optimal algorithms for tree layout, that require JuMP
    # JuMP will only be loaded if these methods are requested
    #@require JuMP include(joinpath(Pkg.dir("GraphLayout","src","tree_opt.jl")))
    include("tree_opt.jl")

    # Drawing utilities
    export draw_layout_adj
    include("draw.jl")
end
