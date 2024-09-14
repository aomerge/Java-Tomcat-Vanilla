#!/bin/bash

# Variables
PROJECT_NAME="app"
TOMCAT_HOME="./apache-tomcat-9.0.94"
JAVA_REQUIRED_VERSION="17"
SRC_DIR="src"
WEB_DIR="web"
BUILD_DIR="./bin/build"
CONTROLLERS_DIR="$SRC_DIR/com/$PROJECT_NAME/controllers"
WAR_FILE="$BUILD_DIR/$PROJECT_NAME.war"
HASH_FILE="./bin/logs/file_hashes.txt"
COMPILE_ERRORS_FILE="compile_errors.txt"
LIBS_DIR="./libs"  # Directory where dependencies (JARs) are located
CLASSPATH="$LIBS_DIR/*"

# Functions

check_java_home() {
    # Check if JAVA_HOME is set
    if [ -z "$JAVA_HOME" ]; then
        echo "Error: JAVA_HOME is not set."
        exit 1
    fi
}

verify_java_version() {
    # Verify the Java version
    JAVA_VERSION=$("$JAVA_HOME/bin/java" -version 2>&1 | awk -F[\".] 'NR==1 {print $2}')

    if [ "$JAVA_VERSION" -ne "$JAVA_REQUIRED_VERSION" ]; then
        echo "Error: Java $JAVA_REQUIRED_VERSION is required, but found Java $JAVA_VERSION."
        exit 1
    fi
}

clean_build_directory() {
    echo "Cleaning and preparing the build directory..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR/WEB-INF/lib"
    mkdir -p "$BUILD_DIR/WEB-INF/classes"
}

verify_required_directories() {
    # Check if required directories exist
    if [ ! -d "$CONTROLLERS_DIR" ]; then
        echo "Error: Directory not found: $CONTROLLERS_DIR"
        exit 1
    fi

    if [ ! -f "$TOMCAT_HOME/lib/servlet-api.jar" ]; then
        echo "Error: servlet-api.jar not found in $TOMCAT_HOME/lib"
        exit 1
    fi
}

compile_java_files() {
    # Compile all .java files
    echo "Compiling Java files in $CONTROLLERS_DIR..."
    find "$SRC_DIR" -name "*.java" > ./bin/logs/sources.txt
    javac -cp "$CLASSPATH" -d "$BUILD_DIR/WEB-INF/classes" @"./bin/logs/sources.txt" 2> ./bin/logs/compile_errors.txt

    # Check if the compilation had errors
    if [ $? -ne 0 ]; then
        echo "Compilation errors found:"
        cat ./bin/logs/compile_errors.txt
        exit 1
    else
        echo "Compilation successful."
    fi

    # Verify if the build directory was created
    if [ ! -d "$BUILD_DIR/WEB-INF/classes" ]; then
        echo "Error: The build directory was not created properly."
        exit 1
    fi
}

copy_web_files() {
    # Copy web files (HTML, CSS, JS)
    echo "Copying web files from $WEB_DIR to $BUILD_DIR..."
    cp -r "$WEB_DIR/"* "$BUILD_DIR/"
}

copy_dependencies() {
    # Copy dependencies (JARs) to WEB-INF/lib
    echo "Copying dependencies to WEB-INF/lib..."
    cp "$LIBS_DIR"/*.jar "$BUILD_DIR/WEB-INF/lib/"
}

package_project() {
    # Package the project into a WAR file
    echo "Packaging the project into a WAR file..."
    jar cvf "$WAR_FILE" -C "$BUILD_DIR" .
}

deploy_to_tomcat() {
    # Clean the Tomcat webapps directory
    echo "Cleaning the Tomcat webapps directory..."
    rm -rf "$TOMCAT_HOME/webapps/$PROJECT_NAME"
    rm -rf "$TOMCAT_HOME/webapps/$PROJECT_NAME.war"

    # Deploy the WAR file to Tomcat
    echo "Deploying the WAR file to Tomcat..."
    cp "$WAR_FILE" "$TOMCAT_HOME/webapps/"
}

restart_tomcat() {
    # Restart Tomcat
    sleep 10  # Wait for Tomcat to shut down completely
    echo "Restarting Tomcat..."
    "$TOMCAT_HOME/bin/shutdown.sh" > ./bin/logs/tomcat-bash.txt 2>&1 &
    sleep 10
    "$TOMCAT_HOME/bin/startup.sh" > ./bin/logs/tomcat-bash.txt 2>&1 &

    # Confirmation
    echo "Tomcat server is running at: http://localhost:8080/$PROJECT_NAME"
}

# Script execution
check_java_home
verify_java_version
clean_build_directory
verify_required_directories
compile_java_files
copy_web_files
copy_dependencies
package_project
deploy_to_tomcat
restart_tomcat
