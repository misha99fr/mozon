local computer = require("computer")



if not computer.getBootAddress then
    print("¯\\_(ツ)_/¯ усп, ваш биос не поддерживает устоновку загрузочьного насителя, попробуйте сами загрузиться с диска через биос, инструкция должна быть написана в описании вашего биоса")
    return
end

computer.setBootAddress()