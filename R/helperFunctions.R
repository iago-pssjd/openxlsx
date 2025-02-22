



#' @name makeHyperlinkString
#' @title create Excel hyperlink string
#' @description Wrapper to create internal hyperlink string to pass to writeFormula()
#' @param sheet Name of a worksheet
#' @param row integer row number for hyperlink to link to
#' @param col column number of letter for hyperlink to link to
#' @param text display text 
#' @param file Excel file name to point to. If NULL hyperlink is internal.
#' @seealso \code{\link{writeFormula}}
#' @export makeHyperlinkString
#' @examples
#' 
#' ## Writing internal hyperlinks
#' wb <- createWorkbook()
#' addWorksheet(wb, "Sheet1")
#' addWorksheet(wb, "Sheet2")
#' addWorksheet(wb, "Sheet 3")
#' writeData(wb, sheet = 3, x = iris)
#' 
#' ## External Hyperlink
#' x <- c("https://www.google.com", "https://www.google.com.au")
#' names(x) <- c("google", "google Aus")
#' class(x) <- "hyperlink"
#' 
#' writeData(wb, sheet = 1, x = x, startCol = 10)
#' 
#' 
#' ## Internal Hyperlink - create hyperlink formula manually
#' writeFormula(wb, "Sheet1", x = '=HYPERLINK("#Sheet2!B3", "Text to Display - Link to Sheet2")'
#'   , startCol = 3)
#' 
#' ## Internal - No text to display using makeHyperlinkString() function
#' writeFormula(wb, "Sheet1", startRow = 1
#' , x = makeHyperlinkString(sheet = "Sheet 3", row = 1, col = 2))
#' 
#' ## Internal - Text to display
#' writeFormula(wb, "Sheet1", startRow = 2, 
#'   x = makeHyperlinkString(sheet = "Sheet 3", row = 1, col = 2
#'     , text = "Link to Sheet 3"))
#' 
#' ## Link to file - No text to display
#' writeFormula(wb, "Sheet1", startRow = 4
#'  , x = makeHyperlinkString(sheet = "testing", row = 3, col = 10
#'    , file = system.file("loadExample.xlsx", package = "openxlsx")))
#' 
#' ## Link to file - Text to display
#' writeFormula(wb, "Sheet1", startRow = 3
#'   , x = makeHyperlinkString(sheet = "testing", row = 3, col = 10
#'     , file = system.file("loadExample.xlsx", package = "openxlsx"), text = "Link to File."))
#' 
#' saveWorkbook(wb, "internalHyperlinks.xlsx")
makeHyperlinkString <- function(sheet, row = 1, col = 1, text = NULL, file = NULL){
  
  od <- getOption("OutDec")
  options("OutDec" = ".")
  on.exit(expr = options("OutDec" = od), add = TRUE)
  
  
  cell <- paste0(int2col(col), row)
  if(!is.null(file)){
    dest <- sprintf("[%s]'%s'!%s", file, sheet, cell)
  }else{
    dest <- sprintf("#'%s'!%s", sheet, cell)  
  }
  
  if(is.null(text)){
    str <- sprintf("=HYPERLINK(\"%s\")", dest)
  }else{
    str <- sprintf("=HYPERLINK(\"%s\", \"%s\")", dest, text)
  }
  
  return(str)
}


getRId <- function(x){
  regmatches(x, gregexpr('(?<= r:id=")[0-9A-Za-z]+', x, perl = TRUE))
}

getId <- function(x){
  regmatches(x, gregexpr('(?<= Id=")[0-9A-Za-z]+', x, perl = TRUE))
}



