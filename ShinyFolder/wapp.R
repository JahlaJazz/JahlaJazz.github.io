
library(markdown)
library(caret)

# load the initial dataset
mydir <- "C:/Data Science Specialization - John Hopkins University/Course 8 - Practical Machine Learning/Project/"
build = read.csv(paste0(mydir,"training.csv"),stringsAsFactors = F)
build <- build[,-c(1:7)]
ind = sapply(build, function(x) x=="#DIV/0!" | x=="")
build[ind] <- NA 
colremove <- colSums(sapply(build,is.na))/(dim(build)[1]) > .95
build <- build[,!colremove]
build$classe <-as.factor(as.character(build$classe))  # create factor variable 


  ui <- fluidPage(
    navbarPage("App Title",
               tabPanel("Instructions", includeMarkdown("Instruction.md")),
               tabPanel("Select Data",
                        fluidRow(sliderInput("psplit", "Percentage of observations allocated to the training dataset:", 
                                             min = .1, max = .9, step = .05, value = .7)),
                        
                        fluidRow(sliderInput("nfold", "Select the number of folds for resampling:", 
                                             min = 3, max = 10, step = 1, value = 5)),
                        
                        fluidRow(sliderInput("ntree", "Select the depth of the trees:", 
                                             min = 5, max = 50, step = 5, value = 10)),
                        
                        fluidRow(column(3,checkboxGroupInput("variable1", "Select Predictor:",
                                                             names(build)[1:26])),
                                 column(6,checkboxGroupInput("variable2", "Select Predictor:",
                                                             names(build)[27:52]))
                                 )
                        ),
               tabPanel("Predictor Selected",DT::dataTableOutput("data")),
               tabPanel("Data Analysis",
                          h4("Build dataset after adjustments"),verbatimTextOutput("summary2"),
                          h4("Training dataset"),verbatimTextOutput("summary3"),
                          h4("Testing dataset"),verbatimTextOutput("summary4")),
               tabPanel("Summary", h4("Summary"), verbatimTextOutput("summary")),
               tabPanel("About", includeMarkdown("about.md"))
               )
      )
  
  
 
  server <- function(input, output) {
    
    
    
    predictorvariable <- function() {c(input$variable1,input$variable2)}
    output$data <- DT::renderDataTable({  matrix(predictorvariable(),ncol=1) })
    
    buildd <- function() {build[,c("classe",input$variable1,input$variable2)]}
    
    set.seed(1234)
    indext <- function() {createDataPartition( y = buildd()$classe, p = input$psplit, list = F)}
    training <- function() {buildd()[indext(),]}
    testing <- function() {buildd()[-indext(),]} 
    
    
    output$summary2 <- renderPrint({ dat <- buildd()
                                     str(dat)})
    output$summary3 <- renderPrint({ dat <- training()
                                     str(dat)})
    output$summary4 <- renderPrint({ dat <- testing()
                                     str(dat)})
    
  }
  
  shinyApp(ui, server)
 
