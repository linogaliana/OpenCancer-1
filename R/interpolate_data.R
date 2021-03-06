# == INTERMEDIATE FUNCTION

#' Given a grouped dataframe and a line, interpolate
#'
#' @details Intermediate function, do not use
#' @param missingdata A dataframe listing groups and variables
#' that must be changed
#' @param i Line index of missingdata that will be looked
#' @return A list with several components: \code{lines} and \code{cols}
#' return the lines and columns concerned by interpolation, \code{after}
#' returns the relevant lines and columns interpolated while \code{change}
#' stores as a dummy whether data have been interpolated
#' @examples
#' # See \code{interpolate_data} source code

interpolate_group <- function(missingdata, df,
                              i = 1, year.var = 'year'){

  # RECOVERING GROUPS
  groupsvar <- missingdata %>% group_vars()

  # ROWS THAT WILL BE CHANGED
  index <- df[,groupsvar] %>% ungroup() %>%
    dplyr::mutate(n = row_number()) %>%
    filter_(paste(groupsvar,"==","\"",missingdata[i,groupsvar],
                  "\"", sep = "",
                  collapse = "&"))

  # EXTRACT ROWS AND COLUMNS CONCERNED
  dftointerpolate <- df[index$n,
                        as.character(
                          stringr::str_split(missingdata$x[i],pattern = ";",
                                             simplify = T))]

  # ENSURE WE DON'T HAVE EMPTY COLUMNS OR COLUMNS WITH ONLY ONE ELEMENT
  dftointerpolate <- dftointerpolate[!check.emptycolumn(dftointerpolate)]
  dftointerpolate <- dftointerpolate[
    ,sapply(names(dftointerpolate), function(nam) sum(!is.na(dftointerpolate[,nam])))>1
    ]

  # ENSURE TO ONLY INTERPOLATE NUMERIC VECTORS
  dftointerpolate <- dftointerpolate[,which(
    sapply(names(dftointerpolate), function(nam) is.numeric(unlist(df[,nam])))
    )]

  # INTERPOLATE USING ZOO PACKAGE
  if (ncol(dftointerpolate)>0){
    dfinterpolated <- lapply(1:ncol(dftointerpolate), function(j)
      zoo::na.approx(dftointerpolate[,j],rule = 2))
    dfinterpolated <- tbl_df(do.call(cbind,dfinterpolated))


  # CODING WE WILL USE FOR MATRIX STORING WHETHER DATA HAVE BEEN INTERPOLATE:
  # NA = NOT USED FOR INTERPOLATION
  # 0  = NOT INTERPOLATED BUT USED TO FILL OTHER VALUES
  # 1  = INTERPOLATED
  dftointerpolate <- sapply(1:ncol(dftointerpolate), function(j)
    as.numeric(is.na(dftointerpolate[,j])))

  } else{ # ONLY NON NUMERIC COLUMNS

    return(NULL)
  }

  # STORE IN LIST EVERYTHING THAT IS NEEDED
  resultinterpol <- list(lines = index$n,
                         cols = colnames(dfinterpolated),
    after = dfinterpolated,
    change = dftointerpolate)

  return(resultinterpol)

}

impute_NA <- function(df,list.interpo,
                      matrixNA,
                      index = 1, changedf = TRUE){

  if (changedf){
    df[list.interpo[[index]]$lines,list.interpo[[index]]$cols] <-
    list.interpo[[index]]$after
    return(df)
  } else{
#    colnames(matrixNA) <- colnames(df)
    matrixNA[list.interpo[[index]]$lines,
             which(colnames(df) %in% list.interpo[[index]]$cols)] <-
      list.interpo[[index]]$change
    return(matrixNA)
  }
}


interpolate_data <- function(df,groupingvar = 'Country_Transco',
                             threshold = 0.6, year.var = 'year',
                             label.var = c('ref_area','area',
                                           'Country_Transco','Zonier')){

  # DATAFRAME SUMMING UP THE CHANGE WE WILL DO
  df <- df %>% group_by_(.dots = groupingvar) %>%
    tidyr::nest() %>%
    dplyr::mutate(data2 = purrr::map2(data,year.var,
                                  label.var[!(label.var %in% groupingvar)],
                                  fill_dataframe)
                  ) # DON'T UNDERSTAND WHY, COLUMNS NOT FILLED

  # FILLING DATAFRAME USING LAPPLY
  df$data2 <-  lapply(1:length(df$data), function(i)
     fill_dataframe(df$data[[i]],year.var = year.var,
                    label.var = label.var[!(label.var %in% groupingvar)]))

  # UNNEST THE FILLED DATAFRAME
  df <- df %>% tidyr::unnest(data2)

  # COMPUTE MISSING VALUES PROPORTIONS
  missingdata <- count_NAs(df = df, groupingvar = groupingvar)
  missingdata <- missingdata %>% filter(p<threshold & p > 0)

  if (nrow(missingdata)==0){
    message("No imputation to process")
    return(NULL)
  }

    # KEEP ONE LINE BY GROUP
    missingdata <- missingdata %>% select(-p) %>%
      group_by_(.dots = groupingvar) %>%
      dplyr::do(x = paste(.$varia,collapse = ";")) %>%
      tidyr::unnest() %>% group_by_(.dots = groupingvar)

     list.interpo <- lapply(1:nrow(missingdata), function(i) try(interpolate_group(missingdata,
                                                                              df,i,
                                                                              year.var = year.var)))
     if (sum(sapply(list.interpo, is.null)>0)) list.interpo <- list.interpo[-which(sapply(list.interpo, is.null))]

     dfNA = data.frame(matrix(nrow = nrow(df), ncol = ncol(df)))
     colnames(dfNA) <- colnames(df)

     for (i in 1:length(list.interpo)){ #LAPPLY DOES NOT WORK
       dfNA <- impute_NA(df, list.interpo,
                         dfNA,
                         changedf = F, index = i)
     }

     for (i in 1:length(list.interpo)){
       df <- impute_NA(df, list.interpo,
                         dfNA,
                         changedf = T, index = i)
     }


     return(list(data = df,NAchange = dfNA))
}