## creates style object based on column classes
## Used in writeData for styling when no borders and writeData table for all column-class based styling
classStyles <- function(wb, sheet, startRow, startCol, colNames, nRow, colClasses, stack = TRUE){
  
  sheet = wb$validateSheet(sheet)
  allColClasses <- unlist(colClasses, use.names = FALSE)
  rowInds <- (1 + startRow + colNames - 1L):(nRow + startRow + colNames - 1L)
  startCol <- startCol - 1L
  
  newStylesElements <- NULL
  names(colClasses) <- NULL
  
  if("hyperlink" %in% allColClasses){
    
    ## style hyperlinks
    inds <- which(sapply(colClasses, function(x) "hyperlink" %in% x))
    
    hyperlinkstyle <- createStyle(textDecoration = "underline")
    hyperlinkstyle$fontColour <- list("theme"="10")
    styleElements <- list("style" = hyperlinkstyle,
                          "sheet" =  wb$sheet_names[sheet],
                          "rows" = rep.int(rowInds, times = length(inds)),
                          "cols" = rep(inds + startCol, each = length(rowInds)))
    
    newStylesElements <- append(newStylesElements, list(styleElements))
    
  }
  
  if("date" %in% allColClasses){
    
    ## style dates
    inds <- which(sapply(colClasses, function(x) "date" %in% x)) 
    
    styleElements <- list("style" = createStyle(numFmt = "date"),
                          "sheet" =  wb$sheet_names[sheet],
                          "rows" = rep.int(rowInds, times = length(inds)),
                          "cols" = rep(inds + startCol, each = length(rowInds)))
    
    newStylesElements <- append(newStylesElements, list(styleElements))
    
  }
  
  if(any(c("posixlt", "posixct", "posixt") %in% allColClasses)){
    
    ## style POSIX
    inds <- which(sapply(colClasses, function(x) any(c("posixct", "posixt", "posixlt") %in% x)))
    
    styleElements <- list("style" = createStyle(numFmt = "LONGDATE"),
                          "sheet" =  wb$sheet_names[sheet],
                          "rows" = rep.int(rowInds, times = length(inds)),
                          "cols" = rep(inds + startCol, each = length(rowInds)))
    
    newStylesElements <- append(newStylesElements, list(styleElements))
    
  }
  
  
  ## style currency as CURRENCY
  if("currency" %in% allColClasses){
    inds <- which(sapply(colClasses, function(x) "currency" %in% x))
    
    styleElements <- list("style" = createStyle(numFmt = "CURRENCY"),
                          "sheet" =  wb$sheet_names[sheet],
                          "rows" = rep.int(rowInds, times = length(inds)),
                          "cols" = rep(inds + startCol, each = length(rowInds)))
    
    newStylesElements <- append(newStylesElements, list(styleElements))
  }
  
  ## style accounting as ACCOUNTING
  if("accounting" %in% allColClasses){
    inds <- which(sapply(colClasses, function(x) "accounting" %in% x))
    
    styleElements <- list("style" = createStyle(numFmt = "ACCOUNTING"),
                          "sheet" =  wb$sheet_names[sheet],
                          "rows" = rep.int(rowInds, times = length(inds)),
                          "cols" = rep(inds + startCol, each = length(rowInds)))
    
    newStylesElements <- append(newStylesElements, list(styleElements))
    
  }
  
  ## style percentages
  if("percentage" %in% allColClasses){
    inds <- which(sapply(colClasses, function(x) "percentage" %in% x))
    
    styleElements <- list("style" = createStyle(numFmt = "percentage"),
                          "sheet" =  wb$sheet_names[sheet],
                          "rows" = rep.int(rowInds, times = length(inds)),
                          "cols" = rep(inds + startCol, each = length(rowInds)))
    
    newStylesElements <- append(newStylesElements, list(styleElements))
  }
  
  ## style big mark
  if("scientific" %in% allColClasses){
    inds <- which(sapply(colClasses, function(x) "scientific" %in% x))
    
    styleElements <- list("style" = createStyle(numFmt = "scientific"),
                          "sheet" =  wb$sheet_names[sheet],
                          "rows" = rep.int(rowInds, times = length(inds)),
                          "cols" = rep(inds + startCol, each = length(rowInds)))
    
    newStylesElements <- append(newStylesElements, list(styleElements))
  }
  
  ## style big mark
  if("3" %in% allColClasses | "comma" %in% allColClasses){
    inds <- which(sapply(colClasses, function(x) "3" %in% tolower(x) | "comma" %in% tolower(x)))
    
    styleElements <- list("style" = createStyle(numFmt = "3"),
                          "sheet" =  wb$sheet_names[sheet],
                          "rows" = rep.int(rowInds, times = length(inds)),
                          "cols" = rep(inds + startCol, each = length(rowInds)))
    
    newStylesElements <- append(newStylesElements, list(styleElements))
  }
  
  ## numeric sigfigs (Col must be numeric and numFmt options must only have 0s and \\.)
  if("numeric" %in% allColClasses & !grepl("[^0\\.,#\\$\\* %]", getOption("openxlsx.numFmt", "GENERAL")) ){
    inds <- which(sapply(colClasses, function(x) "numeric" %in% tolower(x)))
    
    styleElements <- list("style" = createStyle(numFmt = getOption("openxlsx.numFmt", "0")),
                          "sheet" =  wb$sheet_names[sheet],
                          "rows" = rep.int(rowInds, times = length(inds)),
                          "cols" = rep(inds + startCol, each = length(rowInds)))
    
    newStylesElements <- append(newStylesElements, list(styleElements))
  }
  
  
  if(!is.null(newStylesElements)){
    
    if(stack){
      
      for(i in 1:length(newStylesElements)){
        wb$addStyle(sheet = sheet
                    , style = newStylesElements[[i]]$style
                    , rows = newStylesElements[[i]]$rows
                    , cols = newStylesElements[[i]]$cols, stack = TRUE)
      }
      
      
    }else{
      wb$styleObjects <- append(wb$styleObjects, newStylesElements)
    }
    
  }
  
  
  
  invisible(1)
  
}














