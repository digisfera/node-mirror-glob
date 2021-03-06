// Generated by CoffeeScript 1.7.1
(function() {
  var Args, async, defaultUpdateCallback, fs, glob, path, watchGlob, _;

  fs = require('fs');

  _ = require('lodash');

  async = require('async');

  path = require('path');

  glob = require('glob');

  watchGlob = require('watch-glob');

  Args = require('args-js');

  defaultUpdateCallback = function(initialCallback) {
    return function(err, processingResult) {
      if (err) {
        return initialCallback(err);
      } else {
        return initialCallback(null, [processingResult]);
      }
    };
  };

  module.exports = function() {
    var args, buildFile, callbacks, callbacksArg, deleteFile, extraFilePaths, generateFilePath, globOptions, handler, inputFilePath, options, outputDir, outputFilePath, patterns, processFilePair, sourceMapDir, watchGlobInstance;
    args = Args([
      {
        patterns: Args.ANY | Args.Required
      }, {
        globOptions: Args.ANY | Args.Required
      }, {
        outputDir: Args.STRING | Args.Required
      }, {
        options: Args.OBJECT | Args.Optional,
        _default: {}
      }, {
        handler: Args.FUNCTION | Args.Required
      }, {
        callbacksArg: Args.ANY | Args.Optional
      }
    ], arguments);
    patterns = args.patterns, globOptions = args.globOptions, outputDir = args.outputDir, handler = args.handler, options = args.options, callbacksArg = args.callbacksArg;
    callbacks = {};
    callbacks.initial = _.isFunction(callbacksArg) ? callbacksArg : (callbacksArg != null ? callbacksArg.initial : void 0) || (function() {});
    callbacks.update = (callbacksArg != null ? callbacksArg.update : void 0) || defaultUpdateCallback(callbacks.initial);
    callbacks.remove = (callbacksArg != null ? callbacksArg.remove : void 0) || (function() {});
    if (!_.isArray(patterns)) {
      patterns = [patterns];
    }
    if (_.isString(globOptions)) {
      globOptions = {
        cwd: globOptions
      };
    }
    if (options.sourceMapDir) {
      sourceMapDir = options.sourceMapDir === true ? outputDir : options.sourceMapDir;
      if (options.extraFiles == null) {
        options.extraFiles = {};
      }
      options.extraFiles.sourceMap = {
        dir: sourceMapDir,
        extension: 'map'
      };
    }
    generateFilePath = function(p, dir, extension) {
      var outPath;
      outPath = path.normalize(path.resolve(p)) === path.normalize(p) ? path.join(dir, path.basename(p)) : path.join(dir, p);
      if ((extension != null ? extension.length : void 0) > 0) {
        return "" + outPath + "." + extension;
      } else {
        return outPath;
      }
    };
    inputFilePath = function(p) {
      return path.resolve((globOptions != null ? globOptions.cwd : void 0) || '', p);
    };
    outputFilePath = function(p) {
      return generateFilePath(p, outputDir, options.extension);
    };
    extraFilePaths = function(p) {
      return _.mapValues(options.extraFiles, function(extraFileOptions) {
        return generateFilePath(p, extraFileOptions.dir, extraFileOptions.extension);
      });
    };
    processFilePair = function(_arg, cb) {
      var extraPaths, inputPath, outputPath;
      inputPath = _arg[0], outputPath = _arg[1], extraPaths = _arg[2];
      return handler(inputFilePath(inputPath), outputPath, extraPaths, function(err, result) {
        if (err) {
          return cb(err);
        } else {
          return cb(null, {
            inputPath: path.normalize(inputPath),
            outputPath: outputPath,
            extraPaths: extraPaths,
            result: result
          });
        }
      });
    };
    async.map(patterns, (function(pattern, cb) {
      return glob(pattern, globOptions, cb);
    }), function(err, matches) {
      var allMatches, extraFiles, outFiles;
      if (err) {
        if (typeof watchGlobInstance !== "undefined" && watchGlobInstance !== null) {
          watchGlobInstance.destroy();
        }
        callbacks.initial(err);
        return;
      }
      allMatches = _(matches).flatten().uniq().value();
      outFiles = _.map(allMatches, outputFilePath);
      extraFiles = _.map(allMatches, extraFilePaths);
      return async.map(_.zip(allMatches, outFiles, extraFiles), processFilePair, function(err, success) {
        if (err) {
          watchGlobInstance.destroy();
          return callbacks.initial(err);
        } else {
          return callbacks.initial(null, success);
        }
      });
    });
    if (options != null ? options.watch : void 0) {
      buildFile = function(filePathObj) {
        return processFilePair([filePathObj.relative, outputFilePath(filePathObj.relative), extraFilePaths(filePathObj.relative)], callbacks.update);
      };
      deleteFile = function(file) {
        var allPaths, extraPaths, outputPath;
        outputPath = outputFilePath(file.relative);
        extraPaths = extraFilePaths(file.relative);
        allPaths = _.values(extraPaths).concat([outputPath]);
        return async.map(allPaths, fs.unlink, function(err, success) {
          if (err) {
            return callbacks.remove(err);
          } else {
            return callbacks.remove(null, {
              inputPath: path.normalize(file.relative),
              outputPath: outputPath,
              extraPaths: extraPaths
            });
          }
        });
      };
      return watchGlobInstance = watchGlob(patterns, globOptions, buildFile, deleteFile);
    }
  };

}).call(this);
