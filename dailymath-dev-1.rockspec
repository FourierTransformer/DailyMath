package = "dailyMath"
version = "dev-1"

source = {
    url = "git://github.com/FourierTransformer/dailyMath"
}

description = {
    summary = "a website for people who love math",
    homepage = "https://github.com/FourierTransformer/dailyMath",
    maintainer = "Shakil Thakur <shakil.thakur@gmail.com>",
    license = "undecided"
}

dependencies = {
    "lua ~> 5.1",
    "lapis ~> 1.3.0",
    "date ~> 2.1.1",
    "bcrypt ~> 2.1"
}

build = {
    type = "none"
}