validateColour <- function(colour, errorMsg = "Invalid colour!"){
  
  ## check if
  if(is.null(colour))
    colour = "black"
  
  validColours <- colours()
  
  if(any(colour %in% validColours))
    colour[colour %in% validColours] <- col2hex(colour[colour %in% validColours])
  
  if(any(!grepl("^#[A-Fa-f0-9]{6}$", colour)))
    stop(errorMsg, call.=FALSE)
  
  colour <- gsub("^#", "FF", toupper(colour))
  
  return(colour)
  
}

## color helper function: eg col2hex(colors())
col2hex <- function(my.col) {
  rgb(t(col2rgb(my.col)), maxColorValue = 255)
}


## header and footer replacements
headerFooterSub <- function(x){
  
  if(!is.null(x)){
    x <- replaceIllegalCharacters(x)
    x <- gsub("\\[Page\\]", "P", x)
    x <- gsub("\\[Pages\\]", "N", x)
    x <- gsub("\\[Date\\]", "D", x)
    x <- gsub("\\[Time\\]", "T", x)
    x <- gsub("\\[Path\\]", "Z", x)
    x <- gsub("\\[File\\]", "F", x)
    x <- gsub("\\[Tab\\]", "A", x)
  }
  
  return(x)
  
}


writeCommentXML <- function(comment_list, file_name){
  
  
  authors <- unique(sapply(comment_list, "[[", "author"))
  xml <- '<comments xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
  xml <- c(xml, paste0('<authors>', paste(sprintf('<author>%s</author>', authors), collapse = ""), '</authors><commentList>'))
  
  
  for(i in 1:length(comment_list)){
    
    authorInd <- which(authors == comment_list[[i]]$author) - 1L
    xml <- c(xml, sprintf('<comment ref="%s" authorId="%s" shapeId="0"><text>', comment_list[[i]]$ref, authorInd))
    
    for(j in 1:length(comment_list[[i]]$comment))
      xml <- c(xml, sprintf('<r>%s<t xml:space="preserve">%s</t></r>', comment_list[[i]]$style[[j]], comment_list[[i]]$comment[[j]]))
    
    xml <- c(xml, '</text></comment>')
    
  }
  
  write_file(body = paste(xml, collapse = ""), tail = '</commentList></comments>', fl = file_name)
  
  NULL
  
}



