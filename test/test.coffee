expect = require('chai').expect
mkdirp = require('mkdirp')
rimraf = require('rimraf')
path = require('path')
fs = require('fs')
sinon = require('sinon')
filerw = require('file-rw')
_ = require('lodash')

mirrorGlob = require('../index.coffee')

describe 'mirrorGlob', ->

  delay = (t, f) -> setTimeout(f, t)
  djoin = (p) -> path.join(__dirname, p)
  rfile = (p) -> fs.readFileSync(p, { encoding: 'utf-8'})
  globpath = (p) -> p.split(path.sep).join('/')

  before ->
    rimraf.sync(djoin('tmp'))
    mkdirp.sync(djoin('tmp'))

  f = (inputFile, outputFile, extraData, cb) -> 
    fs.readFile inputFile, { encoding: 'utf8' }, (err, data) ->
      if err then return cb(err)

      allFiles = _.values(extraData).concat([outputFile])
      toWrite = ([filePath, data.toUpperCase()] for filePath in allFiles)

      filerw.mkWriteFiles toWrite, (err, success) ->
        if err then cb(err)
        else cb(null, 'processed')


  it 'should read files in glob and write output to dir', (done) ->
    mirrorGlob 'g*.txt', { cwd: djoin('files') }, djoin('tmp/glob1'), {}, f, (err, success) ->
      expect(err).to.be.not.ok
      expect(success).have.length(3)
      expect(success[0]).have.eql({ result: 'processed', inputPath: 'g1.txt', outputPath: djoin('tmp/glob1/g1.txt'), extraPaths: {} })
      expect(success[1]).have.eql({ result: 'processed', inputPath: 'g2.txt', outputPath: djoin('tmp/glob1/g2.txt'), extraPaths: {} })
      expect(success[2]).have.eql({ result: 'processed', inputPath: 'g3.txt', outputPath: djoin('tmp/glob1/g3.txt'), extraPaths: {} })
      expect(rfile(djoin('tmp/glob1/g1.txt'))).to.equal('HELLO')
      expect(rfile(djoin('tmp/glob1/g2.txt'))).to.equal('WORLD')
      expect(rfile(djoin('tmp/glob1/g3.txt'))).to.equal('BAR')
      done()

  it 'should add extension when defined', (done) ->
    mirrorGlob 'g*.txt', { cwd: djoin('files') }, djoin('tmp/glob2'), { extension: 'ext' }, f, (err, success) ->
      expect(err).to.be.not.ok
      expect(success).have.length(3)
      expect(success[0]).have.eql({ result: 'processed', inputPath: 'g1.txt', outputPath: djoin('tmp/glob2/g1.txt.ext'), extraPaths: {} })
      expect(success[1]).have.eql({ result: 'processed', inputPath: 'g2.txt', outputPath: djoin('tmp/glob2/g2.txt.ext'), extraPaths: {} })
      expect(success[2]).have.eql({ result: 'processed', inputPath: 'g3.txt', outputPath: djoin('tmp/glob2/g3.txt.ext'), extraPaths: {} })
      expect(rfile(djoin('tmp/glob2/g1.txt.ext'))).to.equal('HELLO')
      expect(rfile(djoin('tmp/glob2/g2.txt.ext'))).to.equal('WORLD')
      expect(rfile(djoin('tmp/glob2/g3.txt.ext'))).to.equal('BAR')
      done()

  it 'should work if an absolute path is given', (done) ->
    mirrorGlob "#{__dirname}/files/g*.txt", { }, djoin('tmp/glob3'), { }, f, (err, success) ->
      expect(err).to.be.not.ok
      expect(success).have.length(3)
      expect(success[0]).have.eql({ result: 'processed', inputPath: path.normalize("#{__dirname}/files/g1.txt"), outputPath: djoin('tmp/glob3/g1.txt'), extraPaths: {} })
      expect(success[1]).have.eql({ result: 'processed', inputPath: path.normalize("#{__dirname}/files/g2.txt"), outputPath: djoin('tmp/glob3/g2.txt'), extraPaths: {} })
      expect(success[2]).have.eql({ result: 'processed', inputPath: path.normalize("#{__dirname}/files/g3.txt"), outputPath: djoin('tmp/glob3/g3.txt'), extraPaths: {} })
      expect(rfile(djoin('tmp/glob3/g1.txt'))).to.equal('HELLO')
      expect(rfile(djoin('tmp/glob3/g2.txt'))).to.equal('WORLD')
      expect(rfile(djoin('tmp/glob3/g3.txt'))).to.equal('BAR')
      done()

  it 'should replicate directory structure', (done) ->
    mirrorGlob 'g4/**/*.txt', { cwd: djoin('files') }, djoin('tmp/glob4'), {}, f, (err, success) ->
      expect(err).to.be.not.ok
      expect(success).have.length(3)
      expect(success[0]).have.eql({ result: 'processed', inputPath: path.normalize("g4/bar.txt"), outputPath: djoin('tmp/glob4/g4/bar.txt'), extraPaths: {} })
      expect(success[1]).have.eql({ result: 'processed', inputPath: path.normalize("g4/baz.txt"), outputPath: djoin('tmp/glob4/g4/baz.txt'), extraPaths: {} })
      expect(success[2]).have.eql({ result: 'processed', inputPath: path.normalize("g4/foo/test.txt"), outputPath: djoin('tmp/glob4/g4/foo/test.txt'), extraPaths: {} })
      expect(rfile(djoin('tmp/glob4/g4/bar.txt'))).to.equal('BAR')
      expect(rfile(djoin('tmp/glob4/g4/baz.txt'))).to.equal('BAZ')
      expect(rfile(djoin('tmp/glob4/g4/foo/test.txt'))).to.equal('TEST')
      done()

  it 'should take multiple globs', (done) ->
    mirrorGlob [ '*1.txt', 'g2.*' ], { cwd: djoin('files') }, djoin('tmp/glob5'), {}, f, (err, success) ->
      expect(err).to.be.not.ok
      #expect(success).to.eql([ djoin('tmp/glob5/f1.txt'), djoin('tmp/glob5/g1.txt'), djoin('tmp/glob5/g2.txt') ])
      expect(success).have.length(3)
      expect(success[0]).have.eql({ result: 'processed', inputPath: path.normalize("f1.txt"), outputPath: djoin('tmp/glob5/f1.txt'), extraPaths: {} })
      expect(success[1]).have.eql({ result: 'processed', inputPath: path.normalize("g1.txt"), outputPath: djoin('tmp/glob5/g1.txt'), extraPaths: {} })
      expect(success[2]).have.eql({ result: 'processed', inputPath: path.normalize("g2.txt"), outputPath: djoin('tmp/glob5/g2.txt'), extraPaths: {} })
      expect(rfile(djoin('tmp/glob5/f1.txt'))).to.equal('FOO')
      expect(rfile(djoin('tmp/glob5/g1.txt'))).to.equal('HELLO')
      expect(rfile(djoin('tmp/glob5/g2.txt'))).to.equal('WORLD')
      done()


  it 'should not repeat files, even if they are matched in multiple globs', (done) ->
    mirrorGlob [ '*1.txt', 'g1.*' ], { cwd: djoin('files') }, djoin('tmp/glob6'), {}, f, (err, success) ->
      expect(err).to.be.not.ok
      expect(success).have.length(2)
      expect(rfile(djoin('tmp/glob6/f1.txt'))).to.equal('FOO')
      expect(rfile(djoin('tmp/glob6/g1.txt'))).to.equal('HELLO')
      done()

  it 'should not attempt to call callback if it is not defined', (done) ->
    mirrorGlob 'g*.txt', { cwd: djoin('files') }, djoin('tmp/glob7'), f
    delay 50, ->
      expect(rfile(djoin('tmp/glob7/g1.txt'))).to.equal('HELLO')
      expect(rfile(djoin('tmp/glob7/g2.txt'))).to.equal('WORLD')
      expect(rfile(djoin('tmp/glob7/g3.txt'))).to.equal('BAR')
      done()


  it 'assume string is cwd if it is the only globOption', (done) ->
    mirrorGlob 'g*.txt', djoin('files'), djoin('tmp/glob7'), {}, f, (err, success) ->
      expect(err).to.be.not.ok
      expect(success).to.have.length(3)
      expect(rfile(djoin('tmp/glob7/g1.txt'))).to.equal('HELLO')
      expect(rfile(djoin('tmp/glob7/g2.txt'))).to.equal('WORLD')
      expect(rfile(djoin('tmp/glob7/g3.txt'))).to.equal('BAR')
      done()

  it 'has optional options', (done) ->
    mirrorGlob 'g*.txt', { cwd: djoin('files') }, djoin('tmp/glob8'), f, (err, success) ->
      expect(err).to.be.not.ok
      expect(success).to.have.length(3)
      expect(rfile(djoin('tmp/glob8/g1.txt'))).to.equal('HELLO')
      expect(rfile(djoin('tmp/glob8/g2.txt'))).to.equal('WORLD')
      expect(rfile(djoin('tmp/glob8/g3.txt'))).to.equal('BAR')
      done()

  it 'generates extra file paths', (done) ->
    handler = sinon.spy((inFile, outFile, extraFiles, cb) -> delay(1, cb(null, outFile)))

    extraFiles =
      log:
        dir: 'logging'
        extension: 'log'
      sourceMap:
        dir: 'maps'
        extension: 'map'

    mirrorGlob('g*.txt', djoin('files'), 'build', { extension: 'out', extraFiles}, handler)
    delay 50, ->
      expect(handler.callCount).to.equal(3)
      expect(handler.args[0]).to.have.length(4)
      expect(handler.args[0][0]).to.equal(djoin('files/g1.txt'))
      expect(handler.args[0][1]).to.equal(path.join('build','g1.txt.out'))
      expect(handler.args[0][2]).to.eql({log: path.join('logging','g1.txt.log'), sourceMap: path.join('maps','g1.txt.map')})
      done()



  it 'has shorthand for sourceMapDir', (done) ->
    handler = sinon.spy((inFile, outFile, extraFiles, cb) -> delay(1, cb(null, outFile)))

    extraFiles =
      other:
        dir: 'other'
        extension: 'oth'

    mirrorGlob('g*.txt', djoin('files'), 'build', { extension: 'out', extraFiles, sourceMapDir: 'maps'}, handler)
    delay 50, ->
      expect(handler.callCount).to.equal(3)
      expect(handler.args[0]).to.have.length(4)
      expect(handler.args[0][0]).to.equal(djoin('files/g1.txt'))
      expect(handler.args[0][1]).to.equal(path.join('build','g1.txt.out'))
      expect(handler.args[0][2]).to.eql({other: path.join('other','g1.txt.oth'), sourceMap: path.join('maps','g1.txt.map')})
      done()

  it 'returns extra paths to callback', (done) ->

    extraFiles =
      log:
        dir: djoin('tmp/glob9/logging')
        extension: 'log'
      sourceMap:
        dir: djoin('tmp/glob9/maps')
        extension: 'map'

    mirrorGlob 'g*.txt', djoin('files'), djoin('tmp/glob9'), { extension: 'out', extraFiles }, f, (err, success) ->
      expect(err).to.be.not.ok
      expect(success).have.length(3)
      expect(success[0]).have.eql({ result: 'processed', inputPath: 'g1.txt', outputPath: djoin('tmp/glob9/g1.txt.out'), extraPaths: { log: djoin('tmp/glob9/logging/g1.txt.log'), sourceMap: djoin('tmp/glob9/maps/g1.txt.map') } })
      expect(success[1]).have.eql({ result: 'processed', inputPath: 'g2.txt', outputPath: djoin('tmp/glob9/g2.txt.out'), extraPaths: { log: djoin('tmp/glob9/logging/g2.txt.log'), sourceMap: djoin('tmp/glob9/maps/g2.txt.map') } })
      expect(success[2]).have.eql({ result: 'processed', inputPath: 'g3.txt', outputPath: djoin('tmp/glob9/g3.txt.out'), extraPaths: { log: djoin('tmp/glob9/logging/g3.txt.log'), sourceMap: djoin('tmp/glob9/maps/g3.txt.map') } })
      done()

  it 'can receive object with callbacks', (done) ->
    callbacks =
      initial: (err, success) ->
        expect(err).to.be.not.ok
        expect(success).have.length(3)
        done()
      update: (->)
      remove: (->)

    mirrorGlob('g*.txt', { cwd: djoin('files') }, djoin('tmp/glob1'), {}, f, callbacks)


  describe 'withWatch', ->

    beforeEach ->
      rimraf.sync(djoin('tmp/watch'))
      mkdirp.sync(djoin('tmp/watch'))


    it 'should build file when original is changed', (done) ->

      fs.writeFileSync(djoin('tmp/watch/w1.txt'), 'FOO', 'utf8')

      callbacks =
        initial: (err, success) ->

        update: (err, success) ->
          expect(err).to.be.not.ok
          expect(success).to.eql({ result: 'processed', inputPath: 'w1.txt', outputPath: djoin('tmp/glob10/w1.txt'), extraPaths: {} })
          expect(rfile(djoin('tmp/glob10/w1.txt'))).to.equal('BAR')         
          w.destroy() #Cleanup
          done()

      w = mirrorGlob('w*.txt', { cwd: djoin('tmp/watch'), delay: 0 }, djoin('tmp/glob10'), { watch: true }, f, callbacks)

      delay 1000, ->
        fs.writeFileSync(djoin('tmp/watch/w1.txt'), 'BAR', 'utf8')


    it 'should build file when new file is added', (done) ->

      # Broken on Windows with watch-glob 0.1.3 (gaze 5.1) unless the watch matches some file initially
      fs.writeFileSync(djoin('tmp/watch/w-unbreak-my-windows.txt'), 'This file is matched by the initial w*.txt watch. Without it the watch does not detect file adds', 'utf8')

      callbacks =
        update: (err, success) ->
          expect(err).to.be.not.ok
          expect(success).to.eql({ result: 'processed', inputPath: 'w2.txt', outputPath: djoin('tmp/glob11/w2.txt'), extraPaths: {} })
          expect(rfile(djoin('tmp/glob11/w2.txt'))).to.equal('FOO')
          w.destroy() #Cleanup
          done()

      w = mirrorGlob('w*.txt', { cwd: djoin('tmp/watch'), delay: 100 }, djoin('tmp/glob11'), { watch: true }, f, callbacks)

      delay 300, ->
        fs.writeFileSync(djoin('tmp/watch/w2.txt'), 'FOO', 'utf8')


    it 'should remove built file when original is deleted', (done) ->
      fs.writeFileSync(djoin('tmp/watch/w1.txt'), 'FOO', 'utf8')

      callbacks =
        initial: (err, success) ->
          expect(err).to.be.not.ok
          expect(rfile(djoin('tmp/glob12/w1.txt'))).to.equal('FOO')
        remove: (err, success) ->
          expect(err).to.be.not.ok
          expect(success).to.eql({ inputPath: 'w1.txt', outputPath: djoin('tmp/glob12/w1.txt'), extraPaths: {} })
          expect(fs.existsSync(djoin('tmp/glob12/w1.txt'))).to.equal(false)
          w.destroy() #Cleanup
          done()

      w = mirrorGlob('w*.txt', { cwd: djoin('tmp/watch'), delay: 0 }, djoin('tmp/glob12'), { watch: true }, f, callbacks)      

      delay 300, ->
        fs.unlink(djoin('tmp/watch/w1.txt'), 'FOO', 'utf8')


    it 'should remove extra files', (done) ->
      fs.writeFileSync(djoin('tmp/watch/w1.txt'), 'FOO', 'utf8')

      extraFiles = { log: { dir: djoin('tmp/glob13/logging'), extension: 'log' }}

      callbacks =
        initial: (err, success) ->
          expect(err).to.be.not.ok
          expect(success).to.have.length(1)
          expect(fs.existsSync(djoin('tmp/glob13/w1.txt'))).to.equal(true)
          expect(fs.existsSync(djoin('tmp/glob13/logging/w1.txt.log'))).to.equal(true)
          
        remove: (err, success) ->
          expect(err).to.be.not.ok
          expect(success).to.eql({ inputPath: 'w1.txt', outputPath: djoin('tmp/glob13/w1.txt'), extraPaths: { log: djoin('tmp/glob13/logging/w1.txt.log') } })
          expect(fs.existsSync(djoin('tmp/glob13/w1.txt'))).to.equal(false)
          expect(fs.existsSync(djoin('tmp/glob13/logging/w1.txt.log'))).to.equal(false)
          w.destroy() #Cleanup
          done()

      w = mirrorGlob('w*.txt', { cwd: djoin('tmp/watch'), delay: 0 }, djoin('tmp/glob13'), { watch: true, extraFiles }, f, callbacks)

      delay 300, ->
        fs.unlink(djoin('tmp/watch/w1.txt'))
      

    it 'should use initial callback for update when no update callback is defined', (done) ->
      fs.writeFileSync(djoin('tmp/watch/w1.txt'), 'FOO', 'utf8')

      callNum = 0
      callbacks =
        initial: (err, success) ->
          expect(err).to.be.not.ok
          callNum += 1
          if callNum == 1
            expect(success).to.eql([{ result: 'processed', inputPath: 'w1.txt', outputPath: djoin('tmp/glob14/w1.txt'), extraPaths: {} }])
          else if callNum == 2
            expect(success).to.eql([{ result: 'processed', inputPath: 'w1.txt', outputPath: djoin('tmp/glob14/w1.txt'), extraPaths: {} }])
            done()

      w = mirrorGlob('w*.txt', { cwd: djoin('tmp/watch'), delay: 0 }, djoin('tmp/glob14'), { watch: true }, f, callbacks)

      delay 1000, ->
        fs.writeFileSync(djoin('tmp/watch/w1.txt'), 'BAR', 'utf8')


    it 'should build new file and remove old one on rename'
