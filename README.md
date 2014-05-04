# mirror-glob

Process a group of files into another folder and watch them for changes

## Installation

    npm install mirror-glob

## Usage

**mirrorGlob(patterns, base, outputDir, [options], handler, [callbacks], [updateCallback], [removeCallback])**

`processGlob` receives a handler which is called for each files which matches a pattern. It can then watch that pattern, calling the handler whenever a file is changed or a new file is added, and deleting the processed file if the original one is removed.

* `patterns` - a glob pattern or array of glob patterns to process
* `base` - an options object to pass to `glob()` or the base folder in which to search for the patterns (equivalent to `options.cwd`)
* `outputDir `- the directory in which to write the processed files
* `options`
  * `extension` - (default: `''`) extension to add to the output files
  * `watch` - (default: `false`) whether the files should be watched for changes
  * `extraFiles` - an object describing extra file paths to be passed in the `extraFiles` argument. `{ type: { dir, extension } }` (e.g `{ log: { dir: 'logs', extension: 'log' } }`)
  * `sourceMapDir` - a shorthand add a property to `extraFiles`: `{ sourceMap: { dir: sourceMapDir, extension: 'map' } }`
* `handler` - the function to process the files, which will be called with arguments `(inputPath, outputPath, extraFiles, callback)`. The `extraFiles` argument contains the files defined in `options.extraFiles`
* `callbacks` - function or object containing functions to be called after a file is processed
  * if object, should have the following properties:
    * `initial`- function to be called after the initial processing is finished, with `(err, [ { processingResult, inputPath, outputPath, extraPaths }] )`
    * `update` - function to be called after processing is finished due to a file being changed or added, with `(err, { processingResult, inputPath, outputPath, extraPaths })`. only called when `options.watch` is `true`
    * `remove` - function to be called after a file is removed, with ``(err, { inputPath, outputPath, extraPaths })`. only called when `options.watch` is `true`

  * if function, is called after the initial processing and on update, with `(err, [ { processingResult, inputPath, outputPath, extraPaths }] )`
 


## Example

    function someHandler(inputFile, outputFile, extraFiles, callback) {
      // do something with inputFile and write outputFile
      // sample parameter values:
      //   * inputFile: 'src/foo.wutscript'
      //   * outputFile: 'build/foo.wutscript.js'
      //   * extraFiles.sourceMap: 'build/maps/foo.wutscript.js.map'
      //   * extraFiles.log: 'build/logging/foo.wutscript.js.log'
    }

    var options = {
      watch: true,
      extension: 'js',
      extraFiles: { log: { dir: 'logging', extension: 'log' }, sourceMap: { dir: 'maps', extension: 'map' }}
    }
    mirrorGlob('**/*.wutscript', 'src', 'build', options, someHandler, {
      initial: function(err, success) {
        console.log("Initial processing complete");
        // success is an array with information about the file processing
      },
      update: function(err, success) {
        console.log("File reprocessed");
        // success has information about the file processing
      },
      remove: function(err, success) {
        console.log("File removed");
        // err is not null if an error ocurred while unlinking the file
      }});

