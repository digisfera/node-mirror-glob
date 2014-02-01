fs = require('fs')
_ = require('lodash')
async = require('async')
path = require('path')
glob = require('glob')
watchGlob = require('watch-glob')
Args = require('args-js')


module.exports = () ->

  args = Args([
    { patterns:  Args.ANY | Args.Required }
    { globOptions: Args.ANY | Args.Required }
    { outputDir: Args.STRING | Args.Required }
    { handler: Args.FUNCTION | Args.Required }
    { options: Args.OBJECT | Args.Optional, _default: {} }
    { callback: Args.FUNCTION | Args.Optional, _default: (->) }
    { updateCallback: Args.FUNCTION | Args.Optional, _default: (->) }
    { removeCallback: Args.FUNCTION | Args.Optional, _default: (->) }
  ], arguments)

  { patterns, globOptions, outputDir, handler, options, callback, updateCallback, removeCallback } = args      

  if !_.isArray(patterns) then patterns = [ patterns ]
  if _.isString(globOptions) then globOptions = { cwd: globOptions }
  
  if options.sourceMapDir
    options.extraFiles ?= {}
    options.extraFiles.sourceMap = { dir: options.sourceMapDir, extension: 'map' }


  generateFilePath = (p, dir, extension) ->
    outPath = 
      if path.normalize(path.resolve(p)) == path.normalize(p)
      #This is an absolute path, just use the basename
        path.join(dir, path.basename(p))
      else
        path.join(dir, p)

    if extension?.length > 0 then "#{outPath}.#{extension}"
    else outPath

  outputFilePath = (p) -> generateFilePath(p, outputDir, options.extension)

  extraFilePaths = (p) -> _.mapValues options.extraFiles, (extraFileOptions) ->
        generateFilePath(p, extraFileOptions.dir, extraFileOptions.extension)

  async.map patterns, ((pattern, cb) -> glob(pattern, globOptions, cb)), (err, matches) ->
    allMatches = _(matches).flatten().uniq().value()
    inFilesAbsolute = _.map(allMatches, (p) -> path.resolve(globOptions?.cwd || '', p))

    outFiles = _.map(allMatches, outputFilePath)
    extraFiles = _.map(allMatches, extraFilePaths)


    processFilePair = (processArgs, cb) -> handler(processArgs[0], processArgs[1], processArgs[2], cb)

    async.map _.zip(inFilesAbsolute, outFiles, extraFiles), processFilePair, (err, success) ->
      
      if !options?.watch then callback(err, success)
      else
        buildFile = (file) -> processFilePair([ file.path, outputFilePath(file.relative), extraFilePaths(file.relative)], updateCallback)

        deleteFile = (file) ->
          builtPath = outputFilePath(file.relative)
          fs.unlink(builtPath , (err, success) -> removeCallback(err,builtPath))

        watchGlob(patterns, globOptions, buildFile, deleteFile)

        callback(err, success)