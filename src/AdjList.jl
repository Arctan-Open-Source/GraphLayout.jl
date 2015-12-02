import Base: convert
import Graphs: IEdge

# Allows using an adjacency list as a full featured graph object
# Also serves transitional purposes
typealias AdjList{T} Vector{Vector{T}}

# Required by the type system
type _AdjList{T} <: AbstractGraph{Int, IEdge}
    list::AdjList{T}
end

function convert{T}(::Type{AdjList{T}}, obj::_AdjList{T})
    return obj.list
end

is_directed{T}(g::_AdjList{T}) = true

# vertex_list
num_vertices{T}(g::_AdjList{T}) = length(g.list)

vertices{T}(g::_AdjList{T}) = 1:num_vertices(g)

# edge_list
num_edges{T}(g::_AdjList{T}) = sum([length(edgeList) for edgeList in g.list])

function edges{T}(g::_AdjList{T})
    edgeGroup = Array{IEdge, 1}()
    for v in vertices(g)
        push!(edgeGroup, out_edges(v)...)
    end
    return edgeGroup
end

source{T}(ed, g::_AdjList{T}) = source(ed)
target{T}(ed, g::_AdjList{T}) = target(ed)

# vertex map
vertex_index{T}(v, g::_AdjList{T}) = v

# edge map
edge_index{T}(ed, g::_AdjList{T}) = edge_index(ed)

# adjacency list interface
out_degree{T}(v, g::_AdjList{T}) = length(g.list[v])
out_neighbors{T}(v, g::_AdjList{T}) = g.list[v]

# incidence list interface
function out_edges{T}(v, g::_AdjList{T})
    offset = sum([length(edgeList) for edgeList in g.list[1:(v - 1)]])
    return [IEdge(v, offset + i) for i in out_neighbors(v, g)]
end

# bidirectional adjacency list
function in_neighbors{T}(v, g::_AdjList{T})
    ins = Array{Int, 1}()
    for u in vertices(g)
        if v == u
            continue
        end # if
        for t in out_neighbors(u, g)
            if v == t
                push!(ins, u)
                break
            end # if
        end # for
    end # for
    return ins
end

# bidirectional incidence list interface
in_degree{T}(v, g::_AdjList{T}) = length(in_neighbors(v, g))

# much slower and a possible reason not to use adjacency lists
function in_edges{T}(v, g::_AdjList{T})
    # This is horrific due to the need to keep edge indices consistent
    ins = Array{IEdge, 1}()
    neighbors = in_neighbors(v, g)
    offset = 0
    for u in vertices(g)
        i = findfirst(out_neighbors(u), v)
        if i > 0
          push!(ins, IEdge(offset + i, u, v))
        end
        offset += out_degree(u)
    end
    return ins
end

# @graph_implements _AdjList{T} vertex_list edge_list vertex_map edge_map 
# @graph_implements _AdjList{T} adjacency_list incidence_list
# @graph_implements _AdjList{T} bidirectional_incidence_list
# @graph_implements _AdjList{T} bidirectional_adjacency_list
# The "graph_implements" macro doesn't seem to work for templates
implements_vertex_list{T}(::_AdjList{T}) = true
implements_edge_list{T}(::_AdjList{T}) = true
implements_vertex_map{T}(::_AdjList{T}) = true
implements_edge_map{T}(::_AdjList{T}) = true
implements_adjacency_list{T}(::_AdjList{T}) = true
implements_incidence_list{T}(::_AdjList{T}) = true
implements_bidirectional_incidence_list{T}(::_AdjList{T}) = true
implements_bidirectional_adjacency_list{T}(::_AdjList{T}) = true

