
library(markdown)
library(caret)
library(lattice)
library(ggplot2)
library(randomForest)

# load the initial dataset

build = read.csv("data/training.csv",stringsAsFactors = F)
build <- build[,-c(1:7)]
ind = sapply(build, function(x) x=="#DIV/0!" | x=="")
build[ind] <- NA 
colremove <- colSums(sapply(build,is.na))/(dim(build)[1]) > .95
build <- build[,!colremove]
build$classe <-as.factor(as.character(build$classe))  # create factor variable 

 
validation = read.csv("data/validation.csv",stringsAsFactors = F)
validation <- validation[,-c(1:7)]
ind = sapply(validation, function(x) x=="#DIV/0!" | x=="")
validation[ind] <- NA
colremove <- colSums(sapply(validation,is.na))/(dim(validation)[1]) > .95
validation <- validation[,!colremove] 
validation$problem_id <- as.factor(as.character(validation$problem_id))


  ui <- fluidPage(
    navbarPage("What if Analysis",
               tabPanel("Instructions", includeMarkdown("Instruction.md")),
               tabPanel("Select Data",
                        fluidRow(sliderInput("psplit", "Percentage of observations allocated to the training dataset:", 
                                             min = .1, max = .9, step = .05, value = .7)),
                        
                        fluidRow(sliderInput("nfold", "Select the number of folds for resampling:", 
                                             min = 3, max = 10, step = 1, value = 5)),
                        
                        fluidRow(sliderInput("ntreep", "Select the depth of the trees:", 
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
               tabPanel("Regression Summary", 
                        h3("Please given this a few seconds to appear:"),
                         
                        h4("Fitted Model:"), verbatimTextOutput("fitmodel"),
                         
                        h4("Visual representation of relationship between the number of predictor and accuracy:"), plotOutput("modelplot"),
                        
                        h4("Relative Importance of Predictors Selected"), verbatimTextOutput("varimp"),
                        
                        h4("Confusion Matrix and Statistics:"), verbatimTextOutput("confmat"),
                        
                        h4("Resulting predicts based upon the validation dataset:"), verbatimTextOutput("result")
                        ),
               tabPanel("About", includeMarkdown("about.md"))
               )
      )
  
  
 
  server <- function(input, output) {
    
    
    
    predictorvariable <- function() {c(input$variable1,input$variable2)}
    output$data <- DT::renderDataTable({  matrix(predictorvariable(),ncol=1) })
    
    buildd <- function() {build[,c("classe",input$variable1,input$variable2)]}
    valid <- function() { validation[,c("problem_id", input$variable1, input$variable2 )]}
    
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
    
    fitrf <- reactive( {fitControl <- trainControl(method = "cv", number = input$nfold)
                       train(classe ~ ., data = training(), trControl = fitControl, method = "rf", ntree = input$ntreep)})
    
    output$fitmodel <- renderPrint({fitrf()})
    
    output$modelplot <- renderPlot({plot(fitrf())})
    
    output$varimp <- renderPrint({  varImp(fitrf())   })
    
    pred <- reactive({ predict(fitrf(), newdata = testing()) })
    
    conf <- reactive({  confusionMatrix(pred(), testing()$classe ) })
    
    output$confmat <- renderPrint({ conf() })
    
    predv <- reactive({ predict(fitrf(), newdata = valid()) })
    
    resultsv <- reactive({ data.frame(problem_id = valid()$problem_id, predicted = predv()) }) 
    
    output$result <- renderPrint({ resultsv() })
    
  }
  
  shinyApp(ui, server)
 