replaceIllegalCharacters <- function(v){
  
  vEnc <- Encoding(v)
  v <- as.character(v)
  
  flg <- vEnc != "UTF-8"
  if(any(flg))
    v[flg] <- iconv(v[flg], from = "", to = "UTF-8")
  
  v <- gsub('&', "&amp;", v, fixed = TRUE)
  v <- gsub('"', "&quot;", v, fixed = TRUE)
  v <- gsub("'", "&apos;", v, fixed = TRUE)
  v <- gsub('<', "&lt;", v, fixed = TRUE)
  v <- gsub('>', "&gt;", v, fixed = TRUE)
  
  ## Escape sequences
  v <- gsub("\a", "", v, fixed = TRUE)
  v <- gsub("\b", "", v, fixed = TRUE)
  v <- gsub("\v", "", v, fixed = TRUE)
  v <- gsub("\f", "", v, fixed = TRUE)
  
  return(v)
}


replaceXMLEntities <- function(v){
  
  v <- gsub("&amp;", "&", v, fixed = TRUE)
  v <- gsub("&quot;", '"', v, fixed = TRUE)
  v <- gsub("&apos;", "'", v, fixed = TRUE)
  v <- gsub("&lt;", "<", v, fixed = TRUE)
  v <- gsub("&gt;", ">", v, fixed = TRUE)
  
  return(v)
}


pxml <- function(x){
  paste(unique(unlist(x)), collapse = "")
}


removeHeadTag <- function(x){
  
  x <- paste(x, collapse = "")
  
  if(any(grepl("<\\?", x)))
    x <- gsub("<\\?xml [^>]+", "", x)
  
  x <- gsub("^>", "", x)
  x
  
}



validateBorderStyle <- function(borderStyle){
  
  
  valid <- c("none", "thin", "medium", "dashed", "dotted", "thick", "double", "hair", "mediumDashed", 
             "dashDot", "mediumDashDot", "dashDotDot", "mediumDashDotDot", "slantDashDot")
  
  ind <- match(tolower(borderStyle), tolower(valid))
  if(any(is.na(ind)))
    stop("Invalid borderStyle", call. = FALSE)
  
  return(valid[ind])
  
}





getAttrsFont <- function(xml, tag){
  
  
  x <- lapply(xml, getChildlessNode, tag = tag)
  x[sapply(x, length) == 0] <- ""
  x <- unlist(x)
  a <- lapply(x, function(x) unlist(regmatches(x, gregexpr('[a-zA-Z]+=".*?"', x))))
  
  nms = lapply(a, function(xml) regmatches(xml, regexpr('[a-zA-Z]+(?=\\=".*?")', xml, perl = TRUE)))
  vals =  lapply(a, function(xml) regmatches(xml, regexpr('(?<=").*?(?=")', xml, perl = TRUE)))
  vals <- lapply(vals, function(x) {Encoding(x) <- "UTF-8"; x})
  vals <- lapply(1:length(vals), function(i){ names(vals[[i]]) <- nms[[i]]; vals[[i]]})
  
  return(vals)
  
}

getAttrs <- function(xml, tag){
  
  x <- lapply(xml, getChildlessNode, tag = tag)
  x[sapply(x, length) == 0] <- ""
  a <- lapply(x, function(x) regmatches(x, regexpr('[a-zA-Z]+=".*?"', x)))
  
  names = lapply(a, function(xml) regmatches(xml, regexpr('[a-zA-Z]+(?=\\=".*?")', xml, perl = TRUE)))
  vals =  lapply(a, function(xml) regmatches(xml, regexpr('(?<=").*?(?=")', xml, perl = TRUE)))
  vals <- lapply(vals, function(x) {Encoding(x) <- "UTF-8"; x})
  
  names(vals) <- names
  return(vals)
  
}


