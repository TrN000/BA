GH_BA_dir <- normalizePath("~/BachelorArbeit")
save_dir  <- normalizePath("~/BScThesis/4MM/fit-smi2/")
##--------------------------------------------------
stopifnot(dir.exists(GH_BA_dir),
          dir.exists(save_dir))


devtools::load_all(file.path(GH_BA_dir, "norMmix"))


## data sets:

## this takes the longest, as expected
data(SMI.12, package="copula")
smi <- SMI.12

## these need data.matrix, or they'll crash
irt <- data.matrix(iris[,-5]) # irt= IRis Truncated
iri <- data.matrix(iris)

data(loss, package="copula")
los <- data.matrix(loss)

dat <- c("smi", "irt", "iri", "los")


# options to vary over
trafos <- c("clr1", "logit")
inits <- c("clara", "mclVVV")
lls <- c("nmm", "mvt")


seed.n <- 1

for (dd in dat) {
    cat("work on data ", dd, "\n")
    x <- get(dd)
    for (trafo in trafos) {
        cat(">--> trafo = ", dQuote(trafo), "\n")
        for (ini in inits) {
            cat(">--> init = ", dQuote(ini), "\n")
            for (ll in lls) {
                cat(">--> loglikelihood = ", dQuote(ll), "\n")
                set.seed(seed.n)
                st <- system.time(
                    r <- tryCatch(
                        fitnMm(x, k=1:9, models=1:10,
                                    trafo=trafo, ini=ini, ll=ll,
                                    maxit=300),
                        error = identity)
                )
                cat("result of fit: "); str(r, max.level=1)
                sFile <- sprintf("fit_%s_%s_%s_%s.rds",
                                 dd, trafo, ini, ll)
                cat("--saving to file:", sFile, "\n")
                saveRDS(list(fit=r, st=st),
                        file=file.path(save_dir, sFile))
                seed.n <- seed.n+1
            }
        }
        cat("\n---end-of-dataset---\n")
    }
    cat("\n***--------------------------------------------***\n")
}



