#' Data Transformations
#'
#' @description
#' Performs variable transformation for standardization and resolving skewness
#' of numerical variables.
#'
#' @details
#' transform() creates an transform class.
#' The `transform` class includes original data, transformed data,
#' and method of transformation.
#'
#' See vignette("transformation") for an introduction to these concepts.
#'
#' @param x numeric vector for transformation.
#' @param method method of transformations.
#' @return An object of transform class.
#' Attributes of transform class is as follows.
#' \itemize{
#'   \item method : method of transformation data.
#'   \itemize{
#'     \item Standardization
#'       \itemize{
#'         \item "zscore" : z-score transformation. (x - mu) / sigma
#'         \item "minmax" : minmax transformation. (x - min) / (max - min)
#'       }
#'     \item Resolving Skewness
#'     \itemize{
#'       \item "log" : log transformation. log(x)
#'       \item "log+1" : log transformation. log(x + 1). Used for values that contain 0.
#'       \item "sqrt" : square root transformation.
#'       \item "1/x" : 1 / x transformation
#'       \item "x^2" : x square transformation
#'       \item "x^3" : x^3 square transformation
#'     }
#'   }
#' }
#' @seealso \code{\link{summary.transform}}, \code{\link{plot.transform}}.
#' @examples
#' # Generate data for the example
#' carseats <- ISLR::Carseats
#' carseats[sample(seq(NROW(carseats)), 20), "Income"] <- NA
#' carseats[sample(seq(NROW(carseats)), 5), "Urban"] <- NA
#'
#' # Standardization ------------------------------
#' advertising_minmax <- transform(carseats$Advertising, method = "minmax")
#' advertising_minmax
#' summary(advertising_minmax)
#' plot(advertising_minmax)
#'
#' # Resolving Skewness  --------------------------
#' advertising_log <- transform(carseats$Advertising, method = "log")
#' advertising_log
#' summary(advertising_log)
#' plot(advertising_log)
#'
#' # Using dplyr ----------------------------------
#' library(dplyr)
#'
#' carseats %>%
#'   mutate(Advertising_log = transform(Advertising, method = "log+1")) %>%
#'   lm(Sales ~ Advertising_log, data = .)
#' @export
#' @import tibble
#' @importFrom methods is
#' @importFrom stats sd
transform <- function(x, method = c("zscore", "minmax", "log", "log+1", "sqrt",
  "1/x", "x^2", "x^3")) {
  method <- match.arg(method)

  if (!is(x)[1] %in% c("integer", "numeric")) {
    stop("Categorical variable not support")
  }

  get_zscore <- function(x) {
    (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
  }

  get_minmax <- function(x) {
    (x - min(x, na.rm = TRUE)) / diff(range(x, na.rm = TRUE))
  }

  if (method == "zscore")
    result <- get_zscore(x)
  else if (method == "minmax")
    result <- get_minmax(x)
  else if (method == "log")
    result <- log(x)
  else if (method == "log+1")
    result <- log(x + 1)
  else if (method == "sqrt")
    result <- sqrt(x)
  else if (method == "1/x")
    result <- 1/x
  else if (method == "x^2")
    result <- x^2
  else if (method == "x^3")
    result <- x^3

  attr(result, "method") <- method
  attr(result, "origin") <- x

  class(result) <- append("transform", class(result))
  result
}


#' Summarizing transformation information
#'
#' @description print and summary method for "transform" class.
#' @param object an object of class "transform", usually, a result of a call to transform().
#' @param ... further arguments passed to or from other methods.
#' @details
#' summary.transform compares the distribution of data before and after data transformation.
#'
#' @seealso \code{\link{transform}}, \code{\link{plot.transform}}.
#' @examples
#' # Generate data for the example
#' carseats <- ISLR::Carseats
#' carseats[sample(seq(NROW(carseats)), 20), "Income"] <- NA
#' carseats[sample(seq(NROW(carseats)), 5), "Urban"] <- NA
#'
#' # Standardization ------------------------------
#' advertising_minmax <- transform(carseats$Advertising, method = "minmax")
#' advertising_minmax
#' summary(advertising_minmax)
#' plot(advertising_minmax)
#'
#' # Resolving Skewness  --------------------------
#' advertising_log <- transform(carseats$Advertising, method = "log")
#' advertising_log
#' summary(advertising_log)
#' plot(advertising_log)
#' @method summary transform
#' @importFrom tidyr gather
#' @export
summary.transform <- function(object, ...) {
  method <- attr(object, "method")
  origin <- attr(object, "origin")

  suppressWarnings({dframe <- data.frame(original = origin,
    trans = object) %>%
    tidyr::gather()})

  smmry <- dframe %>%
    group_by(key) %>%
    describe("value") %>%
    select(-variable, -key) %>%
    t
  colnames(smmry) <- c("Original", "Transformation")


  if (method %in% c("zscore", "minmax")) {
    cat(sprintf("* Standardization with %s\n\n", method))
  } else if (method %in% c("log", "log+1", "sqrt", "1/x", "x^2", "x^3")) {
    cat(sprintf("* Resolving Skewness with %s\n\n", method))
  }

  cat("* Information of Transformation (before vs after)\n")
  print(smmry)

  invisible(smmry)
}


#' Visualize Information for an "transform" Object
#'
#' @description
#' Visualize two kinds of plot by attribute of `transform` class.
#' The transformation of a numerical variable is a density plot.
#'
#' @param x an object of class "transform", usually, a result of a call to transform().
#' @param ... arguments to be passed to methods, such as graphical parameters (see par).
#' @seealso \code{\link{transform}}, \code{\link{summary.transform}}.
#' @examples
#' # Generate data for the example
#' carseats <- ISLR::Carseats
#' carseats[sample(seq(NROW(carseats)), 20), "Income"] <- NA
#' carseats[sample(seq(NROW(carseats)), 5), "Urban"] <- NA
#'
#' # Standardization ------------------------------
#' advertising_minmax <- transform(carseats$Advertising, method = "minmax")
#' advertising_minmax
#' summary(advertising_minmax)
#' plot(advertising_minmax)
#'
#' # Resolving Skewness  --------------------------
#' advertising_log <- transform(carseats$Advertising, method = "log")
#' advertising_log
#' summary(advertising_log)
#' plot(advertising_log)
#' @method plot transform
#' @import ggplot2
#' @importFrom tidyr gather
#' @importFrom gridExtra grid.arrange
#' @export
plot.transform <- function(x, ...) {
  origin <- attr(x, "origin")
  method <- attr(x, "method")

  suppressWarnings({df <- data.frame(original = origin,
    transformation = x) %>%
    tidyr::gather()})

  fig1 <- df %>%
    filter(key == "original") %>%
    ggplot(aes(x = value)) +
    geom_density(na.rm = TRUE) +
    ggtitle("Original Data") +
    theme(plot.title = element_text(hjust = 0.5))

  fig2 <- df %>%
    filter(key == "transformation") %>%
    ggplot(aes(x = value)) +
    geom_density(na.rm = TRUE) +
    ggtitle(sprintf("Transformation Data with '%s'", method))+
    theme(plot.title = element_text(hjust = 0.5))

  gridExtra::grid.arrange(fig1, fig2, ncol = 2)
}


#' Reporting the information of transformation
#'
#' @description The transformation_report() report the information of transform
#' numerical variables for object inheriting from data.frame.
#'
#' @details Generate transformation reports automatically.
#' You can choose to output to pdf and html files.
#' This is useful for Binning a data frame with a large number of variables
#' than data with a small number of variables.
#' For pdf output, Korean Gothic font must be installed in Korean operating system.
#' 
#' @section Reported information:
#' The transformation process will report the following information:
#'
#' \itemize{
#'   \item Imputation
#'   \itemize{
#'     \item Missing Values
#'     \itemize{
#'       \item * Variable names including missing value
#'     }
#'     \item Outliers
#'     \itemize{
#'       \item * Variable names including outliers
#'     }
#'   }
#'   \item Resolving Skewness
#'   \itemize{
#'     \item Skewed variables information
#'     \itemize{
#'       \item * Variable names with an absolute value of skewness greater than or equal to 0.5
#'     }
#'   }
#'   \item Binning
#'   \itemize{
#'     \item Numerical Variables for Binning
#'     \item Binning
#'     \itemize{
#'       \item Numeric variable names
#'     }
#'     \item Optimal Binning
#'     \itemize{
#'       \item Numeric variable names
#'     }
#'   }
#' }
#'
#' See vignette("transformation") for an introduction to these concepts.
#'
#' @param .data a data.frame or a \code{\link{tbl_df}}.
#' @param target target variable. If the target variable is not specified,
#' the method of using the target variable information is not performed when
#' the missing value is imputed. and Optimal binning is not performed if the
#' target variable is not a binary class.
#' @param output_format report output type. Choose either "pdf" and "html".
#' "pdf" create pdf file by knitr::knit().
#' "html" create html file by rmarkdown::render().
#' @param output_file name of generated file. default is NULL.
#' @param output_dir name of directory to generate report file. default is tempdir().
#' @param font_family character. font family name for figure in pdf.
#' @param browse logical. choose whether to output the report results to the browser.
#'
#' @examples
#' \donttest{
#' # Generate data for the example
#' carseats <- ISLR::Carseats
#' carseats[sample(seq(NROW(carseats)), 20), "Income"] <- NA
#' carseats[sample(seq(NROW(carseats)), 5), "Urban"] <- NA
#'
#' # reporting the Binning information -------------------------
#' # create pdf file. file name is Transformation_Report.pdf & No target variable
#' transformation_report(carseats)
#' # create pdf file. file name is Transformation_Report.pdf
#' transformation_report(carseats, US)
#' # create pdf file. file name is Transformation_carseats.pdf
#' transformation_report(carseats, "US", output_file = "Transformation_carseats.pdf")
#' # create html file. file name is Transformation_Report.html
#' transformation_report(carseats, "US", output_format = "html")
#' # create html file. file name is Transformation_carseats
#' transformation_report(carseats, US, output_format = "html", 
#'                       output_file = "Transformation_carseats.html")
#' }
#'
#' @importFrom knitr knit2pdf
#' @importFrom rmarkdown render
#' @importFrom grDevices cairo_pdf
#' @importFrom gridExtra grid.arrange
#' @importFrom xtable xtable
#' @importFrom moments skewness kurtosis
#' @importFrom knitr kable
#' @importFrom prettydoc html_pretty
#' @importFrom kableExtra kable_styling
#' @importFrom utils browseURL
#'
#' @export
transformation_report <- function(.data, target = NULL, output_format = c("pdf", "html"),
  output_file = NULL, output_dir = tempdir(), font_family = NULL, browse = TRUE) {
  tryCatch(vars <- tidyselect::vars_select(names(.data), !!! rlang::enquo(target)),
    error = function(e) {
      pram <- as.character(substitute(target))
      stop(sprintf("Column %s is unknown", pram))
    }, finally = NULL)
  output_format <- match.arg(output_format)

  assign("edaData", as.data.frame(.data), .dlookrEnv)
  assign("targetVariable", vars, .dlookrEnv)

  path <- output_dir
  if (length(grep("ko_KR", Sys.getenv("LANG"))) == 1) {
    latex_main <- "Transformation_Report_KR.Rnw"
    latex_sub <- "03_Transformation_KR.Rnw"
  } else {
    latex_main <- "Transformation_Report.Rnw"
    latex_sub <- "03_Transformation.Rnw"
  } 
  
  if (!is.null(font_family)) {
    ggplot2::theme_set(ggplot2::theme_gray(base_family = font_family))
    par(family = font_family)
  }
  
  if (output_format == "pdf") {
    installed <- file.exists(Sys.which("pdflatex"))

    if (!installed) {
      stop("No TeX installation detected. Please install TeX before running.\nor Use output_format = \"html\"")
    }

    if (is.null(output_file))
      output_file <- "Transformation_Report.pdf"

    Rnw_file <- file.path(system.file(package = "dlookr"), "report", latex_main)
    file.copy(from = Rnw_file, to = path)

    Rnw_file <- file.path(system.file(package = "dlookr"), "report", latex_sub)
    file.copy(from = Rnw_file, to = path)

    Img_file <- file.path(system.file(package = "dlookr"), "img")
    file.copy(from = Img_file, to = path, recursive = TRUE)

    dir.create(paste(path, "figure", sep = "/"))

    knitr::knit2pdf(paste(path, latex_main, sep = "/"), 
      compiler = "pdflatex",
      output = sub("pdf$", "tex", paste(path, output_file, sep = "/")))

    file.remove(paste(path, latex_sub, sep = "/"))
    file.remove(paste(path, latex_main, sep = "/"))

    fnames <- sub("pdf$", "", output_file)
    fnames <- grep(fnames, list.files(path), value = TRUE)
    fnames <- grep("\\.pdf$", fnames, invert = TRUE, value = TRUE)

    file.remove(paste(path, fnames, sep = "/"))
    
    unlink(paste(path, "figure", sep = "/"), recursive = TRUE)
    unlink(paste(path, "img", sep = "/"), recursive = TRUE)
  } else if (output_format == "html") {
    if (length(grep("ko_KR", Sys.getenv("LANG"))) == 1) {
      rmd <- "Transformation_Report_KR.Rmd"
    } else {
      rmd <- "Transformation_Report.Rmd"
    }
    
    if (is.null(output_file))
      output_file <- "Transformation_Report.html"

    Rmd_file <- file.path(system.file(package = "dlookr"), "report", rmd)
    file.copy(from = Rmd_file, to = path, recursive = TRUE)

    rmarkdown::render(paste(path, rmd, sep = "/"),
      prettydoc::html_pretty(toc = TRUE, number_sections = TRUE),
      output_file = paste(path, output_file, sep = "/"))

    file.remove(paste(path, rmd, sep = "/"))
  }

  if (browse & file.exists(paste(path, output_file, sep = "/"))) {
    browseURL(paste(path, output_file, sep = "/"))
  }
}