buildFontList <- function(fonts){
  
  sz <- getAttrs(fonts, "<sz ")
  colour <- getAttrsFont(fonts, "<color ")
  name <- getAttrs(fonts, tag = "<name ")
  family <- getAttrs(fonts, "<family ")
  scheme <- getAttrs(fonts, "<scheme ")
  
  italic <- lapply(fonts, getChildlessNode, tag = "<i")
  bold <- lapply(fonts, getChildlessNode, tag = "<b")
  underline <- lapply(fonts, getChildlessNode, tag = "<u")
  
  ## Build font objects
  ft <- replicate(list(), n=length(fonts))
  for(i in 1:length(fonts)){
    
    f <- NULL
    nms <- NULL
    if(length(unlist(sz[i])) > 0){
      f <- c(f, sz[i])
      nms <- c(nms, "sz")     
    }
    
    if(length(unlist(colour[i])) > 0){
      f <- c(f, colour[i])
      nms <- c(nms, "color")  
    }
    
    if(length(unlist(name[i])) > 0){
      f <- c(f, name[i])
      nms <- c(nms, "name") 
    }
    
    if(length(unlist(family[i])) > 0){
      f <- c(f, family[i])
      nms <- c(nms, "family") 
    }
    
    if(length(unlist(scheme[i])) > 0){
      f <- c(f, scheme[i])
      nms <- c(nms, "scheme") 
    }
    
    if(length(italic[[i]]) > 0){
      f <- c(f, "italic")
      nms <- c(nms, "italic") 
    }
    
    if(length(bold[[i]]) > 0){
      f <- c(f, "bold")
      nms <- c(nms, "bold") 
    }
    
    if(length(underline[[i]]) > 0){
      f <- c(f, "underline")
      nms <- c(nms, "underline") 
    }
    
    f <- lapply(1:length(f), function(i) unlist(f[i]))
    names(f) <- nms
    
    ft[[i]] <- f
    
  }
  
  ft
  
}



get_named_regions_from_string <- function(dn){
  
  dn <- gsub("</definedNames>", "", dn, fixed = TRUE)
  dn <- gsub("</workbook>", "", dn, fixed = TRUE)
  
  dn <- unique(unlist(strsplit(dn, split = "</definedName>", fixed = TRUE)))
  dn <- dn[grepl("<definedName", dn, fixed=TRUE)]
  
  dn_names <- regmatches(dn, regexpr('(?<=name=")[^"]+', dn, perl = TRUE))
  
  dn_pos <- regmatches(dn, regexpr("(?<=>).*", dn, perl = TRUE))
  dn_pos <- gsub("[$']", "", dn_pos)
  
  has_bang <- grepl("!", dn_pos, fixed=TRUE)
  dn_sheets <- ifelse(has_bang,
                      gsub("^(.*)!.*$", "\\1", dn_pos),
                      "")
  dn_coords <- ifelse(has_bang,
                      gsub("^.*!(.*)$", "\\1", dn_pos),
                      "")
  
  attr(dn_names, "sheet") <- dn_sheets
  attr(dn_names, "position") <- dn_coords
  
  return(dn_names)
  
}



nodeAttributes <- function(x){
  
  
  x <- paste0("<", unlist(strsplit(x, split = "<")))
  x <- x[grepl("<bgColor|<fgColor", x)]
  
  if(length(x) == 0)
    return("")
  
  attrs <- regmatches(x, gregexpr(' [a-zA-Z]+="[^"]*', x, perl =  TRUE))
  tags <- regmatches(x, gregexpr('<[a-zA-Z]+ ', x, perl =  TRUE))
  tags <- lapply(tags, gsub, pattern = "<| ", replacement = "")  
  attrs <- lapply(attrs, gsub, pattern = '"', replacement = "")      
  
  attrs <- lapply(attrs, strsplit, split = "=")
  for(i in 1:length(attrs)){
    nms <- lapply(attrs[[i]], "[[", 1)
    vals <- lapply(attrs[[i]], "[[", 2)
    a <- unlist(vals)
    names(a) <- unlist(nms)
    attrs[[i]] <- a
  }
  
  names(attrs) <- unlist(tags)
  
  attrs
}


