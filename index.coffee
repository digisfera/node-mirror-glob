fs = require('fs')
_ = require('lodash')
async = require('async')
path = require('path')
glob = require('glob')
watchGlob = require('watch-glob')
Args = require('args-js')


defaultUpdateCallback = (initialCallback) ->
  (err, processingResult) ->
    if err then initialCallback(err)
    else initialCallback(null, [processingResult])


module.exports = () ->

  args = Args([
    { patterns:  Args.ANY | Args.Required }
    { globOptions: Args.ANY | Args.Required }
    { outputDir: Args.STRING | Args.Required }
    { options: Args.OBJECT | Args.Optional, _default: {} }
    { handler: Args.FUNCTION | Args.Required }
    { callbacksArg: Args.ANY | Args.Optional }
  ], arguments)

  { patterns, globOptions, outputDir, handler, options, callbacksArg } = args      

  callbacks = {}
  callbacks.initial = 
    if _.isFunction(callbacksArg) then callbacksArg else callbacksArg?.initial || (->)
  callbacks.update = callbacksArg?.update || defaultUpdateCallback(callbacks.initial)
  callbacks.remove = callbacksArg?.remove || (->)

  if !_.isArray(patterns) then patterns = [ patterns ]
  if _.isString(globOptions) then globOptions = { cwd: globOptions }
  
  if options.sourceMapDir
    sourceMapDir = if options.sourceMapDir == true then outputDir else options.sourceMapDir
    options.extraFiles ?= {}
    options.extraFiles.sourceMap = { dir: sourceMapDir, extension: 'map' }


  generateFilePath = (p, dir, extension) ->
    outPath = 
      if path.normalize(path.resolve(p)) == path.normalize(p)
      #This is an absolute path, just use the basename
        path.join(dir, path.basename(p))
      else
        path.join(dir, p)

    if extension?.length > 0 then "#{outPath}.#{extension}"
    else outPath

  inputFilePath = (p) -> path.resolve(globOptions?.cwd || '', p)
  outputFilePath = (p) -> generateFilePath(p, outputDir, options.extension)

  extraFilePaths = (p) -> _.mapValues options.extraFiles, (extraFileOptions) ->
        generateFilePath(p, extraFileOptions.dir, extraFileOptions.extension)

  processFilePair = ([ inputPath, outputPath, extraPaths ], cb) ->
    handler inputFilePath(inputPath), outputPath, extraPaths, (err, result) ->
      if err then cb(err)
      else cb(null, { inputPath: path.normalize(inputPath), outputPath, extraPaths, result })

  async.map patterns, ((pattern, cb) -> glob(pattern, globOptions, cb)), (err, matches) ->
    if err
      watchGlobInstance?.destroy()
      callbacks.initial(err)
      return

    allMatches = _(matches).flatten().uniq().value()
    outFiles = _.map(allMatches, outputFilePath)
    extraFiles = _.map(allMatches, extraFilePaths)

    async.map _.zip(allMatches, outFiles, extraFiles), processFilePair, (err, success) ->
      if err
        watchGlobInstance.destroy()
        callbacks.initial(err)
      else callbacks.initial(null, success)

      
  if options?.watch
    buildFile = (filePathObj) ->
      processFilePair([ filePathObj.relative, outputFilePath(filePathObj.relative), extraFilePaths(filePathObj.relative)], callbacks.update)

    deleteFile = (file) ->
      outputPath = outputFilePath(file.relative)
      extraPaths = extraFilePaths(file.relative)

      allPaths = _.values(extraPaths).concat([outputPath])
      async.map allPaths, fs.unlink, (err, success) ->
        if err then callbacks.remove(err)
        else callbacks.remove(null, { inputPath: path.normalize(file.relative), outputPath, extraPaths })

    watchGlobInstance = watchGlob(patterns, globOptions, buildFile, deleteFile)