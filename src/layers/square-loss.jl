############################################################
# Square Loss
#
# L(\hat{y},y) = 1/2N \sum_{i=1}^N (\hat{y}_i - y_i)^2
############################################################
@defstruct SquareLossLayer LossLayer (
  (tops :: Vector{String} = String["square-loss"], length(tops) == 1),
  (bottoms :: Vector{String} = String[], length(bottoms) == 2)
)

type SquareLossLayerState <: LayerState
  layer :: SquareLossLayer
  blobs :: Vector{Blob}
end

function setup(sys::System, layer::SquareLossLayer, inputs::Vector{Blob})
  data_type = eltype(inputs[1])
  if isa(sys.backend, CPUBackend)
    blobs = Blob[CPUBlob(Array(data_type, 1))]
  else
    error("Backend $(sys.backend) not supported")
  end

  state = SquareLossLayerState(layer, blobs)
  return state
end

function forward(sys::System{CPUBackend}, state::SquareLossLayerState, inputs::Vector{Blob})
  pred  = inputs[1].data
  label = inputs[2].data

  dims = size(pred)
  batch_size = dims[1]
  rest_dim = prod(dims[2:end])

  pred  = reshape(pred, (batch_size, rest_dim))
  label = reshape(label, (batch_size, rest_dim))

  state.blobs[1].data[:] = 0.5*mean(sum((pred - label).^2, 2))
end

function backward(sys::System{CPUBackend}, state::SquareLossLayerState, inputs::Vector{Blob}, diffs::Vector{Blob})
  if isa(diffs[1], CPUBlob)
    pred  = inputs[1].data
    label = inputs[2].data
    diffs[1].data[:] = (pred - label) / size(pred,1)
  end
end