buildBorder <- function(x){
  
  style <- list()
  if(grepl('diagonalup="1"', tolower(x), fixed = TRUE))
    style$borderDiagonalUp <- TRUE
  
  if(grepl('diagonaldown="1"', tolower(x), fixed = TRUE))
    style$borderDiagonalDown <- TRUE
  
  ## gets all borders that have children
  x <- unlist(lapply(c("<left", "<right", "<top", "<bottom", "<diagonal"), function(tag) getNodes(xml = x, tagIn = tag)))
  if(length(x) == 0)
    return(NULL)
  
  sides <- c("TOP", "BOTTOM", "LEFT", "RIGHT", "DIAGONAL")
  sideBorder <- character(length = length(x))
  for(i in 1:length(x)){
    tmp <- sides[sapply(sides, function(s) grepl(s, x[[i]], ignore.case = TRUE))]
    if(length(tmp) > 1) tmp <- tmp[[1]]
    if(length(tmp) == 1)
      sideBorder[[i]] <- tmp
  }
  
  sideBorder <- sideBorder[sideBorder != ""]
  x <- x[sideBorder != ""]
  if(length(sideBorder) == 0)
    return(NULL)
  
  
  ## style
  weight <- gsub('style=|"', "", regmatches(x, regexpr('style="[a-z]+"', x, perl = TRUE, ignore.case = TRUE)))
  
  
  ## Colours
  cols <- replicate(n = length(sideBorder), list(rgb = "FF000000"))
  colNodes <- unlist(sapply(x, getChildlessNode, tag = "<color", USE.NAMES = FALSE))
  
  if(length(colNodes) > 0){
    attrs <- regmatches(colNodes, regexpr('(theme|indexed|rgb|auto)=".+"', colNodes))
  }else{
    attrs <- NULL
  }
  
  if(length(attrs) != length(x)){
    return(
      list("borders" = paste(sideBorder, collapse = ""),
           "colour" = cols)
    ) 
  }
  
  attrs <- strsplit(attrs, split = "=")
  cols <- sapply(attrs, function(attr){
    
    if(length(attr) == 2){
      y <- list(gsub('"', "", attr[2]))
      names(y) <- gsub(" ", "", attr[[1]])
    }else{
      tmp <- paste(attr[-1], collapse = "=")
      y <- gsub('^"|"$', "", tmp)  
      names(y) <- gsub(" ", "", attr[[1]])
    }
    return(y)
  })
  
  ## sideBorder & cols
  if("LEFT" %in% sideBorder){
    style$borderLeft <- weight[which(sideBorder == "LEFT")]
    style$borderLeftColour <- cols[which(sideBorder == "LEFT")]
  }
  
  if("RIGHT" %in% sideBorder){
    style$borderRight <- weight[which(sideBorder == "RIGHT")]
    style$borderRightColour <- cols[which(sideBorder == "RIGHT")]
  }
  
  if("TOP" %in% sideBorder){
    style$borderTop <- weight[which(sideBorder == "TOP")]
    style$borderTopColour <- cols[which(sideBorder == "TOP")]
  }
  
  if("BOTTOM" %in% sideBorder){
    style$borderBottom <- weight[which(sideBorder == "BOTTOM")]
    style$borderBottomColour <- cols[which(sideBorder == "BOTTOM")]
  }
  
  if("DIAGONAL" %in% sideBorder){
    style$borderDiagonal <- weight[which(sideBorder == "DIAGONAL")]
    style$borderDiagonalColour <- cols[which(sideBorder == "DIAGONAL")]
  }
  
  return(style)
}




