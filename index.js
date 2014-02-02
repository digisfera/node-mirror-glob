// Generated by CoffeeScript 1.7.1
(function() {
  var Args, async, fs, glob, path, watchGlob, _;

  fs = require('fs');

  _ = require('lodash');

  async = require('async');

  path = require('path');

  glob = require('glob');

  watchGlob = require('watch-glob');

  Args = require('args-js');

  module.exports = function() {
    var args, callback, extraFilePaths, generateFilePath, globOptions, handler, options, outputDir, outputFilePath, patterns, removeCallback, sourceMapDir, updateCallback;
    args = Args([
      {
        patterns: Args.ANY | Args.Required
      }, {
        globOptions: Args.ANY | Args.Required
      }, {
        outputDir: Args.STRING | Args.Required
      }, {
        handler: Args.FUNCTION | Args.Required
      }, {
        options: Args.OBJECT | Args.Optional,
        _default: {}
      }, {
        callback: Args.FUNCTION | Args.Optional,
        _default: (function() {})
      }, {
        updateCallback: Args.FUNCTION | Args.Optional,
        _default: (function() {})
      }, {
        removeCallback: Args.FUNCTION | Args.Optional,
        _default: (function() {})
      }
    ], arguments);
    patterns = args.patterns, globOptions = args.globOptions, outputDir = args.outputDir, handler = args.handler, options = args.options, callback = args.callback, updateCallback = args.updateCallback, removeCallback = args.removeCallback;
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
    outputFilePath = function(p) {
      return generateFilePath(p, outputDir, options.extension);
    };
    extraFilePaths = function(p) {
      return _.mapValues(options.extraFiles, function(extraFileOptions) {
        return generateFilePath(p, extraFileOptions.dir, extraFileOptions.extension);
      });
    };
    return async.map(patterns, (function(pattern, cb) {
      return glob(pattern, globOptions, cb);
    }), function(err, matches) {
      var allMatches, extraFiles, inFilesAbsolute, outFiles, processFilePair;
      allMatches = _(matches).flatten().uniq().value();
      inFilesAbsolute = _.map(allMatches, function(p) {
        return path.resolve((globOptions != null ? globOptions.cwd : void 0) || '', p);
      });
      outFiles = _.map(allMatches, outputFilePath);
      extraFiles = _.map(allMatches, extraFilePaths);
      processFilePair = function(processArgs, cb) {
        return handler(processArgs[0], processArgs[1], processArgs[2], cb);
      };
      return async.map(_.zip(inFilesAbsolute, outFiles, extraFiles), processFilePair, function(err, success) {
        var buildFile, deleteFile;
        if (!(options != null ? options.watch : void 0)) {
          return callback(err, success);
        } else {
          buildFile = function(file) {
            return processFilePair([file.path, outputFilePath(file.relative), extraFilePaths(file.relative)], updateCallback);
          };
          deleteFile = function(file) {
            var builtPath;
            builtPath = outputFilePath(file.relative);
            return fs.unlink(builtPath, function(err, success) {
              return removeCallback(err, builtPath);
            });
          };
          watchGlob(patterns, globOptions, buildFile, deleteFile);
          return callback(err, success);
        }
      });
    });
  };

}).call(this);
