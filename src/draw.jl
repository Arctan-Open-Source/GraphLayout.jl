using Compose
import Colors
typealias ComposeColor Union{Colors.Color, Colors.AlphaColor, Colors.AbstractString}

@doc """
Given an adjacency matrix and two vectors of X and Y coordinates, returns
a Compose tree of the graph layout

Arguments:
    adj_matrix       Adjacency matrix of some type. Non-zero of the eltype
                     of the matrix is used to determine if a link exists,
                     but currently no sense of magnitude
    locs_x, locs_y   Locations of the nodes. Can be any units you want,
                     but will be normalized and centered anyway
    labels           Optional. Labels for the vertices. Default: Any[]
    nodefillc        Color to fill the nodes with. Default: #AAAAFF
    nodestrokec      Color for the nodes stroke. Default: #BBBBBB
    edgestrokec      Color for the edge strokes. Default: #BBBBBB
    arrowlengthfrac  Fraction of line length to use for arrows.
                     Set to 0 for no arrows. Default: 0.1
    angleoffset      angular width in radians for the arrows. Default: π/9 (20 degrees).

""" ->
function compose_layout_adj{S, T<:Real}(
    adj_matrix::Array{S,2},
    locs_x::Vector{T}, locs_y::Vector{T};
    labels::Vector=Any[],
    filename::AbstractString="",
    labelc::ComposeColor="#000000",
    nodefillc::ComposeColor="#AAAAFF",
    nodestrokec::ComposeColor="#BBBBBB",
    edgestrokec::ComposeColor="#BBBBBB",
    labelsize::Real=4.0,
    arrowlengthfrac::Real=0.1,
    angleoffset=20.0/180.0*π)

    length(locs_x) != length(locs_y) && error("Vectors must be same length")
    const N = length(locs_x)
    if length(labels) != N && length(labels) != 0
        error("Must have one label per node (or none)")
    end

    # Scale to unit square
    min_x, max_x = minimum(locs_x), maximum(locs_x)
    min_y, max_y = minimum(locs_y), maximum(locs_y)
    function scaler(z, a, b)
        2.0*((z - a)/(b - a)) - 1.0
    end
    map!(z -> scaler(z, min_x, max_x), locs_x)
    map!(z -> scaler(z, min_y, max_y), locs_y)

    # Determine sizes
    const NODESIZE    = 0.25/sqrt(N)
    const LINEWIDTH   = 3.0/sqrt(N)
    const ARROWLENGTH = LINEWIDTH * arrowlengthfrac

    # Create lines and arrow heads
    lines = Any[]
    for i = 1:N
        for j = 1:N
            i == j && continue
            if adj_matrix[i,j] != zero(eltype(adj_matrix))
                push!(lines, lineij(locs_x, locs_y, i,j, NODESIZE, ARROWLENGTH, angleoffset))
            end
        end
    end

    # Create nodes
    nodes = [circle(locs_x[i],locs_y[i],NODESIZE) for i=1:N]

    # Create labels (if wanted)
    texts = length(labels) == N ?
        [text(locs_x[i],locs_y[i],labels[i],hcenter,vcenter) for i=1:N] : Any[]

    compose(context(units=UnitBox(-1.2,-1.2,+2.4,+2.4)),
        compose(context(), texts..., fill(labelc), stroke(nothing), fontsize(labelsize)),
        compose(context(), nodes..., fill(nodefillc), stroke(nodestrokec)),
        compose(context(), lines..., stroke(edgestrokec), linewidth(LINEWIDTH))
    )
end
# Adjusts by replacing the adjacency matrix with an abstract graph
function compose_layout_adj{V, E}(g::AbstractGraph{V, E}, 
                                  posargs...; 
                                  keyargs...)
    compose_layout_adj(adjacency_matrix(g), posargs...; keyargs...)
end

function arrowcoords(θ, endx, endy, arrowlength, angleoffset=20.0/180.0*π)
    arr1x = endx - arrowlength*cos(θ+angleoffset)
    arr1y = endy - arrowlength*sin(θ+angleoffset)
    arr2x = endx - arrowlength*cos(θ-angleoffset)
    arr2y = endy - arrowlength*sin(θ-angleoffset)
    return (arr1x, arr1y), (arr2x, arr2y)
end

function lineij(locs_x, locs_y, i, j, NODESIZE, ARROWLENGTH, angleoffset)
    Δx = locs_x[j] - locs_x[i]
    Δy = locs_y[j] - locs_y[i]
    d  = sqrt(Δx^2 + Δy^2)
    θ  = atan2(Δy,Δx)
    endx  = locs_x[i] + (d-NODESIZE)*1.00*cos(θ)
    endy  = locs_y[i] + (d-NODESIZE)*1.00*sin(θ)
    if ARROWLENGTH > 0.0
        arr1, arr2 = arrowcoords(θ, endx, endy, ARROWLENGTH, angleoffset)
        composenode = compose(
                context(),
                line([(locs_x[i], locs_y[i]), (endx, endy)]),
                line([arr1, (endx, endy)]),
                line([arr2, (endx, endy)])
            )
    else
        composenode = compose(
                context(),
                line([(locs_x[i], locs_y[i]), (endx, endy)])
            )
    end
    return composenode
end

@doc """
Given an adjacency matrix and two vectors of X and Y coordinates, returns
an SVG of the graph layout.

Requires Compose.jl

Arguments:
    adj_matrix       Adjacency matrix of some type. Non-zero of the eltype
                     of the matrix is used to determine if a link exists,
                     but currently no sense of magnitude
    locs_x, locs_y   Locations of the nodes. Can be any units you want,
                     but will be normalized and centered anyway
    labels           Optional. Labels for the vertices. Default: Any[]
    filename         Optional. Output filename for SVG. If blank, just
                     tries to draw it anyway, which will display in IJulia
    nodefillc        Color to fill the nodes with. Default: #AAAAFF
    nodestrokec      Color for the nodes stroke. Default: #BBBBBB
    edgestrokec      Color for the edge strokes. Default: #BBBBBB
    arrowlengthfrac  Fraction of line length to use for arrows.
                     Set to 0 for no arrows. Default: 0.1
    angleoffset      angular width in radians for the arrows. Default: π/9 (20 degrees).
    width            Width in millimeters of the resulting SVG image
    height           Height in millimeters of the resulting SVG image
""" ->
function draw_layout_adj{S, T<:Real}(
    adj_matrix::Array{S,2},
    locs_x::Vector{T}, locs_y::Vector{T};
    labels::Vector=Any[],
    filename::AbstractString="",
    labelc::ComposeColor="#000000",
    nodefillc::ComposeColor="#AAAAFF",
    nodestrokec::ComposeColor="#BBBBBB",
    edgestrokec::ComposeColor="#BBBBBB",
    labelsize::Real=4.0,
    arrowlengthfrac::Real=0.1,
    width=8inch,
    height=8inch,
    angleoffset=20.0/180.0*π)

    # provide width and height with units if necessary
    if typeof(width) <: Number
      width *= mm
    end
    if typeof(height) <: Number
      height *= mm
    end

    draw(filename == "" ? SVG(width, height) : SVG(filename, width, height),
        compose_layout_adj(adj_matrix, locs_x, locs_y, labels=labels,
            labelc=labelc, nodefillc=nodefillc, nodestrokec=nodestrokec,
            edgestrokec=edgestrokec, labelsize=labelsize,
            arrowlengthfrac=arrowlengthfrac, angleoffset=angleoffset)
    )
end