genHeaderFooterNode <- function(x){
  
  # <headerFooter differentOddEven="1" differentFirst="1" scaleWithDoc="0" alignWithMargins="0">
  #   <oddHeader>&amp;Lfirst L&amp;CfC&amp;RfR</oddHeader>
  #   <oddFooter>&amp;LfFootL&amp;CfFootC&amp;RfFootR</oddFooter>
  #   <evenHeader>&amp;LTIS&amp;CIS&amp;REVEN H</evenHeader>
  #   <evenFooter>&amp;LEVEN L F&amp;CEVEN C F&amp;REVEN RIGHT F</evenFooter>
  #   <firstHeader>&amp;L&amp;P&amp;Cfirst C&amp;Rfirst R</firstHeader>
  #   <firstFooter>&amp;Lfirst L Foot&amp;Cfirst C Foot&amp;Rfirst R Foot</firstFooter>
  #   </headerFooter>
  
  ## ODD
  if(length(x$oddHeader) > 0){
    oddHeader <- paste0('<oddHeader>', sprintf('&amp;L%s', x$oddHeader[[1]]), sprintf('&amp;C%s', x$oddHeader[[2]]), sprintf('&amp;R%s', x$oddHeader[[3]]), '</oddHeader>', collapse = "")
  }else{
    oddHeader <- NULL
  }
  
  if(length(x$oddFooter) > 0){
    oddFooter <- paste0('<oddFooter>', sprintf('&amp;L%s', x$oddFooter[[1]]), sprintf('&amp;C%s', x$oddFooter[[2]]), sprintf('&amp;R%s', x$oddFooter[[3]]), '</oddFooter>', collapse = "")
  }else{
    oddFooter <- NULL
  }
  
  ## EVEN
  if(length(x$evenHeader) > 0){
    evenHeader <- paste0('<evenHeader>', sprintf('&amp;L%s', x$evenHeader[[1]]), sprintf('&amp;C%s', x$evenHeader[[2]]), sprintf('&amp;R%s', x$evenHeader[[3]]), '</evenHeader>', collapse = "")
  }else{
    evenHeader <- NULL
  }
  
  if(length(x$evenFooter) > 0){
    evenFooter <- paste0('<evenFooter>', sprintf('&amp;L%s', x$evenFooter[[1]]), sprintf('&amp;C%s', x$evenFooter[[2]]), sprintf('&amp;R%s', x$evenFooter[[3]]), '</evenFooter>', collapse = "")
  }else{
    evenFooter <- NULL
  }
  
  ## FIRST
  if(length(x$firstHeader) > 0){
    firstHeader <- paste0('<firstHeader>', sprintf('&amp;L%s', x$firstHeader[[1]]), sprintf('&amp;C%s', x$firstHeader[[2]]), sprintf('&amp;R%s', x$firstHeader[[3]]), '</firstHeader>', collapse = "")
  }else{
    firstHeader <- NULL
  }
  
  if(length(x$firstFooter) > 0){
    firstFooter <- paste0('<firstFooter>', sprintf('&amp;L%s', x$firstFooter[[1]]), sprintf('&amp;C%s', x$firstFooter[[2]]), sprintf('&amp;R%s', x$firstFooter[[3]]), '</firstFooter>', collapse = "")
  }else{
    firstFooter <- NULL
  }
  
  
  headTag <- sprintf('<headerFooter differentOddEven="%s" differentFirst="%s" scaleWithDoc="0" alignWithMargins="0">',
                     as.integer(!(is.null(evenHeader) & is.null(evenFooter))),
                     as.integer(!(is.null(firstHeader) & is.null(firstFooter))))
  
  paste0(headTag, oddHeader, oddFooter, evenHeader, evenFooter, firstHeader, firstFooter, "</headerFooter>")
  
}


buildFillList <- function(fills){
  
  
  fillAttrs <- rep(list(list()), length(fills))
  
  ## patternFill
  inds <- grepl("patternFill", fills)
  fillAttrs[inds] <- lapply(fills[inds], nodeAttributes)
  
  ## gradientFill
  inds <- grepl("gradientFill", fills)
  fillAttrs[inds] <- fills[inds]
  
  return(fillAttrs)
  
}


getDefinedNamesSheet <- function(x){
  
  belongTo <- unlist(lapply(strsplit(x, split = ">|<"), "[[", 3))
  quoted <- grepl("^'", belongTo)
  
  belongTo[quoted] <- regmatches(belongTo[quoted], regexpr("(?<=').*(?='!)", belongTo[quoted], perl = TRUE))
  belongTo[!quoted] <- gsub("!\\$[A-Z0-9].*", "", belongTo[!quoted])
  belongTo[!quoted] <- gsub("!#REF!.*", "", belongTo[!quoted])
  
  return(belongTo)
  
}


getSharedStringsFromFile <- function(sharedStringsFile, isFile){
  
  ## read in, get si tags, get t tag value and  pull out all string nodes
  sharedStrings = get_shared_strings(xmlFile = sharedStringsFile, isFile = isFile) ## read from file
  
  
  Encoding(sharedStrings) <- "UTF-8"
  z <- tolower(sharedStrings)
  sharedStrings[z == "true"] <- "TRUE"
  sharedStrings[z == "false"] <- "FALSE"
  z <- NULL ## effectivel remove z
  
  ## XML replacements
  sharedStrings <- replaceXMLEntities(sharedStrings)
  
  return(sharedStrings)
  
}


clean_names <- function(x,schar){
  x <- gsub("^[[:space:]]+|[[:space:]]+$", "", x)
  x <- gsub("[[:space:]]+", schar, x)
  return(x)
}



