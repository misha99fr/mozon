local bootfs, gpu, screen
do
    bootfs = component.proxy(computer.getBootAddress())
    if computer.getBootGpu then
        gpu = computer.getBootGpu()
    else
        gpu = component.list("gpu")()
    end
    if computer.getBootScreen then
        gpu = computer.getBootGpu()
    else
        gpu = component.list("screen")()
    end
    gpu = component.proxy(gpu)
end