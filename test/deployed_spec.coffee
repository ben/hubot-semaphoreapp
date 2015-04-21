# Hubot classes
Robot = require "hubot/src/robot"
TextMessage = require("hubot/src/message").TextMessage
path = require 'path'

# Load assertion methods to this scope
{ expect } = require 'chai'
nock = require 'nock'
nock.disableNetConnect()

# Enable the deploy commands
process.env.HUBOT_SEMAPHOREAPP_DEPLOY = true
process.env.HUBOT_SEMAPHOREAPP_AUTH_TOKEN = 'xyz'

# Globals
robot = {}

# Create a robot, load our script
prep = ->
    robot = new Robot path.resolve(__dirname), 'shell', yes, 'TestHubot'
    robot.run()

cleanup = ->
    robot.server.close()
    robot.shutdown()
    nock.cleanAll()

# Message/response helper
message_response = (msg, evt, expecter) ->
    robot.adapter.on evt, expecter
    robot.adapter.receive new TextMessage {name: 'foo'}, "TestHubot #{msg}"


# Test help output
describe 'help', ->
    beforeEach (done) ->
        robot = new Robot path.resolve(__dirname), 'shell', yes, 'TestHubot'
        robot.adapter.on 'connected', ->
            # Project script
            robot.loadFile path.resolve('.'), 'index.coffee'
            do done
        robot.run()
    afterEach cleanup

    it 'should parse help', (done) ->
        help = robot.helpCommands()
        expected = [
            'hubot deployed commit on project to server - check if commit has been deployed to server on project',
            'hubot deployed commit - check if commit has been deployed to default server on default project',
            'hubot deployed commit on project - check if commit has been deployed to default server on project',
            'hubot deployed msg on project to server - check if commit message has been deployed to server on project',
            'hubot deployed msg - check if commit message has been deployed to default server on default project',
            'hubot deployed msg on project - check if commit message has been deployed to default server on project'
        ]
        expect(help).to.contain(x) for x in expected
        do done

describe 'deployed', ->
    beforeEach (done) =>
        do prep
        @deployedlib = require '../src/deployed'
        @deployedlib.deployed = (msg, c, p, s) =>
            [@commit, @project, @server] = [c,p,s]
            msg.send 'Overridden deploy'

        @deployedlib robot
        do done
    afterEach cleanup

    it 'should obey the `commit` syntax', (done) =>
        message_response 'deployed commit', 'send', (e,strs) =>
            expect(@commit).to.equal 'commit'
            expect(@project).to.equal 'proj'
            expect(@server).to.equal 'prod'
            do done

    it 'should obey the `commit on project` syntax', (done) =>
        message_response 'deployed commit on project', 'send', (e,strs) =>
            expect(@commit).to.equal 'commit'
            expect(@project).to.equal 'project'
            expect(@server).to.equal 'prod'
            do done

    it 'should obey the `commit on project to server` syntax', (done) =>
        message_response 'deployed commit on project to server', 'send', (e,strs) =>
            expect(@commit).to.equal 'commit'
            expect(@project).to.equal 'project'
            expect(@server).to.equal 'server'
            do done

    it 'should obey the `msg` syntax', (done) =>
        message_response 'deployed msg', 'send', (e,strs) =>
            expect(@commit).to.equal 'msg'
            expect(@project).to.equal 'proj'
            expect(@server).to.equal 'prod'
            do done

    it 'should obey the `msg on project to server` syntax', (done) =>
        message_response 'deployed msg on project to server', 'send', (e,strs) =>
            expect(@commit).to.equal 'msg'
            expect(@project).to.equal 'project'
            expect(@server).to.equal 'server'
            do done
