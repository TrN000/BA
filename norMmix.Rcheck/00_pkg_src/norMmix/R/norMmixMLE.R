#### MLE for norMmix objects


## Compute clara()'s sampsize [ 'ss' := sampsize ;  'L' := Log ]
## to be used as argument e.g., of norMmixMLE()
ssClaraL <- function(n,k, p) pmin(n, pmax(40, round(10*log(n))) + round(2*k*pmax(1, log(n*p))))


# Maximum likelihood Estimation for normal mixture models
#
# norMmixMLE returns fitted nMm obj
#
# Uses clara() and one M-step from EM-algorithm to initialize parameters
# after that uses general optimizer optim() to calculate ML.
#
# x:     sample matrix
# k:     number of components
# trafo: transformation to be used
# model: model to be assumed
norMmixMLE <- function(
               x, k,
               model = c("EII","VII","EEI","VEI","EVI",
                         "VVI","EEE","VEE","EVV","VVV"),
               ini = c("clara", "mclVVV"),
               trafo=c("clr1", "logit"),
               ll = c("nmm", "mvt"),
               ## epsilon = 1e-10,
               method = "BFGS", maxit = 100, trace = 2,
               optREPORT=10, reltol = sqrt(.Machine$double.eps),
               samples = 128,
               sampsize = ssClaraL,
               traceClara = 0,
	       ... ) {
    # 1. san check call
    # 2. prep nMm obj
    # 3. apply optim
    # 4. return

    # 1.
    trafo <- match.arg(trafo)
    model <- match.arg(model)
    ini <- match.arg(ini)
    ll <- match.arg(ll)

    if(!is.matrix(x)) x <- data.matrix(x) # e.g. for data frame
    stopifnot(is.numeric(x), length(k <- as.integer(k)) == 1, 
              (n <- nrow(x)) > 1)
    p <- ncol(x)

    ## init tau : index <- <clustering>
    switch(ini,
         ## init tau using clara
        "clara" = {
            if(is.function(sampsize)) sampsize <- sampsize(n,k,p)
            stopifnot(length(sampsize) == 1L, sampsize >= 1)
            clus <- clara(x, k, rngR=TRUE, pamLike=TRUE, medoids.x=FALSE,
                          samples=samples, sampsize=sampsize, trace=traceClara)
            index <- clus$clustering
        },

        ## clustering using hc() from the mclust package
        "mclVVV" = {
            mclclus <- hcVVV(x)
            index <- hclass(mclclus, k)
        },
        stop("invalid 'ini':", ini))

    tau <- matrix(0, n,k)
    tau[cbind(1:n, index)] <- 1

    # 2.

    mcl.mstep <- switch(model,
        "EII" = mclust::mstepEII(x, tau),
        "VII" = mclust::mstepVII(x, tau),
        "EEI" = mclust::mstepEEI(x, tau),
        "VEI" = mclust::mstepVEI(x, tau),
        "EVI" = mclust::mstepEVI(x, tau),
        "VVI" = mclust::mstepVVI(x, tau),
        "EEE" = mclust::mstepEEE(x, tau),
        "VEE" = mclust::mstepVEE(x, tau),
        "EVV" = mclust::mstepEVV(x, tau),
        "VVV" = mclust::mstepVVV(x, tau),

        stop("error in mstep, in norMmixMLE")
    )

    nMm.temp <- norMmix(mcl.mstep$parameters$mean,
                        Sigma = mcl.mstep$parameters$variance$sigma,
                        weight = mcl.mstep$parameters$pro,
                        model = mcl.mstep$modelName)

    # create par. vector out of m-step
        #nMm.temp <- forcePositive(nMm.temp, eps0=epsilon)
    initpar. <- nMm2par(obj=nMm.temp, model=model, trafo=trafo, meanFUN=mean)
    # save degrees of freedom
    npar <- length(initpar.)

    # 3.

    if(ll == "nmm") tx <- t(x)
    # define function to optimize as negative log-lik
    # also reduces the number of arguments to par.
    neglogl <- switch(ll,
        "nmm" = function(P) { -llnorMmix(P, tx=tx, k=k, model=model, trafo=trafo) }, ## max(-10^300, -llnorMmix) for both
        "mvt" = function(P) { -llmvtnorm(P, x=x, k=k, model=model, trafo=trafo) },
        stop("error selecting neglogl") )

    control <- list(maxit=maxit, reltol=reltol,
                    trace=(trace > 0), REPORT= optREPORT,
    		    ...)
    optr <- optim(initpar., neglogl, method=method, control=control)

    # 4.

    ret <- list(norMmix = par2nMm(optr$par, p, k, model=model),
                optr=optr, npar=npar, n=n,
                x=x,
                cond = parcond(x, k=k, model=model))

    #r <- structure(.Data=par2nMm(optr$par, p, k, model=model),
    #               optr=optr,
    #               npar=npar,
    #               df=npar,
    #               n=n,
    #               x=x,
    #               cond=parcond(x, k=k, model=model),
    #               class=c("norMmixMLE", "norMmix")
    #               )
    class(ret) <- "norMmixMLE"
    ret
}


logLik.norMmixMLE <- function(object, ...) {
    r <- object$optr$value
    attributes(r) <- list(df=object$npar, nobs=nobs(object))
    class(r) <- "logLik"
    r
}


nobs.norMmixMLE <- function(object, ...) object$n


npar.norMmixMLE <- function(object, ...) {
    npar(object$norMmix)
}

print.norMmixMLE <- function(x, ...) {
    cat("object of class 'norMmixMLE' \n")
    print(x$norMmix)
    cat("\nreturned from optim:\n")
    print(x$optr$counts)
    cat("\nlog-likelihood:", -x$optr$value, "\n",
        "\n",
        "nobs\tnpar\tnobs/npar\n",
        x$n, "\t", x$npar, "\t", x$cond, "\n")
    invisible(x)
}
