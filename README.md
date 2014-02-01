# mirror-glob

Process a group of files into another folder and watch them for changes

## Installation

    npm install mirror-glob

## Usage

**mirrorGlob(patterns, base, outputDir, handler, [options], [callback], [updateCallback], [removeCallback])**

`processGlob` receives a handler which is called for each files which matches a pattern. It can then watch that pattern, calling the handler whenever a file is changed or a new file is added, and deleting the processed file if the original one is removed.

* `patterns` - a glob pattern or array of glob patterns to process
* `base` - an options object to pass to `glob()` or the base folder in which to search for the patterns (equivalent to `options.cwd`)
* `outputDir `- the directory in which to write the processed files
* `handler` - the function to process the files, which will be called with arguments `(inputPath, outputPath, extraFiles, callback)`. The `extraFiles` argument contains the files defined in `options.extraFiles`
* `options`
  * `extension` - (default: `''`) extension to add to the output files
  * `watch` - (default: `false`) whether the files should be watched for changes
  * `extraFiles` - an object describing extra file paths to be passed in the `extraFiles` argument. `{ type: { dir, extension } }` (e.g `{ log: { dir: 'logs', extension: 'log' } }`)
  * `sourceMapDir` - a shorthand add a property to `extraFiles`: `{ sourceMap: { dir: sourceMapDir, extension: 'map' } }`
* `callback` - function to be called after the initial processing is finished, with `(err, handlerResults)`
* `updateCallback` - function to be called after processing is finished due to a file being changed or added. only called when `options.watch` is `true`
* `removeCallback` - function to be called after a file is removed. only called when `options.watch` is `true`


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
    mirrorGlob('**/*.wutscript', 'src', 'build', someHandler, options, function(err, success) {
      console.log("Initial processing complete");
      // success is an array with all the results passed to someHandler()'s callback
    }, function(err, success) {
      console.log("File reprocessed");
      // success is the result passed to someHandler()'s callback
    }, function(err) {
      console.log("File removed");
      // err is not null if an error ocurred while unlinking the file
    });

