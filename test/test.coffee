expect = require('chai').expect
mkdirp = require('mkdirp')
rimraf = require('rimraf')
path = require('path')
fs = require('fs')
sinon = require('sinon')
filerw = require('file-rw')

mirrorGlob = require('../index.coffee')

describe 'mirrorGlob', ->

  delay = (t, f) -> setTimeout(f, t)
  djoin = (p) -> path.join(__dirname, p)
  rfile = (p) -> fs.readFileSync(p, { encoding: 'utf-8'})

  before ->
    rimraf.sync(djoin('tmp'))
    mkdirp.sync(djoin('tmp'))

  f = (inputFile, outputFile, extraData, cb) -> 
    fs.readFile inputFile, { encoding: 'utf8' }, (err, data) ->
      if err then cb(err)
      else filerw.mkWriteFile outputFile, data.toUpperCase(), (err, success) ->
        if err then cb(err)
        else cb(null, outputFile)

  it 'should read files in glob and write output to dir', (done) ->
    mirrorGlob 'g*.txt', { cwd: djoin('files') }, djoin('tmp/glob1'), f, {}, (err, success) ->
      expect(err).to.be.not.ok
      expect(success).to.eql([ djoin('tmp/glob1/g1.txt'), djoin('tmp/glob1/g2.txt'), djoin('tmp/glob1/g3.txt') ])
      expect(rfile(djoin('tmp/glob1/g1.txt'))).to.equal('HELLO')
      expect(rfile(djoin('tmp/glob1/g2.txt'))).to.equal('WORLD')
      expect(rfile(djoin('tmp/glob1/g3.txt'))).to.equal('BAR')
      done()

  it 'should add extension when defined', (done) ->
    mirrorGlob 'g*.txt', { cwd: djoin('files') }, djoin('tmp/glob2'), f, { extension: 'ext' }, (err, success) ->
      expect(err).to.be.not.ok
      expect(success).to.eql([ djoin('tmp/glob2/g1.txt.ext'), djoin('tmp/glob2/g2.txt.ext'), djoin('tmp/glob2/g3.txt.ext') ])
      expect(rfile(djoin('tmp/glob2/g1.txt.ext'))).to.equal('HELLO')
      expect(rfile(djoin('tmp/glob2/g2.txt.ext'))).to.equal('WORLD')
      expect(rfile(djoin('tmp/glob2/g3.txt.ext'))).to.equal('BAR')
      done()

  it 'should work if an absolute path is given', (done) ->
    mirrorGlob "#{__dirname}/files/g*.txt", { }, djoin('tmp/glob3'), f, { }, (err, success) ->
      expect(err).to.be.not.ok
      expect(success).to.eql([ djoin('tmp/glob3/g1.txt'), djoin('tmp/glob3/g2.txt'), djoin('tmp/glob3/g3.txt') ])
      expect(rfile(djoin('tmp/glob3/g1.txt'))).to.equal('HELLO')
      expect(rfile(djoin('tmp/glob3/g2.txt'))).to.equal('WORLD')
      expect(rfile(djoin('tmp/glob3/g3.txt'))).to.equal('BAR')
      done()

  it 'should replicate directory structure', (done) ->
    mirrorGlob 'g4/**/*.txt', { cwd: djoin('files') }, djoin('tmp/glob4'), f, {}, (err, success) ->
      expect(err).to.be.not.ok
      expect(success).to.eql([ djoin('tmp/glob4/g4/bar.txt'), djoin('tmp/glob4/g4/baz.txt'), djoin('tmp/glob4/g4/foo/test.txt') ])
      expect(rfile(djoin('tmp/glob4/g4/bar.txt'))).to.equal('BAR')
      expect(rfile(djoin('tmp/glob4/g4/baz.txt'))).to.equal('BAZ')
      expect(rfile(djoin('tmp/glob4/g4/foo/test.txt'))).to.equal('TEST')
      done()

  it 'should take multiple globs', (done) ->
    mirrorGlob [ '*1.txt', 'g2.*' ], { cwd: djoin('files') }, djoin('tmp/glob5'), f, {}, (err, success) ->
      expect(err).to.be.not.ok
      expect(success).to.eql([ djoin('tmp/glob5/f1.txt'), djoin('tmp/glob5/g1.txt'), djoin('tmp/glob5/g2.txt') ])
      expect(rfile(djoin('tmp/glob5/f1.txt'))).to.equal('FOO')
      expect(rfile(djoin('tmp/glob5/g1.txt'))).to.equal('HELLO')
      expect(rfile(djoin('tmp/glob5/g2.txt'))).to.equal('WORLD')
      done()


  it 'should not repeat files, even if they are matched in multiple globs', (done) ->
    mirrorGlob [ '*1.txt', 'g1.*' ], { cwd: djoin('files') }, djoin('tmp/glob6'), f, {}, (err, success) ->
      expect(err).to.be.not.ok
      expect(success).to.eql([ djoin('tmp/glob6/f1.txt'), djoin('tmp/glob6/g1.txt') ])
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
    mirrorGlob 'g*.txt', djoin('files'), djoin('tmp/glob7'), f, {}, (err, success) ->
      expect(err).to.be.not.ok
      expect(success).to.eql([ djoin('tmp/glob7/g1.txt'), djoin('tmp/glob7/g2.txt'), djoin('tmp/glob7/g3.txt') ])
      expect(rfile(djoin('tmp/glob7/g1.txt'))).to.equal('HELLO')
      expect(rfile(djoin('tmp/glob7/g2.txt'))).to.equal('WORLD')
      expect(rfile(djoin('tmp/glob7/g3.txt'))).to.equal('BAR')
      done()

  it 'has optional options', (done) ->
    mirrorGlob 'g*.txt', { cwd: djoin('files') }, djoin('tmp/glob8'), f, (err, success) ->
      expect(err).to.be.not.ok
      expect(success).to.eql([ djoin('tmp/glob8/g1.txt'), djoin('tmp/glob8/g2.txt'), djoin('tmp/glob8/g3.txt') ])
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

    mirrorGlob('g*.txt', djoin('files'), 'build', handler, { extension: 'out', extraFiles})
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

    mirrorGlob('g*.txt', djoin('files'), 'build', handler, { extension: 'out', extraFiles, sourceMapDir: 'maps'})
    delay 50, ->
      expect(handler.callCount).to.equal(3)
      expect(handler.args[0]).to.have.length(4)
      expect(handler.args[0][0]).to.equal(djoin('files/g1.txt'))
      expect(handler.args[0][1]).to.equal(path.join('build','g1.txt.out'))
      expect(handler.args[0][2]).to.eql({other: path.join('other','g1.txt.oth'), sourceMap: path.join('maps','g1.txt.map')})
      done()

  describe 'withWatch', ->
    it 'should build file when original is changed'
    it 'should build file when new file is added'
    it 'should remove built file when original is deleted'
    it 'should build new file and remove old one on rename'
