#'This is my submission of the Getting and Cleaning Data Course project.
#'The script produced in order to achieve the goals required by the assignment
#'is reported and commented in the following.
#'
#'### Downloading data (once only)
#'
#'First load the following packages that will be used to efficiently manipulate 
#'data in tables and to rearrange the structure of tables, making them _tidy_

library(data.table)
library(reshape2)

#'Datasets are supposed to be in a subdirectory of the working directory, 
#'called `UCI HAR Datase`

dir <- "UCI HAR Dataset"

#'If the directory does not exist, the zip file is downloaded and uncompressed, 
#'thus creating the directory. Then, the file can be deleted.

if (!file.exists(dir)) {
    message("Directory ",dir," not found. Data are going to be dowloaded...");
    download.file("https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip",
                "Dataset.zip", method="curl")
    unzip("Dataset.zip")
    file.remove("Dataset.zip")
    message("Data successfully downloaded and directory with data created.");
}

#'###Loading data into tables
#'
#'Read the training data sets with `read.table` and build `data.table` (`fread` made my RStudio crash).

train <- data.table(read.table(file.path(dir, "train", "X_train.txt")))
subjectTrain <- data.table(read.table(file.path(dir, "train", "subject_train.txt")))
activityTrain <- data.table(read.table(file.path(dir, "train", "y_train.txt")))

#'Then, similarly, read the test data sets.

test <- data.table(read.table(file.path(dir, "test", "X_test.txt")))
subjectTest <- data.table(read.table(file.path(dir, "test", "subject_test.txt")))
activityTest <- data.table(read.table(file.path(dir, "test", "y_test.txt")))

#'###Binding data tables
#'
#'Now, training and test data sets can be bound horizontally
subject <- rbind(subjectTrain, subjectTest)
activity <- rbind(activityTrain, activityTest)
dt <- rbind(train, test)

#'The only column of both the subject and activity table is renamed
setnames(subject, "V1", "subjectId")
setnames(activity, "V1", "activityId")

#'Now, the subject and activity tables (both having one only column) are vertically bound 
#'to the table with the observations (previously obtained by horizontally binding the 
#'training and test sets)
dt <- cbind(subject, activity, dt)

#'The key of the dt table, now containing the whole data set, is set, thus sorting the
#'rows sorted by subjectId and activityId
setkey(dt, subjectId, activityId)

#'Now, step 1 of the assignment is completed.

#'###Filtering the columns of the data set
#'
#'Let's load the names of the features
features <- data.table(read.table(file.path(dir, "features.txt")))
setnames(features, names(features), c("featureId", "featureName"))

#'Filter the rows representing the features by keeping only those corresponding to a mean or std, 
#'as required by step 2 of the assignment.
features <- features[grepl("mean\\(\\)|std\\(\\)", featureName)]

#'Create a new column containing codes "V"+id.
#'
#'These codes are also the names of the columuns of dt, starting from the 3rd
features$featureCode <- features[, paste0("V", featureId)]

#'Filter the columns of dt, keeping only the first two (representing the key)
#'and those corresponding to a mean or std value
dt <- dt[, c(key(dt), features$featureCode), with = FALSE]

#'Now the step 2 of the assignment is complete.

#'### Adding descriptive activity names
#'
#'Load the name of the activities
activityNames <- data.table(read.table(file.path(dir, "activity_labels.txt")))

#'Change the name of the columns
setnames(activityNames, names(activityNames), c("activityId", "activityName"))

#'Now, merge the dt table with the activity table, in order to 
#'have the descriptive name of the activity in the dt table
dt <- merge(dt, activityNames, by = "activityId")

#'Drop the activityId, that is no longer needed
dt <- dt[, names(dt)!="activityId", with=FALSE]

#'Redefine the key of dt
setkey(dt, subjectId, activityName)

#'Now, step 3 is complete.

#'### Adding descriptive feature names
#'
#'Change the name of the colums of dt using the actual name of the features, as required by step 4.
setnames(dt, features$featureCode, as.character(features$featureName))

#'### Creating a tidy data table with the average of each feature for each activity and each subject
#'
#'Reshape the dt by turning it into a tidy table with 4 columns, 
#'representing `subjectId`, `activityName`, `featureName`, and `value` 
#'of the observation
dt2 <- data.table(melt(dt, key(dt), variable.name = "featureName"))

#'Set the key of dt2
setkey(dt2, subjectId, activityName, featureName)

#'Now, find the average value of each feature and each pair (subjectId, activityName)
dt3 <- dt2[, mean(value), by = key(dt2)]

#'Rename last column
setnames(dt3, names(dt3)[4], c("mean"))

#'Save the data on disk
write.table(dt3, "tidy.txt", quote=FALSE, row.name=FALSE)

#'The README.md file can be automatically created using the
#'command `spin` to run this scrip: `spin("run_analysis.R")`
#'The `spin` command is available in the `knitr` package.