### A Pluto.jl notebook ###
# v0.11.14

using Markdown
using InteractiveUtils

# ╔═╡ e47f3940-f4c8-11ea-0595-332f7117096c
# Classifies MNIST digits with a convolutional network.
# Writes out saved model to the file "mnist_conv.bson".
# Demonstrates basic model construction, training, saving,
# conditional early-exit, and learning rate scheduling.
#
# This model, while simple, should hit around 99% test
# accuracy after training for approximately 20 epochs.

using Flux, Flux.Data.MNIST, Statistics

# ╔═╡ ed1fda32-f4c8-11ea-0ada-f331e31a0dc9
using Flux: onehotbatch, onecold, logitcrossentropy

# ╔═╡ ed201362-f4c8-11ea-09f2-4b69c3096fe4
using Base.Iterators: partition

# ╔═╡ ed205a70-f4c8-11ea-3768-7d5267dde1d5
using Printf, BSON

# ╔═╡ ed285bd0-f4c8-11ea-33a1-3fa5651e7e59
using Parameters: @with_kw

# ╔═╡ ed28a02c-f4c8-11ea-3761-09e16a594d46
using CUDAapi

# ╔═╡ ed2da9e6-f4c8-11ea-0056-fbfbf1b97043
if has_cuda()
    @info "CUDA is on"
    import CuArrays
    CuArrays.allowscalar(false)
end

# ╔═╡ ed2df982-f4c8-11ea-35e0-9de4a6e69b0d
@with_kw mutable struct Args
    lr::Float64 = 3e-3
    epochs::Int = 20
    batch_size = 128
    savepath::String = "./" 
end

# ╔═╡ ed302e32-f4c8-11ea-03d6-e78d980ab7a1
# Bundle images together with labels and group into minibatchess
function make_minibatch(X, Y, idxs)
    X_batch = Array{Float32}(undef, size(X[1])..., 1, length(idxs))
    for i in 1:length(idxs)
        X_batch[:, :, :, i] = Float32.(X[idxs[i]])
    end
    Y_batch = onehotbatch(Y[idxs], 0:9)
    return (X_batch, Y_batch)
end

# ╔═╡ ed329438-f4c8-11ea-190e-d30380a4f5d1
function get_processed_data(args)
    # Load labels and images from Flux.Data.MNIST
    train_labels = MNIST.labels()
    train_imgs = MNIST.images()
    mb_idxs = partition(1:length(train_imgs), args.batch_size)
    train_set = [make_minibatch(train_imgs, train_labels, i) for i in mb_idxs] 
    
    # Prepare test set as one giant minibatch:
    test_imgs = MNIST.images(:test)
    test_labels = MNIST.labels(:test)
    test_set = make_minibatch(test_imgs, test_labels, 1:length(test_imgs))

    return train_set, test_set

end

# ╔═╡ ed3827f4-f4c8-11ea-2ea2-cfa26f21b048
# Build model
function build_model(args; imgsize = (28,28,1), nclasses = 10)
    cnn_output_size = Int.(floor.([imgsize[1]/8,imgsize[2]/8,32]))	

    return Chain(
    # First convolution, operating upon a 28x28 image
    Conv((3, 3), imgsize[3]=>16, pad=(1,1), relu),
    MaxPool((2,2)),

    # Second convolution, operating upon a 14x14 image
    Conv((3, 3), 16=>32, pad=(1,1), relu),
    MaxPool((2,2)),

    # Third convolution, operating upon a 7x7 image
    Conv((3, 3), 32=>32, pad=(1,1), relu),
    MaxPool((2,2)),

    # Reshape 3d tensor into a 2d one using `Flux.flatten`, at this point it should be (3, 3, 32, N)
    flatten,
    Dense(prod(cnn_output_size), 10))
end

# ╔═╡ ed38f472-f4c8-11ea-370b-a186ceac7474
# We augment `x` a little bit here, adding in random noise. 
augment(x) = x .+ gpu(0.1f0*randn(eltype(x), size(x)))

# ╔═╡ ed3b3fac-f4c8-11ea-3621-5f527468b53d
# Returns a vector of all parameters used in model
paramvec(m) = vcat(map(p->reshape(p, :), params(m))...)

# ╔═╡ ed40bb08-f4c8-11ea-3a38-7b685b8f5d93
# Function to check if any element is NaN or not
anynan(x) = any(isnan.(x))

# ╔═╡ ed41c278-f4c8-11ea-2bbc-5b76756e2f2a
accuracy(x, y, model) = mean(onecold(cpu(model(x))) .== onecold(cpu(y)))

