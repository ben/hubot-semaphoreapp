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

# Globals
robot = {}

# Create a robot, load our script
prep = (done) ->
    robot = new Robot path.resolve(__dirname), 'shell', yes, 'TestHubot'
    robot.adapter.on 'connected', ->
        # Project script
        robot.loadFile path.resolve('.'), 'index.coffee'
        done()
    robot.run()

cleanup = ->
    robot.server.close()
    robot.shutdown()
    nock.cleanAll()

# Message/response helper
message_response = (msg, evt, expecter) ->
    robot.adapter.on evt, expecter
    robot.adapter.receive new TextMessage user, "TestHubot #{msg}"


# Test help output
describe 'help', ->
    beforeEach prep
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
