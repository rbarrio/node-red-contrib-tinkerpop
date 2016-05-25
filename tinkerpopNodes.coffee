###
  * Copyright 2016 IBM Corp.
  *
  * Licensed under the Apache License, Version 2.0 (the "License");
  * you may not use this file except in compliance with the License.
  * You may obtain a copy of the License at
  *
  * http://www.apache.org/licenses/LICENSE-2.0
  *
  * Unless required by applicable law or agreed to in writing, software
  * distributed under the License is distributed on an "AS IS" BASIS,
  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  * See the License for the specific language governing permissions and
  * limitations under the License.
###

rest = require 'rest'
mustache = require 'mustache'

module.exports = (RED) ->
  "use strict"

  GremlinQueryNode = (n) ->
    RED.nodes.createNode this, n
    script = n.gremlin
    isTemplated = (script||"").indexOf("{{") != -1
    this.gremlin = n.gremlin
    this.database = RED.nodes.getNode(n.database)
    node = this
    @on 'input', (msg) ->
      time = new Date().toLocaleTimeString().replace(/([\d]+:[\d]{2})(:[\d]{2})(.*)/, "$1$3")
      node.status {fill:"blue",shape:"dot",text:"Requesting @ "+time}
      if isTemplated
        script = mustache.render script, msg
      rest('http://'+this.database.server+':'+this.database.port+'/?gremlin='+script).then (response)->
        console.log response.entity
        json = JSON.parse response.entity
        if json.message == undefined
          if json.status.code = 200
            msg.status = 'OK'
            node.status {fill:"green",shape:"dot",text:"Successful @ "+time}
          else
            msg.status = 'ERROR'
            node.status {fill:"red",shape:"dot",text:"Error @ "+time}
          msg.status = json.status
          if json.result.data.length == 1
            msg.payload = json.result.data[0]
          else
            msg.payload = json.result.data
        else
          node.status {fill:"red",shape:"dot",text:"Error @ "+time}
          msg.status = 'ERROR'
          msg.payload = json.message
        node.send msg

  RED.nodes.registerType 'gremlin-query', GremlinQueryNode

  TinkerpopConfigNode = (n) ->
    RED.nodes.createNode this, n
    this.server = n.server
    this.port = n.port

  RED.nodes.registerType 'tinkerpop-config', TinkerpopConfigNode
