## Intent: compare init methods

nmmdir <- normalizePath("~/BachelorArbeit/norMmix.Rcheck/")
savdir <- normalizePath("~/BachelorArbeit/Rscripts/2init")
stopifnot(dir.exists(nmmdir), dir.exists(savdir))
library(norMmix, lib.loc=nmmdir)
library(mclust)

## at n=500,p=2 can do about 250xfitnMm(x,1:10) in 24h
init <- c("clara", "mclVVV")
seeds <- 1:50
nmm <- list(MW214, MW34)
## => about 200 cases

# for naming purposes
nmnames <- c("MW214", "MW34")
files <- vector(mode="character")


for (nm in 1:2) {
    set.seed(2019); x <- rnorMmix(500,nmm[[nm]])
    for (seed in seeds) {
        for (ini in init) {
            set.seed(2019+seed)
            r <- tryCatch(fitnMm(x, k=1:8, ini=ini,
                                 optREPORT=1e4, maxit=1e4),
                          error = identity)
            filename <- sprintf("%s_ini=%s_seed=%0.2d.rds",
                                nmnames[nm], ini, seed)
            files <- append(files, filename)
            cat("===> saving to file:", filename, "\n")
            saveRDS(list(fit=r), file=file.path(savdir, filename))
        }
    }
}

fillis <- list()
for (i in seq_along(init)) {
    for (j in seq_along(nmnames)) {
        # for lack of AND matching, OR match everything else and invert
        ret <- grep(paste(init[-i], nmnames[-j], sep="|"), 
                    files, value=TRUE, invert=TRUE)
        fillis[[paste0(init[i], nmnames[j])]] <- ret
    }
}

epfl(fillis, savdir)
