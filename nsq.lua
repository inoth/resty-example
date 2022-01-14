local producer = require "./lib/resty.nsq.producer"
local cjson = require "cjson"
local requsetBody = {method, body}
local nsqTopic = 'ngx_body_mid'
local nsqHost = {
    host = 'localhost',
    port = 4150
}

function __main__()
    GetRequestBody()
    PushMsgToNsq()
    ngx.say("push msg to nsq. ")
    ngx.say(cjson.encode(requsetBody))
end

function PushMsgToNsq()
    local prod = producer:new()

    local ok, err = prod:connect(nsqHost.host, nsqHost.port)
    if not ok then
        ngx.log(ngx.ERR, "failed to connect: ", err)
        return
    end

    local message = cjson.encode(requsetBody)
    ok, err = prod:pub(nsqTopic, message)
    if not ok then
        ngx.log(ngx.ERR, "failed to pub: ", err)
        return
    end

    ok, err = prod:close()
    if not ok then
        ngx.log(ngx.ERR, "failed to close: ", err)
        return
    end
end

function GetRequestBody()
    requsetBody.method = ngx.req.get_method()
    -- ngx.log(ngx.INFO, 'request method is: ' .. requsetBody.method)
    if requsetBody.method == nil then
        ngx.log(ngx.ERR, "get request type error!")
    elseif requsetBody.method == 'POST' then
        ngx.req.read_body()
        requsetBody.body = ngx.req.get_post_args()
    elseif requsetBody.method == 'GET' then
        requsetBody.body = ngx.req.get_uri_args()
    end
end

__main__()