# ╔═╡ ed4687d6-f4c8-11ea-1f75-dd520f505a99
function train(; kws...)	
    args = Args(; kws...)

    @info("Loading data set")
    train_set, test_set = get_processed_data(args)

    # Define our model.  We will use a simple convolutional architecture with
    # three iterations of Conv -> ReLU -> MaxPool, followed by a final Dense layer.
    @info("Building model...")
    model = build_model(args) 

    # Load model and datasets onto GPU, if enabled
    train_set = gpu.(train_set)
    test_set = gpu.(test_set)
    model = gpu(model)
    
    # Make sure our model is nicely precompiled before starting our training loop
    model(train_set[1][1])

    # `loss()` calculates the crossentropy loss between our prediction `y_hat`
    # (calculated from `model(x)`) and the ground truth `y`.  We augment the data
    # a bit, adding gaussian random noise to our image to make it more robust.
    function loss(x, y)    
        x̂ = augment(x)
        ŷ = model(x̂)
        return logitcrossentropy(ŷ, y)
    end
	
    # Train our model with the given training set using the ADAM optimizer and
    # printing out performance against the test set as we go.
    opt = ADAM(args.lr)
	
    @info("Beginning training loop...")
    best_acc = 0.0
    last_improvement = 0
    for epoch_idx in 1:args.epochs
        # Train for a single epoch
        Flux.train!(loss, params(model), train_set, opt)
	    
        # Terminate on NaN
        if anynan(paramvec(model))
            @error "NaN params"
            break
        end
	
        # Calculate accuracy:
        acc = accuracy(test_set..., model)
		
        @info(@sprintf("[%d]: Test accuracy: %.4f", epoch_idx, acc))
        # If our accuracy is good enough, quit out.
        if acc >= 0.999
            @info(" -> Early-exiting: We reached our target accuracy of 99.9%")
            break
        end
	
        # If this is the best accuracy we've seen so far, save the model out
        if acc >= best_acc
            @info(" -> New best accuracy! Saving model out to mnist_conv.bson")
            BSON.@save joinpath(args.savepath, "mnist_conv.bson") params=cpu.(params(model)) epoch_idx acc
            best_acc = acc
            last_improvement = epoch_idx
        end
	
        # If we haven't seen improvement in 5 epochs, drop our learning rate:
        if epoch_idx - last_improvement >= 5 && opt.eta > 1e-6
            opt.eta /= 10.0
            @warn(" -> Haven't improved in a while, dropping learning rate to $(opt.eta)!")
   
            # After dropping learning rate, give it a few epochs to improve
            last_improvement = epoch_idx
        end
	
        if epoch_idx - last_improvement >= 10
            @warn(" -> We're calling this converged.")
            break
        end
    end
end

# ╔═╡ ed47c4ca-f4c8-11ea-0538-2bc53deec1b6
# Testing the model, from saved model
function test(; kws...)
    args = Args(; kws...)
    
    # Loading the test data
    _,test_set = get_processed_data(args)
    
    # Re-constructing the model with random initial weights
    model = build_model(args)
    
    # Loading the saved parameters
    BSON.@load joinpath(args.savepath, "mnist_conv.bson") params
    
    # Loading parameters onto the model
    Flux.loadparams!(model, params)
    
    test_set = gpu.(test_set)
    model = gpu(model)
    @show accuracy(test_set...,model)
end

# ╔═╡ ed4c32ee-f4c8-11ea-35b1-13d3f4a987ae
cd(@__DIR__)

# ╔═╡ ed4f80e6-f4c8-11ea-086d-55bce4cc20ec
train()

# ╔═╡ ed50dcfe-f4c8-11ea-36ac-adb90071436a
test()

# ╔═╡ Cell order:
# ╠═e47f3940-f4c8-11ea-0595-332f7117096c
# ╠═ed1fda32-f4c8-11ea-0ada-f331e31a0dc9
# ╠═ed201362-f4c8-11ea-09f2-4b69c3096fe4
# ╠═ed205a70-f4c8-11ea-3768-7d5267dde1d5
# ╠═ed285bd0-f4c8-11ea-33a1-3fa5651e7e59
# ╠═ed28a02c-f4c8-11ea-3761-09e16a594d46
# ╠═ed2da9e6-f4c8-11ea-0056-fbfbf1b97043
# ╠═ed2df982-f4c8-11ea-35e0-9de4a6e69b0d
# ╠═ed302e32-f4c8-11ea-03d6-e78d980ab7a1
# ╠═ed329438-f4c8-11ea-190e-d30380a4f5d1
# ╠═ed3827f4-f4c8-11ea-2ea2-cfa26f21b048
# ╠═ed38f472-f4c8-11ea-370b-a186ceac7474
# ╠═ed3b3fac-f4c8-11ea-3621-5f527468b53d
# ╠═ed40bb08-f4c8-11ea-3a38-7b685b8f5d93
# ╠═ed41c278-f4c8-11ea-2bbc-5b76756e2f2a
# ╠═ed4687d6-f4c8-11ea-1f75-dd520f505a99
# ╠═ed47c4ca-f4c8-11ea-0538-2bc53deec1b6
# ╠═ed4c32ee-f4c8-11ea-35b1-13d3f4a987ae
# ╠═ed4f80e6-f4c8-11ea-086d-55bce4cc20ec
# ╠═ed50dcfe-f4c8-11ea-36ac-adb90071436a