mergeCell2mapping <- function(x){
  
  refs <- regmatches(x, regexpr("(?<=ref=\")[A-Z0-9:]+", x, perl = TRUE))
  refs <- strsplit(refs, split = ":")
  rows <- lapply(refs, function(r) {
    r <- as.integer(gsub(pattern = "[A-Z]", replacement = "", r, perl = TRUE))
    seq(from = r[1], to = r[2], by = 1)
  })
  
  cols <- lapply(refs, function(r) {
    r <- convertFromExcelRef(r)
    seq(from = r[1], to = r[2], by = 1)
  })
  
  ## for each we grid.expand
  refs <- do.call("rbind", lapply(1:length(rows), function(i){
    tmp <- expand.grid("cols" = cols[[i]], "rows" = rows[[i]])
    tmp$ref <- paste0(convert_to_excel_ref(cols = tmp$cols, LETTERS = LETTERS), tmp$rows)
    tmp$anchor_cell <- tmp$ref[1]
    return(tmp[, c("anchor_cell", "ref", "rows")])
  }))
  
  
  refs <- refs[refs$anchor_cell != refs$ref,  ]
  
  return(refs)
}




splitHeaderFooter <- function(x){
  
  tmp <- gsub("<(/|)(odd|even|first)(Header|Footer)>(&amp;|)", "", x, perl = TRUE)
  special_tags <- regmatches(tmp, regexpr("&amp;[^LCR]", tmp))
  if(length(special_tags) > 0){
    for(i in 1:length(special_tags))
      tmp <- gsub(special_tags[i], sprintf("openxlsx__%s67298679", i), tmp, fixed = TRUE)
  }
  
  tmp <- strsplit(tmp, split = "&amp;")[[1]]
  
  if(length(special_tags) > 0){
    for(i in 1:length(special_tags))
      tmp <- gsub(sprintf("openxlsx__%s67298679", i), special_tags[i], tmp, fixed = TRUE)
  }
  
  
  res <- rep(list(NULL), 3)
  ind <- substr(tmp, 1, 1) == "L"
  if(any(ind))
    res[[1]] = substring(tmp, 2)[ind]
  
  ind <- substr(tmp, 1, 1) == "C"
  if(any(ind))
    res[[2]] = substring(tmp, 2)[ind]
  
  ind <- substr(tmp, 1, 1) == "R"
  if(any(ind))
    res[[3]] = substring(tmp, 2)[ind]
  
  res
  
}




getFile <- function(xlsxFile){
  
  ## Is this a file or URL (code taken from read.table())
  on.exit(try(close(fl), silent = TRUE), add = TRUE)
  fl <- file(description = xlsxFile)
  
  ## If URL download
  if("url" %in% class(fl)){
    tmpFile <- tempfile(fileext = ".xlsx")
    download.file(url = xlsxFile, destfile = tmpFile, cacheOK = FALSE,  mode = "wb", quiet = TRUE)
    xlsxFile <- tmpFile
  }
  
  return(xlsxFile)
  
}

# Rotate the 15-bit integer by n bits to the 
hashPassword <- function(password) {
  # password limited to 15 characters
  chars = head(strsplit(password, "")[[1]], 15)
  # See OpenOffice's documentation of the Excel format: http://www.openoffice.org/sc/excelfileformat.pdf
  # Start from the last character and for each character
  # - XOR hash with the ASCII character code
  # - rotate hash (16 bits) one bit to the left
  # Finally, XOR hash with 0xCE4B and XOR with password length
  # Output as hex (uppercase)
  rotate16bit <- function(hash, n = 1) {
    bitwOr(bitwAnd(bitwShiftR(hash, 15 - n), 0x01), bitwAnd(bitwShiftL(hash, n), 0x7fff));
  }
  hash = Reduce(function(char, h) {
    h = bitwXor(h, as.integer(charToRaw(char)))
    rotate16bit(h, 1)
  }, chars, 0, right = TRUE)
  hash = bitwXor(bitwXor(hash, length(chars)), 0xCE4B)
  format(as.hexmode(hash), upper.case = TRUE)
}