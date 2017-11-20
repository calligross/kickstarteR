#' kickstarterAddin
#'
#' @export
#' @import miniUI
#' @import shiny
#' @import rstudioapi
#' @import dplyr
#' @import reinstallr
#' @importFrom utils installed.packages
#'
#' @examples NULL
kickstarteRAddin <- function() {

  packageList <- getOption('kickstarteR.setup')
  allPackages <- unique(c(packageList$packages, unlist(packageList$sets, use.names = FALSE)))

  ui <- miniPage(
    gadgetTitleBar("kickstarteR"),
    miniTabstripPanel(selected = 'kickstarteR',
      miniTabPanel("Setup", icon = icon('sliders'),
        miniContentPanel(
          textInput('setup_path', 'Path to scan', value = getwd()),
          actionButton('setup_scan', 'Scan for packages to sort by usage'),
          textAreaInput('setup_options', label = '', resize = 'both'),
          checkboxGroupInput('setup_packages', '', choices = row.names(installed.packages()))
        )
      ),
      miniTabPanel('kickstarteR', icon = icon('sliders'),
        miniContentPanel(scrollable = TRUE,
          if (length(packageList$sets) > 0) {
            setChoices <- names(packageList$sets)

            names(setChoices) <- paste0(
              paste0(names(packageList$sets),': '),
              sapply(packageList$sets, function(x) {paste0(x, collapse = ', ')})
            )

            checkboxGroupInput('kickstarteR_packageSets', 'Sets', choices = setChoices)
          },
          checkboxGroupInput('kickstarteR_packages', 'Packages', choices = allPackages)
        )
      )
    )
  )

  server <- function(input, output, session) {

    observe({
      input$setup_packages

      if (length(input$setup_packages) > 0) {
        optionText <- paste0(
          'options(kickstarteR.setup = list(packages = c(',
            paste0("'", paste0(input$setup_packages, collapse = "', '"), "'"),
          ')))'
        )
      updateTextAreaInput(session, 'setup_options', value = optionText)
      }
    })

    observeEvent(input$setup_scan, {
      installed <- data.frame(package = row.names(installed.packages()), stringsAsFactors = FALSE)
      used <- reinstallr::show_package_stats(input$setup_path)
      used <- used[order(-used$n), ]
      used$rank <- 1:nrow(used)
      packages <- left_join(installed, used, by = 'package') %>%
        arrange(rank)

      packagesFound <- show_package_stats(path = input$setup_path)
      packagesFound <- packagesFound[order(-packagesFound$n), ]
      updateCheckboxGroupInput(session, 'setup_packages', choices = packages$package, selected = packageList$packages)
    })


    observe({
      if (length(packageList$sets) > 0) {
      input$kickstarteR_packageSets
      setsFlat <- do.call('c', packageList$sets)
      names(setsFlat) <- gsub('[0-9]+$', '', names(setsFlat))
      setsFlat <- setsFlat[names(setsFlat) %in% input$kickstarteR_packageSets]
      updateCheckboxGroupInput(session, 'kickstarteR_packages', selected = setsFlat)
      }
    })


    observeEvent(input$done, {
      packagesToLoad <- input$kickstarteR_packages

      for (i in packagesToLoad) {
        rstudioapi::insertText(paste0('library(', i, ')\n'))
      }
      invisible(stopApp())
    })

    observeEvent(input$cancel, {
      invisible(stopApp())
    })
  }


  viewer <- dialogViewer(dialogName = 'kickstarteR') #, width = 990, height = 900)
  runGadget(ui, server, stopOnCancel = FALSE, viewer = viewer)


}
