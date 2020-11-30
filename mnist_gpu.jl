### A Pluto.jl notebook ###
# v0.11.14

using Markdown
using InteractiveUtils

# ╔═╡ 8149551a-f4c6-11ea-252d-29f2baaad175
using Printf

# ╔═╡ 34cfe268-f4c7-11ea-1ec0-61e696684aa8
using Flux, Flux.Data.MNIST, Statistics

# ╔═╡ 34d0a516-f4c7-11ea-1e64-0d13a3840193
using Flux: onehotbatch, onecold, crossentropy, @epochs

# ╔═╡ 34d16fd2-f4c7-11ea-2f25-6362afceb48c
using Base.Iterators: partition

# ╔═╡ 34d9308c-f4c7-11ea-3401-43a143aa6f38
using BSON: @load, @save

# ╔═╡ 34da4742-f4c7-11ea-3add-c94710249ab8
using CuArrays

# ╔═╡ 34e01046-f4c7-11ea-3ec3-2528feadb9f0
using Random

# ╔═╡ e2020640-f4c6-11ea-32a6-e34d72594529
function prepare_dataset(;train=true)
    train_or_test = ifelse(train,:train,:test)
    imgs = MNIST.images(train_or_test)
    X = hcat(float.(vec.(imgs))...)
    labels = MNIST.labels(train_or_test)
    Y = onehotbatch(labels,0:9)
    return X, Y
end

# ╔═╡ e741e54e-f4c6-11ea-2e13-21ad98e74417
function define_model(;hidden)
    mlp = Chain(Dense(28^2,hidden,relu),
                Dense(hidden,hidden,relu),
                Dense(hidden,10),
                softmax)
    return mlp
end

# ╔═╡ ec9bf1e2-f4c6-11ea-1c77-87e5bc4d9d4a
function split_dataset_random(X, Y)
    divide_ratio=0.9
    shuffled_indices = shuffle(1:size(Y)[2])
    divide_idx = round(Int,0.9*length(shuffled_indices))
    train_indices = shuffled_indices[1:divide_idx]
    val_indices = shuffled_indices[divide_idx:end]
    train_X = X[:,train_indices]
    train_Y = Y[:,train_indices]
    val_X = X[:,val_indices]
    val_Y = Y[:,val_indices]
    return train_X, train_Y, val_X, val_Y
end

# ╔═╡ f7c15526-f4c6-11ea-0db3-13fff316d2c9
function train()
    println("Start to train")
    epochs = 10
    X, Y = prepare_dataset(train=true)
    train_X, train_Y, val_X,val_Y = split_dataset_random(X, Y)
    model = define_model(hidden=100) |> gpu
    loss(x,y)= crossentropy(model(x),y)
    accuracy(x, y) = mean(onecold(model(x)) .== onecold(y))
    batchsize = 64
    train_dataset = gpu.([(train_X[:,batch] ,train_Y[:,batch]) for batch in partition(1:size(train_Y)[2],batchsize)])
    val_dataset = gpu.([(val_X[:,batch] ,val_Y[:,batch]) for batch in partition(1:size(val_Y)[2],batchsize)])

    callback_count = 0
    eval_callback = function callback()
        callback_count += 1
        if callback_count == length(train_dataset)
            println("action for each epoch")
            total_loss = 0
            total_acc = 0
            for (vx, vy) in val_dataset
                total_loss += loss(vx, vy)
                total_acc += accuracy(vx, vy)
            end
            total_loss /= length(val_dataset)
            total_acc /= length(val_dataset)
            @show total_loss, total_acc
            callback_count = 0
            pretrained = model |> cpu
            @save "pretrained.bson" pretrained
            callback_count = 0
        end
        if callback_count % 50 == 0
            progress = callback_count / length(train_dataset)
           @printf("%.3f\n", progress)
        end
    end
    optimizer = ADAM(params(model))

    @epochs epochs Flux.train!(loss, train_dataset, optimizer, cb = eval_callback)

    pretrained = model |> cpu
    weights = Tracker.data.(params(pretrained))
    @save "pretrained.bson" pretrained
    @save "weights.bson" weights
    println("Finished to train")
end

# ╔═╡ fd61af12-f4c6-11ea-254e-05caae039eb4
function predict()
    println("Start to evaluate testset")
    println("loading pretrained model")
    @load "pretrained.bson" pretrained
    model = pretrained |> gpu
    accuracy(x, y) = mean(onecold(model(x)) .== onecold(y))
    println("prepare dataset")
    X, Y = prepare_dataset(train=false)
    X = X |> gpu
    Y = Y |> gpu
    @show accuracy(X, Y)
    println("Done")
end

# ╔═╡ 02de4586-f4c7-11ea-37e5-5fbc6d9ed260
function predict2()
    println("Start to evaluate testset")
    println("loading pretrained model")
    @load "weights.bson" weights
    model = define_model(hidden=100)
    Flux.loadparams!(model, weights)
    model = model |> gpu
    accuracy(x, y) = mean(onecold(model(x)) .== onecold(y))
    println("prepare dataset")
    X, Y = prepare_dataset(train=false)
    X = X |> gpu
    Y = Y |> gpu
    @show accuracy(X, Y)
    println("Done")
end

# ╔═╡ 0a717b74-f4c7-11ea-3599-9384c8513b2a
train()

# ╔═╡ 1cb86220-f4c7-11ea-2e3d-571d34765494
predict()

# ╔═╡ 227c0586-f4c7-11ea-10db-bb45821ebb67
predict2()

# ╔═╡ Cell order:
# ╠═8149551a-f4c6-11ea-252d-29f2baaad175
# ╠═34cfe268-f4c7-11ea-1ec0-61e696684aa8
# ╠═34d0a516-f4c7-11ea-1e64-0d13a3840193
# ╠═34d16fd2-f4c7-11ea-2f25-6362afceb48c
# ╠═34d9308c-f4c7-11ea-3401-43a143aa6f38
# ╠═34da4742-f4c7-11ea-3add-c94710249ab8
# ╠═34e01046-f4c7-11ea-3ec3-2528feadb9f0
# ╠═e2020640-f4c6-11ea-32a6-e34d72594529
# ╠═e741e54e-f4c6-11ea-2e13-21ad98e74417
# ╠═ec9bf1e2-f4c6-11ea-1c77-87e5bc4d9d4a
# ╠═f7c15526-f4c6-11ea-0db3-13fff316d2c9
# ╠═fd61af12-f4c6-11ea-254e-05caae039eb4
# ╠═02de4586-f4c7-11ea-37e5-5fbc6d9ed260
# ╠═0a717b74-f4c7-11ea-3599-9384c8513b2a
# ╠═1cb86220-f4c7-11ea-2e3d-571d34765494
# ╠═227c0586-f4c7-11ea-10db-bb45821ebb67
