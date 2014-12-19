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
            'hubot deploy project - deploys project/master to \'prod\'',
            'hubot deploy project to server - deploys project/master to server',
            'hubot deploy project/branch - deploys project/branch to \'prod\'',
            'hubot deploy project/branch to server - deploys project/branch to server',
        ]
        expect(help).to.contain(x) for x in expected
        do done

describe 'deploy', ->
    beforeEach (done) =>
        do prep
        @deploylib = require '../src/deploy'
        @deploylib.deploy = (msg, p, b, s) =>
            [@project, @branch, @server] = [p,b,s]
            msg.send 'Overridden deploy'

        @deploylib robot
        do done
    afterEach cleanup

    it 'should obey the `project` syntax', (done) =>
        message_response 'deploy proj', 'send', (e,strs) =>
            expect(@project).to.equal 'proj'
            expect(@branch).to.equal 'master'
            expect(@server).to.equal 'prod'
            do done

    it 'should obey the `project/branch` syntax', (done) =>
        message_response 'deploy proj/brnch', 'send', (e,strs) =>
            expect(@project).to.equal 'proj'
            expect(@branch).to.equal 'brnch'
            expect(@server).to.equal 'prod'
            do done

    it 'should obey the `project/branch to server` syntax', (done) =>
        message_response 'deploy proj/brnch to srv', 'send', (e,strs) =>
            expect(@project).to.equal 'proj'
            expect(@branch).to.equal 'brnch'
            expect(@server).to.equal 'srv'
            do done

    it 'should obey the `project to srv` syntax', (done) =>
        message_response 'deploy proj to srv', 'send', (e,strs) =>
            expect(@project).to.equal 'proj'
            expect(@branch).to.equal 'master'
            expect(@server).to.equal 'srv'
            do done

    it 'should allow slashes in branch names', (done) =>
        message_response 'deploy proj/brnch/name to srv', 'send', (e,strs) =>
            expect(@project).to.equal 'proj'
            expect(@branch).to.equal 'brnch/name'
            expect(@server).to.equal 'srv'
            do done
